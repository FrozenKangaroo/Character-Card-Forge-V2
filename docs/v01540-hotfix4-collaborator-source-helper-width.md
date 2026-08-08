# v0.15.40-hotfix4 — Collaborator Source Helper Width

## Runtime report

After v0.15.40-hotfix3 removed the giant full-height action columns, desktop runtime testing still showed a malformed Reference Context sidebar. The inherited Character Card helper sentence rendered one character per line beneath the source guidance.

The visible text identified the remaining control precisely: the v0.15.37 helper that says Character Card JSON/PNG added through Attach Files is detected as structured source automatically.

## Root cause

That explanatory `Label` was created inside `CollaboratorMultiSourceActionsV01537`, an `HFlowContainer` shared with source action buttons. It was therefore still participating in action-flow width allocation even though hotfix1–hotfix3 had already replaced and guarded the dynamic structured-source and ordinary context rows.

At the real desktop sidebar width, Godot could give this wrapped label essentially one glyph of horizontal space, producing the one-character-per-line column seen in runtime testing.

## Fix

- Move explanatory labels out of the source action `HFlowContainer` and into the parent source `VBoxContainer` as independent full-width rows.
- Keep `CollaboratorMultiSourceActionsV01537` action-only.
- Explicitly give the helper, source panel, action flow, and multi-source list horizontal expand/fill sizing.
- Extend the hotfix3 visible runtime guard so any explanatory `Label` found inside the source action flow is itself an invalid layout state and triggers reconciliation.
- Preserve all prior Card metadata + Vision, UserPersona exclusion, multi-source, target, updater, and Workspace AI activity behavior.

## Regression

`tools/test_v01540_hotfix4_source_helper_width.gd` opens the real main scene and Collaborator, confirms the inherited helper is a direct full-width child of the source panel, and verifies the action flow contains no labels. It then deliberately reparents the helper back into the action flow—the exact structural condition behind the runtime screenshot—and requires the normal deferred sidebar reflow to move it back out and restore expand/fill sizing.

Where headless Godot provides usable desktop geometry, the regression additionally requires the helper to receive most of the source-panel width rather than a one-glyph allocation.
