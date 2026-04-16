#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SEED_HELPER="$SCRIPT_DIR/gamestick-userdata-seed.sh"
LABEL="${GAMESTICK_USERDATA_LABEL:-USERDATA}"
PARTNUM=2
MIN_SIZE_BYTES="${GAMESTICK_USERDATA_MIN_SIZE_BYTES:-268435456}"
ROOTFS_PARTNUM=1
ROOTFS_MNT=
USERDATA_MNT=

usage() {
	cat <<'EOF'
Usage: sudo ./prepare-userdata.sh /dev/sdX

Expands partition 2 to the end of the card and formats it as exFAT with label USERDATA.
Run this after writing sdcard.img and before the first boot on the device.
EOF
}

partition_path() {
	disk=$1
	partnum=${2:-$PARTNUM}
	case "$disk" in
		/dev/mmcblk*|/dev/nvme*n1)
			echo "${disk}p${partnum}"
			;;
		/dev/*)
			echo "${disk}${partnum}"
			;;
		*)
			return 1
			;;
	esac
}

require_command() {
	command -v "$1" >/dev/null 2>&1 || {
		echo "missing required command: $1" >&2
		exit 1
	}
}

cleanup() {
	if [ -n "${USERDATA_MNT:-}" ] && mountpoint -q "$USERDATA_MNT" 2>/dev/null; then
		umount "$USERDATA_MNT" || true
	fi

	if [ -n "${ROOTFS_MNT:-}" ] && mountpoint -q "$ROOTFS_MNT" 2>/dev/null; then
		umount "$ROOTFS_MNT" || true
	fi

	[ -n "${USERDATA_MNT:-}" ] && rmdir "$USERDATA_MNT" 2>/dev/null || true
	[ -n "${ROOTFS_MNT:-}" ] && rmdir "$ROOTFS_MNT" 2>/dev/null || true
}

preseed_userdata() {
	root_part=$1
	userdata_part=$2

	# shellcheck source=/dev/null
	. "$SEED_HELPER"

	ROOTFS_MNT="$(mktemp -d /tmp/gamestick-rootfs.XXXXXX)"
	USERDATA_MNT="$(mktemp -d /tmp/gamestick-userdata.XXXXXX)"

	mount -o ro "$root_part" "$ROOTFS_MNT"
	if ! mount -t exfat "$userdata_part" "$USERDATA_MNT" >/dev/null 2>&1; then
		mount "$userdata_part" "$USERDATA_MNT"
	fi

	seed_userdata_from_root "$ROOTFS_MNT" "$USERDATA_MNT"
}

[ $# -eq 1 ] || {
	usage >&2
	exit 1
}

DISK=$1
PART="$(partition_path "$DISK" "$PARTNUM")"
ROOT_PART="$(partition_path "$DISK" "$ROOTFS_PARTNUM")"
trap cleanup EXIT

[ "$(id -u)" -eq 0 ] || {
	echo "run as root" >&2
	exit 1
}

[ -b "$DISK" ] || {
	echo "block device not found: $DISK" >&2
	exit 1
}

[ -b "$ROOT_PART" ] || {
	echo "rootfs partition not found: $ROOT_PART" >&2
	exit 1
}

require_command sfdisk
require_command partprobe
require_command blockdev
require_command mkfs.exfat
require_command lsblk

[ -r "$SEED_HELPER" ] || {
	echo "seed helper is missing: $SEED_HELPER" >&2
	exit 1
}

echo "Preparing USERDATA on $DISK"

while read -r dev mnt; do
	[ -n "$mnt" ] || continue
	umount "$dev"
done <<EOF
$(lsblk -nrpo NAME,MOUNTPOINT "$DISK")
EOF

if ! printf ', +\n' | sfdisk --force -N "$PARTNUM" "$DISK"; then
	echo "warning: sfdisk resizepart failed, continuing with current partition size" >&2
fi
sync
blockdev --rereadpt "$DISK" || true
partprobe "$DISK" || true

if command -v udevadm >/dev/null 2>&1; then
	udevadm settle || true
else
	sleep 2
fi

[ -b "$PART" ] || {
	echo "partition device not visible after resize: $PART" >&2
	exit 1
}

PART_SIZE="$(blockdev --getsize64 "$PART" 2>/dev/null || echo 0)"
[ "$PART_SIZE" -ge "$MIN_SIZE_BYTES" ] || {
	echo "partition 2 is still too small after resize: $PART_SIZE bytes" >&2
	exit 1
}

mkfs.exfat -L "$LABEL" "$PART"

preseed_userdata "$ROOT_PART" "$PART"

echo
echo "USERDATA prepared:"
blkid "$PART" || true
