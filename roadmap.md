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
- Deferred or awaited UI work must verify that its node, controls, and original `SceneTree` are still valid after every await before touching them.
- Detached tools that consume saved project data must receive save/change notifications rather than relying only on startup scans or stale private caches.
- Image provider discovery belongs to Image profiles and must never be stored in or resolved through Character Text/Vision profiles.
- Image Studio is a first-class main-navigation page. Its native `Window` controller may remain an implementation detail, but normal navigation must present the studio embedded in the main workspace.
- **Generate Prompt from Character** is an AI-authored Character Text-role workflow; deterministic Character → image-prompt construction remains an explicit **Build Local Fallback** rather than silently replacing the AI path.
- Passive Image Studio browsing, project loading, and character switching must never spend provider tokens; AI calls require an explicit user action.
- Long-form multiline authoring fields such as Image Prompt and Negative Prompt must wrap visually at the available editor width instead of requiring horizontal scrolling; visual wrapping must not mutate the stored text.

## Current Development Phase

**v0.15.30 development candidate — Image Prompt Word Wrapping**

v0.15.30 is a narrow Image Studio presentation fix following the v0.15.29 embedded-page and AI-prompt restoration. The Image Prompt and Negative Prompt controls remain normal multiline `TextEdit` editors, but now use boundary word wrapping so long AI-authored or manually edited prompts flow across visible lines instead of appearing as one enormous horizontal line.

The underlying prompt text is unchanged. Wrapping is presentation-only and therefore does not alter copied prompt content, negative prompts, saved defaults, or the text sent to image providers. Existing vertical scrolling remains available for long prompts, and horizontal scroll is reset when the editors are configured.

The running development build displays **v0.15.30**. Release metadata remains controlled by `release.sh` until a tagged release is promoted.

## Completed

### v0.15.30 — Image Prompt Word Wrapping

- Enabled `TextEdit.LINE_WRAPPING_BOUNDARY` for both the Image Prompt and Negative Prompt editors.
- Reset horizontal scroll when those editors are configured while preserving multiline editing and vertical scrolling.
- Kept wrapping presentation-only so prompt text passed to clipboard, settings, AI prompt workflows, and Image providers remains unchanged.
- Preserved the v0.15.29 embedded Image Studio, Character Text-role **Generate Prompt from Character**, and deterministic **Build Local Fallback** behavior.
- Preserved v0.15.28 Workspace-save handoff, Image-profile separation, and cached model/sampler discovery.
- Added `docs/v01530-image-prompt-word-wrap.md`, a strict real-main-scene regression that inserts a long single paragraph into both live editors and verifies actual wrapped visual lines, a focused v0.15.30 workflow, and the v0.15.30 broad regression manifest.

### v0.15.29 — Embedded Image Studio + AI Prompt Restoration

- Restored Image Studio as an embedded main-navigation page rather than a native popup workflow.
- Remounted the current v0.15.29 controller UI inside the established `CCFImageGenerationPage` scroll viewport while retaining the native Window only as a hidden implementation detail.
- Made the controller `open_studio()` compatibility entry point refresh-only so normal or inherited callers cannot reopen the popup.
- Restored **Generate Prompt from Character** as an explicit Character AI Text-role request that authors a purpose-built image prompt instead of mechanically extracting card fields.
- Restored the established separation between the AI-authored prompt action and **Build Local Fallback**, which remains deterministic and provider-free.
- Kept project/character loading passive so merely opening or browsing Image Studio cannot spend Text-provider tokens.
- Preserved Description, Scenario, Personality, First Message, Generation Concept, and Additional visual direction as prompt-authoring source context, with Additional visual direction treated as authoritative for the requested image.
- Kept Stable Diffusion-style and natural-language prompt contracts distinct and retained optional generated negative prompts.
- Prevented a completed AI prompt from applying if the active character changed while the request was running.
- Implemented the restored prompt writer on the current v0.15.26 scheduler/generation inheritance chain rather than reviving the old v0.13 service unchanged.
- Preserved v0.15.28 Workspace-save handoff, correct Image-profile routing, and persistent model/sampler discovery.
- Added `docs/v01529-image-studio-regression-restoration.md`, a real-main-scene regression, a strict wrapper, a focused v0.15.29 workflow, and the v0.15.29 broad regression manifest.

### v0.15.28 — Image Studio Live Project and Provider State

- Added direct Workspace `project_saved` handoff into Image Studio so newly saved projects appear without app restart.
- Made opening Image Studio prefer the current saved Workspace project and active character.
- Made **Reload Projects** perform a real disk rescan, retain the preferred project where possible, and report how many saved projects were found.
- Added an immediate saved-project fallback for the same-frame case where a platform directory listing has not yet exposed the new project folder.
- Replaced Image Studio's incorrect Character `api_profiles` enumeration/lookup with `image_profiles` and `image_profile_by_id()`.
- Corrected **Save Image Defaults** so it updates the selected Image profile rather than a Text/Vision profile.
- Added a normalised per-Image-profile `discovered_capabilities` cache for models/checkpoints, samplers, backend flags, notes, and discovery time.
- Made Settings **Test / Discover** save its discovered lists and notify the live Image Studio.
- Made Image Studio discovery save to the same cache and restore cached lists whenever an Image profile is selected.
- Added visible prompt-state errors instead of silent failures.
- v0.15.28 also accidentally reintroduced native popup presentation and replaced the established AI-authored Character → image prompt with local extraction; both regressions are explicitly corrected in v0.15.29 without removing the v0.15.28 state fixes.
- Added `docs/v01528-image-studio-live-state.md`, a strict real-main-scene regression, a v0.15.28 workflow, and the v0.15.28 broad regression manifest.

