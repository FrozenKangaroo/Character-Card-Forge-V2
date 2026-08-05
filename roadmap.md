# Character Card Forge — Project Roadmap

## Project Vision

Rebuild Character Card Forge as a responsive, native Godot desktop application for creating, generating, editing, organising, importing, exporting, analysing, illustrating, and collaboratively developing AI roleplay character cards.

The original PyWebView V1 application remains a feature and behaviour reference, not an architecture specification. Useful V1 behaviour should be re-expressed as maintainable Godot-native systems with versioned external data and portable Character Card / `.ccfproject` content.

## Core Design Principles

- Godot-native desktop UI with detachable tool windows where useful.
- Character project JSON/files are the source of truth; the legacy V1 database is not.
- Versioned, externally inspectable templates, authoring schemas, lorebooks, series data, settings, project packages, Idea Notebook data, Collaborator source data, and interchange formats.
- Clear separation between character data, project-shared context, AI generation, providers, images, imports/exports, library indexing, and tooling.
- OpenAI-compatible and local/self-hosted Text, Vision, and Image providers remain first-class targets.
- Text/Vision provider roles and Image Generation providers stay independently configurable.
- New systems extend the central project model rather than create parallel character copies.
- Existing character/card data must not be destroyed by unchecked preview fields, failed reviews, disabled generation components, unrelated regeneration, partial imports, exploratory AI conversation, or unreviewed Collaborator output.
- Conversational brainstorming never becomes canonical project data until the user explicitly applies, generates, or imports it.
- Stable internal IDs should survive user-facing renames where practical.
- Brand-new Character Projects remain in memory until meaningful authored content exists. UUIDs, timestamps, Workspace state, configured templates, and untouched `Untitled` placeholders alone must never create a Library entry.
- Wider desktop windows should reveal more workspace rather than scale a fixed game-style canvas.
- Secondary workflows belong in grouped menus instead of an ever-growing wall of top-level buttons.
- V1 parity is judged by useful workflow capability, not literal screen-for-screen reproduction.
- AI Ideas target interactive Character Card / SillyTavern-style roleplay by default and normally establish a meaningful relationship or opening dynamic with literal `{{user}}`.
- AI Ideas preserve player agency without making ordinary openings unusably rigid: temporary scene logistics for `{{user}}` may be invented when they merely establish where/when the scene begins, but substantive `{{user}}` personality, backstory, profession, long-term motives/preferences, major history, or consequential reactions/decisions remain author-controlled unless explicitly established by the source premise.
- Conditional `{{user}}` choices such as `whether {{user}} confronts her` remain valid because they preserve the roleplayer's decision; direct forced reactions such as `{{user}} confronts her immediately` remain invalid unless source-authored.
- Generated ideas remain disposable until the user explicitly saves them. Persistent Idea Notebook material is versioned app-level authoring data independent of Character Projects, and saving one idea must never implicitly save the rest of a generated batch.
- Named Idea Notebooks organise saved material without replacing tags: notebook membership is one organisational axis while tags/search work across notebooks.
- Collaborator source handoffs preserve structured source snapshots and provenance rather than paste opaque text into private UI state.
- Multi-source Collaborator sessions keep every character, Idea, external card, and pasted source individually identifiable rather than flattening them into one opaque prompt. At most one existing Workspace character is the explicit refinement target; all other sources remain read-only references.
- Collaborator source ingestion preserves a raw snapshot for provenance/recovery and derives a separate AI-facing normalised snapshot. Normalisation must never destructively rewrite the author's original imported, attached, or pasted source.
- A distinct embedded `UserPersona`, user-profile, or roleplayer-persona section found in extracted/imported source is treated as chat-session residue by default and excluded from Collaborator AI context. This rule must not remove genuine character-source facts about that character's relationship or situation with `{{user}}`; `{{user}}` remains otherwise unspecified unless the current author explicitly supplies facts.
- Collaborator source-aware reasoning distinguishes **established source facts**, **author-requested changes**, and **new/proposed details**. Existing facts stay authoritative unless the author explicitly branches, retcons, advances, rewrites, or replaces them.
- A Collaborator source is read-only authoring context. Conversation, summarisation, or attachment removal must not silently mutate or erase the source snapshot.
- Collaborator completion routing is explicit: an occupied character is never overwritten by a completed Blueprint/draft without a later review/apply workflow, while genuinely empty placeholders may be safely reused.
- Existing-character refinement compares against the exact captured source snapshot. Selective application must preserve unselected data and must not overwrite newer manual edits silently.
- Branch/related-character Collaborator directions remain non-destructive by default; future/past versions, alternate routes, descendants, side-character promotions, connected characters, and same-setting characters must not casually overwrite their source.
- Alternate character routes should not require full duplicate cards when only a few fields differ; Linked Variants may inherit from a base while exports always materialise normal standalone cards.
- Visual graph layout metadata stays separate from authoritative character, relationship, and route data.
- External authoring tools and AIs should be able to hand CCF a partial character without being forced to generate filler for fields they do not know.
- Long-running AI collaboration must account for model context limits, reserve output space, preserve original local transcripts, and make lossy summarisation explicit to the user.
- Provider/model token limits remain data-driven; UI controls and generation stages must not impose obsolete hidden ceilings.
- Every Character-generation sub-request uses the active Text profile's authoritative Maximum Output Tokens allowance unless the user changes that profile setting.
- Concurrent AI work must preserve isolated request/job state. A shared scheduler may coordinate capacity, but unrelated Character, Collaborator, Idea, Vision, authoring-tool, and Image jobs must never share one mutable `_active_job`.
- Concurrent AI work must also be inspectable: users should be able to see what is running, queued, waiting for capacity, or blocked by dependencies, and selective cancellation must not silently clear unrelated workflows.
- Parallel generation must remain deterministic: dependency order and template order—not network completion timing—determine context and final assembly.
- Character Collaborator preserves established canon by default, deepens existing material before rewriting premises, and makes alternate/rewrite directions explicit.
- Collaborator conversations are independent local authoring documents; project association is optional metadata rather than ownership.
- Collaborator image attachments go through the configured Vision role first; the Text role receives a provenance-tagged description rather than the original image payload.
- Text and Vision models may have different context/output limits and must use their own role-specific settings.
- Vision input preprocessing preserves originals and only optimises genuinely oversized files.
- **Generate Character** uses the complete authoritative Workspace as source material while the active template and Generation Components define the generated output contract.
- Collaborator Blueprint handoff preserves one detailed canonical Generation Concept before template materialisation; direct field filling remains an explicit alternative.
- Alternative Greetings and Character Lorebook material are first-class character data as well as preserved authoring source.
- The live Workspace generation-service composition is a tested compatibility boundary. Compatibility is capability-based rather than an exact historical script filename check.
- Malformed, empty, interrupted, or non-JSON provider envelopes should fail as normal provider/network errors with usable Diagnostics rather than emitting repeated Godot JSON parser errors.
- Native engine/driver crashes are tracked separately from application-level provider failures and are never marked fixed without evidence.
- Forward+ is the standard desktop renderer. Compatibility/OpenGL remains an automatic fallback for systems that cannot initialise a supported RenderingDevice backend rather than the normal modern-desktop path.
- Normal Godot import/open operations leave the Git checkout clean.
- Release/update helpers prefer the repository checkout they are launched from and retain separate-copy syncing only as an explicit fallback.
- Every major supported workflow has representative cross-feature regression coverage; a focused feature test alone is not a release gate.
- Automated tests that exercise `user://` run in isolated temporary app-data directories.
- Generation reliability strategy is independent of Generation Mode/Style.
- Safe generation fails narrowly: accepted sections remain accepted, and missing required components receive focused repair rather than unrelated regeneration.
- Failed provider generations remain inspectable through credential-redacted Diagnostics containing request, raw response, assistant text, parse/validation state, termination reason, token usage, repair evidence, and trace.
- Deferred or awaited UI work must verify that its node, controls, and original `SceneTree` are still valid after every await before touching them.
- Detached tools that consume saved project data must receive save/change notifications rather than relying only on startup scans or stale private caches.
- Image provider discovery belongs to Image profiles and must never be stored in or resolved through Character Text/Vision profiles.
- Image Studio is a first-class main-navigation page. Its native `Window` controller may remain an implementation detail, but normal navigation must present the studio embedded in the main workspace.
- **Generate Prompt from Character** is an AI-authored Character Text-role workflow; deterministic Character → image-prompt construction remains an explicit **Build Local Fallback** rather than silently replacing the AI path.
- Passive Image Studio browsing, project loading, and character switching must never spend provider tokens; AI calls require an explicit user action.
- Long-form multiline authoring fields such as Image Prompt and Negative Prompt must wrap visually at the available editor width instead of requiring horizontal scrolling; visual wrapping must not mutate the stored text.

