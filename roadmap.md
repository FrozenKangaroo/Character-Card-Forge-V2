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
- Provider/model token limits must remain data-driven; UI controls must not impose obsolete ceilings that prevent use of newer long-context/high-output models.
- Character Collaborator should preserve established canon by default, deepen existing material before rewriting premises, and make alternate/rewrite directions explicit rather than silently replacing accepted facts.
- Collaborator presentation should use semantic rich text for readability while preserving the original model response in stored conversation data.
- Collaborator conversations are independent local authoring documents. A project link is optional metadata and must never be required for a chat to survive an app restart.
- Collaborator autosave on the interactive send path should touch only the active conversation; unrelated archived chats must not make current-message preparation slower.
- Rich-text styling must remain readable across supported platforms and should not depend on synthetic font effects that introduce glyph-rendering artifacts.
- Collaborator image attachments must be analysed by the configured Vision role first. The Text role receives a comprehensive Vision-derived description of the full scene, never the original image payload, and decides how to use that evidence according to the author's request.
- AI profiles may expose different Text and Vision model IDs; Vision-role requests must route through the dedicated `vision_model` while Text-role requests continue to use `model`.
- Text and Vision models may have different context/output limits; Vision jobs must use Vision-specific token limits rather than inheriting Text-model limits.
- Vision input preprocessing must preserve originals and only optimise genuinely oversized files; small images should pass through unchanged.
- File-dialog authoring state should survive application restarts instead of depending on Godot's process-local FileDialog state.
- **Generate Character** is a full synthesis action: populated Workspace fields are authoritative source material, while the active template defines the generated output contract. Selective/missing-field tools remain separate workflows.
- Full synthesis review should expose the complete returned template result, including intentionally preserved values, rather than collapsing review to only byte-different fields.
- Generation Components are the authoritative transformation recipe for grouped outputs: Workspace data is the source fact pool, enabled components decide what is materialised, and template fields are the final destinations.
- Character Collaborator handoff is blueprint-first by default: preserve the collaboration as one detailed canonical Generation Concept before template materialisation so repeated field-to-field transformations do not silently discard carefully developed facts.
- Direct field-filling from Collaborator remains an explicit alternative workflow and should preserve high detail while carrying supplementary character data such as Alternative Greetings and Character Lorebook entries.

## Current Development Phase

**v0.15.15 development candidate — blueprint-first Collaborator handoff**

The v0.15 line now has persistent Character Collaborator sessions, strict Vision → Text handling, visible Vision analysis, durable desktop FileDialog state, component-driven full-character synthesis, and a safer handoff model for long creative sessions. v0.15.15 makes a loss-minimising Generation Blueprint the recommended bridge from Collaborator to Workspace while retaining an optional detailed direct-draft mode that also materialises Alternative Greetings and Character Lorebook data.

The running development build displays **v0.15.15**. Release metadata remains controlled by `release.sh` until a tagged release is promoted.

## Completed

### v0.15.15 — Blueprint-First Collaborator Handoff

- Replaced the one-size-fits-all Collaborator materialisation action with an explicit Workspace handoff selector.
- **Blueprint → Generation Concept (Recommended)** is the default handoff mode.
- Blueprint mode asks the Text model for a long, loss-minimising canonical source document rather than immediately scattering the collaboration across many card fields.
- Blueprint prompts explicitly preserve concrete accepted facts, later corrections, chronology, relationship details, appearance, behaviour, history, scenario beats, dialogue requirements, boundaries, secrets and other established specifics instead of aggressively summarising them.
- The generated Blueprint includes dedicated Alternative Greetings and Lorebook planning sections so those parts of the character are not forgotten when they were developed in the collaboration.
- Blueprint mode creates a normal Workspace character with the detailed blueprint in `concept.prompt`; normal **Generate Character** can then materialise the card from that source using the active template and Generation Components.
- Kept **Detailed Workspace Draft** as an alternative for authors who want immediate field population.
- Strengthened Detailed Workspace Draft prompts to favour detail retention over terse field summaries and to use the active template/Generation Component structure as organisation rather than as a reason to discard information.
- Detailed Workspace Draft now returns and stores `character.alternate_greetings` as complete playable openings.
- Detailed Workspace Draft now returns and stores a Character Card-compatible `character.character_book` Lorebook object.
- Added handoff-mode provenance, visible working states and handoff-specific Workspace status messages.
- Added v0.15.15 generation-service, Collaborator window, Workspace, app-shell, regression and CI coverage.
- Made the v0.15.14 regression forward-compatible with later inherited shells.

