#!/usr/bin/env python3
"""Static regression checks for v0.20.7 generation-service consolidation."""

from __future__ import annotations

import importlib.util
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def load_reporter():
    path = ROOT / "tools/generation_inheritance_report_v0207.py"
    spec = importlib.util.spec_from_file_location("ccf_generation_report_v0207", path)
    require(spec is not None and spec.loader is not None, "Could not load generation reporter.")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    report = load_reporter().build_report()
    require(
        report["active_service"] == "res://scripts/services/generation_service_current.gd",
        "The semantic current generation service is not active.",
    )
    require(report["historical_depth"] == 34, "Historical v0.19.5 generation depth changed.")
    require(report["active_depth"] == 31, "Phase 2 must reduce generation depth to 31 layers.")
    require(report["depth_reduction"] == 3, "Phase 2 must remove three active inheritance hops.")
    require(report["historical_layers_preserved"], "Historical generation layers must remain available.")
    require(not (ROOT / "scripts/main_v0207.gd").exists(), "v0.20.7 must retain the semantic shell.")
    require((ROOT / "VERSION").read_text(encoding="utf-8").strip() in {"0.20.7", "0.20.8"}, "Phase 2 must remain active in a compatible candidate.")
    print("V0207_GENERATION_CONSOLIDATION_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
