# Character Card Forge — Project Roadmap

## Project Vision

Rebuild Character Card Forge as a responsive, native Godot desktop application for creating, generating, editing, organising, importing, and exporting AI roleplay character cards.

The existing PyWebView application is a feature reference, not an architecture or interface specification. The rewrite should preserve useful capabilities while replacing the legacy persistence, frontend, and job architecture with modular Godot-native systems.

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
- Data formats are versioned from the beginning.
- New features should extend the central project model rather than create parallel copies of character state.
- Wider desktop windows should expose additional workspace instead of letterboxing a fixed 16:9 interface.

## Current Development Phase

**GitHub Release Infrastructure — v0.9.2 stable candidate**

The Godot rewrite now has reproducible Windows, Linux, and unsigned Universal macOS exports driven by committed presets and tag-triggered GitHub Actions. Release metadata is synchronised and validated before publication, and build outputs receive SHA-256 checksums. The next feature phase remains the Vision and Attachments foundation.

## Completed

### v0.9.2 — GitHub Release Infrastructure

- Added committed Windows x86-64, Linux x86-64, and macOS Universal export presets.
- Added push/PR validation using the official Godot 4.6.3 editor and export templates.
- Added tag-triggered exports and automatic GitHub Release publication.
- Added Windows ZIP, Linux tar.gz, unsigned macOS ZIP, and SHA-256 checksum generation.
- Added a Godot-native two-path `release.sh` for source-only pushes or production tags.
- Added safe semantic-version synchronisation across runtime, package manifests, and export presets.
- Added release metadata, bundled-JSON, preset, and tag validation tooling.
- Added release documentation and an operator checklist.
- Preserved the v0.9.1 application feature set and all existing data formats.

### v0.9.1 — Strict Warning Maintenance

- Wired series context into Idea Generator prompts instead of leaving its API parameter unused.
- Renamed project-package remapping locals and parameters that shadowed Godot's built-in `remap()` function.
- Added explicit FileDialog enum casts for strict Godot 4.6 compilation.
- Preserved all v0.9.0 Series System data formats and behaviour.

### v0.9.0 — Series System Foundation

- Added a native Series Manager with create, edit, save, duplicate, delete, search, usage-count, import, export, and AI-drafting workflows.
- Added standalone versioned series JSON files outside character projects.
- Added names, aliases, descriptions, categories, setting guidance, canon notes, visual direction, generation rules, default tags, and matching keywords.
- Added project-level series selection, clearing, Auto Series matching, missing-reference repair visibility, and default-tag application.
- Added deterministic local Auto Series scoring and safe handling of ambiguous equal-scoring candidates.
- Added Series and Unassigned filters plus bulk assignment, clearing, auto-match, and tag application in Character Library 2.0.
- Added current-series display throughout library cards, rows, project details, recent projects, search, and Dashboard statistics.
- Added assigned-series context to full character generation, field suggestions, Controlled Build, Character Builder, Group Scene Generator, Relationship Matrix generation, and Card Workflow Studio planning.
- Added portable `.ccfseries` renamed-ZIP Series Packs with versioned manifests and collision-safe ID remapping.
- Added referenced series inclusion/remapping in `.ccfproject` packages.
- Added CCF series-reference round trips through the namespaced Character Card V2 extension.
- Kept project format version 2 because series assignment is additive and was already reserved in metadata.

### v0.8.1 — Parser hotfix

- Replaced the invalid constructor-backed PNG signature constant with a typed static byte array.
- Retained all v0.8.0 Character Library 2.0 features unchanged.

### v0.8.0 — Character Library 2.0

- Replaced the basic project list with thumbnail-grid and compact-list views.
- Added project portrait thumbnails with source-image freshness checks and disposable cache storage.
- Added incremental per-project indexing based on `character.json` fingerprints.
- Added broad project/character/card-text search and multiple sorting modes.
- Added favourites-only, folder, collection, tag, and unfiled filters.
- Added virtual folders and collections stored as recoverable project metadata rather than filesystem moves.
- Added project detail summaries covering the full roster and recorded import metadata.
- Added grid/list multi-selection and bulk favourite, tag, folder, collection, and delete actions.
- Added library-wide case-insensitive tag merging across project and character metadata.
- Added remembered library view and filter preferences.
- Updated Dashboard statistics to reuse the library index.
- Kept project format version 2 because library organisation is additive.

### v0.7.1 — Strict-Typing Maintenance

- Fixed the Card Workflow generation instruction selection so no local variable is inferred from a `Variant` returned by `Dictionary.get()`.
- Preserved the exact v0.7.0 prompt behaviour while compiling cleanly when Godot warnings are treated as errors.
- Updated portable project-package manifests to identify the patch release correctly.