## Current Development Phase

**v0.15.37 development candidate — Multi-source Character Collaborator**

v0.15.37 promotes Collaborator's v0.15.33 single-source context into a versioned multi-source collection. One conversation can now keep several characters, saved/generated Ideas, pasted source material, and external Character Card JSON/PNG references distinct at the same time. Existing single-source sessions migrate into the new collection when opened rather than being abandoned or flattened.

At most one existing Workspace character may be the explicit **TARGET**. That target remains compatible with v0.15.36 Compare & Apply, conflict checking, Update Original, and Create Improved Copy. Every additional source is a read-only **REFERENCE** used for family, relationships, cast, scenario, setting, continuity, and ensemble reasoning without becoming an overwrite target. Per-source IDs, labels, types, roles, author intent and provenance stay individually visible, and completion lineage carries a compact summary of the full source set alongside the primary target provenance.

Source ingestion now uses a raw-versus-AI-facing boundary. Raw attached/pasted/extracted source is retained unchanged for provenance and recovery. A separate AI-facing snapshot is normalised before model context is assembled. Distinct `<UserPersona>`, User Persona/user-profile fields, and equivalent roleplayer-persona residue are excluded from that AI-facing copy by default so old chat-user details do not silently become the new `{{user}}` identity. Character-source statements that genuinely establish the character's relationship or situation with `{{user}}` remain valid and are not stripped simply because they mention `{{user}}`.

The normal Collaborator **Attach Files…** path now promotes recognised Character Card JSON/PNG/APNG files into structured sources without importing them into the Library. Non-card JSON continues through the normal text-attachment path and non-card images continue through Vision. **Paste Source…** accepts extracted text or Character Card JSON, **Add Saved Idea…** adds an Idea Notebook entry as another reference, and Workspace can add its current character to an open Collaborator conversation as another structured reference.

