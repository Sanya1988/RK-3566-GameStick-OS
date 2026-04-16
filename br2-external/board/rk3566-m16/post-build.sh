#!/bin/sh
set -eu

BOARD_DIR="$(dirname "$0")"

find_host_readelf() {
	for candidate in \
		"$HOST_DIR/bin/readelf" \
		"$HOST_DIR/bin/aarch64-linux-readelf"
	do
		if [ -x "$candidate" ]; then
			echo "$candidate"
			return 0
		fi
	done

	if command -v readelf >/dev/null 2>&1; then
		command -v readelf
		return 0
	fi

	echo "ERROR: readelf not available for target ELF validation" >&2
	exit 1
}

READELF="$(find_host_readelf)"

find_target_soname() {
	soname="$1"
	for dir in "$TARGET_DIR/lib" "$TARGET_DIR/usr/lib" "$TARGET_DIR/lib64" "$TARGET_DIR/usr/lib64"; do
		if [ -e "$dir/$soname" ]; then
			return 0
		fi
	done
	return 1
}

validate_target_elf() {
	relpath="$1"
	path="$TARGET_DIR$relpath"

	[ -e "$path" ] || return 0
	"$READELF" -h "$path" >/dev/null 2>&1 || return 0

	interpreter="$($READELF -l "$path" 2>/dev/null | sed -n 's/.*Requesting program interpreter: \(.*\)]$/\1/p')"
	if [ -n "$interpreter" ] && [ ! -e "$TARGET_DIR$interpreter" ]; then
		echo "ERROR: missing interpreter $interpreter required by $relpath" >&2
		exit 1
	fi

	$READELF -d "$path" 2>/dev/null \
		| sed -n 's/.*Shared library: \[\(.*\)\].*/\1/p' \
		| while IFS= read -r soname; do
			[ -n "$soname" ] || continue
			case "$soname" in
				linux-vdso.so.*)
					continue
					;;
			esac
			if ! find_target_soname "$soname"; then
				echo "ERROR: missing shared library $soname required by $relpath" >&2
				exit 1
			fi
		done
}

if [ -x "$HOST_DIR/bin/uuidgen" ]; then
	PARTUUID="$($HOST_DIR/bin/uuidgen)"
elif command -v uuidgen >/dev/null 2>&1; then
	PARTUUID="$(uuidgen)"
else
	PARTUUID="$(cat /proc/sys/kernel/random/uuid)"
fi

if [ -f "$TARGET_DIR/boot/Image.gz" ]; then
	KERNEL_IMAGE="/boot/Image.gz"
elif [ -f "$TARGET_DIR/boot/Image" ]; then
	KERNEL_IMAGE="/boot/Image"
else
	echo "ERROR: kernel image not found in $TARGET_DIR/boot (expected Image or Image.gz)" >&2
	exit 1
fi

DTB_CANDIDATE="$TARGET_DIR/boot/rockchip/m_16_boot.dtb"
if [ -f "$DTB_CANDIDATE" ]; then
	DTB_PATH="/boot/rockchip/m_16_boot.dtb"
else
	DTB_CANDIDATE="$(find "$TARGET_DIR/boot/rockchip" -maxdepth 1 -type f -name '*.dtb' | LC_ALL=C sort | head -n 1)"
	if [ -z "$DTB_CANDIDATE" ]; then
		echo "ERROR: no DTB found in $TARGET_DIR/boot/rockchip" >&2
		exit 1
	fi
	DTB_PATH="${DTB_CANDIDATE#$TARGET_DIR}"
fi

# Buildroot can keep package stamps even when images are cleaned; in that case
# re-export the Rockchip loader image from the U-Boot build directory.
if [ ! -f "$BINARIES_DIR/u-boot-rockchip.bin" ]; then
	UBOOT_ROCKCHIP_BIN="$(find "$BUILD_DIR" -maxdepth 2 -type f -name 'u-boot-rockchip.bin' -path "$BUILD_DIR/uboot-*/*" | LC_ALL=C sort | tail -n 1)"
	if [ -n "$UBOOT_ROCKCHIP_BIN" ]; then
		install -D -m 0644 "$UBOOT_ROCKCHIP_BIN" "$BINARIES_DIR/u-boot-rockchip.bin"
	else
		echo "ERROR: u-boot-rockchip.bin is missing and was not found in $BUILD_DIR/uboot-*" >&2
		exit 1
	fi
fi

install -d "$TARGET_DIR/boot/extlinux"
sed \
	-e "s|%PARTUUID%|$PARTUUID|g" \
	-e "s|%KERNEL_IMAGE%|$KERNEL_IMAGE|g" \
	-e "s|%DTB_PATH%|$DTB_PATH|g" \
	"$BOARD_DIR/extlinux.conf.in" > "$TARGET_DIR/boot/extlinux/extlinux.conf"
sed "s/%PARTUUID%/$PARTUUID/g" "$BOARD_DIR/genimage.cfg.in" > "$BINARIES_DIR/genimage.cfg"

if [ -f "$TARGET_DIR/usr/lib/os-release" ]; then
	sed -i \
		-e 's/^NAME=.*/NAME="GameStick OS"/' \
		-e 's/^PRETTY_NAME=.*/PRETTY_NAME="GameStick OS"/' \
		-e 's/^ID=.*/ID=gamestick-os/' \
		"$TARGET_DIR/usr/lib/os-release"
