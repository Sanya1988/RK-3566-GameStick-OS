#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
output_dir=${1:-"$repo_dir/output"}

if [ ! -d "$repo_dir/buildroot" ]; then
	echo "buildroot submodule is missing" >&2
	echo "run: git submodule update --init --recursive" >&2
	exit 1
fi

apply_buildroot_compat_patches() {
	patches_dir="$repo_dir/patches/buildroot"

	if [ ! -d "$patches_dir" ]; then
		return 0
	fi

	if grep -q 'select BR2_PACKAGE_MALI_DRIVER if BR2_LINUX_KERNEL' \
		"$repo_dir/buildroot/package/rockchip-mali/Config.in"; then
		echo "Applying Buildroot compatibility patch: rockchip-mali"
		patch -d "$repo_dir/buildroot" -p1 < \
			"$patches_dir/0001-rockchip-mali-do-not-force-external-mali-driver.patch"
	fi

	if ! grep -q 'SDL2_GAMESTICK_OLD_GBM_COMPAT' \
		"$repo_dir/buildroot/package/sdl2/sdl2.mk"; then
		echo "Applying Buildroot compatibility patch: sdl2 kmsdrm"
		patch -d "$repo_dir/buildroot" -p1 < \
			"$patches_dir/0002-sdl2-add-gamestick-kmsdrm-compat.patch"
	fi
}

mkdir -p "$output_dir"
apply_buildroot_compat_patches

make -C "$repo_dir/buildroot" \
	O="$output_dir" \
	BR2_EXTERNAL="$repo_dir/br2-external" \
	gamestick_rk3566_m16_defconfig

echo
echo "Build tree initialized:"
echo "  cd \"$output_dir\" && make"
