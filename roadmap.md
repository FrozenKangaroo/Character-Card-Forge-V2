# Character Card Forge — Project Roadmap

## Project Vision

Rebuild Character Card Forge as a responsive, native Godot desktop application for creating, generating, editing, organising, importing, exporting, analysing, and illustrating AI roleplay character cards.

The existing PyWebView application remains a feature and behaviour reference, not an architecture or interface specification. Useful V1 behaviour should be re-expressed as maintainable Godot-native systems rather than copied literally.

## Core Design Principles

- Godot-native UI using Control nodes and containers.
- Character project files are the source of truth; the legacy internal database is not a compatibility target.
- Large assets remain ordinary files rather than database blobs or data URLs.
- Search indexes and thumbnails are disposable caches.
- Template-driven fields and generation behaviour.
- Non-blocking networking and long-running tasks.
- Clear separation between project data, UI, AI providers, imports/exports, integrations, and generated assets.
- OpenAI-compatible and useful local/self-hosted backends remain first-class targets.
- Character text/vision providers and image-generation providers are separate configuration domains.
- Data formats are versioned from the beginning and older content should remain usable where practical.
- New features extend the central project model rather than create parallel copies of character state.
- Wider desktop windows expose additional workspace instead of letterboxing a fixed interface.
- Detachable native tool windows are used where multi-monitor workflows benefit; primary navigation pages may remain embedded when clearer.
- Generation parity ports useful V1 behaviour into the Godot architecture rather than recreating PyWebView-specific implementation details.
- Workspace/editing structure, AI-generation structure, and interoperable Character Card output fields are related but distinct layers.

## Current Development Phase

**v0.13 development candidate — Generation Parity Core**

The v0.12 source milestone has been merged into `main`: it contains the expanded image-generation path, separated image providers, and Generation Parity Phase 1 prompt/template corrections. Release/application metadata intentionally remains at v0.11.0 until a formal release promotion is performed; merging source work alone is not treated as a published v0.12.0 release.

v0.13 now moves generation parity from prompt guidance into the engine. Its first implemented slice adds a data-driven completeness contract, semantic validation of otherwise-valid JSON, and one targeted repair pass before Generation Preview.

The current v0.13 candidate adds:

- a versioned Default generation contract stored under `data/generation_contracts/`;
- generic required top-level field checks derived from the active template's `required` generation fields;
- Default-template Description checks for Age, Appearance, Outfit Style, and Distinguishing Features;
- Default-template Personality checks for Core Traits, Motivation, Behavior Toward `{{user}}`, Speech Style, Strengths, Flaws, Likes, Dislikes, and Habits / Mannerisms;
- configurable minimum useful-content lengths in the bundled contract;
- a special Example Dialogue rule requiring exactly one `<START>` marker when that optional field is returned;
- contract instructions appended to full-character generation so the model knows the same requirements the validator will check;
- semantic validation after JSON parsing, rather than treating syntactically valid JSON as automatically complete;
- one targeted semantic repair pass that receives the source concept, current generated JSON, and exact missing requirements;
- preservation of useful generated material during repair instead of blindly regenerating the entire character from scratch;
- revalidation after the repair pass before the proposal reaches Generation Preview;
- repair diagnostics stored in generation metadata;
- a visible queue stage, **Repairing incomplete character generation**, using the existing cancellable asynchronous request architecture;
- continued review-first behaviour: automatic repair improves the proposal but does not silently apply it to project data;
- one shared upgraded generation queue for full generation, Builder, Controlled Build, Vision/Attachments, group scenes, relationships, and card workflows, while parity-specific semantic repair currently activates only for full-character jobs.

## Completed

### v0.12 source milestone — Image Expansion + Generation Parity Phase 1

Source merged to `main`; formal release/version promotion is still pending.

- Separated Character AI profiles from dedicated Image Generation providers with settings-format-v6 migration.
- Added separate **Character AI** and **Image Generation** Settings tabs.
- Added Forge/Automatic1111 WebUI generation alongside OpenAI-compatible Images APIs.
- Added `/sdapi/v1/txt2img`, checkpoint discovery, sampler discovery, OpenAI `/models` discovery, batch generation, sampler/steps/CFG/seed controls, returned-seed capture, Regenerate, and New Seed Variant workflows.
- Kept Image Studio as a selected main workspace while provider credentials live in Settings.
- Source-audited V1 generation behaviour and documented the quality/architecture gaps.
- Made the source Generation Concept authoritative in the built-in Default template.
- Restored Description to physical/external semantics with Age, Appearance, Outfit Style, and Distinguishing Features guidance.
- Expanded Personality guidance with traits, motivation, behaviour toward `{{user}}`, speech, strengths, flaws, likes, dislikes, and mannerisms.
- Strengthened Scenario / First Message continuity and Example Dialogue `<START>` guidance.

