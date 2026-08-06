#!/usr/bin/env python3
"""Run the v0.15.31 AI Jobs panel regression and fail on logged Godot errors."""

from __future__ import annotations

import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


REPO_ROOT = Path(__file__).resolve().parent.parent
SUCCESS_MARKER = "v0.15.31 AI Jobs queue panel regression passed"
ERROR_PATTERNS = (
    re.compile(r"SCRIPT ERROR:", re.IGNORECASE),
    re.compile(r"Assertion failed", re.IGNORECASE),
    re.compile(r"Failed to load script", re.IGNORECASE),
    re.compile(r"SHADOWED_VARIABLE_BASE_CLASS", re.IGNORECASE),
    re.compile(r"CONFUSABLE_LOCAL_DECLARATION", re.IGNORECASE),
    re.compile(r"Parse Error", re.IGNORECASE),
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


def decode_timeout_output(value: object) -> str:
    if isinstance(value, str):
        return value
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return ""


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
        "res://tools/test_v01531_ai_jobs_panel.gd",
    ]
    try:
        completed = subprocess.run(
            command,
            cwd=REPO_ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=60,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        output = decode_timeout_output(exc.stdout)
        if output:
            print(output, end="" if output.endswith("\n") else "\n")
        print("ERROR: v0.15.31 AI Jobs regression timed out.", file=sys.stderr)
        return 124

    output = completed.stdout or ""
    if output:
        print(output, end="" if output.endswith("\n") else "\n")
    if completed.returncode != 0:
        print(
            f"ERROR: v0.15.31 AI Jobs regression exited with {completed.returncode}.",
            file=sys.stderr,
        )
        return completed.returncode
    matched = [pattern.pattern for pattern in ERROR_PATTERNS if pattern.search(output)]
    if matched:
        print(
            "ERROR: v0.15.31 regression logged a forbidden script/assertion warning: "
            + ", ".join(matched),
            file=sys.stderr,
        )
        return 1
    if SUCCESS_MARKER not in output:
        print("ERROR: v0.15.31 regression did not print its success marker.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
