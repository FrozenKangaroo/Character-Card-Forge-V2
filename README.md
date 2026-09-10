# Character Card Forge — Godot Rewrite

Character Card Forge is being rebuilt from scratch as a native Godot 4.7 desktop application. The original PyWebView application remains a feature and generation-behaviour reference; its legacy database, frontend architecture, and interface are not compatibility targets.

## Current development candidate: v0.18.3 AI Review, Rating and Selective Improvement

v0.18.3 adds an optional **AI Review** workspace tool beside the deterministic Card
Inspector. It checks consistency across identity, appearance, personality, scenario,
greetings and lore, then shows a locally calculated advisory score using a visible
eight-part rubric. Reviews store their content hash, model/profile and private history;
they become stale after relevant edits and never rerun just because the library opens.
Every proposed field is shown with its current and replacement value, defaults to
Reject, and can be approved or edited only through the complete visible change set.
Rejected proposals and intentionally dismissed findings remain recorded. Accepted
batches create revision recovery checkpoints and AI Review history stays out of
ordinary Character Card exports.

v0.18.2 adds a consolidated **Card Inspector** with advisory health findings,
per-section token estimates, an explicitly approximate compiled-prompt view, technical
metadata, validated expert Raw JSON editing, missing-file relinking, group-member
reference repair and a private configurable quality checklist. Import preview now
shows the source portrait, detected format/version, estimated size, validation,
duplicate evidence and migration/loss mapping before explicit Copy, Merge, Replace
or Cancel choices. Content-changing expert and import actions use v0.18.1 recovery
checkpoints; no health or checklist result blocks unusual intentional cards.

v0.18.1 adds durable per-character revision history. **Revision History** can create
named checkpoints, compare any checkpoint with the current character or another
checkpoint, inspect full before/after values, selectively apply checked fields,
restore without deleting later work, fork an earlier revision into a new character
or compare/copy selected fields from another project character, and export an earlier
revision as standard Character Card V2 JSON. Save, accepted AI
changes, imports, selective merges, forks and restores create meaningful recovery
points; unchanged automatic saves are deduplicated. Per-character retention and
portable-project inclusion controls prevent unbounded history. Image assets remain
references rather than being copied into every checkpoint, and private fork lineage
is omitted from ordinary earlier-revision card export.

v0.18.0-hotfix3 enables automatic visual word wrapping in the Lorebook Manager's **Lore content** editor and **Trigger Preview** sample-text box. Long paragraphs now flow across visible lines without requiring manual line breaks. Wrapping does not insert newline characters or change saved lore and trigger matching.

v0.18.0-hotfix2 adds a dedicated **Settings → Updates** page, a manual **Check Now** action and an optional automatic check in packaged builds. The automatic check is enabled by default, runs at startup no more than once every 24 hours and makes one unauthenticated request to this repository's public latest-release endpoint. It sends no AI-provider credentials or character/project data. When a newer stable release exists, CCF shows a sidebar notice, release notes and the exact published package for the current platform. Download remains an explicit browser handoff: CCF never silently replaces its running executable or edits user projects during an update check.

v0.18.0-hotfix1 makes Safe Section generation tolerant of models that return usable prose for a text field instead of the requested one-key JSON object. Standalone line/multiline text, focused text-field repair and focused output-component repair can recover locally, then pass through the same field validation, agency and cross-section contamination guards as normal JSON. Tags, numbers, checkboxes, selects, output groups and malformed object-shaped replies remain strict. When a remote JSON repair is still needed, the request now identifies the exact field or component shape instead of asking for an unspecified object. A conservative local repair also covers the captured missing outer-string quote failure.

The underlying v0.18.0 candidate adds a project-level Front Porch World Studio with lossless `.fpworld` import/export, bare-lorebook compatibility, manual world/lore/climate authoring, embedded cover preparation and optional Stoop metadata. Imported unknown fields and additional lorebooks survive known-field edits. Every world export requires a private-context review and adult worlds require an additional declaration confirmation. Stoop preparation is local only: this version performs no direct publishing, network calls or Front Porch database writes. It retains the v0.17.5 avatar-gallery, Character Life suggestion, export-safety and Godot 4.7.2 warning fixes.

The current public release baseline is v0.18.0. A source development candidate is not automatically treated as a published release.

See `docs/v0183-ai-review.md` for the AI Review rubric, staleness and explicit-apply
boundary, `docs/v0182-card-health-inspection.md` for inspection and reviewed import
boundaries, `docs/v0181-revision-safety.md` for the revision model and recovery boundaries,
`docs/v0180-hotfix3-lorebook-word-wrap.md` for the wrapping behavior,
`docs/v0180-hotfix2-github-update-checks.md` for the update-check privacy and install
boundary, `docs/v0180-hotfix1-safe-section-text-recovery.md` for the recovery boundary
and `docs/v0180-front-porch-worlds.md` for the `.fpworld` round-trip contract.

### Semantic character-generation validation and repair

Full-character generation now uses a data-driven completeness contract in addition to the existing JSON parsing/repair path.

The current Default contract checks:

