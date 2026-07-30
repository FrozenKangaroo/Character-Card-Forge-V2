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
- Workspace/editing structure, AI-generation structure, planning controls, and interoperable Character Card output fields are related but distinct layers.
- Stable IDs are internal references; user-facing names may change without silently breaking bindings or preferences.
- Major interface restructuring and visual polish should follow stable workflow architecture where practical, avoiding repeated UI rewrites while core authoring/generation systems are still changing.

## Current Development Phase

**v0.13.12 development candidate — Provider Capability + AI Image Prompt Authoring**

The v0.12 source milestone is already merged into `main`: it contains expanded image generation, separated image providers, and Generation Parity Phase 1. v0.13 has moved parity into the generation engine while runtime testing has also exposed workflow and provider-compatibility problems worth fixing before the larger v0.14 image expansion.

The running development build displays **v0.13.12**. Published/tagged release metadata remains controlled by the release workflow until an actual release promotion is performed.

The current v0.13 line includes:

- semantic completeness validation after ordinary JSON parsing;
- one targeted repair pass for valid-but-incomplete full-character results and revalidation before Generation Preview;
- fail-closed generation-contract protection and regression coverage for dispatch/contract regressions;
- template format 3 with first-class generation groups/components and backwards loading of format-2 templates;
- editable group/component ordering, enabled/required state, per-component AI instructions, output bindings, and allow-extra-components policy;
- multiple generation groups targeting one Character Card field composed in template order instead of later groups overwriting earlier groups;
- Default Description structure: Age, Appearance, Outfit Style, Distinguishing Features;
- richer V1-inspired Default Personality structure including Mind, Moral Alignment, Emotional Tendencies, Decision Style, Occupation, Likes, Dislikes, Hobbies, Skills, Boundaries, Risk Tolerance, Secrecy, Relationship Behavior toward `{{user}}`, Loyalty, and Speech Style;
- private pre-generation Interview / Q&A with bundled defaults, template overrides, manual answers, required-answer checking, and bounded retries;
- explicit planning precedence: source concept → manual Interview/Q&A → Builder guidance → AI interview answers → existing card values/generic inference;
- Mode & Style controls for Full/Lite/Compact Lite intent, writing style, First Message style, length, and custom greeting guidance;
- conservative concept-fidelity checks and one bounded correction pass for high-confidence supplied markers;
- multi-stage generation progress and Generation Preview diagnostics covering planning, generation, validation, fidelity, repair, and review without exposing private scratchpad content;
- configurable Alternative First Messages stored separately from the main First Message and exported through Character Card V2 alternate greetings;
- Generation Preview Apply Selected autosave and null-proposal filtering;
- default Vision Analysis restricted to observable physical/visual Description, with no default Personality inference;
- **Creative Concept** vision mode using an image as a visual seed for an original generation-ready concept rather than attempting to fill final card fields directly;
- Creative Concept preserving clear visual identity anchors while deliberately inventing coherent identity, motivations, conflicts, background hooks, secrets, setting possibilities, and roleplay potential when the image provides little narrative information;
- separate Text and Vision model selection for Character AI profiles;
- separate Text and Vision context/output configuration, including independent Vision output and temperature settings;
- best-effort `/models` capability discovery preserving raw metadata and recognising common context-window, maximum-output, and vision-capability fields where providers expose them;
- NanoGPT-aware detailed model discovery using its documented `detailed=true` mode so `context_length`, `max_output_tokens`, and capability metadata can be consumed when available;
- Text and Vision Auto output limits using detected per-model metadata independently, with manual values retained as fallbacks when metadata is unavailable;
- removal of the old 131,072 UI hard ceiling so large-model output limits can be entered without silent clamping;
- hardened assistant-response parsing for alternate OpenAI-compatible response envelopes and clearer reasoning/length diagnostics;
- Image Studio prompt state isolation between characters;
- V2 PNG export using the active portrait automatically when available;
- Image Studio prompt controls with real multiline word wrapping;
- AI-authored Image Studio prompts generated through the configured Character AI Text role from visual identity plus visually useful character/scenario context;
- explicit local image-prompt fallback preserving the deterministic visual-anchor builder for offline/no-extra-provider workflows;
- bounded local fallback appearance/outfit/scene detail and filtering of behavioural, symbolic, and transient prose;
- recoverable malformed provider JSON handled through the repair path without misleading engine-level parser errors;
- Character Project vs Character terminology/presentation cleanup;
- in-memory new-project drafts, empty-character pruning, first-character project naming, and placeholder-name save protection;
- global **Default Character Template** selection by stable template ID;
- Template Manager **Set as Default** state plus Settings → Defaults selection;
- first characters in new projects and newly added characters automatically inheriting the selected global default;
- existing characters retaining their assigned template when the global default changes;
- safe fallback to the built-in Default template when a configured custom default is deleted or unavailable.

