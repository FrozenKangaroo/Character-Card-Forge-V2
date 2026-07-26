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
- Data formats are versioned and older content should remain usable where practical.
- New features extend the central project model rather than create parallel copies of character state.
- Wider desktop windows expose additional workspace instead of letterboxing a fixed interface.
- Detachable native tool windows are used where multi-monitor workflows benefit; primary navigation pages may remain embedded when clearer.
- Generation parity ports useful V1 behaviour into the Godot architecture rather than recreating PyWebView-specific implementation details.
- Workspace/editing structure, AI-generation structure, and interoperable Character Card output fields are related but distinct layers.

## Current Development Phase

**v0.13 development candidate — Generation Parity Core**

The v0.12 source milestone is already merged into `main`: it contains expanded image generation, separated image providers, and Generation Parity Phase 1. v0.13 moves parity into the generation engine and now also makes the V1-style structured Description/Personality expectations editable template data.

The running development build displays **v0.13.0**. Published/tagged release metadata remains controlled by the release workflow until an actual release promotion is performed.

The current v0.13 candidate now includes:

- semantic completeness validation after ordinary JSON parsing;
- one targeted repair pass for valid-but-incomplete full-character results;
- revalidation before Generation Preview;
- repair diagnostics and a visible cancellable repair queue stage;
- template format **3**, adding first-class `generation_groups` and generation components;
- automatic loading/normalisation of older format-2 templates;
- generation groups that bind many structured components into an existing interoperable card/workspace field rather than creating extra Character Card top-level fields;
- add/remove/reorder generation groups and components;
- per-group enable/disable, output-field binding, and allow-extra-components policy;
- per-component label, AI instruction, enabled state, required state, and ordering;
- disabled components omitted from both generation prompts and completeness validation;
- enabled required components used by semantic missing-component repair;
- a Template Manager **Edit Generation Components** workflow;
- the Default Description structure: Age, Appearance, Outfit Style, Distinguishing Features;
- a richer V1-inspired Default Personality structure: Mind, Moral Alignment, Emotional Tendencies, Decision Style, Occupation, Likes, Dislikes, Hobbies, Skills, Boundaries, Risk Tolerance, Secrecy, Relationship Behavior toward `{{user}}`, Loyalty, and Speech Style;
- standard Character Card Description and Personality remain the final interoperable output fields.

## Completed

### v0.12 source milestone — Image Expansion + Generation Parity Phase 1

Source merged to `main`; it was a source milestone rather than a separate published release.

- Separated Character AI profiles from dedicated Image Generation providers with settings-format-v6 migration.
- Added separate Character AI and Image Generation Settings tabs.
- Added Forge/Automatic1111 WebUI generation alongside OpenAI-compatible Images APIs.
- Added `/sdapi/v1/txt2img`, checkpoint/sampler discovery, OpenAI `/models` discovery, batches, sampler/steps/CFG/seed controls, returned-seed capture, Regenerate, and New Seed Variant workflows.
- Kept Image Studio as a selected main workspace while provider credentials live in Settings.
- Source-audited V1 generation behaviour and documented the quality/architecture gaps.
- Made Generation Concept authoritative in the Default template.
- Restored Description to physical/external semantics.
- Expanded Personality generation guidance and strengthened Scenario / First Message continuity and Example Dialogue formatting.

### v0.11.0 — Image Generation Foundation

- Added an independent Image generation role.
- Added OpenAI-compatible image generation, flexible response decoding, PNG normalisation, generated-image storage, prompt construction, gallery/preview, portrait assignment, metadata, documentation, and validation.

### Release Workflow Maintenance after v0.11.0

- `release.sh` automatically fetches/fast-forwards a clean destination `main`, reconciles already-merged synced content, stops for genuine local divergence, and removes the normal manual post-merge fetch/reset step.

### v0.10.0 — Vision and Attachments Foundation

- Added independent Text/Vision provider assignments, project/per-character attachments, preprocessing/context budgeting, generation context, review-first visual analysis, and portable attachment storage.

### v0.9.x — Series and Release Infrastructure

- Added versioned series bibles, Series Manager, categories/aliases/canon/visual/generation guidance, deterministic Auto Series, series-aware library tools, `.ccfseries`, export presets, GitHub Actions releases, semantic-version tooling, and release-helper infrastructure.

