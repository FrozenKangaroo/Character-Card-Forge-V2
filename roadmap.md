# Character Card Forge — Project Roadmap

## Project Vision

Rebuild Character Card Forge as a responsive, native Godot desktop application for creating, generating, editing, organising, importing, exporting, analysing, illustrating, and collaboratively developing AI roleplay character cards.

The original PyWebView V1 application remains a feature and behaviour reference, not an architecture specification. Useful V1 behaviour should be re-expressed as maintainable Godot-native systems with versioned external data and portable Character Card / `.ccfproject` content.

## Core Design Principles

- Godot-native desktop UI with detachable tool windows where useful.
- Character project JSON/files are the source of truth; the legacy V1 database is not.
- Versioned, externally inspectable templates, authoring schemas, lorebooks, series data, settings, project packages, and interchange formats.
- Clear separation between character data, project-shared context, AI generation, providers, images, imports/exports, library indexing, and tooling.
- OpenAI-compatible and local/self-hosted text, vision, and image providers remain first-class targets.
- Text/Vision provider roles and Image Generation providers stay independently configurable.
- New systems extend the central project model rather than create parallel character copies.
- Existing character/card data must not be destroyed by unchecked preview fields, failed reviews, disabled generation components, unrelated regeneration, partial imports, or exploratory AI conversation.
- Conversational brainstorming never becomes canonical project data until the user explicitly applies, generates, or imports it.
- Stable internal IDs should survive user-facing renames where practical.
- Wider desktop windows should reveal more workspace rather than scale a fixed game-style canvas.
- Secondary workflows belong in grouped menus instead of an ever-growing wall of top-level buttons.
- V1 parity is judged by useful workflow capability, not literal screen-for-screen reproduction.
- AI Ideas target interactive Character Card / SillyTavern-style roleplay by default: generated characters should have a clear relationship and opening dynamic with literal `{{user}}` unless the author explicitly requests a detached narrator/observer/world-NPC role.
- Alternate character routes should not require full duplicate cards when only a few fields differ; Linked Variants may inherit from a base while exports always materialise normal standalone cards.
- Visual graph layout metadata stays separate from authoritative character, relationship, and route data.
- Relationship and route/timeline editors share one reusable graph-canvas interaction model: draggable cards, explicit anchor points, labelled connections, and saved endpoint/layout metadata.
- External authoring tools and AIs should be able to hand CCF a partial character without being forced to generate filler for fields they do not know.
- Long-running AI collaboration must account for model context limits, reserve output space, preserve original local transcripts, and make lossy summarisation explicit to the user.

## Current Development Phase

**v0.15.0 development candidate — Character Collaborator + AI Authoring**

The v0.15 line begins a new conversational authoring layer while retaining the mature structured tools built through v0.14. Character Collaborator lets an author brainstorm naturally with the selected text model, attach existing cards and image references, preserve long-running sessions, regenerate responses, manage context pressure, and explicitly materialise the result into Workspace only when ready.

The running development build displays **v0.15.0**. Release metadata remains controlled by `release.sh` until a tagged release is promoted.

## Completed

### v0.15.0 — Character Collaborator Foundation

- Added **Author → Character Collaborator…** as a detachable native tool window.
- Added persistent per-project collaboration sessions with full local message history.
- Added natural freeform Text-provider conversation for character brainstorming rather than forcing every interaction through structured field generation.
- Added the active project character as optional read-only collaboration context.
- Added Character Card JSON and Character Card V2 PNG/APNG import as read-only context using the existing card parser and PNG metadata extraction path.
- Added PNG/JPG/WebP reference-image context; images are first analysed by the configured Vision provider and the resulting grounded description is supplied to the Text provider.
- Added approximate context-budget reporting using the selected model/profile context window and a reserved output-token allowance.
- Added over-budget protection rather than silently sending requests that exceed the configured context budget.
- Added **Summarise Older Messages…** with a clear warning that compression can lose nuance, exact wording, chronology, or minor detail.
- Preserved original transcript messages locally even after older content is represented by compressed model-facing memory.
- Added **Regenerate Response** while retaining previous assistant generations as selectable response variants.
- Added **Generate Character → Workspace** to materialise the current collaboration through the active template into a normal new Workspace character.
- Collaboration itself does not mutate character/project data; only explicit handoff actions cross the authoring boundary.
- Added a v0.15 generation-service layer for collaborator replies, summarisation, vision reference analysis, and final character materialisation.
- Added v0.15 shell integration and regression coverage while preserving v0.14.22 through inheritance.

### v0.14.22 — Shared Graph Canvas + Editable Relationship / Route Charts

