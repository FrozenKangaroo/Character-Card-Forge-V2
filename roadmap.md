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

**v0.13.10 development candidate — Generation Parity + Runtime Usability**

The v0.12 source milestone is already merged into `main`: it contains expanded image generation, separated image providers, and Generation Parity Phase 1. v0.13 has moved parity into the generation engine while runtime testing has also exposed workflow problems worth fixing before the larger v0.14 image expansion.

The running development build displays **v0.13.10**. Published/tagged release metadata remains controlled by the release workflow until an actual release promotion is performed.

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
- separate Text and Vision model selection for Character AI profiles;
- Image Studio prompt state isolation between characters;
- V2 PNG export using the active portrait automatically when available;
- Image Studio prompt controls with real multiline word wrapping;
- balanced image-prompt synthesis focused on stable visual identity instead of converting every Description sentence into tags;
- bounded appearance/outfit/scene prompt detail and filtering of behavioural, symbolic, and transient prose from automatic image prompts;
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
- Image prompt correctness/usability repairs needed for character → portrait testing.
- Default Character Template preference for future characters with per-character assignment preservation.
- Existing Generation Preview remains the final review boundary.
- Existing asynchronous queue/cancellation architecture remains authoritative.

**Still in v0.13:**

- Expand configurable special generation contracts beyond component/minimum-length/marker foundations, including greeting counts and constrained sets where useful.
- Complete V1-equivalent split/multi-pass execution for Lite/Compact Lite rather than only density guidance.
- Continue real-provider regression testing of Q&A retries, Builder precedence, Mode & Style, component toggling/composition, semantic repair, concept-fidelity correction, malformed-JSON recovery, and default-template workflows.
- Consider expanding automatic concept-fidelity marker types only where runtime evidence shows they can remain high-confidence and avoid false-positive rewrites.
- Consider per-Builder-field provenance only if later workflows need to distinguish manual, preset, concept-extracted, and Builder-AI values inside the accepted scratchpad.

### Ongoing validation

- Real-world testing across multiple OpenAI-compatible text backends.
- Compare fresh characters against pre-parity V2 output, especially Description/Personality separation and concept fidelity.
- Test Interview → missing-answer retry → full generation → semantic repair, including templates that override or disable the bundled interview.
- Test precedence conflicts deliberately: concept versus manual Q&A, manual Q&A versus Builder, Builder versus AI interview answers, and semantic repair after those conflicts.
- Test First Message modes deliberately: Detailed/Cinematic should be substantially fuller while Brief remains intentionally short.
- Test deliberate concept-fidelity drift: supplied name, numeric age, explicit cup-size markers, equivalent written-out ages, and advisory quoted-marker omissions.
- Confirm multiple enabled generation groups bound to the same output field compose in template order and targeted repair can identify missing groups/components.
- Confirm malformed provider JSON enters normal local/provider repair without noisy engine parser failures.
- Confirm Alternative First Messages remain separate from the main First Message and survive V2 export.
- Confirm Apply Selected persists accepted generation before immediately entering Image Studio.
- Confirm default Vision Analysis keeps environment/pose out of Description and filters null optional proposals.
- Test draft lifecycle deliberately: empty new project → leave without Library entry; first named character → first save; empty added character → prune; manual project name → preserve.
- Test default-template lifecycle deliberately: select custom default → new project inherits it → Add Character inherits it → change default → existing characters unchanged → delete default → built-in fallback.
- Compare balanced image prompts across character descriptions with elaborate outfits and behavioural prose; explicit Additional visual direction must remain authoritative.
- Forge/Automatic1111 and OpenAI-compatible image batch testing.
- Template format-2 → format-3 migration and custom generation-component testing.
- Guided Builder, relationship, group/card workflow, import/export, large-library, series, attachments, vision, and `.ccfproject` interoperability testing.

## Next Up

### Remaining v0.13 Generation Parity Core

True split/multi-pass Lite/Compact Lite execution and broader configurable generation contracts are the main remaining parity work after the current runtime regression cycle. Continue tightening real-provider behaviour before the larger image milestone.

