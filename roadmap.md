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
- Large-library selectors should use searchable lightweight indexes rather than unbounded dropdowns. When a workflow ultimately targets a character, direct character search should be primary and project membership should remain visible context rather than a mandatory first navigation step.
- V1 parity is judged by useful workflow capability, not literal screen-for-screen reproduction.
- AI Ideas target interactive Character Card / SillyTavern-style roleplay by default and normally establish a meaningful relationship or opening dynamic with literal `{{user}}`.
- AI Ideas preserve player agency without making ordinary openings unusably rigid: temporary scene logistics for `{{user}}` may be invented when they merely establish where/when the scene begins, but substantive `{{user}}` personality, backstory, profession, long-term motives/preferences, major history, or consequential reactions/decisions remain author-controlled unless explicitly established by the source premise.
- Conditional `{{user}}` choices remain valid because they preserve the roleplayer's decision; direct forced reactions remain invalid unless source-authored.
- Generated ideas remain disposable until the user explicitly saves them. Persistent Idea Notebook material is versioned app-level authoring data independent of Character Projects.
- Named Idea Notebooks organise saved material without replacing tags.
- Collaborator source handoffs preserve structured source snapshots and provenance rather than paste opaque text into private UI state.
- Multi-source Collaborator sessions keep every character, Idea, external card, and pasted source individually identifiable. At most one existing Workspace character is the explicit refinement target; all other sources remain read-only references.
- Collaborator source ingestion preserves a raw snapshot for provenance/recovery and derives a separate AI-facing normalised snapshot. Normalisation never destructively rewrites the original imported, attached, or pasted source.
- A distinct embedded `UserPersona`, user-profile, or roleplayer-persona section found in extracted/imported source is treated as chat-session residue by default and excluded from Collaborator AI context. Genuine character-source facts involving `{{user}}` remain authoritative.
- Collaborator source-aware reasoning distinguishes established source facts, author-requested changes, and new/proposed details.
- A Collaborator source is read-only authoring context. Conversation, summarisation, or attachment removal must not silently mutate or erase the source snapshot.
- Collaborator completion routing is explicit: an occupied character is never overwritten by a completed Blueprint/draft without a later review/apply workflow, while genuinely empty placeholders may be safely reused.
- Existing-character refinement compares against the exact captured source snapshot. Selective application preserves unselected data and conflict-checks newer manual edits.
- Branch/related-character Collaborator directions remain non-destructive by default.
- Alternate character routes may use sparse Linked Variants internally, while exports materialise complete standalone cards.
- Visual graph layout metadata stays separate from authoritative character, relationship, and route data.
- External authoring tools and AIs should be able to hand CCF a partial character without being forced to generate filler for fields they do not know.
- Long-running AI collaboration must account for model context limits, reserve output space, preserve original local transcripts, and make lossy summarisation explicit.
- Provider/model token limits remain data-driven; UI controls and generation stages must not impose obsolete hidden ceilings.
- Every Character-generation sub-request uses the active Text profile's authoritative Maximum Output Tokens allowance unless the user changes that profile setting.
- Concurrent AI work must preserve isolated request/job state. A shared scheduler may coordinate capacity, but unrelated Character, Collaborator, Idea, Vision, authoring-tool, and Image jobs never share one mutable `_active_job`.
- Concurrent AI work must be inspectable and selectively cancellable without clearing unrelated workflows.
- Parallel generation remains deterministic: dependency order and template order—not network completion timing—determine context and final assembly.
- Character Collaborator preserves established canon by default, deepens existing material before rewriting premises, and makes alternate/rewrite directions explicit.
- Collaborator conversations are independent local authoring documents; project association is optional metadata rather than ownership.
- Collaborator image attachments go through the configured Vision role first; the Text role receives a provenance-tagged description rather than the original image payload.
- Text and Vision models may have different context/output limits and use their own role-specific settings.
- Vision input preprocessing preserves originals and only optimises genuinely oversized files.
- **Generate Character** uses the complete authoritative Workspace as source material while the active template and Generation Components define the generated output contract.
- Collaborator Blueprint handoff preserves one detailed canonical Generation Concept before template materialisation; direct field filling remains an explicit alternative.
- Alternative Greetings and Character Lorebook material are first-class character data as well as preserved authoring source.
- The live Workspace generation-service composition is a tested compatibility boundary. Compatibility is capability-based rather than an exact historical script filename check.
- Malformed, empty, interrupted, or non-JSON provider envelopes fail as normal provider/network errors with usable Diagnostics rather than repeated parser noise.
- Native engine/driver crashes are tracked separately from application-level provider failures and are never marked fixed without evidence.
- Forward+ is the standard desktop renderer. Compatibility/OpenGL remains an automatic fallback for unsupported RenderingDevice hardware.
- Normal Godot import/open operations leave the Git checkout clean.
- Release/update helpers prefer the repository checkout they are launched from and retain separate-copy syncing only as an explicit fallback.
- Every major supported workflow has representative cross-feature regression coverage; a focused feature test alone is not a release gate.
- Automated tests that exercise `user://` run in isolated temporary app-data directories.
- Generation reliability strategy is independent of Generation Mode/Style.
- Safe generation fails narrowly: accepted sections remain accepted, and missing required components receive focused repair rather than unrelated regeneration.
- Safe Section output must match the identity of the requested field/component as well as its JSON/type contract. Valid JSON containing content routed from Scenario, First Message, Lorebook, or another long section must not be silently materialised into an unrelated card field.
- Failed provider generations remain inspectable through credential-redacted Diagnostics.
- Deferred or awaited UI work verifies node/control/SceneTree validity before touching UI after an await.
- Detached tools that consume saved project data receive save/change notifications rather than relying only on startup scans or stale private caches.
- Image provider discovery belongs to Image profiles and is never stored in or resolved through Character Text/Vision profiles.
- Image Studio is a first-class main-navigation page. Its native `Window` controller may remain an implementation detail, but normal navigation presents the studio embedded in the main workspace.
- **Generate Prompt from Character** is an explicit AI-authored Character Text-role workflow; deterministic Character → image-prompt construction remains an explicit **Build Local Fallback**.
- Passive Image Studio browsing, search, project loading, and character switching never spend provider tokens; AI calls require an explicit user action.
- Long-form multiline authoring fields such as Image Prompt and Negative Prompt wrap visually without mutating stored text.

