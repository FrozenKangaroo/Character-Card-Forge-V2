# v0.15.40-hotfix5 — Collaborator Composer Resize Guard

## Runtime report

Desktop testing found that resizing a populated Character Collaborator window could push the entire composer area (input box plus action controls) below the visible window. Switching to another project and back forced a fuller UI refresh and restored the composer, indicating stale layout/minimum-size state rather than lost conversation data.

The same runtime session also exposed three Godot 4.7.1 warnings: one `SHADOWED_VARIABLE_BASE_CLASS` in the hotfix3 sessions callback and two `INCOMPATIBLE_TERNARY` warnings in the hotfix4 source-helper code.

## Fix

- Make the chat transcript scroll container the vertical-expansion surface.
- Keep the composer input and action controls vertically shrinking/pinned after the transcript.
- Clear stale custom minimum height from the transcript scroll container during deferred resize reconciliation.
- Schedule one bounded composer reflow after window resize, visibility changes, and normal Collaborator refreshes.
- Add a visible runtime guard that detects the composer leaving the chat-panel bounds and schedules reconciliation without requiring a project/session switch.
- Rename the hotfix3 sessions callback parameter so it no longer shadows the base `_sessions` member.
- Replace the two incompatible hotfix4 ternaries with explicit typed branches.

## Regression

The real-main-scene regression opens the actual Collaborator, adds a very long Vision-style message to the live transcript, repeatedly resizes the native window through large and minimum-supported sizes, and requires the input to remain visible and inside the chat panel without switching projects. It then deliberately recreates stale transcript minimum-height/input sizing state and requires automatic recovery.

The dedicated Godot 4.7.1 import gate treats `SHADOWED_VARIABLE_BASE_CLASS` and `INCOMPATIBLE_TERNARY` as failures.