### v0.15.14 — Component-Driven Full Character Synthesis

- Full-character synthesis now reads the active template's `generation_groups` and builds an explicit component-driven generation plan.
- The complete populated Workspace is treated as a shared source/fact pool rather than a set of isolated destination fields.
- Enabled Generation Groups bind their ordered enabled components to the group's configured output field.
- Component labels, requiredness, order, and author instructions are passed explicitly to the model as the transformation recipe.
- Disabled groups and disabled components do not participate in synthesis; a group with every component disabled is treated as intentionally inactive.
- Grouped fields gather relevant facts from anywhere in the Workspace and materialise one coherent final output value rather than exposing component subkeys.
- AI-generatable fields not controlled by a Generation Group continue to follow their normal field-specific generation instructions.
- Existing canon remains authoritative while material can be reorganised, reconciled and deepened to satisfy the component recipe.
- Preserved v0.15.13 complete-result preview behaviour and added explicit component-plan metadata for diagnostics/regression coverage.
- Added v0.15.14 generation-service, Workspace, app-shell, regression and CI coverage.
- Made the v0.15.13 regression forward-compatible with later inherited shells.

### v0.15.13 — Complete Synthesis Review + Collaborator Responsiveness

- Strengthened full-character synthesis so every AI-generatable field in the active template is explicitly mandatory in the synthesis response, even when the Workspace already contains a value.
- Added stronger whole-character editorial guidance: preserve canon, reconcile cross-field facts, and actively polish each returned field into final-form card text rather than treating populated fields as finished work.
- Full-synthesis preview now shows every returned template field, including fields whose final value intentionally matches the existing Workspace text.
- Missing requested synthesis fields are reported explicitly in the preview instead of silently making a complete generation look like a one-field update.
- Character Collaborator now paints a **Preparing context…** state before token estimation, transcript assembly, autosave, or request construction so long conversations no longer look unresponsive immediately after Send.
- Context-budget validation now includes the newly pasted message instead of checking only the previous transcript.
- Added a high defensive single-message safety bound so pathological pastes fail gracefully instead of creating an unbounded UI/request workload.
- Added targeted Collaborator autosave that writes only the active session on the message hot path instead of serialising every saved chat after each message.
- Deferred project chat snapshots now include only conversations linked to the current project, so unrelated saved conversations do not inflate normal current-chat updates.
- Fixed the two Godot 4.6.3 `INT_AS_ENUM_WITHOUT_CAST` FileDialog warnings by explicitly restoring persisted integers as `FileDialog.DisplayMode` enum values.
- Made the v0.15.12 regression forward-compatible with later inherited app shells.
- Added dedicated v0.15.13 regression and CI coverage.

### v0.15.12 — Full Character Synthesis from Workspace

- Added a dedicated full-character synthesis path instead of relying on existing/missing-field gating.
- **Generate Character** now reads all populated fields exposed by the active template as source material, including fields that are not themselves AI-generated outputs.
- Existing character facts are treated as canon to preserve, reconcile, deepen, and polish rather than as a reason to skip generation.
- The active template's AI-generatable fields remain the explicit JSON output contract, so populated output fields are still regenerated as part of a coherent complete character.
- Full synthesis no longer requires a Generation Concept when other meaningful Workspace material already exists.
- Generation Mode and Style are included as synthesis guidance when present.
- Existing shared project context, series bible, relationships, and enabled attachment context remain available to the synthesis pass.
- Full-synthesis jobs carry explicit `full_workspace_synthesis` scope and canon-preservation metadata.
- AI Suggest and Controlled Build remain separate selective-generation workflows.
- Added v0.15.12 Workspace/service/app-shell integration and dedicated regression/CI coverage.
- Made the v0.15.11 regression forward-compatible with later inherited app shells.

