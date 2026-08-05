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
- Existing character/card data must not be destroyed by unchecked preview fields, failed reviews, disabled generation components, unrelated regeneration, partial imports, or exploratory AI conversation.
- Conversational brainstorming never becomes canonical project data until the user explicitly applies, generates, or imports it.
- Stable internal IDs should survive user-facing renames where practical.
- Wider desktop windows should reveal more workspace rather than scale a fixed game-style canvas.
- Secondary workflows belong in grouped menus instead of an ever-growing wall of top-level buttons.
- V1 parity is judged by useful workflow capability, not literal screen-for-screen reproduction.
- AI Ideas target interactive Character Card / SillyTavern-style roleplay by default and normally establish a meaningful relationship or opening dynamic with literal `{{user}}`.
- AI Ideas preserve player agency: unless the author explicitly establishes a `{{user}}` fact/action in the source premise, generated concepts and roleplay hooks may create choices, uncertainty, tension, and pressure around `{{user}}` but must not decide `{{user}}`'s actions, dialogue, thoughts, feelings, consent, reactions, intentions, or decisions.
- Generated ideas remain disposable until the user explicitly saves them. Persistent Idea Notebook material is versioned app-level authoring data independent of Character Projects, and saving one idea must never implicitly save the rest of a generated batch.
- Named Idea Notebooks organise saved material without replacing tags: notebook membership is one organisational axis while tags/search work across notebooks.
- Collaborator source handoffs preserve structured source snapshots and provenance rather than paste opaque text into private UI state.
- Collaborator source-aware reasoning should distinguish **established source facts**, **author-requested changes**, and **new/proposed details**. Existing facts stay authoritative unless the author explicitly branches, retcons, advances, rewrites, or replaces them.
- A Collaborator source is read-only authoring context. Conversation, summarisation, or attachment removal must not silently mutate or erase the source snapshot.
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

**v0.15.33-hotfix3 development candidate — AI Ideas User Agency Contract**

v0.15.33-hotfix3 strengthens AI Ideas so generated concepts and roleplay hooks define the generated character and situation without deciding how the future roleplayer-controlled `{{user}}` behaves. Every queued Idea request receives an explicit User Agency Contract, and the existing identity/POV semantic-validation pipeline now also checks common direct `{{user}}` actions/reactions, prescriptive `must`/`should` language, and asserted emotional states.

The contract deliberately preserves author-established setup. If the source premise explicitly says `{{user}}` catches, sees, leaves, confronts, or otherwise does something, the Idea Generator may carry that fact forward; it still must leave what `{{user}}` does next open. Conditional and hypothetical choices such as **whether `{{user}}` confronts her** or **if `{{user}}` chooses to investigate** remain valid because they preserve roleplayer agency.

Agency violations use the existing single bounded semantic-repair pass rather than a parallel generation path. The repair request receives the same agency contract and must preserve valid source facts while reopening any AI-invented `{{user}}` behavior.

v0.15.33-hotfix2 Idea Notebook capture, v0.15.33-hotfix1 Structured Builder → Collaborator, v0.15.33 source context/provider hardening, v0.15.31 AI Jobs, and v0.15.26 scheduler/Safe Sections remain layered underneath. **v0.15.34 remains reserved for Existing Character → Collaborator**.

The separate Linux/X11 GL Compatibility crash (`BadAlloc` → `glXMakeCurrent failed` → signal 11) remains under investigation and is not claimed fixed by this hotfix.

The running development build displays **v0.15.33-hotfix3**. Release metadata remains controlled by `release.sh` until a tagged release is promoted.

## Completed

### v0.15.33-hotfix3 — AI Ideas User Agency Contract

- Added an explicit **User Agency Contract** to AI Ideas system/user prompts so `{{user}}` remains controlled by the person roleplaying.
- Extended the existing identity/POV semantic validator across `concept` and `roleplay_hook` to reject common AI-invented `{{user}}` actions/reactions, prescriptive behavior, and asserted feelings/states.
- Preserved `{{user}}` actions explicitly established by the source premise as valid setup while keeping subsequent choices open.
- Allowed conditional/hypothetical phrasing such as **whether `{{user}}` confronts her** and **if `{{user}}` chooses to investigate** so open roleplay hooks are not flattened into vague prose.
- Fed agency violations into the existing bounded semantic-repair pass and appended the same agency rules to repair prompts.
- Added `CCFGenerationServiceV01533Hotfix3` above the current provider-hardening / AI Jobs / scheduler stack and installed it across current Workspace AI workers.
- Preserved v0.15.33-hotfix2 Idea Notebook completion capture and v0.15.33-hotfix1 Structured Builder → Collaborator behavior.
- Added focused prompt/validation/repair/live-wiring regression coverage, `docs/v01533-hotfix3-ai-ideas-user-agency.md`, and `regression_suites_v01533_hotfix3.json`.

