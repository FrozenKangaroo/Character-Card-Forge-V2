# Character Card Forge — Project Roadmap

## Project Vision

Rebuild Character Card Forge as a responsive, native Godot desktop application for creating, generating, editing, organising, importing, exporting, analysing, and illustrating AI roleplay character cards.

The original PyWebView V1 application remains a feature and behaviour reference, not an architecture specification. Useful V1 behaviour should be re-expressed as maintainable Godot-native systems with versioned external data and portable Character Card / `.ccfproject` content.

## Core Design Principles

- Godot-native desktop UI with detachable tool windows where useful.
- Character project JSON/files are the source of truth; the legacy V1 database is not.
- Versioned, externally inspectable templates, authoring schemas, lorebooks, series data, settings, project packages, and interchange formats.
- Clear separation between character data, project-shared context, AI generation, providers, images, imports/exports, library indexing, and tooling.
- OpenAI-compatible and local/self-hosted text, vision, and image providers remain first-class targets.
- Text/Vision provider roles and Image Generation providers stay independently configurable.
- New systems extend the central project model rather than create parallel character copies.
- Existing character/card data must not be destroyed by unchecked preview fields, failed reviews, disabled generation components, unrelated regeneration, or partial source imports.
- Stable internal IDs should survive user-facing renames where practical.
- Wider desktop windows should reveal more workspace rather than scale a fixed game-style canvas.
- Secondary workflows belong in grouped menus instead of an ever-growing wall of top-level buttons.
- V1 parity is judged by useful workflow capability, not literal screen-for-screen reproduction.
- AI Ideas target interactive Character Card / SillyTavern-style roleplay by default: the generated character should have a clear relationship and opening dynamic with literal `{{user}}` unless the author explicitly requests a detached narrator/observer/world-NPC role.
- Alternate character routes should not require full duplicate cards when only a few fields differ; linked variants may inherit from a base while exports always materialise normal standalone cards.
- Visual graph layout metadata stays separate from authoritative character, relationship, and route data.
- Relationship and route/timeline editors share one reusable graph-canvas interaction model: draggable cards, explicit anchor points, labelled connections and saved endpoint/layout metadata.
- External authoring tools and AIs should be able to hand CCF a partial character without being forced to generate filler for fields they do not know.

## Current Development Phase

**v0.14.22 development candidate — Shared Graph Canvas + Continuity Tools**

The v0.14 line is closing the remaining practical V1 authoring gap while expanding V2-native continuity and interoperability tooling. Current V2 includes Manual Guided, recoverable generation review, focused Character/Personality/Scene builders, AI and structured Idea Generator workflows, related-character/AI-variation creation, first-class lorebooks, multi-character projects/relationships, Linked Variants, `.ccfchar` authoring interchange, an editable Relationship Graph, and a VN-style Route / Timeline Flowchart built on a shared anchor-based graph canvas.

The running development build displays **v0.14.22**. Release metadata remains controlled by `release.sh` until a tagged release is promoted.

## Completed

### v0.14.22 — Shared Graph Canvas + Editable Relationship / Route Charts

- Added a reusable graph-canvas control shared by Relationship Graph and Route / Timeline Flowchart rather than implementing two incompatible editors.
- Every graph card exposes 12 explicit anchor points: top-left/middle/right, right-top/middle/bottom, bottom-right/middle/left, and left-bottom/middle/top.
- Cards can be dragged freely and graph layout preserves their exact positions.
- Dragging from one anchor to an anchor on another card requests a connection; source and destination anchor names are persisted with the connection.
- Connections render as labelled orthogonal paths with directional arrowheads.
- Upgraded Relationship Graph so new relationships can be created directly in the graph.
- Relationship creation asks **“What is the connection these two characters have?”** and accepts freeform labels instead of forcing a short predefined list.
- Relationship connections support forward, reverse, mutual and undirected semantics while retaining the permanent `{{user}}` node.
- Graph-created relationship records are saved back into project relationship data; node layout remains workspace/editor metadata.
- Added **Project → Route / Timeline Flowchart…** as a separate detachable native window.
- Route Flowchart automatically exposes full characters and Linked Variants as character-reference nodes and supports freeform Step/Event nodes.
- Flowchart connections ask **“What does this connection represent?”**, allowing arbitrary VN-style choice, event, time-skip, route and ending labels.
- Route/timeline data is stored separately at project level with a versioned schema so it does not contaminate Character Card export.
- Updated older v0.14.20/v0.14.21 shell regressions to remain forward-compatible with newer inherited shells.
- Added regression coverage for all 12 anchors, dragging, exact anchor persistence, freeform connection prompts, Relationship Graph save wiring, Route Flowchart availability, Linked Variant visibility and v0.14.22 shell integration.

