# v0.15.40-hotfix2 — Live Collaborator Source Refresh Guard

## Problem

Runtime testing after v0.15.40-hotfix1 showed the Character Collaborator could still display the original broken horizontal source row after adding a Character Card PNG with **Card data + Vision**.

The visible failure matched the v0.15.39 fallback structure: the descriptive source label was squeezed between action controls until it wrapped almost one character per line, while the sibling buttons expanded to the full resulting row height.

The hotfix1 row component itself was correct. Its regression built that component directly, so it did not prove that the normal `add_source_v01537()` / Vision completion / `_refresh_all()` chain finished on the new renderer.

## Fix

v0.15.40-hotfix2 makes the active Collaborator leaf enforce compact source rows as a postcondition of the entire source-panel refresh.

- `_refresh_multi_source_list_v01537()` is authoritative in the active leaf.
- `_refresh_source_panel_v01533()` verifies that every final live row is a hotfix2 stacked row and rebuilds if an inherited horizontal row survived.
- Old rows are removed from the source list immediately before `queue_free()` so a stale row cannot remain visible while the replacement is already present.
- Source descriptions receive the full row width in a vertical stack.
- **Make Target**, **Analyse Image / Re-analyse Image**, and remove live in a separate `HFlowContainer` beneath the label.
- Every action button explicitly opts out of vertical expansion.
- Character Card metadata/Vision separation, linked provenance, UserPersona exclusion, target switching, and removal remain unchanged.

## Regression

`tools/test_v01540_hotfix2_live_source_refresh.gd` now uses the real main scene and a real exported Character Card PNG. It:

1. Adds the structured source through `add_source_v01537()`, which runs the normal `_refresh_all()` chain.
2. Adds linked Vision evidence in the same stored source/context shape produced after Vision completion and runs `_refresh_all()` again.
3. Confirms the final live source list contains the compact stacked renderer and **Re-analyse Image**.
4. Deliberately injects an inherited `HBoxContainer` reproduction into the live source list.
5. Runs the normal source-panel refresh and requires that the horizontal row is eliminated and replaced by the hotfix2 renderer.

This closes the coverage gap that allowed v0.15.40-hotfix1 to pass CI while the runtime path still reproduced the bug.
