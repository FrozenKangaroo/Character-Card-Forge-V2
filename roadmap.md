# Character Card Forge — Project Roadmap

## Project Vision

Rebuild Character Card Forge as a responsive, native Godot desktop application for creating, generating, editing, organising, importing, exporting, analysing, and illustrating AI roleplay character cards.

The existing PyWebView application remains a feature reference, not an architecture or interface specification. The rewrite should preserve useful capabilities while replacing the legacy persistence, frontend, and job architecture with modular Godot-native systems.

## Core Design Principles

- Godot-native UI using Control nodes and containers.
- No compatibility requirement with the legacy internal database format.
- Character project files are the source of truth.
- Large assets remain ordinary files rather than database blobs or data URLs.
- Search indexes and thumbnails are disposable caches.
- Template-driven fields and generation behaviour.
- Non-blocking networking and long-running tasks.
- Clear separation between project data, UI, AI providers, imports/exports, and integrations.
- OpenAI-compatible backends remain a first-class target.
- Local/self-hosted backends remain first-class where the old application had useful local workflows.
- Character text/vision providers and image-generation providers are separate configuration domains even when they use similar HTTP APIs.
- Data formats are versioned from the beginning.
- New features extend the central project model rather than create parallel copies of character state.
- Wider desktop windows expose additional workspace instead of letterboxing a fixed 16:9 interface.
- Detachable native tool windows are preferred for substantial workflows that benefit from multi-monitor use; primary navigation workspaces may remain embedded when that interaction is clearer.
- Generation parity work should port useful V1 behaviour into the Godot architecture rather than recreate PyWebView-specific implementation details.
- Workspace/editing structure, AI-generation structure, and interoperable Character Card output fields should be treated as related but distinct layers where that produces cleaner templates and exports.

## Current Development Phase

**v0.12 development candidate — Image Generation Expansion + Generation Parity Phase 1**

v0.11.0 established the first native image-generation foundation and has now been promoted from candidate to a real release. The current v0.12 branch expands that image system and begins a source-audited generation-parity programme after comparing the Godot generator with the V1 PyWebView implementation.

The v0.12 candidate currently adds:

- dedicated image-provider profiles separated from character text/vision API profiles;
- settings-format-v6 migration from the earlier shared-profile model;
- separate **Character AI** and **Image Generation** Settings tabs;
- local Forge/A1111 configuration centred on a WebUI server URL, with no API key required for a normal local installation;
- Stable Diffusion Forge / Automatic1111 WebUI API support alongside OpenAI-compatible Images APIs;
- `/sdapi/v1/txt2img` generation using the existing central gallery and asset model;
- WebUI checkpoint and sampler discovery;
- OpenAI-compatible model discovery from `/models`;
- batch generation;
- sampler, steps, CFG, seed, size, checkpoint/model, and prompt controls;
- capture of returned Stable Diffusion seeds for reproducibility;
- gallery **Regenerate** and **New Seed Variant** workflows;
- format-v2 generated-image metadata while retaining older gallery entries;
- Image Studio as a selected main navigation workspace rather than an unexpected popup, while provider connection management remains in Settings;
- a V1-inspired default character-generation contract that treats the source concept as authoritative instead of generic inspiration;
- a corrected **Description** contract focused on visible physical appearance/external presentation rather than mixing biography and personality into the same field;
- structured labelled guidance inside Description for age, appearance, outfit style, and distinguishing features while still exporting through the normal Character Card Description field;
- richer **Personality** guidance for traits, motivation, behaviour toward `{{user}}`, speech, strengths, flaws, likes, dislikes, and mannerisms while retaining the normal Character Card Personality field;
- stronger Scenario and First Message continuity guidance so both describe the same immediately playable opening situation;
- V1-style Example Dialogue guidance requiring one `<START>` marker followed by one continuous example conversation;
- stronger required-field and concept-fidelity instructions in the built-in template without changing existing project or template format versions.

Release/application metadata intentionally remains on v0.11.0 while this branch is a development candidate. A normal `release.sh` promotion can synchronise v0.12.0 after real local-provider testing confirms the new provider split/Forge workflow and a text-generation smoke test confirms the revised default generation contract behaves well on the user's configured backend.

## Completed

### v0.11.0 — Image Generation Foundation