### v0.14.21 — `.ccfchar` Authoring Interchange

- Added a versioned `.ccfchar` JSON format for importing externally authored character data directly into the active workspace.
- A source may contain only Generation Concept, a subset of fields, or a nearly complete character.
- Supports recognised Overview/metadata, Character, Advanced, template, generation mode/style, Alternative Greetings and Character Lorebook data.
- Missing properties never erase current workspace values; explicitly supplied empty values remain intentional edits.
- Added review-first import with one checkbox per supplied field before anything is applied.
- Unknown top-level data is ignored safely and reported in the preview rather than failing the whole import.
- Import works through the same workspace data model as normal editing, including Linked Variants, so variant commits continue storing only differences.
- Added `docs/ccfchar-format.md` with the schema, minimal/complete examples, AI-authoring guidance and the distinction between `.ccfchar`, `.ccfproject`, and final Character Card JSON/PNG.
- Added regression coverage for concept-only imports, non-destructive omission, explicit clearing, mode/style, Alternative Greetings, lorebook mapping, menu wiring and shell integration.

### v0.14.20 — Relationship Graph + Linked Variants

- Added a detachable project Relationship Graph over the existing structured relationship data.
- Added a permanent `{{user}}` graph node alongside project characters.
- Existing relationships render as labelled directional connections without creating a second relationship model.
- Graph nodes are draggable, Auto Layout is available, and saved positions live only in project workspace metadata.
- Added explicit character-version creation choice between a full independent character and a Linked Variant.
- Linked Variants use a versioned sparse record containing a base character reference plus only changed overrides.
- Variant editing resolves inherited data into the normal full workspace while save/commit recomputes the minimal deep diff.
- Variants can inherit unchanged card fields and assets without duplicating portrait/image files during authoring.
- Added recursive variant resolution with cycle protection and dependency checks.
- Added Convert Linked Variant to Full Character.
- Prevented deleting a base character while direct linked variants still depend on it.
- Import / Export Studio receives a temporary materialised character for variants, so JSON/PNG export remains a complete ordinary Character Card with no external dependency on CCF variant metadata.
- Added regression coverage for inheritance, diff-only storage, materialisation/export projection, graph `{{user}}` support, menu wiring, and shell integration.

### v0.14.19 — Live Idea Generator Service Wiring

- Fixed the unified AI Ideas tab retaining a stale generation-service reference through its hidden legacy controller.
- Rebinds the embedded AI Ideas controller to the workspace's current generation service after service upgrades and whenever the unified Idea Generator opens.
- Ensures the visible Generate Ideas action actually reaches the v0.14.18 `{{user}}`-centric validation and repair path.
- Added integration regression coverage using a fake embedded controller rather than testing only the generation service in isolation.

### v0.14.18 — User-Centric SillyTavern Idea Generation

- Reframed AI Ideas as interactive Character Card / SillyTavern concepts rather than detached fiction synopses.
- By default every generated idea must explicitly centre the card character's relationship and immediate roleplay dynamic with literal `{{user}}`.
- Added `roleplay_hook` so each idea explains why the generated character and `{{user}}` are interacting now and what drives the opening roleplay.
- `character_role`, `roleplay_hook`, and `concept` must all explicitly involve `{{user}}` for normal ideas.
- Third-person prose remains required for the card character while second-person `you`/`your` narration remains invalid.
- Explicit observer/narrator/world-NPC/detached requests remain supported as opt-in exceptions.
- Extended semantic validation and bounded repair for missing `{{user}}` framing and roleplay hooks.

### v0.14.17 — Detachable Lorebook Manager

- Configured Lorebook Manager as a true native OS window before it enters the scene tree.
- Lorebook Manager is non-modal and non-transient, so it can move outside the main app bounds and onto another monitor.
- Retained v0.14.15 lorebook trigger/context/editing behaviour.

### v0.14.16 — Idea Generator Identity + POV Validation

- Strengthened AI Ideas from prompt-only POV guidance into a validated output contract.
- Every idea identifies `character_name`, `character_role`, and a source anchor grounded in the premise.
- `{{user}}` cannot become the generated card subject.
- Narrative second person and invented unrelated viewpoint roles are rejected/repaired.

