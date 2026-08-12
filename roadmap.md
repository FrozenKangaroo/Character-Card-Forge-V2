# Character Card Forge — Project Roadmap

## Project Vision

Rebuild Character Card Forge as a responsive, native Godot desktop application for creating, generating, editing, organising, importing, exporting, analysing, illustrating, and collaboratively developing AI roleplay character cards.

The original PyWebView V1 application remains a feature and behaviour reference, not an architecture specification. Useful V1 behaviour should be re-expressed as maintainable Godot-native systems with versioned external data and portable Character Card / `.ccfproject` content.

## Core Design Principles

- Godot-native desktop UI with detachable tool windows where useful.
- Character project JSON/files are the source of truth; the legacy V1 database is not.
- Versioned, externally inspectable templates, authoring schemas, lorebooks, series data, settings, project packages, Idea Notebook data, Collaborator source data, Image creative catalogs/presets and interchange formats.
- Clear separation between character data, project-shared context, AI generation, providers, images, imports/exports, library indexing and tooling.
- OpenAI-compatible and local/self-hosted Text, Vision and Image providers remain first-class targets.
- Text/Vision provider roles and Image Generation providers stay independently configurable.
- New systems extend the central project model rather than create parallel character copies.
- Existing character/card data must not be destroyed by unchecked preview fields, failed reviews, disabled generation components, unrelated regeneration, partial imports, exploratory AI conversation or unreviewed Collaborator output.
- Conversational brainstorming never becomes canonical project data until the user explicitly applies, generates or imports it.
- Stable internal IDs should survive user-facing renames where practical.
- Brand-new Character Projects remain in memory until meaningful authored content exists.
- Wider desktop windows should reveal more workspace rather than scale a fixed game-style canvas.
- Secondary workflows belong in grouped menus instead of an ever-growing wall of top-level buttons.
- Large-library selectors should use searchable lightweight indexes rather than unbounded dropdowns.
- V1 parity is judged by useful workflow capability, not literal screen-for-screen reproduction.
- Collaborator source handoffs preserve structured source snapshots and provenance rather than paste opaque text into private UI state.
- Multi-source Collaborator sessions keep every character, Idea, external card and pasted source individually identifiable; at most one existing Workspace character is the explicit refinement target.
- Character Card PNG/APNG metadata and Vision-derived evidence stay linked but distinct.
- Embedded UserPersona/user-profile residue is excluded from AI-facing source context by default without deleting the raw source.
- Collaborator transcript deletion is chronological rewind and never silently removes independent Reference Context.
- Existing-character refinement remains selection-based, conflict-checks newer manual edits and is non-destructive by default.
- Linked Variants may remain sparse internally while exports materialise complete standalone cards.
- Long-running AI collaboration accounts for model context limits and keeps lossy summarisation explicit.
- Provider/model token limits remain data-driven and role-specific.
- Concurrent AI work keeps isolated request/job state, is inspectable and is selectively cancellable.
- Safe generation fails narrowly and preserves accepted sections.
- Failed provider generations remain inspectable through credential-redacted, binary-free, bounded Diagnostics.
- Forward+ is the standard desktop renderer with Compatibility/OpenGL fallback.
- Normal Godot import/open operations leave the Git checkout clean.
- `update.sh` and `release.sh` fail closed around real user work and treat release metadata as one generated transaction.
- Every major supported workflow has representative cross-feature regression coverage.
- Image provider discovery belongs to Image profiles and never leaks into Character Text/Vision profile configuration.
- Image Studio is a first-class main-navigation page; passive browsing/search never spends provider tokens.
- **Generate Prompt from Character** is an explicit Text-role AI workflow; deterministic local prompt construction remains available separately.
- Long-form Image Prompt and Negative Prompt fields wrap visually without mutating stored text.
- **Creative image intent is provider-independent; generation capabilities are provider, backend, model or workflow specific.**
- Image Studio must not hardcode per-model capability tables when authoritative runtime discovery exists.
- Missing capability metadata is not proof of lack of support; capability state may be `supported`, `unsupported` or `unknown`.
- Capability provenance is retained across provider metadata, backend knowledge, model-family profiles, ComfyUI workflow mappings, inference and explicit user overrides.
- Backend/model capability is distinct from current Image Studio execution readiness.
- Provider-specific parameter metadata is additive; unknown future parameters should be preserved rather than silently discarded.
- Local Stable Diffusion / Forge / A1111 and ComfyUI remain first-class Image Studio targets alongside paid/cloud APIs.
- ComfyUI is treated as a workflow execution backend; capabilities may belong to a saved Generation Profile/workflow rather than one checkpoint alone.
- Image Studio uses progressive disclosure: common creative workflow stays prominent while optional technical/provider controls may live in dedicated tabs.
- Cross-tool image handoffs should preserve raw image evidence and provenance rather than degrade generated images into anonymous attachments.