- Added an Image generation provider role independent of Text and Vision roles.
- Added settings-format-v4 migration preserving existing assignments.
- Added OpenAI-compatible `/images/generations` requests in a dedicated cancellable image service.
- Added flexible decoding for base64, data URLs, downloadable URLs, and raw PNG/JPEG/WebP responses.
- Added PNG normalisation and ordinary per-character generated-image storage.
- Added natural-language and Stable Diffusion-style prompt construction from the central character model.
- Added default image size and prompt-style settings plus per-run model override.
- Added detachable Image Generation Studio with project/character selection, editable prompts, gallery preview, open-in-system-app, and portrait assignment.
- Added lightweight `assets.generated_images[]` metadata and preserved `.ccfproject` portability.
- Added dedicated image-generation documentation and repository validation.
- Promoted release metadata to v0.11.0 after local testing.

### Release Workflow Maintenance after v0.11.0

- Updated `release.sh` to fetch and fast-forward a clean destination `main` automatically before syncing the development copy.
- Added automatic reconciliation when previously synced local files already exactly match newly merged `origin/main` files.
- Preserved safety stops for genuinely different local work, local-only commits, and diverged history.
- Removed the common post-merge manual fetch/reset step from the normal release workflow.

### v0.10.0 — Vision and Attachments Foundation

- Added independent Text generation and Vision analysis assignments backed by reusable API profiles.
- Added settings-format-v3 migration preserving the prior active profile for both roles.
- Added shared-project and per-character attachment collections without increasing project format version 2.
- Added managed local files for images, GIFs, text, PDFs, subtitles, transcripts, notes, and arbitrary references.
- Added preprocessing summaries, text/token estimates, context inclusion controls, and configurable deterministic prompt budgeting.
- Added attachment context to principal character and multi-character generation workflows.
- Added image/GIF Concept Extraction and Full-card Suggestions through OpenAI-compatible multimodal requests.
- Reused Generation Preview so visual proposals remain editable and opt-in.
- Kept attachment files portable inside existing `.ccfproject` packages.

### v0.9.x — Series and Release Infrastructure

- Added the Series System foundation and native Series Manager.
- Added versioned series definitions/bibles, categories, aliases, canon notes, visual direction, generation rules, default tags, and matching keywords.
- Added deterministic local Auto Series matching and series-aware Character Library filtering/bulk actions.
- Added series context across major generation workflows.
- Added portable `.ccfseries` packs and `.ccfproject` series inclusion/remapping.
- Added warning cleanup and strict Godot 4.6 maintenance fixes.
- Added Windows x86-64, Linux x86-64, and macOS Universal export presets.
- Added GitHub Actions validation and tag-triggered release builds.
- Added semantic-version synchronisation and release validation tooling.
- Added Universal macOS texture-import hotfixes.
- Added automatic development-copy → Git-checkout `rsync` release workflow.

### v0.8.x — Character Library 2.0

- Added thumbnail-grid and compact-list views.
- Added project portrait thumbnails with disposable cache storage.
- Added incremental per-project indexing.
- Added broad project/character/card-text search, sorting, favourites, folders, collections, tags, unfiled filtering, and bulk actions.
- Added project detail summaries and remembered library preferences.
- Updated Dashboard statistics to reuse the library index.
- Added parser/warning maintenance without changing the library data model.

### v0.7.x — Import / Export Foundation

- Added detachable Import / Export Studio.
- Added Character Card V2 JSON export/import and tolerant legacy V1 import.
- Added PNG/APNG `chara` metadata reading and Character Card V2 metadata writing.
- Preserved alternate greetings, embedded lorebooks, creator/version metadata, and unknown V2 extension data.
- Added namespaced CCF V2 extension round trips for CCF-only/template-specific fields.
- Added mapping/compatibility reports.
- Added portable `.ccfproject` renamed-ZIP packages with assets, manifest, templates, safe extraction, and ID remapping.
- Added batch JSON export from split-card workflow plans.

### v0.6.x — Relationships and Multi-Character Card Workflows

- Added structured sparse relationship matrices.
- Added detachable relationship editing and AI-assisted relationship drafting.
- Added relationship-aware context to major generation workflows.
- Added detachable Card Workflow Studio with multi-character single-card, split-card batch-plan, and group-card planning modes.
- Added reusable project-level card workflow drafts.
- Added reference cleanup/remapping when characters change or projects are duplicated.

### v0.5.x — Multi-Character Project Foundation