### v0.15.33-hotfix2 — AI Ideas Notebook Capture Reliability

- Fixed successful AI Ideas batches being visible in the generator while Idea Notebook still reported no completed batch and kept **Save Generated Ideas…** disabled.
- Restored **Develop Generated Idea…** availability for the same captured batch without automatically saving it.
- Kept `ideas` as the current canonical Idea-generation job type and added only a forward-compatible alias rather than rewriting the established generation contract.
- Made the Notebook completion bridge listen across compatible live Workspace generation services instead of assuming the embedded legacy controller can only ever complete through one worker reference.
- Refreshes capture wiring after concurrent-client rebinding and immediately before/after opening the unified Idea Generator, where legacy controller service rebinding can occur.
- Added a real-main-scene regression that emits `job_completed` through a second live generation service, verifies Save/Develop controls enable and the status updates, and proves capture alone does not persist anything.
- Advanced the broad regression default to `regression_suites_v01533_hotfix2.json` and documented the corrected diagnosis in `docs/v01533-hotfix2-ai-ideas-notebook-capture.md`.

### v0.15.33-hotfix1 — Structured Builder → Collaborator

- Added **Develop in Collaborator** beside **Build Idea into Main Concept** in Structured Builder.
- Preserved selected/typed ingredients, stable field IDs, labels, multi-select metadata, and custom instructions as read-only structured Collaborator source context.
- Kept Structured Builder source distinct from generated ideas, saved Notebook ideas, and existing-character source groundwork.
- Kept v0.15.34 reserved for the larger Existing Character → Collaborator workflow.

### v0.15.33 — Generic Collaborator Source Context

- Added versioned first-class Collaborator `source_context` snapshots with stable source IDs, source type, structured snapshot, provenance, capture time, and author intent.
- Added source types for generated AI Ideas, saved Idea Notebook entries, and existing-character schema groundwork.
- Kept source snapshots read-only and separate from removable attachments, messages, and lossy conversation summaries.
- Added model-facing source rules that distinguish established source facts, author-requested changes, and new/proposed details.
- Added a visible Source panel and source-specific context-token accounting to Character Collaborator.
- Persisted source-aware conversations through the existing independent Collaborator session store without changing historical no-source sessions.
- Added **Develop Generated Idea…** with a chooser for the latest completed AI Ideas batch; the selected idea is not automatically saved to Idea Notebook.
- Added **Develop in Collaborator** to saved Idea Notebook entries while preserving stable Idea/Notebook provenance.
- Made Idea/Notebook handoff passive so opening the source conversation does not immediately queue an AI request.
- Established the existing-character source API for v0.15.34 without prematurely adding its Workspace UI or derivation-intent workflow.
- Limited v0.15.33 to one primary source per conversation; multi-source work remains v0.15.37.
- Added `CCFGenerationServiceV01533` across current concurrent workers to catch empty/malformed/non-JSON provider envelopes before inherited parser layers, retain raw HTTP/network diagnostics, and use existing bounded retry behavior.
- Preserved the v0.15.32-hotfix1 AI Ideas header layout, v0.15.32 Idea Notebook, v0.15.31 AI Jobs, v0.15.26 scheduler/Safe Sections, Collaborator attachments, Vision routing, Blueprint handoff, and existing app-level/project boundaries.
- Added `docs/v01533-collaborator-source-context.md`, strict source/provider regression coverage, a focused v0.15.33 workflow, and the v0.15.33 broad regression manifest.

### v0.15.32-hotfix1 — AI Ideas Notebook Header Layout

- Replaced the malformed AI Ideas `HFlowContainer` action strip with a compact button row and separate full-width batch-status row so status text cannot collapse to a one-character column or stretch the tab vertically.
- Added screenshot-failure-specific layout regression coverage while preserving all Idea Notebook behavior.

### v0.15.32 — Idea Notebook Foundation

- Added **Idea Notebook** beside AI Ideas and Structured Builder.
- Added explicit selective saving for generated batches; generation remains disposable until the user chooses what to keep.
- Preserved structured generated title, character identity/role, source anchor, roleplay hook, concept, tags, and available generation provenance.
- Added versioned app-level storage under `user://character_card_forge/idea_notebook` with a library index and individual idea JSON files.
- Added named notebook create/rename/delete, built-in **All Ideas** and **Unfiled**, notebook counts, search, tag filtering, editing, move, archive/restore, delete, and **Use as Main Concept**.
- Made notebook deletion non-destructive: its ideas become Unfiled.

