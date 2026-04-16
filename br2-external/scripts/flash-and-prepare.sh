#!/bin/sh

set -eu

require_command() {
	command -v "$1" >/dev/null 2>&1 || {
		echo "missing required command: $1" >&2
		exit 1
	}
}

unmount_disk_partitions() {
	disk=$1

	lsblk -nrpo NAME,MOUNTPOINT "$disk" | while read -r dev mnt; do
		[ -n "$mnt" ] || continue
		umount "$dev"
	done
}

show_layout() {
	disk=$1

	echo "Partition layout for $disk:"
	lsblk -o NAME,PATH,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS "$disk"
	echo
}

usage() {
	cat <<'EOF'
Usage: sudo ./flash-and-prepare.sh /path/to/sdcard.img /dev/sdX

Writes the image to the card, keeps the image GPT layout, then prepares
partition 2 as USERDATA.
EOF
}

[ $# -eq 2 ] || {
	usage >&2
	exit 1
}

IMG=$1
DISK=$2
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PREPARE="$SCRIPT_DIR/prepare-userdata.sh"

[ "$(id -u)" -eq 0 ] || {
	echo "run as root" >&2
	exit 1
}

[ -f "$IMG" ] || {
	echo "image not found: $IMG" >&2
	exit 1
}

[ -b "$DISK" ] || {
	echo "block device not found: $DISK" >&2
	exit 1
}

[ -x "$PREPARE" ] || {
	echo "missing helper: $PREPARE" >&2
	exit 1
}

require_command dd
require_command lsblk

echo "Unmounting mounted partitions on $DISK"
unmount_disk_partitions "$DISK"

echo "Flashing $IMG to $DISK"
dd if="$IMG" of="$DISK" bs=4M conv=fsync status=progress
sync

echo
"$PREPARE" "$DISK"

echo
show_layout "$DISK"