- Upgraded the central project schema to format v2 with `characters[]`.
- Added migration from earlier single-character projects.
- Added project-level shared premise/setting/situation/rules/notes.
- Added character roster switching, creation, duplication, removal, and group-role metadata.
- Preserved independent templates, histories, builder state, assets, and custom fields per character.
- Added Shared Context and Group Scene native windows.
- Added shared context to major generation prompts.
- Updated Character Library and Dashboard semantics for multi-character projects.
- Added per-character asset directory foundations.
- Added responsive workspace-flow layouts and strict Godot warning maintenance.

### v0.4.x — Guided and Controlled Building

- Added native Guided Character Builder with data-driven steps and presets.
- Added AI step fill, full-builder fill, concept extraction, review, and character transfer workflows.
- Added safe fill-empty and optional overwrite behaviour.
- Added originating-project checks for asynchronous results.
- Added Safe Section Build, Custom Section Build, and selected-field Revision workflows.
- Added protected-context prompts and allowed-field enforcement.
- Added per-field keep/replace review and editable Generation Preview.
- Added JSON extraction/repair and generation diagnostics.

### v0.3.x — Template System and Native Tool Windows

- Added native Template Manager with versioned user templates.
- Added editable sections, fields, field types, AI instructions, template rules, output discipline, and migration/validation.
- Added detachable native Idea Generator and Generation Preview windows with remembered geometry.
- Added native-window lifecycle and GDScript warning fixes.

### v0.2.x — Generation Foundation

- Added shared queued AI generation service.
- Added cancellation, queue status, retries, editable previews, selective application, per-field suggestions, Idea Generator, approximate token estimates, multiple API profiles, and compatible `/models` discovery.
- Fixed early modal lifecycle and ultrawide canvas behaviour.

### v0.1.x — Application Foundation

- Created the Godot 4.6 project structure and native shell/navigation.
- Added versioned character project JSON, per-character assets, settings persistence, template-generated editing fields, basic Character Library, asynchronous OpenAI-compatible generation, and generation history.

## In Progress

### v0.12 — Image Generation Expansion + Generation Parity Phase 1 candidate

- **Implemented:** settings-format-v6 separation between character-AI profiles and dedicated image-provider profiles.
- **Implemented:** v5 → v6 migration preserving text/vision assignments and image-generation defaults while preventing an SD provider from inheriting an OpenAI-style text URL/model/key.
- **Implemented:** separate **Character AI** and **Image Generation** Settings tabs.
- **Implemented:** local Forge/A1111 image providers default to `http://127.0.0.1:7860` and hide/clear the API key for normal local use.
- **Implemented:** OpenAI-compatible and Forge/Automatic1111 provider adapters behind the same image service.
- **Implemented:** Forge/A1111 `/sdapi/v1/txt2img` generation.
- **Implemented:** direct Stable Diffusion negative prompts.
- **Implemented:** sampler, steps, CFG, seed, batch, resolution, and checkpoint/model controls.
- **Implemented:** WebUI checkpoint discovery from `/sdapi/v1/sd-models`.
- **Implemented:** WebUI sampler discovery from `/sdapi/v1/samplers`.
- **Implemented:** OpenAI-compatible `/models` discovery in Image Studio with capability caveats.
- **Implemented:** multi-image batches with one project save per completed batch.
- **Implemented:** actual returned WebUI seed capture from `info.all_seeds` where available.
- **Implemented:** generated-image record format v2 with backend and reproducibility metadata.
- **Implemented:** gallery Regenerate workflow using stored generation settings and seed.
- **Implemented:** New Seed Variant workflow using the stored recipe with a fresh random SD seed.
- **Implemented:** profile-level Save Image Defaults using the dedicated image-provider record.
- **Implemented:** Image Studio embedded as a primary main-content workspace with selected sidebar state; connection credentials live in Settings rather than the Studio.
- **Implemented — Generation Parity Phase 1:** source-audited the V1 generation/template behaviour and documented the architectural gaps that matter to output quality.
- **Implemented — Generation Parity Phase 1:** rewrote the built-in Default template's generation instructions so the source concept is authoritative and explicit supplied details should be preserved rather than casually reinvented.
- **Implemented — Generation Parity Phase 1:** restored physical/external-only Description semantics with labelled Age, Appearance, Outfit Style, and Distinguishing Features guidance inside the standard interoperable Description field.
- **Implemented — Generation Parity Phase 1:** expanded Personality guidance into labelled traits, motivation, behaviour toward `{{user}}`, speech, strengths, flaws, likes, dislikes, and habits/mannerisms inside the standard interoperable Personality field.
- **Implemented — Generation Parity Phase 1:** strengthened Scenario/First Message continuity and Example Dialogue formatting guidance.
- **Validated previously:** repository checks and Godot 4.6.3 headless import/parse pass on the separated-provider candidate.
- **Pending validation:** repository/CI parse validation after the Generation Parity Phase 1 template changes.
- **Pending validation:** real-world Forge/Automatic1111 testing on the user's local setup.
- **Pending validation:** OpenAI-compatible batch behaviour across providers with different `n` limits/response envelopes.
- **Pending validation:** compare at least several freshly generated cards against the previous V2 default template to confirm Description/Personality fidelity improves across the user's normal text model.