### v0.15.31 — AI Jobs Queue Visibility & Selective Cancellation

- Added a collapsible **AI Jobs (N)** panel with running, coordinating, queued, capacity-waiting, dependency-waiting, and completed-child states.
- Added workflow/stage, role, provider/model, queue-position and dependency details where available.
- Added selective per-job cancellation without clearing unrelated worker queues; Safe child cancellation targets its parent build.
- Surfaced Image Prompt/Image Generation work through the shared jobs view while retaining subsystem-owned cleanup.

### v0.15.30 — Image Prompt Word Wrapping

- Restored actual visual word wrapping for Image Prompt and Negative Prompt without mutating stored prompt text.

### v0.15.29 — Embedded Image Studio + AI Prompt Restoration

- Restored Image Studio as a main-navigation page and restored Character Text-role **Generate Prompt from Character** alongside deterministic **Build Local Fallback**.
- Kept passive browsing provider-free and preserved v0.15.28 project/provider-state fixes.

### v0.15.28 — Image Studio Live Project and Provider State

- Added live Workspace-save project handoff, real project rescans, correct Image-profile routing/default storage, and persisted per-Image-profile model/sampler discovery.

### v0.15.27 — Runtime Lifecycle and Warning Cleanup

- Removed reported GDScript shadow warnings and made deferred Collaborator scrolling safe when its window leaves the SceneTree.

### v0.15.26 — Concurrent AI Scheduler + Collaborator Service Compatibility

- Added configurable overall/Text/Vision/Image/per-character concurrency, isolated workers, queued overflow, and dependency-wave parallel Safe Section generation.
- Replaced Collaborator's exact historical script check with capability-based current-service compatibility.

### v0.15.25 — Character Generation Token Budget Invariant

- Made the active Text profile Maximum Output Tokens authoritative across Interview, Safe Sections, repairs, fidelity correction, and Fast Full Card; removed the historical 2,600-token Interview ceiling.

### v0.15.24 — Live Safe Section Service Wiring

- Fixed the live Workspace retaining an old service and added real-main-scene composition coverage.

### v0.15.23 — Token Settings Regression Fix

- Restored Text and Vision token controls and modern large output values.

### v0.15.22 — Safe Section Build + Generation Diagnostics

- Added recommended Safe Section Build, Fast Full Card, focused component/field repair, deterministic multi-group assembly, and credential-redacted Diagnostics.

### v0.15.21 — Unified Collaborator Attachments

- Added persistent text/subtitle/JSON/image references with token accounting, Vision routing, removal semantics, and documentation.

### v0.15.20 — Broad Regression Safety

- Added composable quick/release regression profiles, isolated app-data execution, and release gating.

### v0.15.19 — Release Checkout Selection

- Made release/update helpers prefer the current checkout and retained explicit separate-copy syncing.

### v0.15.18 — Checkout Hygiene + Warning Cleanup

- Added `.gd.uid` policy, canonical project serialization checks, checkout-clean CI, and warning cleanup.

### v0.15.17 — Blueprint Supplementary Materialisation

- Restored Interview review metadata and materialised Alternative Greetings/Lorebook data without overwriting accepted content.

### v0.15.16 — Generation Pipeline Restoration

- Restored Interview/Q&A, Builder precedence, Mode & Style, template enforcement, semantic repair, fidelity, fail-closed behavior, and current-client rebinding.

### v0.15.15 — Blueprint-First Collaborator Handoff

- Made detailed Generation Concept Blueprint the recommended handoff while retaining Detailed Workspace Draft.

### v0.15.14 — Component-Driven Full Synthesis

- Added Generation Group/component-driven transformation planning from the complete Workspace source pool.

### v0.15.13 — Complete Synthesis Review + Responsiveness

- Added complete-result review and improved Collaborator context preparation and autosave responsiveness.

### v0.15.12 — Full Character Synthesis from Workspace

- Added full-Workspace synthesis while retaining selective tools; later normal Generate Character routing returned to the validated parity pipeline.

### v0.15.11 — Visible Vision Analysis Messages

- Made Vision results persistent, selectable, provenance-aware Collaborator transcript content.

### v0.15.10 — Persistent FileDialog State

- Persisted favourites, history, filesystem location, view mode, hidden-file state, and sorting across restarts.

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

