# Character Card Forge — Godot Rewrite

Character Card Forge is being rebuilt from scratch as a native Godot 4.6 desktop application. The original PyWebView application is a feature reference only: its legacy database, frontend architecture, and interface are not compatibility targets.

## Version 0.10.0 scope

v0.10.0 begins the **Vision and Attachments Foundation**. Character projects can now contain managed local reference files and notes, ordinary generation can use a configurable attachment-context budget, and image-capable OpenAI-compatible models can propose review-first character concepts or controlled full-card suggestions.

### Vision and attachments

- Assign existing API profiles independently to **Text generation** and **Vision analysis** roles.
- Attach images, GIFs, text files, PDFs, subtitles, transcripts, notes, and arbitrary reference files at project or character scope.
- Keep attachment metadata in `character.json` while copying source files into ordinary project asset folders.
- Inspect file type, size, image dimensions where available, text length, and estimated prompt size.
- Include enabled notes and supported text attachments in existing character, field, controlled-build, group, relationship, and card-workflow prompts.
- Analyse an image through the Vision role using Concept Extraction or Full-card Suggestions.
- Send every visual proposal into the existing detachable Generation Preview; no vision result overwrites card content directly.

PDFs are stored portably and represented by metadata in this foundation release; native PDF text extraction is still planned. See `docs/vision_attachments.md` for the schema, context rules, supported formats, provider requirements, and current limitations.

### Automated desktop releases

A pushed `vX.Y.Z` tag now triggers GitHub Actions to:

- download the matching official Godot 4.6.3 editor and export templates;
- validate release metadata and bundled JSON;
- import and parse the project headlessly;
- export Windows x86-64, Linux x86-64, and macOS Universal builds;
- package the Windows and Linux downloads;
- publish the unsigned macOS Universal ZIP;
- generate `SHA256SUMS.txt`;
- create a GitHub Release and attach all downloads.

The macOS build is intentionally unsigned and unnotarised for now. See `docs/releasing.md` for first-launch guidance and the future signing path.

### Local release helper

Run the helper from the development project directory:

```bash
cd /home/damee/character-card-forge
./release.sh
```

It automatically performs a safe additive sync into `~/Projects/Character-Card-Forge-V2`, excludes generated/local output, and then continues from the Git checkout. Repository-only files are not deleted. An alternate checkout can be selected with `CCF_REPO_DIR=/path/to/clone ./release.sh`.

The Godot-native helper preserves the useful two-path workflow from the old PyWebView app:

1. synchronise the version, validate, commit, push `main`, create an annotated tag, and trigger release builds;
2. validate, commit, and push source changes without making a release.

`tools/set_version.py` synchronises the application version across Godot project settings, runtime display, portable package manifests, and export presets. Published tags are not deleted or reused; a failed published version should be followed by a patch bump.

### Export presets

Committed `export_presets.cfg` definitions cover:

- `Windows Desktop` — embedded-PCK x86-64 executable;
- `Linux x86_64` — embedded-PCK native executable;
- `macOS Universal` — unsigned Universal 2 ZIP for Intel and Apple Silicon.

Bundled JSON remains explicitly included in every export because the builder schemas, presets, and templates are runtime data.

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
- Separate text-generation and vision-analysis provider roles.
- Managed project/character attachments with context budgeting and review-first visual analysis.

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
- Vision and Attachments

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
│       ├── attachments/
│       ├── generated_images/
│       ├── emotion_images/
│       └── characters/
│           └── <character UUID>/
│               ├── assets/
│               ├── attachments/
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
- `scripts/services/settings_service.gd` — settings format v3, API profiles, and text/vision role assignments.
- `scripts/services/template_service.gd` — template storage, migration, validation, import/export, and field discovery.
- `scripts/services/builder_service.gd` — builder schema/state, presets, concept composition, and character transfer logic.
- `scripts/services/tool_window_state_service.gd` — detachable-window geometry persistence.
- `scripts/services/generation_service.gd` — queued text and multimodal jobs including character, builder, controlled, group-scene, relationship, card-workflow, series, and vision analysis.
- `scripts/services/attachment_service.gd` — managed attachment import, format normalisation, preprocessing summaries, context budgeting, and vision image payloads.
- `scripts/ui/series_manager_view.gd` — native Series Manager and AI series-bible editor.
- `scripts/ui/library_view.gd` — Character Library 2.0 browsing, series filters, detail summaries, and bulk project management.
- `scripts/ui/library_project_card.gd` — reusable thumbnail-grid project card.
- `scripts/ui/workspace_view.gd` — active-character workspace, project/roster coordination, and series assignment.
- `scripts/ui/import_export_window.gd` — mapping preview, card import/export, portable project packages, and batch export.
- `scripts/ui/attachment_manager_window.gd` — project/character attachment management and review-first vision analysis.
- `scripts/ui/project_context_window.gd` — shared project-context editor.
- `scripts/ui/group_scene_window.gd` — multi-character group-scene generation and review.
- `scripts/ui/relationship_matrix_window.gd` — structured pair-matrix editor and AI relationship drafting.
- `scripts/ui/card_workflow_window.gd` — saved multi-character card workflow planning.
- `scripts/ui/character_builder_window.gd` — guided Character Builder.
- `scripts/ui/controlled_build_window.gd` — controlled section and revision workflows.
- `scripts/ui/template_manager_view.gd` — native template editor.

See the `docs/` directory for current format and workflow documentation.
