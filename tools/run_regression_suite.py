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
DEFAULT_MANIFEST = REPO_ROOT / "tools" / "regression_suites_v01533.json"


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
            print(f"[{index}/{len(tests)}] {suite}: {label}")
            command = command_for_test(test, godot_bin)
            test_root = temp_root / f"{index:03d}_{test.get('id', 'test')}"
            test_root.mkdir(parents=True, exist_ok=True)
            env = isolated_environment(test_root)
            try:
                completed = subprocess.run(
                    command,
                    cwd=REPO_ROOT,
                    env=env,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    timeout=timeout_seconds,
                    check=False,
                )
                output = completed.stdout or ""
                if output:
                    print(output, end="" if output.endswith("\n") else "\n")
                if completed.returncode != 0:
                    failures.append((test, completed.returncode, output))
                    if bool(test.get("fail_fast", True)):
                        break
            except subprocess.TimeoutExpired as exc:
                output = exc.stdout if isinstance(exc.stdout, str) else ""
                if output:
                    print(output, end="" if output.endswith("\n") else "\n")
                failures.append((test, 124, output))
                break

    elapsed = time.monotonic() - started
    if failures:
        print(f"Regression profile failed after {elapsed:.1f}s:", file=sys.stderr)
        for test, code, _output in failures:
            print(
                f"  - {test.get('id')} ({test.get('suite')}): exit {code}",
                file=sys.stderr,
            )
        return 1
    print(f"Regression profile passed {len(tests)} test(s) in {elapsed:.1f}s")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--manifest",
        type=Path,
        default=DEFAULT_MANIFEST,
        help=f"Regression manifest (default: {DEFAULT_MANIFEST.relative_to(REPO_ROOT)})",
    )
    parser.add_argument("--profile", choices=("quick", "release"))
    parser.add_argument("--suite", action="append", default=[], help="Additional suite to run")
    parser.add_argument("--godot", help="Godot executable path")
    parser.add_argument("--list", action="store_true", help="List resolved tests without running")
    args = parser.parse_args()

    try:
        manifest = load_manifest(args.manifest)
        suite_names, tests = collect_tests(manifest, args.profile, args.suite)
        validate_test_paths(tests)
        if args.list:
            print(manifest.get("name", args.manifest.name))
            print("Suites: " + ", ".join(suite_names))
            for index, test in enumerate(tests, start=1):
                print(
                    f"{index:02d}. [{test.get('suite')}] {test.get('id')} — {test.get('label', '')}"
                )
            return 0
        godot_bin = resolve_godot(args.godot)
    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    return run_tests(tests, godot_bin)


if __name__ == "__main__":
    raise SystemExit(main())