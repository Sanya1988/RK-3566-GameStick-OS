#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
	echo "usage: $0 <libretro-super-dir>" >&2
	exit 1
fi

workdir="$1"
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
lock_file="${CORES_LOCK_FILE:-$script_dir/core-sources.lock}"

if [ ! -d "$workdir" ]; then
	echo "missing libretro-super workdir: $workdir" >&2
	exit 1
fi

if [ ! -f "$lock_file" ]; then
	echo "missing core lock file: $lock_file" >&2
	exit 1
fi

target_prefix="${HOST_CC:-${TARGET_CROSS:-}}"
target_prefix="${target_prefix%-}"

# Buildroot may export git-related environment from the top-level tree.
# Clear it so per-core git worktrees behave normally.
unset GIT_DIR
unset GIT_WORK_TREE

export HOST_CC="${target_prefix}"
export ARCH="${ARCH:-aarch64}"
export platform="${platform:-unix}"
export JOBS="${JOBS:-1}"
export FORMAT_COMPILER_TARGET="${FORMAT_COMPILER_TARGET:-unix}"
export FORMAT_COMPILER_TARGET_ALT="${FORMAT_COMPILER_TARGET_ALT:-unix}"
export CXX="${CXX:-${target_prefix:+$target_prefix-g++}}"
export CXX11="${CXX11:-$CXX}"
export CXX17="${CXX17:-$CXX}"

cd "$workdir"
# libretro-super defines many optional variables in terms of prior values.
# Load its rule set without nounset, then restore strict mode for our helper.
set +u
. "$workdir/rules.d/core-rules.sh"
set -u

# libretro/gpsp autodetects x86 when built with generic platform=unix.
# Force the dedicated aarch64 path so it picks arm64 dynarec stubs.
if [ "${ARCH}" = "aarch64" ]; then
	libretro_gpsp_build_platform="arm64"
fi

github_archive_url() {
	local git_url="$1"
	local ref="$2"
	local repo_path

	case "$git_url" in
		https://github.com/*/*.git)
			repo_path="${git_url#https://github.com/}"
		;;
		http://github.com/*/*.git)
			repo_path="${git_url#http://github.com/}"
		;;
		git://github.com/*/*.git)
			repo_path="${git_url#git://github.com/}"
		;;
		git@github.com:*.git)
			repo_path="${git_url#git@github.com:}"
		;;
		*)
			return 1
		;;
	esac

	repo_path="${repo_path%.git}"
	printf 'https://codeload.github.com/%s/tar.gz/%s\n' "$repo_path" "$ref"
}

existing_checkout_matches_ref() {
	local module_dir="$1"
	local ref="$2"
	local git_submodules="$3"
	local current_ref wanted_ref submodule_state

	if [ ! -d "$module_dir/.git" ]; then
		return 1
	fi

	current_ref="$(git -C "$module_dir" rev-parse HEAD 2>/dev/null)" || return 1
	wanted_ref="$(git -C "$module_dir" rev-parse -q --verify "${ref}^{commit}" 2>/dev/null)" || return 1

	if [ "$current_ref" != "$wanted_ref" ]; then
		return 1
	fi

	if [ -n "$git_submodules" ]; then
		submodule_state="$(git -C "$module_dir" submodule status --recursive 2>/dev/null || true)"
		if printf '%s\n' "$submodule_state" | grep -q '^[+-]'; then
			return 1
		fi
	fi

	return 0
}

fetch_module_archive() {
	local module_dir="$1"
	local module="$2"
	local git_url="$3"
	local ref="$4"
	local archive_url archive_path temp_dir

	if [ -d "$module_dir" ] && [ ! -d "$module_dir/.git" ] && \
		find "$module_dir" -mindepth 1 -maxdepth 1 -print -quit >/dev/null 2>&1; then
		echo "using existing module archive: $module" >&2
		return 0
	fi

	if ! archive_url="$(github_archive_url "$git_url" "$ref")"; then
		return 1
	fi

	archive_path="$(mktemp)"
	temp_dir="$(mktemp -d)"

	if ! curl --http1.1 --location --fail --retry 3 --retry-delay 1 \
		--retry-all-errors --continue-at - --speed-limit 1024 --speed-time 20 \
		--output "$archive_path" "$archive_url"; then
		rm -f "$archive_path"
		rm -rf "$temp_dir"
		return 1
	fi

	if ! tar -xzf "$archive_path" --strip-components=1 -C "$temp_dir"; then
		rm -f "$archive_path"
		rm -rf "$temp_dir"
		return 1
	fi

	rm -rf "$module_dir"
	mkdir -p "$(dirname "$module_dir")"
	mv "$temp_dir" "$module_dir"
	rm -f "$archive_path"
	echo "fetched module archive: $module" >&2
	return 0
}

