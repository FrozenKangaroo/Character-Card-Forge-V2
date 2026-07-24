#!/usr/bin/env python3
"""Validate release metadata and data files without changing the project."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SEMVER_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:[-+][0-9A-Za-z.-]+)?$")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"Validation failed: {message}")


def read_match(path: Path, pattern: str, label: str) -> str:
    text = path.read_text(encoding="utf-8")
    match = re.search(pattern, text, flags=re.MULTILINE)
    require(match is not None, f"Could not find {label} in {path.relative_to(ROOT)}.")
    return match.group(1)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--tag",
        default="",
        help="Optional release tag to compare with VERSION, for example v0.9.2",
    )
    args = parser.parse_args()

    required_paths = [
        "project.godot",
        "export_presets.cfg",
        "scenes/main.tscn",
        "scripts/main.gd",
        "VERSION",
        ".github/workflows/validate.yml",
        ".github/workflows/release.yml",
    ]
    for relative in required_paths:
        require((ROOT / relative).is_file(), f"Missing required file: {relative}")

    version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    require(bool(SEMVER_RE.fullmatch(version)), f"VERSION is not semantic: {version!r}")

    discovered = {
        "project.godot": read_match(
            ROOT / "project.godot", r'^config/version="([^"]+)"$', "application version"
        ),
        "scripts/main.gd": read_match(
            ROOT / "scripts/main.gd", r'^const APP_VERSION := "([^"]+)"$', "APP_VERSION"
        ),
        "project_package_service.gd": read_match(
            ROOT / "scripts/services/project_package_service.gd",
            r'^\s*"application_version":\s*"([^"]+)"',
            "package application version",
        ),
        "series_service.gd": read_match(
            ROOT / "scripts/services/series_service.gd",
            r'^\s*"application_version":\s*"([^"]+)"',
            "series-pack application version",
        ),
    }
    for source, source_version in discovered.items():
        require(
            source_version == version,
            f"{source} reports {source_version}, but VERSION reports {version}.",
        )

    preset_text = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
    for preset_name in ("Windows Desktop", "Linux x86_64", "macOS Universal"):
        require(f'name="{preset_name}"' in preset_text, f"Missing export preset {preset_name}.")
    require(
        preset_text.count(f'application/file_version="{version}"') == 1,
        "Windows file version is not synchronised.",
    )
    require(
        preset_text.count(f'application/product_version="{version}"') == 1,
        "Windows product version is not synchronised.",
    )
    require(
        preset_text.count(f'application/short_version="{version}"') == 1,
        "macOS short version is not synchronised.",
    )
    require(
        preset_text.count(f'application/version="{version}"') == 1,
        "macOS build version is not synchronised.",
    )

    json_files = sorted((ROOT / "data").rglob("*.json"))
    require(bool(json_files), "No bundled JSON data files were found.")
    for json_path in json_files:
        try:
            json.loads(json_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
            raise SystemExit(
                f"Validation failed: invalid JSON in {json_path.relative_to(ROOT)}: {error}"
            ) from error

    if args.tag:
        expected_tag = f"v{version}"
        require(
            args.tag == expected_tag,
            f"Release tag {args.tag!r} does not match VERSION ({expected_tag}).",
        )

    print(
        f"Validated Character Card Forge v{version}: "
        f"version metadata, three export presets, and {len(json_files)} JSON files."
    )


if __name__ == "__main__":
    main()
