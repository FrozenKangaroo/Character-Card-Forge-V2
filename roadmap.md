# Character Card Forge — Project Roadmap

## Project Vision

Rebuild Character Card Forge as a responsive, native Godot desktop application for creating, generating, editing, organising, importing, exporting, analysing, illustrating, and collaboratively developing AI roleplay character cards.

The original PyWebView V1 application remains a feature and behaviour reference, not an architecture specification. Useful V1 behaviour should be re-expressed as maintainable Godot-native systems with versioned external data and portable Character Card / `.ccfproject` content.

## Core Design Principles

- Godot-native desktop UI with detachable tool windows where useful.
- Character project JSON/files are the source of truth; the legacy V1 database is not.
- Versioned, externally inspectable templates, authoring schemas, lorebooks, series data, settings, project packages, and interchange formats.
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
- Alternate character routes should not require full duplicate cards when only a few fields differ; Linked Variants may inherit from a base while exports always materialise normal standalone cards.
- Visual graph layout metadata stays separate from authoritative character, relationship, and route data.
- External authoring tools and AIs should be able to hand CCF a partial character without being forced to generate filler for fields they do not know.
- Long-running AI collaboration must account for model context limits, reserve output space, preserve original local transcripts, and make lossy summarisation explicit to the user.
- Provider/model token limits remain data-driven; UI controls and generation stages must not impose obsolete hidden ceilings.
- Every Character-generation sub-request uses the active Text profile's authoritative Maximum Output Tokens allowance unless the user changes that profile setting.
- Concurrent AI work must preserve isolated request/job state. A shared scheduler may coordinate capacity, but unrelated Character, Collaborator, Idea, Vision, authoring-tool, and Image jobs must never share one mutable `_active_job`.
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
- Normal Godot import/open operations leave the Git checkout clean.
- Release/update helpers prefer the repository checkout they are launched from and retain separate-copy syncing only as an explicit fallback.
- Every major supported workflow has representative cross-feature regression coverage; a focused feature test alone is not a release gate.
- Automated tests that exercise `user://` run in isolated temporary app-data directories.
- Generation reliability strategy is independent of Generation Mode/Style.
- Safe generation fails narrowly: accepted sections remain accepted, and missing required components receive focused repair rather than unrelated regeneration.
- Failed provider generations remain inspectable through credential-redacted Diagnostics containing request, raw response, assistant text, parse/validation state, termination reason, token usage, repair evidence, and trace.

## Current Development Phase

**v0.15.26 development candidate — Concurrent AI Scheduler + Collaborator Service Compatibility**

v0.15.26 replaces the effective one-request application bottleneck with a dependency-aware capacity scheduler. Generate Character, Character Collaborator, Idea Generator, authoring tools, Vision/Attachments, and Image Studio use isolated workers that can run together up to user-configured overall and role-specific limits. Work beyond capacity remains queued.

Safe Section Build keeps Interview/Q&A as a mandatory planning barrier. After Interview completion, eligible sections run in dependency waves. Every sibling in a wave receives the same frozen accepted-context snapshot, and child results remain isolated until the coordinator assembles them in template and Generation Group order. First Message waits for Scenario, and later greeting/dialogue material waits for required scene/opening context when those outputs exist.

Vision and Image roles can count toward the overall maximum or operate outside it while retaining their own role limits, supporting combinations such as cloud Text plus local Vision and local Stable Diffusion. Provider-specific API pools and shared local-GPU resource pools are planned refinements rather than part of this version.

The build also fixes the reported Character Collaborator failure caused by an exact v0.15.22 service comparison. Collaborator now uses capability-based compatibility and a dedicated current v0.15.26 worker.

The running development build displays **v0.15.26**. Release metadata remains controlled by `release.sh` until a tagged release is promoted.

## Completed

### v0.15.26 — Concurrent AI Scheduler + Collaborator Service Compatibility

- Added a shared AI capacity scheduler with configurable overall, Text, Vision, Image, and per-character Safe Section limits.
- Kept backwards-compatible defaults equivalent to the previous single-job behaviour; parallelism is enabled deliberately in Character AI settings.
- Added isolated live workers for primary Character generation, Character Collaborator, Idea Generator, authoring tools, and Vision/Attachments.
- Added scheduler-aware Image Studio execution using the same capacity manager while retaining Image Studio's provider flow and Cancel control.
- Added **Vision jobs count toward the overall maximum** and **Image jobs count toward the overall maximum** settings; independent roles still obey their role limits.
- Preserved Interview/Q&A as a required Safe Section barrier, then added dependency-wave parallel section generation with frozen sibling context.
- Added built-in Scenario → First Message and Scenario/First Message → later dialogue/greeting dependencies plus data-driven `depends_on` support.
- Kept child results isolated and assembled fields in template/Generation Group order, including multiple Output Groups targeting one Character Card field.
- Routed the assembled candidate through the existing template contract, semantic repair, concept-fidelity correction, fail-closed validation, Diagnostics, and Generation Preview.
- Replaced Character Collaborator's exact `generation_service_v01522.gd` comparison with capability-based compatibility and a dedicated v0.15.26 worker.
- Added aggregate `running / queued` Workspace status and **Cancel AI Queue** for Text/Vision workers.
- Added `docs/v01526-concurrent-ai-scheduler.md`, the composable v0.15.26 regression manifest, real-main-scene scheduler/Collaborator coverage, and a strict wrapper that treats logged Godot assertion/script errors as failures even if Godot returns exit code zero.

