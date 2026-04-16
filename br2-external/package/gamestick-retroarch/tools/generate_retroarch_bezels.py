#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import shutil
from pathlib import Path

SYSTEM_ASSET_MAP = {
    "arcade": "fbneo.png",
    "neogeo": "neogeo.png",
    "nes": "nes.png",
    "famicom": "nes.png",
    "fds": "fds.png",
    "snes": "snes.png",
    "sfc": "snes.png",
    "gb": "gb.png",
    "gbc": "gbc.png",
    "gba": "gba.png",
    "mastersystem": "mastersystem.png",
    "gamegear": "gamegear.png",
    "megadrive": "megadrive.png",
    "genesis": "megadrive.png",
    "segacd": "megacd.png",
    "megacd": "megacd.png",
    "pcengine": "pcengine.png",
    "tg16": "pcengine.png",
    "pcenginecd": "pcenginecd.png",
    "tg-cd": "pcenginecd.png",
    "ngp": "ngp.png",
    "ngpc": "ngpc.png",
    "wonderswan": "wswan.png",
    "wonderswancolor": "wswanc.png",
    "psx": "psx.png",
    "dos": "dos.png",
    "amiga": "amiga500.png",
    "amigacd32": "amigacd32.png",
    "msx": "msx.png",
    "msx2": "msx2.png",
    "c64": "c64.png",
}


def overlay_cfg_text(system_name: str) -> str:
    return "\n".join(
        (
            "overlays = 1",
            "",
            f'overlay0_overlay = "images/{system_name}.png"',
            "overlay0_full_screen = true",
            "overlay0_normalized = true",
            "overlay0_descs = 1",
            'overlay0_desc0 = "nul,0.500000,0.500000,rect,0.001000,0.001000"',
            "",
        )
    )


def system_bezel_cfg_text(system_name: str) -> str:
    return "\n".join(
        (
            'input_overlay_enable = "true"',
            'input_overlay_hide_in_menu = "true"',
            'input_overlay_hide_when_gamepad_connected = "false"',
            'input_overlay_behind_menu = "true"',
            f'input_overlay = "/usr/share/gamestick/retroarch-defaults/overlays/{system_name}.cfg"',
            "",
        )
    )


def iter_systems(tsv_path: Path) -> list[str]:
    systems: list[str] = []
    with tsv_path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.reader(handle, delimiter="\t")
        for row in reader:
            if not row or row[0].startswith("#"):
                continue
            system_name = row[0].strip()
            if system_name:
                systems.append(system_name)
    return systems


def create_assets(
    systems_tsv: Path,
    asset_dir: Path,
    overlay_dir: Path,
    overlay_image_dir: Path,
    system_bezel_dir: Path,
) -> None:
    overlay_dir.mkdir(parents=True, exist_ok=True)
    overlay_image_dir.mkdir(parents=True, exist_ok=True)
    system_bezel_dir.mkdir(parents=True, exist_ok=True)

    for system_name in iter_systems(systems_tsv):
        asset_name = SYSTEM_ASSET_MAP.get(system_name)
        if not asset_name:
            raise FileNotFoundError(f"no Batocera bezel mapping configured for system '{system_name}'")

        asset_path = asset_dir / asset_name
        if not asset_path.is_file():
            raise FileNotFoundError(f"missing Batocera bezel asset: {asset_path}")

        shutil.copy2(asset_path, overlay_image_dir / f"{system_name}.png")
        (overlay_dir / f"{system_name}.cfg").write_text(overlay_cfg_text(system_name), encoding="utf-8")
        (system_bezel_dir / f"{system_name}.cfg").write_text(
            system_bezel_cfg_text(system_name), encoding="utf-8"
        )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--systems-tsv", required=True)
    parser.add_argument("--asset-dir", required=True)
    parser.add_argument("--overlay-dir", required=True)
    parser.add_argument("--overlay-image-dir", required=True)
    parser.add_argument("--system-bezel-dir", required=True)
    args = parser.parse_args()

    create_assets(
        Path(args.systems_tsv),
        Path(args.asset_dir),
        Path(args.overlay_dir),
        Path(args.overlay_image_dir),
        Path(args.system_bezel_dir),
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
