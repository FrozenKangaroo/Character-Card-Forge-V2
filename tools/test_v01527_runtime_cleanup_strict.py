#!/usr/bin/env python3
"""Run the v0.15.27 lifecycle regression and fail on logged Godot errors/warnings."""

from __future__ import annotations

import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


REPO_ROOT = Path(__file__).resolve().parent.parent
SUCCESS_MARKER = "v0.15.27 runtime warning and Collaborator lifecycle regression passed"
ERROR_PATTERNS = (
    re.compile(r"SHADOWED_VARIABLE_BASE_CLASS", re.IGNORECASE),
    re.compile(r"data\.tree.*null", re.IGNORECASE),
    re.compile(r"Invalid access to property or key ['\"]process_frame['\"]", re.IGNORECASE),
    re.compile(r"SCRIPT ERROR:", re.IGNORECASE),
    re.compile(r"Assertion failed", re.IGNORECASE),
    re.compile(r"Failed to load script", re.IGNORECASE),
)


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
        "res://tools/test_v01527_runtime_cleanup.gd",
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
        print("ERROR: v0.15.27 runtime cleanup regression timed out.", file=sys.stderr)
        return 124

    output = completed.stdout or ""
    if output:
        print(output, end="" if output.endswith("\n") else "\n")
    if completed.returncode != 0:
        print(
            f"ERROR: v0.15.27 runtime cleanup regression exited with {completed.returncode}.",
            file=sys.stderr,
        )
        return completed.returncode
    matched = [pattern.pattern for pattern in ERROR_PATTERNS if pattern.search(output)]
    if matched:
        print(
            "ERROR: v0.15.27 regression logged a forbidden warning/runtime error: "
            + ", ".join(matched),
            file=sys.stderr,
        )
        return 1
    if SUCCESS_MARKER not in output:
        print("ERROR: v0.15.27 regression did not print its success marker.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