### v0.14 — Image Workflow Expansion

The immediate Image Studio correctness/usability repairs landed during v0.13 because they blocked normal character → portrait testing. The larger v0.14 expansion remains reserved and planned.

- Add image-to-image/reference-image generation where supported.
- Allow generated images and managed visual attachments to become generation references without embedding binary data in JSON.
- Add emotion-image generation/regeneration using the existing `emotion_images/` tree.
- Add named emotions/expressions and per-emotion editable prompts.
- Add reusable visual-style/prompt presets.
- Add richer gallery management including intentional deletion with portrait/reference safety checks.
- Add provider-specific quality/aspect controls where useful.
- Add optional Stable Diffusion advanced helpers such as LoRA/embedding-oriented prompt tools without making one WebUI ecosystem part of the central character schema.
- Consider an optional text-model visual-prompt refinement pass while retaining deterministic/local visual tag synthesis as a no-extra-provider path.

### Post-core Authoring Workflow and Interface Pass — version TBD

Do this after the major generation, Q&A, image, import/export, and project workflows are sufficiently stable that UI changes are unlikely to be immediately invalidated by another architecture change.

- Restore a full **Guided Manual** authoring mode inspired by V1, implemented on the same template, generation-component, output-binding, and project data model used everywhere else.
- Expand the existing Builder foundation into richer Character, Personality, and Scene Builder workflows with presets, manual guidance, optional AI assistance, review-first application, and concept/Q&A integration.
- Perform a systematic V1 parity and authoring-UX audit classifying features as missing, relocated, evolved/replaced, partial, or intentionally retired before the final interface redesign.
- Hide implementation-facing identifiers such as internal field/component IDs behind automatic defaults and Advanced controls wherever users do not need them directly.
- Revisit Workspace information architecture once the final set of major workflows is known: clearer tabs/pages/sections, less top-level button clutter, task-oriented grouping.
- Perform the larger visual-polish pass after workflow hierarchy stabilises: spacing, typography, theme/identity, responsive layouts, ultrawide use, controls, keyboard workflows, onboarding, and empty/error/progress states.

## Planned Features

### Generation Improvements

- Streaming text where providers support it.
- Generation components/output bindings and editable per-template semantic contracts. **Core implemented in v0.13; expand special contracts over time.**
- V1-style private Q&A completeness and targeted missing-answer retries. **Core implemented in v0.13.1.**
- Builder guidance precedence. **Core implemented in v0.13.2.**
- Mode & Style and First Message length/style guidance. **Foundation implemented in v0.13.3.**
- Conservative concept-fidelity validation/retry. **Core implemented in v0.13.4.**
- Semantic completeness validation and targeted repair. **Core implemented in v0.13.**
- Multi-stage generation progress and review diagnostics. **Core implemented in v0.13.7.**
- Alternative First Messages with configurable count/style/instructions and interoperable export where supported. **Core implemented in v0.13.8.**
- Multiple generation groups bound to one final field must compose rather than overwrite. **Core implemented in v0.13.9.**
- V1-style Full/Lite/Compact-Lite or equivalent true multi-pass strategies after the core contract is stable.
- Section-by-section generation/continuation with per-stage progress where it remains useful after the multi-pass design is finalised.
- Configurable special formatting rules such as `<START>` counts, greeting counts, and constrained tag sets.
- Recent/favourite model lists, broader provider capability detection, token-limit metadata/context estimation, and reusable provider presets.

### Template and Authoring Defaults

- Global default template stored by stable template ID. **Implemented in v0.13.10.**
- New project first characters and newly added characters inherit the current global default. **Implemented in v0.13.10.**
- Existing characters retain their explicit assigned template when the global default changes. **Implemented in v0.13.10.**
- Missing/deleted custom defaults fall back safely to built-in Default. **Implemented in v0.13.10.**
- Continue keeping template IDs/internal bindings out of ordinary user-facing workflow where a name/selector is sufficient.

### Authoring Workflows