## Current Development Phase

**v0.15.38 development candidate — Scalable Image Studio Character Picker + Warning Cleanup**

Image Studio now treats the character as the primary source-selection target. The visible unbounded Project and Character dropdowns are replaced by one searchable **Choose Character…** picker that indexes lightweight Library rows and searches character/project names, roles, tags, series IDs, folders, and collections. Results remain disambiguated as `Character — Project`, and the unfiltered/result rendering is bounded so libraries containing hundreds of characters do not create an enormous popup.

The inherited Project/Character selectors remain hidden compatibility backing state so existing gallery ownership, Workspace synchronisation, provider routing, prompt generation, and Image Studio callbacks continue to operate without duplicating those systems. Selecting a search result loads the exact character rather than merely the project's active character, and passive browsing remains provider-free.

v0.15.38 also removes the three newly reported Godot 4.7.1 warnings in Collaborator Compare & Apply, the saved-Idea source picker, and the v0.15.37-hotfix1 Safe Section validator. The dedicated import gate now fails on both `SHADOWED_VARIABLE_BASE_CLASS` and `CONFUSABLE_LOCAL_DECLARATION`.

The running development build displays **v0.15.38**. Character Card Forge remains on Godot **4.7.1 stable** with Forward+ as the normal desktop renderer and Compatibility/OpenGL fallback retained for unsupported RenderingDevice hardware.

## Completed

### v0.15.38 — Scalable Image Studio Character Picker + Warning Cleanup

- Replaced the visible two-stage Project/Character dropdown hunt with direct searchable Character selection across all saved projects.
- Reused lightweight Library project/character rows instead of opening every project only to populate search results.
- Added search across character/project names, roles, tags, series IDs, folders, collections, and available creator/version metadata.
- Bounded rendered results to 250 while continuing to search the complete index; the regression fixture covers 540 characters and finds a target beyond the initial cutoff.
- Kept inherited selectors hidden as compatibility backing state and preserved Workspace live sync, gallery ownership, AI prompt generation, local fallback, and provider discovery.
- Fixed the reported `mode`, `title`, and `returned_keys` GDScript warning sites without suppressing warning categories.
- Added warning-as-error import coverage, focused large-library regression coverage, broad regression inheritance, CI, and `docs/v01538-image-studio-character-picker.md`.

