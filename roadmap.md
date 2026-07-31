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
- Wider desktop windows expose additional workspace instead of scaling the interface larger or letterboxing a fixed canvas.
- Detachable native tool windows are used where multi-monitor workflows benefit; primary navigation pages may remain embedded when clearer.
- Generation parity ports useful V1 behaviour into the Godot architecture rather than recreating PyWebView-specific implementation details.
- Workspace/editing structure, authoring/planning structure, AI-generation structure, and interoperable Character Card output fields are related but distinct layers.
- Stable IDs are internal references; user-facing names may change without silently breaking bindings or preferences.
- Major visual redesign should follow stable workflow architecture where practical, while missing core authoring behaviour should be restored before expanding secondary workflows.

## Current Development Phase

**v0.14.1 development candidate — V1 Authoring Workflow Parity + Desktop UX Stabilisation**

The v0.13 line established the modern generation, validation, Q&A, provider, vision, project-lifecycle, and AI-authored image-prompt foundations. Runtime use then highlighted an important parity problem: V2's underlying generation architecture is stronger than V1, but its everyday character-authoring workflow became too dependent on typing values manually.

The running development build displays **v0.14.1**. Published/tagged release metadata remains controlled by the release workflow until an actual release promotion is performed.

v0.14 therefore restores the distinct V1 authoring workflows before the larger image expansion:

- **Character Builder** is option-driven character construction: users should be able to try useful combinations quickly while retaining fully editable custom values.
- **Manual Guided** is the direct structured authoring route for users who already know what they want and prefer to type it themselves.
- **Idea Generator** is a controlled combination workflow whose candidate pools can be customised per field rather than merely asking AI for an unconstrained concept.
- All three workflows should feed the same accepted planning/project model rather than creating incompatible parallel character formats.
- Authoring choices are suggestions and planning inputs, not restrictive Character Card enums.
- Builder controls, Manual Guided fields, Idea Generator pools, generation components, and final Character Card fields remain distinct concepts even when they map to related data.

The first v0.14.0 slice adds a versioned shared authoring-option catalog and restores option suggestions to the existing Character Builder without changing `workspace.builder` storage. Existing Builder precedence therefore remains intact: accepted Builder values continue to participate in concept/Q&A/full-generation planning exactly as before.

v0.14.0-hotfix1 removed the historical fixed **2,600-token private Interview ceiling**. Interview planning and missing-answer retries preserve the Text role's already-resolved output budget instead of silently replacing a large model/profile limit with a tiny stage-specific maximum.

v0.14.0-hotfix2 made the embedded Image Studio vertically scrollable so genuine content overflow can never push lower prompt/gallery controls beyond reach.

v0.14.1 moves the application away from game-style canvas stretching to desktop-native 1:1 interface sizing: increasing the window size exposes more usable workspace instead of enlarging every control. It also persists and renders the latest private Interview / Q&A responses with **Manual answer** versus **AI Interview** provenance, so planning details that affected generation remain inspectable after the run.

## Completed

### v0.14.1 — Desktop-Native Layout + Interview Review

- Switched the desktop app away from `canvas_items` stretch scaling so resizing/maximising the main window exposes additional workspace instead of scaling the whole UI larger.
- Kept responsive Control/container layouts and explicit scroll containers responsible for adapting to available space.
- Private Interview / Q&A planning now carries answered question text and provenance into final generation metadata.
- The latest completed interview review is stored in character-local `generation.interview_review` state and survives normal project save/reopen workflows.
- Interview / Q&A sections display a **Latest generation interview responses** panel containing the actual planning answers used by generation.
- Manual versus AI provenance remains explicit; displaying an AI response does not silently promote it to a higher-priority manual answer.
- Added regression coverage for desktop stretch mode, answer persistence, provenance, and Interview / Q&A rendering.

### v0.14.0-hotfix2 — Image Studio Embedded Layout

- Mounted the embedded Image Studio inside an expanding vertical scroll viewport.
- Genuine vertical overflow is now reachable without narrowing the main application window.
- Horizontal scrolling remains disabled so Image Studio continues using its responsive flow/split layout.
- Added a headless layout regression for the embedded studio scroll contract.

