# v0.15.39 — Character Card PNG Dual Ingestion

## Overview

Character Collaborator can now treat an attached Character Card PNG/APNG as both a structured Character Card source and a visual reference. Earlier multi-source handling promoted recognised card images into structured metadata and therefore bypassed the ordinary image/Vision attachment path.

v0.15.39 links the two established systems without flattening them into one source representation.

## Ingestion modes

When a PNG/APNG contains recognised Character Card metadata, Collaborator offers three choices:

### Card data + Vision (recommended)

- adds the embedded Character Card as a structured Collaborator reference source;
- preserves the raw card snapshot and builds the normal UserPersona-sanitised AI-facing snapshot;
- queues the visible image through the configured Vision role;
- stores the Vision description as separate Vision-derived reference context;
- links that Vision context back to the structured card through `source_context_id` provenance.

### Card data only

Uses the v0.15.37 structured-source path without spending a Vision request.

### Vision only

Uses the normal Collaborator image/Vision pipeline without adding the embedded card metadata as a structured source.

## Analyse an existing attached card later

A visual Character Card source now exposes **Analyse Image**. Once linked Vision evidence exists, the action becomes **Re-analyse Image**.

This allows an author to attach a card as metadata first and decide later that the artwork should also inform the conversation.

## Evidence separation

Card metadata and Vision analysis remain deliberately separate:

- Vision never edits or replaces the raw Character Card snapshot;
- Vision never edits or replaces the normalised AI-facing card snapshot;
- a discrepancy between artwork and card metadata therefore remains visible evidence for Collaborator to reason about rather than being silently resolved during ingestion;
- Vision output continues to pass through the existing Vision → Text boundary, so the Text model receives the Vision-derived description rather than the original image payload.

## Embedded UserPersona handling

v0.15.39 retains the v0.15.37 UserPersona rule for every structured Character Card source.

A separate embedded `UserPersona`, user-profile, roleplayer-persona, or equivalent extraction residue:

- remains in the raw source snapshot for provenance/recovery;
- is excluded from the AI-facing structured source;
- must not define `{{user}}`.

Actual character-source facts involving `{{user}}` remain valid. For example, a card statement that the character has been `{{user}}`'s partner for two years remains available while a separate extracted user profile such as a name, age, appearance, hobbies, or biography is removed from AI-facing card context.

## Other attachment behavior

- Character Card JSON remains a structured metadata source.
- Non-card JSON retains normal text-attachment behavior.
- Non-card PNG/JPG/JPEG/WebP retains normal Vision behavior.
- APNG is exposed in the Collaborator attachment chooser alongside PNG.

## Compatibility

v0.15.39 layers on top of the existing compatibility stack:

- v0.15.38 scalable Image Studio Character picker remains active;
- v0.15.37-hotfix1 Safe Section field-identity/contamination protection remains active;
- v0.15.37 Multi-source Collaborator remains the source model;
- v0.15.21 Vision attachment behavior remains the underlying image-analysis pipeline;
- v0.15.38-hotfix1 `update.sh` local-`project.godot` preservation remains unchanged.

## Regression coverage

`tools/test_v01539_character_card_dual_ingestion.gd` exports and reloads a real Character Card PNG and checks:

- all three ingestion-mode contracts;
- visual-card detection and retained PNG path;
- raw UserPersona preservation;
- UserPersona removal from AI-facing metadata;
- preservation of genuine character-to-`{{user}}` relationship canon;
- source-ID linkage between structured metadata and Vision-derived context;
- non-destructive visual-analysis provenance;
- the live v0.15.39 Workspace/Collaborator shell;
- the three-option ingestion chooser and APNG file-filter support.

Dedicated CI also rechecks v0.15.37 UserPersona behavior, Collaborator attachments/Vision, v0.15.38 Image Studio, v0.15.37-hotfix1 generation validation, the updater hotfix, and the broad quick regression profile.