### v0.11.0 — Image Generation Foundation

- Added an independent Image generation role.
- Added OpenAI-compatible `/images/generations` requests in a dedicated cancellable image service.
- Added flexible base64, data-URL, downloadable-URL, and raw PNG/JPEG/WebP response decoding.
- Added PNG normalisation and ordinary per-character generated-image storage.
- Added natural-language and Stable Diffusion-style prompt construction.
- Added Image Generation Studio, persistent gallery, image preview/opening, and portrait assignment.
- Added lightweight generated-image metadata and retained `.ccfproject` portability.
- Added image-generation documentation and repository validation.

### Release Workflow Maintenance after v0.11.0

- `release.sh` fetches and fast-forwards a clean destination `main` before syncing the development copy.
- It reconciles the common case where locally synced files already match a newly merged `origin/main`.
- It stops for genuinely different local work, local-only commits, or diverged history.
- The normal workflow no longer requires a manual post-merge fetch/reset.

### v0.10.0 — Vision and Attachments Foundation

- Added independent Text and Vision provider assignments.
- Added project and per-character managed attachments for images, GIFs, text, PDFs, subtitles, transcripts, notes, and references.
- Added preprocessing summaries, context inclusion controls, and deterministic prompt budgeting.
- Added attachment context to major character and multi-character generation workflows.
- Added review-first Concept Extraction and Full-card Suggestions for image/GIF analysis.
- Kept attachment files portable inside `.ccfproject` packages.

### v0.9.x — Series and Release Infrastructure

- Added versioned series definitions/bibles, Series Manager, categories, aliases, canon notes, visual direction, generation rules, default tags, and matching keywords.
- Added deterministic local Auto Series matching and series-aware library filtering/bulk actions.
- Added generation context from assigned series and portable `.ccfseries` packs.
- Added Windows, Linux, and Universal macOS export presets, GitHub Actions validation/releases, semantic-version synchronisation, and release helper infrastructure.

### v0.8.x — Character Library 2.0

- Added thumbnail-grid and compact-list views, portrait thumbnails, incremental indexing, broad search, sorting, favourites, folders, collections, tags, filtering, bulk actions, and dashboard statistics reuse.

### v0.7.x — Import / Export Foundation

- Added Character Card V1/V2 import, V2 export, PNG/APNG metadata reading, PNG V2 writing, compatibility reports, embedded lorebook preservation, CCF extension round trips, portable `.ccfproject` packages, and split-workflow batch JSON export.

### v0.6.x — Relationships and Multi-Character Card Workflows

- Added sparse relationship matrices, directional relationship editing/generation, relationship-aware context, and Card Workflow Studio planning for multi-character single-card, split-card, and group-card workflows.

### v0.5.x — Multi-Character Project Foundation

- Upgraded project schema to format v2 with `characters[]` and migration from single-character projects.
- Added project shared context, roster management, per-character independent templates/history/builder/assets/custom fields, Group Scene generation, and per-character asset directories.

### v0.4.x — Guided and Controlled Building

- Added Guided Character Builder, data-driven presets, AI fill/extraction, Safe Section Build, Custom Section Build, selected-field revision, protected-context prompts, review-first field application, JSON repair, and diagnostics.

### v0.3.x — Template System and Native Tool Windows

- Added native Template Manager with versioned user templates, editable sections/fields/types, AI instructions, output discipline, migration/validation, and detachable Idea Generator / Generation Preview windows.

### v0.2.x — Generation Foundation

- Added shared queued generation, cancellation, retries, editable previews, selective application, per-field suggestions, Idea Generator, token estimates, API profiles, model discovery, and early UI maintenance.

### v0.1.x — Application Foundation

- Created the Godot 4.6 project shell, versioned project JSON, settings, template-driven editing, Character Library foundation, asynchronous OpenAI-compatible generation, and generation history.

## In Progress

### v0.13 — Generation Parity Core candidate

**Implemented in the current candidate:**

- Data-driven Default generation completeness contract.
- Generic required top-level generation-field validation from active templates.
- Default Description and Personality labelled-component validation.
- Minimum useful-content and Example Dialogue marker checks.
- Contract-aware full-character prompt instructions.
- Valid-JSON semantic completeness validation.
- One targeted semantic repair pass preserving source concept and useful generated material.
- Revalidation before Generation Preview.
- Repair diagnostics in job metadata.
- Repair stage surfaced through the existing queue/status UI.
- Existing Generation Preview remains the final review boundary.
- Existing queue/cancellation architecture remains authoritative.
- Godot 4.6.3 headless import/parse and repository JSON validation pass on the initial semantic-repair implementation.