- Added one reusable graph-canvas control shared by Relationship Graph and Route / Timeline Flowchart.
- Every graph card exposes 12 explicit anchor points around its perimeter.
- Cards can be dragged freely and exact positions are preserved.
- Anchor-to-anchor connections preserve exact source/destination anchor names.
- Connections render as labelled orthogonal paths with direction support.
- Relationship Graph creates freeform labelled relationships directly from dragged connections and retains the permanent `{{user}}` node.
- Added **Project → Route / Timeline Flowchart…** with character, Linked Variant, and freeform Step/Event nodes.
- Flowchart edges use freeform labels suitable for choices, events, time skips, alternate routes, and endings.
- Route/timeline data remains project-level versioned authoring data and does not contaminate Character Card export.

### v0.14.21 — `.ccfchar` Authoring Interchange

- Added a versioned `.ccfchar` JSON format for importing externally authored data directly into the active workspace.
- Sources may contain only Generation Concept, a subset of fields, or a nearly complete character.
- Supports recognised Overview/metadata, Character, Advanced, template, generation mode/style, Alternative Greetings, and Character Lorebook data.
- Missing properties never erase current values; explicitly supplied empty values remain intentional edits.
- Added review-first selective import and safe handling/reporting of unknown top-level keys.
- Added `docs/ccfchar-format.md` with schema rules, examples, and AI-authoring guidance.

### v0.14.20 — Relationship Graph + Linked Variants

- Added the first detachable Relationship Graph with `{{user}}`, draggable nodes, labelled relationships, and editor-only layout metadata.
- Added explicit choice between **Linked Variant** and **Full Character** when creating character versions.
- Linked Variants store sparse differences from a base, recursively inherit unchanged data/assets, and materialise into ordinary complete cards for export.
- Added cycle protection, dependency checks, base-deletion protection, and Convert Linked Variant to Full Character.

### v0.14.19 — Live Idea Generator Service Wiring

- Fixed the unified AI Ideas tab retaining a stale generation-service reference through its hidden legacy controller.
- Rebinds the visible Generate Ideas path to the current live service so current validation/repair rules actually run.

### v0.14.18 — User-Centric SillyTavern Idea Generation

- Reframed AI Ideas around interactive Character Card roleplay with literal `{{user}}` involvement by default.
- Added roleplay hooks and semantic validation/repair for missing user-centric framing while preserving explicit detached-role exceptions.

### v0.14.17 — Detachable Lorebook Manager

- Made Lorebook Manager a native, non-modal, non-transient tool window suitable for multi-monitor use.

### v0.14.16 — Idea Generator Identity + POV Validation

- Added explicit character identity/source anchoring and rejected/repaired accidental viewpoint-character replacement or invalid second-person framing.

### v0.14.15 — Lorebook Generation + Trigger Tools

- Promoted Project/Character Lorebooks into active generation context with deterministic constant/key/selective activation, ordering, token budgets, Trigger Preview, and scope transfer tools.

### v0.14.14 — Focused Character Builders

- Added direct Appearance, Personality, and Scene builders alongside the Full Character builder using external focused-builder schema data.

### v0.14.13 — Idea Generator POV Safety

- Kept AI Ideas in neutral third-person design prose and preserved `{{user}}` as the eventual chat user.

### v0.14.12 — Unified Idea Generator

- Combined AI Ideas and Structured Builder into one Idea Generator entry point and retired duplicate/orphan legacy windows.

### v0.14.11 — Structured Idea Builder + Editable Pools

- Restored V1-style structured ingredients with locks, randomisation, custom values, multi-select fields, editable option lists, and reset controls.

### v0.14.10 — Related Character / AI Variation

- Added creation of independent related characters or transformed versions seeded by source card, project context, and/or relationships with provenance.

### v0.14.9 — Library Assignment UX

- Replaced retyping of existing folder/collection names with assignment pickers and simplified Library filtering/navigation.

### v0.14.8 — Manual Guided Alternative Greetings

- Added repeatable, reorderable, removable Alternative Greetings with Character Card round-trip support.

### v0.14.7 — Manual Guided Component Parity

- Manual Guided now follows enabled template Generation Components and keeps state isolated per character/project.

### v0.14.6 — Preview Selection Safety

- Unchecked Generation Preview rows perform no writes and live user edits remain authoritative when applying generated content.

### v0.14.5 — Grouped Navigation + Lorebook Foundation

- Added grouped Author / Project / Character / Tools menus plus Project and Character Lorebook editing.

### v0.14.4 — Manual Guided