## Current Development Phase

**v0.16.5 — Local Stable Diffusion / Forge / A1111 Profiles**

v0.15.40 remains the public release baseline. v0.16.0 began the current development line with Collaborator rewind, v0.16.1 introduced normalized Image capability architecture, v0.16.2 added provider-independent structured creative prompt composition, v0.16.3 reorganised Image Studio into Prompt & Results, Creative, and Advanced tabs, and v0.16.4 connected the capability model to rich provider-discovered model metadata.

v0.16.5 makes local Forge/A1111 checkpoints first-class capability-profile targets without pretending every checkpoint is identical. Backend discovery remains authoritative for backend facts, optional model-family profiles contribute workflow defaults only, and explicit per-checkpoint author overrides can correct operation/parameter state with `user_override` provenance.

The Advanced tab now contains a Forge/A1111-only **Local checkpoint profile** surface with model-family selection, notes, preferred resolution/sampler/steps/CFG defaults, Apply Profile Defaults, checkpoint-specific capability overrides, Save and Reset. Family/default metadata is externally versioned in `data/image_local_model_families_v1.json` and does not become capability proof merely because a family was selected.

The running development build displays **v0.16.5**, uses Godot **4.7.1 stable**, keeps Forward+ with Compatibility/OpenGL fallback and retains the complete v0.16.4/v0.16.3/v0.16.2/v0.16.1/v0.16.0/v0.15.40 safety baseline. Release metadata remains at the last promoted public version until `release.sh` performs the next release transaction.

## Completed

### v0.16.5 — Local Stable Diffusion / Forge / A1111 Profiles

- Added versioned external `data/image_local_model_families_v1.json` for reusable local model-family authoring defaults.
- Added `CCFImageLocalModelProfileServiceV0165` with checkpoint-specific records stored per Image provider profile.
- Kept family defaults separate from capability claims; selecting SD1/SDXL/Pony/Illustrious-derived authoring profiles never automatically changes support state.
- Added checkpoint notes and preferred resolution, sampler, steps and CFG defaults.
- Added explicit Auto / Supported / Unsupported / Unknown overrides for core operations and technical parameters.
- Reused the v0.16.1 normalized `user_override` provenance/confidence layer.
- Added Forge/A1111-only **Local checkpoint profile** controls to the Advanced tab with Apply Profile Defaults, Save and Reset actions.
- Added focused v0.16.5 regression coverage, inherited regression manifest, Godot 4.7.1 CI and `docs/v0165-local-sd-profiles.md`.
- Expanded the v0.16.5 warning gate to catch `INTEGER_DIVISION` following the v0.16.4 desktop warning cleanup.

### v0.16.4 — Dynamic Provider Model Capabilities

- Added `CCFImageProviderModelCatalogServiceV0164` with versioned per-profile rich model catalogs.
- Preferred `/api/v1/images/models`, retained `/api/v1/image-models`, then generic `/models` fallback for OpenAI-compatible Image profiles.
- Kept Forge/A1111 discovery on its existing WebUI API path.
- Preserved raw provider model records, capabilities, supported parameters, pricing, tags and unknown future fields.
- Reused the v0.16.1 normalized tri-state capability model instead of introducing provider-specific model tables.
- Added cached fetch endpoint/time metadata and passive cache browsing with explicit Refresh.
- Added vanished-model-safe behavior so manual/cached selections are not silently replaced.
- Added dynamic Advanced controls for provider resolution values, image-count constraints, choice/boolean/numeric/text parameters and unknown additive supported fields.
- Added `CCFImageGenerationServiceV0164` so supported provider-specific parameters can reach OpenAI-compatible generation payloads without overwriting core `model`, `prompt`, `n` or `size` fields.
- Added focused v0.16.4 regression coverage, inherited regression manifest, Godot 4.7.1 CI and `docs/v0164-dynamic-image-model-capabilities.md`.

