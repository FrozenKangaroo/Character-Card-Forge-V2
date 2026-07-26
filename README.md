# Character Card Forge — Godot Rewrite

Character Card Forge is being rebuilt from scratch as a native Godot 4.6 desktop application. The original PyWebView application is a feature reference only: its legacy database, frontend architecture, and interface are not compatibility targets.

## v0.12 development candidate

v0.11.0 established the first native Image Generation Studio. The current v0.12 development branch expands that foundation with a dedicated local Stable Diffusion Forge / Automatic1111 path while preserving the OpenAI-compatible Images API workflow, and begins a source-audited generation-parity programme based on the useful behaviour of Character Card Forge V1.

Release/application metadata intentionally remains at v0.11.0 until this candidate is parsed by CI, tested against a real local image backend, and smoke-tested with the revised default text-generation contract. The normal release helper can perform the coordinated v0.12.0 version promotion afterward.

### Generation parity — Phase 1

The first parity pass deliberately improves the data-driven built-in template before attempting V1's larger multi-stage generation pipeline.

- Treat the user's Generation Concept as authoritative source material rather than loose inspiration.
- Preserve supplied names, relationships, premise, setting, visible details, clothing, props, requested dynamics, and explicit opening beats instead of casually replacing them.
- Restore **Description** to its V1-style job: visible physical appearance and external presentation rather than a mixture of appearance, biography, personality, and scenario facts.
- Ask Description to organise the standard Character Card field with labelled **Age**, **Appearance**, **Outfit Style**, and **Distinguishing Features** content.
- Expand **Personality** generation into labelled **Core Traits**, **Motivation**, **Behavior Toward {{user}}**, **Speech Style**, **Strengths**, **Flaws**, **Likes**, **Dislikes**, and **Habits / Mannerisms** while still using the interoperable Character Card Personality field.
- Make Scenario and First Message describe the same immediately playable starting situation.
- Preserve explicit scenario/greeting material from the source concept where it exists.
- Ask Example Dialogue for exactly one `<START>` marker followed by one continuous 2-3 exchange conversation.
- Strengthen required-field and cross-field consistency instructions without changing project format 2 or template format 2.

This is intentionally only Phase 1. The V1 source audit also found private pre-generation Q&A, required-output validation, targeted missing-section repair, concept-fidelity retries, builder precedence, and multi-pass generation. Those are now staged in `roadmap.md` for the Generation Parity Core milestone rather than being squeezed into one risky change.

### Image generation

- Assign reusable API profiles independently to **Text generation**, **Vision analysis**, and **Image generation** roles.
- Choose an image backend per profile:
  - OpenAI-compatible Images API;
  - Stable Diffusion Forge / Automatic1111 WebUI API.
- Send OpenAI-compatible requests to `/images/generations`.
- Send Forge/A1111 requests to `/sdapi/v1/txt2img`.
- Discover OpenAI-compatible model IDs through `/models`.
- Discover Stable Diffusion checkpoints and samplers through `/sdapi/v1/sd-models` and `/sdapi/v1/samplers`.
- Override the image model/checkpoint per generation.
- Build editable natural-language or Stable Diffusion-style prompts from the central character model.
- Use real Stable Diffusion negative prompts on Forge/A1111; OpenAI-compatible routes retain provider-neutral exclusion guidance.
- Control image size, batch size, sampler, steps, CFG, and seed where the selected backend supports them.
- Capture returned Stable Diffusion seeds so gallery images retain reproducible generation recipes.
- Generate batches and save the completed batch into the project in one update.
- Regenerate a gallery image from its stored prompt/settings/seed.
- Create a **New Seed Variant** from the stored generation recipe.
- Accept common base64, data-URL, remote-URL, and raw-image provider responses.
- Normalise received PNG, JPEG, and WebP images into managed PNG files.
- Keep generated artwork in the existing per-character `generated_images/` tree with lightweight metadata in `character.json`.
- Browse generated images in a persistent gallery and promote a selected image to the character portrait without duplicating image bytes.
- Warn when Image Studio is opened while the main workspace has unsaved edits because the studio deliberately uses saved project state.

See `docs/image_generation.md` for backend URLs, request behaviour, seeds, batches, generated-image records, portability, and the next image-workflow phase.

### Vision and attachments

The v0.10.0 foundation remains intact:

- Attach images, GIFs, text files, PDFs, subtitles, transcripts, notes, and arbitrary reference files at project or character scope.
- Keep attachment metadata in `character.json` while copying source files into ordinary project asset folders.
- Inspect file type, size, image dimensions where available, text length, and estimated prompt size.
- Include enabled notes and supported text attachments in existing character, field, controlled-build, group, relationship, and card-workflow prompts.
- Analyse an image through the Vision role using Concept Extraction or Full-card Suggestions.
- Send every visual proposal into the existing detachable Generation Preview; no vision result overwrites card content directly.

