#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path


SDL_MAPPING = {
    "b": "a",
    "a": "b",
    "x": "y",
    "y": "x",
    "l2": "lefttrigger",
    "r2": "righttrigger",
    "l3": "leftstick",
    "r3": "rightstick",
    "pageup": "leftshoulder",
    "pagedown": "rightshoulder",
    "start": "start",
    "select": "back",
    "up": "dpup",
    "down": "dpdown",
    "left": "dpleft",
    "right": "dpright",
    "joystick1up": "lefty",
    "joystick1left": "leftx",
    "joystick2up": "righty",
    "joystick2left": "rightx",
    "hotkey": "guide",
}

RETROARCH_DIGITAL = {
    "b": "input_b",
    "a": "input_a",
    "y": "input_y",
    "x": "input_x",
    "pageup": "input_l",
    "pagedown": "input_r",
    "l2": "input_l2",
    "r2": "input_r2",
    "l3": "input_l3",
    "r3": "input_r3",
    "start": "input_start",
    "select": "input_select",
    "up": "input_up",
    "down": "input_down",
    "left": "input_left",
    "right": "input_right",
}

RETROARCH_ANALOG = {
    "joystick1left": "input_l_x",
    "joystick1up": "input_l_y",
    "joystick2left": "input_r_x",
    "joystick2up": "input_r_y",
}

HAT_DIR = {
    "1": "up",
    "2": "right",
    "4": "down",
    "8": "left",
}


def normalize_name(name: str) -> str:
    return " ".join(name.split()).strip()


def safe_stem(name: str) -> str:
    stem = normalize_name(name)
    stem = stem.replace("/", "_").replace("\\", "_")
    stem = re.sub(r"[^0-9A-Za-z._ +()-]+", "_", stem)
    stem = stem.strip(" .")
    if not stem:
        stem = "controller"
    return stem


def make_filename(name: str, suffix: str | None = None) -> str:
    stem = safe_stem(name)
    if suffix:
        stem = f"{stem}__{safe_stem(suffix)}"
    return stem + ".cfg"


def parse_vid_pid(guid: str) -> tuple[str, str]:
    if not re.fullmatch(r"[0-9a-fA-F]{32}", guid):
        return "", ""

    vendor_chunk = guid[8:16]
    product_chunk = guid[16:24]

    vendor = (vendor_chunk[2:4] + vendor_chunk[0:2]).lower()
    product = (product_chunk[2:4] + product_chunk[0:2]).lower()

    if vendor == "0000":
        vendor = ""
    if product == "0000":
        product = ""

    return vendor, product


def retroarch_binding(input_type: str, input_id: str, value: str) -> tuple[str, str] | None:
    if input_type == "button":
        return "btn", input_id
    if input_type == "hat":
        return "btn", f"h{input_id}{HAT_DIR.get(value, '')}"
    if input_type == "axis":
        sign = "-" if value == "-1" else "+"
        return "axis", f"{sign}{input_id}"
    if input_type == "key":
        return "key", input_id
    return None


def sdl_binding(name: str, input_type: str, input_id: str, value: str) -> str | None:
    key_name = SDL_MAPPING.get(name)
    if not key_name:
        return None

    if input_type == "button":
        return f"{key_name}:b{input_id}"

    if input_type == "hat":
        return f"{key_name}:h{input_id}.{value}"

    if input_type == "axis":
        if "joystick" in name:
            return f"{key_name}:a{input_id}{'~' if int(value) > 0 else ''}"
        if key_name in {"dpup", "dpdown", "dpleft", "dpright"}:
            return f"{key_name}:{'-' if int(value) < 0 else '+'}a{input_id}"
        if "trigger" in key_name:
            return f"{key_name}:a{input_id}{'~' if int(value) < 0 else ''}"
        return f"{key_name}:a{input_id}"

    return None


def add_retroarch_digital(config: dict[str, str], prefix: str, input_type: str, input_id: str, value: str) -> None:
    binding = retroarch_binding(input_type, input_id, value)
    if not binding:
        return

    bind_type, bind_value = binding
    config[f"{prefix}_{bind_type}"] = bind_value


def add_retroarch_hotkey_binding(config: dict[str, str], input_type: str, input_id: str, value: str) -> None:
    binding = retroarch_binding(input_type, input_id, value)
    if not binding:
        return

    bind_type, bind_value = binding
    config[f"input_enable_hotkey_{bind_type}"] = bind_value


def add_retroarch_analog(config: dict[str, str], prefix: str, input_id: str, value: str) -> None:
    if value == "-1":
        config[f"{prefix}_minus_axis"] = f"-{input_id}"
        config[f"{prefix}_plus_axis"] = f"+{input_id}"
    else:
        config[f"{prefix}_minus_axis"] = f"+{input_id}"
        config[f"{prefix}_plus_axis"] = f"-{input_id}"