else
	cat >"$TARGET_DIR/usr/lib/os-release" <<'EOF_OS_RELEASE'
NAME="GameStick OS"
ID=gamestick-os
PRETTY_NAME="GameStick OS"
EOF_OS_RELEASE
fi

ln -snf ../usr/lib/os-release "$TARGET_DIR/etc/os-release"
printf '%s\n' 'gamestick-os' >"$TARGET_DIR/etc/hostname"
printf '%s\n' 'GameStick OS' >"$TARGET_DIR/etc/issue"

# -----------------------------------------------------------------------------
# Optional boot logging helpers.
# Disabled by default because the production target should stay visually quiet
# on HDMI and should not force a tty1 shell prompt onto the screen.
# -----------------------------------------------------------------------------
if [ "${GAMESTICK_ENABLE_BOOTLOG:-0}" = "1" ]; then
install -d "$TARGET_DIR/usr/bin" "$TARGET_DIR/etc/init.d"

cat > "$TARGET_DIR/usr/bin/bootlog-persist.sh" << 'EOF_BOOTLOG_PERSIST'
#!/bin/sh
set +e

pick_target_dir() {
	for d in \
		/userdata/bootlogs \
		/sdcard/emuelec/logs/bootlogs \
		/mnt/udata/bootlogs \
		/mnt/UDISK/bootlogs \
		/boot/bootlogs
	do
		mkdir -p "$d" 2>/dev/null || continue
		touch "$d/.bootlog_rw_test" 2>/dev/null || continue
		rm -f "$d/.bootlog_rw_test"
		echo "$d"
		return 0
	done
	return 1
}

TARGET_DIR="$(pick_target_dir)"
[ -n "$TARGET_DIR" ] || exit 0

TS="$(date +%Y%m%d_%H%M%S)"
BASE="$TARGET_DIR/boot_${TS}"

{
	echo "timestamp=$TS"
	echo "kernel_cmdline=$(cat /proc/cmdline 2>/dev/null)"
	echo "uname=$(uname -a 2>/dev/null)"
} > "${BASE}.meta.txt"

cat /proc/mounts > "${BASE}.mounts.txt" 2>/dev/null
dmesg > "${BASE}.dmesg.txt" 2>/dev/null

[ -f /tmp/boot-rcS.log ] && cp -f /tmp/boot-rcS.log "${BASE}.rcS.log"
[ -f /tmp/dmesg-early.log ] && cp -f /tmp/dmesg-early.log "${BASE}.dmesg_early.log"
EOF_BOOTLOG_PERSIST
chmod 0755 "$TARGET_DIR/usr/bin/bootlog-persist.sh"

cat > "$TARGET_DIR/usr/bin/hdmi-audio-test.sh" << 'EOF_HDMI_AUDIO_TEST'
#!/bin/sh
set -u

device="${1:-hw:0,0}"
stamp="$(date +%F_%H%M%S 2>/dev/null || date)"
logdir="/boot/bootlogs/cmdlogs"
tmpfile="/tmp/hdmi-audio-test.$$.log"
logfile="${logdir}/${stamp}_hdmi_audio_test.log"

if [ -d /usr/glibc-compat/lib ]; then
	export LD_LIBRARY_PATH="/usr/glibc-compat/lib:/usr/lib:/lib:/usr/lib64:/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
fi

run() {
	echo
	echo "\$ $*"
	"$@" 2>&1
	rc=$?
	echo "[rc=$rc]"
	return 0
}