### v0.15.27 — Runtime Lifecycle and Warning Cleanup

- Removed the reported `Node.name` and `Node.ready` shadowing warnings without suppressing warning categories.
- Made Character Collaborator's two-frame deferred chat scroll safe when its window leaves the SceneTree.
- Added strict lifecycle/import coverage for the reported null-tree errors and warnings.

### v0.15.26 — Concurrent AI Scheduler + Collaborator Service Compatibility

- Added configurable overall, Text, Vision, Image, and per-character Safe Section concurrency with queued overflow work.
- Added isolated workers for Character generation, Collaborator, Ideas, authoring tools, Vision/Attachments, and Image Studio.
- Added dependency-wave parallel Safe Section generation with frozen sibling context and deterministic template-order assembly.
- Replaced Collaborator's exact historical script check with capability-based current-service compatibility.

### v0.15.25 — Character Generation Token Budget Invariant

- Made the active Text profile's Maximum Output Tokens authoritative for Interview, Safe Sections, repairs, fidelity correction, and Fast Full Card.
- Removed the historical 2,600-token Interview ceiling and added request-time enforcement plus termination/token Diagnostics.

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

- Runtime-test v0.15.30 with the user's real Character AI Text provider plus Stable Diffusion/Forge provider: AI-authored prompt, optional negative prompt, visible wrapping for both prompt editors, cached checkpoint/sampler lists, image generation, and restart persistence.
- Compare **Generate Prompt from Character** against **Build Local Fallback** across sparse and detailed characters; AI prompting should add deliberate composition without drifting established physical identity.
- Runtime-test v0.15.30 with real provider calls while Character generation, Character Collaborator, Idea Generator, Vision, AI image-prompt generation, and Image generation run concurrently.
- Runtime-test parallel Safe Section Build with Interview/Q&A, multiple Output Groups targeting one field, a separate Sexual Traits group, and deliberately varied completion order.
- Verify First Message waits for Scenario and later dialogue/greeting sections wait for intended dependencies in a real custom template.
- Test Vision and Image global-participation toggles with cloud Text plus local Vision/Stable Diffusion.
- Compare real-world latency, rate-limit behavior, completeness, and provider cost between sequential Safe Build, parallel Safe Build, and Fast Full Card.
- Deliberately provoke section failure/cancellation while siblings are active and confirm successful isolated results are not cross-contaminated.
- Continue real-provider Diagnostics testing, including missing required components, malformed envelopes, content filtering, and configured output-limit exhaustion.
- Runtime-test unified Collaborator attachments with TXT/Markdown, SRT, ASS/SSA, JSON, and image references through save/reopen and Blueprint handoff.
- Confirm generated Interview/Q&A review responses and Manual-vs-AI provenance survive generation and save/reopen.
- Validate Blueprint supplementary compatibility materialisation without overwriting manually populated Alternative Greetings/Lorebooks.
- Continue profiling very long Collaborator sessions for preparation, rendering, autosave, Blueprint generation, and direct-draft responsiveness.
- Runtime-test `python3 tools/run_regression_suite.py --profile quick` and `--profile release` on the normal Linux/Godot machine and confirm real `user://` data remains untouched.
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
- Continue replacing silent button no-ops with visible actionable status messages.

## Long-Term Ideas

- Expand graph tooling into richer character/route planning without contaminating exported card data.
- Make Character Collaborator capable of increasingly sophisticated project-wide creative planning while keeping explicit brainstorming/canonical boundaries.
- Continue supporting portable user-created templates/content and external AI-assisted authoring workflows.
- Consider durable server-owned background jobs for future remote/mobile workflows while keeping generation logic shared and credentials server-side; this is separate from the current local desktop scheduler.

## Deferred / Experimental Ideas

- The standalone v0.15.12–v0.15.14 full-Workspace synthesis shortcut is not the normal Generate Character path because it bypassed the established parity/validation pipeline. Any revival must compose with that pipeline.
- Provider-specific concurrency heuristics remain opt-in until CCF can model provider limits without weakening the generic OpenAI-compatible path.
- Shared GPU resource pools are deferred until real local Vision/Image testing establishes the necessary controls.
- Persistent local queue recovery across application restarts is deferred; v0.15.30 queues are process-local.
- More elaborate graph layout automation beyond the current draggable anchor-based system.
- Advanced context compression beyond explicit user-triggered summarisation.