**Still in v0.13:**

- Separate **workspace fields**, **generation components/subfields**, and **interoperable output bindings** so multiple authoring/generation components can fold into one Character Card field.
- Add template-managed generation components with stable IDs, labels, instructions, enabled state, required state, ordering, and output binding.
- Keep older format-v2 templates working through migration/defaults and bump the template format only when necessary.
- Make nested/custom completeness contracts editable/data-driven per user template rather than only providing generic required-field checks plus a bundled Default contract.
- Add private pre-generation Q&A/interview passes driven by enabled questions.
- Verify every required Q&A answer and retry only missing questions.
- Feed completed Q&A into generation as private planning context rather than exported card content.
- Define builder/context precedence so explicit builder guidance outranks generic generation assumptions without silently rewriting unrelated established facts.
- Add conservative concept-fidelity diagnostics for supplied names and distinctive literal markers, with at most one stricter retry when clear drift occurs.
- Improve user-visible generation stages beyond the current generation/repair queue labels: planning/Q&A, generation, fidelity check, validation, repair, ready for review.
- Present semantic validation/repair diagnostics more richly in Generation Preview.
- Test semantic repair across the user's normal text backend and deliberately incomplete/low-token responses.

### Ongoing validation

- Real-world testing against multiple OpenAI-compatible text backends.
- Compare several fresh characters against the pre-parity V2 generator, especially Description/Personality separation and concept fidelity.
- Real-world Forge/Automatic1111 testing and OpenAI-compatible image batch testing across provider differences.
- Continued template/custom-field testing.
- Guided Builder extraction/fill testing across providers.
- Relationship matrix and larger-roster testing.
- Card Workflow Studio planning/reference-maintenance testing.
- Character Card V2 JSON/PNG/APNG interoperability testing.
- `.ccfproject` testing with large assets, custom-template collisions, attachments, and generated-image trees.
- Character Library 2.0 large-library/bulk-operation testing.
- Series Manager / `.ccfseries` and ambiguous Auto Series matching tests.
- Attachment imports across Linux, Windows, and macOS.
- Large attachment-context budget tests.
- Vision analysis across image-capable OpenAI-compatible and local multimodal servers.

## Next Up

### Remaining v0.13 Generation Parity Core

Finish the component/output-binding model, private Q&A, builder precedence, conservative concept-fidelity retry, richer multi-stage progress, and editable/custom template contracts after the semantic-repair foundation proves stable in real generation tests.

### v0.14 — Image Workflow Expansion

This milestone was moved from the original v0.13 slot so generation parity could take priority. It remains planned.

- Add image-to-image/reference-image generation where supported.
- Allow generated images and managed visual attachments to become generation references without embedding binary data in JSON.
- Add emotion-image generation/regeneration using the existing `emotion_images/` tree.
- Add named emotions/expressions and per-emotion editable prompts.
- Add reusable visual-style/prompt presets.
- Add richer gallery management including intentional deletion with portrait/reference safety checks.
- Add provider-specific quality/aspect controls where useful.
- Add optional Stable Diffusion advanced helpers such as LoRA/embedding-oriented prompt tools without making one WebUI ecosystem part of the central character schema.

## Planned Features

### Generation Improvements

- Streaming text support where providers support it.
- Generation components/output bindings and editable per-template semantic contracts. **In progress in v0.13.**
- V1-style private Q&A completeness and targeted missing-answer retries. **Planned for v0.13.**
- Conservative concept-fidelity validation/retry. **Planned for v0.13.**
- Semantic completeness validation and targeted repair. **Initial core implemented in v0.13 candidate.**
- Builder guidance precedence for full generation. **Planned for v0.13.**
- V1-style Full/Lite/Compact-Lite or equivalent multi-pass strategies for smaller context windows after the core generation contract is stable.
- Section-by-section generation/continuation with per-stage progress, inspired by the later V1 beta workflow once its desired Godot behaviour is cleanly specified.
- Configurable special formatting rules such as `<START>` counts, greeting counts, and constrained tag sets.
- Recent/favourite model lists.
- Broader provider capability detection.
- Token-limit metadata and stronger context-budget estimation.
- Reusable provider presets without unnecessary credential duplication.

### Multi-Character Workflows

- Relationship matrix generation/editing and relationship-aware generation context. **Foundation completed in v0.6.0.**
- Multi-character single-card planning. **Foundation completed; final generation/export still planned.**
- Split-card batch planning. **Foundation completed; automatic full-card batch execution still planned.**
- Group-card planning. **Foundation completed; dedicated generation/export remains planned.**
- Shared lore and deeper group continuity tools.
- Relationship visualisation/flowchart integration in Character Library 2.0.

### Character Library 2.0