### Ongoing validation

- Real-world testing against multiple OpenAI-compatible text backends.
- Stronger generation-response repair and structured diagnostics.
- UI refinement as larger workflows are restored.
- Continued template/custom-field testing.
- Guided builder AI extraction/fill testing across providers.
- Relationship-matrix AI output testing across providers and larger rosters.
- Card Workflow Studio planning and reference-maintenance testing.
- Character Card V2 JSON/PNG/APNG round-trip testing against multiple ecosystem tools.
- `.ccfproject` testing with large asset trees and custom-template collisions.
- Character Library 2.0 testing with large collections, portrait formats, and repeated bulk operations.
- Series Manager / `.ccfseries` testing across large local libraries.
- Auto Series scoring tests against ambiguous franchises and aliases.
- Attachment imports across Linux, Windows, and macOS.
- Context-budget testing with large text/subtitle/transcript collections.
- Vision-analysis testing across image-capable OpenAI-compatible and local multimodal servers.
- `.ccfproject` round trips containing attachment and generated-image trees.

## Next Up

### v0.13 — Generation Parity Core

The V1 source audit showed that its higher output quality came from more than prompt wording. After v0.12 is validated and released, make the generation contract an explicit engine feature rather than relying only on stronger default-template prose.

- Separate **workspace fields**, **generation subfields/components**, and **interoperable output bindings** so several editable/generatable components can fold into one Character Card field such as Description or Personality.
- Add template-managed generation components with stable IDs, labels, instructions, enabled state, required state, ordering, and output binding.
- Keep older format-v2 templates working through migration/defaults; version the template schema when the new component model is introduced.
- Add private pre-generation Q&A/interview passes driven by enabled template questions.
- Verify that every required Q&A question receives an answer and perform targeted retry passes for only missing answers.
- Feed reviewed/completed Q&A into final generation as private planning context rather than exporting it as card content.
- Define builder/context precedence so explicit builder guidance overrides generic generation assumptions without silently overwriting unrelated established character facts.
- Add concept-fidelity checks for supplied names and distinctive concept markers, with a strict regeneration path when output clearly drifts from the source concept.
- Add template-aware completeness validation for required fields, required generation components, special formatting contracts, and enabled sections.
- Add targeted semantic repair for incomplete generated fields/sections while preserving useful content from the original response.
- Revalidate repaired results before Generation Preview and surface useful diagnostics such as missing components and repair attempts.
- Keep the existing review-first Generation Preview: automatic generation/repair may improve a proposal, but generated content must still not silently overwrite project data.
- Add user-visible generation progress that can distinguish planning/Q&A, generation, validation, and repair stages.

### v0.14 — Image Workflow Expansion

The previously planned v0.13 image-workflow milestone is deliberately moved, not removed, so generation parity can take priority after the V1 source audit.

- Add image-to-image/reference-image generation where the selected backend supports it.
- Allow existing generated images and managed visual attachments to become generation references without copying binary data into JSON.
- Add emotion-image generation/regeneration using the existing per-character `emotion_images/` asset tree.
- Add named emotions/expressions and per-emotion editable prompts.
- Add reusable visual-style/prompt presets.
- Add richer gallery management, including intentional file deletion with portrait/reference safety checks.
- Add provider-specific quality/aspect controls where useful.
- Add opt-in Stable Diffusion advanced controls such as LoRA/embedding-oriented prompt helpers without hard-coding one WebUI ecosystem into the central character format.

