# Character Card Forge — Godot Rewrite

Character Card Forge is being rebuilt from scratch as a native Godot 4.6 desktop application. The original PyWebView application is a feature reference only: its legacy database, frontend architecture, and interface are not compatibility targets.

## Version 0.9.1 scope

v0.9.1 retains the **Series System Foundation** feature set and adds a Godot 4.6 strict-warning maintenance pass. Series are reusable, standalone JSON definitions that can organise many projects and provide shared continuity, setting, visual, and generation guidance without duplicating those rules into every character card.

Existing format-v2 projects remain compatible. An unassigned project simply keeps an empty `metadata.series_id`; assigning a series is additive and does not change the project format version.

### Native Series Manager

Open **Series** from the main sidebar to:

- create, edit, duplicate, save, and delete series definitions;
- record names, aliases, descriptions, categories, setting guidance, canon notes, visual direction, generation rules, default tags, and auto-match keywords;
- search the local series library and see project usage counts;
- import/export individual series JSON files;
- export or import one or more series as a portable `.ccfseries` renamed-ZIP Series Pack;
- generate or improve a structured series bible through the active OpenAI-compatible text profile;
- run Auto Assign across currently unassigned saved projects.

Series definitions live under `user://character_card_forge/series/` and remain independent from character projects. See `docs/series_system.md` and `docs/series_format.md`.

### Project assignment and Auto Series

The Character Workspace now includes a project-level Series selector plus:

- **Auto Series**, which scores local names, aliases, matching keywords, default tags, and categories against the current project;
- **Apply Series Tags**, which copies missing series default tags into project metadata;
- **Manage Series**, which opens the Series Manager.

Auto assignment is deterministic and local. Ambiguous ties are not silently applied. Deleting a series does not erase a project's stored series ID; the workspace and library show a repairable missing reference instead.

### Series-aware generation

Assigned series guidance is now supplied to:

- full-character generation;
- per-field AI suggestions;
- Safe Section Build, Custom Section Build, and Revision;
- Character Builder filling and concept extraction;
- Group Scene Generator;
- Relationship Matrix generation;
- Card Workflow Studio planning.

The series bible is treated as protected continuity and style context rather than content to copy verbatim into every field.

### Character Library integration

Character Library 2.0 now supports:

- Series and Unassigned filters;
- series names in search results, compact rows, grid cards, and project details;
- bulk series assignment or clearing;
- bulk Auto Series matching;
- bulk application of assigned-series default tags.

The disposable library cache resolves series names at refresh time, so editing a series does not rewrite every assigned project.

### Portable interoperability

- `.ccfproject` packages include the assigned series definition when it is available locally.
- Package imports remap colliding series IDs safely and update the imported project reference.
- Character Card V2 exports preserve the CCF series ID and display name inside the existing namespaced `character_card_forge/v1` extension.
- Individual card imports restore the series ID as a project-level reference without pretending series data is part of the Character Card standard.

## Existing major systems

### Character creation and AI

- Template-driven character workspace.
- Guided Character Builder with Foundation, Personality, Background, Scene, and Review steps.
- Data-driven builder presets.
- AI Fill This Step / AI Fill All Builder Fields.
- Concept-to-builder extraction.
- Safe Section Build.
- Custom Section Build.
- Selected-field revision workflows.
- Full-character generation with editable Generation Preview.
- Per-field AI suggestions.
- Idea Generator.
- Shared queued OpenAI-compatible generation service.
- Cancellation, retry handling, malformed-JSON recovery, and one AI repair pass.
- Multiple API profiles and compatible `/models` discovery.

### Multi-character systems

- Multiple independent characters per project.
- Shared project context.
- Group Scene Generator.
- Structured Relationship Matrix with directional perspectives and AI drafting.
- Card Workflow Studio for multi-character single-card, split-card, and group-card plans.

### Import/export

- Character Card V1 and V2 JSON import.
- Character Card V2 JSON export.
- PNG/APNG `chara` metadata reading.
- V2 PNG export using existing artwork.
- Split-workflow batch JSON export.
- Portable `.ccfproject` renamed-ZIP packages with assets, templates, and assigned series.

### Character Library 2.0

- Thumbnail-grid and compact-list views.
- Disposable incremental search index and portrait cache.
- Broad project, character, card-text, creator, tag, folder, collection, interoperability, and series search.
- Favourites, sorting, virtual folders, collections, filters, bulk maintenance, and tag merging.