- **Guided Manual mode:** template-driven manual construction through active sections/components without requiring AI generation, using the same underlying card/project model.
- Guided Manual should understand enabled/disabled template structure, required content, output bindings, section progress/completeness, and final interoperable Character Card projection.
- Allow optional AI assistance inside Guided Manual while keeping manual authoring fully usable without a provider.
- **Builder expansion:** grow Guided Character Builder toward richer V1 Character, Personality, and Scene Builder experiences where that separation remains useful.
- Builders should accept manual input and AI fill/extraction, preserve explicit user guidance, feed structured planning context into final generation, and participate in established precedence rules.
- Add/revisit builder presets, reusable builder templates, clearer completion/progress state, richer selective revision, and smooth Concept → Q&A → Builders → generation handoff.
- Keep Builder data as planning/source context unless explicitly mapped into card output.

### Multi-Character Workflows

- Relationship matrix generation/editing and relationship-aware context. **Foundation completed.**
- Multi-character single-card planning, split-card batch planning, and group-card planning. **Foundations completed; final generation/export execution remains planned.**
- Add a visual **Relationship Map** editor using draggable character cards, directional/named connections, selectable anchor points, and editor-only layout metadata while relationship content remains independent of canvas geometry.
- Support richer shared lore/deeper continuity and additional relationship visualisation/flowchart views.

### Character Library 2.0

- Thumbnail grid/list, sorting/filtering, tags/tag merging, folders, collections, series filters, favourites, and incremental index. **Foundations completed.**
- Card groups/variations, flowchart/relationship views, and richer image/portrait filtering.

### Series System

- Series definitions/bibles, Manager, generation guidance, deterministic Auto Series, categories, import/export, and portable packs. **Foundations completed.**
- Provider-assisted semantic matching, series artwork, richer hierarchy, and collection-level defaults.

### Vision and Attachments

- Images as concept references and review-first analysis. **Foundation completed.**
- Default concept-mode analysis remains observational: physical Character Description only, scene context outside Description, no automatic Personality inference. **Implemented in v0.13.5 hotfix.**
- GIF frame selection, image URL references, native PDF text extraction, preprocessing/context refinement, and visual-reference handoff to v0.14 image workflows.

### Image Generation

- OpenAI-compatible generation, prompt builders, gallery, portrait assignment. **Foundation completed.**
- Forge/Automatic1111, provider settings, checkpoint/sampler discovery, batches, seeds, regeneration, and SD defaults. **v0.12 source milestone implemented.**
- Visual-only prompt synthesis, Scenario-derived setting cues, no raw Concept fallback, provider-aware Auto style, wrapping prompt editors, and balanced core-identity prompting. **v0.13 runtime repairs implemented.**
- Image-to-image/reference generation, emotion workflows, per-emotion prompts, visual presets, richer provider controls, and LoRA/embedding helpers. **v0.14/later.**

### Import / Export

- Character Card V2 JSON/PNG/APNG, SillyTavern-oriented mappings, lorebook preservation, `.ccfproject`, and split-workflow JSON export. **Foundation completed.**
- Broader ecosystem testing, PNG batch export, automatic split-workflow generation, additional meaningful formats, and generated/emotion image export options.

### Character Concept Exchange — later milestone

This remains intentionally after generation/template/Q&A architecture stabilises enough for the concept format to stay durable.

- Add a Character Card Forge-specific, versioned, human-readable concept document for **pre-generation source material**, distinct from a completed Character Card or full `.ccfproject`.
- Working format idea: JSON content with a dedicated extension such as `.ccfconcept`; exact extension/schema should not be frozen until the model is mature.
- Make it easy for external AI assistants to produce using a published schema/example.
- Keep it higher-level and more stable than internal project/template schemas: describe what the character should become rather than mirror every workspace/component ID.
- Require a main concept with optional identity, physical/visual direction, personality direction, background, relationships, setting, scenario/opening ideas, constraints, and freeform notes.
- Include optional template-Q&A answers associated with a recognised Q&A template once that format is stable.
- Include optional extra Q&A as arbitrary character-specific question/answer pairs preserving the useful V1 one-off-question workflow.
- During import, map compatible Q&A to the active plan, retain unmatched answers as supplemental Q&A, and leave unanswered required current-template questions to normal completeness handling.
- Treat imported/extra Q&A as private planning context, not automatic Character Card output.
- Allow omitted/unknown sections so rough concepts remain valid.
- Import through a review/mapping step into a new character/concept workspace instead of treating the file as a finished card.
- Feed concept material into normal templates, generation components, Q&A, Builders, Mode & Style, fidelity checks, semantic repair, and Generation Preview.
- Consider concept export for sharing, archiving, external AI refinement, and re-import.
- Version the concept format independently and provide migrations/defaults once active use begins.

