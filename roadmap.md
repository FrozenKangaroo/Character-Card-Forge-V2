# Character Card Forge — Project Roadmap

## Project Vision

Rebuild Character Card Forge as a responsive, native Godot desktop application for creating, generating, editing, organising, importing, exporting, analysing, and illustrating AI roleplay character cards.

The original PyWebView V1 application remains a feature and behaviour reference, not an architecture or interface specification. Useful V1 behaviour should be re-expressed as maintainable Godot-native systems rather than copied literally.

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
- Workspace/editing structure, authoring/planning structure, AI-generation structure, lore/context structure, and interoperable Character Card output fields are related but distinct layers.
- Stable IDs are internal references; user-facing names may change without silently breaking bindings or preferences.
- Missing core authoring/data behaviour should be restored before the larger visual redesign, but usability regressions such as toolbar overcrowding should be fixed as soon as they become obvious.
- Existing folders, collections, series, templates, and other named objects should be selected from visible UI choices rather than requiring users to retype names they already created.
- Derived characters must remain independent records: source context may seed generation, but creating a related character or variation must never overwrite the source character.

## Current Development Phase

**v0.14.10 development candidate — Authoring Parity, Character Derivation, Lorebooks, and Library UX**

The v0.13 line established the modern generation, validation, Q&A, provider, vision, project-lifecycle, and AI-authored image-prompt foundations. v0.14 restores V1 authoring workflows, fills missing first-class Character Card data such as lorebooks, adds related-character/variation authoring, and includes targeted usability passes where feature growth has made navigation or management unclear.

The running development build displays **v0.14.10**. Published/tagged release metadata remains controlled by the release workflow until an actual release promotion is performed.

The current authoring model deliberately keeps three distinct routes:

- **Character Builder** — option-driven character construction for users who want structured choices without writing everything manually.
- **Manual Guided** — direct template-aware authoring for users who already know what they want; it does not require AI and skips private Interview / Q&A.
- **Idea Generator** — controlled ingredient/pool composition that creates an editable concept seed before normal generation.

V1-style **Make AI Variation** behaviour is now evolving into a broader **Create Related Character / AI Variation** workflow: the active character can ground a new standalone related character or transformed version, the user controls what source context is included, derivation provenance is retained internally, and normal Generation Preview remains the review boundary before generated values are accepted.

Workspace navigation keeps Save, Generate Character, and Library immediately visible while secondary workflows are grouped under **Author**, **Project**, **Character**, and **Tools** menus instead of each new feature adding another equally prominent button.

Library navigation follows the same hierarchy principle: common filtering and assignment stay visible, secondary actions move into menus, and existing folders/collections are assigned through pickers rather than remembered free-text names.

Lorebook data is a first-class editing concern:

- **Project Lorebook** contains shared world, location, organisation, rule, history, and recurring-NPC context for the whole multi-character project.
- **Character Lorebook** edits the active character's interoperable `character_book` data so Character Card imports/exports can preserve lore instead of treating it as an opaque blob.
- Lorebook entries remain separate from Description, Personality, Scenario, and other direct card prose even when generation can later use selected lore as context.

## Completed

### v0.14.10 — Related Character / AI Variation Foundation

- Added **Character → Create Related Character / AI Variation…** as the V2 evolution of V1's Make AI Variation workflow.
- Supports two derivation modes: create a distinct related character from established source facts, or create a transformed variation of the same identity such as an older/younger, future/past, alternate-universe, or changed-life-path version.
- The user supplies an authoritative derivation instruction and may optionally name the new character before generation.
- Source Character Card text, shared project context, and source-character relationships can be included independently as grounding context.
- Variations preserve established identity anchors unless the derivation request explicitly transforms them; related-character mode explicitly avoids cloning the source character.
- Creates a new independent character record first, seeds its Generation Concept from the derivation context, carries the source template assignment, and can immediately launch the normal Generate Character / Generation Preview workflow.
- Stores non-exported derivation provenance under character workspace metadata: source project ID, source character ID/name, derivation type, prompt, and timestamp.
- The source character is never overwritten.
- Added regression coverage for context inclusion/exclusion, related/variation guidance, provenance markers, menu wiring, normal-generation routing, and v0.14.10 shell wiring.

### v0.14.9 — Library Assignment and Action UX