### v0.14.0-hotfix1 — Private Interview Output Budget

- Removed the hidden 2,600-token completion ceiling from private Interview / Q&A planning.
- Interview planning now inherits the already-resolved Text-role `max_tokens` budget, preserving Auto-detected/manual model limits and the existing request-level context budgeting performed before the character job is queued.
- Missing-required-answer retries use the same resolved output budget rather than falling back to the legacy cap.
- Deliberately smaller user/model budgets remain respected; the hotfix removes an artificial ceiling rather than forcing a larger minimum.
- Added regression coverage using a large 384,000-token resolved output budget and a larger custom question set so the fixed cap cannot return unnoticed.

### v0.13.x — Generation Parity and Provider/Workflow Stabilisation

- Added semantic completeness validation after ordinary JSON parsing and one targeted repair pass for valid-but-incomplete full-character results.
- Added fail-closed generation-contract protection and regression coverage for contract/dispatch regressions.
- Added template format 3 generation groups/components with editable order, enabled/required state, AI instructions, output bindings, and allow-extra-components policy.
- Multiple enabled generation groups targeting one Character Card field now compose in template order instead of overwriting one another.
- Restored structured V1-inspired Description and Personality expectations while keeping Description physical/external.
- Added private Interview / Q&A planning with bundled defaults, template overrides, manual answers, required-answer checking, and bounded retries.
- Defined planning precedence: source concept → manual Interview/Q&A → Builder guidance → AI interview answers → existing card values/generic inference.
- Added Mode & Style controls for Full/Lite/Compact Lite intent, writing style, First Message style/length, and custom greeting guidance.
- Added conservative concept-fidelity checks and one bounded correction pass for high-confidence supplied markers.
- Added multi-stage generation progress and Generation Preview diagnostics without exposing private scratchpad content.
- Added configurable Alternative First Messages with Character Card V2 alternate-greeting export.
- Generation Preview Apply Selected now saves accepted output and filters null proposals.
- Default Vision Analysis is restricted to observable physical/visual Description.
- Added two-stage Creative Concept: Vision extracts a visual seed and the Text role develops it into a generation-ready premise.
- Added separate Text and Vision model selection plus independent context/output configuration and Vision temperature.
- Added best-effort model capability discovery, including NanoGPT `detailed=true` metadata for context/output limits when published.
- Removed the old 131,072 output-token UI ceiling.
- Hardened alternate OpenAI-compatible assistant-response envelopes and reasoning/length diagnostics.
- Added recoverable malformed-provider-JSON handling without misleading engine parser noise.
- Added global Default Character Template selection while preserving existing per-character assignments.
- Added in-memory project drafts, empty-character pruning, first-character project naming, and placeholder-name save protection.
- Added V2 PNG export using the active portrait automatically when available.
- Added Image Studio prompt-state isolation and real multiline wrapping.
- Promoted AI-authored character → image prompts through the Text role, while retaining deterministic visual-anchor prompt construction as a local fallback.
- Added NanoGPT detailed model discovery and fixed model-list recursion with sparse capability metadata.
- Fixed Image Studio startup so project/character browsing never automatically spends Text-model tokens.

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

- `release.sh` fetches/fast-forwards a clean destination `main`, reconciles already-merged synced content, stops for genuine local divergence, and supports release/tag workflows.
- `update.sh` provides a safe fast-forward-only workflow for a clean development checkout following merged `main`.
- The historical separate release-staging checkout remains technical debt now that the normal development project is itself the canonical Git clone; simplify this workflow later so normal releases do not need two project copies.

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

### v0.4.x — Guided and Controlled Building Foundation

- Added Guided Character Builder, whole-builder presets, AI fill/extraction, Safe/Custom Section Build, selected-field revision, protected context, review-first field application, JSON repair, and diagnostics.

### v0.3.x — Template System and Native Tool Windows

- Added Template Manager, versioned user templates, editable sections/fields/types/AI instructions/output policy, migration/validation, Idea Generator, and Generation Preview.

### v0.2.x — Generation Foundation

- Added queued generation, cancellation, retries, editable previews, selective application, field suggestions, Idea Generator, token estimates, API profiles, and model discovery.