The running development build displays **v0.15.37**. Current work is runtime validation and polish of multi-source sessions, target switching, source persistence/reopen, Character Card attachment detection, saved-Idea addition, UserPersona exclusion, completion provenance, and real provider behavior.

Character Card Forge remains on Godot **4.7.1 stable** and Forward+ as the standard desktop renderer, with Compatibility/OpenGL fallback retained for unsupported RenderingDevice hardware. The previously observed Linux/X11 GL Compatibility crash remains classified as not reproduced after switching to Forward+, not universally proven fixed.

## Completed

### v0.15.37 — Multi-source Character Collaborator

- Extended the versioned Collaborator source model from one source to a collection of separately identified sources.
- Added one explicit existing-character TARGET plus any number of read-only REFERENCE sources without flattening their identities or provenance.
- Kept v0.15.36 Compare & Apply tied only to the explicit target while reference characters/Ideas/cards remain non-destructive context.
- Added automatic migration of older single-source Collaborator sessions into the multi-source representation.
- Added **Author → Add Current Character to Open Collaborator…** for building multi-character/family/cast reference sets from Workspace.
- Added **Add Saved Idea…** inside Collaborator for bringing Idea Notebook material into an existing conversation.
- Added **Paste Source…** for copied/extracted card text and Character Card JSON.
- Promoted recognised Character Card JSON/PNG/APNG selected through normal **Attach Files…** into structured Collaborator sources without importing them into the Library; retained normal text/Vision fallback for non-card files.
- Added raw source snapshots plus separate AI-facing normalised snapshots so source cleanup never destroys provenance.
- Added embedded UserPersona/user-profile exclusion while preserving actual character-established facts involving `{{user}}`.
- Added visible per-source role/type/label/exclusion reporting and explicit target switching for eligible Workspace character sources.
- Preserved compact multi-source lineage in Collaborator completion derivation provenance while retaining the primary-source compatibility contract expected by v0.15.35/v0.15.36.
- Added actual Character Card PNG round-trip regression coverage, isolated source-normalisation tests, broad regression inheritance, CI, and `docs/v01537-multi-source-collaborator.md`.

### v0.15.36-hotfix3 — Empty Project Save Guard

- Removed the premature disk save from the live **New Character** path while preserving stable in-memory project/character IDs.
- Preserved configured application-default-template assignment without making template selection alone count as authored content.
- Added a reusable project-persistence guard that distinguishes a never-saved empty shell from meaningful authored content.
- Added project-level content checks for names, summary/tags/series/shared context, relationships, workflows, and attachments.
- Reused v0.15.35 effective-empty-character semantics while treating real non-placeholder character names as meaningful for persistence.
- Changed Workspace Save so an unsaved empty project stays in memory, reports **Nothing to save yet**, emits no saved-project event, and creates no Library entry.
- Kept already-persisted projects saveable even if later cleared; the hotfix never silently deletes existing data.
- Added isolated real-main-scene persistence regression coverage, CI, broad manifest inheritance, and `docs/v01536-hotfix3-empty-project-save.md`.

### v0.15.36-hotfix2 — AI Ideas Agency / Backstory / POV Validation

- Corrected the false detached-POV trigger caused by generic `without {{user}}` secrecy wording.
- Made detached mode require explicit observer/narrator/world-NPC/omniscient/detached-viewpoint intent.
- Replaced broad supporting-role scanning with card-subject-focused identity validation.
- Accepted ordinary temporary `{{user}}` scene logistics while continuing to reject invented substantive user canon and forced meaningful reactions.
- Preserved conditional roleplayer choices.
- Made third-person identity checks accept the supplied character name, `the character`, or clean pronoun-led prose.
- Added semantic validation reporting to Generation Diagnostics.
- Added real-seed regression coverage and a new broad regression layer while retaining v0.15.36-hotfix1, Compare & Apply, Forward+, and historical gates.
- Added `docs/v01536-hotfix2-ai-ideas-agency-backstory.md`.

### v0.15.36-hotfix1 — Configured Default Template

- Fixed new project, Add Character, and missing-template recovery paths so the configured user-created default template wins before the built-in Default fallback.
- Kept existing characters that explicitly use the built-in Default unchanged.
- Hardened historical regression inheritance checks so later compatible hotfix shells remain valid.

### v0.15.36 — Collaborator Refinement Compare/Apply + Forward+

- Added **Compare & Apply to Source Character…** as an explicit destination for completed existing-character Collaborator work while retaining v0.15.35's non-destructive default.
- Added original/proposed comparison with independent selection for changed Generation Concept, generated template fields, Alternative Greetings, and Character Lorebook material.
- Added selective **Update Original** with stable-ID preservation, unselected-data preservation, and stale-source conflict checks.
- Restricted destructive update to same-character refinement directions; branch/related-character directions remain non-destructive.
- Added **Create Improved Copy** from the latest source state with a new stable identity and compatible provenance.
- Switched the desktop project default from GL Compatibility to **Forward+** while retaining Godot's OpenGL fallback for unsupported RenderingDevice hardware.
- Added focused regression coverage and `docs/v01536-collaborator-compare-apply-forward-plus.md`.