- Reworked the Library action panel so the active project or bulk selection is named explicitly instead of relying on the ambiguous “actions use active project” message.
- Replaced free-text assignment of existing folders and collections with populated **Choose folder…** and **Choose collection…** pickers built from current Library facet values.
- Preserved creation workflows with explicit **New Folder…** and **New Collection…** dialogs that create names by assigning the current project selection.
- Grouped lower-frequency Favourite, Series, Folder, and Collection operations into contextual menus to reduce the always-visible button wall.
- Kept **All Character Projects** as the explicit filter reset and **Unfiled** as a genuine folder filter.
- Added regression coverage for picker-based assignment, menu grouping, selection context, and v0.14.9 application wiring.

### v0.14.8 — Manual Guided Alternative Greetings

- Added a dedicated repeatable Alternative Greetings editor to Manual Guided First Message(s).
- Each greeting is independently editable, removable, and reorderable.
- Existing `character.alternate_greetings` values repopulate as separate entries and round-trip through the interoperable Character Card array.
- Blank alternatives are omitted on Apply; State Tracking remains intentionally deferred.

### v0.14.7 — Manual Guided Component Parity + State Isolation

- Manual Guided now reads enabled Generation Components from the active template as the source of truth for structured Description and Personality fields.
- Adding, removing, disabling, renaming, reordering, or changing component instructions is reflected automatically when Manual Guided opens.
- Structured values compose into normal Character Card output fields using the same group structure rather than a second hard-coded schema.
- Generation Concept and private Interview/Q&A planning fields are excluded from Manual Guided.
- Fixed previous-character/project Manual Guided state leaking into newly opened characters.

### v0.14.6 — Generation Preview Selection Safety

- Unchecked Generation Preview rows perform no write at all, preserving existing fields during both normal generation and Vision Analysis.
- Preview Apply captures live workspace values first so manual edits made while generation was running remain authoritative.
- Added regression coverage for preserving unchecked Generation Concept/Personality while applying selected proposals.

### v0.14.5 — Grouped Workspace Navigation + Lorebook Foundation

- Reorganised the crowded workspace controls into **Author**, **Project**, **Character**, and **Tools** menus while keeping Save, Generate Character, Library, project identity, character selection, template selection, and status/progress immediately visible.
- Existing actions are routed through their current handlers rather than reimplemented, reducing UI duplication risk.
- Added a detachable **Lorebook Manager** supporting both Project Lorebook and active-character Lorebook scopes.
- Character lore maps to `character.character_book` rather than creating a second incompatible lore format.
- Project lore is stored as first-class project data and remains available to every character in that project.
- Lore entries include stable IDs, names, primary keys, secondary keys, content, comments, enabled state, constant/selective/case-sensitive flags, priority, insertion order, position, and extension storage.
- Added add, duplicate, delete, scope-switch, edit, and apply workflows.
- Added regression coverage for grouped navigation, lorebook field support, and v0.14.5 application wiring.

### v0.14.4 — Manual Guided Direct Authoring

- Restored **Manual Guided** as a no-AI, template-driven direct-authoring workflow.
- Manual Guided skips private Interview / Q&A and writes directly into the normal character workspace.
- Added seven V1-inspired pages: Description, Personality, Scenario, First Message(s), Example Dialogues, Tags and System Prompt, and State Tracking and Image Prompts.
- Added per-section Include controls, live output preview, character-local draft persistence, Tags array conversion, and Alternative Greeting conversion foundations.
- Recorded the V1 authoring audit and expanded the future Idea Generator/Builder parity scope.

### v0.14.3 — Recoverable Generation Review

- A parseable generated character is no longer discarded merely because semantic/template review still fails after the bounded repair pass.
- Generation Preview receives the preserved candidate plus exact review diagnostics.
- Users can keep, edit, selectively apply, or later repair individual fields with the normal AI Suggest workflow.
- Truly unparseable/missing-contract/provider failures still fail normally.

### v0.14.2 — Character Transfer + Multiline Input Convention

- Added **Move / Copy…** for character transfer into existing or new projects.
- Copy creates an independent character identity; Move preserves identity where practical.
- Character-local card data, Generation Concept, Builder state, Interview review/provenance, assigned template, generation history/settings, portrait/generated/emotion-image records, managed files, and character attachments travel with the character.
- Shared project context/attachments/relationships remain project-level.
- Move is destination-first so a failed destination save does not damage the source.
- Moving a project's only character leaves a fresh empty character in the source project.
- Added the shared `Shift+Enter` newline convention for multiline editors.

### v0.14.1 — Desktop-Native Layout + Interview Review

