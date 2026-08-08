# v0.15.39-hotfix1 — Collaborator Window.mode Shadow Warning

## Problem

Godot 4.7.1 reports `SHADOWED_VARIABLE_BASE_CLASS` when the v0.15.39 Character Collaborator dual-ingestion leaf declares either a local variable or a function parameter named `mode`, because `Window` already owns a `mode` property.

The reported sites were in `scripts/ui/character_collaborator_window_v01539.gd`:

- the selected Character Card ingestion mode local in `_confirm_card_ingestion_v01539()`;
- the `mode` parameter in `_apply_card_ingestion_v01539()`.

## Fix

Both identifiers now use `ingestion_mode`. The Character Card PNG/APNG ingestion contract is unchanged: `Card data + Vision`, `Card data only`, and `Vision only` still map to the same service modes and return the same public `mode` result field.

The running development label is `0.15.39-hotfix1`.

## Regression

`tools/test_v01539_hotfix1_collaborator_shadowing.py` provides a source-level guard that fails if the v0.15.39 Collaborator leaf again declares a local `mode` variable or an `_apply_card_ingestion_v01539()` parameter named `mode`. This complements the existing Godot warning-as-error import gate, which did not reproduce the editor/runtime warning reliably in headless CI.

The v0.15.39 dedicated workflow also reruns the full dual-ingestion regression, Multi-source/UserPersona checks, attachment/Vision inheritance, Image Studio picker, Safe Section contamination protection, updater preservation, and the broad quick profile.