### v0.15.37-hotfix1 — Safe Section Field Identity & Contamination Guard
- Exact field/component identity, cross-section contamination checks, final assembled fail-closed validation, parallel-worker coverage, and richer Diagnostics.

### v0.15.37 — Multi-source Character Collaborator
- One explicit TARGET plus read-only REFERENCES, saved Idea/pasted/card sources, Character Card JSON/PNG/APNG promotion, raw versus AI-facing normalised snapshots, embedded UserPersona exclusion, target switching, and multi-source provenance.

### v0.15.36-hotfix3 — Empty Project Save Guard
- Brand-new empty shells stay in memory until meaningful content exists; existing persisted projects remain safe.

### v0.15.36-hotfix2 — AI Ideas Agency / Backstory / POV Validation
- Refined detached-POV detection, temporary scene logistics, substantive `{{user}}` canon protection, conditional choices, and semantic validation Diagnostics.

### v0.15.36-hotfix1 — Configured Default Template
- Configured user default wins for new/add/missing-template paths without rewriting existing explicit built-in Default choices.

### v0.15.36 — Collaborator Refinement Compare/Apply + Forward+
- Selective Update Original/Create Improved Copy with stale-source checks, plus Forward+ desktop default.

### v0.15.35 — Collaborator Character Completion & Project Integration
- Safe completion destinations and derivation provenance without occupied-character overwrite.

### v0.15.34 — Existing Character → Collaborator + Godot 4.7.1
- Structured character sources, ten development directions, read-only snapshots, provenance, and Godot 4.7.1 baseline.

### v0.15.33-hotfix3 — AI Ideas User Agency Contract
- Initial agency contract, bounded repair, source-authored action preservation, and conditional-choice support.

### v0.15.33-hotfix2 — AI Ideas Notebook Capture Reliability
- Restored live Ideas completion capture for save/develop actions.

### v0.15.33-hotfix1 — Structured Builder → Collaborator
- Structured Builder ingredient/source handoff.

### v0.15.33 — Generic Collaborator Source Context
- Versioned read-only structured source snapshots/provenance.

### v0.15.32-hotfix1 — AI Ideas Notebook Header Layout
- Fixed malformed Ideas action/status layout.

### v0.15.32 — Idea Notebook Foundation
- Disposable batches, selective saving, notebooks, Unfiled, tags/search, editing/move/archive/restore/delete, versioned app persistence.

### v0.15.31 — AI Jobs Queue Visibility & Selective Cancellation
- Inspectable running/queued/waiting/dependency states and selective cancellation.

### v0.15.30 — Image Prompt Word Wrapping
- Wrapped Image Prompt and Negative Prompt editors.

### v0.15.29 — Embedded Image Studio + AI Prompt Restoration
- Image Studio main navigation and Text-role image-prompt generation beside Local Fallback.

### v0.15.28 — Image Studio Live Project and Provider State
- Live project handoff/rescans, Image-profile routing, cached model/sampler discovery.

### v0.15.27 — Runtime Lifecycle and Warning Cleanup
- Warning cleanup and safer deferred Collaborator scrolling.

### v0.15.26 — Concurrent AI Scheduler + Collaborator Service Compatibility
- Configurable AI concurrency, isolated workers, dependency-wave Safe Section parallelism, capability-based Collaborator compatibility.

### v0.15.25 — Character Generation Token Budget Invariant
- Active Text-profile Maximum Output Tokens became authoritative across Character generation.

### v0.15.24 — Live Safe Section Service Wiring
- Corrected live generation-service composition.

### v0.15.23 — Token Settings Regression Fix
- Restored Text/Vision token controls and large modern output values.

### v0.15.22 — Safe Section Build + Generation Diagnostics
- Safe Section Build, Fast Full Card, focused repair, deterministic assembly, credential-redacted Diagnostics.

