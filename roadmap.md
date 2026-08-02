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
- Rich-text styling must remain readable across supported platforms and should not depend on synthetic font effects that introduce glyph-rendering artifacts.
- Collaborator image attachments must be analysed by the configured Vision role first. The Text role receives a comprehensive Vision-derived description of the full scene, never the original image payload, and decides how to use that evidence according to the author's request.
- AI profiles may expose different Text and Vision model IDs; Vision-role requests must route through the dedicated `vision_model` while Text-role requests continue to use `model`.
- Text and Vision models may have different context/output limits; Vision jobs must use Vision-specific token limits rather than inheriting Text-model limits.
- Vision input preprocessing must preserve originals and only optimise genuinely oversized files; small images should pass through unchanged.
- File-dialog authoring state should survive application restarts instead of depending on Godot's process-local FileDialog state.

## Current Development Phase

**v0.15.10 development candidate — persistent FileDialog state**

The v0.15 line now has a usable long-form conversational authoring workflow with independent persistent chats and a strict Vision → Text image pipeline. v0.15.10 improves everyday desktop workflow by persisting FileDialog favourites, recent/history locations, last-used filesystem directory, layout/view choices, hidden-file preference, and sort choice across application relaunches while seeding Downloads as a convenient default location.

The running development build displays **v0.15.10**. Release metadata remains controlled by `release.sh` until a tagged release is promoted.

## Completed

### v0.15.10 — Persistent FileDialog State

- Added a shared `user://` FileDialog preference store independent of projects and release/update files.
- Persists Godot FileDialog favourites across app relaunches using the engine's shared favorite-list API.
- Persists recent/history directories with a bounded 20-folder history rather than allowing an unbounded list.
- Seeds the operating system's actual Downloads directory as a default quick location on first use when available.
- Persists the last-used filesystem directory for future open/save dialogs.
- Persists list/thumbnail display mode and hidden-file visibility.
- Persists the selected built-in FileDialog sort mode, including date/modified sorting, through a guarded UI-state bridge because Godot 4.6 does not expose sort mode as a public property.
- Tracks FileDialog nodes created throughout the app so the behaviour is shared rather than duplicated per workflow.
- Made the v0.15.9 Vision regression forward-compatible with later inherited app shells.
- Added dedicated v0.15.10 regression and CI coverage.

### v0.15.9 — Independent Vision Token Limits & Input Optimisation

- Added **Vision Context Window Tokens** to Character AI profiles independently of the Text model context window.
- Added **Vision Maximum Output Tokens** independently of the normal Text-model response limit.
- Vision jobs remap the dedicated Vision model and Vision token limits onto a temporary routed profile without mutating saved Text settings.
- Added preflight validation preventing Vision Maximum Output Tokens from exceeding or equalling a known Vision context window.
- Preserved `0` as an unknown Vision-context value for providers/models whose limit is not known.
- Added conservative automatic Vision-input optimisation: images at or below 4096 px on the longest edge and 8 MiB pass through unchanged.
- Oversized images are proportionally resized when needed and encoded to a temporary high-quality WebP solely for the Vision request.
- Original attachments are never modified, and temporary preprocessing files are removed after the synchronous payload conversion/queueing step.
- Added v0.15.9 Settings, generation-service, Workspace, app-shell, regression and dedicated CI coverage.

### v0.15.8 — Dedicated Vision-Model Routing

- Character Collaborator Vision jobs now copy the selected Vision-role profile and route the provider request through its dedicated `vision_model` value.
- Normal Text-role requests continue to use the profile's normal `model`; the stored profile is never mutated by Vision routing.
- A missing/blank Vision model now produces a clear Settings error instead of silently falling back to the Text model and sending it an unsupported image payload.
- Preserved the full-scene Vision analysis and provenance-tagged Vision → Text handoff introduced in v0.15.7.
- Added v0.15.8 regression and CI coverage verifying the model remap, non-mutating profile copy, missing-model guard, live service installation, and active shell.
- Made the v0.15.7 Vision regression forward-compatible with later inherited v0.15 shells.

### v0.15.7 — Collaborator Vision Pipeline

- Enforced the configured **Vision** provider role for Character Collaborator image attachments instead of allowing image analysis to blur into normal Text-role generation.
- Expanded Collaborator Vision analysis from appearance-focused extraction to a comprehensive full-scene description covering visible people/characters, appearance, clothing, expressions, poses, interactions, setting/environment, props/objects, readable text, lighting, composition, visual style, and the apparent action or situation.
- Required the Vision analyst to distinguish direct visual observations from uncertain interpretation rather than inventing relationships, intent, identities, emotions, or off-screen context.
- The original image payload is sent only to the multimodal Vision request; the separate Text Collaborator receives only the resulting description.
- Vision-derived context is explicitly labelled **VISION DESCRIPTION OF USER-ATTACHED IMAGE** so the Text model knows it is grounded visual evidence supplied by another model and must not pretend it inspected the original image itself.
- Stored Vision provenance including profile/model metadata and the raw Vision description alongside the wrapped Text-model context.
- Added clearer UI status showing which configured Vision profile/model is analysing the attachment and explaining the Vision → Text handoff.
- Added v0.15.7 regression coverage verifying Vision-role selection, full-scene analysis requirements, provenance tagging, live service installation, and the active v0.15.7 shell.