### v0.15.35 — Collaborator Character Completion & Project Integration

- Added explicit post-generation destination routing, safe empty-slot reuse, same-project/new-project destinations, pending-completion recovery, and source/derivation provenance preservation without occupied-character overwrite.

### v0.15.34 — Existing Character → Collaborator + Godot 4.7.1

- Added structured existing-character Collaborator sources, ten development directions, read-only source snapshots, derivation provenance, and moved the project/CI baseline to Godot 4.7.1 stable.

### v0.15.33-hotfix3 — AI Ideas User Agency Contract

- Added the first explicit AI Ideas user-agency contract, bounded semantic repair, source-authored action preservation, and conditional-choice support. v0.15.36-hotfix2 refines this rule to distinguish temporary scene logistics from substantive user canon.

### v0.15.33-hotfix2 — AI Ideas Notebook Capture Reliability

- Restored live AI Ideas completion capture for Idea Notebook save/develop actions across compatible generation-service instances.

### v0.15.33-hotfix1 — Structured Builder → Collaborator

- Added structured Builder ingredient/source handoff into Character Collaborator without flattening selected fields into opaque prose.

### v0.15.33 — Generic Collaborator Source Context

- Added versioned read-only structured Collaborator source snapshots/provenance for generated Ideas, saved Ideas, Structured Builder, and existing-character groundwork.

### v0.15.32-hotfix1 — AI Ideas Notebook Header Layout

- Fixed malformed AI Ideas action/status layout while preserving Idea Notebook behavior.

### v0.15.32 — Idea Notebook Foundation

- Added disposable generated batches, selective saving, named notebooks, Unfiled, tags/search, editing/move/archive/restore/delete, and app-level versioned persistence.

### v0.15.31 — AI Jobs Queue Visibility & Selective Cancellation

- Added inspectable running/queued/waiting/dependency states and selective cancellation across shared AI work.

### v0.15.30 — Image Prompt Word Wrapping

- Restored visual wrapping for Image Prompt and Negative Prompt without mutating stored text.

### v0.15.29 — Embedded Image Studio + AI Prompt Restoration

- Restored Image Studio as main navigation and Character Text-role **Generate Prompt from Character** beside deterministic Local Fallback.

### v0.15.28 — Image Studio Live Project and Provider State

- Added live project handoff/rescans, correct Image-profile routing, and persisted per-profile model/sampler discovery.

### v0.15.27 — Runtime Lifecycle and Warning Cleanup

- Removed reported GDScript shadow warnings and hardened deferred Collaborator scrolling against SceneTree/window lifecycle changes.

### v0.15.26 — Concurrent AI Scheduler + Collaborator Service Compatibility

- Added configurable overall/Text/Vision/Image/per-character concurrency, isolated workers, queued overflow, dependency-wave Safe Section parallelism, and capability-based Collaborator service compatibility.

### v0.15.25 — Character Generation Token Budget Invariant

- Made the active Text profile Maximum Output Tokens authoritative across Interview, Safe Sections, repairs, fidelity correction, and Fast Full Card.

### v0.15.24 — Live Safe Section Service Wiring

- Fixed live Workspace service composition and added real-main-scene coverage.

### v0.15.23 — Token Settings Regression Fix

- Restored Text/Vision token controls and modern large output values.

### v0.15.22 — Safe Section Build + Generation Diagnostics

- Added recommended Safe Section Build, Fast Full Card, focused repair, deterministic multi-group assembly, and credential-redacted Diagnostics.

### v0.15.21 — Unified Collaborator Attachments

- Added persistent text/subtitle/JSON/image reference attachments with token accounting, Vision routing, removal semantics, and documentation.

### v0.15.20 — Broad Regression Safety

- Added composable quick/release regression profiles, isolated app-data execution, and release gating.

### v0.15.19 — Release Checkout Selection

- Made release/update helpers prefer the current checkout with explicit separate-copy fallback.

### v0.15.18 — Checkout Hygiene + Warning Cleanup

- Added `.gd.uid` policy, canonical project serialization checks, checkout-clean CI, and warning cleanup.

### v0.15.17 — Blueprint Supplementary Materialisation

- Restored Interview review metadata and materialised Alternative Greetings/Lorebook data without overwriting accepted content.

### v0.15.16 — Generation Pipeline Restoration

- Restored Interview/Q&A, Builder precedence, Mode & Style, template enforcement, semantic repair, fidelity, fail-closed behavior, and current-client rebinding.

### v0.15.15 — Blueprint-First Collaborator Handoff

- Made detailed Generation Concept Blueprint the recommended Collaborator handoff while retaining Detailed Workspace Draft.

### v0.15.14 — Component-Driven Full Synthesis

- Added Generation Group/component-driven transformation planning from the complete Workspace source pool.

### v0.15.13 — Complete Synthesis Review + Responsiveness

- Added complete-result review and improved Collaborator context preparation/autosave responsiveness.

### v0.15.12 — Full Character Synthesis from Workspace

- Added full-Workspace synthesis while retaining selective tools; normal Generate Character later returned to the validated parity pipeline.

### v0.15.11 — Visible Vision Analysis Messages

- Made Vision results persistent, selectable, provenance-aware Collaborator transcript content.

### v0.15.10 — Persistent FileDialog State