def generate_autoconfig(element: ET.Element) -> tuple[str, str, str, str, str, str]:
    device_name = element.attrib["deviceName"]
    lookup_name = normalize_name(device_name)
    guid = element.attrib.get("deviceGUID", "")
    vendor, product = parse_vid_pid(guid)

    config: dict[str, str] = {
        "input_driver": '"udev"',
        "input_device": f'"{device_name}"',
    }

    if vendor:
        config["input_vendor_id"] = f'"{int(vendor, 16)}"'
    if product:
        config["input_product_id"] = f'"{int(product, 16)}"'

    sdl_bindings: list[str] = []

    for input_element in element.findall("input"):
        name = input_element.attrib.get("name", "")
        input_type = input_element.attrib.get("type", "")
        input_id = input_element.attrib.get("id", "")
        value = input_element.attrib.get("value", "1")

        if name in RETROARCH_DIGITAL:
            add_retroarch_digital(config, RETROARCH_DIGITAL[name], input_type, input_id, value)
        elif name in RETROARCH_ANALOG and input_type == "axis":
            add_retroarch_analog(config, RETROARCH_ANALOG[name], input_id, value)
        elif name == "hotkey":
            add_retroarch_hotkey_binding(config, input_type, input_id, value)

        sdl_value = sdl_binding(name, input_type, input_id, value)
        if sdl_value:
            sdl_bindings.append(sdl_value)

    ordered_keys = [
        "input_driver",
        "input_device",
        "input_vendor_id",
        "input_product_id",
        "input_b_btn",
        "input_b_axis",
        "input_y_btn",
        "input_y_axis",
        "input_select_btn",
        "input_select_axis",
        "input_start_btn",
        "input_start_axis",
        "input_up_btn",
        "input_up_axis",
        "input_down_btn",
        "input_down_axis",
        "input_left_btn",
        "input_left_axis",
        "input_right_btn",
        "input_right_axis",
        "input_a_btn",
        "input_a_axis",
        "input_x_btn",
        "input_x_axis",
        "input_l_btn",
        "input_l_axis",
        "input_r_btn",
        "input_r_axis",
        "input_l2_btn",
        "input_l2_axis",
        "input_r2_btn",
        "input_r2_axis",
        "input_l3_btn",
        "input_l3_axis",
        "input_r3_btn",
        "input_r3_axis",
        "input_l_x_plus_axis",
        "input_l_x_minus_axis",
        "input_l_y_plus_axis",
        "input_l_y_minus_axis",
        "input_r_x_plus_axis",
        "input_r_x_minus_axis",
        "input_r_y_plus_axis",
        "input_r_y_minus_axis",
        "input_enable_hotkey_btn",
        "input_enable_hotkey_axis",
    ]

    lines = ["# Generated from Batocera es_input.cfg", ""]
    seen = set()
    for key in ordered_keys:
        if key in config:
            lines.append(f"{key} = {config[key]}")
            seen.add(key)

    for key in sorted(config):
        if key not in seen:
            lines.append(f"{key} = {config[key]}")

    sdl_line = ",".join([guid.lower(), device_name.replace(",", "."), "platform:Linux", *sdl_bindings, ""])
    return device_name, lookup_name, guid.lower(), vendor, product, "\n".join(lines) + "\n", sdl_line


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--es-input", required=True)
    parser.add_argument("--autoconfig-dir", required=True)
    parser.add_argument("--index", required=True)
    parser.add_argument("--sdl-db", required=True)
    args = parser.parse_args()

    es_input = Path(args.es_input)
    autoconfig_dir = Path(args.autoconfig_dir)
    index_file = Path(args.index)
    sdl_db_file = Path(args.sdl_db)

    autoconfig_dir.mkdir(parents=True, exist_ok=True)
    root = ET.parse(es_input).getroot()

    index_lines = ["filename\tguid\tvendor\tproduct\tdevice_name\tlookup_name"]
    sdl_lines: list[str] = []
    generated_entries: list[dict[str, str]] = []

    for index, element in enumerate(root.findall("inputConfig"), start=1):
        if element.attrib.get("type") != "joystick":
            continue

        device_name, lookup_name, guid, vendor, product, autoconfig_text, sdl_line = generate_autoconfig(element)
        generated_entries.append({
            "device_name": device_name,
            "lookup_name": lookup_name,
            "guid": guid,
            "vendor": vendor,
            "product": product,
            "autoconfig_text": autoconfig_text,
            "sdl_line": sdl_line,
            "base_filename": make_filename(lookup_name or device_name),
            "ordinal": str(index),
        })

    base_counts = Counter(entry["base_filename"] for entry in generated_entries)
    used_filenames: set[str] = set()

    for entry in generated_entries:
        filename = entry["base_filename"]
        if base_counts[filename] > 1:
            suffix = (
                entry["guid"]
                or "_".join(part for part in (entry["vendor"], entry["product"]) if part)
                or f"profile_{entry['ordinal']}"
            )
            filename = make_filename(entry["lookup_name"] or entry["device_name"], suffix)

        collision_index = 2
        while filename in used_filenames:
            filename = make_filename(
                entry["lookup_name"] or entry["device_name"],
                f"{entry['guid'] or entry['ordinal']}_{collision_index}",
            )
            collision_index += 1

        used_filenames.add(filename)
        (autoconfig_dir / filename).write_text(entry["autoconfig_text"], encoding="utf-8")
        index_lines.append(
            f"{filename}\t{entry['guid']}\t{entry['vendor']}\t{entry['product']}\t"
            f"{entry['device_name']}\t{entry['lookup_name']}"
        )
        sdl_lines.append(entry["sdl_line"])

    index_file.write_text("\n".join(index_lines) + "\n", encoding="utf-8")
    sdl_db_file.write_text("\n".join(sdl_lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
