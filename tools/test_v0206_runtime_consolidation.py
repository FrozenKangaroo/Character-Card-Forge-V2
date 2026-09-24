#!/usr/bin/env python3
"""Static regression checks for v0.20.6 current-runtime consolidation."""

from __future__ import annotations

import importlib.util
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def load_reporter():
    path = ROOT / "tools/runtime_inheritance_report_v0206.py"
    spec = importlib.util.spec_from_file_location("ccf_runtime_report_v0206", path)
    require(spec is not None and spec.loader is not None, "Could not load runtime reporter.")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    reporter = load_reporter()
    report = reporter.build_report()
    require(report["active_shell"] == "res://scripts/main_current.gd", "Semantic shell is not active.")
    require(report["historical_depth"] == 132, "Historical v0.20.5 shell depth changed unexpectedly.")
    require(report["active_depth"] == 129, "Phase 1 must reduce the active shell to 129 layers.")
    require(report["depth_reduction"] == 3, "Phase 1 must remove three active inheritance hops.")
    require(report["historical_layers_preserved"], "Historical compatibility layers must remain available.")
    require(not (ROOT / "scripts/main_v0206.gd").exists(), "New releases must not restart version-shell stacking.")
    require(
        (ROOT / "VERSION").read_text(encoding="utf-8").strip() in {"0.20.6", "0.20.7", "0.20.8", "0.20.9", "0.21.0"},
        "Phase 1 must remain active in a compatible candidate.",
    )
    print("V0206_RUNTIME_CONSOLIDATION_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