### Front Porch Integration

- Data folder discovery/configuration, character scanning, import, install/export, character management, and chat reading/export where practical.

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
- Maintain documentation for workspace fields vs generation components vs output bindings.
- Document persistent planning settings such as Mode & Style and authoring defaults separately from exported card fields.
- When Character Concept Exchange is implemented, keep its schema/version independent from internal project/template formats so concept files remain portable across versions where practical.

## Technical Improvements

- Add automated schema/behaviour tests beyond marker validation.
- Add recovery from interrupted writes using temporary-file replacement.
- Add optional autosave with safe snapshots.
- Add async thumbnail generation.
- Generalise cancellable task handling beyond AI jobs to scanning/imports.
- Add structured application logging and diagnostics viewer.
- Add secure credential-storage options where platform support permits.
- Add additional API authentication modes where local servers require them.
- Split very large UI scripts into reusable components as workflows expand.
- Consider formal provider-adapter classes as provider diversity grows.
- Keep generation validators/repair logic in reusable services rather than embedding V1 assumptions in workspace UI code.
- Keep image-prompt synthesis separate from Character Card Description so prose-card semantics and provider-specific visual prompt formats do not collapse into one field again.
- Add release-aware update checking against **published GitHub Releases/package assets only**, never repository source state.
- Update installation must remain explicitly user-approved, support intentionally staying on older versions, and eventually use safe download/verification/restart-helper/rollback mechanics rather than silently overwriting the running application.
- Development/source testing remains a Godot + repository workflow; packaged applications do not need a repository-development update channel.
- Packaged releases may skip development version numbers; each published package should be independently installable and migrations should support direct upgrade from supported older persisted formats without requiring every intermediate development build.

## Polish

Major interface polish is intentionally sequenced after the main systems and authoring workflows are in place, while small usability fixes that prevent data loss or block testing should continue immediately.

- Rework Workspace navigation/hierarchy around final workflows rather than accumulating unrelated top-level buttons.
- Use tabs/pages/sections where they make task boundaries clearer while retaining detachable windows where multi-monitor use benefits.
- Create a stronger theme/visual identity with consistent spacing, typography, hierarchy, selected states, controls, dialogs, and status/progress presentation.
- Refine responsive behaviour for normal desktop, ultrawide, high-DPI, and smaller supported windows.
- Add keyboard shortcuts and keyboard-first editing/navigation where practical.
- Add drag-and-drop where it improves file/image workflows.
- Improve onboarding, empty states, inline explanations, validation feedback, error recovery, and progress reporting.
- Standardise unsaved-change protection and safe close/navigation across editors and tool windows.
- Add native completion notifications where useful and denser gallery/library browsing for large collections.

## Long-Term Ideas

- Optional LAN/mobile companion service as a separate service rather than an embedded web frontend.
- Plugin/provider extension API.
- Community template sharing.
- Batch character generation pipelines.
- Local semantic search over large character libraries.
- Provider-agnostic image recipe presets shareable where settings overlap safely.

## Deferred / Experimental Ideas

- Legacy database import remains intentionally deferred and is not a compatibility goal.
- Reproducing the old PyWebView interface is explicitly not planned.
- A mobile browser interface only returns if a strong workflow need appears and it can remain cleanly separated from the desktop core.
- Highly backend-specific Stable Diffusion controls remain optional adapter-owned features rather than mandatory project fields.
- Exact recreation of V1 prompt strings is not a goal; source-audited behaviour should be expressed as maintainable Godot-native data and services.
