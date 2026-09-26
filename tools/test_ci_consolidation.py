#!/usr/bin/env python3
"""Guard the manifest-driven GitHub Actions consolidation."""

from __future__ import annotations

import importlib.util
from pathlib import Path
import sys


REPO_ROOT = Path(__file__).resolve().parent.parent
WORKFLOW_ROOT = REPO_ROOT / ".github" / "workflows"
EXPECTED_WORKFLOWS = {
    "release.yml",
    "validate-regression-suite.yml",
    "validate.yml",
}
CURRENT_MANIFEST = REPO_ROOT / "tools" / "regression_suites_v0212.json"
LEGACY_WORKFLOW_TESTS = {
    "tools/test_alternative_greetings.gd",
    "tools/test_generation_diagnostics.gd",
    "tools/test_image_prompt_generation_v01312.gd",
    "tools/test_v01311_creative_vision_hotfix.gd",
    "tools/test_v01311_seed_warning_name.gd",
    "tools/test_v01311_vision_capabilities.gd",
    "tools/test_v01412_unified_idea_generator.gd",
    "tools/test_v01413_idea_generator_pov.gd",
    "tools/test_v01416_idea_identity_pov.gd",
    "tools/test_v01417_detachable_lorebook.gd",
    "tools/test_v01418_user_centric_ideas.gd",
    "tools/test_v01419_idea_generator_live_service.gd",
    "tools/test_v0142_character_transfer_input.gd",
    "tools/test_v014_authoring_options.gd",
    "tools/test_v014_image_studio_scroll_layout.gd",
    "tools/test_v014_interview_output_budget.gd",
    "tools/test_v01512_full_character_synthesis.gd",
    "tools/test_v01514_component_driven_synthesis.gd",
    "tools/test_v0152_large_output_and_collaborator_wiring.gd",
    "tools/test_v01532_hotfix1_ai_ideas_layout.gd",
    "tools/test_v01532_idea_notebook.gd",
    "tools/test_v01539_character_card_dual_ingestion.gd",
    "tools/test_v0153_collaborator_chat_ux.gd",
    "tools/test_v01540_hotfix2_live_source_refresh.gd",
    "tools/test_v01540_hotfix6_scrollable_source_sidebar.gd",
    "tools/test_v01540_hotfix7_lightweight_diagnostics.gd",
    "tools/test_v0154_collaborator_management_rich_text.gd",
    "tools/test_v0156_collaborator_rich_text_artifacts.gd",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def load_runner():
    runner_path = REPO_ROOT / "tools" / "run_regression_suite.py"
    spec = importlib.util.spec_from_file_location("ccf_regression_runner", runner_path)
    require(spec is not None and spec.loader is not None, "Could not load regression runner.")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def main() -> int:
    workflows = {path.name for path in WORKFLOW_ROOT.glob("*.yml")}
    require(
        workflows == EXPECTED_WORKFLOWS,
        "GitHub Actions must stay consolidated. Expected "
        f"{sorted(EXPECTED_WORKFLOWS)}, found {sorted(workflows)}.",
    )

    validate_text = (WORKFLOW_ROOT / "validate.yml").read_text(encoding="utf-8")
    regression_text = (WORKFLOW_ROOT / "validate-regression-suite.yml").read_text(
        encoding="utf-8"
    )
    require("name: Validate Godot project" in validate_text, "Stable validation name changed.")
    require("name: Validate regression suite" in regression_text, "Stable regression name changed.")
    for text, label in ((validate_text, "validation"), (regression_text, "regression")):
        require("regression_suites_v0212.json" in text, f"{label} workflow uses a stale manifest.")
        require("pull_request:" in text, f"{label} workflow must run on pull requests.")
        require("branches:\n      - main" in text, f"{label} workflow must run on main.")

    runner = load_runner()
    require(runner.DEFAULT_MANIFEST.resolve() == CURRENT_MANIFEST.resolve(), "Default manifest is stale.")
    manifest = runner.load_manifest(CURRENT_MANIFEST)
    suite_names, tests = runner.collect_tests(manifest, "release", [])
    runner.validate_test_paths(tests)
    paths = {str(test["path"]) for test in tests}
    require(len(tests) >= 158, f"Release profile lost historical coverage: {len(tests)} tests.")
    require(
        LEGACY_WORKFLOW_TESTS.issubset(paths),
        "Tests formerly owned only by milestone workflows are missing from the manifest: "
        f"{sorted(LEGACY_WORKFLOW_TESTS - paths)}",
    )
    require(len({test["id"] for test in tests}) == len(tests), "Release profile contains duplicate IDs.")
    require("current_wiring" in suite_names, "Release profile lost current live wiring tests.")

    print(
        "CI consolidation regression passed: "
        f"{len(workflows)} workflows, {len(tests)} inherited release tests."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
