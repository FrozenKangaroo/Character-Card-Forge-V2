# v0.15.32 — Idea Notebook

## Purpose

v0.15.32 turns AI Ideas from disposable generation output into optional, persistent authoring material. Generation still behaves exactly as before until the user explicitly chooses **Save Generated Ideas…**. Nothing is placed in Idea Notebook automatically.

## Workflow

The unified Idea Generator now contains three tabs:

1. **AI Ideas** — the existing prompt/count/results workflow.
2. **Structured Builder** — the existing configurable ingredient workflow.
3. **Idea Notebook** — persistent saved ideas.

After an AI Ideas job completes, the live Idea worker hands the normalised result batch to the unified window. **Save Generated Ideas…** opens a selection view for that latest batch. Every result is individually selectable, with Select All / Select None helpers and a destination notebook selector.

## Saved data

The Notebook preserves the structured AI Ideas object rather than reconstructing it from visible labels:

- title
- character name
- character role
- source anchor
- roleplay hook
- generation-ready concept
- tags

It also stores editable private notes, archive state, notebook assignment, timestamps, and source metadata that is already available at save time such as seed prompt and idea-contract version.

## Storage format

Idea Notebook is deliberately independent of Character Projects.

```text
user://character_card_forge/idea_notebook/
├── library.json
└── ideas/
    ├── <idea-id>.json
    └── ...
```

`library.json` uses `format: character_card_forge_idea_notebook` and `format_version: 1`. Individual ideas use `format: character_card_forge_saved_idea` and `format_version: 1`.

Named notebooks have stable IDs. **All Ideas** and **Unfiled** are built-in views rather than stored notebook records. Deleting a named notebook never deletes its ideas; they move to Unfiled.

## Notebook tools

v0.15.32 supports:

- named notebook create / rename / delete
- All Ideas and Unfiled views
- notebook counts
- cross-notebook text search
- case-insensitive tag filtering
- title / concept / private notes / tag editing
- moving an idea between notebooks
- archive / restore
- permanent saved-idea deletion
- **Use as Main Concept**

Archived ideas are excluded from normal browsing and may be shown explicitly.

## Collaborator handoff

The proposed **Develop in Collaborator** action is intentionally not implemented as an ad-hoc pasted chat message in v0.15.32. The current Collaborator does not expose a stable public source-seeding API; reaching into its private input/session state would create a compatibility problem immediately.

v0.15.33 is therefore planned to introduce a generic structured Collaborator Source / provenance model that can accept both generated/saved ideas and existing characters. Idea Notebook will consume that API rather than inventing a Notebook-specific handoff format.

## Compatibility

v0.15.32 does not change AI Ideas prompts, generation contracts, Character Project schema, Safe Section behavior, AI scheduler limits, Image Studio, or current Collaborator sessions. It adds persistence after successful idea generation and reads the normalised batch emitted by the existing Idea worker.
