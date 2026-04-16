#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
dist_dir="$repo_dir/dist"
date_tag=$(date +%Y%m%d)
archive_name="gamestick-os-br2-$date_tag.tar.gz"
archive_path="$dist_dir/$archive_name"

git -C "$repo_dir" submodule update --init --recursive

mkdir -p "$dist_dir"
rm -f "$archive_path" "$archive_path.sha256"

tar \
	--exclude-vcs \
	--exclude='./dist' \
	--exclude='./output' \
	-C "$(dirname "$repo_dir")" \
	-czf "$archive_path" \
	"$(basename "$repo_dir")"

sha256sum "$archive_path" >"$archive_path.sha256"

echo "Created:"
echo "  $archive_path"
echo "  $archive_path.sha256"
