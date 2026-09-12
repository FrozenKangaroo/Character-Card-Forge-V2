#!/usr/bin/env python3
"""Validate the branded v0.19.1 startup splash and its project wiring."""

from __future__ import annotations

import struct
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
PROJECT_FILE = REPO_ROOT / "project.godot"
SPLASH_PATH = REPO_ROOT / "assets" / "branding" / "character_card_forge_splash_v0191.png"
EXPECTED_SIZE = (1600, 900)


def png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as stream:
        header = stream.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
        raise AssertionError(f"Splash is not a valid PNG: {path}")
    if header[12:16] != b"IHDR":
        raise AssertionError(f"Splash PNG has no leading IHDR chunk: {path}")
    return struct.unpack(">II", header[16:24])


def main() -> int:
    project_text = PROJECT_FILE.read_text(encoding="utf-8")
    required_settings = (
        "boot_splash/bg_color=Color(0.035, 0.039, 0.055, 1)",
        'boot_splash/image="res://assets/branding/character_card_forge_splash_v0191.png"',
        "boot_splash/fullsize=true",
        "boot_splash/show_image=true",
        "boot_splash/use_filter=true",
    )
    missing = [setting for setting in required_settings if setting not in project_text]
    if missing:
        raise AssertionError("Missing boot splash setting(s): " + ", ".join(missing))
    if not SPLASH_PATH.is_file():
        raise AssertionError(f"Configured splash image is missing: {SPLASH_PATH}")
    if png_size(SPLASH_PATH) != EXPECTED_SIZE:
        raise AssertionError(
            f"Splash must match the native {EXPECTED_SIZE[0]}x{EXPECTED_SIZE[1]} viewport; "
            f"found {png_size(SPLASH_PATH)[0]}x{png_size(SPLASH_PATH)[1]}."
        )
    if SPLASH_PATH.stat().st_size > 2 * 1024 * 1024:
        raise AssertionError("Splash image exceeds the 2 MiB startup-asset budget.")
    print("V0191_SPLASH_SCREEN_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