### v0.7.0 — Import / Export Foundation

- Added detachable Import / Export Studio with mapping preview, validation, card import/export, portable project packaging, and batch export tabs.
- Added Character Card V2 JSON export for any selected character in a multi-character CCF project.
- Added Character Card V2 JSON import and tolerant legacy V1 import into new clean CCF projects.
- Added PNG/APNG `chara` metadata reading and Character Card V2 metadata writing into a copy of an existing PNG image.
- Added preservation of alternate greetings, embedded character lorebooks, creator metadata, character-version metadata, and unknown V2 extension data.
- Added a namespaced CCF V2 extension for round-tripping template-specific and CCF-only character data without pretending those fields are standard card fields.
- Added compatibility reports showing direct, preserved, and namespaced field mappings before export.
- Added `.ccfproject` renamed-ZIP packages containing project JSON, project assets, a manifest, and referenced custom templates.
- Added fresh-UUID package imports, safe relative-path extraction, and custom-template ID collision remapping.
- Added batch Character Card V2 JSON export driven by saved Split-card batch workflows.
- Kept the internal project format at version 2 because the new interoperability fields are additive.

### v0.6.0 — Relationships and Multi-Character Card Workflows

- Added a structured sparse relationship-matrix model with one canonical record per character pair.
- Added detachable Relationship Matrix editing for labels, status, intensity, tags, shared summaries, directional perspectives, dynamics, and notes.
- Added AI-assisted relationship generation across selected character sets with review-before-project-apply behaviour.
- Added relationship-aware context to full-character generation, field suggestions, Controlled Build, Group Scene Generator, and Card Workflow Studio planning.
- Added a detachable Card Workflow Studio with multi-character single-card, split-card batch-plan, and group-card planning modes.
- Added reusable project-level `card_workflows[]` drafts with per-character output directions.
- Added safe UUID remapping for relationships and workflow references when projects are duplicated.
- Added relationship cleanup and workflow-reference pruning when characters are removed.
- Kept the project format at version 2 because the new structures are additive to the existing multi-character container.

### v0.5.3 — Responsive Workspace Layout

- Replaced fixed single-line workspace control rows with wrapping horizontal flow layouts where multi-character controls can exceed ordinary 16:9 widths.
- Workspace actions now reflow onto additional rows instead of rendering outside the visible application frame.
- Project, character-roster, and template controls wrap at narrower desktop widths while naturally remaining compact on ultrawide displays.
- Preserved wider-display expansion without introducing fixed 16:9 letterboxing or horizontal scrolling.

### v0.5.2 — Godot 4.6 Warning Cleanup

- Replaced two mixed-type ternary expressions with explicit typed/default-value branches in the Character Builder code.
- Renamed local `mode` variables in the Controlled Build window to avoid shadowing `Window.mode`.
- Renamed the local preview `title` variable to avoid shadowing `Window.title`.
- Kept Controlled Build job metadata and runtime behaviour unchanged.

### v0.5.1 — Multi-Character Compile Hotfix

- Fixed the explicit integer typing required by Godot 4.6 when calculating the next character number from variant-backed project data.

### v0.5.0 — Multi-Character Project Foundation

- Upgraded the central project schema to format v2 with a `characters[]` collection.
- Added non-destructive migration from the Godot rewrite's format-v1 single-character projects.
- Added project-level shared context for premise, setting, current situation, shared rules, and notes.
- Added in-workspace character roster switching, creation, duplication, removal, and optional group-role metadata.
- Preserved independent templates, generation histories, builder state, assets, and custom fields per character.
- Added project-level Shared Context and Group Scene Generator native windows.
- Added the first multi-character AI workflow with selectable characters, shared-context generation, per-character scenario suggestions, and review-before-apply behaviour.
- Added shared project context to normal character, field-suggestion, and controlled-build generation prompts.
- Updated Character Library and Dashboard semantics for multi-character projects.
- Added per-character asset directory foundations for later image and attachment systems.

### v0.4.1 — Controlled Section Building

- Added detachable Safe Section Build, Custom Section Build, and selected-field Revision workflows.
- Added explicit protected-context prompts so unselected content can guide consistency without becoming writable output.
- Added hard allowed-field enforcement in Generation Preview for controlled jobs.
- Added per-field keep/replace review through the existing editable Generation Preview.
- Added freeform revision instructions for partial regeneration of existing content.
- Added balanced JSON extraction, common local JSON repair, and one automatic AI response-repair pass.
- Added parse-strategy and repair-count generation diagnostics/history metadata.

### v0.4.0 — Guided Character Builder