### v0.8.x — Character Library 2.0

- Added thumbnail/list views, portrait thumbnails, incremental indexing, broad search, sorting, favourites, folders, collections, tags, filters, bulk tools, and dashboard statistics reuse.

### v0.7.x — Import / Export Foundation

- Added Character Card V1/V2 import, V2 export, PNG/APNG metadata support, compatibility reports, lorebook preservation, CCF extension round trips, portable `.ccfproject`, and split-workflow JSON export.

### v0.6.x — Relationships and Multi-Character Card Workflows

- Added relationship matrices, directional editing/generation, relationship-aware context, and multi-character Card Workflow Studio planning.

### v0.5.x — Multi-Character Project Foundation

- Added project format v2 with `characters[]`, migration, shared context, roster tools, independent per-character state/assets/templates, Group Scene generation, and per-character asset directories.

### v0.4.x — Guided and Controlled Building

- Added Guided Character Builder, presets, AI fill/extraction, Safe/Custom Section Build, selected-field revision, protected context, review-first field application, JSON repair, and diagnostics.

### v0.3.x — Template System and Native Tool Windows

- Added Template Manager, versioned user templates, editable sections/fields/types/AI instructions/output policy, migration/validation, Idea Generator, and Generation Preview.

### v0.2.x — Generation Foundation

- Added queued generation, cancellation, retries, editable previews, selective application, field suggestions, Idea Generator, token estimates, API profiles, and model discovery.

### v0.1.x — Application Foundation

- Added the Godot 4.6 shell, project JSON, settings, template-driven editing, Character Library foundation, asynchronous generation, and generation history.

## In Progress

### v0.13 — Generation Parity Core candidate

**Implemented:**

- Semantic completeness validation and one bounded targeted repair pass.
- Revalidation before review and repair diagnostics metadata.
- Template format 3 with generation groups/components and backwards loading of format 2.
- Explicit separation between normal workspace/output fields and structured generation components.
- Editable output bindings from a generation group to an existing card/workspace field.
- Add/remove/reorder/enable/disable generation groups and subcomponents.
- Required/optional component semantics and per-component AI instructions.
- Dynamic contract prompts and validation generated from the active template rather than fixed Default Personality labels.
- Default V1-inspired Description and Personality structures stored as data.
- Existing Generation Preview remains the final review boundary.
- Existing asynchronous queue/cancellation architecture remains authoritative.

**Still in v0.13:**

- Private pre-generation Q&A/interview passes driven by enabled template questions.
- Required Q&A completeness checking and retry of only missing answers.
- Feed completed Q&A into final generation as private planning context rather than exported card content.
- Define builder/context precedence so explicit user-entered builder guidance outranks generic generation assumptions without silently rewriting unrelated facts.
- Add conservative concept-fidelity diagnostics for supplied names/distinctive literal markers, with at most one stricter retry for clear drift.
- Improve visible stages: planning/Q&A, generation, fidelity check, validation, repair, ready for review.
- Present semantic validation and repair diagnostics directly in Generation Preview.
- Expand configurable special contracts beyond the current component/minimum-length/marker foundations, including greeting counts and constrained sets where useful.
- Test component toggling and semantic repair across real text backends and deliberately incomplete/low-token responses.

### Ongoing validation

- Real-world testing across multiple OpenAI-compatible text backends.
- Compare fresh characters against pre-parity V2 output, especially Description/Personality separation and concept fidelity.
- Forge/Automatic1111 and OpenAI-compatible image batch testing.
- Template format-2 → format-3 migration and custom generation-component testing.
- Guided Builder, relationship, group/card workflow, import/export, large-library, series, attachments, vision, and `.ccfproject` interoperability testing.

## Next Up

### Remaining v0.13 Generation Parity Core

Private Q&A is the next major parity slice, followed by builder precedence, conservative concept-fidelity retry, richer multi-stage progress, and Generation Preview diagnostics.

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
- Generation components/output bindings and editable per-template semantic contracts. **Core implemented in v0.13 candidate; expand special contracts over time.**
- V1-style private Q&A completeness and targeted missing-answer retries. **Planned for v0.13.**
- Conservative concept-fidelity validation/retry. **Planned for v0.13.**
- Semantic completeness validation and targeted repair. **Initial core implemented in v0.13 candidate.**
- Builder guidance precedence for full generation. **Planned for v0.13.**
- V1-style Full/Lite/Compact-Lite or equivalent multi-pass strategies after the core contract is stable.
- Section-by-section generation/continuation with per-stage progress, inspired by the later V1 beta workflow once its desired Godot behaviour is cleanly specified.
- Configurable special formatting rules such as `<START>` counts, greeting counts, and constrained tag sets.
- Recent/favourite model lists, broader provider capability detection, token-limit metadata/context estimation, and reusable provider presets.

