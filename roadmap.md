# Character Card Forge — Project Roadmap

## Project Vision

Rebuild Character Card Forge as a responsive, native Godot desktop application for creating, generating, editing, organising, importing, exporting, analysing, and illustrating AI roleplay character cards.

The original PyWebView V1 application remains a feature and behaviour reference, not an architecture specification. Useful V1 behaviour should be re-expressed as maintainable Godot-native systems with versioned external data and portable Character Card / `.ccfproject` content.

## Core Design Principles

- Godot-native desktop UI with detachable tool windows where useful.
- Character project JSON/files are the source of truth; the legacy V1 database is not.
- Versioned, externally inspectable templates, authoring schemas, lorebooks, series data, settings, and project packages.
- Clear separation between character data, project-shared context, AI generation, providers, images, imports/exports, library indexing, and tooling.
- OpenAI-compatible and local/self-hosted text, vision, and image providers remain first-class targets.
- Text/Vision provider roles and Image Generation providers stay independently configurable.
- New systems extend the central project model rather than create parallel character copies.
- Existing character/card data must not be destroyed by unchecked preview fields, failed reviews, disabled generation components, or unrelated regeneration.
- Stable internal IDs should survive user-facing renames where practical.
- Wider desktop windows should reveal more workspace rather than scale a fixed game-style canvas.
- Secondary workflows belong in grouped menus instead of an ever-growing wall of top-level buttons.
- V1 parity is judged by useful workflow capability, not literal screen-for-screen reproduction.

## Current Development Phase

**v0.14.16 development candidate — Authoring Parity + Hardened Idea Generation**

The v0.14 line is closing the remaining practical V1 authoring gap while keeping V2's stronger project architecture. Current V2 now includes Manual Guided, recoverable generation review, focused Character/Personality/Scene builders, both AI and structured Idea Generator workflows, related-character/AI-variation creation, first-class lorebook generation context, multi-character projects/relationships, portable project content, and improved Library organisation.

The running development build displays **v0.14.16**. Release metadata remains controlled by `release.sh` until a tagged release is promoted.

## Completed

### v0.14.16 — Idea Generator Identity + POV Validation

- Strengthened AI Ideas from prompt-only POV guidance into a validated output contract.
- Every idea now identifies `character_name`, `character_role`, and an exact `source_anchor` copied from the source premise.
- `{{user}}` remains the future chat user and cannot become the generated card subject.
- Concepts are required to use neutral third-person design prose; narrative `you` / `your` wording is rejected before result cards are shown.
- Seeded ideas reject common newly invented observer/relative/viewpoint roles when those role types are absent from the source premise.
- Invalid batches receive one bounded semantic repair pass that preserves the original premise while correcting identity and POV violations.
- After repair, only ideas satisfying the contract reach the UI; a completely invalid batch fails cleanly rather than showing misleading concepts.
- Added regression coverage using the same class of double-affair/pregnancy premise that exposed the original inconsistent POV behaviour.

### v0.14.15 — Lorebook Generation + Trigger Tools

- Promoted Project Lorebook and Character Lorebook from passive editable data into active generation context.
- Added deterministic lore activation using enabled state, constant entries, primary keys, optional selective secondary keys, and case sensitivity.
- Active entries are ordered by priority and insertion order.
- Lorebook token budgets cap injected context instead of blindly sending every entry to the model.
- Character generation, field suggestions, and inherited generation workflows receive activated lore through the shared generation-context path.
- Added Trigger Preview in Lorebook Manager for testing which entries activate against sample text.
- Added Copy to Other Scope and Move to Other Scope for transferring entries between Project and Character Lorebooks.
- Preserved the existing interoperable `character.character_book` location for character lore.
- Added regression coverage for constant/key/selective activation, disabled entries, generation-service wiring, trigger preview, scope transfer, and v0.14.15 shell integration.

### v0.14.14 — Focused Character Builders

- Kept the existing V2 Full Character builder and added direct Appearance, Personality, and Scene tabs.
- Restored mapped V1 field groups and option pools through `data/focused_builder_schema_v01414.json` rather than hard-coded UI forms.
- Added editable guidance and safe Sync to Full Character without bypassing the established Send to Concept / Apply to Character review boundary.
- Focused builder state persists separately per character.

### v0.14.13 — Idea Generator POV Safety

- AI Ideas now describe proposed characters/scenarios in neutral third person rather than producing `You are <character>` concepts.
- `{{user}}` remains the eventual chat user and is not assigned invented identity/actions unless supplied by the prompt.

