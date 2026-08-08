#!/usr/bin/env python3
"""Guard the v0.15.39 Collaborator leaf against Window.mode shadowing."""

from __future__ import annotations

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parent.parent
COLLABORATOR = ROOT / "scripts" / "ui" / "character_collaborator_window_v01539.gd"
MAIN = ROOT / "scripts" / "main_v01539.gd"


def fail(message: str) -> int:
    print(f"V01539_HOTFIX1_REGRESSION_ERROR: {message}", file=sys.stderr)
    return 1


def main() -> int:
    collaborator = COLLABORATOR.read_text(encoding="utf-8")
    main_source = MAIN.read_text(encoding="utf-8")

    if re.search(r"(?m)^\s*var\s+mode\b", collaborator):
        return fail("The Collaborator leaf must not declare a local variable named 'mode'; Window already owns that property.")
    if re.search(
        r"func\s+_apply_card_ingestion_v01539\s*\([^)]*\bmode\s*:\s*String",
        collaborator,
        flags=re.S,
    ):
        return fail("_apply_card_ingestion_v01539 must not use a parameter named 'mode'.")
    if "var ingestion_mode :=" not in collaborator:
        return fail("The selected Character Card ingestion mode should use the non-shadowing ingestion_mode local.")
    if "candidate: Dictionary, ingestion_mode: String" not in collaborator:
        return fail("The Character Card ingestion helper should use the non-shadowing ingestion_mode parameter.")

    version_match = re.search(
        r'BUILD_DISPLAY_VERSION_V01539\s*:=\s*"0\.15\.39-hotfix(\d+)"',
        main_source,
    )
    if not version_match or int(version_match.group(1)) < 1:
        return fail("The running build must identify v0.15.39-hotfix1 or a later v0.15.39 hotfix.")

    print("v0.15.39-hotfix1 Collaborator Window.mode shadowing regression passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