### Multi-Character Workflows

- Relationship matrix generation/editing and relationship-aware context. **Foundation completed.**
- Multi-character single-card planning, split-card batch planning, and group-card planning. **Foundations completed; final generation/export execution remains planned.**
- Shared lore/deeper continuity and relationship visualisation/flowchart views.

### Character Library 2.0

- Thumbnail grid/list, sorting/filtering, tags/tag merging, folders, collections, series filters, favourites, and incremental index. **Foundations completed.**
- Card groups/variations, flowchart/relationship views, and richer image/portrait filtering.

### Series System

- Series definitions/bibles, Manager, generation guidance, deterministic Auto Series, categories, import/export, and portable packs. **Foundations completed.**
- Provider-assisted semantic matching, series artwork, richer hierarchy, and collection-level defaults.

### Vision and Attachments

- Images as concept references and review-first analysis. **Foundation completed.**
- GIF frame selection, image URL references, native PDF text extraction, preprocessing/context refinement, and visual-reference handoff to v0.14 image workflows.

### Image Generation

- OpenAI-compatible generation, prompt builders, gallery, portrait assignment. **Foundation completed.**
- Forge/Automatic1111, provider settings, checkpoint/sampler discovery, batches, seeds, regeneration, and SD defaults. **v0.12 source milestone implemented.**
- Image-to-image/reference generation, emotion workflows, per-emotion prompts, visual presets, richer provider controls, and LoRA/embedding helpers. **v0.14/later.**

### Import / Export

- Character Card V2 JSON/PNG/APNG, SillyTavern-oriented mappings, lorebook preservation, `.ccfproject`, and split-workflow JSON export. **Foundation completed.**
- Broader ecosystem testing, PNG batch export, automatic split-workflow generation, additional meaningful formats, and generated/emotion image export options.

### Front Porch Integration

- Data folder discovery/configuration, character scanning, import, install/export, character management, and chat reading/export where practical.

### Quality Tools

- Final AI Audit, card rating/improvement suggestions, consistency checking, broader missing-field reports, token estimates, revision history/snapshots, and image-recipe comparison.

## Data and Content Tools

- Keep character-project JSON and template schemas documented.
- Maintain project/template migrations as formats evolve.
- Maintain and version the `.ccfproject` renamed-ZIP package format.
- Keep generated assets referenced through relative portable paths.
- Preserve older generated-image records as metadata evolves.
- Add reusable template packs if community template sharing becomes useful.
- Maintain documentation for workspace fields vs generation components vs output bindings.

## Technical Improvements

- Add automated schema/behaviour tests beyond marker validation.
- Add recovery from interrupted writes, optional autosave/snapshots, async thumbnails, general cancellable tasks, structured logging/diagnostics, secure credential storage, additional authentication modes, UI script decomposition, and provider-adapter abstractions as diversity grows.
- Keep generation validators/repair logic in reusable services rather than embedding V1 assumptions in workspace UI code.

## Polish

- Custom application theme/visual identity, responsive layout refinement, keyboard shortcuts, drag-and-drop, better onboarding/empty states, native completion notifications, denser image gallery browsing, and richer generation progress/repair presentation.

## Long-Term Ideas

- Optional LAN/mobile companion service, plugin/provider extension API, community template sharing, batch character generation, local semantic library search, and provider-agnostic image recipe presets.

## Deferred / Experimental Ideas

- Legacy database import remains intentionally deferred.
- Reproducing the old PyWebView interface is not planned.
- A mobile browser interface only returns if a strong separated workflow need appears.
- Highly backend-specific Stable Diffusion controls remain optional adapter-owned features rather than mandatory project fields.
- Exact recreation of V1 prompt strings is not a goal; source-audited behaviour should be expressed as maintainable Godot-native data and services.