### v0.15.6 — Collaborator Rich-Text Rendering Fix

- Removed the Collaborator renderer's synthetic `RichTextLabel.push_bold()` path that could produce dark vertical marks inside coloured glyphs on affected systems.
- Preserved heading size hierarchy and semantic section colours without relying on synthetic bold rendering.
- Inline `**bold**` emphasis now uses a brighter theme-safe tint instead of the artifact-prone bold path.
- Native italics remain supported.
- Raw AI response text remains unchanged for persistence and Copy; only presentation rendering changed.
- Added v0.15.6 regression coverage preventing the synthetic bold path from returning to the Collaborator renderer.

### v0.15.5 — Independent Collaborator Session Persistence

- Added a versioned local Collaborator session store under `user://collaborator_sessions`.
- Every Collaborator conversation now autosaves independently of `.ccfproject` persistence.
- A chat started from a new or unsaved project survives closing and reopening Character Card Forge even if that project was never saved.
- Collaborator loads the local conversation library when opened, including draft/unlinked conversations and chats linked to other projects.
- Added optional linked project ID/name metadata without making the project the owner of the chat.
- Existing project-embedded Collaborator sessions are merged into the local library so older projects remain portable and migrate forward naturally.
- Project-linked conversations may still be included as a project snapshot when the project is explicitly saved, but chat autosave no longer calls `save_project()` or forces an otherwise-unsaved project to disk.
- The session selector distinguishes project-linked conversations from draft/unlinked chats.
- Added regression coverage that writes, reloads, merges, and removes local Collaborator conversations without any saved project.

### v0.15.4 — Collaborator Persistence, Behaviour Contract & Rich Text

- Added autosave after each meaningful Collaborator session change, including user messages, AI replies, regenerated variants, summaries, context changes, renames, and deletions.
- Added **Rename** and **Delete** controls for saved Collaborator conversations, with deletion scoped only to the chat session rather than generated characters or other project data.
- Strengthened the Collaborator system contract so established facts are preserved by default and contradictory ideas are clearly framed as alternate/rewrite directions.
- Added proportional response-depth guidance: small changes remain conversational while major design decisions may use deeper structured analysis.
- Added a non-pathologizing default for unusual traits, sexuality, habits, preferences, and behaviour unless psychological dysfunction is explicitly established or being explored.
- Added a restricted presentation contract for headings, emphasis, and labelled list sections.
- AI responses now render headings, italics, bold text, bullets, and semantic labels as native rich text rather than showing raw Markdown markers.
- Added restrained semantic colours for headings and common labels such as Behavior, Sample dialogue, Effect, Drawback/Warning, and Motive while keeping the raw response available for Copy and transcript persistence.

### v0.15.3 — Character Collaborator Chat UX

- Added automatic wrapping for long pasted/input text.
- Added clearly differentiated user and Collaborator message cards.
- Added selectable chat text, normal context-menu copying, and one-click whole-message Copy actions.
- Added visible in-chat working states for replies, summarisation, image analysis, and Workspace character generation.
- Improved auto-scroll after sending, generation start, and response completion by waiting for Godot layout updates before scrolling.

### v0.15.2 — Large Output Token Limits

- Removed the Settings UI's effective 131,072 Maximum Output Tokens ceiling.
- Raised the normal spinner range to 4,194,304 tokens and enabled manually entered values above that range for future models.
- Kept backend profile storage unbounded above rather than introducing a second hidden clamp.
- Added regression coverage explicitly requiring support for values above 131,072, including 384k-class output limits.

### v0.15.1 — Context Window Budgeting

- Added a separate Context Window Tokens setting to Character AI profiles.
- Kept Maximum Output Tokens as the response limit rather than treating it as total context capacity.
- Added unknown-context mode (`0`) that reports estimated input without incorrectly blocking sends.
- Added input allowance, output reserve, headroom and total-context reporting in Character Collaborator.
- Prevented oversized configured output reserves from collapsing the calculated input budget to a bogus one-token allowance.
- Added warning and critical thresholds before a known model context window is exhausted.

### v0.15.0 — Character Collaborator Foundation

- Added **Author → Character Collaborator…** as a detachable native tool window.
- Added persistent collaboration sessions with full local message history.
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