- Restored no-AI template-aware direct authoring across core card fields and future-facing sections.

### v0.14.3 — Recoverable Generation Review

- Preserves parseable AI output for user review/editing even when semantic validation still fails after bounded repair.

### v0.14.2 — Character Transfer + Text Input Convention

- Added Move/Copy between projects with character-local data/files and consistent multiline input behaviour.

### v0.14.1 — Desktop Layout + Interview Review

- Improved native resizing and persisted Interview/Q&A answers with Manual versus AI provenance.

### v0.14.0 — Authoring Option Foundation

- Added shared versioned authoring-option pools and stabilised Interview output budgets and Image Studio scrolling.

### v0.13.x — Generation Parity and Provider Stabilisation

- Generation contracts/groups/components, semantic validation/repair, private Interview/Q&A, mode/style controls, concept fidelity, Generation Preview diagnostics, alternate greetings, Vision Analysis, Creative Concept, provider capability discovery, response compatibility, default templates, project drafts, and AI-authored image prompts.

### v0.12.x — Image Provider Expansion

- Separate image provider settings, Forge/A1111 and OpenAI-compatible image generation, discovery, batch generation, seed/steps/CFG, and regenerate/new-seed workflows.

### v0.11.x — Image Generation Foundation

- Generated-image storage/gallery, prompt construction, portrait assignment, response decoding, and PNG normalisation.

### v0.10.x — Vision and Attachments

- Independent Text/Vision roles, project/per-character attachments, vision preprocessing/context budgeting, review-first analysis, and portable managed assets.

### v0.9.x — Series and Release Infrastructure

- Versioned Series Bibles, Series Manager, Auto Series, series packs/import/export, release validation, export presets, and release/update helpers.

### v0.8.x — Character Library 2.0

- Thumbnail/list views, search, sorting, favourites, folders, collections, tags, filters, bulk tools, incremental indexing, and dashboard statistics reuse.

### v0.7.x — Import / Export Foundation

- Character Card V1/V2 import, V2 export, PNG/APNG metadata, compatibility reports, Character Book preservation, CCF extension round-trips, and portable `.ccfproject` packages.

### v0.6.x — Relationships and Multi-Character Card Workflows

- Relationship matrices, directional relationship generation/context, Group Scene generation, and Card Workflow Studio planning.

### v0.5.x — Multi-Character Project Foundation

- Project format v2 with `characters[]`, shared context, roster tools, per-character state/assets/templates, and migration support.

### v0.4.x — Guided / Controlled Building

- Guided Character Builder, presets, AI fill/extraction, safe section builds, selected-field revision, and diagnostics.

### v0.3.x — Template System

- Template Manager, editable fields/generation instructions/output policy, migration/validation, Idea Generator, and Generation Preview.

### v0.2.x / v0.1.x — Application + Generation Foundations

- Godot shell, project JSON, template-driven editor, async generation queue/cancellation/retries, field suggestions, API profiles/model discovery, generation history, and initial Library.

## In Progress

### Character Collaborator

v0.15.0 establishes the conversational authoring foundation. Continue with:

- Runtime-test natural multi-turn character development against local and cloud OpenAI-compatible providers.
- Add explicit model/profile context-window configuration and, where provider APIs expose reliable data, discovery of model context limits.
- Improve token budgeting beyond the current approximate characters-per-token estimate where practical without provider lock-in.
- Add user-pinned facts/constraints that survive all memory summarisation passes.
- Add configurable summarisation strategies, chunk sizes, and summary boundaries for very long sessions.
- Keep full local transcripts even when model-facing history uses multiple levels of compressed memory.
- Add session rename, delete, duplicate, export/import, and clearer per-character/project association.
- Add edit-message and conversation-branch workflows while keeping discarded branches available locally.
- Add **Regenerate with Instruction** in addition to plain regeneration.
- Add review-first **Update Existing Character** and **Create Linked Variant** actions from a collaboration, with field-by-field diffs before writes.
- Let the user attach multiple selected project characters, project shared context, relationships, lorebooks, Series Bible information, and route/timeline state as explicit context sources.
- Add review-first collaborator actions for proposed relationships and lorebook entries without silently applying them.
- Copy/manage external reference images into portable project storage when the author chooses to retain them long term.
- Preserve source/provenance information for imported JSON/PNG characters and image-derived context.

### v0.14 — Finish Practical V1 Authoring Parity

