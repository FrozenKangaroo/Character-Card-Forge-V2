#!/usr/bin/env python3
"""Run representative Character Card Forge regression suites.

The runner deliberately isolates HOME/app-data directories so tests that exercise
``user://`` persistence cannot modify the author's real Character Card Forge data.
"""

from __future__ import annotations

import argparse
import copy
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
from typing import Any


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_MANIFEST = REPO_ROOT / "tools" / "regression_suites_v01532.json"


def load_manifest(path: Path, _visited: set[Path] | None = None) -> dict[str, Any]:
    resolved = path.resolve()
    visited = set() if _visited is None else set(_visited)
    if resolved in visited:
        raise RuntimeError(f"Regression manifest inheritance cycle detected at {path}")
    visited.add(resolved)

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"Could not load regression manifest {path}: {exc}") from exc
    if data.get("format_version") != 1:
        raise RuntimeError(
            f"Unsupported regression manifest format_version: {data.get('format_version')!r}"
        )

    base_name = str(data.get("base_manifest", "")).strip()
    if base_name:
        base_path = path.parent / base_name
        merged = copy.deepcopy(load_manifest(base_path, visited))
        if data.get("name"):
            merged["name"] = data["name"]
        if data.get("description"):
            merged["description"] = data["description"]
        additions = data.get("suite_additions", {})
        if not isinstance(additions, dict):
            raise RuntimeError("Regression suite_additions must be an object.")
        suites = merged.get("suites", {})
        if not isinstance(suites, dict):
            raise RuntimeError("Inherited regression manifest has invalid suites.")
        for suite_name, extra_tests in additions.items():
            if suite_name not in suites or not isinstance(suites[suite_name], dict):
                raise RuntimeError(f"Regression additions reference unknown suite: {suite_name}")
            if not isinstance(extra_tests, list):
                raise RuntimeError(f"Regression additions for {suite_name} must be an array.")
            current_tests = suites[suite_name].get("tests", [])
            if not isinstance(current_tests, list):
                raise RuntimeError(f"Inherited suite {suite_name} has invalid tests.")
            current_tests.extend(copy.deepcopy(extra_tests))
        return merged

    if not isinstance(data.get("suites"), dict) or not isinstance(data.get("profiles"), dict):
        raise RuntimeError("Regression manifest must contain object-valued suites and profiles.")
    return data


def resolve_godot(explicit: str | None) -> str:
    candidates = [explicit, os.environ.get("GODOT_BIN"), shutil.which("godot"), shutil.which("godot4")]
    for candidate in candidates:
        if candidate:
            return candidate
    raise RuntimeError("Godot was not found. Pass --godot /path/to/godot or set GODOT_BIN.")


def isolated_environment(base: dict[str, str], temp_root: Path) -> dict[str, str]:
    env = base.copy()
    home = temp_root / "home"
    xdg_data = temp_root / "xdg-data"
    xdg_config = temp_root / "xdg-config"
    xdg_cache = temp_root / "xdg-cache"
    for directory in (home, xdg_data, xdg_config, xdg_cache):
        directory.mkdir(parents=True, exist_ok=True)
    env["HOME"] = str(home)
    env["XDG_DATA_HOME"] = str(xdg_data)
    env["XDG_CONFIG_HOME"] = str(xdg_config)
    env["XDG_CACHE_HOME"] = str(xdg_cache)
    return env


def run_test(test: dict[str, Any], godot: str, env: dict[str, str]) -> tuple[int, str, float]:
    kind = str(test.get("kind", "godot"))
    path = str(test.get("path", "")).strip()
    timeout = int(test.get("timeout_seconds", 45))
    if not path:
        return 2, "Regression entry has no path.\n", 0.0
    if kind == "python":
        command = [sys.executable, str(REPO_ROOT / path)]
    elif kind == "godot":
        command = [godot, "--headless", "--path", str(REPO_ROOT), "--script", f"res://{path}"]
    else:
        return 2, f"Unsupported regression kind: {kind}\n", 0.0
    started = time.monotonic()
    try:
        completed = subprocess.run(
            command,
            cwd=REPO_ROOT,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=timeout,
            check=False,
        )
        return completed.returncode, completed.stdout or "", time.monotonic() - started
    except subprocess.TimeoutExpired as exc:
        output = exc.stdout if isinstance(exc.stdout, str) else ""
        return 124, output + f"\nTimed out after {timeout}s.\n", time.monotonic() - started


def selected_tests(manifest: dict[str, Any], profile_name: str) -> list[tuple[str, dict[str, Any]]]:
    profiles = manifest.get("profiles", {})
    if profile_name not in profiles:
        raise RuntimeError(f"Unknown regression profile: {profile_name}")
    suites = manifest.get("suites", {})
    profile = profiles[profile_name]
    suite_names = profile.get("suites", [])
    if not isinstance(suite_names, list):
        raise RuntimeError(f"Regression profile {profile_name} has invalid suites list.")
    result: list[tuple[str, dict[str, Any]]] = []
    for suite_name in suite_names:
        suite = suites.get(suite_name)
        if not isinstance(suite, dict):
            raise RuntimeError(f"Regression profile {profile_name} references unknown suite: {suite_name}")
        tests = suite.get("tests", [])
        if not isinstance(tests, list):
            raise RuntimeError(f"Regression suite {suite_name} has invalid tests list.")
        for test in tests:
            if isinstance(test, dict):
                result.append((str(suite_name), test))
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", default="quick", help="Regression profile name from the manifest.")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--godot", default=None, help="Godot executable for Godot-kind tests.")
    parser.add_argument("--list", action="store_true", help="List selected tests without running them.")
    args = parser.parse_args()

    try:
        manifest = load_manifest(args.manifest)
        tests = selected_tests(manifest, args.profile)
    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    if args.list:
        for index, (suite_name, test) in enumerate(tests, start=1):
            print(f"{index:02d}. {suite_name}: {test.get('label', test.get('id', 'unnamed'))}")
        return 0

    try:
        godot = resolve_godot(args.godot)
    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    failures: list[str] = []
    started_all = time.monotonic()
    with tempfile.TemporaryDirectory(prefix="ccf-regression-") as temp_dir:
        temp_root = Path(temp_dir)
        env = isolated_environment(os.environ, temp_root)
        for index, (suite_name, test) in enumerate(tests, start=1):
            label = str(test.get("label", test.get("id", "unnamed")))
            print(f"[{index}/{len(tests)}] {suite_name}: {label}", flush=True)
            code, output, elapsed = run_test(test, godot, env)
            if output:
                print(output, end="" if output.endswith("\n") else "\n")
            if code != 0:
                failures.append(f"{test.get('id', label)} ({suite_name}): exit {code}")
                if bool(test.get("fail_fast", False)):
                    break
            if bool(test.get("show_timing", False)):
                print(f"  completed in {elapsed:.1f}s")

    elapsed_all = time.monotonic() - started_all
    if failures:
        print(f"Regression profile failed after {elapsed_all:.1f}s:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1
    print(f"Regression profile '{args.profile}' passed: {len(tests)} tests in {elapsed_all:.1f}s")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