### v0.1.x — Application Foundation

- Added the Godot 4.6 shell, project JSON, settings, template-driven editing, Character Library foundation, asynchronous generation, and generation history.

## In Progress

### v0.14 — V1 Authoring Workflow Parity

**Implemented in the current v0.14 line:**

- Added `data/authoring_option_pools.json`, a versioned shared catalog of suggested authoring values keyed to existing Builder paths.
- Added reusable option pools for genre, setting, role/archetype, traits, strengths, flaws, speech style, relationship style, skills, scene location, user role, initial relationship, and tone.
- Character Builder now presents **Try an option** controls beside supported fields while leaving the original editor available at all times.
- Single-choice suggestions fill the editable field; multi-value/tag suggestions append without replacing existing choices.
- Selecting a suggestion marks the Builder state exactly like manual editing, so current `workspace.builder` storage, AI fill/extraction, Apply to Character, concept composition, and generation precedence remain compatible.
- Option pools are deliberately shared data rather than hard-coded button logic so the Idea Generator can reuse them as candidate pools.
- Private Interview / Q&A planning preserves the resolved Text-role output budget instead of imposing the legacy 2,600-token stage ceiling.
- Embedded Image Studio overflow is vertically scrollable rather than clipped.
- Desktop window resizing uses native 1:1 UI sizing so larger windows expose more real workspace.
- Latest private Interview / Q&A responses are persisted and visible with Manual/AI provenance.

**Next v0.14 authoring and organisation slices:**

- Expand/adjust the built-in option catalog from real V1 usage and runtime feedback without turning suggestions into rigid enums.
- Add template/user authoring-option overrides so custom workflows can supply their own Builder choices.
- Restore **Manual Guided** as an explicitly named structured direct-entry workflow using the template/workspace data model, separate from option-driven Builder mode.
- Rework **Idea Generator** around per-field candidate pools: enable/disable choices, add custom choices, and save reusable pool presets.
- Add Idea Generator field locks, single-field reroll, and **Reroll Unlocked** while preserving accepted selections.
- Let generated combinations be edited before being sent to Generation Concept or other planning workflows.
- Define clear provenance only where useful: manual value, selected preset, Idea Generator choice, concept extraction, Builder AI, or private Interview AI.
- Add first-class **Move Character** and **Copy Character** workflows between existing Character Projects or into a new project, carrying character-local state/assets while safely handling project-level relationships/context.
- Make move operations transactional so the source character is never removed until the destination has saved successfully; preserve/remap relationships when multiple characters are eventually moved together.
- Establish a shared text-input convention: multiline editors accept `Shift+Enter` for a newline, and any future Enter-to-submit control reserves `Shift+Enter` for multiline input.
- Perform a formal V1 authoring UX audit: missing / equivalent-relocated / replaced-evolved / partial / intentionally retired, plus V2-only features.

### Remaining v0.13 Generation Parity Core carried forward

These generation-engine tasks remain important and should be completed without blocking useful authoring-parity work:

- Expand configurable special generation contracts beyond component/minimum-length/marker foundations, including greeting counts and constrained sets where useful.
- Complete V1-equivalent split/multi-pass execution for Lite/Compact Lite rather than only density guidance.
- Continue real-provider regression testing of Q&A retries, Builder precedence, Mode & Style, component toggling/composition, semantic repair, concept-fidelity correction, malformed-JSON recovery, response-envelope compatibility, Creative Concept generation, capability discovery, AI image-prompt authoring, and default-template workflows.
- Consider expanding concept-fidelity marker types only where runtime evidence shows they remain high-confidence.

### Ongoing validation