- Switched away from game-style canvas scaling so maximising/resizing exposes more real workspace instead of enlarging controls.
- Private Interview / Q&A responses persist with Manual versus AI provenance.
- Latest interview responses remain inspectable after generation and save/reopen.

### v0.14.0 + hotfixes — Authoring Options and Runtime Stability

- Added `data/authoring_option_pools.json`, a versioned shared suggestion catalog for existing Builder paths.
- Builder option suggestions remain editable planning values rather than restrictive enums.
- Private Interview / Q&A planning preserves the resolved Text-role output budget instead of using the old 2,600-token ceiling.
- Embedded Image Studio genuine vertical overflow is scrollable instead of clipped.

### v0.13.x — Generation Parity and Provider/Workflow Stabilisation

- Added semantic completeness validation after JSON parsing and one bounded repair pass.
- Added generation contracts, template format-3 generation groups/components, component order/enabled/required state, prompt instructions, bindings, and composition into shared output fields.
- Restored V1-inspired Description/Personality generation expectations while keeping Description physical/external.
- Added private Interview / Q&A planning with bundled defaults, template overrides, manual answers, required-answer checking, and bounded retries.
- Defined planning precedence: source concept → manual Interview/Q&A → Builder guidance → AI interview answers → existing values/generic inference.
- Added Mode & Style controls for Full/Lite/Compact Lite intent, writing style, First Message style/length, and custom greeting guidance.
- Added conservative concept-fidelity checks/correction, Generation Preview diagnostics, configurable Alternative First Messages, selective application, and null filtering.
- Added review-first Vision Analysis, Creative Concept, separate Text/Vision model selection and budgets, model capability discovery, malformed-response handling, default-template selection, project drafts, V2 PNG export, Image Studio isolation, AI-authored image prompts, and NanoGPT detailed discovery.

### v0.12 source milestone — Image Expansion + Generation Parity Phase 1

- Separated Character AI profiles from dedicated Image Generation providers.
- Added separate Character AI and Image Generation Settings.
- Added Forge/Automatic1111 generation alongside OpenAI-compatible Images APIs.
- Added checkpoint/sampler/model discovery, batch generation, sampler/steps/CFG/seed controls, returned-seed capture, Regenerate, and New Seed Variant workflows.
- Source-audited V1 generation behaviour and restored Generation Concept authority plus stronger core field guidance.

### v0.11.0 — Image Generation Foundation

- Added independent image-generation role, OpenAI-compatible image generation, response decoding, PNG normalisation, generated-image storage, prompt construction, gallery/preview, portrait assignment, and metadata.

### v0.10.0 — Vision and Attachments Foundation

- Added independent Text/Vision provider assignments, project/per-character attachments, preprocessing/context budgeting, generation context, review-first image analysis, and portable attachment storage.

### v0.9.x — Series and Release Infrastructure

- Added versioned series bibles, Series Manager, categories/aliases/canon/visual/generation guidance, deterministic Auto Series, import/export, portable packs, export presets, validation/releases, semantic-version tooling, and release/update helper infrastructure.

### v0.8.x — Character Library 2.0

- Added thumbnail/list views, portrait thumbnails, incremental indexing, broad search, sorting, favourites, folders, collections, tags, filters, bulk tools, and dashboard statistics reuse.

### v0.7.x — Import / Export Foundation

- Added Character Card V1/V2 import, V2 export, PNG/APNG metadata support, compatibility reports, lorebook/character-book preservation, CCF extension round trips, portable `.ccfproject`, and split-workflow JSON export.

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

Current v0.14 capabilities include option-driven Builder suggestions, component-driven no-AI Manual Guided authoring, repeatable Alternative Greetings, character transfer, related-character/variation derivation, interview review/provenance, recoverable validation failures, safe selective Preview application, native desktop resizing, grouped workspace navigation, lorebooks, and clearer Library organisation workflows.

**Next authoring slices:**

