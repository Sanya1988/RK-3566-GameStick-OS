#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin

GAMESTICK_USERDATA_MOUNTPOINT="${GAMESTICK_USERDATA_MOUNTPOINT:-/storage}"
GAMESTICK_USERDATA_LABEL="${GAMESTICK_USERDATA_LABEL:-USERDATA}"
GAMESTICK_USERDATA_PARTNUM="${GAMESTICK_USERDATA_PARTNUM:-2}"
GAMESTICK_USERDATA_MIN_SIZE_BYTES="${GAMESTICK_USERDATA_MIN_SIZE_BYTES:-268435456}"
GAMESTICK_FIRSTBOOT_STATE_FILE="${GAMESTICK_FIRSTBOOT_STATE_FILE:-/var/lib/gamestick/userdata-firstboot.state}"
GAMESTICK_FIRSTBOOT_LOG_FILE="${GAMESTICK_FIRSTBOOT_LOG_FILE:-/var/lib/gamestick/userdata-firstboot.log}"
GAMESTICK_BOOT_TO_SHELL_MARKER="${GAMESTICK_BOOT_TO_SHELL_MARKER:-/boot/boot_to_shell}"
GAMESTICK_FIRSTBOOT_SCREEN_HELPER="${GAMESTICK_FIRSTBOOT_SCREEN_HELPER:-/usr/bin/gamestick-firstboot-screen}"

log() {
	message=$*
	echo "gamestick-storage: $message" >&2

	log_dir=$(dirname "$GAMESTICK_FIRSTBOOT_LOG_FILE")
	mkdir -p "$log_dir" 2>/dev/null || true
	printf '%s gamestick-storage: %s\n' \
		"$(date '+%F %T' 2>/dev/null || echo unknown-time)" \
		"$message" >>"$GAMESTICK_FIRSTBOOT_LOG_FILE" 2>/dev/null || true
}