### v0.16.3 — Image Studio Tabbed Workflow

- Added **Prompt & Results**, **Creative**, and **Advanced** tabs without replacing inherited generation state.
- Kept project/character/provider/model and common generation context visible outside the tabs.
- Kept the editable prompt/results workflow primary and selected by default.
- Moved v0.16.2 creative controls into Creative and optional technical/capability controls into Advanced.
- Preserved provider discovery, scheduler, gallery/results and all earlier Image Studio behavior.

### v0.16.2 — Structured Creative Prompt Composer

- Added versioned external `data/image_prompt_catalog_v1.json` and reusable `CCFImagePromptComposerServiceV0162`.
- Added Visual Style, Medium, Camera / Composition, Lighting, Colour Palette, Material / Surface, Atmosphere / Elements and multi-select Modifiers.
- Kept the final Image prompt editable and exposed structured contribution summaries.
- Added deterministic composition ordering and duplicate-phrase protection.

### v0.16.1 — Image Studio 2 Capability Foundation

- Added versioned normalized capability documents with `supported` / `unsupported` / `unknown` semantics.
- Added capability provenance/confidence and operation-level `execution_ready` separate from backend/model support.
- Added rich provider-model normalization, additive unknown parameter preservation, legacy capability-cache conversion and user-override layering.
- Normalized Forge/A1111 discovery and kept generic OpenAI-compatible discovery unknown-safe.
- Added passive capability summary and **Capability Details…** inspection.

### v0.16.0 — Character Collaborator Conversation Rewind

- Added **Delete From Here…** chronological author-message rewind.
- Rewind truncates later transcript history and invalidates affected summaries while preserving independent Reference Context.
- Added autosave persistence and real-main-scene regression coverage.

### v0.15.40 — Public Release Baseline

- Public release promoted on 2026-08-09 after Godot 4.7.1 validation and all inherited release regressions passed before staging.
- The v0.15 line delivered modern Character Collaborator, Safe Section generation, AI Jobs, Idea Notebook, multi-source provenance, Vision/Card dual ingestion, Image Studio integration, scalable character selection, release/update hardening and extensive runtime/UI regression coverage.

### Historical Milestone Index

Detailed history remains preserved in versioned docs, pull requests, regression manifests/tests and Git history.

- v0.15.40-hotfix1..9 — Collaborator source/layout/runtime fixes, Diagnostics hardening, Godot 4.7.1 release gate and interrupted updater recovery.
- v0.15.39 + hotfixes — Character Card PNG/APNG metadata + Vision dual ingestion, UserPersona exclusion and warning cleanup.
- v0.15.38 + hotfix1 — scalable Image Studio character picker and safer `update.sh` local-change handling.
- v0.15.37 + hotfix1 — multi-source Collaborator and Safe Section contamination protection.
- v0.15.36 + hotfixes — Compare & Apply, Forward+, configured default template, AI Ideas agency/backstory validation and empty-project save guard.
- v0.15.35 — Collaborator completion routing.
- v0.15.34 — Existing Character → Collaborator and Godot 4.7.1 baseline.
- v0.15.33 + hotfixes — structured Collaborator source context, Builder/Idea handoffs and user-agency contract.
- v0.15.32 + hotfix1 — Idea Notebook and layout fixes.
- v0.15.31 — AI Jobs queue visibility/selective cancellation.
- v0.15.28..30 — Image Studio live provider/project state, embedded Studio + AI prompt generation and prompt wrapping.
- v0.15.26..27 — concurrent AI scheduler and runtime lifecycle cleanup.
- v0.15.22..25 — Safe Section Build, Diagnostics, token settings/budget and live service wiring.
- v0.15.20..21 — broad regression safety and unified Collaborator attachments.
- v0.15.18..19 — checkout hygiene and release checkout selection.
- v0.15.12..17 — full synthesis experiments, Blueprint-first handoff, restored generation pipeline and supplementary materialisation.
- v0.15.10..11 — persistent FileDialog state and visible Vision Analysis messages.
- v0.15.0..9 — Character Collaborator foundation, persistence/UX, Vision pipeline/routing/limits and token/context controls.
- v0.14.x — relationship/route graphs, Linked Variants, `.ccfchar` interchange, focused builders, Lorebook tools, Idea generation, Manual Guided parity, Alternative Greetings and Library assignment UX.

## In Progress