## Planned Features

### Generation Improvements

- Streaming text support where providers support it.
- Structured generation diagnostics and stronger response-repair attempts. **Promoted to the v0.13 Generation Parity Core milestone.**
- V1-style concept fidelity, Q&A completeness, template completeness validation, and targeted semantic repair. **Planned for v0.13.**
- V1-style Full/Lite/Compact-Lite or equivalent multi-pass generation strategies for smaller context windows after the core generation contract is explicit and testable.
- Section-by-section generation/continuation with per-stage progress, inspired by the later V1 beta workflow, once the exact behaviour is source-verified or cleanly specified for the Godot architecture.
- Optional template-level rules for special formatting contracts such as one `<START>` marker, greeting counts, or constrained tag sets without hard-coding every format rule into the general generator.
- Separate Text and Vision role assignments within the Character AI provider collection. **Completed in v0.10.0 and retained.**
- Dedicated image-provider collection independent from Character AI credentials/models. **v0.12 candidate implemented with settings format v6.**
- Image backend selection per dedicated image provider. **v0.12 candidate implemented.**
- Recent/favourite model lists.
- Broader provider capability detection.
- Token-limit metadata and stronger context-budget estimation.
- Reusable provider presets without duplicating credentials unnecessarily.

### Multi-Character Workflows

- Relationship matrix generation and editing. **Foundation completed in v0.6.0.**
- Relationship-aware generation context. **Foundation completed in v0.6.0.**
- Multi-character single-card planning. **Foundation completed in v0.6.0; final generation/export still planned.**
- Split-card batch planning. **Foundation completed in v0.6.0; automatic full-card batch execution still planned.**
- Group-card planning workflows. **Foundation completed in v0.6.0; dedicated generation/export remains planned.**
- Shared lore and deeper group continuity tools.
- Relationship visualisation/flowchart integration in Character Library 2.0.

### Character Library 2.0

- Thumbnail grid and optional list view. **Completed in v0.8.0.**
- Sorting and advanced filters. **Foundation completed in v0.8.0; series filters added in v0.9.0.**
- Tags and tag merging. **Completed in v0.8.0.**
- Virtual folders. **Completed in v0.8.0.**
- Collections. **Completed in v0.8.0.**
- Card groups and variations.
- Series sidebar/filtering. **Completed in v0.9.0.**
- Favourites. **Completed in v0.8.0.**
- Flowchart/relationship views.
- Incremental disposable search index. **Completed in v0.8.0.**
- Richer image/portrait filtering once image workflows mature.

### Series System

- Series definitions and bibles. **Completed in v0.9.0.**
- Series Manager. **Completed in v0.9.0.**
- Generation guidance from selected series. **Completed in v0.9.0.**
- Deterministic local Auto Series assignment. **Completed in v0.9.0.**
- Optional provider-assisted semantic matching for difficult cases.
- Categories. **Completed in v0.9.0.**
- Series import/export. **Completed in v0.9.0.**
- Portable Series Packs. **Completed in v0.9.0.**
- Series artwork, richer hierarchy, and collection-level defaults.

### Vision and Attachments

- Images as concept references. **Local attachment and review-first analysis foundation completed in v0.10.0.**
- GIF frame handling. **File support completed in v0.10.0; explicit frame selection remains planned.**
- Image URL references.
- Character analysis and full-card analysis. **Review-first foundation completed in v0.10.0.**
- PDF/text/subtitle/transcript attachments. **Managed attachment foundation completed in v0.10.0; PDF extraction remains planned.**
- Attachment preprocessing and context budgeting. **Foundation completed in v0.10.0.**
- Visual-reference handoff into image-to-image workflows. **Planned for v0.14.**

### Image Generation