### v0.14.15 — Lorebook Generation + Trigger Tools

- Promoted Project Lorebook and Character Lorebook from passive editable data into active generation context.
- Added deterministic constant/key/selective/case-sensitive activation, ordering and token budgets.
- Added Trigger Preview plus Copy/Move between project and character scopes.
- Preserved interoperable `character.character_book` storage.

### v0.14.14 — Focused Character Builders

- Kept the V2 Full Character builder and added direct Appearance, Personality, and Scene tabs.
- Restored mapped V1 field groups and option pools through `data/focused_builder_schema_v01414.json` rather than hard-coded forms.
- Added editable guidance and safe Sync to Full Character while retaining existing review boundaries.

### v0.14.13 — Idea Generator POV Safety

- AI Ideas describe proposed characters/scenarios in neutral third person rather than producing `You are <character>` concepts.
- `{{user}}` remains the eventual chat user.

### v0.14.12 — Unified Idea Generator

- One Idea Generator entry point contains AI Ideas and Structured Builder tabs.
- Removed redundant Concept Studio navigation and duplicate/orphan legacy Idea Generator windows.

### v0.14.11 — Structured Idea Builder + Editable Pools

- Restored the V1-style structured ingredient workflow alongside V2's freeform AI Ideas workflow.
- Added locks, randomisation, custom values, multi-select fields, editable option lists, per-field reset, and reset-all behaviour.

### v0.14.10 — Related Character / AI Variation

- Added creation of independent related characters or transformed versions of an existing character.
- Source card, project context, and relationships can independently seed derivation.
- Internal provenance records the source character/project and transformation request without overwriting the source.

### v0.14.9 — Library Assignment UX

- Replaced retyping of existing folder/collection names with assignment pickers.
- Grouped lower-frequency Library actions while preserving All Character Projects as the explicit filter reset.

### v0.14.8 — Manual Guided Alternative Greetings

- Added independently editable, reorderable, removable Alternative Greetings that round-trip through Character Card arrays.

### v0.14.7 — Manual Guided Component Parity

- Manual Guided reads enabled template Generation Components as its source of truth.
- Component add/remove/rename/reorder changes are reflected automatically.
- Fixed character/project draft leakage.

### v0.14.6 — Preview Selection Safety

- Unchecked Generation Preview rows perform no write and preserve existing content.
- Live workspace values are recaptured before Apply so user edits made during generation remain authoritative.

### v0.14.5 — Grouped Navigation + Lorebook Foundation

- Added grouped Author / Project / Character / Tools workspace menus.
- Added Project Lorebook and Character Lorebook editing with standard Character Card `character_book` storage.

### v0.14.4 — Manual Guided

- Restored no-AI, template-aware direct authoring across Description, Personality, Scenario, First Message(s), Example Dialogues, Tags/System Prompt, and future-facing state/image sections.

### v0.14.3 — Recoverable Generation Review

- Parseable AI output is preserved for review even if semantic/template validation still fails after repair.
- Users can edit, selectively apply, keep, or later regenerate individual sections.

### v0.14.2 — Character Transfer + Text Input Convention

- Added Move/Copy between existing/new projects while preserving character-local data and files.
- Added consistent Shift+Enter multiline input behaviour.

### v0.14.1 — Desktop Layout + Interview Review

- Native resizing exposes more workspace.
- Interview/Q&A answers persist with Manual versus AI provenance.

### v0.14.0 — Authoring Option Foundation

- Added shared versioned authoring-option pools for Builder suggestions.
- Stabilised Interview output budgets and Image Studio scrolling.

### v0.13.x — Generation Parity and Provider Stabilisation

- Generation contracts/groups/components, semantic validation/repair, private Interview/Q&A, mode/style controls, concept fidelity, Generation Preview diagnostics, alternate greetings, Vision Analysis, Creative Concept, model capability discovery, provider-response compatibility, default templates, project drafts, and AI-authored image prompts.

### v0.12.x — Image Provider Expansion

- Separate image provider settings, Forge/A1111 and OpenAI-compatible API image generation, model/sampler discovery, batch generation, seed/steps/CFG controls, regenerate/new-seed workflows.

### v0.11.x — Image Generation Foundation

- Generated-image storage/gallery, prompt construction, portrait assignment, response decoding and PNG normalisation.

### v0.10.x — Vision and Attachments