root_partition_device() {
	root_arg="$(sed -n 's/.* root=\([^ ]*\).*/\1/p' /proc/cmdline 2>/dev/null | head -n 1)"

	case "$root_arg" in
		PARTUUID=*)
			partuuid="${root_arg#PARTUUID=}"
			blkid -t "PARTUUID=$partuuid" -o device 2>/dev/null | head -n 1
			;;
		/dev/*)
			echo "$root_arg"
			;;
	esac

	if command -v blkid >/dev/null 2>&1; then
		root_label_dev="$(blkid -L rootfs 2>/dev/null || true)"
		if [ -n "$root_label_dev" ] && [ -b "$root_label_dev" ]; then
			echo "$root_label_dev"
			return 0
		fi
	fi

	for dev in /dev/mmcblk1p1 /dev/mmcblk0p1 /dev/sda1 /dev/sdb1 /dev/nvme0n1p1; do
		[ -b "$dev" ] || continue
		echo "$dev"
		return 0
	done
}

partition_path() {
	disk=$1
	partnum=$2

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

partition_two_for_device() {
	partition_path "$1" "$GAMESTICK_USERDATA_PARTNUM"
}

disk_device_from_partition() {
	part=$1

	case "$part" in
		/dev/mmcblk*p[0-9]*|/dev/nvme*n1p[0-9]*)
			echo "$part" | sed 's/p[0-9][0-9]*$//'
			;;
		/dev/*[0-9])
			echo "$part" | sed 's/[0-9][0-9]*$//'
			;;
		*)
			return 1
			;;
	esac
}

preferred_userdata_partition() {
	root_dev="$(root_partition_device || true)"
	if [ -n "$root_dev" ]; then
		userdata_dev="$(partition_two_for_device "$root_dev" || true)"
		if [ -n "$userdata_dev" ] && [ -b "$userdata_dev" ]; then
			echo "$userdata_dev"
			return 0
		fi
	fi

	for dev in /dev/mmcblk1p2 /dev/mmcblk0p2 /dev/sda2 /dev/sdb2 /dev/nvme0n1p2; do
		[ -b "$dev" ] || continue
		echo "$dev"
		return 0
	done

	return 1
}

device_fs_type() {
	dev=$1
	blkid -o value -s TYPE "$dev" 2>/dev/null || true
}

device_size_bytes() {
	dev=$1
	blockdev --getsize64 "$dev" 2>/dev/null || echo 0
}

is_supported_userdata_fs() {
	case "$1" in
		exfat|ntfs)
			return 0
			;;
		*)
			return 1
			;;
	esac
}

find_userdata_device() {
	if command -v blkid >/dev/null 2>&1; then
		dev="$(blkid -L "$GAMESTICK_USERDATA_LABEL" 2>/dev/null || true)"
		if [ -n "$dev" ] && [ -b "$dev" ]; then
			echo "$dev"
			return 0
		fi
	fi

	dev="$(preferred_userdata_partition || true)"
	if [ -n "$dev" ]; then
		fs_type="$(device_fs_type "$dev")"
		if is_supported_userdata_fs "$fs_type"; then
			echo "$dev"
			return 0
		fi
	fi

	return 1
}

mount_exfat_storage() {
	dev=$1
	mountpoint=${2:-$GAMESTICK_USERDATA_MOUNTPOINT}

	if [ -x /etc/init.d/fuse3 ]; then
		/etc/init.d/fuse3 start >/dev/null 2>&1 || true
	fi

	if command -v mount.exfat-fuse >/dev/null 2>&1; then
		mount.exfat-fuse -o uid=0,gid=0,umask=022,noatime "$dev" "$mountpoint"
		return $?
	fi

	if command -v mount.exfat >/dev/null 2>&1; then
		mount.exfat -o uid=0,gid=0,umask=022,noatime "$dev" "$mountpoint"
		return $?
	fi

	if mount -t exfat -o uid=0,gid=0,umask=022,noatime "$dev" "$mountpoint" >/dev/null 2>&1; then
		return 0
	fi

	log "exFAT mount helper is missing"
	return 1
}

ensure_userdata_layout() {
	mountpoint=${1:-$GAMESTICK_USERDATA_MOUNTPOINT}

	mkdir -p \
		"$mountpoint/roms" \
		"$mountpoint/screensaver" \
		"$mountpoint/bios" \
		"$mountpoint/music" \
		"$mountpoint/esde" \
		"$mountpoint/esde/settings" \
		"$mountpoint/esde/custom_systems" \
		"$mountpoint/esde/gamelists" \
		"$mountpoint/esde/themes" \
		"$mountpoint/esde/downloaded_media" \
		"$mountpoint/system" \
		"$mountpoint/system/input" \
		"$mountpoint/system/input/overrides/udev" \
		"$mountpoint/system/input/profiles/udev" \
		"$mountpoint/system/input/profiles" \
		"$mountpoint/system/input/quirks" \
		"$mountpoint/system/logs" \
		"$mountpoint/retroarch" \
		"$mountpoint/retroarch/home" \
		"$mountpoint/retroarch/config" \
		"$mountpoint/retroarch/cache" \
		"$mountpoint/retroarch/share" \
		"$mountpoint/retroarch/cores" \
		"$mountpoint/retroarch/info" \
		"$mountpoint/retroarch/database/rdb" \
		"$mountpoint/retroarch/cheats" \
		"$mountpoint/retroarch/filters/video" \
		"$mountpoint/retroarch/filters/audio" \
		"$mountpoint/retroarch/shaders" \
		"$mountpoint/retroarch/overlays" \
		"$mountpoint/retroarch/autoconfig" \
		"$mountpoint/retroarch/autoconfig/udev" \
		"$mountpoint/retroarch/config/retroarch" \
		"$mountpoint/retroarch/config/retroarch/gamestick" \
		"$mountpoint/retroarch/config/retroarch/gamestick/overrides" \
		"$mountpoint/retroarch/config/retroarch/gamestick/overrides/systems" \
		"$mountpoint/retroarch/config/retroarch/gamestick/overrides/cores" \
		"$mountpoint/retroarch/config/retroarch/gamestick/overrides/games" \
		"$mountpoint/retroarch/playlists" \
		"$mountpoint/retroarch/thumbnails" \
		"$mountpoint/retroarch/remaps" \
		"$mountpoint/retroarch/saves" \
		"$mountpoint/retroarch/states" \
		"$mountpoint/retroarch/screenshots"
	ln -snf /storage/roms /roms
}

read_firstboot_state() {
	if [ -f "$GAMESTICK_FIRSTBOOT_STATE_FILE" ]; then
		head -n 1 "$GAMESTICK_FIRSTBOOT_STATE_FILE"
		return 0
	fi

	echo pending
}

write_firstboot_state() {
	state=$1
	state_dir=$(dirname "$GAMESTICK_FIRSTBOOT_STATE_FILE")

	mkdir -p "$state_dir"
	printf '%s\n' "$state" >"$GAMESTICK_FIRSTBOOT_STATE_FILE"
	sync
}

tell_psplash() {
	message=$1

	if command -v psplash-write >/dev/null 2>&1; then
		psplash-write "MSG $message" >/dev/null 2>&1 || true
	fi
}

show_firstboot_screen() {
	screen=$1
	fallback_message=${2:-}

	if [ -x "$GAMESTICK_FIRSTBOOT_SCREEN_HELPER" ] \
		&& "$GAMESTICK_FIRSTBOOT_SCREEN_HELPER" "$screen" >/dev/null 2>&1; then
		return 0
	fi

	if [ -n "$fallback_message" ]; then
		tell_psplash "$fallback_message"
	fi
}

arm_boot_to_shell() {
	touch "$GAMESTICK_BOOT_TO_SHELL_MARKER" 2>/dev/null || true
}