### v0.15.21 — Unified Collaborator Attachments
- Persistent text/subtitle/JSON/image reference attachments with Vision routing and token accounting.

### v0.15.20 — Broad Regression Safety
- Composable quick/release profiles and isolated app-data execution.

### v0.15.19 — Release Checkout Selection
- Release/update helpers prefer the active checkout.

### v0.15.18 — Checkout Hygiene + Warning Cleanup
- `.gd.uid` policy, project serialisation checks, checkout-clean CI, warning cleanup.

### v0.15.17 — Blueprint Supplementary Materialisation
- Restored Interview review metadata and Alternative Greetings/Lorebook materialisation.

### v0.15.16 — Generation Pipeline Restoration
- Interview/Q&A, Builder precedence, Mode & Style, template enforcement, repair, fidelity, fail-closed behaviour.

### v0.15.15 — Blueprint-First Collaborator Handoff
- Detailed Generation Concept Blueprint became the recommended handoff.

### v0.15.14 — Component-Driven Full Synthesis
- Generation Group/component transformation planning.

### v0.15.13 — Complete Synthesis Review + Responsiveness
- Complete-result review and Collaborator responsiveness work.

### v0.15.12 — Full Character Synthesis from Workspace
- Full-Workspace synthesis groundwork; normal Generate Character later returned to the validated parity pipeline.

### v0.15.11 — Visible Vision Analysis Messages
- Persistent/selectable provenance-aware Vision transcript content.

### v0.15.10 — Persistent FileDialog State
- Favourites/history/location/view/sort persistence.

### v0.15.9 — Independent Vision Limits & Input Optimisation
- Separate Vision limits and safe oversized-image preprocessing.

### v0.15.8 — Dedicated Vision Routing
- Configured Vision-model routing and missing-model errors.

### v0.15.7 — Collaborator Vision Pipeline
- Full-scene Vision analysis and Vision-to-Text boundary.

### v0.15.6 — Collaborator Rich-Text Fix
- Removed synthetic bold rendering artefacts while preserving semantic display.

### v0.15.5 — Independent Collaborator Persistence
- Versioned local chats under `user://collaborator_sessions`.

### v0.15.4 — Collaborator Persistence & Behaviour Contract
- Autosave, rename/delete, canon preservation, proportional depth, semantic rich text.

### v0.15.3 — Collaborator Chat UX
- Wrapped input, distinct cards, selectable text, visible work state, copying, reliable scrolling.

### v0.15.2 — Large Output Token Limits
- Removed the old effective 131,072 output-token UI ceiling.

### v0.15.1 — Context Window Budgeting
- Context/output reserve/headroom and unknown-context mode.

### v0.15.0 — Collaborator Foundation
- Detachable brainstorming, reference context, summarisation, variants, Workspace handoff.

### v0.14.22 — Shared Graph Canvas
- Reusable draggable graph cards, anchors, labelled links, Relationship Graph, Route/Timeline editing.

### v0.14.21 — `.ccfchar` Interchange
- Versioned partial/full external authoring interchange with review-first import.

### v0.14.20 — Relationship Graph + Linked Variants
- Labelled relationship graphs and sparse inheriting variants with standalone export.

### v0.14.19 — Live Idea Generator Wiring
- Rebound visible Ideas to current validation/repair service.

### v0.14.18 — User-Centric Idea Generation
- Interactive-roleplay framing and literal `{{user}}` involvement.

### v0.14.17 — Detachable Lorebook Manager
- Non-modal multi-monitor-friendly Lorebook tool.

### v0.14.16 — Idea Identity + POV Validation
- Identity/source anchoring and repair.

### v0.14.15 — Lorebook Generation + Trigger Tools
- Scoped generation, activation rules, ordering, budgets, Trigger Preview, transfer tools.

### v0.14.14 — Focused Character Builders
- Appearance, Personality, Scene, and Full Character builders.

### v0.14.13 — Idea POV Safety
- Neutral third-person design prose while preserving literal `{{user}}`.

### v0.14.12 — Unified Idea Generator
- AI Ideas and Structured Builder unified.

