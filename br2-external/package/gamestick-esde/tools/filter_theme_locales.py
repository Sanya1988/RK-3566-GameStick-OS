#!/usr/bin/env python3
import argparse
import os
import xml.etree.ElementTree as ET


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--keep", action="append", dest="keep", required=True)
    parser.add_argument("--theme-dir", action="append", dest="theme_dirs", required=True)
    return parser.parse_args()


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


def prune_labels(node, keep_languages):
    for child in list(node):
        prune_labels(child, keep_languages)
        if child.tag != "label":
            continue
        language = child.attrib.get("language")
        if language and language not in keep_languages:
            node.remove(child)


def filter_capabilities(path, keep_languages):
    if not os.path.isfile(path):
        return

    tree = ET.parse(path)
    root = tree.getroot()
    if root.tag != "themeCapabilities":
        return

    for child in list(root):
        if child.tag == "language":
            language = (child.text or "").strip()
            if language not in keep_languages:
                root.remove(child)
            continue
        prune_labels(child, keep_languages)

    indent(root)
    tree.write(path, encoding="utf-8", xml_declaration=False)


def filter_languages(path, keep_languages):
    if not os.path.isfile(path):
        return

    tree = ET.parse(path)
    root = tree.getroot()
    if root.tag != "theme":
        return

    for child in list(root):
        if child.tag != "language":
            continue
        if child.attrib.get("name") not in keep_languages:
            root.remove(child)

    indent(root)
    tree.write(path, encoding="utf-8", xml_declaration=False)


def main():
    args = parse_args()
    keep_languages = set(args.keep)
    keep_languages.add("en_US")

    for theme_dir in args.theme_dirs:
        filter_capabilities(f"{theme_dir}/capabilities.xml", keep_languages)
        filter_languages(f"{theme_dir}/languages.xml", keep_languages)


if __name__ == "__main__":
    main()