- Persisted favourites, history, location, view mode, hidden-file state, and sorting across restarts.

### v0.15.9 — Independent Vision Limits & Input Optimisation

- Added separate Vision context/output limits and safe preprocessing for genuinely oversized images.

### v0.15.8 — Dedicated Vision Routing

- Routed Vision requests through the configured Vision model and produced clear missing-model errors.

### v0.15.7 — Collaborator Vision Pipeline

- Added full-scene Vision analysis and enforced the Vision-to-Text boundary.

### v0.15.6 — Collaborator Rich-Text Fix

- Removed synthetic bold rendering artifacts while preserving semantic presentation and raw stored text.

### v0.15.5 — Independent Collaborator Persistence

- Added versioned local chat storage under `user://collaborator_sessions` with optional project links.

### v0.15.4 — Collaborator Persistence & Behaviour Contract

- Added autosave, rename/delete, canon-preservation guidance, proportional response depth, and semantic rich text.

### v0.15.3 — Collaborator Chat UX

- Added wrapped input, distinct user/AI cards, selectable text, visible work states, copying, and reliable deferred scrolling.

### v0.15.2 — Large Output Token Limits

- Removed the old effective 131,072 output-token UI ceiling and supported modern large-output models.

### v0.15.1 — Context Window Budgeting

- Added separate context configuration, output reserve/headroom, unknown-context mode, and warnings.

### v0.15.0 — Collaborator Foundation

- Added detachable freeform collaboration, reference context, summarisation, response variants, and explicit Workspace handoff.

### v0.14.22 — Shared Graph Canvas

- Added reusable draggable graph cards, anchors, labelled connections, Relationship Graph, and Route/Timeline editing.

### v0.14.21 — `.ccfchar` Interchange

- Added versioned partial/full external character authoring interchange with review-first import.

### v0.14.20 — Relationship Graph + Linked Variants

- Added labelled relationship graphs and sparse inheriting variants that export as complete standalone cards.

### v0.14.19 — Live Idea Generator Wiring

- Rebound the visible Idea Generator to the current validation/repair service.

### v0.14.18 — User-Centric Idea Generation

- Reframed Ideas around interactive roleplay and literal `{{user}}` involvement.

### v0.14.17 — Detachable Lorebook Manager

- Added a native non-modal multi-monitor-friendly Lorebook tool window.

### v0.14.16 — Idea Identity + POV Validation

- Added identity/source anchoring and repair for viewpoint-character replacement.

### v0.14.15 — Lorebook Generation + Trigger Tools

- Added scoped lorebook generation context, activation rules, ordering, budgets, Trigger Preview, and transfer tools.

### v0.14.14 — Focused Character Builders

- Added Appearance, Personality, and Scene builders alongside Full Character Builder.

### v0.14.13 — Idea POV Safety

- Kept AI Ideas in neutral third-person design prose while preserving literal `{{user}}`.

### v0.14.12 — Unified Idea Generator

- Combined AI Ideas and Structured Builder into one workflow.

### v0.14.11 — Structured Idea Builder

- Restored V1-style ingredients, locks, randomisation, custom values, multi-select fields, editable pools, and reset controls.

### v0.14.10 — Related Character / AI Variation

- Added independent related/transformed character creation with source/project/relationship provenance.

### v0.14.9 — Library Assignment UX

- Added existing-folder/collection pickers and simplified filtering/navigation.

### v0.14.8 — Manual Guided Alternative Greetings

- Added repeatable, reorderable Alternative Greetings with Character Card round-trip support.

### v0.14.7 — Manual Guided Component Parity

- Made Manual Guided follow active Generation Components with per-character/project state isolation.

### v0.14.6 — Preview Selection Safety

- Ensured unchecked Preview rows write nothing and current user edits remain authoritative.

### v0.14.5 — Grouped Navigation + Lorebook Foundation

- Added grouped menus and Project/Character Lorebook editing.

### v0.14.4 — Manual Guided

- Restored template-aware no-AI authoring across core and future-facing fields.

### v0.14.3 — Recoverable Generation Review

- Preserved parseable failed-review output for import, editing, and regeneration rather than discarding it.

### v0.14.2 — Character Transfer + Text Convention

- Added Move/Copy between projects and consistent multiline input behaviour.

Detailed per-release implementation notes remain in versioned docs, pull requests, tests, and Git history.

## In Progress