- Added a detachable native Character Builder.
- Added data-driven Foundation, Personality, Background, Scene, and Review steps.
- Added JSON-backed builder presets.
- Added per-step and full-builder AI filling through the shared generation queue.
- Added AI concept-to-builder extraction.
- Added builder completion and assembled-concept review.
- Added Send to Concept and Apply to Character workflows.
- Added non-destructive fill-empty behaviour with optional overwrite mode.
- Stored reusable builder state inside each character project's workspace data.
- Added originating-project checks for asynchronous AI results to prevent cross-character result leakage after project switches.

### v0.3.3 — Native Window Startup Fix

- Fixed native tool-window construction order so `force_native` is configured only after each new `Window` has been hidden.
- Removed the startup errors introduced by v0.3.2 while preserving detachable Idea Generator and Generation Preview windows.

### v0.3.2 — Native Tool Windows

- Moved Idea Generator and Generation Preview into detachable native OS windows.
- Kept large tool windows non-exclusive so the main workspace can remain interactive.
- Added remembered tool-window size and placement in a separate disposable UI-state file.
- Added off-screen placement rejection for changed monitor layouts.
- Added project ownership checks for Generation Preview and automatic tool closing when switching characters.

### v0.3.1 — Warning Cleanup

- Removed an unused generation-service local variable.
- Renamed an Idea Generator local that shadowed GDScript's built-in `seed()` function.
- Kept the v0.3 template-system feature set unchanged while cleaning the reported editor warnings.

### v0.3.0 — Template System

- Added a native Template Manager.
- Added separate versioned user-template JSON storage.
- Added create, duplicate, import, export, save, and delete template workflows.
- Kept the built-in Default template read-only.
- Added section creation, editing, deletion, and reordering.
- Added Standard and Interview/Q&A section kinds.
- Added field creation, editing, deletion, and reordering.
- Added line, multiline, tags, number, checkbox, and select field types.
- Added required and AI-generation flags.
- Added per-field AI instructions/questions.
- Added global template AI rules.
- Added strict/flexible output discipline and unexpected-field handling.
- Added template switching per character while retaining hidden project data.
- Added template validation and format-v1 → format-v2 normalisation.
- Extended AI prompts and Generation Preview for typed custom fields.

### v0.2.x — Generation Foundation

- Added a shared queued AI generation service.
- Added active-job cancellation, queue status, and retry handling.
- Added full-generation preview with selective field application.
- Added editable generated proposals.
- Added per-field AI suggestions.
- Added an Idea Generator.
- Added approximate concept token estimates.
- Added multiple OpenAI-compatible API profiles.
- Added compatible `/models` discovery.
- Fixed modal lifecycle issues.
- Fixed maximised ultrawide letterboxing by using expandable canvas scaling.

### v0.1.x — Application Foundation

- Created the Godot 4.6 project structure.
- Added native application shell and navigation.
- Added versioned character project JSON format.
- Added per-character asset directories.
- Added settings persistence.
- Added template-generated editing tabs and fields.
- Added Character Library scanning, search, open, duplicate, and delete.
- Added asynchronous OpenAI-compatible generation.
- Added generation metadata/history.
- Fixed initial generated tab labels and GDScript shadowing warnings.

## In Progress

- Real-world testing against multiple OpenAI-compatible backends.
- Stronger generation-response repair and structured diagnostics.
- UI refinement as larger workflows are restored.
- Continued testing of template editing and custom typed fields.
- Real-world testing of guided builder AI extraction/fill behaviour across different providers.
- Real-world testing of relationship-matrix AI output across providers and larger character rosters.
- Real-world testing of Card Workflow Studio planning quality and project-reference maintenance.
- Real-world round-trip testing against Character Card V2 files produced by multiple ecosystem tools.
- Real-world PNG/APNG metadata testing across different card images and chunk layouts.
- Portable `.ccfproject` import/export testing with large asset trees and custom-template collisions.
- Real-world Character Library 2.0 testing with large project collections, mixed portrait formats, and repeated bulk metadata operations.
- Real-world Series Manager and `.ccfseries` pack testing across large local series libraries.
- Auto Series scoring tests against ambiguous franchises, aliases, and overlapping keywords.
- Verification that all supported AI workflows consistently honour assigned series guidance across providers.

## Next Up

### v0.10 — Vision and Attachments Foundation

- Add separate text and vision provider roles without breaking existing API profiles.
- Attach local images, GIFs, text files, PDFs, subtitles, transcripts, and notes to character projects.
- Keep attachment metadata in project JSON while storing source files as ordinary assets.
- Add image and document preprocessing with explicit context-size summaries before generation.
- Add character-image analysis and concept extraction into the existing review-first generation workflow.
- Add full-card visual analysis and controlled suggestions without directly overwriting card content.
- Design the attachment model for later image-generation prompts, emotion images, and mobile/remote workflows.