### v0.14.11 — Structured Idea Builder
- V1-style ingredients, locks, randomisation, custom values, multi-select, editable pools, reset.

### v0.14.10 — Related Character / AI Variation
- Independent related/transformed characters with provenance.

### v0.14.9 — Library Assignment UX
- Existing-folder/collection pickers and filter/navigation simplification.

### v0.14.8 — Manual Guided Alternative Greetings
- Repeatable/reorderable greetings with Character Card round-trip.

### v0.14.7 — Manual Guided Component Parity
- Manual Guided follows active Generation Components with isolated state.

### v0.14.6 — Preview Selection Safety
- Unchecked Preview rows write nothing; current edits remain authoritative.

### v0.14.5 — Grouped Navigation + Lorebook Foundation
- Grouped menus and Project/Character Lorebook editing.

### v0.14.4 — Manual Guided
- Template-aware no-AI authoring.

### v0.14.3 — Recoverable Generation Review
- Parseable failed-review output retained for import/edit/regenerate.

### v0.14.2 — Character Transfer + Text Convention
- Move/Copy between projects and consistent multiline behaviour.

Detailed implementation notes remain in versioned docs, pull requests, regression tests, and Git history.

## In Progress

- Runtime-test v0.15.38 with a genuinely large personal Library: search by character/project/tag/series/folder/collection, duplicate character names across projects, exact character loading, Workspace-preferred project handoff, gallery ownership, and picker use after save/reload.
- Confirm v0.15.38 passive character search/switching never calls Text/Vision/Image providers and that Generate Prompt / Generate remain the only provider-spending actions in this workflow.
- Continue warning-as-error runtime observation for the three v0.15.38 cleanup sites and any additional Godot 4.7.x warnings surfaced by real use.
- Runtime-test v0.15.37-hotfix1 against real provider generation after the reported cross-section contamination. Confirm wrong-key responses receive focused repair, Scenario/First Message/Lorebook echoes are rejected from unrelated components, clean long-form fields remain accepted, parallel generation uses the same guard, and exported Diagnostics expose requested/returned keys plus contamination fingerprints.
- Runtime-test v0.15.37 with real multi-source Collaborator sessions: target character plus additional Workspace characters, saved/generated Ideas, pasted extraction text, and Character Card JSON/PNG sources. Confirm source roles survive save/reopen and long conversations without being flattened.
- Runtime-test embedded UserPersona exclusion against real extracted cards from JSON, PNG and copy/paste. Confirm raw source remains inspectable, AI-facing context excludes roleplayer residue, and legitimate character-to-`{{user}}` relationship/situation facts remain intact.
- Runtime-test target switching and v0.15.36 Compare & Apply from a multi-source session; only the explicit Workspace target may be updated while reference sources remain read-only.
- Confirm completion/refinement provenance carries the compact v0.15.37 source-set lineage and remains compatible with older derivation metadata.
- Runtime-test v0.15.36-hotfix3 by creating/abandoning blank projects, pressing Save while blank, then adding project/character content and confirming first persistence occurs only after meaningful authoring.
- Confirm existing saved projects remain normally saveable after content is deliberately cleared and old empty projects are never auto-deleted.
- Runtime-test v0.15.36-hotfix2 with real AI Ideas batches; confirm temporary logistics are accepted, invented durable user canon is rejected, supporting NPC roles do not falsely redefine the subject, and valid batches avoid unnecessary repair.
- Confirm failed/repaired Idea batches retain useful semantic validation reports in Diagnostics.
- Runtime-test v0.15.36-hotfix1 configured-default-template behaviour for new projects, Add Character, and missing-template fallback.
- Runtime-test v0.15.36 Compare & Apply with real Collaborator completions: selective changes, Update Original, Create Improved Copy, stale-source conflict handling, pending completion reopen, and branch safeguards.
- Continue normal Linux/X11 use under Forward+ and treat the old `BadAlloc` / `glXMakeCurrent failed` crash as not reproduced after renderer change until enough runtime evidence supports closing it; verify Compatibility fallback remains usable.
- Runtime-test v0.15.35 completion routing with real Blueprint and Detailed Workspace Draft generations.
- Runtime-test v0.15.34 Existing Character → Collaborator across refine/future/past/descendant/side-character/connected/same-setting directions.
- Runtime-test v0.15.33-hotfix2 with a real AI Ideas batch and confirm visible cards enable save/develop while selective saving remains opt-in.
- Runtime-test generated/saved Idea Collaborator sources through long conversations, restart persistence, summarisation, and attachment removal.
- Real-provider test malformed/empty/truncated API envelopes and confirm one actionable provider failure/Diagnostics record rather than repeated JSON parser errors.
- Runtime-test Idea Notebook selective save, multi-save, restart persistence, notebooks/tags/search, edit/move/archive/restore, and non-auto-save behaviour.
- Verify deleting a named Idea Notebook retains every saved idea in Unfiled and Notebook data stays outside portable Character Projects unless explicitly used.
- Runtime-test AI Jobs while Character generation, Collaborator, Ideas, Vision, AI image-prompt generation, and Image generation run concurrently; verify state visibility and selective cancellation.
- Runtime-test parallel Safe Section Build with Interview/Q&A, multiple Output Groups, separate Sexual Traits group, and varied completion order.
- Verify First Message visibly waits for Scenario and later dialogue/greeting sections wait for intended dependencies.
- Runtime-test real Character AI Text plus Stable Diffusion/Forge: AI-authored prompt, optional negative prompt, wrapping, cached model/sampler lists, image generation, and shared AI Jobs visibility.
- Compare **Generate Prompt from Character** against **Build Local Fallback** across sparse and detailed characters.
- Test Vision and Image global-participation toggles with cloud Text plus local Vision/Stable Diffusion.
- Compare latency, rate-limit behaviour, completeness, and provider cost between sequential Safe Build, parallel Safe Build, and Fast Full Card.
- Deliberately provoke section failure/cancellation while siblings are active and confirm isolated results are not cross-contaminated.
- Continue real-provider Diagnostics testing including missing components, filtering, output-limit exhaustion, and retry behaviour.
- Runtime-test unified Collaborator attachments with TXT/Markdown, SRT, ASS/SSA, JSON, and image references through save/reopen and Blueprint handoff.
- Confirm generated Interview/Q&A review responses and Manual-vs-AI provenance survive generation and save/reopen.
- Validate Blueprint supplementary materialisation without overwriting manually populated Alternative Greetings/Lorebooks.
- Continue profiling very long Collaborator sessions for preparation, rendering, autosave, Blueprint generation, and direct-draft responsiveness.
- Runtime-test `python3 tools/run_regression_suite.py --profile quick` and `--profile release` on the normal Linux/Godot machine and confirm real `user://` data remains untouched.
- Runtime-test `release.sh` and confirm the broad release gate runs before staging/tagging and fails closed.
- Continue hardening forward-compatible tests so later shells/services cannot drop historical capabilities/hotfix invariants.
- Continue V1 parity review where V1 still has useful workflows V2 has not surpassed.

