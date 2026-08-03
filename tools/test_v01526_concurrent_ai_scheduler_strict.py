#!/usr/bin/env python3
"""Run the v0.15.26 Godot regression and fail on logged script/assert errors.

Godot can occasionally return exit code zero after a GDScript assertion or script
load failure. This wrapper makes those diagnostics authoritative for CI and the
broad regression registry.
"""

from __future__ import annotations

import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


REPO_ROOT = Path(__file__).resolve().parent.parent
ERROR_PATTERNS = (
    re.compile(r"SCRIPT ERROR:\s*(?:Parse Error|Compile Error)", re.IGNORECASE),
    re.compile(r"Failed to load script", re.IGNORECASE),
    re.compile(r"Assertion failed", re.IGNORECASE),
    re.compile(r"v0\.15\.26.*(?:must|should|need|cannot|could not)", re.IGNORECASE),
)
SUCCESS_MARKER = "v0.15.26 concurrent AI scheduler regression passed"


def resolve_godot() -> str:
    for candidate in (
        os.environ.get("GODOT_BIN"),
        shutil.which("godot"),
        shutil.which("godot4"),
    ):
        if candidate:
            return candidate
    raise RuntimeError("Godot was not found in GODOT_BIN or PATH.")


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
        "res://tools/test_v01526_concurrent_ai_scheduler.gd",
    ]
    try:
        completed = subprocess.run(
            command,
            cwd=REPO_ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=45,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        output = exc.stdout if isinstance(exc.stdout, str) else ""
        if output:
            print(output, end="" if output.endswith("\n") else "\n")
        print("ERROR: v0.15.26 scheduler regression timed out after 45 seconds.", file=sys.stderr)
        return 124

    output = completed.stdout or ""
    if output:
        print(output, end="" if output.endswith("\n") else "\n")

    logged_errors = [pattern.pattern for pattern in ERROR_PATTERNS if pattern.search(output)]
    if completed.returncode != 0:
        print(
            f"ERROR: v0.15.26 scheduler regression exited with {completed.returncode}.",
            file=sys.stderr,
        )
        return completed.returncode
    if logged_errors:
        print(
            "ERROR: v0.15.26 scheduler regression logged a script/assertion failure: "
            + ", ".join(logged_errors),
            file=sys.stderr,
        )
        return 1
    if SUCCESS_MARKER not in output:
        print(
            "ERROR: v0.15.26 scheduler regression did not print its success marker.",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