- Real-world testing across multiple OpenAI-compatible text and vision backends.
- Compare fresh characters against pre-parity V2 output, especially Description/Personality separation and concept fidelity.
- Deliberately test concept/manual-Q&A/Builder/AI-answer precedence conflicts and semantic repair after those conflicts.
- Test long Generation Concepts and larger custom Interview / Q&A sets with reasoning models; the private interview must retain the resolved Text-role output budget and reach final JSON without a CCF-imposed 2,600-token ceiling.
- Confirm persisted Interview / Q&A reviews match the responses used by generation and preserve Manual versus AI provenance after save/reopen.
- Confirm maximising and resizing the desktop app exposes additional workspace without scaling controls larger; genuine content overflow should remain reachable through local scroll containers.
- Confirm Detailed/Cinematic First Message modes remain substantially fuller while Brief remains intentionally short.
- Confirm multiple enabled generation groups bound to the same output field compose in template order and targeted repair identifies missing groups/components.
- Confirm malformed provider JSON enters normal repair without noisy engine-level parser failures.
- Confirm alternate provider envelopes produce usable assistant text and reasoning/length failures produce actionable diagnostics.
- Test Creative Concept with sparse and detailed images.
- Test model capability discovery across rich, partial, and ID-only backends; unknown limits must remain unknown rather than guessed.
- Confirm NanoGPT detailed discovery loads `context_length` / `max_output_tokens` when published.
- Test Text and Vision models with different context/output limits and independent Auto/manual behaviour.
- Test default-template lifecycle, project draft lifecycle, Builder option selection, and arbitrary custom Builder values.
- Compare AI-authored image prompts against the local fallback across simple and elaborate cards.
- Forge/Automatic1111 and OpenAI-compatible image batch testing.
- Template format-2 → format-3 migration and custom generation-component testing.
- Guided Builder, Manual Guided, Idea Generator, relationship, group/card workflow, import/export, large-library, series, attachments, vision, and `.ccfproject` interoperability testing.

## Next Up

### Continue v0.14 Authoring Workflow Parity

The immediate next target after the option-driven Builder foundation and current runtime-stability fixes is the V1-style Idea Generator pool workflow, followed by explicit Manual Guided parity, character move/copy organisation, shared keyboard-input behaviour, and the authoring UX audit. All authoring modes should continue to share accepted project/planning data rather than inventing parallel card schemas.

### v0.15 — Image Workflow Expansion

The image milestone has moved from v0.14 to v0.15 so primary character-authoring parity is restored first. The existing image plans remain accepted:

- Add image-to-image/reference-image generation where supported.
- Allow generated images and managed visual attachments to become generation references without embedding binary data in JSON.
- Add emotion-image generation/regeneration using the existing `emotion_images/` tree.
- Add named emotions/expressions and per-emotion editable prompts.
- Add reusable visual-style/prompt presets.
- Add richer gallery management including intentional deletion with portrait/reference safety checks.
- Add provider-specific quality/aspect controls where useful.
- Add optional Stable Diffusion advanced helpers such as LoRA/embedding-oriented prompt tools without making one WebUI ecosystem part of the central character schema.
- Expand the AI-authored prompt workflow with reusable refinement/regeneration controls while retaining the deterministic/local visual-anchor fallback as the no-extra-provider path.

### Post-core Workspace and Visual Interface Pass — version TBD

Do the larger navigation/theme/layout redesign after the core generation, authoring, Q&A, image, import/export, and project workflows are stable enough that visual restructuring is unlikely to be immediately invalidated. Small usability and data-loss fixes should continue as soon as they are identified.

## Technical Improvements

- Simplify the release workflow around the canonical development Git checkout and retire the unnecessary two-copy staging path when safe.
- Generate and commit canonical Godot 4.6 `.gd.uid` sidecars rather than repeatedly treating them as disposable local noise.
- Synchronise project/release version metadata so `project.godot`, the development build label, VERSION, tags, and release assets cannot drift silently.
- Continue replacing version-layer compatibility bridges with clean named APIs when the surrounding workflow is stable.
- Audit remaining primary pages/tool windows for fixed minimum sizes or game-style assumptions that fight normal desktop resizing; use flexible containers and local scrolling where content genuinely cannot fit.

## Long-Term Ideas

- Visual relationship-map canvas with draggable character cards, directional/mutual connections, labels, notes, grouping, zoom/pan, and future world-entity support.
- Character Concept Exchange format after authoring/planning schemas are stable.
- GitHub-Releases-only packaged updater with explicit user-controlled download/install, release channels, hashes, safe restart/install, and no automatic installation.
- Richer reusable authoring libraries and community-shareable presets after the local data model proves stable.