fetch_module() {
	local module="$1"
	local ref="$2"
	local git_url module_dir git_submodules legacy_makefile build_makefile

	eval "git_url=\${libretro_${module}_git_url:-}"
	eval "module_dir=\${libretro_${module}_dir:-libretro-$module}"
	eval "git_submodules=\${libretro_${module}_git_submodules:-}"
	eval "legacy_makefile=\${libretro_${module}_makefile:-}"
	eval "build_makefile=\${libretro_${module}_build_makefile:-}"

	if [ -n "$legacy_makefile" ] && [ -z "$build_makefile" ]; then
		eval "libretro_${module}_build_makefile=\$legacy_makefile"
	fi

	if [ -z "$git_url" ]; then
		echo "missing git url for module: $module" >&2
		exit 1
	fi

	if existing_checkout_matches_ref "$module_dir" "$ref" "$git_submodules"; then
		echo "using existing module checkout: $module" >&2
		return 0
	fi

	if [ "$git_submodules" != "yes" ]; then
		if fetch_module_archive "$module_dir" "$module" "$git_url" "$ref"; then
			return 0
		fi
	fi

	if [ ! -d "$module_dir/.git" ]; then
		rm -rf "$module_dir"
		git init "$module_dir" >/dev/null
		git -C "$module_dir" remote add origin "$git_url"
	else
		git -C "$module_dir" remote set-url origin "$git_url"
	fi

	if ! git_fetch_ref "$module_dir" "$module" "$ref"; then
		echo "failed to fetch pinned ref for module: $module" >&2
		exit 1
	fi

	if ! git -C "$module_dir" checkout --detach "$ref" >/dev/null 2>&1; then
		git -C "$module_dir" checkout --detach FETCH_HEAD >/dev/null
	fi

	if [ -n "$git_submodules" ]; then
		git -C "$module_dir" submodule sync --recursive || true
		git -C "$module_dir" submodule update --init --recursive
	fi
}

git_fetch_ref() {
	local module_dir="$1"
	local module="$2"
	local ref="$3"
	local attempt

	for attempt in 1 2 3; do
		if git -c http.version=HTTP/1.1 -c protocol.version=2 -C "$module_dir" \
			fetch --no-tags --depth 1 origin "$ref"; then
			return 0
		fi

		echo "retrying shallow fetch for module: $module (attempt $attempt/3)" >&2
		sleep "$attempt"
	done

	return 1
}

modules=()
while read -r module ref; do
	[ -n "$module" ] || continue
	case "$module" in
		\#*) continue
		;;
	esac
	modules+=("$module")
	fetch_module "$module" "$ref"
done < "$lock_file"

rm -rf "$workdir/dist/unix"
mkdir -p "$workdir/dist/unix"
"$workdir/libretro-build.sh" "${modules[@]}"

missing=0
while read -r module ref; do
	[ -n "$module" ] || continue
	case "$module" in
		\#*) continue
		;;
	esac

	eval "products=\${libretro_${module}_build_products:-$module}"
	found=0
	for product in $products; do
		if [ -f "$workdir/dist/unix/${product}_libretro.so" ]; then
			found=1
			break
		fi
	done

	if [ "$found" -ne 1 ]; then
		echo "missing built core output for module: $module" >&2
		missing=1
	fi

	if [ ! -f "$workdir/dist/info/${module}_libretro.info" ]; then
		echo "missing core info for module: $module" >&2
		missing=1
	fi
done < "$lock_file"

exit "$missing"