PDFs are stored portably and represented by metadata in the current foundation; native PDF text extraction is still planned. See `docs/vision_attachments.md` for the schema, context rules, supported formats, provider requirements, and limitations.

### Automated desktop releases

A pushed `vX.Y.Z` tag triggers GitHub Actions to:

- download the matching official Godot 4.6.3 editor and export templates;
- validate release metadata and bundled JSON;
- import and parse the project headlessly;
- export Windows x86-64, Linux x86-64, and macOS Universal builds;
- package Windows and Linux downloads;
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

The helper now keeps the staging checkout current automatically:

- fetches the latest `origin/main`;
- fast-forwards a clean destination checkout;
- automatically reconciles the common case where locally synced files already exactly match a newly merged `origin/main`;
- stops before overwriting genuinely different local work;
- refuses silently diverged Git history;
- performs a safe additive `rsync` into `~/Projects/Character-Card-Forge-V2`;
- excludes generated/local output and never deletes repository-only files by default;
- continues execution from the Git checkout after sync.

An alternate checkout can be selected with `CCF_REPO_DIR=/path/to/clone ./release.sh`.

The Godot-native helper keeps two release paths:

1. synchronise the version, validate, commit, push `main`, create an annotated tag, and trigger release builds;
2. validate, commit, and push source changes without making a release.

`tools/set_version.py` synchronises the application version across Godot project settings, runtime display, portable package manifests, and export presets. Published tags are not deleted or reused; a failed published version should be followed by a patch bump.

### Export presets

Committed `export_presets.cfg` definitions cover:

- `Windows Desktop` — embedded-PCK x86-64 executable;
- `Linux x86_64` — embedded-PCK native executable;
- `macOS Universal` — unsigned Universal 2 ZIP for Intel and Apple Silicon.

Bundled JSON remains explicitly included in every export because builder schemas, presets, and templates are runtime data.

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
- V1-inspired concept-fidelity/physical-description/personality generation contract in the v0.12 candidate.
- Per-field AI suggestions.
- Idea Generator.
- Shared queued OpenAI-compatible text/vision generation service.
- Cancellation, retry handling, malformed-JSON recovery, and one JSON repair pass.
- Multiple API profiles and compatible `/models` discovery.
- Separate text-generation, vision-analysis, and image-generation provider roles.
- Managed project/character attachments with context budgeting and review-first visual analysis.
- Independent image-generation and image-capability services.
- OpenAI Images plus Forge/A1111 image adapters in the v0.12 candidate.

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

The built-in Default template remains read-only. Duplicate it before editing. The v0.12 candidate keeps template format 2 unchanged while making the built-in generation instructions much closer to V1's field responsibilities. The later Generation Parity Core milestone will introduce explicit generation components/output bindings with migration rather than overloading today's field model.

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
- Image Generation Studio

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

- `scripts/services/storage_service.gd` — format-v2 project persistence, migration, roster helpers, reference maintenance, library-row extraction, and user-data layout.
- `scripts/services/series_service.gd` — versioned series persistence, matching, assignment, generation context, default tags, JSON import/export, and `.ccfseries` packaging.
- `scripts/services/library_service.gd` — disposable incremental indexing, thumbnail caching, view-state persistence, series decoration, virtual organisation, favourites, and bulk tools.
- `scripts/services/card_format_service.gd` — Character Card V1/V2 normalisation, mapping, validation, JSON import/export, PNG metadata read/write, and CCF extension round trips.
- `scripts/services/project_package_service.gd` — `.ccfproject` ZIP packaging, asset/template/series inclusion, safe extraction, and ID collision handling.
- `scripts/services/relationship_service.gd` — relationship pair normalisation and generation-context rendering.
- `scripts/services/settings_service.gd` — settings format v6, reusable Character AI profiles, dedicated image-provider profiles, text/vision roles, image backend types, and backend-specific image defaults.
- `scripts/services/template_service.gd` — template storage, migration, validation, import/export, and field discovery.
- `scripts/services/builder_service.gd` — builder schema/state, presets, concept composition, and character transfer logic.
- `scripts/services/tool_window_state_service.gd` — detachable-window geometry persistence.
- `scripts/services/generation_service.gd` — queued text and multimodal jobs including character, builder, controlled, group-scene, relationship, card-workflow, series, and vision analysis.
- `scripts/services/image_generation_service.gd` — OpenAI Images and Forge/A1111 generation adapters, batches, reproducible metadata, result decoding, and managed PNG persistence.
- `scripts/services/image_capability_service.gd` — image model/checkpoint/sampler discovery and backend capability summaries.
- `scripts/services/attachment_service.gd` — managed attachment import, format normalisation, preprocessing summaries, context budgeting, and vision image payloads.
- `scripts/ui/series_manager_view.gd` — native Series Manager and AI series-bible editor.