### v0.15.11 — Visible Vision Analysis Messages

- Completed Collaborator Vision analysis now replaces the temporary analysing state with a persistent, visually distinct **Vision Analysis** transcript message.
- Vision descriptions are selectable/copyable, preserve profile/model provenance, autosave with the independent chat session, and remain available as tagged reference context for the Text model.
- Completion scrolls to the visible result instead of leaving the transcript apparently stuck.
- Added v0.15.11 regression and CI coverage.

### v0.15.10 — Persistent FileDialog State

- Added a shared `user://` FileDialog preference store independent of projects and release/update files.
- Persists favourites, recent/history directories, last-used filesystem directory, list/thumbnail mode, hidden-file visibility, and sort selection across app relaunches.
- Seeds the operating system's actual Downloads directory as a default quick location when available.
- Recent history is bounded to 20 folders.
- Added shared FileDialog tracking and dedicated regression/CI coverage.

### v0.15.9 — Independent Vision Token Limits & Input Optimisation

- Added independent Vision Context Window and Vision Maximum Output token limits.
- Vision jobs use Vision-specific limits without mutating Text settings.
- Added preflight validation for impossible Vision output/context combinations.
- Small images pass through unchanged; genuinely oversized images may be proportionally resized and temporarily encoded as high-quality WebP without modifying originals.
- Added v0.15.9 Settings, generation-service, Workspace, app-shell, regression and CI coverage.

### v0.15.8 — Dedicated Vision-Model Routing

- Vision-role requests route through the profile's dedicated `vision_model`; Text requests continue to use `model`.
- Missing Vision models now produce a clear configuration error instead of silently sending images to the Text model.
- Preserved the full-scene Vision → Text handoff and added regression coverage.

### v0.15.7 — Collaborator Vision Pipeline

- Enforced the configured Vision role for Collaborator image attachments.
- Vision analysis describes the complete visible scene: people/characters, appearance, clothing, expressions, poses, interactions, setting, props, readable text, lighting, composition, style, and apparent activity.
- Direct observations are separated from uncertain interpretation.
- Original image payloads go only to Vision; the Text model receives a provenance-tagged full-scene description.
- Added visible Vision profile/model status and regression coverage.

### v0.15.6 — Collaborator Rich-Text Rendering Fix

- Removed synthetic `push_bold()` styling that could create dark glyph artifacts on affected font/Linux stacks.
- Preserved semantic colour, heading hierarchy, italics, selectable text, and unmodified stored responses.

### v0.15.5 — Independent Collaborator Session Persistence

- Added versioned local Collaborator storage under `user://collaborator_sessions`.
- Chats survive application restart even when started from an unsaved project.
- Project association is optional metadata rather than ownership.
- Existing project-embedded chats migrate/merge into the local library while project saves may still include linked snapshots.

### v0.15.4 — Collaborator Persistence, Behaviour Contract & Rich Text

- Added autosave after meaningful Collaborator changes plus rename/delete controls.
- Added canon-preservation, proportional response-depth, and non-pathologizing collaboration rules.
- Added semantic rich-text rendering for headings, emphasis, bullets, and common design labels while preserving raw response text for storage/Copy.

### v0.15.3 — Character Collaborator Chat UX

- Added input wrapping, differentiated user/AI cards, selectable/copyable text, visible working states, and improved auto-scroll.

### v0.15.2 — Large Output Token Limits

