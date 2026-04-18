#!/bin/sh

copy_tree_into() {
	src=$1
	dst=$2

	[ -d "$src" ] || return 0
	mkdir -p "$dst"

	# exFAT does not preserve Unix ownership and permission metadata.
	cp -R "$src/." "$dst/"
}

copy_cfg_files_if_missing() {
	src_dir=$1
	dst_dir=$2

	[ -d "$src_dir" ] || return 0
	mkdir -p "$dst_dir"

	find "$src_dir" -maxdepth 1 -type f -name '*.cfg' | while IFS= read -r src; do
		dst="$dst_dir/$(basename "$src")"
		[ -e "$dst" ] || cp -f "$src" "$dst"
	done
}

create_esde_rom_dirs() {
	systems_xml=$1
	roms_dir=$2

	[ -f "$systems_xml" ] || return 0
	mkdir -p "$roms_dir"

	sed -n 's:.*<path>%ROMPATH%/\([^<]*\)</path>.*:\1:p' "$systems_xml" | \
	while IFS= read -r rel_path; do
		[ -n "$rel_path" ] || continue
		mkdir -p "$roms_dir/$rel_path"
	done
}

seed_userdata_from_root() {
	root_dir=${1%/}
	userdata_dir=${2%/}

	mkdir -p \
		"$userdata_dir/roms" \
		"$userdata_dir/screensaver" \
		"$userdata_dir/music" \
		"$userdata_dir/bios" \
		"$userdata_dir/esde" \
		"$userdata_dir/esde/settings" \
		"$userdata_dir/esde/custom_systems" \
		"$userdata_dir/esde/resources" \
		"$userdata_dir/esde/scripts" \
		"$userdata_dir/esde/themes" \
		"$userdata_dir/esde/gamelists" \
		"$userdata_dir/esde/downloaded_media" \
		"$userdata_dir/system" \
		"$userdata_dir/system/input" \
		"$userdata_dir/system/input/profiles" \
		"$userdata_dir/system/input/profiles/udev" \
		"$userdata_dir/system/input/overrides/udev" \
		"$userdata_dir/system/input/quirks" \
		"$userdata_dir/system/logs" \
		"$userdata_dir/retroarch/cores" \
		"$userdata_dir/retroarch/info" \
		"$userdata_dir/retroarch/autoconfig" \
		"$userdata_dir/retroarch/autoconfig/udev" \
		"$userdata_dir/retroarch/config/retroarch" \
		"$userdata_dir/retroarch/config/retroarch/gamestick" \
		"$userdata_dir/retroarch/config/retroarch/gamestick/overrides" \
		"$userdata_dir/retroarch/config/retroarch/gamestick/overrides/systems" \
		"$userdata_dir/retroarch/config/retroarch/gamestick/overrides/cores" \
		"$userdata_dir/retroarch/config/retroarch/gamestick/overrides/games" \
		"$userdata_dir/retroarch/database/rdb" \
		"$userdata_dir/retroarch/cheats" \
		"$userdata_dir/retroarch/filters/video" \
		"$userdata_dir/retroarch/filters/audio" \
		"$userdata_dir/retroarch/shaders" \
		"$userdata_dir/retroarch/overlays" \
		"$userdata_dir/retroarch/playlists" \
		"$userdata_dir/retroarch/thumbnails" \
		"$userdata_dir/retroarch/remaps" \
		"$userdata_dir/retroarch/saves" \
		"$userdata_dir/retroarch/states" \
		"$userdata_dir/retroarch/screenshots" \
		"$userdata_dir/retroarch/home" \
		"$userdata_dir/retroarch/cache" \
		"$userdata_dir/retroarch/share" \
		"$userdata_dir/retroarch/system"

	copy_tree_into "$root_dir/usr/share/gamestick/retroarch-seed/cores" \
		"$userdata_dir/retroarch/cores"
	copy_tree_into "$root_dir/usr/share/gamestick/retroarch-seed/info" \
		"$userdata_dir/retroarch/info"
	copy_tree_into "$root_dir/usr/share/gamestick/retroarch-seed/cheats" \
		"$userdata_dir/retroarch/cheats"
	copy_tree_into "$root_dir/usr/share/gamestick/retroarch-seed/bios" \
		"$userdata_dir/bios"
	copy_tree_into "$root_dir/usr/share/gamestick/roms-seed" \
		"$userdata_dir/roms"
	copy_tree_into "$root_dir/usr/share/gamestick/screensaver-seed" \
		"$userdata_dir/screensaver"
	copy_tree_into "$root_dir/usr/share/gamestick/music-seed" \
		"$userdata_dir/music"
	copy_tree_into "$root_dir/usr/share/gamestick/esde-seed/settings" \
		"$userdata_dir/esde/settings"
	copy_tree_into "$root_dir/usr/share/gamestick/esde-seed/custom_systems" \
		"$userdata_dir/esde/custom_systems"
	copy_tree_into "$root_dir/usr/share/gamestick/esde-seed/resources" \
		"$userdata_dir/esde/resources"
	copy_tree_into "$root_dir/usr/share/gamestick/esde-seed/scripts" \
		"$userdata_dir/esde/scripts"
	copy_tree_into "$root_dir/usr/share/gamestick/esde-seed/themes" \
		"$userdata_dir/esde/themes"
	copy_tree_into "$root_dir/usr/share/gamestick/esde-seed/downloaded_media" \
		"$userdata_dir/esde/downloaded_media"

	copy_cfg_files_if_missing \
		"$root_dir/usr/share/gamestick/input/retroarch-autoconfig/udev" \
		"$userdata_dir/retroarch/autoconfig/udev"
	copy_cfg_files_if_missing \
		"$root_dir/usr/share/retroarch/autoconfig/udev" \
		"$userdata_dir/retroarch/autoconfig/udev"

	create_esde_rom_dirs \
		"$root_dir/usr/share/gamestick/esde-seed/custom_systems/es_systems.xml" \
		"$userdata_dir/roms"

	: >"$userdata_dir/esde/.gamestick_settings_seed_v1"
	: >"$userdata_dir/esde/.gamestick_custom_systems_v4"
	: >"$userdata_dir/esde/.gamestick_themes_v4"
	: >"$userdata_dir/esde/.gamestick_resources_v2"
	: >"$userdata_dir/esde/.gamestick_scripts_v2"
	: >"$userdata_dir/esde/.gamestick_downloaded_media_v1"
	: >"$userdata_dir/music/.gamestick_music_seed_v1"
	: >"$userdata_dir/roms/.gamestick_roms_seed_v1"
	: >"$userdata_dir/screensaver/.gamestick_screensaver_seed_v1"
	: >"$userdata_dir/retroarch/config/retroarch/.gamestick_userdata_seed_v5"
	sync
}
