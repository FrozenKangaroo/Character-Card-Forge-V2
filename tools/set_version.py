#!/usr/bin/env python3
"""Synchronise Character Card Forge application version strings."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SEMVER_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:[-+][0-9A-Za-z.-]+)?$")


class VersionSyncError(RuntimeError):
    """Raised when a required version marker cannot be updated safely."""


def replace_once(path: Path, pattern: str, replacement: str) -> None:
    text = path.read_text(encoding="utf-8")
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.MULTILINE)
    if count != 1:
        raise VersionSyncError(f"Expected one version marker in {path}, found {count}.")
    path.write_text(updated, encoding="utf-8")


def replace_all_expected(path: Path, pattern: str, replacement: str, expected: int) -> None:
    text = path.read_text(encoding="utf-8")
    updated, count = re.subn(pattern, replacement, text, flags=re.MULTILINE)
    if count != expected:
        raise VersionSyncError(
            f"Expected {expected} version markers in {path}, found {count}."
        )
    path.write_text(updated, encoding="utf-8")


def sync_version(version: str) -> None:
    if not SEMVER_RE.fullmatch(version):
        raise VersionSyncError(
            "Version must use semantic versioning, for example 1.2.3 or 1.0.0-beta.1."
        )

    (ROOT / "VERSION").write_text(f"{version}\n", encoding="utf-8")

    replace_once(
        ROOT / "project.godot",
        r'^config/version="[^"]+"$',
        f'config/version="{version}"',
    )
    replace_once(
        ROOT / "scripts/main.gd",
        r'^const APP_VERSION := "[^"]+"$',
        f'const APP_VERSION := "{version}"',
    )
    replace_once(
        ROOT / "scripts/services/project_package_service.gd",
        r'^(\s*"application_version":\s*)"[^"]+"(,?)$',
        rf'\1"{version}"\2',
    )
    replace_once(
        ROOT / "scripts/services/series_service.gd",
        r'^(\s*"application_version":\s*)"[^"]+"(,?)$',
        rf'\1"{version}"\2',
    )

    replace_all_expected(
        ROOT / "export_presets.cfg",
        r'^(application/(?:file_version|product_version|short_version|version))="[^"]*"$',
        rf'\1="{version}"',
        expected=4,
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version", help="Semantic application version, without a leading v")
    args = parser.parse_args()

    try:
        sync_version(args.version.strip())
    except VersionSyncError as error:
        raise SystemExit(f"Version sync failed: {error}") from error

    print(f"Character Card Forge version synchronised to {args.version.strip()}.")
