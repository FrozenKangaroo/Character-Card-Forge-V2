#!/usr/bin/env python3
"""Report and validate the first current-runtime inheritance consolidation."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parent.parent
SCENE = ROOT / "scenes/main.tscn"
CURRENT_SHELL = "res://scripts/main_current.gd"
CURRENT_BASE = "res://scripts/main_v0201.gd"
HISTORICAL_LEAF = "res://scripts/main_v0205.gd"
CONSOLIDATED_LAYERS = (
    "res://scripts/main_v0202.gd",
    "res://scripts/main_v0203.gd",
    "res://scripts/main_v0204.gd",
    "res://scripts/main_v0205.gd",
)

SCENE_SCRIPT_RE = re.compile(
    r'\[ext_resource path="(res://scripts/main[^\"]*\.gd)" type="Script" id="1_main"\]'
)
EXTENDS_RE = re.compile(r'^extends\s+"(res://[^\"]+\.gd)"\s*$', re.MULTILINE)


class ConsolidationError(RuntimeError):
    """Raised when the active runtime violates the consolidation contract."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ConsolidationError(message)


def resource_path(resource: str) -> Path:
    require(resource.startswith("res://"), f"Not a project resource: {resource}")
    return ROOT / resource.removeprefix("res://")


def extends_target(resource: str) -> str:
    path = resource_path(resource)
    require(path.is_file(), f"Missing inheritance resource: {resource}")
    match = EXTENDS_RE.search(path.read_text(encoding="utf-8"))
    return match.group(1) if match else ""


def trace_chain(leaf: str) -> list[str]:
    chain: list[str] = []
    current = leaf
    for _ in range(256):
        require(current not in chain, f"Inheritance cycle detected at {current}")
        chain.append(current)
        parent = extends_target(current)
        if not parent:
            return chain
        current = parent
    raise ConsolidationError("Inheritance chain exceeded 256 layers.")


def active_shell() -> str:
    match = SCENE_SCRIPT_RE.search(SCENE.read_text(encoding="utf-8"))
    require(match is not None, "The main scene does not expose its application shell.")
    return match.group(1)


def build_report() -> dict[str, object]:
    active = active_shell()
    active_chain = trace_chain(active)
    historical_chain = trace_chain(HISTORICAL_LEAF)
    current_source = resource_path(CURRENT_SHELL).read_text(encoding="utf-8")

    require(active == CURRENT_SHELL, "The live scene must use the semantic current shell.")
    require(
        extends_target(CURRENT_SHELL) == CURRENT_BASE,
        "The current shell must consolidate directly onto the v0.20.1 boundary.",
    )
    for layer in CONSOLIDATED_LAYERS:
        require(resource_path(layer).is_file(), f"Historical compatibility layer is missing: {layer}")
        require(layer not in active_chain, f"Consolidated layer remains active: {layer}")
    for marker in (
        "SUPPORT_CENTER_CURRENT",
        "HELP_CENTER_CURRENT",
        "CURRENT_BUILD_VERSION",
        "_open_support_center_v0202",
        "_open_help_center_v0203",
    ):
        require(marker in current_source, f"Current shell is missing semantic capability: {marker}")
    require(
        len(active_chain) < len(historical_chain),
        "The semantic current shell did not reduce active inheritance depth.",
    )

    return {
        "active_shell": active,
        "active_depth": len(active_chain),
        "historical_leaf": HISTORICAL_LEAF,
        "historical_depth": len(historical_chain),
        "depth_reduction": len(historical_chain) - len(active_chain),
        "consolidated_layers": list(CONSOLIDATED_LAYERS),
        "historical_layers_preserved": True,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="Print machine-readable JSON.")
    args = parser.parse_args()
    report = build_report()
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(
            "Runtime shell depth: {active_depth} (was {historical_depth}; reduced by "
            "{depth_reduction}).".format(**report)
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