{
	echo "timestamp: $(date 2>/dev/null || true)"
	echo "device: ${device}"
	echo "PATH=${PATH}"
	echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}"

	echo
	echo "--- kernel side ---"
	run ls -la /dev/snd
	run cat /proc/asound/cards
	run cat /proc/asound/pcm
	run sh -c "dmesg | tail -n 200"

	echo
	echo "--- userspace ---"
	run /usr/bin/aplay -l
	run /usr/bin/amixer -c 0 scontrols

	echo
	echo "--- audio test ---"
	run /usr/bin/speaker-test -D "$device" -c 2 -t sine -f 440 -l 1
} | tee "$tmpfile"

mkdir -p "$logdir" 2>/dev/null || true
cp -f "$tmpfile" "$logfile" 2>/dev/null || true
sync 2>/dev/null || true
rm -f "$tmpfile"

echo
echo "log: $logfile"
EOF_HDMI_AUDIO_TEST
chmod 0755 "$TARGET_DIR/usr/bin/hdmi-audio-test.sh"

cat > "$TARGET_DIR/sbin/init-wrapper" << 'EOF_INIT_WRAPPER'
#!/bin/sh
set +e

TS="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo unknown)"
EARLY="/boot/extlinux/init-wrapper.log"

{
	echo "===== init-wrapper start ts=$TS ====="
	echo "cmdline: $(cat /proc/cmdline 2>/dev/null)"
	echo "mounts:"
	cat /proc/mounts 2>/dev/null
	echo "dmesg-early:"
	dmesg 2>/dev/null
	echo "===== init-wrapper end ts=$TS ====="
} >> "$EARLY" 2>/dev/null || true
sync 2>/dev/null || true

exec /sbin/init "$@"
EOF_INIT_WRAPPER
chmod 0755 "$TARGET_DIR/sbin/init-wrapper"

cat > "$TARGET_DIR/etc/init.d/S02bootlog" << 'EOF_S02BOOTLOG'
#!/bin/sh

case "$1" in
	start)
		mkdir -p /boot/bootlogs 2>/dev/null || true
		echo "[S02bootlog] start $(date -R)" >> /tmp/boot-rcS.log
		echo "[S02bootlog] start $(date -R)" >> /boot/bootlogs/live_rcS.log 2>/dev/null || true
		dmesg > /tmp/dmesg-early.log 2>/dev/null || true
		dmesg > /boot/bootlogs/live_dmesg_early.log 2>/dev/null || true
		sync 2>/dev/null || true
		;;
esac
EOF_S02BOOTLOG
chmod 0755 "$TARGET_DIR/etc/init.d/S02bootlog"

cat > "$TARGET_DIR/etc/init.d/S99bootlog" << 'EOF_S99BOOTLOG'
#!/bin/sh

case "$1" in
	start)
		/usr/bin/bootlog-persist.sh
		;;
esac
EOF_S99BOOTLOG
chmod 0755 "$TARGET_DIR/etc/init.d/S99bootlog"

if [ -f "$TARGET_DIR/etc/init.d/rcS" ]; then
	cp -f "$TARGET_DIR/etc/init.d/rcS" "$TARGET_DIR/etc/init.d/rcS.br.orig"
fi

cat > "$TARGET_DIR/etc/init.d/rcS" << 'EOF_RCS'
#!/bin/sh

BOOTLOG_TMP="/tmp/boot-rcS.log"
BOOTLOG_LIVE="/boot/bootlogs/live_rcS.log"
mkdir -p /tmp
mkdir -p /boot/bootlogs 2>/dev/null || true
exec >>"$BOOTLOG_TMP" 2>&1

echo "==== rcS start $(date -R) ===="
echo "cmdline: $(cat /proc/cmdline 2>/dev/null)"
dmesg -n 8

{
	echo "==== rcS start $(date -R) ===="
	echo "cmdline: $(cat /proc/cmdline 2>/dev/null)"
} >>"$BOOTLOG_LIVE" 2>/dev/null || true

# Start all init scripts in /etc/init.d in numerical order.
for i in /etc/init.d/S??* ;do
	[ ! -f "$i" ] && continue
	echo "---- start $i ----"
	echo "---- start $i ----" >>"$BOOTLOG_LIVE" 2>/dev/null || true
	case "$i" in
	*.sh)
		(
			trap - INT QUIT TSTP
			set start
			. "$i"
		)
		;;
	*)
		"$i" start
		;;
	esac
	echo "---- done  $i (rc=$?) ----"
	echo "---- done  $i (rc=$?) ----" >>"$BOOTLOG_LIVE" 2>/dev/null || true
	sync 2>/dev/null || true
done

echo "==== rcS done $(date -R) ===="
echo "==== rcS done $(date -R) ====" >>"$BOOTLOG_LIVE" 2>/dev/null || true