### v0.14.12 — Unified Idea Generator

- One Idea Generator entry point now contains AI Ideas and Structured Builder tabs.
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
- Added Project Lorebook and Character Lorebook editing with standard Character Card `character_book` storage for character lore.

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

- Runtime-test the v0.14.14 focused builders and tune field/option coverage against real authoring use.
- Add template/user overrides for focused-builder and authoring-option pools.
- Add remaining structured Idea Generator conveniences where useful: reusable presets, richer chips, field enable/disable, individual local reroll and conditional/gender-aware pools.
- Continue runtime-testing v0.14.16 AI Ideas identity/POV validation across complex multi-person premises and tune grounding rules without suppressing legitimate characters already present in a seed.
- Define clearer provenance for manual values, presets, Idea Generator choices, concept extraction, Builder AI, Interview AI and derivation.
- Finish true V1-equivalent Lite / Compact Lite split or multi-pass execution rather than relying only on density guidance.
- Continue character derivation with optional relationship creation/remapping and richer source-context selection after runtime testing.
- Extend Move/Copy to batch character transfer with relationship preservation/remapping when related characters move together.
- Complete the formal V1 feature audit using: ported / replaced-evolved / partial / intentionally retired / V2-only.

### Lorebook and Context Work

v0.14.15 establishes generation activation and trigger preview. Continue with:

- Audit Character Card V2/V3 `character_book` import/export against real cards and preserve unknown/extension fields without loss.
- Add standalone lorebook JSON import/export.
- Add search/filter/sort for large lorebooks.
- Add optional scan-depth/recursion behaviour only where interoperability requires it; avoid pretending unsupported semantics exist.
- Add explicit per-generation lore scope controls when users need to override automatic activation.
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

1. Runtime-test v0.14.16 AI Ideas against complex multi-person prompts and tune identity grounding if needed.
2. Harden Character Book/lorebook import-export unknown-field preservation.
3. Add standalone lorebook import/export and large-lorebook search/filter tools.
4. Add State Tracking direct-authoring support.
5. Finish remaining Builder/Idea Generator parity conveniences and true Lite/Compact generation execution.
6. Begin v0.15 image workflow expansion once primary authoring/data parity is stable.

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

Character Card Forge is not a level-based game. The equivalent externally editable content systems are templates, builder schemas, authoring option pools, series bibles, lorebooks, attachments and portable `.ccfproject` packages. These remain versioned and separated from engine code wherever practical.

## Technical Improvements

- Simplify release workflow around the canonical development checkout.
- Generate/commit canonical Godot `.gd.uid` sidecars consistently rather than repeatedly treating them as local noise.
- Synchronise development/version/release metadata to avoid drift between labels, VERSION, project settings, tags and assets.
- Replace temporary version-layer compatibility bridges with clean named APIs once surrounding systems stabilise.
- Audit remaining tool windows for fixed-size assumptions and duplicated controls.
- Keep regression tests feature-focused and forward-compatible; older tests must not pin `main.tscn` permanently to their historical shell.
- Add reusable lorebook normalisation/interoperability helpers instead of duplicating format knowledge in UI code.
- Audit folders/collections for stable-ID needs before rename-heavy workflows.

## Polish

- Full workspace visual hierarchy/theme pass after primary authoring, lorebook, image and interoperability work stabilises.
- Improve keyboard navigation, focus order, tooltips, empty states, confirmation wording and accessibility.
- Reduce unnecessary modal depth and duplicated controls.
- Preserve multi-monitor-friendly detachable windows only where they improve the workflow.

## Long-Term Ideas

- Visual relationship-map canvas with draggable character cards, directional/mutual links, notes, grouping and zoom/pan.
- Character Concept Exchange format after authoring/planning schemas stabilise.
- Shared/community authoring-option, builder-preset and lorebook libraries.
- GitHub-Releases-only in-app updater with explicit user-controlled download/install, release channels, hashes and safe restart/install.
- Reusable world/campaign libraries spanning multiple projects.

## Deferred / Experimental Ideas

- V1 Front Porch-specific Manual Guided group-card implementation remains a behavioural reference but will not be copied directly; future manual multi-character authoring should build on V2 projects, relationships, shared context, Group Scene and Card Workflow architecture.
- Large navigation/theme redesign concepts remain deferred until workflow architecture is stable; targeted usability fixes remain immediate.