- Runtime-test focused builders and tune field/option coverage against real authoring use.
- Add template/user overrides for focused-builder and authoring-option pools.
- Add remaining structured Idea Generator conveniences: reusable presets, richer chips, field enable/disable, individual local reroll, and conditional/gender-aware pools.
- Continue runtime-testing the v0.14.18/v0.14.19 AI Ideas path against varied SillyTavern premises.
- Define clearer provenance for manual values, presets, Idea Generator choices, concept extraction, Builder AI, Interview AI, `.ccfchar` imports, Character Collaborator, and derivation.
- Finish true V1-equivalent Lite / Compact Lite split or multi-pass execution rather than relying only on density guidance.
- Continue character derivation with optional relationship creation/remapping and richer source-context selection.
- Extend Move/Copy to batch character transfer with relationship preservation/remapping when related characters move together.
- Complete the formal V1 feature audit using: ported / replaced-evolved / partial / intentionally retired / V2-only.

### Authoring Interchange

v0.14.21 establishes `.ccfchar` v1 as the stable single-character authoring handoff format. Continue with:

- Runtime-test files produced by several external AIs and hand-written tools.
- Add sample `.ccfchar` fixtures once real-world examples settle preferred conventions.
- Consider optional export of the current workspace back to `.ccfchar` for round-trip authoring.
- Add future state-tracking/image-generation hint fields only when those authoring systems are stable enough to document.
- Preserve backwards compatibility by versioning new semantics instead of silently changing v1 behaviour.

### Relationship, Variant and Route Tools

v0.14.22 establishes the shared 12-anchor graph canvas, graph-side relationship creation, and first Route / Timeline Flowchart. Continue with:

- Add connection selection, edit, and delete for both graphs.
- Add manual connector waypoints/routing handles for dense charts.
- Add zoom/pan, portrait thumbnails, grouping, relationship-type styling, and optional graph filters.
- Preserve exact anchor choices and connector layout metadata as editing expands.
- Add richer relationship metadata editing without forcing freeform edge labels into a narrow taxonomy.
- Add a **Resolved Card / Overrides Only** variant inspector and per-field **Revert to Inherited** actions.
- Make Linked Variant asset overrides explicit while inherited assets continue referencing the base without copies.
- Add safe re-parenting and flatten-all options for variant dependency trees.
- Expand route nodes with explicit decision, event, time-skip, route-state, good/bad end, and alternate-continuity types.
- Allow route nodes to create/link either a base character, Linked Variant, or full independent character while preserving the Full Character vs Linked Variant choice.
- Add route-node notes/conditions and branch metadata separately from final Character Card content.
- Later preview how a route state changes relationships without silently applying those changes.

### Lorebook and Context Work

- Audit Character Card V2/V3 `character_book` import/export against real cards and preserve unknown/extension fields without loss.
- Add standalone lorebook JSON import/export.
- Add search/filter/sort for large lorebooks.
- Add optional scan-depth/recursion behaviour only where interoperability requires it.
- Add explicit per-generation lore scope controls.
- Add Manual Guided lorebook editing/creation without flattening lore into ordinary prose fields.
- Add AI helpers such as Extract Lore and Suggest Lore Entry after direct editing/interoperability stabilises.
- Consider reusable shared world-lore libraries after project/character semantics stabilise.

### State Tracking

V1 Front Porch-style state remains intentionally incomplete. Planned direct-authoring support includes:

- starting emotion and objective;
- short-term bond / long-term bond;
- trust level;
- time-of-day and weekday anchors;
- preservation/import/export as interoperable extension data where appropriate;
- no hard dependency on Front Porch runtime/database internals.

### Remaining Generation Parity

- Expand generation contracts for greeting counts and constrained sets where useful.
- Finish true Lite/Compact split/multi-pass behaviour.
- Continue provider regression testing for Builder/Interview precedence, semantic repair, malformed responses, Creative Concept, capability discovery, and alternate provider envelopes.

## Next Up

1. Runtime-test v0.15.0 Character Collaborator with multi-turn brainstorming, regeneration, imported JSON/V2 PNG context, Vision image context, summarisation, and Generate Character → Workspace.
2. Add explicit context-window configuration/discovery so Collaborator budgets match the chosen model rather than relying on fallback assumptions.
3. Add review-first Update Existing Character / Create Linked Variant actions from Collaborator sessions.
4. Runtime-test the v0.14.22 Relationship Graph by dragging cards, connecting varied anchors, and creating freeform labels including `{{user}}` links.
5. Runtime-test Route / Timeline Flowchart with base characters, Linked Variants, Full Character versions, and Step/Event nodes.
6. Add graph connection edit/delete and manual waypoint routing after core anchor interaction is proven.
7. Runtime-test `.ccfchar` files from concept-only through complete cards, including AI-produced files, alternative greetings, mode/style, and lorebooks.
8. Runtime-test Linked Variants with base edits, variant-of-variant chains, and JSON/PNG export.
9. Harden Character Book/lorebook interoperability and add standalone lorebook import/export.
10. Add State Tracking direct-authoring support.
11. Finish remaining Builder/Idea Generator conveniences and true Lite/Compact generation execution.