## Completed

### v0.12 source milestone — Image Expansion + Generation Parity Phase 1

Source merged to `main`; it was a source milestone rather than a separate published release.

- Separated Character AI profiles from dedicated Image Generation providers with settings-format-v6 migration.
- Added separate Character AI and Image Generation Settings tabs.
- Added Forge/Automatic1111 WebUI generation alongside OpenAI-compatible Images APIs.
- Added checkpoint/sampler/model discovery, batches, sampler/steps/CFG/seed controls, returned-seed capture, Regenerate, and New Seed Variant workflows.
- Kept Image Studio as a selected main workspace while provider credentials live in Settings.
- Source-audited V1 generation behaviour and documented quality/architecture gaps.
- Made Generation Concept authoritative in the Default template.
- Restored Description to physical/external semantics and strengthened Personality, Scenario, First Message, and Example Dialogue guidance.

### v0.11.0 — Image Generation Foundation

- Added an independent image-generation role.
- Added OpenAI-compatible image generation, flexible response decoding, PNG normalisation, generated-image storage, prompt construction, gallery/preview, portrait assignment, metadata, documentation, and validation.

### Release Workflow Maintenance after v0.11.0

- `release.sh` automatically fetches/fast-forwards a clean destination `main`, reconciles already-merged synced content, stops for genuine local divergence, and removes the normal manual post-merge fetch/reset step.

### v0.10.0 — Vision and Attachments Foundation

- Added independent Text/Vision provider assignments, project/per-character attachments, preprocessing/context budgeting, generation context, review-first visual analysis, and portable attachment storage.

### v0.9.x — Series and Release Infrastructure

- Added versioned series bibles, Series Manager, categories/aliases/canon/visual/generation guidance, deterministic Auto Series, import/export, portable packs, export presets, validation/releases, semantic-version tooling, and release-helper infrastructure.

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

- Data-driven generation groups/components and output bindings.
- Required/optional component semantics, multi-group composition, semantic validation, bounded targeted repair, and fail-closed contract dispatch.
- Private Interview / Q&A planning, required-answer retries, Builder participation, and explicit planning precedence.
- App-level Mode & Style foundation.
- Conservative concept-fidelity diagnostics/correction.
- Multi-stage progress plus Generation Preview diagnostics.
- Alternative First Messages with V2 alternate-greeting export.
- Runtime project-draft lifecycle and naming cleanup.
- Physical-only default Vision Analysis and separate Vision model selection.
- Creative Concept vision mode that produces source concept material rather than bypassing normal character generation.
- Per-model capability discovery with independent Text/Vision output limits and context settings.
- NanoGPT detailed capability discovery for provider-published context/output metadata.
- Large output-token values no longer constrained by the old 131,072 UI ceiling.
- Hardened assistant-response envelope compatibility and reasoning/length diagnostics.
- AI-authored character → image prompt generation through the Text role, with the existing deterministic visual-anchor path retained as an explicit local fallback.
- Default Character Template preference for future characters with per-character assignment preservation.
- Existing Generation Preview remains the final review boundary.
- Existing asynchronous queue/cancellation architecture remains authoritative.

**Still in v0.13:**

- Expand configurable special generation contracts beyond component/minimum-length/marker foundations, including greeting counts and constrained sets where useful.
- Complete V1-equivalent split/multi-pass execution for Lite/Compact Lite rather than only density guidance.
- Continue real-provider regression testing of Q&A retries, Builder precedence, Mode & Style, component toggling/composition, semantic repair, concept-fidelity correction, malformed-JSON recovery, response-envelope compatibility, Creative Concept generation, capability discovery, AI image-prompt authoring, and default-template workflows.
- Consider expanding automatic concept-fidelity marker types only where runtime evidence shows they can remain high-confidence and avoid false-positive rewrites.
- Consider per-Builder-field provenance only if later workflows need to distinguish manual, preset, concept-extracted, and Builder-AI values inside the accepted scratchpad.