- Runtime-test v0.15.37 with real multi-source Collaborator sessions: target character plus additional Workspace characters, saved/generated Ideas, pasted extraction text, and Character Card JSON/PNG sources. Confirm source roles survive save/reopen and long conversations without being flattened.
- Runtime-test embedded UserPersona exclusion against real extracted cards from JSON, PNG and copy/paste. Confirm raw source remains inspectable, AI-facing context excludes roleplayer residue, and legitimate character-to-`{{user}}` relationship/situation facts remain intact.
- Runtime-test target switching and v0.15.36 Compare & Apply from a multi-source session; only the explicit Workspace target may be updated while reference sources remain read-only.
- Confirm completion/refinement provenance carries the compact v0.15.37 source-set lineage and remains compatible with older derivation metadata.
- Runtime-test v0.15.36-hotfix3 by creating and abandoning blank projects, pressing Save while blank, then adding project-level and character-level content and confirming first persistence occurs only after meaningful authoring.
- Confirm existing saved projects remain normally saveable after content is deliberately cleared and that old empty projects are never auto-deleted by the hotfix.
- Runtime-test v0.15.36-hotfix2 with the reported secrecy-style AI Ideas premise and additional real-provider batches. Confirm temporary scene logistics are accepted, invented durable user canon is rejected, supporting NPC roles do not falsely redefine the card subject, and valid batches do not incur unnecessary repair requests.
- Confirm failed/repaired Idea batches now retain a useful semantic validation report in Diagnostics.
- Runtime-test v0.15.36-hotfix1 configured-default-template behavior for new projects, Add Character, and missing-template fallback with real user templates.
- Runtime-test v0.15.36 Compare & Apply with real Collaborator Blueprint and Detailed Workspace Draft completions: selective changes, Update Original, Create Improved Copy, stale-source conflict handling, pending-completion reopen, and branch-intent safeguards.
- Continue normal Linux/X11 use under Forward+ and treat the old `BadAlloc` / `glXMakeCurrent failed` crash as **not reproduced after renderer change** until enough runtime evidence supports closing it; verify automatic Compatibility fallback remains usable on unsupported hardware.
- Runtime-test v0.15.35 completion routing with real Collaborator Blueprint and Detailed Workspace Draft generations: empty-slot reuse, occupied same-project creation, new-project Library creation, cancel/reopen pending completion, and project-switch clearing.
- Runtime-test v0.15.34 Existing Character → Collaborator across refine, future/past, descendant, side-character, connected-character and same-setting directions; confirm source cards remain unchanged where appropriate and provenance survives completion/refinement.
- Runtime-test v0.15.33-hotfix2 with a real AI Ideas batch and confirm visible generated cards enable **Save Generated Ideas…** and **Develop Generated Idea…**, with selective saving still opt-in only.
- Runtime-test v0.15.33 generated/saved Idea Collaborator sources through long conversations, restart persistence, summarisation, and attachment removal; first-class source snapshots must remain intact and continue informing later replies.
- Real-provider test malformed/empty/truncated API envelopes and confirm they produce one actionable provider failure/Diagnostics record rather than repeated Godot `Parse JSON failed` errors.
- Runtime-test v0.15.32 Idea Notebook through a real AI Ideas batch: selective save, multi-save, restart persistence, named notebooks/tags/search, edit/move/archive/restore, and non-auto-save behavior.
- Verify deleting a named Idea Notebook retains every saved idea in Unfiled and Notebook data stays outside portable Character Projects unless explicitly used as authoring input.
- Runtime-test v0.15.31 with real provider calls while Character generation, Collaborator, Ideas, Vision, AI image-prompt generation, and Image generation run concurrently; verify running/queued/capacity/dependency states and selective cancellation.
- Runtime-test parallel Safe Section Build through Interview/Q&A, multiple Output Groups targeting one field, a separate Sexual Traits group, and varied completion order while watching AI Jobs.
- Verify First Message visibly waits for Scenario and later dialogue/greeting sections wait for intended dependencies in a real custom template.
- Runtime-test the real Character AI Text provider plus Stable Diffusion/Forge provider: AI-authored image prompt, optional negative prompt, prompt wrapping, cached checkpoint/sampler lists, image generation, and shared AI Jobs visibility.
- Compare **Generate Prompt from Character** against **Build Local Fallback** across sparse and detailed characters.
- Test Vision and Image global-participation toggles with cloud Text plus local Vision/Stable Diffusion.
- Compare real-world latency, rate-limit behavior, completeness, and provider cost between sequential Safe Build, parallel Safe Build, and Fast Full Card.
- Deliberately provoke section failure/cancellation while siblings are active and confirm successful isolated results are not cross-contaminated.
- Continue real-provider Diagnostics testing, including missing required components, content filtering, output-limit exhaustion, and retry behavior.
- Runtime-test unified Collaborator attachments with TXT/Markdown, SRT, ASS/SSA, JSON, and image references through save/reopen and Blueprint handoff.
- Confirm generated Interview/Q&A review responses and Manual-vs-AI provenance survive generation and save/reopen.
- Validate Blueprint supplementary compatibility materialisation without overwriting manually populated Alternative Greetings/Lorebooks.
- Continue profiling very long Collaborator sessions for preparation, rendering, autosave, Blueprint generation, and direct-draft responsiveness.
- Runtime-test `python3 tools/run_regression_suite.py --profile quick` and `--profile release` on the normal Linux/Godot machine and confirm real `user://` data remains untouched.
- Runtime-test `release.sh` and confirm the broad release gate runs before staging/tagging and fails closed.
- Continue hardening forward-compatible tests so later shells/services cannot drop historical capabilities or hotfix invariants.
- Continue V1 parity review where V1 still has useful workflows V2 has not surpassed.

## Next Up