- Runtime-test v0.16.5 with real Forge/A1111 profiles containing multiple checkpoints; confirm each checkpoint keeps independent family/default/override data.
- Confirm Apply Profile Defaults changes live generation controls without silently changing capability overrides.
- Confirm Reset Checkpoint Profile returns to inherited backend behavior without deleting the checkpoint/provider configuration.
- Runtime-test v0.16.4 against a real rich provider Image profile and confirm model changes rebuild Advanced controls correctly without automatic network traffic.
- Confirm provider-specific resolution strings, quality/speed options and image-count constraints match live provider metadata.
- Confirm a model removed from live discovery remains visibly selected/stale rather than silently changing the project/profile.
- Runtime-test v0.16.3 tab layout at narrow and wide window sizes.
- Runtime-test v0.16.2 structured prompt composition across OpenAI-compatible and Forge/A1111 Image profiles.
- Confirm legacy cached Image profile discovery still populates model/sampler controls.
- Runtime-test v0.16.0 rewind persistence and summary invalidation on long real Collaborator conversations.
- Continue hardening forward-compatible tests so later shells/services cannot drop historical capabilities/hotfix invariants.
- Continue V1 parity review where V1 still has useful workflows V2 has not surpassed.

## Next Up — v0.16.x Image Studio 2

### v0.16.6 — ComfyUI Workflow Generation Profiles

- Treat ComfyUI as a workflow execution backend rather than an A1111-style model endpoint.
- Save a Generation Profile linking a ComfyUI workflow to explicit CCF inputs/outputs.
- Map Prompt, Negative Prompt, Width/Height or Aspect Ratio, Steps, CFG/Guidance, Seed, Reference Image, Denoise/Strength and other workflow-specific inputs.
- Allow explicit mapping even if automatic node/input discovery is later added.
- Retain workflow provenance and unknown/additive fields.

### v0.16.7 — Image-to-Image, Reference and Inpainting

- Support distinct **Text → Image**, **Image → Image**, **Reference Image Guidance**, and **Inpainting** modes when capabilities allow them.
- Show source-image, denoise/strength, mask, reference weight, preserve-composition or equivalent controls only when meaningful.
- Reuse existing character/project artwork as explicit image-generation reference without conflating generation reference with Vision analysis.

### v0.16.8 — Image Style Presets

- Add global reusable Image Style presets.
- Add project-level visual identity presets.
- Add optional per-character image defaults.
- Keep creative presets portable across providers; technical provider/model settings remain separate.

### v0.16.9 — Studio Workflow & Results Polish

- Improve generation history and preserve exact composed prompt plus provider/model/settings used for each result.
- Add robust Reuse Settings, Regenerate, New Seed/Variation, comparison, favourites and batch-result workflows where supported.
- Improve project/character asset assignment and recovery.
- Surface optional cost information without making paid-provider metadata a requirement for local backends.
- Continue refining tab/progressive-disclosure layout based on real desktop use.

## Planned — v0.17.x and Later Authoring Work

### Structured Image Studio → Collaborator handoff

- Add **Send to Character Collaborator** from an Image Studio result.
- Treat the generated image as a structured Collaborator source rather than an anonymous generic attachment.
- Preserve raw image provenance and, where useful, generation prompt/model/profile/settings metadata.
- Optionally run/use Vision analysis while keeping Vision-derived evidence distinct from the image itself.
- Support choosing whether the image becomes Reference Context for an existing target or starts/seeds a new Collaborator workflow.
- Keep all canonical character writes explicit; sending an image to Collaborator must not silently change the character card.

### Other accepted v0.17.x+ work

