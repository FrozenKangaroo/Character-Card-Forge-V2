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
DEFAULT_MANIFEST = REPO_ROOT / "tools" / "regression_suites_v01527.json"


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


def collect_tests(
    manifest: dict[str, Any], profile: str | None, selected_suites: list[str]
) -> tuple[list[str], list[dict[str, Any]]]:
    suites: dict[str, Any] = manifest["suites"]
    profiles: dict[str, Any] = manifest["profiles"]

    suite_names: list[str] = []
    if profile:
        raw_profile = profiles.get(profile)
        if not isinstance(raw_profile, list):
            raise RuntimeError(f"Unknown regression profile: {profile}")
        suite_names.extend(str(item) for item in raw_profile)
    suite_names.extend(selected_suites)
    if not suite_names:
        suite_names.extend(str(item) for item in profiles.get("release", []))

    ordered_suites: list[str] = []
    for suite_name in suite_names:
        if suite_name not in suites:
            raise RuntimeError(f"Unknown regression suite: {suite_name}")
        if suite_name not in ordered_suites:
            ordered_suites.append(suite_name)

    tests: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    for suite_name in ordered_suites:
        suite = suites[suite_name]
        raw_tests = suite.get("tests", []) if isinstance(suite, dict) else []
        if not isinstance(raw_tests, list):
            raise RuntimeError(f"Suite {suite_name} has an invalid tests list.")
        for raw_test in raw_tests:
            if not isinstance(raw_test, dict):
                raise RuntimeError(f"Suite {suite_name} contains a non-object test entry.")
            test_id = str(raw_test.get("id", "")).strip()
            if not test_id:
                raise RuntimeError(f"Suite {suite_name} contains a test without an id.")
            if test_id in seen_ids:
                continue
            seen_ids.add(test_id)
            test = dict(raw_test)
            test["suite"] = suite_name
            tests.append(test)
    return ordered_suites, tests


def validate_test_paths(tests: list[dict[str, Any]]) -> None:
    missing: list[str] = []
    for test in tests:
        rel_path = str(test.get("path", "")).strip()
        if not rel_path or not (REPO_ROOT / rel_path).is_file():
            missing.append(f"{test.get('id', '<missing id>')}: {rel_path or '<missing path>'}")
    if missing:
        raise RuntimeError("Regression manifest references missing files:\n  " + "\n  ".join(missing))


def isolated_environment(root: Path) -> dict[str, str]:
    env = os.environ.copy()
    home = root / "home"
    xdg_data = root / "xdg-data"
    xdg_config = root / "xdg-config"
    xdg_cache = root / "xdg-cache"
    appdata = root / "appdata"
    localappdata = root / "localappdata"
    for directory in (home, xdg_data, xdg_config, xdg_cache, appdata, localappdata):
        directory.mkdir(parents=True, exist_ok=True)
    env.update(
        {
            "HOME": str(home),
            "XDG_DATA_HOME": str(xdg_data),
            "XDG_CONFIG_HOME": str(xdg_config),
            "XDG_CACHE_HOME": str(xdg_cache),
            "APPDATA": str(appdata),
            "LOCALAPPDATA": str(localappdata),
            "CCF_REGRESSION_RUN": "1",
        }
    )
    return env


def command_for_test(test: dict[str, Any], godot_bin: str) -> list[str]:
    kind = str(test.get("kind", "godot"))
    rel_path = str(test.get("path", ""))
    if kind == "godot":
        return [godot_bin, "--headless", "--path", str(REPO_ROOT), "--script", f"res://{rel_path}"]
    if kind == "python":
        return [sys.executable, str(REPO_ROOT / rel_path)]
    if kind == "shell":
        return ["bash", str(REPO_ROOT / rel_path)]
    raise RuntimeError(f"Unsupported regression test kind {kind!r} for {test.get('id')}")


def run_tests(tests: list[dict[str, Any]], godot_bin: str) -> int:
    failures: list[tuple[dict[str, Any], int, str]] = []
    started = time.monotonic()
    with tempfile.TemporaryDirectory(prefix="ccf-regression-") as tmp:
        temp_root = Path(tmp)
        for index, test in enumerate(tests, start=1):
            label = str(test.get("label", test.get("id", "Unnamed test")))
            suite = str(test.get("suite", "unknown"))
            timeout_seconds = max(5, int(test.get("timeout_seconds", 30)))
            command = command_for_test(test, godot_bin)
            print(f"[{index:02d}/{len(tests):02d}] {suite}: {label}")
            test_root = temp_root / str(test.get("id", f"test-{index}"))
            test_root.mkdir(parents=True, exist_ok=True)
            try:
                completed = subprocess.run(
                    command,
                    cwd=REPO_ROOT,
                    env=isolated_environment(test_root),
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    timeout=timeout_seconds,
                    check=False,
                )
                output = completed.stdout or ""
                if completed.returncode != 0:
                    failures.append((test, completed.returncode, output))
                    print(f"  FAIL (exit {completed.returncode})")
                else:
                    print("  PASS")
                    if output.strip():
                        last_line = output.strip().splitlines()[-1]
                        print(f"  {last_line}")
            except subprocess.TimeoutExpired as exc:
                output = (exc.stdout or "") if isinstance(exc.stdout, str) else ""
                failures.append((test, 124, output))
                print(f"  FAIL (timeout after {timeout_seconds}s)")

    elapsed = time.monotonic() - started
    print()
    print(f"Regression suite finished in {elapsed:.1f}s: {len(tests) - len(failures)} passed, {len(failures)} failed.")
    if failures:
        print("\nFailures:")
        for test, code, output in failures:
            print(f"\n--- {test.get('suite')} / {test.get('label', test.get('id'))} (exit {code}) ---")
            trimmed = output.strip()
            if trimmed:
                print(trimmed[-8000:])
        return 1
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--manifest",
        type=Path,
        default=DEFAULT_MANIFEST,
        help=f"Regression manifest path (default: {DEFAULT_MANIFEST.relative_to(REPO_ROOT)})",
    )
    parser.add_argument("--profile", choices=["quick", "release"], help="Named regression profile to run.")
    parser.add_argument(
        "--suite",
        action="append",
        default=[],
        help="Run an additional named suite. May be passed more than once.",
    )
    parser.add_argument("--godot", help="Godot executable. Defaults to GODOT_BIN/godot/godot4.")
    parser.add_argument("--list", action="store_true", help="List selected tests without running them.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    manifest_path = args.manifest if args.manifest.is_absolute() else REPO_ROOT / args.manifest
    try:
        manifest = load_manifest(manifest_path)
        suite_names, tests = collect_tests(manifest, args.profile, args.suite)
        validate_test_paths(tests)
        if args.list:
            print(f"Suites: {', '.join(suite_names)}")
            for test in tests:
                print(f"- {test['id']}: {test.get('label', test['id'])} [{test.get('kind', 'godot')}]")
            return 0
        godot_bin = resolve_godot(args.godot)
    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    print(f"Character Card Forge regression profile: {args.profile or 'custom/release-default'}")
    print(f"Suites: {', '.join(suite_names)}")
    print(f"Tests: {len(tests)}")
    print(f"Godot: {godot_bin}")
    print()
    return run_tests(tests, godot_bin)


if __name__ == "__main__":
    raise SystemExit(main())