- required AI-generatable top-level fields from the active template;
- Description labels: **Age**, **Appearance**, **Outfit Style**, **Distinguishing Features**;
- Personality labels: **Core Traits**, **Motivation**, **Behavior Toward {{user}}**, **Speech Style**, **Strengths**, **Flaws**, **Likes**, **Dislikes**, **Habits / Mannerisms**;
- minimum useful content lengths for selected fields;
- exactly one `<START>` marker when Example Dialogue is returned.

The generation flow is now:

```text
Generate
  ↓
Parse / repair malformed JSON
  ↓
Validate semantic generation contract
  ↓
Complete? ── yes ──→ Generation Preview
  │
  no
  ↓
One targeted semantic repair pass
  ↓
Revalidate
  ↓
Generation Preview
```

The repair request receives the authoritative source concept, complete current generated JSON, and exact missing requirements. It is instructed to preserve good existing material and return a complete repaired object rather than loose fragments.

Only one semantic repair pass is allowed in this first implementation to avoid runaway repeated requests. While it runs, the normal queue/status UI displays **Repairing incomplete character generation**, and cancellation remains available.

Generation Preview is still the review boundary: generation and repair never silently apply the proposal to project data.

See `docs/generation_parity.md` for the source-audited V1 behaviour, current contract format, and the remaining v0.13 work including private Q&A, generation components/output bindings, builder precedence, and conservative concept-fidelity retry.

## Image generation

The v0.12 source milestone adds dedicated image-provider profiles independent from Character AI credentials/models.

Supported image backends currently include:

- OpenAI-compatible Images APIs;
- Stable Diffusion Forge / Automatic1111 WebUI APIs.

Current image capabilities include:

- `/images/generations`, OpenRouter `/api/v1/images`, and `/sdapi/v1/txt2img` generation;
- OpenAI model discovery through `/models`;
- Forge/A1111 checkpoint and sampler discovery;
- natural-language and Stable Diffusion-style character prompt builders;
- real SD negative prompts;
- size, batch, sampler, steps, CFG, seed, and checkpoint/model controls where supported;
- returned SD seed capture;
- gallery **Regenerate** and **New Seed Variant** workflows;
- base64, data-URL, remote-URL, and raw image response handling;
- PNG/JPEG/WebP normalisation into managed PNG assets;
- persistent per-character gallery records and portrait assignment.

Provider connection settings live in **Settings → Image Generation**. Image Studio is a normal primary workspace used for generation rather than connection credentials.

See `docs/image_generation.md` for backend URLs, request behaviour, metadata, and portability.

## Vision and attachments

The v0.10 foundation supports:

- project- and character-scoped images, GIFs, text, PDFs, subtitles, transcripts, notes, and reference files;
- ordinary managed attachment files with lightweight JSON metadata;
- preprocessing summaries, token/context estimates, and prompt budgeting;
- attachment context in character, controlled-build, group, relationship, and card-workflow generation;
- review-first image/GIF Concept Extraction and Full-card Suggestions through the Vision role.

PDF files are currently stored portably with metadata; native PDF text extraction remains planned.

See `docs/vision_attachments.md` for details.

## Existing major systems

### Character creation and AI

- Template-driven character workspace.
- Guided Character Builder with data-driven steps and presets.
- AI builder fill and concept extraction.
- Safe Section Build, Custom Section Build, and selected-field revision.
- Full-character generation with editable Generation Preview.
- Semantic generation completeness/repair foundation in the v0.13 candidate.
- Per-field AI suggestions and Idea Generator.
- Shared queued OpenAI-compatible text/vision generation service.
- Cancellation, network retries, JSON extraction/repair, and generation diagnostics.
- Multiple Character AI profiles with independent Text and Vision roles.
- Managed attachments and review-first visual analysis.

### Multi-character systems

- Multiple independent characters per project.
- Shared project context.
- Group Scene Generator.
- Structured directional Relationship Matrix with AI drafting.
- Card Workflow Studio for multi-character single-card, split-card, and group-card plans.
- Front Porch 1.0 multi-character group-card authoring with manual or review-first AI writing fields.

### Import/export

- Character Card V1 and V2 JSON import.
- Character Card V2 JSON export.
- Export-readiness protection for concept-only drafts, with an explicit missing-artwork confirmation for text-only cards.
- PNG/APNG `chara` metadata reading.
- V2 PNG export using existing artwork.
- Split-workflow batch JSON export.
- Portable Front Porch `fpa_group` PNG import/export with embedded member artwork and fresh-ID remapping.
- Front Porch expression/alternate-look galleries from Image Studio or manual images, with portable ZIP and supported API installation.
- Portable `.ccfproject` renamed-ZIP packages with assets, templates, and assigned series.

### Character Library 2.0

- Thumbnail-grid and compact-list views.
- Disposable incremental search index and portrait cache.
- Broad project/character/card-text/creator/tag/folder/collection/series search.
- Favourites, sorting, folders, collections, filters, bulk maintenance, and tag merging.

### Series system