- Runtime-test v0.15.33-hotfix3 with real-provider AI Ideas batches and confirm generated concepts/hooks do not decide `{{user}}` behavior unless directly preserved from the source premise; verify conditional/open-ended hooks remain varied and specific rather than becoming vague.
- Runtime-test v0.15.33-hotfix2 with a real AI Ideas batch and confirm the visible generated cards also enable **Save Generated Ideas…** and **Develop Generated Idea…**, with selective saving still opt-in only.
- Runtime-test v0.15.33 by sending a generated unsaved Idea into Collaborator, developing it through several messages, closing/reopening CCF, and verifying the source snapshot/provenance survives independently of the original generation batch.
- Runtime-test a saved Idea Notebook entry through **Develop in Collaborator**, confirm its Notebook entry remains unchanged, and verify Idea/notebook provenance survives session reload.
- Exercise source-aware Collaborator context through user-triggered summarisation and attachment removal; the first-class source must remain intact and continue to inform later replies.
- Real-provider test malformed/empty/truncated API envelopes and confirm they produce one actionable provider failure/Diagnostics record rather than repeated Godot `Parse JSON failed` errors.
- Investigate the separate Linux/X11 GL Compatibility native crash observed twice as `BadAlloc` → `glXMakeCurrent failed` → signal 11. Compare behavior under normal GL Compatibility and a deliberate Vulkan/Forward+ test before considering renderer changes; do not conflate this with API JSON failures.
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

- **v0.15.34 — Existing Character → Collaborator:** expose the new structured character source from Workspace/imported cards and add author-intent starting choices such as refine, alternative version, future/past version, continue after an event, side-character promotion, relative/descendant, connected character, new character in the same setting, and open-ended development.
- Reuse v0.14.10 Related Character / AI Variation provenance and relationship concepts where they fit rather than creating a second incompatible derivation system.
- Prepare v0.15.35 completion routing so an occupied Workspace defaults a newly completed Collaborator character into a new character in the same group instead of silently replacing the source/current character.
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

- **v0.15.35 — Collaborator Character Completion & Group Integration:** when the current Workspace character is occupied, default a completed Collaborator character to a new character in the same group rather than overwriting the current one; retain explicit Replace Current and New Group alternatives. When the current character slot is genuinely empty, using that empty slot remains the natural default.
- Preserve source/relationship provenance for Collaborator-created characters while ensuring each created/exported character remains a complete standalone card. Suggest appropriate Relationship Graph edges without silently making them canonical.
- **v0.15.36 — Collaborator Refinement Compare/Apply:** compare original and proposed fields/sections and allow selective acceptance, update-original, or create-improved-copy workflows.
- **v0.15.37 — Multi-source Collaborator:** accept several characters and/or saved/generated Ideas as simultaneous structured source context for family, relationship, cast, and scenario development.
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
- Maintain one authoritative Character Text output budget per queued generation job and reassert it at request time.
- Keep each concurrent worker's request, retry, repair, Diagnostics, cancellation, and parent-state data isolated.
- Expose scheduler/job state through stable inspectable records rather than having UI scrape visual status strings.
- Route selective cancellation back through the owning worker/service so unrelated queues remain intact and each subsystem retains authority over its cleanup state.
- Keep dependency graphs data-driven and detect cycles/invalid references without deadlocking a build.
- Preserve frozen wave context and deterministic template-order assembly for parallel generation.
- Maintain the versioned representative regression registry as a release compatibility boundary across unrelated app areas.
- Keep local regression subprocesses isolated from real HOME/XDG/AppData state.
- Keep strict wrappers/import gates for Godot cases where logged script/assertion failures may not produce a nonzero exit code.
- Continue warning-as-error GDScript hygiene on Godot 4.6.x without hiding warning categories globally.
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
- Keep AI Ideas player-agency validation layered after the existing identity/POV validation, preserve explicit source-authored `{{user}}` setup, and avoid treating conditional/hypothetical choices as if the AI had already chosen them for the roleplayer.
- Keep Collaborator source seeding as a public structured capability instead of directly manipulating private composer/session controls from Idea Notebook or Workspace.
- Keep the primary Collaborator source separate from ordinary `context_items`; attachments may be removed or summaries rebuilt without changing the source snapshot.
- Keep Collaborator source formats versioned and backwards-compatible so future existing-character and multi-source workflows can extend rather than replace early source-aware conversations.
- Validate provider envelopes before inherited parsing/diagnostic layers, retain raw credential-safe evidence, and report network/malformed-envelope failures once through the normal retry/failure path.
- Continue investigating the Linux/X11 GL Compatibility `BadAlloc`/`glXMakeCurrent` crash separately; do not mask it by treating application-level JSON failures as its cause.
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
- Improve source-aware Collaborator UX with clearer source/provenance summaries and intent guidance as the v0.15.34–v0.15.37 workflows arrive.
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