- OpenAI-compatible image provider support. **Completed in v0.11.0; dedicated provider storage and batch path expanded in v0.12 candidate.**
- Natural-language image prompt builder. **Completed in v0.11.0.**
- Stable Diffusion-style prompt builder. **Completed in v0.11.0.**
- Generated image gallery. **Completed in v0.11.0.**
- Character portrait assignment. **Completed in v0.11.0.**
- Stable Diffusion Forge / Automatic1111-compatible provider support. **v0.12 candidate implemented.**
- Dedicated image-provider Settings tab and local server configuration. **v0.12 candidate implemented.**
- Image provider model/checkpoint and sampler discovery. **v0.12 candidate implemented.**
- Batch generation. **v0.12 candidate implemented.**
- Seed-aware regeneration and new-seed variants. **v0.12 candidate implemented for reproducible backends.**
- Sampler/steps/CFG/seed image-provider defaults. **v0.12 candidate implemented.**
- Image-to-image/reference-image generation. **Planned for v0.14.**
- Emotion-image generation and regeneration. **Planned for v0.14.**
- Per-emotion prompt editing. **Planned for v0.14.**
- Reusable visual-style/prompt presets. **Planned for v0.14.**
- Richer provider-specific quality/aspect/advanced controls.
- LoRA/embedding-oriented workflow helpers where useful.

### Import / Export

- Character Card V2 JSON import/export. **Foundation completed in v0.7.0.**
- Character Card V2 PNG/APNG metadata read and PNG metadata write. **Foundation completed in v0.7.0.**
- SillyTavern ecosystem field mapping and compatibility reports. **Foundation completed in v0.7.0; broader testing remains.**
- Embedded lorebook preservation. **Round-trip preservation completed in v0.7.0; dedicated editing remains planned.**
- Portable Character Card Forge `.ccfproject` packages. **Foundation completed in v0.7.0.**
- Split-workflow batch JSON export. **Foundation completed in v0.7.0; PNG batch export and automatic generation remain planned.**
- Additional external formats where they provide meaningful interoperability.
- Generated image/emotion asset export options where external formats support them.

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
- Missing-field checks. **Core generation-time completeness checks promoted to v0.13; broader audit/reporting remains planned here.**
- Token estimates.
- Revision history and snapshots.
- Generation-recipe comparison for image variants.

## Data and Content Tools

- Keep the character project JSON schema documented.
- Maintain template schema documentation and migration support.
- Maintain project-format migration functions as the schema evolves beyond format version 2.
- Maintain the documented `.ccfproject` renamed-ZIP package format and version it when compatibility changes.
- Keep generated assets referenced by relative paths inside portable packages.
- Preserve older generated-image records when image metadata grows.
- Add reusable template packs if community template sharing becomes useful.
- Document the distinction between workspace fields, generation components, and interoperable output bindings when the v0.13 template schema is introduced.

## Technical Improvements

- Add automated schema validation tests beyond marker-based repository validation.
- Add project recovery from interrupted writes using temporary-file replacement.
- Add optional autosave with safe snapshots.
- Add async thumbnail generation.
- Generalise the cancellable task service beyond AI jobs to scanning/imports.
- Add structured application logging and a diagnostics viewer.
- Add secure credential-storage options where platform support permits.
- Add additional API authentication modes where local servers require them.
- Split very large UI scripts into reusable components as workflows expand.
- Consider formal provider-adapter classes once image/text provider diversity justifies the abstraction.
- Keep generation validators/repair logic in reusable services rather than embedding V1-specific assumptions directly into workspace UI code.

## Polish

- Custom application theme and stronger visual identity.
- Continue responsive-layout refinement for narrow desktop windows and high-density toolbars.
- Continue using detachable native windows where multi-monitor workflows benefit while keeping primary navigation pages embedded when that is clearer.
- Keyboard shortcuts.
- Drag-and-drop files.
- Better empty states and onboarding.
- Native notifications for completed long-running jobs where useful.
- Image-gallery thumbnails and denser browsing once gallery collections become larger.
- Clear generation-progress and repair-status presentation as the v0.13 multi-stage pipeline lands.

## Long-Term Ideas

- Optional LAN/mobile companion interface implemented as a separate service rather than embedding the main desktop UI in a web frontend.
- Plugin/provider extension API.
- Community template sharing.
- Batch character generation pipelines.
- Local semantic search over large character libraries.
- Provider-agnostic image recipe presets shareable between projects where settings overlap safely.

## Deferred / Experimental Ideas

- Legacy database import is intentionally deferred and is not a compatibility goal.
- Reproducing the old PyWebView interface is explicitly not planned.
- A mobile browser interface will only return if there is a strong workflow need and it can remain cleanly separated from the desktop application core.
- Highly backend-specific Stable Diffusion controls should remain optional adapter-owned features rather than becoming mandatory fields in every character project.
- Exact recreation of V1's internal prompt strings is not a goal; source-audited behaviour should be re-expressed as maintainable Godot-native data and services.