- Versioned series bibles.
- Series Manager.
- Categories, aliases, canon notes, visual guidance, generation rules, tags, and matching keywords.
- Deterministic local Auto Series matching.
- Portable `.ccfseries` packages.

## Template system

Open **Templates** from the sidebar to:

- create, duplicate, import, export, and delete user templates;
- add and reorder sections and workspace fields;
- create Standard or Interview/Q&A sections;
- use line, multiline, tags, number, checkbox, and select fields;
- define required and AI-generatable fields;
- add per-field and global AI instructions;
- choose strict or flexible unexpected-output handling.

The built-in Default template remains read-only; duplicate it before editing.

Template format 2 remains active in the current v0.13 slice. Rich generation components/output bindings are planned as a later v0.13 schema evolution with backwards-compatible migration/defaults rather than overloading today's workspace-field model.

## Running

Open the project in Godot 4.7.x and run it.

No Python runtime, web server, PyWebView, Node.js, or browser frontend is required by the application.

## Keeping a development test checkout current

For testing the newest merged development source, clone the repository once instead of repeatedly downloading GitHub ZIP archives.

```bash
git clone git@github.com:FrozenKangaroo/Character-Card-Forge-V2.git
cd Character-Card-Forge-V2
bash update.sh
```

After the first clone, update the test checkout at any time with:

```bash
bash update.sh
```

The updater always targets `origin/main`. It requires a clean working tree, switches a clean checkout back to `main` when necessary, fetches the latest remote state, and performs a fast-forward-only merge. It deliberately refuses to overwrite local edits, detached-HEAD state, or divergent local commits.

If desired, make it directly executable once:

```bash
chmod +x update.sh
./update.sh
```

This is a **development-source updater**, not the planned packaged application updater. It follows `main`, so it may contain newly merged development work that has not yet been promoted to a packaged release.

## Local release helper

From the development project directory:

```bash
cd /home/damee/character-card-forge
./release.sh
```

The helper:

- fetches the latest `origin/main`;
- fast-forwards a clean staging checkout;
- reconciles the common case where synced files already match newly merged GitHub content;
- stops before overwriting genuinely different local work;
- refuses silently diverged Git history;
- safely `rsync`s the development copy into `~/Projects/Character-Card-Forge-V2` without deleting repository-only files.

An alternate checkout can be selected with `CCF_REPO_DIR=/path/to/clone ./release.sh`.

The release path can synchronise version metadata, validate, commit/push, create an annotated version tag, and trigger platform builds. The source-only path validates and pushes without publishing a release.

## Automated desktop releases

A pushed `vX.Y.Z` tag triggers GitHub Actions to:

- install Godot 4.7.1 and matching export templates;
- validate release metadata and bundled JSON;
- import and parse the Godot project headlessly;
- export Windows x86-64, Linux x86-64, and unsigned macOS Universal builds;
- package downloads, generate checksums, and create a GitHub Release.

## User data

Godot stores application data under its normal `user://` location. The project uses lightweight JSON plus ordinary asset files rather than a replacement database.

Typical layout:

```text
character_card_forge/
├── settings/
├── templates/
├── series/
├── characters/
│   └── <project UUID>/
│       ├── character.json
│       ├── attachments/
│       ├── generated_images/
│       ├── emotion_images/
│       └── characters/
│           └── <character UUID>/
│               ├── attachments/
│               ├── generated_images/
│               └── emotion_images/
├── cache/
└── exports/
```

Character Card JSON/PNG, `.ccfproject`, and `.ccfseries` are interchange formats; the central project JSON and ordinary managed files remain authoritative.

## Architecture highlights

- `scripts/services/storage_service.gd` — format-v2 project persistence, migration, roster helpers, and user-data layout.
- `scripts/services/template_service.gd` — template storage, migration, validation, import/export, and field discovery.
- `scripts/services/generation_service.gd` — base queued text/multimodal generation and JSON repair.
- `scripts/services/generation_contract_service.gd` — v0.13 semantic generation-contract construction/validation and repair diagnostics.
- `scripts/services/parity_generation_service.gd` — v0.13 full-character semantic validation/revalidation and targeted repair layer.
- `data/generation_contracts/default.json` — bundled Default nested-content/format contract.
- `scripts/services/builder_service.gd` — guided builder schemas/state/presets and transfer logic.
- `scripts/services/settings_service.gd` — Character AI profiles, dedicated image providers, role assignments, and image defaults.
- `scripts/services/image_generation_service.gd` — OpenAI Images and Forge/A1111 generation adapters and managed image persistence.
- `scripts/services/image_capability_service.gd` — image model/checkpoint/sampler discovery.
- `scripts/services/attachment_service.gd` — managed attachment import, preprocessing, context budgeting, and vision payloads.
- `scripts/services/relationship_service.gd` — relationship normalisation and generation context.
- `scripts/services/series_service.gd` — series persistence, matching, generation context, and `.ccfseries` packaging.
- `scripts/services/card_format_service.gd` — Character Card V1/V2 normalisation, import/export, and PNG metadata.
- `scripts/services/project_package_service.gd` — `.ccfproject` packaging, safe extraction, assets/templates/series inclusion, and ID collision handling.