- Removed the old 131,072 effective output-token ceiling and allowed modern large-output model limits, including 384k-class values.

### v0.15.1 — Context Window Budgeting

- Added separate model context-window configuration, output reserve/headroom reporting, unknown-context mode, and pre-send context warnings.

### v0.15.0 — Character Collaborator Foundation

- Added detachable freeform Character Collaborator conversations with local history.
- Added existing-character, JSON, V2 PNG/APNG, and image reference context.
- Added context budgeting and explicit lossy summarisation with original transcript preservation.
- Added response regeneration with variants and **Generate Character → Workspace** handoff.
- Collaboration remains non-canonical until an explicit apply/generate/import action.

### v0.14.22 — Shared Graph Canvas + Editable Relationship / Route Charts

- Added reusable draggable graph cards with 12 anchors, labelled anchor-to-anchor connections, persistent layout metadata, Relationship Graph editing, and Route/Timeline Flowchart editing.

### v0.14.21 — `.ccfchar` Authoring Interchange

- Added versioned partial/full external character import covering Overview, Character, Advanced, template, mode/style, Alternative Greetings, and Lorebook data.
- Added review-first import and `docs/ccfchar-format.md` for human/AI authoring.

### v0.14.20 — Relationship Graph + Linked Variants

- Added labelled relationship graphs and sparse Linked Variants that inherit from a base card, store only differences, protect against cycles/dependency deletion, and materialise complete standalone exports.

### v0.14.19 — Live Idea Generator Service Wiring

- Fixed the visible Idea Generator retaining a stale generation-service reference and rebound it to the live validation/repair service.

### v0.14.18 — User-Centric SillyTavern Idea Generation

- Reframed AI Ideas around interactive Character Card roleplay with literal `{{user}}` involvement by default and repair for missing user-centric framing.

### v0.14.17 — Detachable Lorebook Manager

- Made Lorebook Manager a native non-modal, non-transient tool window suitable for multi-monitor use.

### v0.14.16 — Idea Generator Identity + POV Validation

- Added explicit identity/source anchoring and validation/repair for accidental viewpoint-character replacement or invalid POV framing.

### v0.14.15 — Lorebook Generation + Trigger Tools

- Promoted Project/Character Lorebooks into generation context with constant/key/selective activation, ordering, token budgets, Trigger Preview, and scope transfer tools.

### v0.14.14 — Focused Character Builders

- Added focused Appearance, Personality, and Scene builders alongside Full Character builder using external builder schema data.

### v0.14.13 — Idea Generator POV Safety

- Kept AI Ideas in neutral third-person design prose while preserving `{{user}}` as the eventual chat user.

### v0.14.12 — Unified Idea Generator

- Combined AI Ideas and Structured Builder into one Idea Generator workflow and retired duplicate/orphan windows.

### v0.14.11 — Structured Idea Builder + Editable Pools

- Restored V1-style structured ingredients with locks, randomisation, custom values, multi-select fields, editable option lists, and reset controls.

### v0.14.10 — Related Character / AI Variation

- Added independent related-character/transformed-version creation seeded by source card, project context, and relationships with provenance.

### v0.14.9 — Library Assignment UX

- Added assignment pickers for existing folders/collections and simplified Library filtering/navigation.

### v0.14.8 — Manual Guided Alternative Greetings

- Added repeatable, reorderable, removable Alternative Greetings with Character Card round-trip support.

### v0.14.7 — Manual Guided Component Parity

- Manual Guided now follows enabled template Generation Components with per-character/project state isolation.

### v0.14.6 — Preview Selection Safety

- Unchecked Generation Preview rows perform no writes and live user edits remain authoritative when applying generated content.

### v0.14.5 — Grouped Navigation + Lorebook Foundation

- Added grouped Author / Project / Character / Tools menus plus Project and Character Lorebook editing.

### v0.14.4 — Manual Guided

- Restored no-AI template-aware direct authoring across core card fields and future-facing sections.