## Next Up

- Improve source precedence/conflict presentation after real multi-source use: show conflicting facts and author resolutions clearly without inventing a hidden precedence order.
- Consider multi-selection for saved Idea/source pickers and denser source-list controls if family/cast sessions make one-at-a-time addition cumbersome.
- Consider extracting the v0.15.38 character-search/index behaviour into a reusable Character Picker if Image Studio runtime use proves it suitable for Collaborator, relationship tools, or other large-library workflows.
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
- Extend multi-source Collaborator after runtime use with richer conflict-resolution/source-selection UX for family, relationship, cast, scenario, continuity, and ensemble development without weakening one-target safety.
- Later expose derivation/lineage history such as future versions, side-character promotions, descendants, and characters created from a saved idea, while keeping exported card data independent of authoring history.
- Further Library organisation, search/filter polish, and large-library performance work.
- More template authoring/validation tools and clearer documentation of generation contracts and dependencies.
- Stronger import/export diagnostics and compatibility reporting for external Character Card ecosystems.
- Additional provider capability discovery where providers expose reliable metadata.
- Continued V1 workflow parity where it improves V2 rather than reproducing obsolete architecture.
- More robust queue persistence/recovery only if future server-owned or long-running generation workflows require it; API keys remain local and are never moved into portable projects.

