# Series System

## Overview

The Series System groups related projects around one reusable series bible. It is designed for original settings, franchise-inspired continuities, campaigns, themed collections, or any project group that should share canon, tone, visual language, and generation rules.

Series are separate from character projects. Updating a series immediately changes the guidance available to all assigned projects without rewriting those projects.

## Series Manager

Open **Series** from the main sidebar. The manager supports:

- create, save, duplicate, and delete;
- full-text search across names, aliases, categories, tags, keywords, and guidance;
- assignment usage counts;
- JSON import/export;
- multi-select `.ccfseries` Series Pack export;
- Series Pack import with collision-safe ID remapping;
- AI generation or improvement using the active text profile;
- automatic assignment of currently unassigned saved projects.

The built-in editor fields are defined by series format version 1. They are deliberately independent of character templates.

## Assigning a project

The Character Workspace has a Series selector in its project controls. Assignment affects the whole project, including every character in its roster.

Changing the selection marks the project dirty. Save the project to persist the new `metadata.series_id`.

### Missing references

Deleting a series does not silently clear assigned projects. The stored ID remains visible as a missing reference so it can be repaired by re-importing the series, recreating it, clearing the assignment, or choosing another series.

## Auto Series matching

Auto Series is local and deterministic. It builds searchable text from project metadata, shared context, character names, concepts, card text, roles, creators, and tags, then scores each local series:

- exact series name found: **8 points**;
- alias found: **6 points**;
- matching keyword found: **3 points**;
- matching default tag already on the project: **2 points**;
- category found: **1 point**.

A result needs at least 3 points. Equal top scores are considered ambiguous and are not silently assigned.

The workspace Auto Series button reports the best ambiguous candidate. The Series Manager's bulk command only modifies currently unassigned saved projects. Character Library bulk Auto Match works on the selected projects.

## Default tags

A series may define reusable default tags. **Apply Series Tags** adds only missing case-insensitive project tags; it never removes existing tags or creates duplicates.

## Generation context

The following tools resolve the latest local series definition when a job is queued:

- full character generation;
- field suggestions;
- Controlled Build;
- Character Builder fill and concept extraction;
- Group Scene Generator;
- Relationship Matrix AI generation;
- Card Workflow Studio AI planning.

The prompt labels this information as an assigned series bible and instructs the model to use it as continuity/style guidance rather than copying it verbatim into card fields.

## Series Packs

A `.ccfseries` file is a renamed ZIP archive:

```text
example.ccfseries
├── manifest.json
└── series/
    ├── <series_id>.json
    └── ...
```

The manifest includes package and series format versions, creation information, application version, count, IDs, names, and internal paths.

On import, an identical local ID can be reused. When the same ID already belongs to different content, CCF creates a fresh ID and records the remap instead of overwriting the unrelated local series.

## Portable projects and character cards

A `.ccfproject` export includes the project's assigned series JSON when available. Import remaps the project reference when a local ID collision requires a new series ID.

Character Card V2 has no standard project-series field. CCF therefore stores `series_id` and `series_name` only inside its namespaced `character_card_forge/v1` extension. Import restores the reference but does not fabricate a series definition when none is available.