# One more attempt to persist logs in case userdata appears late.
if [ -x /usr/bin/bootlog-persist.sh ]; then
	/usr/bin/bootlog-persist.sh &
fi
EOF_RCS
chmod 0755 "$TARGET_DIR/etc/init.d/rcS"

fi

if [ -f "$TARGET_DIR/etc/init.d/rcS.br.orig" ]; then
	cp -f "$TARGET_DIR/etc/init.d/rcS.br.orig" "$TARGET_DIR/etc/init.d/rcS"
	rm -f "$TARGET_DIR/etc/init.d/rcS.br.orig"
fi

rm -f \
	"$TARGET_DIR/etc/init.d/S02bootlog" \
	"$TARGET_DIR/etc/init.d/S99bootlog" \
	"$TARGET_DIR/usr/bin/bootlog-persist.sh" \
	"$TARGET_DIR/sbin/init-wrapper"

if [ -x "$TARGET_DIR/usr/bin/psplash" ] || [ -x "$TARGET_DIR/usr/bin/fbv" ]; then
	install -D -m 0755 "$BOARD_DIR/S03psplash" "$TARGET_DIR/etc/init.d/S03psplash"
else
	rm -f "$TARGET_DIR/etc/init.d/S03psplash"
fi

if [ -f "$BOARD_DIR/boot-splash.png" ]; then
	install -D -m 0644 "$BOARD_DIR/boot-splash.png" \
		"$TARGET_DIR/usr/share/gamestick/boot/boot-splash.png"
else
	rm -f "$TARGET_DIR/usr/share/gamestick/boot/boot-splash.png"
fi

if [ -x "$TARGET_DIR/usr/bin/fbv" ]; then
	install -d \
		"$TARGET_DIR/etc/init.d" \
		"$TARGET_DIR/usr/bin" \
		"$TARGET_DIR/usr/share/gamestick/shutdown"
	install -D -m 0755 "$BOARD_DIR/gamestick-shutdown-screen" \
		"$TARGET_DIR/usr/bin/gamestick-shutdown-screen"
	install -D -m 0755 "$BOARD_DIR/S98gamestick-shutdown-start" \
		"$TARGET_DIR/etc/init.d/S98gamestick-shutdown-start"
	install -D -m 0755 "$BOARD_DIR/S00gamestick-shutdown-complete" \
		"$TARGET_DIR/etc/init.d/S00gamestick-shutdown-complete"

	if [ -f "$BOARD_DIR/shutdown-start.png" ]; then
		install -D -m 0644 "$BOARD_DIR/shutdown-start.png" \
			"$TARGET_DIR/usr/share/gamestick/shutdown/shutdown-start.png"
	else
		rm -f "$TARGET_DIR/usr/share/gamestick/shutdown/shutdown-start.png"
	fi

	if [ -f "$BOARD_DIR/shutdown-complete.png" ]; then
		install -D -m 0644 "$BOARD_DIR/shutdown-complete.png" \
			"$TARGET_DIR/usr/share/gamestick/shutdown/shutdown-complete.png"
	else
		rm -f "$TARGET_DIR/usr/share/gamestick/shutdown/shutdown-complete.png"
	fi
else
	rm -f \
		"$TARGET_DIR/etc/init.d/S98gamestick-shutdown-start" \
		"$TARGET_DIR/etc/init.d/S00gamestick-shutdown-complete" \
		"$TARGET_DIR/usr/bin/gamestick-shutdown-screen"
	rm -rf "$TARGET_DIR/usr/share/gamestick/shutdown"
fi

if [ -f "$TARGET_DIR/etc/inittab" ]; then
	tmp_inittab="$(mktemp)"
	grep -v '^tty1::askfirst:-/bin/sh$' "$TARGET_DIR/etc/inittab" > "$tmp_inittab" || true
	mv "$tmp_inittab" "$TARGET_DIR/etc/inittab"
fi

# Fail the build if the target contains ELF binaries whose runtime loader or
# required shared libraries are missing. This catches silent libc/toolchain
# mixups before an image reaches the SD card.
validate_target_elf /bin/busybox
validate_target_elf /linuxrc
validate_target_elf /usr/bin/aplay
validate_target_elf /usr/bin/speaker-test
validate_target_elf /usr/bin/amixer
validate_target_elf /usr/sbin/alsactl
validate_target_elf /usr/bin/fbv
validate_target_elf /usr/lib/libasound.so.2.0.0
validate_target_elf /usr/lib/libatopology.so.2.0.0