## Level and Content Tools

Character Card Forge is an authoring application rather than a level-based game. The equivalent content-tool priority is externally editable, versioned templates, `.ccfchar` interchange, project packages, lorebooks, Idea Notebook entries, Collaborator source snapshots, and schema/editor tooling. Loading and saving continue to use the same underlying data models exposed to authoring tools.

## Technical Improvements

- Keep generation services modular and preserve older project/card compatibility as schemas evolve.
- Treat runtime generation-service composition as a capability-tested compatibility boundary.
- Keep important historical hotfix behavior as active-leaf regression invariants rather than assuming an old class remains in every later inheritance chain.
- Keep first-save project persistence content-aware: never-saved empty shells stay in memory, while already-persisted projects are never silently deleted or blocked from ordinary Save.
- Keep multi-source Collaborator collections versioned and backwards-compatible; never flatten distinct source IDs/types/roles/provenance to fit an older prompt shape.
- Maintain a single explicit existing-character refinement target while allowing arbitrary read-only references.
- Keep raw Collaborator source evidence separate from AI-facing normalised source data. Embedded user-persona cleanup happens only at the model-context boundary and remains auditable.
- Treat Character Card detection on normal attachment paths as a promotion step, not a replacement for attachments: non-card JSON remains text context and non-card images continue through Vision.
- Maintain one authoritative Character Text output budget per queued generation job and reassert it at request time.
- Keep each concurrent worker's request, retry, repair, Diagnostics, cancellation, and parent-state data isolated.
- Expose scheduler/job state through stable inspectable records rather than having UI scrape visual status strings.
- Route selective cancellation through the owning worker/service so unrelated queues remain intact.
- Keep dependency graphs data-driven and detect cycles/invalid references without deadlocking a build.
- Preserve frozen wave context and deterministic template-order assembly for parallel generation.
- Safe Section normal responses require exact requested field/component identities. Generic `value` is reserved for explicit focused repair; final assembly fails closed on high-confidence routed/duplicated contamination.
- Parallel Safe Section child workers are created through the active compatibility leaf (or overridable factory) so later validation/security fixes cannot be bypassed by historical hard-coded classes.
- Maintain the versioned representative regression registry as a release compatibility boundary across unrelated app areas.
- Keep local regression subprocesses isolated from real HOME/XDG/AppData state.
- Keep strict wrappers/import gates for Godot cases where logged script/assertion failures may not produce a nonzero exit code.
- Continue warning-as-error GDScript hygiene on Godot 4.7.x without hiding warning categories globally.
- Large-library pickers should search lightweight cached/index rows, bound rendered result counts, and load full project data only after the user selects an item.
- Keep hidden compatibility controls only where they safely reuse mature inherited logic; new user-facing selection UX should not require users to navigate those legacy controls.
- Audit awaited/deferred UI callbacks for node/tree validity whenever windows or views can be replaced dynamically.
- Keep detached tools synchronised through explicit save/settings signals and stable IDs, not only startup scans.
- Keep Image capability caches per Image profile and normalise them before persistence.
- Keep Character Text/Vision and Image profile lookup paths separate at every UI/service boundary.
- Keep Image Studio's embedded-page presentation as a tested user-facing contract even when its controller remains a Window internally.
- Preserve the explicit-action boundary for AI image prompting: passive refresh/search is provider-free, Generate Prompt uses Text AI, and Local Fallback never calls a provider.
- Keep Image Prompt and Negative Prompt as multiline wrapped editors; test visual wrapping rather than relying only on source configuration.
- When replacing/upgrading an Image Studio controller, reattach current controller content to the embedded host rather than reopening/exposing the hidden native Window.
- Prefer capability/user-contract regression assertions over fixed-depth inheritance or exact historical script filenames.
- Keep normal Godot import/open operations checkout-clean.
- Replace the temporary `.gd.uid` ignore policy with a deliberate checked-in canonical set when that migration occurs.
- Keep release/update helper executable modes under version control.
- Keep persistent app-level state under `user://` separate from portable project/card data unless explicitly included for portability.
- Keep Idea Notebook persistence independent of Character Projects and version both library index and saved-idea records.
- Keep Idea Notebook completion capture bound to the live generation-service topology rather than one assumed worker reference.
- Keep AI Ideas agency/backstory validation focused on durable user canon and consequential responses rather than banning harmless temporary scene logistics. Preserve source-authored facts and conditional choices.
- Keep detached-POV detection explicit and role-based; generic secrecy phrases remain normal user-centric premises.
- Keep AI Ideas card-subject validation focused on the generated character rather than supporting NPC terms in the role description.
- Keep Collaborator source seeding as a public structured capability instead of manipulating private composer/session controls.
- Keep the primary Collaborator source separate from ordinary `context_items`; attachments may be removed or summaries rebuilt without changing the source snapshot.
- Keep Collaborator source formats versioned and backwards-compatible so multi-source workflows extend rather than replace existing source-aware conversations.
- Keep completion payloads project-scoped, preserve generated payloads when destination selection is postponed, and never expose empty-slot replacement once meaningful authored content exists.
- Compare/refinement writes remain selection-based, preserve stable IDs when updating the original, and conflict-check selected fields against the captured source.
- Improved-copy creation starts from latest source state so unrelated manual edits survive while selected proposal changes layer on top.
- Keep branch/related-character derivations non-destructive unless a future explicit migration/retcon tool defines stronger semantics.
- Validate provider envelopes before inherited parsing/diagnostic layers, retain credential-safe evidence, and report malformed-envelope failures once through the normal failure path.
- Keep Forward+ as the standard desktop renderer while retaining Compatibility fallback for unsupported RenderingDevice hardware; continue observing the former GLX crash separately from application/API failures.
- Continue reducing synchronous whole-library work from interactive Collaborator paths.
- Keep attachment decoding/classification separate from UI composition and project-write boundaries.
- Keep Generation Component and section-dependency semantics data-driven.
- Treat Generation Concept Blueprint as preserved authoring source rather than disposable intermediate text.
- Carry `generation.template_id` through every character-creation handoff.
- Keep supplementary Blueprint materialisation separate from strict template-field validation unless the schema explicitly models it.
- Keep Diagnostics credential-safe before UI, clipboard, or disk exposure.