- Expand and tune the built-in authoring option catalog from real V1/runtime usage without turning suggestions into rigid enums.
- Add template/user authoring-option overrides so custom templates can provide their own candidate pools.
- Restore the mature V1 **Idea Generator** as a controlled ingredient composer rather than a generic “ask AI for ideas” popup.
- Support the V1 ingredient families: Gender, Archetype, Core Conflict, Setting, Tone, Occupation/Role, Relationship to `{{user}}`, Status/Social Position, Personality, Subject Of, Engages In, and Engages In (Sexual).
- Support per-field editable option pools, custom values, enable/disable state, reset-to-default, and reusable presets.
- Support single-select and configurable multi-select fields with chips; V1 defaults were Personality, Subject Of, Engages In, and Engages In (Sexual).
- Support locks, single-field local reroll, **Reroll Unlocked**, and configurable random choice count without spending AI tokens.
- Keep conditional pool capability such as gender-aware relationship/archetype suggestions, implemented data-first rather than hard-coded into UI handlers.
- Let the final selected/randomised combination remain editable before **Generate Concept**, then use AI only for the compact editable Main Concept seed.
- Define useful provenance for manual values, presets, Idea Generator choices, concept extraction, Builder AI, private Interview AI, and character derivation.
- Continue V1 Character Builder / Personality Builder / Scene Builder parity where those structured controls remain useful in V2.
- Expand character derivation after runtime testing with optional direct relationship creation/remapping, richer source-context selection, and possible batch/branch workflows without making derived characters dependent on their source at runtime.
- Extend character transfer to future batch Move/Copy Selected workflows with relationship preservation/remapping when related characters move together.
- Continue the formal V1 authoring UX audit: missing / equivalent-relocated / replaced-evolved / partial / intentionally retired / V2-only.

### Lorebook and Context Work

v0.14.5 establishes editable project and character lorebooks. Continue with:

- Confirm Character Card V2/V3 import/export maps standard `character_book` properties and entries without data loss.
- Preserve unknown/extension lorebook fields during edit/save round trips.
- Add import/export for standalone lorebook JSON where useful.
- Add entry search/filter/sort and move/copy between project and character scopes.
- Make project and character lore available to generation through explicit context selection/budgeting rather than blindly injecting every entry.
- Implement trigger evaluation for previews/testing: primary/secondary keys, constant entries, case sensitivity, selective logic, priority/order, recursion/scan depth where supported.
- Add optional AI Suggest / extract-lore helpers after the direct manual workflow is stable.
- Expose lorebook/support entries appropriately from Manual Guided without flattening them into ordinary prose fields.
- Consider reusable shared world-lore libraries after project/character lore semantics stabilise.

### Library UX follow-up

v0.14.9 replaces existing-folder/collection name retyping with assignment pickers and groups secondary actions. Continue with:

- Consider sidebar context menus for rename/delete/edit operations instead of adding management buttons.
- Consider stable internal IDs for folders/collections if future rename semantics require identity independent of display names.
- Improve multi-selection affordances and keyboard selection where runtime testing shows ambiguity.
- Keep **All Character Projects** as the obvious reset state and **Unfiled** as a real filter, not an accidental reset shortcut.

### Remaining v0.13 Generation Parity Core carried forward

- Expand special generation contracts beyond component/minimum-length/marker foundations, including greeting counts and constrained sets where useful.
- Complete V1-equivalent split/multi-pass execution for Lite/Compact Lite rather than only density guidance.
- Continue real-provider regression testing across Q&A retries, Builder precedence, Mode & Style, component toggling/composition, semantic repair, concept fidelity, malformed JSON, alternate provider envelopes, Creative Concept, capability discovery, AI image prompts, and default templates.
- Expand concept-fidelity marker types only where runtime evidence shows they remain high-confidence.

### Ongoing validation

- Real-world testing across multiple OpenAI-compatible text and vision backends.
- Compare new output against pre-parity V2 output, especially Description/Personality separation and concept fidelity.
- Test concept/manual-Q&A/Builder/AI-answer precedence conflicts and semantic repair.
- Test long Generation Concepts and large custom Interview/Q&A sets with reasoning models.
- Confirm persisted Interview/Q&A reviews match the responses actually used by generation.
- Confirm native resizing exposes additional workspace and genuine overflow remains reachable locally.
- Confirm character Move/Copy preserves exact character-local state/files while excluding project-shared context/relationships.
- Confirm related-character mode produces a distinct standalone character while preserving established source facts, and variation mode preserves source identity anchors unless explicitly transformed.
- Confirm derivation context toggles exclude disabled source-card/shared-context/relationship data and the original character is never modified.
- Confirm grouped navigation keeps all previous workflows reachable without duplicate primary buttons.
- Confirm project lore persists across save/reopen and character lore survives Character Card import/export.
- Confirm Manual Guided follows Generation Component changes and isolates drafts between characters/projects.
- Confirm Alternative Greetings retain order and round-trip through Manual Guided and Character Card export.
- Confirm Library folder/collection pickers refresh after creating or assigning organisation values.
- Confirm `Shift+Enter` remains reliable across existing and new multiline editors.
- Confirm multiple enabled generation groups bound to one output field compose in template order.
- Confirm malformed provider JSON enters repair without noisy engine parser failures.
- Test Creative Concept with sparse and detailed images.
- Test model capability discovery across rich, partial, and ID-only providers.
- Test Text and Vision models with different context/output limits.
- Test default-template lifecycle, project draft lifecycle, Builder options, Manual Guided, Idea Generator, character derivation, Lorebooks, relationships, group/card workflows, import/export, large-library, series, attachments, vision, and `.ccfproject` interoperability.