- Independent Text/Vision roles, project/per-character attachments, vision preprocessing/context budgeting, review-first analysis, and portable managed assets.

### v0.9.x — Series and Release Infrastructure

- Versioned Series Bibles, Series Manager, Auto Series, series packs/import/export, release validation, export presets, and release/update helper tooling.

### v0.8.x — Character Library 2.0

- Thumbnail/list views, search, sorting, favourites, folders, collections, tags, filters, bulk tools, incremental indexing, and dashboard statistics reuse.

### v0.7.x — Import / Export Foundation

- Character Card V1/V2 import, V2 export, PNG/APNG metadata, compatibility reports, Character Book preservation, CCF extension round-trips, and portable `.ccfproject` packages.

### v0.6.x — Relationships and Multi-Character Card Workflows

- Relationship matrices, directional relationship generation/context, Group Scene generation, and Card Workflow Studio planning.

### v0.5.x — Multi-Character Project Foundation

- Project format v2 with `characters[]`, shared context, roster tools, per-character state/assets/templates, and migration support.

### v0.4.x — Guided / Controlled Building

- Guided Character Builder, presets, AI fill/extraction, safe section builds, selected-field revision and diagnostics.

### v0.3.x — Template System

- Template Manager, editable fields/generation instructions/output policy, migration/validation, Idea Generator and Generation Preview.

### v0.2.x / v0.1.x — Application + Generation Foundations

- Godot shell, project JSON, template-driven editor, async generation queue/cancellation/retries, field suggestions, API profiles/model discovery, generation history and initial Library.

## In Progress

### v0.14 — Finish Practical V1 Authoring Parity

- Runtime-test focused builders and tune field/option coverage against real authoring use.
- Add template/user overrides for focused-builder and authoring-option pools.
- Add remaining structured Idea Generator conveniences: reusable presets, richer chips, field enable/disable, individual local reroll and conditional/gender-aware pools.
- Continue runtime-testing the v0.14.18/v0.14.19 AI Ideas path against varied SillyTavern premises.
- Define clearer provenance for manual values, presets, Idea Generator choices, concept extraction, Builder AI, Interview AI, `.ccfchar` imports and derivation.
- Finish true V1-equivalent Lite / Compact Lite split or multi-pass execution rather than relying only on density guidance.
- Continue character derivation with optional relationship creation/remapping and richer source-context selection.
- Extend Move/Copy to batch character transfer with relationship preservation/remapping when related characters move together.
- Complete the formal V1 feature audit using: ported / replaced-evolved / partial / intentionally retired / V2-only.

### Authoring Interchange

v0.14.21 establishes `.ccfchar` v1 as the stable single-character authoring handoff format. Continue with:

- Runtime-test files produced by several external AIs and hand-written tools.
- Add sample `.ccfchar` fixtures in the repository when real-world examples settle the preferred conventions.
- Consider optional export of the current workspace back to `.ccfchar` for round-trip authoring workflows.
- Add future state-tracking/image-generation hint fields only when those authoring systems are stable enough to document.
- Preserve backward compatibility by versioning new semantics rather than silently changing v1 behaviour.

### Relationship, Variant and Route Tools

v0.14.22 establishes the shared 12-anchor graph canvas, graph-side relationship creation and the first Route / Timeline Flowchart. Continue with:

- Add connection selection, edit and delete for both Relationship Graph and Route Flowchart.
- Add manual connector waypoints/routing handles so dense charts can route around cards cleanly.
- Add zoom/pan, portrait thumbnails, grouping, relationship-type styling and optional graph filters.
- Preserve exact anchor choices and connector layout metadata when graph editing expands.
- Add richer relationship metadata editing without forcing freeform edge labels into a narrow taxonomy.
- Add a clear **Resolved Card / Overrides Only** variant inspector and per-field **Revert to Inherited** actions.
- Make linked-variant asset overrides explicit while inherited assets continue referencing the base without copies.
- Add safe re-parenting and flatten-all options for variant dependency trees.
- Expand Route / Timeline nodes with explicit decision, event, time-skip, route-state, good/bad end and alternate-continuity node types.
- Allow route nodes to create/link either a base character, a Linked Variant or a full independent character while preserving the user's Full Character vs Linked Variant choice.
- Add route-node notes/conditions and branch metadata separately from final Character Card content.
- Later allow previewing how a route state changes relationships without silently applying those changes.

### Lorebook and Context Work