## Polish

- Improve semantic colour/theme consistency, keyboard navigation, detachable-window behaviour, multi-monitor use, resizing, and long-text editing.
- Improve visible progress/error states for long AI operations and distinguish queue wait, local preparation, provider thinking, repair, and validation time.
- Improve queue labels so project, character, workflow, role, provider, model, section, and dependency state are legible without opening Diagnostics.
- Improve Idea Notebook browsing as real libraries grow, including denser cards/list options and multi-selection if needed.
- Improve source-aware Collaborator UX with clearer source/provenance summaries, conflict presentation, target/reference guidance, and completion/refinement guidance.
- Continue replacing silent button no-ops with visible actionable status messages.

## Long-Term Ideas

- Expand graph tooling into richer character/route planning without contaminating exported card data.
- Make Character Collaborator capable of increasingly sophisticated project-wide creative planning while keeping brainstorming/canonical boundaries explicit.
- Add navigable creative lineage such as **Characters created from this Idea**, **Ideas involving this character**, future/past variants, side-character promotions, descendants/family trees, and related Collaborator sessions.
- Continue supporting portable user-created templates/content and external AI-assisted authoring workflows.
- Consider durable server-owned background jobs for future remote/mobile workflows while keeping generation logic shared and credentials server-side; this remains separate from the local desktop scheduler.

## Deferred / Experimental Ideas

- The standalone v0.15.12–v0.15.14 full-Workspace synthesis shortcut is not the normal Generate Character path because it bypassed the established parity/validation pipeline. Any revival must compose with that pipeline.
- Provider-specific concurrency heuristics remain opt-in until CCF can model provider limits without weakening the generic OpenAI-compatible path.
- Shared GPU resource pools are deferred until real local Vision/Image testing establishes the necessary controls.
- Persistent local queue recovery across application restarts is deferred; current queues are process-local.
- More elaborate graph layout automation beyond the current draggable anchor-based system.
- Advanced context compression beyond explicit user-triggered summarisation.