## Next Up

### Continue v0.14 Authoring + Lorebook Parity

1. Runtime-test v0.14.10 Related Character / AI Variation and v0.14.9 Library assignment/action UX.
2. Harden Character Card lorebook interoperability/unknown-field preservation.
3. Rebuild Idea Generator around the mature V1 controlled-pool workflow.
4. Continue deeper Builder option coverage and template/user pool overrides.
5. Finish the formal V1 authoring parity audit.

### v0.15 — Image Workflow Expansion

The image milestone remains after primary authoring/data parity:

- Add image-to-image/reference-image generation where providers support it.
- Allow generated images and managed visual attachments to become generation references without embedding binary data in JSON.
- Add emotion-image generation/regeneration using the existing `emotion_images/` tree.
- Add named emotions/expressions and per-emotion editable prompts.
- Add reusable visual-style/prompt presets.
- Add richer gallery management including intentional deletion with portrait/reference safety checks.
- Add provider-specific quality/aspect controls where useful.
- Add optional Stable Diffusion advanced helpers such as LoRA/embedding prompt tools without making one WebUI ecosystem part of the central schema.
- Expand AI-authored prompt refinement/regeneration while retaining the deterministic/local visual-anchor fallback.

## Level and Content Tools

Character Card Forge is not a level-based game, so the project-wide JSON level-package requirements do not apply directly. Its analogous content systems are versioned templates, projects, series data, authoring option pools, lorebooks, attachments, and portable `.ccfproject` packages. These should remain externally inspectable, versioned, portable, and editor-driven.

## Technical Improvements

- Simplify the release workflow around the canonical development checkout and retire unnecessary two-copy staging when safe.
- Generate/commit canonical Godot `.gd.uid` sidecars consistently instead of repeatedly treating them as disposable local noise.
- Synchronise project/release version metadata so development label, VERSION, tags, project settings, and release assets cannot silently drift.
- Continue replacing version-layer compatibility bridges with clean named APIs when surrounding workflows stabilise.
- Audit remaining pages/tool windows for fixed-size/game-style assumptions that fight desktop resizing.
- Continue navigation hierarchy work as new features arrive; do not return to a one-button-per-feature toolbar.
- Add reusable data-model/service helpers for lorebook normalisation and interoperability rather than leaving format knowledge only in UI code.
- Audit Library organisation data for stable-ID needs before implementing rename-heavy workflows.
- Keep derivation provenance as internal workspace metadata unless/until a portable interoperable extension format is deliberately defined.

## Polish

- Full workspace visual hierarchy/theme pass after authoring, lorebook, image, import/export, and project workflows stabilise.
- Improve keyboard navigation, focus order, tooltips, empty states, confirmation language, and accessibility.
- Reduce unnecessary modal depth and duplicated controls.
- Preserve multi-monitor friendly detachable tools where they genuinely improve workflows.

## Long-Term Ideas

- Visual relationship-map canvas with draggable character cards, directional/mutual connections, labels, notes, grouping, zoom/pan, and future world-entity support.
- Character Concept Exchange format after authoring/planning schemas stabilise.
- Shared/community authoring-option and lorebook libraries.
- GitHub-Releases-only packaged updater with explicit user-controlled download/install, release channels, hashes, and safe restart/install.
- Richer reusable authoring libraries and community-shareable presets after the local data model proves stable.

## Deferred / Experimental Ideas

- The V1 Front Porch-specific Manual Guided group-card implementation remains a behavioural reference but will not be copied directly. Future V2 manual multi-character authoring should build on the existing project, relationship, shared-context, Group Scene, and Card Workflow architecture.
- Large visual/navigation redesign concepts remain deferred until workflow architecture is stable; targeted usability fixes remain immediate.