# v0.15.40-hotfix1 — Collaborator Source Row Layout Guard

## Problem

After a Character Card PNG was added to Character Collaborator using **Card data + Vision**, the structured source was correctly created and Vision analysis was correctly queued, but the source list in the narrow left sidebar could become almost the full window height.

The visible symptom was two large vertical button-like columns covering the source details while the main Collaborator area continued to show the Vision analysis activity.

## Root cause

The v0.15.37 multi-source list rendered each source as one `HBoxContainer` containing:

- the wrapping source-description label;
- optional **Make Target**;
- the v0.15.39 **Analyse Image / Re-analyse Image** action for Character Card PNG/APNG sources;
- the remove (`×`) action.

In the narrow Collaborator source sidebar, the buttons consumed most of the horizontal width. The descriptive label was left with only a very small width, so even an ordinary source label wrapped into many lines. Because all controls shared the same `HBoxContainer`, Godot stretched the buttons to the resulting row height. The buttons therefore appeared as giant vertical columns.

The Character Card metadata/Vision ingestion itself was not the cause: the source existed and Vision could still run. This was a presentation/layout failure in the populated source row.

## Fix

v0.15.40-hotfix1 replaces the horizontal source row with a compact stacked source card:

1. the descriptive source label receives the full available row width;
2. source actions live in a separate `HFlowContainer` underneath;
3. action buttons explicitly use vertical shrink sizing;
4. action controls can wrap naturally in very narrow sidebars without reducing the label to a few characters per line.

The source row retains all existing behavior:

- **Make Target** for eligible existing Workspace-character references;
- **Analyse Image / Re-analyse Image** for visual Character Card sources;
- linked-Vision status text;
- embedded UserPersona exclusion indicators;
- source removal;
- source IDs, roles and provenance;
- metadata + Vision separation from v0.15.39;
- Workspace AI activity lifecycle behavior from v0.15.40.

## Regression coverage

`tools/test_v01540_hotfix1_collaborator_source_rows.gd` loads the real application shell and builds a deliberately long visual Character Card source with linked Vision evidence. It verifies that:

- the live app installs the v0.15.40-hotfix1 Workspace and Collaborator;
- source descriptions and actions are vertically stacked rather than sharing the old horizontal row;
- the descriptive label keeps expand/fill horizontal sizing;
- source actions use a wrapping flow container beneath the label;
- **Re-analyse Image** and remove remain present;
- every action button uses vertical shrink sizing;
- when headless layout geometry is available, action controls begin below the label and no button expands to the complete source-row height.

The strict runner treats script errors, parse errors, invalid calls/accesses, shadow warnings and confusable declarations as failures.

## Compatibility

The hotfix layers on v0.15.40 rather than replacing its systems. Character Card dual ingestion, UserPersona sanitisation, Vision linkage, Safe Section validation, Image Studio, AI Jobs inspection/cancellation, updater preservation and Workspace status reconciliation remain inherited and are rechecked by CI.