## Template system

Open **Templates** from the sidebar to:

- create, duplicate, import, export, and delete user templates;
- add and reorder sections and fields;
- create Standard or Interview/Q&A sections;
- use line, multiline, tags, number, checkbox, and select fields;
- define required and AI-generatable fields;
- add field-specific and global AI instructions;
- choose strict or flexible AI output handling.

The built-in Default template remains read-only. Duplicate it before editing.

## Desktop tool windows

Substantial tools use native operating-system windows and can be dragged outside the main Character Card Forge frame:

- Character Builder
- Controlled Build
- Idea Generator
- Generation Preview
- Shared Project Context
- Group Scene Generator
- Relationship Matrix
- Card Workflow Studio
- Import / Export Studio

Their size and position are stored as disposable UI state rather than project content. The Series Manager itself is a full main-navigation workspace.

## Running

Open this folder in Godot 4.6.x and run the project.

No Python runtime, web server, PyWebView, Node.js, or browser frontend is required.

## User data

Godot stores application data under its normal `user://` location:

```text
character_card_forge/
├── settings/
│   ├── app_settings.json
│   ├── library_view.json
│   └── tool_windows.json
├── templates/
│   └── <template_id>.json
├── series/
│   └── <series_id>.json
├── characters/
│   └── <project UUID>/
│       ├── character.json
│       ├── assets/
│       ├── generated_images/
│       ├── emotion_images/
│       └── characters/
│           └── <character UUID>/
│               ├── assets/
│               ├── generated_images/
│               └── emotion_images/
├── cache/
│   ├── library_index.json
│   └── library_thumbnails/
└── exports/
```

`character.json` and standalone series/template JSON files remain authoritative. Large assets stay as ordinary files referenced by relative paths. Character Card JSON/PNG, `.ccfproject`, and `.ccfseries` files are interchange formats, not replacement databases.

## Architecture

- `scripts/services/storage_service.gd` — format-v2 project persistence, v1 migration, roster helpers, reference maintenance, library-row extraction, and user-data layout.
- `scripts/services/series_service.gd` — versioned series persistence, matching, assignment, generation context, default tags, JSON import/export, and `.ccfseries` packaging.
- `scripts/services/library_service.gd` — disposable incremental indexing, thumbnail caching, view-state persistence, series decoration, virtual organisation, favourites, and bulk tools.
- `scripts/services/card_format_service.gd` — Character Card V1/V2 normalisation, mapping, validation, JSON import/export, PNG metadata read/write, and CCF extension round trips.
- `scripts/services/project_package_service.gd` — `.ccfproject` ZIP packaging, asset/template/series inclusion, safe extraction, and ID collision handling.
- `scripts/services/relationship_service.gd` — relationship pair normalisation and generation-context rendering.
- `scripts/services/settings_service.gd` — application settings and API profiles.
- `scripts/services/template_service.gd` — template storage, migration, validation, import/export, and field discovery.
- `scripts/services/builder_service.gd` — builder schema/state, presets, concept composition, and character transfer logic.
- `scripts/services/tool_window_state_service.gd` — detachable-window geometry persistence.
- `scripts/services/generation_service.gd` — queued AI jobs including character, builder, controlled, group-scene, relationship, card-workflow, and series generation.
- `scripts/ui/series_manager_view.gd` — native Series Manager and AI series-bible editor.
- `scripts/ui/library_view.gd` — Character Library 2.0 browsing, series filters, detail summaries, and bulk project management.
- `scripts/ui/library_project_card.gd` — reusable thumbnail-grid project card.
- `scripts/ui/workspace_view.gd` — active-character workspace, project/roster coordination, and series assignment.
- `scripts/ui/import_export_window.gd` — mapping preview, card import/export, portable project packages, and batch export.
- `scripts/ui/project_context_window.gd` — shared project-context editor.
- `scripts/ui/group_scene_window.gd` — multi-character group-scene generation and review.
- `scripts/ui/relationship_matrix_window.gd` — structured pair-matrix editor and AI relationship drafting.
- `scripts/ui/card_workflow_window.gd` — saved multi-character card workflow planning.
- `scripts/ui/character_builder_window.gd` — guided Character Builder.
- `scripts/ui/controlled_build_window.gd` — controlled section and revision workflows.
- `scripts/ui/template_manager_view.gd` — native template editor.

See the `docs/` directory for current format and workflow documentation.