### v0.15.25 — Character Generation Token Budget Invariant

- Made the active Text profile's Maximum Output Tokens authoritative for Interview, Safe Sections, repairs, fidelity correction, and Fast Full Card.
- Removed the reintroduced historical 2,600-token Interview ceiling and added request-time enforcement plus provider termination/token Diagnostics.

### v0.15.24 — Live Safe Section Service Wiring

- Fixed the live Workspace retaining an old v0.14.3 service and added a real-main-scene service-composition regression.

### v0.15.23 — Token Settings Regression Fix

- Restored Text context/output controls, separate Vision controls, and large modern output-token values after a Settings inheritance regression.

### v0.15.22 — Safe Section Build + Generation Diagnostics

- Added Safe Section Build as the recommended strategy, Fast Full Card as the lower-request alternative, focused component/field repair, deterministic multi-group assembly, and credential-redacted failure Diagnostics.

### v0.15.21 — Unified Collaborator Attachments

- Added persistent TXT/Markdown/subtitle/JSON/image references with token accounting, Vision routing, removal semantics, and attachment documentation.

### v0.15.20 — Broad Regression Safety

- Added composable quick/release regression profiles, isolated app-data execution, release gating, and representative cross-feature CI.

### v0.15.19 — Release Checkout Selection

- Made release/update helpers prefer the current checkout, preserved explicit separate-copy syncing, and restored executable Linux helper modes.

### v0.15.18 — Checkout Hygiene + Warning Cleanup

- Added temporary `.gd.uid` policy, canonical project serialization checks, checkout-clean CI, and warning cleanup.

### v0.15.17 — Blueprint Supplementary Materialisation

- Restored Interview review metadata, preserved active templates through Collaborator handoff, and materialised Alternative Greetings/Lorebook data without overwriting accepted content.

### v0.15.16 — Generation Pipeline Restoration

- Repaired the parity inheritance boundary and restored Interview/Q&A, Builder precedence, Mode & Style, template enforcement, semantic repair, concept fidelity, fail-closed behavior, and current-client rebinding.

### v0.15.15 — Blueprint-First Collaborator Handoff

- Made detailed Generation Concept Blueprint the recommended handoff and retained Detailed Workspace Draft as an explicit alternative.

### v0.15.14 — Component-Driven Full Synthesis

- Added Generation Group/component-driven transformation planning from the complete Workspace source pool.

### v0.15.13 — Complete Synthesis Review + Responsiveness

- Added complete-result review and improved Collaborator context-preparation/autosave responsiveness.

### v0.15.12 — Full Character Synthesis from Workspace

- Added full-Workspace synthesis while retaining selective tools; later normal Generate Character routing returned to the validated parity pipeline.

### v0.15.11 — Visible Vision Analysis Messages

- Made Vision results persistent, selectable, provenance-aware Collaborator transcript content.

### v0.15.10 — Persistent FileDialog State

- Persisted favourites, history, filesystem location, view mode, hidden-file state, and sorting across restarts.

### v0.15.9 — Independent Vision Limits & Input Optimisation

- Added separate Vision context/output limits and safe preprocessing for genuinely oversized images.

### v0.15.8 — Dedicated Vision Routing

- Routed Vision requests through `vision_model` and produced clear missing-model errors.

### v0.15.7 — Collaborator Vision Pipeline

- Added full-scene Vision analysis and enforced the Vision → Text boundary.

### v0.15.6 — Collaborator Rich-Text Fix

- Removed synthetic bold rendering artifacts while preserving semantic presentation and raw stored text.

### v0.15.5 — Independent Collaborator Persistence

- Added versioned local chat storage under `user://collaborator_sessions` with optional project links.

### v0.15.4 — Collaborator Persistence & Behaviour Contract

- Added autosave, rename/delete, canon-preservation guidance, proportional response depth, and semantic rich text.

### v0.15.3 — Collaborator Chat UX

- Added wrapped input, distinct user/AI cards, selectable text, visible work states, and improved scrolling.

### v0.15.2 — Large Output Token Limits

- Removed the old 131,072 effective UI ceiling and supported modern large-output models.

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

- Preserved parseable failed-review output for import/editing/regeneration rather than discarding it.

### v0.14.2 — Character Transfer + Text Convention

- Added Move/Copy between projects and consistent multiline input behaviour.

Detailed per-release implementation notes remain in versioned docs, pull requests, tests, and Git history.

## In Progress

