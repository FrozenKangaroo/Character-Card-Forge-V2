# Multi-Character Card Workflows

Character Card Forge v0.6 introduces the **Card Workflow Studio** as the planning and data foundation for later multi-character exports and batch generation.

The workflow system deliberately stores plans separately from individual character records. A workflow can therefore describe how several characters should be packaged or generated without overwriting the source characters.

## Workflow modes

### Multi-character single card

Plans one combined card where multiple characters coexist in one exported character definition. The workflow describes the shared setup and how each member should be represented without merging their identities.

### Split-card batch plan

Plans a coordinated set of separate character cards generated from one shared project setup. Each member receives individual output directions while preserving shared continuity and relationships.

### Group-card plan

Plans an output centred on the collective group, shared premise, and interaction structure while retaining per-character identity.

## Stored workflow draft

A project-level workflow contains:

```text
workflow_id
created_at
updated_at
mode
title
selected_character_ids[]
instructions
summary
shared_scenario
opening_message
notes
members[]
```

Each member entry contains:

```text
character_id
role_in_output
card_direction
scenario_direction
opening_direction
```

Workflow drafts are stored under `card_workflows[]` in the project JSON.

## AI-assisted planning

The Card Workflow Studio can generate a workflow draft from:

- selected characters;
- their existing character data;
- shared project context;
- established relationships;
- the selected workflow mode;
- optional user instructions.

The generated result is editable and remains unsaved until **Save Draft** is used. Saving a draft updates the in-memory project; the main workspace **Save** action still controls writing the project file to disk.

## Current scope

v0.7 connects saved **Split-card batch plan** workflows to the Import / Export Studio. A selected split workflow can now export every valid member as an individual Character Card V2 JSON file in one operation.

The workflow remains a planning layer: v0.7 does **not** yet automatically run full-card generation for every member, batch-create PNG cards, or define a dedicated ecosystem format for combined/group cards.

Later generation/export systems can continue consuming these workflow drafts as a stable specification instead of inventing their own parallel multi-character configuration format.

## Character removal and project duplication

Workflow character references are UUID-based.

When a project is duplicated, selected-character and member references are remapped to the duplicated UUIDs.

When a character is removed, workflow references are pruned. A workflow that no longer has at least two valid selected characters is removed during normalisation because it is no longer a multi-character workflow.

## Assigned series context

AI-assisted workflow planning receives the latest assigned series bible alongside shared project context, selected characters, and established relationships. Saved workflow drafts contain the resulting plan, not a duplicated snapshot of the series definition.
