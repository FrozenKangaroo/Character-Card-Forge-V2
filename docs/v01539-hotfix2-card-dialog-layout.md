# v0.15.39-hotfix2 — Character Card Ingestion Dialog Layout

## Problem

On normal desktop runtime, the v0.15.39 Character Card PNG/APNG mode chooser could expand to almost the full height of the Collaborator window. The visible custom content showed the card name, the three ingestion choices and the provenance note, but the `ConfirmationDialog` action buttons were pushed below the visible desktop area. The user therefore had no visible **Add** button to confirm the selected mode.

## Root cause

The mode chooser inserted wrapped custom `Label` controls directly into a `ConfirmationDialog` without giving the wrapped content an explicit minimum width. On some desktop/window-manager layouts Godot could calculate a very tall minimum content height before the final width was established. The native `ConfirmationDialog` action row was then laid out below that inflated content height.

## Fix

- Give the custom dialog content and wrapped labels a stable 680-pixel minimum width before minimum-size calculation.
- Reduce the requested popup height to a compact 300-pixel target.
- Add an explicit **Cancel / Add** action row inside the custom content so the controls cannot be displaced below the visible dialog.
- Hide the native ConfirmationDialog action buttons to avoid duplicate controls.
- Explicit Add/Cancel handlers hide the dialog before processing the queued source and continue to the next queued card image when multiple cards were attached.
- Focus the visible **Add** button after the mode chooser opens.
- Preserve the three existing modes and all v0.15.39 metadata/Vision/UserPersona behavior unchanged.

## Regression coverage

`tools/test_v01539_hotfix2_card_dialog_layout.gd` instantiates the real application and verifies:

- the live v0.15.39 Collaborator exposes explicit visible Add and Cancel buttons;
- all three ingestion modes remain present;
- native duplicate action buttons are hidden;
- a long Character Card filename still produces a bounded dialog rather than desktop-height expansion;
- the visible action buttons receive real layout rectangles and remain inside the dialog bounds.

The strict runner also rejects script errors, warning regressions and hidden assertion failures. The hotfix manifest inherits the v0.15.39-hotfix1 shadow-warning guard and the complete v0.15.39 feature/regression stack.