### v0.14.3 — Recoverable Generation Review

- Preserves parseable AI output for review/editing even when semantic validation still fails after bounded repair.

### v0.14.2 — Character Transfer + Text Input Convention

- Added Move/Copy between projects with character-local data/files and consistent multiline input behaviour.

## In Progress

- Validate v0.15.15 Blueprint handoff against long real Collaborator sessions and confirm small established facts survive into Generation Concept rather than being collapsed during field distribution.
- Validate Detailed Workspace Draft against real characters with Alternative Greetings and Lorebook material, including custom templates and mixed Generation Component configurations.
- Continue profiling very long Collaborator sessions so token estimation, transcript rendering, autosave, Blueprint generation and direct-draft generation remain responsive at large context sizes.
- Continue hardening forward-compatible regression tests so a new inherited shell does not falsely break an older feature check.
- Continue V1 parity review where V1 still has useful authoring workflow details that V2 has not yet surpassed.

## Next Up

- Evaluate extending normal **Generate Character** review so a Blueprint can optionally materialise Alternative Greetings and Lorebook entries in the same reviewed generation operation rather than requiring separate authoring tools.
- Improve visibility/diagnostics around exactly which Generation Groups and components participated in a full synthesis result.
- Improve distinction and wording between Blueprint handoff, Detailed Workspace Draft, full-character synthesis, Controlled Build, AI Suggest, and direct manual authoring.
- Continue polishing Character Collaborator context management, image-reference workflows, and generation handoff.
- Continue relationship/route graph usability and Linked Variant workflow testing.

## Planned Features

- Further Library organisation/search/filter polish and large-library performance work.
- More template authoring/validation tooling and clearer documentation of template generation contracts.
- Stronger import/export diagnostics and compatibility reporting for external Character Card ecosystems.
- Additional AI-provider capability discovery where providers expose reliable model metadata.
- Continued V1 workflow parity where it improves V2 rather than reproducing obsolete architecture.

## Level and Content Tools

Character Card Forge is an authoring application rather than a level-based game. The equivalent content-tool priority is externally editable, versioned templates, `.ccfchar` interchange, project packages, lorebooks, and future schema/editor tooling. Loading and saving should continue to use the same data model exposed to authoring tools.

## Technical Improvements

- Keep generation services modular and preserve older project/card compatibility as schemas evolve.
- Reduce inherited-shell regression fragility by testing capability/inheritance rather than exact active-version filenames.
- Continue warning-as-error GDScript hygiene and CI parsing on Godot 4.6.x.
- Keep persistent app-level state under `user://` separate from portable project/card data unless explicitly included for portability.
- Continue reducing synchronous whole-library work from interactive Collaborator paths as conversation histories grow.
- Keep Generation Component semantics data-driven so new groups/components can be added without hard-coding Description or Personality behavior into the service.
- Treat the detailed Generation Concept Blueprint as preserved authoring source, not disposable intermediate text, so later template/model changes can regenerate the card without reconstructing the Collaborator session.

## Polish

- Continue improving semantic colour/theme consistency, keyboard navigation, detachable-window behaviour, multi-monitor use, resizing, and long-text editing.
- Improve visible progress/error states for potentially long AI operations and distinguish local context preparation from provider/model thinking time.

## Long-Term Ideas

- Expand graph tooling into richer character/route planning without contaminating exported card data.
- Make Character Collaborator capable of increasingly sophisticated project-wide creative planning while keeping explicit boundaries between brainstorming and canonical data.
- Continue supporting portable user-created templates/content and external AI-assisted authoring workflows.

## Deferred / Experimental Ideas

- More elaborate graph visualisation/layout automation beyond the current draggable anchor-based system.
- Optional advanced context compression strategies beyond the current explicit user-triggered summarisation model.
- Experimental provider-specific optimisations should remain opt-in until they can be implemented without weakening the generic OpenAI-compatible path.
