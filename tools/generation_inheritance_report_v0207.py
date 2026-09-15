#!/usr/bin/env python3
"""Report and validate the v0.20.7 generation-service consolidation."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parent.parent
CURRENT_SERVICE = "res://scripts/services/generation_service_current.gd"
CURRENT_BASE = "res://scripts/services/generation_service_v0180_hotfix1.gd"
HISTORICAL_LEAF = "res://scripts/services/generation_service_v0195.gd"
ACTIVE_WORKSPACE = ROOT / "scripts/ui/workspace_v0195.gd"
CONSOLIDATED_LAYERS = (
    "res://scripts/services/generation_service_v0183.gd",
    "res://scripts/services/generation_service_v0186.gd",
    "res://scripts/services/generation_service_v0190.gd",
    "res://scripts/services/generation_service_v0195.gd",
)
EXTENDS_RE = re.compile(r'^extends\s+"(res://[^"]+\.gd)"\s*$', re.MULTILINE)


class ConsolidationError(RuntimeError):
    """Raised when the active generation boundary violates its contract."""


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


def build_report() -> dict[str, object]:
    current_chain = trace_chain(CURRENT_SERVICE)
    historical_chain = trace_chain(HISTORICAL_LEAF)
    current_source = resource_path(CURRENT_SERVICE).read_text(encoding="utf-8")
    workspace_source = ACTIVE_WORKSPACE.read_text(encoding="utf-8")

    require(
        extends_target(CURRENT_SERVICE) == CURRENT_BASE,
        "The current generation service must consolidate onto the v0.18.0 hotfix boundary.",
    )
    require(
        CURRENT_SERVICE in workspace_source and "GENERATION_SERVICE_CURRENT" in workspace_source,
        "The live Workspace must compose the semantic current generation service.",
    )
    for layer in CONSOLIDATED_LAYERS:
        require(resource_path(layer).is_file(), f"Historical generation layer is missing: {layer}")
        require(layer not in current_chain, f"Consolidated layer remains active: {layer}")
    for marker in (
        "queue_ai_review_v0183",
        "queue_compact_derivative_v0186",
        "queue_split_character_set_v0190",
        "text_routing_capabilities_v0195",
        "_technical_failure_category_v0195",
    ):
        require(marker in current_source, f"Current generation service is missing: {marker}")
    require(
        len(current_chain) < len(historical_chain),
        "The semantic generation service did not reduce inheritance depth.",
    )

    return {
        "active_service": CURRENT_SERVICE,
        "active_depth": len(current_chain),
        "historical_leaf": HISTORICAL_LEAF,
        "historical_depth": len(historical_chain),
        "depth_reduction": len(historical_chain) - len(current_chain),
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
            "Generation-service depth: {active_depth} (was {historical_depth}; "
            "reduced by {depth_reduction}).".format(**report)
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
