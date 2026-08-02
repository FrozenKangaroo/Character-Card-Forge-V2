#!/usr/bin/env python3
"""Run representative Character Card Forge regression suites.

The runner deliberately isolates HOME/app-data directories so tests that exercise
``user://`` persistence cannot modify the author's real Character Card Forge data.
"""

from __future__ import annotations

import argparse
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
DEFAULT_MANIFEST = REPO_ROOT / "tools" / "regression_suites_v01520.json"


def load_manifest(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"Could not load regression manifest {path}: {exc}") from exc
    if data.get("format_version") != 1:
        raise RuntimeError(
            f"Unsupported regression manifest format_version: {data.get('format_version')!r}"
        )
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
    rel_path = str(test["path"])
    absolute = REPO_ROOT / rel_path
    if kind == "godot":
        resource_path = "res://" + Path(rel_path).as_posix()
        return [godot_bin, "--headless", "--path", str(REPO_ROOT), "--script", resource_path]
    if kind == "shell":
        bash = shutil.which("bash")
        if not bash:
            raise RuntimeError(f"bash is required for shell regression {test['id']}.")
        return [bash, str(absolute)]
    if kind == "python":
        return [sys.executable, str(absolute)]
    raise RuntimeError(f"Unsupported regression test kind {kind!r} for {test['id']}.")


def run_tests(tests: list[dict[str, Any]], godot_bin: str) -> int:
    failures: list[tuple[dict[str, Any], str]] = []
    started = time.monotonic()

    with tempfile.TemporaryDirectory(prefix="ccf-regression-") as temp_dir:
        env = isolated_environment(Path(temp_dir))
        print(f"Regression data isolation: {temp_dir}")
        print(f"Running {len(tests)} representative regression tests...\n")

        for index, test in enumerate(tests, start=1):
            label = str(test.get("label", test["id"]))
            suite = str(test.get("suite", ""))
            timeout_seconds = int(test.get("timeout_seconds", 30))
            print(f"[{index:02d}/{len(tests):02d}] {suite}: {label}")
            command = command_for_test(test, godot_bin)
            test_started = time.monotonic()
            try:
                completed = subprocess.run(
                    command,
                    cwd=REPO_ROOT,
                    env=env,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    timeout=timeout_seconds,
                    check=False,
                )
                duration = time.monotonic() - test_started
                if completed.returncode == 0:
                    print(f"  PASS ({duration:.1f}s)")
                else:
                    output = completed.stdout or "<no output>"
                    failures.append((test, output))
                    print(f"  FAIL exit={completed.returncode} ({duration:.1f}s)")
                    print(output.rstrip())
            except subprocess.TimeoutExpired as exc:
                duration = time.monotonic() - test_started
                output = ""
                if exc.stdout:
                    output = exc.stdout if isinstance(exc.stdout, str) else exc.stdout.decode(errors="replace")
                failures.append((test, output or f"Timed out after {timeout_seconds}s"))
                print(f"  FAIL timeout after {duration:.1f}s")
                if output:
                    print(output.rstrip())
            print()

    duration = time.monotonic() - started
    passed = len(tests) - len(failures)
    print("=== Broad regression summary ===")
    print(f"Passed: {passed}/{len(tests)}")
    print(f"Failed: {len(failures)}")
    print(f"Time:   {duration:.1f}s")
    if failures:
        print("\nFailed tests:")
        for test, _output in failures:
            print(f"  - {test.get('suite')}: {test.get('label', test.get('id'))}")
        return 1
    print("All representative feature areas passed.")
    return 0


def print_manifest(manifest: dict[str, Any]) -> None:
    print(manifest.get("name", "Regression suites"))
    print("Profiles:")
    for profile, suite_names in manifest["profiles"].items():
        print(f"  {profile}: {', '.join(str(item) for item in suite_names)}")
    print("Suites:")
    for suite_name, suite in manifest["suites"].items():
        tests = suite.get("tests", []) if isinstance(suite, dict) else []
        print(f"  {suite_name}: {len(tests)} tests")
        if isinstance(suite, dict) and suite.get("description"):
            print(f"    {suite['description']}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Run Character Card Forge broad regression suites.")
    parser.add_argument("--manifest", default=str(DEFAULT_MANIFEST), help="Regression suite JSON manifest.")
    parser.add_argument("--profile", default=None, help="Named profile from the manifest, e.g. quick or release.")
    parser.add_argument("--suite", action="append", default=[], help="Additional suite to run; may be repeated.")
    parser.add_argument("--godot", default=None, help="Godot executable path. Defaults to GODOT_BIN/godot/godot4.")
    parser.add_argument("--list", action="store_true", help="List profiles and suites without running tests.")
    args = parser.parse_args()

    try:
        manifest = load_manifest(Path(args.manifest).resolve())
        if args.list:
            print_manifest(manifest)
            return 0
        suite_names, tests = collect_tests(manifest, args.profile, args.suite)
        validate_test_paths(tests)
        godot_bin = resolve_godot(args.godot)
        print(f"Regression suites: {', '.join(suite_names)}")
        print(f"Godot: {godot_bin}")
        return run_tests(tests, godot_bin)
    except RuntimeError as exc:
        print(f"Regression runner error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
