#!/usr/bin/env python3
import argparse
import copy
import csv
import os
import re
import sys
import xml.etree.ElementTree as ET


CORE_RE = re.compile(r"%CORE_RETROARCH%/([A-Za-z0-9_.+-]+)_libretro\.so")
SYSTEM_EXTENSION_OVERRIDES = {
    "psx": ".ccd .CCD .chd .CHD .cue .CUE .ecm .ECM .exe .EXE .img .IMG .iso .ISO .m3u .M3U .mdf .MDF .mds .MDS .minipsf .MINIPSF .pbp .PBP .psexe .PSEXE .psf .PSF .toc .TOC .z .Z .znx .ZNX .7z .7Z .zip .ZIP",
}


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--upstream", required=True)
    parser.add_argument("--whitelist", required=True)
    parser.add_argument("--active-cores", dest="active_cores")
    parser.add_argument("--cores-lock", dest="active_cores", help=argparse.SUPPRESS)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    if not args.active_cores:
        parser.error("--active-cores is required")
    return args


def read_active_cores(path):
    active = set()
    if os.path.isdir(path):
        for entry in os.listdir(path):
            if not entry.endswith("_libretro.so"):
                continue
            active.add(entry[: -len("_libretro.so")])
        return active

    with open(path, "r", encoding="utf-8") as handle:
        for raw_line in handle:
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            active.add(line.split()[0])
    return active


def read_whitelist(path):
    systems = []
    with open(path, "r", encoding="utf-8") as handle:
        reader = csv.reader(handle, delimiter="\t")
        for row in reader:
            if not row or row[0].startswith("#"):
                continue
            if len(row) < 4:
                raise SystemExit(f"Invalid whitelist row: {row!r}")
            name, group_name, allowed_cores, status = row[:4]
            if status != "enabled":
                continue
            allowed = [item for item in allowed_cores.split("|") if item]
            systems.append(
                {
                    "name": name,
                    "group": group_name,
                    "allowed": set(allowed),
                    "allowed_ordered": allowed,
                }
            )
    return systems


def indent(elem, level=0):
    prefix = "\n" + level * "    "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = prefix + "    "
        for child in elem:
            indent(child, level + 1)
        if not child.tail or not child.tail.strip():
            child.tail = prefix
    elif level and (not elem.tail or not elem.tail.strip()):
        elem.tail = prefix


def extract_core_name(command_text):
    match = CORE_RE.search(command_text or "")
    if not match:
        return None
    return match.group(1)


def filter_commands(system_elem, active_cores, allowed_cores, allowed_order):
    order_map = {core_name: idx for idx, core_name in enumerate(allowed_order)}
    selected = []
    for command in system_elem.findall("command"):
        text = command.text or ""
        if "%EMULATOR_RETROARCH%" not in text:
            continue
        core_name = extract_core_name(text)
        if not core_name:
            continue
        if core_name not in active_cores:
            continue
        if core_name not in allowed_cores:
            continue
        selected.append((order_map.get(core_name, len(order_map)), copy.deepcopy(command)))
    selected.sort(key=lambda item: item[0])
    return [command for _, command in selected]


def apply_system_overrides(system_elem, system_name):
    extension_override = SYSTEM_EXTENSION_OVERRIDES.get(system_name)
    if not extension_override:
        return

    extension_elem = system_elem.find("extension")
    if extension_elem is not None:
        extension_elem.text = extension_override


def main():
    args = parse_args()
    active_cores = read_active_cores(args.active_cores)
    whitelist = read_whitelist(args.whitelist)

    upstream_tree = ET.parse(args.upstream)
    upstream_root = upstream_tree.getroot()
    if upstream_root.tag != "systemList":
        raise SystemExit("Upstream es_systems.xml does not have <systemList> root")

    upstream_by_name = {}
    for system in upstream_root.findall("system"):
        name = system.findtext("name", default="").strip()
        if name:
            upstream_by_name[name] = system

    output_root = ET.Element("systemList")

    for entry in whitelist:
        source_system = upstream_by_name.get(entry["name"])
        if source_system is None:
            print(f"Missing upstream system definition: {entry['name']}", file=sys.stderr)
            continue

        new_system = copy.deepcopy(source_system)
        for command in list(new_system.findall("command")):
            new_system.remove(command)

        filtered_commands = filter_commands(
            source_system,
            active_cores,
            entry["allowed"],
            entry["allowed_ordered"],
        )
        if not filtered_commands:
            print(
                f"Skipping {entry['name']}: no RetroArch commands left after filtering",
                file=sys.stderr,
            )
            continue

        apply_system_overrides(new_system, entry["name"])

        insert_at = 0
        for idx, child in enumerate(list(new_system)):
            if child.tag == "extension":
                insert_at = idx + 1
                break
        for offset, command in enumerate(filtered_commands):
            new_system.insert(insert_at + offset, command)

        output_root.append(new_system)

    output_root.insert(0, ET.Element("loadExclusive"))
    indent(output_root)

    tree = ET.ElementTree(output_root)
    with open(args.output, "wb") as handle:
        handle.write(b'<?xml version="1.0"?>\n')
        tree.write(handle, encoding="utf-8")
        handle.write(b"\n")


if __name__ == "__main__":
    main()
