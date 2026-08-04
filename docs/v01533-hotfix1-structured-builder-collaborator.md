# v0.15.33-hotfix1 — Structured Builder → Character Collaborator

## Goal

Complete the v0.15.33 Collaborator source-context surface by allowing the **Structured Builder** tab to open Character Collaborator directly from its current author-selected ingredients.

This is a hotfix-level extension of v0.15.33 rather than v0.15.34. v0.15.34 remains reserved for the larger **Existing Character → Collaborator** workflow.

## User workflow

The Structured Builder now presents two neighbouring actions:

- **Build Idea into Main Concept** — existing behaviour; converts the selected ingredients into the Workspace Main Concept.
- **Develop in Collaborator** — new behaviour; opens a new source-aware Character Collaborator conversation directly from the current Structured Builder state.

The Collaborator handoff does not require the idea to be saved to Idea Notebook and does not automatically spend an AI request merely by opening the conversation.

## Source model

v0.15.33's versioned source contract now recognises:

```text
source_type: structured_builder
```

The source snapshot retains:

- each non-empty ingredient's stable field ID;
- user-facing ingredient label;
- selected/typed value;
- whether the ingredient supports multi-selection;
- Structured Builder custom instructions;
- a deterministic Main-Concept-style rendering of the same ingredients.

Provenance identifies the source origin as `structured_builder` and retains the Idea Generator options format version when available.

This source type remains distinct from:

- `generated_idea` — returned by an AI Ideas provider request;
- `saved_idea` — loaded from Idea Notebook;
- `character` — existing-character source groundwork for v0.15.34.

## Canon/source behaviour

Structured Builder ingredients are passed as read-only authoritative source material. Character Collaborator receives the same v0.15.33 source-handling rules used by other source types:

- established source facts remain authoritative unless the author requests a change;
- author-requested changes are distinct from new/proposed details;
- normal Collaborator conversation never mutates the Structured Builder source snapshot itself.

## Validation

The focused regression verifies:

- `structured_builder` is a valid v0.15.33 source type;
- ingredient order/value and custom instructions survive the source conversion;
- the model-facing source block identifies Structured Builder correctly;
- the visible Structured Builder contains **Develop in Collaborator**;
- invoking the action emits a structured Collaborator source rather than flattened UI text;
- the real main scene installs the v0.15.33-hotfix1 Workspace and Idea Generator;
- the Workspace advertises `structured_builder_handoff` capability.

The broad regression default advances to `regression_suites_v01533_hotfix1.json` so this handoff remains part of future release compatibility coverage.