## Planned Features

### Generation Improvements

- Streaming text support where providers support it.
- Structured generation diagnostics and response-repair attempts.
- Separate text, vision, and image provider roles/profiles.
- Recent/favourite model lists.
- Provider capability detection.
- Token-limit metadata and stronger context-budget estimation.

### Multi-Character Workflows

- Relationship matrix generation and editing. **Foundation completed in v0.6.0.**
- Relationship-aware generation context. **Foundation completed in v0.6.0.**
- Multi-character single-card planning. **Foundation completed in v0.6.0; final generation/export still planned.**
- Split-card batch planning. **Foundation completed in v0.6.0; automatic full-card batch execution still planned.**
- Group-card planning workflows. **Foundation completed in v0.6.0; dedicated export formats still planned.**
- Shared lore and deeper group continuity tools.
- Relationship visualisation/flowchart integration in the future Character Library 2.0.

### Character Library 2.0

- Thumbnail grid and optional list view. **Completed in v0.8.0.**
- Sorting and advanced filters. **Foundation completed in v0.8.0; series filters added in v0.9.0.**
- Tags and tag merging. **Completed in v0.8.0.**
- Virtual folders. **Completed in v0.8.0.**
- Card groups and variations.
- Series sidebar. **Completed in v0.9.0.**
- Favourites. **Completed in v0.8.0.**
- Flowchart/relationship views.
- Incremental disposable search index. **Completed in v0.8.0.**

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

- Images as concept references.
- GIF frame handling.
- Image URL references.
- Character analysis and full-card analysis.
- PDF/text/subtitle/transcript attachments.
- Attachment preprocessing and context budgeting.

### Image Generation

- Stable Diffusion-compatible provider support.
- OpenAI-compatible image provider support.
- Natural-language image prompt builder.
- Generated image gallery.
- Character portrait assignment.
- Emotion-image generation and regeneration.
- Per-emotion prompt editing.

### Import / Export

- Character Card V2 JSON import/export. **Foundation completed in v0.7.0.**
- Character Card V2 PNG/APNG metadata read and PNG metadata write. **Foundation completed in v0.7.0.**
- SillyTavern ecosystem field mapping and compatibility reports. **Foundation completed in v0.7.0; broader interoperability testing remains.**
- Embedded lorebook preservation. **Round-trip preservation completed in v0.7.0; dedicated editing remains planned.**
- Portable Character Card Forge `.ccfproject` packages. **Foundation completed in v0.7.0.**
- Split-workflow batch JSON export. **Foundation completed in v0.7.0; PNG batch export and automatic generation remain planned.**
- Additional external formats where they provide meaningful interoperability.

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
- Missing-field checks.
- Token estimates.
- Revision history and snapshots.

## Data and Content Tools

- Keep the character project JSON schema documented.
- Maintain template schema documentation and migration support.
- Maintain project-format migration functions as the schema evolves beyond format version 2.
- Maintain the documented `.ccfproject` renamed-ZIP package format and version it when compatibility changes.
- Keep generated assets referenced by relative paths inside portable packages.
- Add reusable template packs if community template sharing becomes useful.

## Technical Improvements

- Add automated schema validation tests.
- Add project recovery from interrupted writes using temporary-file replacement.
- Add optional autosave with safe snapshots.
- Add async thumbnail generation.
- Generalise the cancellable task service beyond AI jobs to scanning and imports.
- Add structured application logging and a diagnostics viewer.
- Add secure credential-storage options where platform support permits.
- Split very large UI scripts into reusable components as workflows expand.

## Polish

- Custom application theme and stronger visual identity.
- Continue responsive-layout refinement for very narrow desktop windows and future high-density toolbars.
- Continue deciding which substantial tools should become detachable native windows while keeping small confirmations embedded.
- Keyboard shortcuts.
- Drag-and-drop files.
- Better empty states and onboarding.
- Native notifications for completed long-running jobs where useful.

## Long-Term Ideas

- Optional LAN/mobile companion interface implemented as a separate service rather than embedding the main desktop UI in a web frontend.
- Plugin/provider extension API.
- Community template sharing.
- Batch character generation pipelines.
- Local semantic search over large character libraries.

## Deferred / Experimental Ideas

- Legacy database import is intentionally deferred and is not a compatibility goal.
- Reproducing the old PyWebView interface is explicitly not planned.
- A mobile browser interface will only return if there is a strong workflow need and it can remain cleanly separated from the desktop application core.
