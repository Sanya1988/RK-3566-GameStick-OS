#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
output_dir=${1:-"$repo_dir/output"}

if [ ! -d "$repo_dir/buildroot" ]; then
	echo "buildroot submodule is missing" >&2
	echo "run: git submodule update --init --recursive" >&2
	exit 1
fi

mkdir -p "$output_dir"

make -C "$repo_dir/buildroot" \
	O="$output_dir" \
	BR2_EXTERNAL="$repo_dir/br2-external" \
	gamestick_rk3566_m16_defconfig

echo
echo "Build tree initialized:"
echo "  cd \"$output_dir\" && make"