- Improve multi-source precedence/conflict presentation, especially when Character Card metadata and linked Vision evidence disagree.
- Add denser/multi-selection source controls for family/cast/ensemble Collaborator sessions if runtime use confirms the need.
- Extract the v0.15.38 character-search/index behaviour into a reusable Character Picker for Collaborator, relationship tools, Image Studio and other large-library workflows.
- Preserve source/relationship provenance for Collaborator-created characters while keeping exports complete and standalone.
- Suggest appropriate Relationship Graph edges without silently making them canonical.
- Extend multi-source Collaborator for richer family, relationship, cast, scenario, continuity and ensemble development while preserving one-target safety.
- Expose derivation/lineage history such as future versions, side-character promotions, descendants, related characters and characters created from saved Ideas.
- Add optional provider/API execution pools for shared concurrency/rate-limit ceilings.
- Add optional local hardware pools for shared GPU resource limits.
- Extend AI Jobs with pause/resume, priority/reorder, richer parent/child progress and clearer project/character names.
- Consider scheduler fairness refinements so one large parent build cannot dominate all eligible Text slots.
- Consider a **Custom Section Build** strategy for user-defined request batches while retaining validation and deterministic assembly.
- Expand Diagnostics into optional recent-attempt history/retry tooling if real provider use shows value.
- Evaluate a pending-message attachment strip and optional per-message attachment association while retaining long-lived Reference Context.
- Decide whether Blueprint supplementary material needs a dedicated review dialog.
- Revisit full-Workspace synthesis only if it composes through the validated parity pipeline.
- Improve reporting of exactly which Generation Groups/components participated in a result.
- Clarify Blueprint handoff, Detailed Workspace Draft, Generate Character, Controlled Build, AI Suggest and manual authoring.
- Continue Relationship Graph, Route Graph and Linked Variant usability work.
- Continue Library organisation/search/filter polish and large-library performance work.
- Add more template authoring/validation tools and clearer generation-contract/dependency documentation.
- Improve import/export diagnostics and compatibility reporting for external Character Card ecosystems.
- Continue V1 workflow parity only where it improves V2 rather than reproducing obsolete architecture.

## Level and Content Tools

Character Card Forge is an authoring application rather than a level-based game. The equivalent content-tool priority is externally editable, versioned templates, `.ccfchar` interchange, project packages, lorebooks, Idea Notebook entries, Collaborator source snapshots, Image creative catalogs/presets/Generation Profiles and schema/editor tooling. Loading and saving should continue to use the same underlying models exposed to authoring tools.

## Technical Improvements

- Keep generation services modular and preserve older project/card compatibility as schemas evolve.
- Treat runtime generation-service composition as a capability-tested compatibility boundary.
- Keep historical hotfix behaviour as active-leaf regression invariants rather than depending on exact old filenames/inheritance depth.
- Keep first-save persistence content-aware.
- Keep multi-source collections versioned/backwards-compatible and preserve source IDs/types/roles/provenance.
- Keep raw Collaborator evidence separate from AI-facing normalized source data.
- Keep Character Card metadata and Vision evidence independently provenance-linked.
- Keep all dynamic Reference Context surfaces under one scroll boundary and maintain composer visibility against native-window bounds.
- Keep each AI worker's request/retry/repair/Diagnostics/cancellation state isolated.
- Preserve deterministic Safe Section dependency/context/template order.
- Maintain the representative versioned regression registry as a release compatibility boundary.
- Continue Godot 4.7.x warning-as-error hygiene.
- Keep large-library pickers index-based and bounded; load full data only after selection.
- Audit awaited/deferred UI callbacks for node/tree validity when controllers can be replaced.
- Keep detached tools synchronized through explicit signals/stable IDs.
- Keep Image capability caches per Image profile and version their normalized format.
- Maintain backward conversion from legacy Image capability cache shapes while those profiles remain in active use.
- Keep Creative Prompt Composer data separate from provider technical settings.
- Normalize provider model capabilities behind one CCF model rather than leaking provider response shapes throughout UI code.
- Preserve provider-supported parameter values verbatim where providers treat them as opaque strings.
- Keep unknown capability states explicit; only explicit negative metadata/user configuration becomes `unsupported`.
- Retain capability provenance/confidence through cache, UI and debugging paths.
- Keep backend/model support separate from Image Studio `execution_ready`.
- For rich provider discovery, cache full model records and retain the endpoint/fetch time so stale metadata is visible and refreshable.
- Never silently replace a selected model merely because it vanished from the latest provider catalog.
- Dynamic provider parameters may add to a request but must never overwrite CCF's authoritative core model/prompt/count/size fields.
- For Forge/A1111, distinguish backend endpoint capabilities from per-checkpoint/model-family assumptions and allow explicit overrides.
- Keep local model-family defaults as workflow hints only; capability state changes require backend/provider evidence or explicit user overrides.
- Keep checkpoint profile data keyed by stable local checkpoint ID so one provider can hold different assumptions/defaults for different installed models.
- For ComfyUI, keep workflow parameter mapping versioned and separate from arbitrary workflow JSON.
- Provider-specific rich discovery should be cacheable and refreshable; opening Image Studio must not block on network discovery.
- Passive capability inspection, model browsing and preset editing must not spend generation tokens/credits.
- Keep Character Text/Vision and Image profile lookup paths separate at every UI/service boundary.
- Keep Image Studio's embedded-page presentation as the user-facing contract even when a Window controller remains internally.
- Preserve the explicit-action boundary for AI image prompting: passive refresh/search is provider-free, Generate Prompt uses Text AI, Local Fallback never calls a provider.
- Keep generated-image records backwards-compatible as richer capability/settings/provenance metadata is added.
- Keep Image Studio tab layout as presentation only; moving a control between tabs must not create duplicate generation state.
- Keep normal Godot import/open operations checkout-clean.
- Replace the temporary `.gd.uid` ignore policy with a deliberate canonical migration later.
- Keep release/update executable modes under version control.
- Keep persistent app-level state under `user://` separate from portable project/card data unless explicitly included for portability.
- Keep Idea Notebook persistence independent of Character Projects and generation-service topology.
- Keep Collaborator source seeding public/structured rather than manipulating private composer state.
- Keep completion/refinement writes project-scoped, selection-based, stale-source checked and non-destructive.
- Validate provider envelopes before inherited parsing layers and report malformed failures once through the normal Diagnostics path.
- Continue reducing synchronous whole-library work from interactive paths.
- Keep attachment decoding/classification separate from UI composition and project-write boundaries.
- Keep Generation Component/section dependency semantics data-driven.
- Treat Generation Concept Blueprint as preserved source rather than disposable intermediate text.
- Carry `generation.template_id` through character-creation handoffs.
- Keep Diagnostics credential-safe, binary-free, bounded and lazily rendered.
- Treat release version synchronization as one generated transaction owned by `set_version.py`.
- Keep regression subprocesses on the approved Godot binary consistently; eliminate stale historical per-workflow version assumptions over time.
- Replace noisy arbitrary-text `JSON.parse_string()` probes with quiet parse paths where normal non-JSON text is expected.
- Continue headless resource/ObjectDB/RID cleanup, especially Image Studio teardown, without treating leak-warning cleanup as functional failure.