### Ongoing validation

- Real-world testing across multiple OpenAI-compatible text and vision backends.
- Compare fresh characters against pre-parity V2 output, especially Description/Personality separation and concept fidelity.
- Test Interview → missing-answer retry → full generation → semantic repair, including templates that override or disable the bundled interview.
- Test precedence conflicts deliberately: concept versus manual Q&A, manual Q&A versus Builder, Builder versus AI interview answers, and semantic repair after those conflicts.
- Test First Message modes deliberately: Detailed/Cinematic should be substantially fuller while Brief remains intentionally short.
- Test deliberate concept-fidelity drift: supplied name, numeric age, explicit cup-size markers, equivalent written-out ages, and advisory quoted-marker omissions.
- Confirm multiple enabled generation groups bound to the same output field compose in template order and targeted repair can identify missing groups/components.
- Confirm malformed provider JSON enters normal local/provider repair without noisy engine parser failures.
- Confirm alternate successful provider envelopes produce usable assistant text and reasoning-only/length failures produce actionable diagnostics.
- Confirm Alternative First Messages remain separate from the main First Message and survive V2 export.
- Confirm Apply Selected persists accepted generation before immediately entering Image Studio.
- Confirm default Vision Analysis keeps environment/pose out of Description and filters null optional proposals.
- Test Creative Concept with sparse and detailed images: visual anchors should persist while invented narrative material should be coherent, useful, and clearly more than an image caption.
- Test model capability discovery across backends that expose rich metadata, partial metadata, and IDs only; unknown limits must remain unknown rather than guessed.
- Confirm NanoGPT `detailed=true` discovery loads documented `context_length` / `max_output_tokens` metadata when the selected model exposes it.
- Test Text and Vision models with different context/output limits and confirm independent Auto/manual behavior.
- Test draft lifecycle deliberately: empty new project → leave without Library entry; first named character → first save; empty added character → prune; manual project name → preserve.
- Test default-template lifecycle deliberately: select custom default → new project inherits it → Add Character inherits it → change default → existing characters unchanged → delete default → built-in fallback.
- Compare AI-authored prompts against the local fallback across simple and elaborate character cards; explicit Additional visual direction must remain authoritative and stable physical identity must not drift.
- Forge/Automatic1111 and OpenAI-compatible image batch testing.
- Template format-2 → format-3 migration and custom generation-component testing.
- Guided Builder, relationship, group/card workflow, import/export, large-library, series, attachments, vision, and `.ccfproject` interoperability testing.

## Next Up

### Remaining v0.13 Generation Parity Core

True split/multi-pass Lite/Compact Lite execution and broader configurable generation contracts are the main remaining parity work after the current runtime regression cycle. Continue tightening real-provider behaviour before the larger image milestone.

### v0.14 — Image Workflow Expansion

The immediate Image Studio correctness/usability repairs landed during v0.13 because they blocked normal character → portrait testing. The AI-authored prompt foundation was promoted into v0.13.12 after runtime testing showed deterministic Description extraction was too limiting; v0.14 should build on it rather than replace it.

- Add image-to-image/reference-image generation where supported.
- Allow generated images and managed visual attachments to become generation references without embedding binary data in JSON.
- Add emotion-image generation/regeneration using the existing `emotion_images/` tree.
- Add named emotions/expressions and per-emotion editable prompts.
- Add reusable visual-style/prompt presets.
- Add richer gallery management including intentional deletion with portrait/reference safety checks.
- Add provider-specific quality/aspect controls where useful.
- Add optional Stable Diffusion advanced helpers such as LoRA/embedding-oriented prompt tools without making one WebUI ecosystem part of the central character schema.
- Expand the AI-authored prompt workflow with reusable refinement/regeneration controls while retaining the deterministic/local visual-anchor fallback as the no-extra-provider path.

### Post-core Authoring Workflow and Interface Pass — version TBD

Do this after the major generation, Q&A, image, import/export, and project workflows are sufficiently stable that UI changes are unlikely to be immediately invalidated by another architecture change.