- Improve source precedence/conflict presentation after real multi-source use: show conflicting facts and author resolutions clearly without inventing a hidden precedence order.
- Consider multi-selection for saved Idea/source pickers and denser source-list controls if family/cast sessions make one-at-a-time addition cumbersome.
- Add optional provider/API execution pools so profiles sharing one cloud provider can share a provider-specific concurrency/rate-limit ceiling.
- Add optional local hardware pools so Vision and Image providers using the same GPU can share a configurable resource limit.
- Extend AI Jobs with pause/resume, priority, move-to-front/reorder controls, richer parent/child progress, and clearer project/character names.
- Consider round-robin fairness refinements so one large parent build cannot dominate all eligible Text slots.
- Consider a future **Custom Section Build** strategy for user-defined request batches while retaining component-level validation and deterministic assembly.
- Expand Diagnostics into optional recent-attempt history/retry tooling if real provider testing shows persistent traces are useful.
- Evaluate a pending-message attachment strip and optional per-message attachment association while retaining long-lived Reference Context.
- Keep the representative regression registry aligned with the actual supported feature surface.
- Perform a deliberate canonical GDScript UID migration later and replace the temporary ignore policy with checked-in stable UIDs and churn detection.
- Decide whether Blueprint supplementary material needs a dedicated review dialog or existing Alternative Greetings/Lorebook tools provide sufficient review.
- Revisit full-Workspace synthesis only if it composes through the validated parity pipeline rather than bypassing it.
- Improve visible reporting of exactly which Generation Groups/components participated in a result.
- Clarify the distinction between Blueprint handoff, Detailed Workspace Draft, Generate Character, Controlled Build, AI Suggest, and manual authoring.
- Continue relationship/route graph and Linked Variant usability testing.

## Planned Features

- Preserve source/relationship provenance for Collaborator-created characters while ensuring each created/exported character remains a complete standalone card. Suggest appropriate Relationship Graph edges without silently making them canonical.
- Extend multi-source Collaborator after runtime use with richer conflict-resolution/source-selection UX where it improves family, relationship, cast, scenario, continuity, and ensemble development without weakening one-target safety.
- Later expose derivation/lineage history such as future versions, side-character promotions, descendants, and characters created from a saved idea, while keeping exported card data independent of that authoring history.
- Further Library organisation, search/filter polish, and large-library performance work.
- More template authoring/validation tools and clearer documentation of generation contracts and dependencies.
- Stronger import/export diagnostics and compatibility reporting for external Character Card ecosystems.
- Additional provider capability discovery where providers expose reliable metadata.
- Continued V1 workflow parity where it improves V2 rather than reproducing obsolete architecture.
- More robust queue persistence/recovery only if future server-owned or long-running generation workflows require it; API keys remain local and are never moved into portable projects.

## Level and Content Tools

Character Card Forge is an authoring application rather than a level-based game. The equivalent content-tool priority is externally editable, versioned templates, `.ccfchar` interchange, project packages, lorebooks, Idea Notebook entries, Collaborator source snapshots, and schema/editor tooling. Loading and saving should continue to use the same underlying data models exposed to authoring tools.

## Technical Improvements