v0.14.15 establishes generation activation and trigger preview; v0.14.17 makes the editor independently detachable. Continue with:

- Audit Character Card V2/V3 `character_book` import/export against real cards and preserve unknown/extension fields without loss.
- Add standalone lorebook JSON import/export.
- Add search/filter/sort for large lorebooks.
- Add optional scan-depth/recursion behaviour only where interoperability requires it.
- Add explicit per-generation lore scope controls.
- Add Manual Guided lorebook editing/creation without flattening lore into ordinary prose fields.
- Add AI helpers such as Extract Lore and Suggest Lore Entry after direct editing/interoperability is stable.
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
- Continue provider regression testing for Builder/Interview precedence, semantic repair, malformed responses, Creative Concept, capability discovery and alternate provider envelopes.

## Next Up

1. Runtime-test the v0.14.22 Relationship Graph by dragging cards, connecting different anchor combinations and creating freeform relationship labels including `{{user}}` links.
2. Runtime-test the Route / Timeline Flowchart with base characters, Linked Variants, Full Character versions and Step/Event nodes.
3. Add graph connection edit/delete and manual waypoint routing after the core anchor interaction is proven in real projects.
4. Runtime-test `.ccfchar` files ranging from concept-only to complete characters, including AI-generated files, alternative greetings, mode/style and lorebooks.
5. Runtime-test Linked Variants with ordinary edits, base edits, variant-of-variant chains and JSON/PNG export.
6. Harden Character Book/lorebook import-export unknown-field preservation and add standalone lorebook import/export.
7. Add State Tracking direct-authoring support.
8. Finish remaining Builder/Idea Generator conveniences and true Lite/Compact generation execution.
9. Begin v0.15 image workflow expansion once primary authoring/data parity is stable.

## v0.15 — Image Workflow Expansion

Planned:

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

Character Card Forge is not a level-based game. The equivalent externally editable content systems are templates, builder schemas, authoring option pools, series bibles, lorebooks, relationship/route metadata, attachments, `.ccfchar` authoring sources and portable `.ccfproject` packages. These remain versioned and separated from engine code wherever practical.

## Technical Improvements

- Simplify release workflow around the canonical development checkout.
- Generate/commit canonical Godot `.gd.uid` sidecars consistently rather than repeatedly treating them as local noise.
- Synchronise development/version/release metadata to avoid drift between labels, VERSION, project settings, tags and assets.
- Replace temporary version-layer compatibility bridges with clean named APIs once surrounding systems stabilise.
- Audit remaining tool windows for fixed-size assumptions and duplicated controls.
- Keep regression tests feature-focused and forward-compatible; older tests must not pin `main.tscn` permanently to their historical shell.
- Add reusable lorebook normalisation/interoperability helpers instead of duplicating format knowledge in UI code.
- Keep Linked Variant resolution/diff/materialisation in one service rather than teaching every editor/exporter a separate inheritance implementation.
- Keep `.ccfchar` parsing/mapping in one versioned service so future import/export paths share one schema implementation.
- Keep graph-node dragging, anchor semantics and connector rendering in the shared graph canvas rather than duplicating interaction logic in Relationship and Route windows.
- Audit folders/collections for stable-ID needs before rename-heavy workflows.

## Polish

- Full workspace visual hierarchy/theme pass after primary authoring, lorebook, graph, image and interoperability work stabilises.
- Improve keyboard navigation, focus order, tooltips, empty states, confirmation wording and accessibility.
- Reduce unnecessary modal depth and duplicated controls.
- Preserve multi-monitor-friendly detachable windows only where they improve the workflow.

## Long-Term Ideas

- Rich Relationship Graph with draggable portrait cards, named directional/mutual links, notes, grouping, filtering and zoom/pan.
- VN-style Route / Timeline Graph with linked alternate character versions, branch conditions and continuity inspection.
- Shared/community authoring-option, builder-preset and lorebook libraries.
- GitHub-Releases-only in-app updater with explicit user-controlled download/install, release channels, hashes and safe restart/install.
- Reusable world/campaign libraries spanning multiple projects.

## Deferred / Experimental Ideas

- V1 Front Porch-specific Manual Guided group-card implementation remains a behavioural reference but will not be copied directly; future manual multi-character authoring should build on V2 projects, relationships, shared context, Group Scene and Card Workflow architecture.
- Large navigation/theme redesign concepts remain deferred until workflow architecture is stable; targeted usability fixes remain immediate.