## Polish

- Improve semantic colour/theme consistency, keyboard navigation, detachable-window behaviour, multi-monitor use, resizing and long-text editing.
- Improve visible progress/error states for long AI operations.
- Improve queue labels so project, character, workflow, role, provider, model, section and dependency state are legible without opening Diagnostics.
- Improve Idea Notebook browsing as real libraries grow.
- Improve source-aware Collaborator UX with clearer provenance/conflict/target/reference/completion guidance.
- Keep Image Studio structured creative controls compact through progressive disclosure rather than one giant wall of dropdowns.
- Keep common creative controls easy to use while provider/model-specific advanced controls appear only when relevant.
- Continue replacing silent button no-ops with visible actionable status messages.

## Long-Term Ideas

- Expand graph tooling into richer character/route planning without contaminating exported card data.
- Make Character Collaborator capable of increasingly sophisticated project-wide creative planning while keeping brainstorming/canonical boundaries explicit.
- Add navigable creative lineage such as Characters created from this Idea, Ideas involving this character, future/past variants, side-character promotions, descendants/family trees and related Collaborator sessions.
- Continue supporting portable user-created templates/content and external AI-assisted authoring workflows.
- Let Image Studio presets/Generation Profiles become portable authoring assets where doing so does not expose credentials or machine-specific local paths.
- Consider richer automatic ComfyUI workflow inspection after explicit workflow mapping is stable.
- Consider durable server-owned background jobs for future remote/mobile workflows while keeping generation logic shared and credentials server-side.

## Deferred / Experimental Ideas

- The standalone v0.15.12–v0.15.14 full-Workspace synthesis shortcut is not the normal Generate Character path because it bypassed the established validation pipeline. Any revival must compose with that pipeline.
- Provider-specific concurrency heuristics remain opt-in until CCF can model limits without weakening generic providers.
- Shared GPU resource pools remain deferred until real local Vision/Image testing establishes useful controls.
- Persistent local queue recovery across application restarts remains deferred; current queues are process-local.
- More elaborate graph-layout automation beyond the current draggable anchor-based system.
- Advanced context compression beyond explicit user-triggered summarisation.
- Fully automatic arbitrary-ComfyUI-workflow interpretation is experimental; explicit Generation Profile mapping remains the dependable path first.