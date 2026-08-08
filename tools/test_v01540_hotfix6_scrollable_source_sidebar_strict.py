#!/usr/bin/env python3
from __future__ import annotations

import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

REPO_ROOT = Path(__file__).resolve().parent.parent
SUCCESS_MARKER = "v0.15.40-hotfix6 scrollable source sidebar regression passed"
ERROR_PATTERNS = (
    re.compile(r"SCRIPT ERROR:", re.IGNORECASE),
    re.compile(r"Assertion failed", re.IGNORECASE),
    re.compile(r"V01540_HOTFIX6_SIDEBAR_ERROR", re.IGNORECASE),
    re.compile(r"Failed to load script", re.IGNORECASE),
    re.compile(r"Parse Error", re.IGNORECASE),
    re.compile(r"Invalid access", re.IGNORECASE),
    re.compile(r"Invalid call", re.IGNORECASE),
    re.compile(r"SHADOWED_VARIABLE_BASE_CLASS", re.IGNORECASE),
    re.compile(r"CONFUSABLE_LOCAL_DECLARATION", re.IGNORECASE),
    re.compile(r"INCOMPATIBLE_TERNARY", re.IGNORECASE),
)


def resolve_godot() -> str:
    for candidate in (os.environ.get("GODOT_BIN"), shutil.which("godot"), shutil.which("godot4")):
        if candidate:
            return candidate
    raise RuntimeError("Godot was not found in GODOT_BIN or PATH.")


def isolated_environment(root: Path) -> dict[str, str]:
    env = os.environ.copy()
    for name in ("home", "xdg-data", "xdg-config", "xdg-cache", "appdata", "localappdata"):
        (root / name).mkdir(parents=True, exist_ok=True)
    env.update({
        "HOME": str(root / "home"),
        "XDG_DATA_HOME": str(root / "xdg-data"),
        "XDG_CONFIG_HOME": str(root / "xdg-config"),
        "XDG_CACHE_HOME": str(root / "xdg-cache"),
        "APPDATA": str(root / "appdata"),
        "LOCALAPPDATA": str(root / "localappdata"),
        "CCF_REGRESSION_RUN": "1",
    })
    return env


def main() -> int:
    try:
        godot = resolve_godot()
    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2
    command = [
        godot,
        "--headless",
        "--path",
        str(REPO_ROOT),
        "--script",
        "res://tools/test_v01540_hotfix6_scrollable_source_sidebar.gd",
    ]
    with tempfile.TemporaryDirectory(prefix="ccf-v01540-hotfix6-sidebar-") as tmp:
        try:
            completed = subprocess.run(
                command,
                cwd=REPO_ROOT,
                env=isolated_environment(Path(tmp)),
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=240,
                check=False,
            )
        except subprocess.TimeoutExpired as exc:
            output = exc.stdout.decode(errors="replace") if isinstance(exc.stdout, bytes) else (exc.stdout or "")
            if output:
                print(output, end="" if output.endswith("\n") else "\n")
            print("ERROR: v0.15.40-hotfix6 sidebar regression timed out.", file=sys.stderr)
            return 124
    output = completed.stdout or ""
    if output:
        print(output, end="" if output.endswith("\n") else "\n")
    if completed.returncode != 0:
        return completed.returncode
    matched = [pattern.pattern for pattern in ERROR_PATTERNS if pattern.search(output)]
    if matched:
        print("ERROR: forbidden regression output: " + ", ".join(matched), file=sys.stderr)
        return 1
    if SUCCESS_MARKER not in output:
        print("ERROR: success marker missing.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