## v0.15 — Character Collaborator + Image Workflow Expansion

Character Collaborator is the headline authoring addition for v0.15. Alongside the collaboration work above, planned image expansion remains:

- image-to-image/reference-image generation where providers support it;
- generated images and managed attachments as references without embedding binary data in JSON;
- emotion-image generation/regeneration using the existing per-character emotion-image tree;
- named emotions/expressions and editable per-emotion prompts;
- reusable visual-style/prompt presets;
- richer gallery deletion/management with portrait/reference safety;
- provider-specific quality/aspect controls;
- optional advanced Forge/A1111 helpers such as LoRA/embedding prompt tools without making one WebUI ecosystem central to the project schema;
- richer AI prompt refinement/regeneration while keeping deterministic/local fallback prompt construction.

## Front Porch Compatibility — Optional / Separate

V1 gained deep Front Porch database integration late in development. V2 should not make that database layout part of its core project model. Potential optional compatibility work:

- import directly from Front Porch Stable/Beta installs;
- direct single/group-card export;
- installed-character manager with safe backups;
- state/realism extension mapping;
- keep all integration isolated behind adapters so normal V2 projects remain portable and Front-Porch-independent.

## Level and Content Tools

Character Card Forge is not a level-based game. The equivalent externally editable content systems are templates, builder schemas, authoring option pools, series bibles, lorebooks, relationship/route metadata, Collaborator sessions/context, attachments, `.ccfchar` authoring sources, and portable `.ccfproject` packages. These remain versioned and separated from engine code wherever practical.

## Technical Improvements

- Simplify release workflow around the canonical development checkout.
- Generate/commit canonical Godot `.gd.uid` sidecars consistently rather than repeatedly treating them as local noise.
- Synchronise development/version/release metadata to avoid drift between labels, VERSION, project settings, tags, and assets.
- Replace temporary version-layer compatibility bridges with clean named APIs once surrounding systems stabilise.
- Audit remaining tool windows for fixed-size assumptions and duplicated controls.
- Keep regression tests feature-focused and forward-compatible; older tests must not pin `main.tscn` permanently to historical shells.
- Add reusable lorebook normalisation/interoperability helpers instead of duplicating format knowledge in UI code.
- Keep Linked Variant resolution/diff/materialisation in one service rather than teaching every editor/exporter a separate inheritance implementation.
- Keep `.ccfchar` parsing/mapping in one versioned service so future import/export paths share one schema implementation.
- Keep graph-node dragging, anchor semantics, and connector rendering in the shared graph canvas rather than duplicating interaction logic.
- Keep Character Collaborator networking on the shared generation-service/provider layer rather than creating a separate API client stack.
- Keep Collaborator transcript storage separate from compressed model-facing memory so context optimisation never destroys author history.
- Audit folders/collections for stable-ID needs before rename-heavy workflows.

## Polish

- Full workspace visual hierarchy/theme pass after primary authoring, lorebook, graph, Collaborator, image, and interoperability work stabilises.
- Improve keyboard navigation, focus order, tooltips, empty states, confirmation wording, and accessibility.
- Reduce unnecessary modal depth and duplicated controls.
- Preserve multi-monitor-friendly detachable windows only where they improve workflow.

## Long-Term Ideas

- Rich Relationship Graph with draggable portrait cards, named directional/mutual links, notes, grouping, filtering, zoom/pan, and continuity diagnostics.
- VN-style Route / Timeline Graph with linked alternate character versions, branch conditions, and continuity inspection.
- Character Collaborator branching conversations, pinned facts, multi-character continuity sessions, and review-first application of relationships/lore/route ideas.
- Shared/community authoring-option, builder-preset, and lorebook libraries.
- GitHub-Releases-only in-app updater with explicit user-controlled download/install, release channels, hashes, and safe restart/install.
- Reusable world/campaign libraries spanning multiple projects.

## Deferred / Experimental Ideas

- V1 Front Porch-specific Manual Guided group-card implementation remains a behavioural reference but will not be copied directly; future manual multi-character authoring should build on V2 projects, relationships, shared context, Group Scene, Card Workflow, and Collaborator architecture.
- Large navigation/theme redesign concepts remain deferred until workflow architecture is stable; targeted usability fixes remain immediate.
