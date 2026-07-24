# Character Card Forge Project Format v2

Character Card Forge v0.5 introduces a real multi-character project model. A project is still stored in one human-readable `character.json` file, but that file can now contain multiple independent character records plus shared project context.

Format-v1 single-character projects are migrated in memory when loaded and are written back as format v2 the next time they are saved.

## Project-level structure

```text
character.json
├── format_version
├── project_id
├── created_at
├── updated_at
├── metadata
├── shared_context
├── characters[]
├── relationships[]
├── card_workflows[]
└── workspace
```

### `metadata`

Project/library-facing information:

- `name`
- `summary`
- `tags`
- `series_id`
- `favorite`
- `library.folder` — optional virtual folder label
- `library.collections[]` — zero or more virtual collection labels

Project metadata describes the whole project rather than one character. Virtual folders and collections never move the physical project directory; they remain recoverable from `character.json` when the disposable library cache is rebuilt.

### `shared_context`

Facts available to every character in the project:

- `title` — optional name for the shared setup.
- `premise` — why the characters are together or what the project is about.
- `setting` — shared world/location/era information.
- `situation` — current opening circumstances.
- `shared_rules` — continuity, tone, or behavioural constraints.
- `notes` — private project-planning notes.

Normal character generation, field suggestions, and controlled builds can use shared context as read-only consistency guidance. Relationship-aware and multi-character workflows can combine this project context with the structured relationship matrix.

### `characters[]`

Each item is an independent character record:

```text
character_id
created_at
updated_at
metadata
concept
character
generation
assets
workspace
```

Each character keeps its own:

- name, summary, tags, optional group role, creator, and character-version metadata;
- freeform concept;
- template-backed card fields;
- preserved interoperability fields such as alternate greetings, embedded character lorebooks, and raw card extensions;
- selected template;
- generation history;
- asset references;
- Character Builder state and editor state.

Characters can therefore use different templates inside the same project.

### `relationships[]`

Project-level structured relationships introduced in v0.6. Each defined unordered character pair is stored once using stable character UUIDs:

```text
relationship_id
character_a_id
character_b_id
label
status
summary
a_to_b
b_to_a
dynamic
notes
tags[]
intensity
updated_at
```

`a_to_b` and `b_to_a` preserve directional asymmetry without duplicating the relationship into both character records. Empty pairs are not stored. Relationship context can be supplied to character and multi-character generation as read-only continuity guidance.

See `relationships.md` for the editor and AI workflow.

### `card_workflows[]`

Reusable project-level multi-character output plans introduced in v0.6. A workflow stores:

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

Member entries reference stable character UUIDs and contain output-specific directions rather than copies of the source character. Current modes are `multi_single`, `split_batch`, and `group_card`.

See `card_workflows.md` for details.

### `workspace`

Project-level editor state currently includes:

- `active_character_id`
- `selected_project_tab`

Character-specific workspace state remains inside each character record.

## Character workspace adapter

The editor internally presents the active character through the same paths used by earlier versions, such as:

```text
concept.prompt
character.name
character.personality
metadata.tags
workspace.builder
```

This is an editor adapter only. On save, those fields are merged back into the matching item in `characters[]`. The project file therefore has one authoritative copy of each character rather than mirrored active-character data.

## Generation history

Generation history remains metadata rather than a second copy of card content. Applied AI changes may record:

- generation timestamp;
- model ID;
- API profile display name;
- generation job type;
- accepted field IDs;
- request attempt count;
- parse strategy;
- automatic response-repair count.

Discarded previews are not written into project content.

## Assets

Large binary data should remain ordinary files beside the JSON project rather than being embedded into JSON.

v0.5 creates project-level asset directories and per-character directories ready for later image/attachment work:

```text
<project UUID>/
├── character.json
├── assets/
├── generated_images/
├── emotion_images/
└── characters/
    └── <character UUID>/
        ├── assets/
        ├── generated_images/
        └── emotion_images/
```

Existing asset references remain preserved during migration.

## Template-defined custom data

Templates may still expose arbitrary dot-separated paths inside a character record. Custom fields should normally live below `character.custom`, for example:

```text
character.custom.occupation
character.custom.relationship_style
character.custom.world.faction
```

Unknown character data is preserved even when the active template does not display it.

## Format-v1 migration

When a v0.4-era project is loaded:

1. The old single character becomes the first item in `characters[]`.
2. Its concept, card data, generation history, assets, template choice, custom fields, and builder state are preserved.
3. Its former library metadata is copied to both the new project metadata and the character metadata where appropriate.
4. A new stable `character_id` is assigned.
5. `workspace.active_character_id` points to the migrated character.
6. The file is not rewritten until the user explicitly saves.

This migration exists for Character Card Forge's own Godot-development formats; compatibility with the original legacy PyWebView database is still intentionally out of scope.

## v0.6 relationship and workflow compatibility

The format version remains `2` because `relationships[]` was reserved by the v0.5 container model and new project-level arrays are optional additive data. Older v0.5 projects therefore load without a migration step and receive empty relationship/workflow collections by default.

Project duplication remaps relationship endpoints and workflow character references to the duplicated character UUIDs. Character removal drops affected relationships and prunes invalid workflow references.

## v0.7 interoperability fields

Project format version remains `2`. Existing character records receive additive defaults during normalisation:

```text
metadata.creator
metadata.character_version
character.alternate_greetings[]
character.character_book{}
character.card_extensions{}
interoperability{}          # created for imported external cards when applicable
```

`character.card_extensions` stores arbitrary Character Card V2 extension data that CCF did not author. CCF's own exported round-trip metadata uses the namespaced `character_card_forge/v1` key inside the external V2 `data.extensions` object.

`character.character_book` is preserved as raw structured data until a dedicated lorebook editor is implemented. The absence of a dedicated editor must not cause imported lorebooks to be discarded on later export.

Imported external cards may include an `interoperability` object recording source format/spec details and import time. This is CCF metadata and is not a second copy of the card.

## Portable project packages

The internal `character.json` file remains the source of truth. v0.7 adds `.ccfproject` as a transport container rather than a new project database.

A package stores the current project JSON, project assets, a package manifest, and referenced custom templates in a renamed ZIP archive. Import assigns a fresh project UUID and then passes the extracted project through the normal storage service.

See `project_packages.md` for the archive contract.

## v0.8 library organisation and cache

Character Library 2.0 adds the following additive project metadata:

```text
metadata.library.folder
metadata.library.collections[]
```

These values are part of `character.json` and travel inside `.ccfproject` packages. Favourites and tags continue to live in normal project/character metadata.

The following files are **not** part of the project format and may be deleted safely:

```text
user://character_card_forge/cache/library_index.json
user://character_card_forge/cache/library_thumbnails/
user://character_card_forge/settings/library_view.json
```

The first two are rebuildable accelerators. `library_view.json` contains only browsing preferences such as grid/list mode, sorting, and active filters.


## v0.9 series assignment

`metadata.series_id` is now active project-level data. It stores either an empty string or the stable ID of a standalone file under `user://character_card_forge/series/`.

The series definition is deliberately not embedded in `character.json`. This lets many projects share one current bible and avoids duplicated stale guidance. Missing IDs are retained as repairable references. The project schema remains format version 2 because series assignment was already reserved in metadata and is additive.

Portable `.ccfproject` packages may include the referenced series JSON and remap the project ID on collision-safe import. See `series_format.md` and `series_system.md`.