- Thumbnail grid/list, sorting/filtering, tags/tag merging, folders, collections, series filters, favourites, and incremental index. **Foundations completed.**
- Card groups and variations.
- Flowchart/relationship views.
- Richer image/portrait filtering once image workflows mature.

### Series System

- Series definitions/bibles, Series Manager, generation guidance, deterministic Auto Series, categories, import/export, and portable Series Packs. **Completed foundations.**
- Optional provider-assisted semantic matching for difficult cases.
- Series artwork, richer hierarchy, and collection-level defaults.

### Vision and Attachments

- Images as concept references and review-first character/full-card analysis. **Foundation completed.**
- GIF frame selection beyond current file support.
- Image URL references.
- Native PDF text extraction beyond current portable file storage/metadata.
- Attachment preprocessing/context budgeting refinement.
- Visual-reference handoff into image-to-image workflows. **Planned for v0.14.**

### Image Generation

- OpenAI-compatible image providers, natural/SD-style prompts, gallery, portrait assignment. **Completed foundation.**
- Forge/Automatic1111 support, dedicated provider settings, checkpoint/sampler discovery, batch generation, reproducible seeds, regeneration, and SD defaults. **v0.12 source milestone implemented.**
- Image-to-image/reference generation. **Planned for v0.14.**
- Emotion-image generation/regeneration and per-emotion prompts. **Planned for v0.14.**
- Reusable visual-style/prompt presets. **Planned for v0.14.**
- Richer provider-specific quality/aspect/advanced controls.
- LoRA/embedding-oriented workflow helpers where useful.

### Import / Export

- Character Card V2 JSON import/export, PNG/APNG metadata, SillyTavern-oriented mappings, embedded lorebook preservation, portable `.ccfproject`, and split-workflow JSON export. **Foundation completed.**
- Broader ecosystem compatibility testing.
- PNG batch export and automatic split-workflow generation.
- Additional external formats where meaningful.
- Generated/emotion image export options where external formats support them.

### Front Porch Integration

- Data folder discovery/configuration.
- Character scanning.
- Import from Front Porch.
- Install/export to Front Porch.
- Character management tools.
- Chat reading/export where practical.

### Quality Tools

- Final AI Audit.
- Card rating and improvement suggestions.
- Consistency checking.
- Broader missing-field reports beyond generation-time completeness checks.
- Token estimates.
- Revision history and snapshots.
- Generation-recipe comparison for image variants.

## Data and Content Tools

- Keep character-project JSON and template schemas documented.
- Maintain project/template migrations as formats evolve.
- Maintain and version the `.ccfproject` renamed-ZIP package format.
- Keep generated assets referenced through relative portable paths.
- Preserve older generated-image records as metadata evolves.
- Add reusable template packs if community template sharing becomes useful.
- Document workspace fields vs generation components vs output bindings when that model lands.

## Technical Improvements

- Add automated schema/behavior tests beyond marker-based repository validation.
- Add recovery from interrupted writes using temporary-file replacement.
- Add optional autosave with safe snapshots.
- Add async thumbnail generation.
- Generalise the cancellable task service beyond AI jobs to scanning/imports.
- Add structured application logging and diagnostics viewer.
- Add secure credential-storage options where platform support permits.
- Add additional API authentication modes where local servers require them.
- Split very large UI scripts into reusable components as workflows expand.
- Consider formal provider-adapter classes as provider diversity grows.
- Keep generation validators/repair logic in reusable services rather than embedding V1 assumptions in workspace UI code.

## Polish

- Custom application theme and stronger visual identity.
- Responsive-layout refinement for narrow windows and high-density toolbars.
- Continue balancing embedded primary pages with detachable multi-monitor tools.
- Keyboard shortcuts.
- Drag-and-drop files.
- Better empty states and onboarding.
- Native notifications for completed long-running jobs where useful.
- Denser image-gallery thumbnail browsing as collections grow.
- Richer generation-progress and repair-status presentation.

## Long-Term Ideas

- Optional LAN/mobile companion interface as a separate service rather than a web frontend embedded in the desktop app.
- Plugin/provider extension API.
- Community template sharing.
- Batch character generation pipelines.
- Local semantic search over large character libraries.
- Provider-agnostic image recipe presets shareable where settings overlap safely.

## Deferred / Experimental Ideas

- Legacy database import is intentionally deferred and is not a compatibility goal.
- Reproducing the old PyWebView interface is explicitly not planned.
- A mobile browser interface only returns if a strong workflow need appears and it can remain cleanly separated from the desktop core.
- Highly backend-specific Stable Diffusion controls remain optional adapter-owned features rather than mandatory character-project fields.
- Exact recreation of V1 prompt strings is not a goal; source-audited behaviour should be expressed as maintainable Godot-native data and services.