- Keep generation services modular and preserve older project/card compatibility as schemas evolve.
- Treat runtime generation-service composition as a capability-tested compatibility boundary.
- Keep important historical hotfix behavior as active-leaf regression invariants rather than assuming an old class remains in every later inheritance chain.
- Keep first-save project persistence content-aware: never-saved empty shells stay in memory, while already-persisted projects are never silently deleted or blocked from ordinary Save.
- Keep multi-source Collaborator collections versioned and backwards-compatible. Never flatten distinct source IDs/types/roles/provenance merely to fit an older single-source prompt shape.
- Maintain a single explicit existing-character refinement target while allowing arbitrary read-only references; legacy completion/refinement APIs may receive the primary target plus compact multi-source lineage metadata rather than losing the rest of the source set.
- Keep raw Collaborator source evidence separate from AI-facing normalised source data. Embedded user-persona cleanup happens only at the model-context boundary and remains visible/auditable through exclusion metadata.
- Treat Character Card detection on normal attachment paths as a promotion step, not a replacement for attachments: non-card JSON must continue as text context and non-card images must continue through Vision.
- Maintain one authoritative Character Text output budget per queued generation job and reassert it at request time.
- Keep each concurrent worker's request, retry, repair, Diagnostics, cancellation, and parent-state data isolated.
- Expose scheduler/job state through stable inspectable records rather than having UI scrape visual status strings.
- Route selective cancellation back through the owning worker/service so unrelated queues remain intact and each subsystem retains authority over its cleanup state.
- Keep dependency graphs data-driven and detect cycles/invalid references without deadlocking a build.
- Preserve frozen wave context and deterministic template-order assembly for parallel generation.
- Maintain the versioned representative regression registry as a release compatibility boundary across unrelated app areas.
- Keep local regression subprocesses isolated from real HOME/XDG/AppData state.
- Keep strict wrappers/import gates for Godot cases where logged script/assertion failures may not produce a nonzero exit code.
- Continue warning-as-error GDScript hygiene on Godot 4.7.x without hiding warning categories globally.
- Audit awaited/deferred UI callbacks for node/tree validity whenever windows or views can be replaced dynamically.
- Keep detached tools synchronised through explicit save/settings signals and stable IDs, not only startup scans.
- Keep Image capability caches per Image profile and normalise them before persistence.
- Keep Character Text/Vision and Image profile lookup paths separate at every UI/service boundary.
- Keep Image Studio's embedded-page presentation as a tested user-facing contract even when its controller remains implemented as a Window internally.
- Preserve the explicit-action boundary for AI image prompting: passive refresh is provider-free, Generate Prompt uses Text AI, and Local Fallback never calls a provider.
- Keep Image Prompt and Negative Prompt as multiline wrapped editors; test actual visual line wrapping rather than relying only on source-level configuration.
- When replacing/upgrading an Image Studio controller, reattach the current controller content to the embedded host rather than reopening or exposing the hidden native Window.
- Prefer capability/user-contract regression assertions over fixed-depth inheritance or assumptions about exact historical script filenames.
- Keep normal Godot import/open operations checkout-clean.
- Replace the temporary `.gd.uid` ignore policy with a deliberate checked-in canonical set when that migration occurs.
- Keep release/update helper executable modes under version control.
- Keep persistent app-level state under `user://` separate from portable project/card data unless explicitly included for portability.
- Keep Idea Notebook persistence independent of Character Projects and version both the library index and individual saved-idea records so later source/provenance fields can evolve compatibly.
- Keep Idea Notebook completion capture bound to the live generation-service topology rather than one assumed worker reference; embedded legacy-controller rebinding must not make visible AI results unavailable to save/develop workflows.
- Keep AI Ideas agency/backstory validation focused on durable user canon and consequential responses rather than banning harmless temporary scene logistics. Preserve explicit source-authored facts and conditional/hypothetical choices.
- Keep detached-POV detection explicit and role-based; generic phrases such as `without {{user}} realising` must remain normal user-centric secrecy premises.
- Keep AI Ideas card-subject validation focused on the generated character rather than supporting NPC terms mentioned in the role description.
- Keep Collaborator source seeding as a public structured capability instead of directly manipulating private composer/session controls from Idea Notebook or Workspace.
- Keep the primary Collaborator source separate from ordinary `context_items`; attachments may be removed or summaries rebuilt without changing the source snapshot.
- Keep Collaborator source formats versioned and backwards-compatible so multi-source workflows extend rather than replace existing source-aware conversations.
- Keep completion payloads project-scoped, preserve already-generated payloads when destination selection is postponed, and never expose the empty-slot replacement route once meaningful authored content exists.
- Compare/refinement writes must be selection-based, preserve stable IDs where updating the original, and conflict-check selected fields against the captured source before destructive application.
- Improved-copy creation must start from the latest source state so unrelated manual edits survive while selected proposal changes are layered on top.
- Keep branch/related-character derivations non-destructive unless a future explicit migration/retcon tool defines stronger semantics.
- Validate provider envelopes before inherited parsing/diagnostic layers, retain raw credential-safe evidence, and report network/malformed-envelope failures once through the normal retry/failure path.
- Keep Forward+ as the standard desktop renderer while retaining explicit Compatibility fallback for unsupported RenderingDevice hardware; continue observing the former GLX crash separately from application/API failures.
- Continue reducing synchronous whole-library work from interactive Collaborator paths.
- Keep attachment decoding/classification separate from UI composition and project-write boundaries.
- Keep Generation Component and section-dependency semantics data-driven.
- Treat Generation Concept Blueprint as preserved authoring source rather than disposable intermediate text.
- Carry `generation.template_id` through every character-creation handoff.
- Keep supplementary Blueprint materialisation separate from strict template-field validation unless the schema explicitly models it.
- Keep Diagnostics credential-safe before UI, clipboard, or disk exposure.

## Polish

- Improve semantic colour/theme consistency, keyboard navigation, detachable-window behavior, multi-monitor use, resizing, and long-text editing.
- Improve visible progress/error states for long AI operations and distinguish queue wait, local preparation, provider thinking, repair, and validation time.
- Improve queue labels so project, character, workflow, role, provider, model, section, and dependency state are legible without opening Diagnostics.
- Improve Idea Notebook browsing as real libraries grow, including denser cards/list options and multi-selection if runtime use shows the need.
- Improve source-aware Collaborator UX with clearer source/provenance summaries, conflict presentation, target/reference guidance, and completion/refinement guidance as multi-source runtime use matures.
- Continue replacing silent button no-ops with visible actionable status messages.

## Long-Term Ideas

- Expand graph tooling into richer character/route planning without contaminating exported card data.
- Make Character Collaborator capable of increasingly sophisticated project-wide creative planning while keeping explicit brainstorming/canonical boundaries.
- Add navigable creative lineage such as **Characters created from this Idea**, **Ideas involving this character**, future/past variants, side-character promotions, descendants/family trees, and related Collaborator sessions.
- Continue supporting portable user-created templates/content and external AI-assisted authoring workflows.
- Consider durable server-owned background jobs for future remote/mobile workflows while keeping generation logic shared and credentials server-side; this is separate from the current local desktop scheduler.

## Deferred / Experimental Ideas

- The standalone v0.15.12–v0.15.14 full-Workspace synthesis shortcut is not the normal Generate Character path because it bypassed the established parity/validation pipeline. Any revival must compose with that pipeline.
- Provider-specific concurrency heuristics remain opt-in until CCF can model provider limits without weakening the generic OpenAI-compatible path.
- Shared GPU resource pools are deferred until real local Vision/Image testing establishes the necessary controls.
- Persistent local queue recovery across application restarts is deferred; current queues are process-local.
- More elaborate graph layout automation beyond the current draggable anchor-based system.
- Advanced context compression beyond explicit user-triggered summarisation.