- Runtime-test v0.15.26 with real provider calls: run Character generation, Character Collaborator, Idea Generator, and Vision concurrently and verify configured capacity/queue behavior.
- Runtime-test parallel Safe Section Build with Interview/Q&A, multiple Output Groups targeting one field, a separate Sexual Traits group, and deliberately varied completion order.
- Verify First Message waits for Scenario and later dialogue/greeting sections wait for the intended dependencies in a real custom template.
- Test Vision and Image global-participation toggles with cloud Text plus local Vision/Stable Diffusion.
- Compare real-world latency, rate-limit behavior, completeness, and provider cost between sequential Safe Build, parallel Safe Build, and Fast Full Card.
- Deliberately provoke section failure/cancellation while siblings are active and confirm successful isolated results are not incorrectly written or cross-contaminated.
- Continue real-provider Diagnostics testing, including missing required components, malformed envelopes, content filtering, and genuine configured output-limit exhaustion.
- Runtime-test unified Collaborator attachments with TXT/Markdown, SRT, ASS/SSA, JSON, and image references through save/reopen and Blueprint handoff.
- Confirm generated Interview/Q&A review responses and Manual-vs-AI provenance survive real generation and save/reopen.
- Validate Blueprint supplementary compatibility materialisation without overwriting manually populated Alternative Greetings/Lorebooks.
- Continue profiling very long Collaborator sessions so preparation, rendering, autosave, Blueprint generation, and direct-draft generation remain responsive.
- Runtime-test `python3 tools/run_regression_suite.py --profile quick` and `--profile release` on the normal Linux/Godot development machine and confirm real `user://` data remains untouched.
- Runtime-test `release.sh` and confirm the broad release gate runs before staging/tagging and fails closed.
- Continue hardening forward-compatible tests so later shells/services cannot drop historical capabilities or hotfix invariants.
- Continue V1 parity review where V1 still has useful workflows V2 has not surpassed.

## Next Up

- Add optional provider/API execution pools so profiles sharing one cloud provider can share a provider-specific concurrency/rate-limit ceiling.
- Add optional local hardware pools so Vision and Image providers using the same GPU can share a configurable resource limit.
- Add richer queue UI with parent/child jobs, per-job cancellation, pause/resume, priority, move-to-front, and section progress.
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

- Further Library organisation, search/filter polish, and large-library performance work.
- More template authoring/validation tools and clearer documentation of generation contracts and dependencies.
- Stronger import/export diagnostics and compatibility reporting for external Character Card ecosystems.
- Additional provider capability discovery where providers expose reliable metadata.
- Continued V1 workflow parity where it improves V2 rather than reproducing obsolete architecture.
- More robust queue persistence/recovery only if future server-owned or long-running generation workflows require it; API keys remain local and are never moved into portable projects.

## Level and Content Tools

Character Card Forge is an authoring application rather than a level-based game. The equivalent content-tool priority is externally editable, versioned templates, `.ccfchar` interchange, project packages, lorebooks, and schema/editor tooling. Loading and saving continue to use the same data model exposed to authoring tools.

## Technical Improvements

- Keep generation services modular and preserve older project/card compatibility as schemas evolve.
- Treat runtime generation-service composition as a capability-tested compatibility boundary.
- Keep important historical hotfix behavior as active-leaf regression invariants rather than assuming an old class remains in every later inheritance chain.
- Maintain one authoritative Character Text output budget per queued generation job and reassert it at request time.
- Keep each concurrent worker's request, retry, repair, Diagnostics, cancellation, and parent-state data isolated.
- Keep dependency graphs data-driven and detect cycles/invalid references without deadlocking a build.
- Preserve frozen wave context and deterministic template-order assembly for parallel generation.
- Maintain the versioned representative regression registry as a release compatibility boundary across unrelated app areas.
- Keep local regression subprocesses isolated from real HOME/XDG/AppData state.
- Keep strict wrappers/import gates for Godot cases where logged script/assertion failures may not produce a nonzero exit code.
- Continue warning-as-error GDScript hygiene on Godot 4.6.x.
- Keep normal Godot import/open operations checkout-clean.
- Replace the temporary `.gd.uid` ignore policy with a deliberate checked-in canonical set when that migration occurs.
- Keep release/update helper executable modes under version control.
- Keep persistent app-level state under `user://` separate from portable project/card data unless explicitly included for portability.
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

## Long-Term Ideas

- Expand graph tooling into richer character/route planning without contaminating exported card data.
- Make Character Collaborator capable of increasingly sophisticated project-wide creative planning while keeping explicit brainstorming/canonical boundaries.
- Continue supporting portable user-created templates/content and external AI-assisted authoring workflows.
- Consider durable server-owned background jobs for future remote/mobile workflows while keeping generation logic shared and credentials server-side; this is separate from the current local desktop scheduler.

## Deferred / Experimental Ideas

- The standalone v0.15.12–v0.15.14 full-Workspace synthesis shortcut is not the normal Generate Character path because it bypassed the established parity/validation pipeline. Any revival must compose with that pipeline.
- Provider-specific concurrency heuristics remain opt-in until CCF can model provider limits without weakening the generic OpenAI-compatible path.
- Shared GPU resource pools are deferred until real local Vision/Image testing establishes the necessary controls.
- Persistent local queue recovery across application restarts is deferred; v0.15.26 queues are process-local.
- More elaborate graph layout automation beyond the current draggable anchor-based system.
- Advanced context compression beyond explicit user-triggered summarisation.
