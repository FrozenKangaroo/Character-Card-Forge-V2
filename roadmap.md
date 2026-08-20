# Character Card Forge — Project Roadmap

## Project Vision

Rebuild Character Card Forge as a responsive native Godot desktop application for creating, generating, editing, organising, importing, exporting, analysing, illustrating and collaboratively developing AI roleplay character cards.

The original PyWebView V1 application remains a feature/behaviour reference rather than an architecture specification. Useful V1 behaviour should be re-expressed as maintainable Godot-native systems with versioned external data and portable Character Card / `.ccfproject` content.

## Core Design Principles

- Godot-native desktop UI with detachable tool windows where useful.
- Character project JSON/files are the source of truth; the legacy V1 database is not.
- Versioned, externally inspectable templates, authoring schemas, lorebooks, series data, settings, project packages, Idea Notebook data, Collaborator source data, Image creative catalogs/presets and interchange formats.
- Clear separation between character data, project-shared context, AI generation, providers, images, imports/exports, library indexing and tooling.
- OpenAI-compatible and local/self-hosted Text, Vision and Image providers remain first-class targets; Text/Vision roles and Image Generation remain independently configurable.
- New systems extend the central project model rather than create parallel character copies.
- Existing character/card data must not be destroyed by unchecked previews, failed reviews, unrelated regeneration, partial imports, exploratory AI conversation or unreviewed Collaborator output.
- Conversational brainstorming never becomes canonical project data until the user explicitly applies, generates or imports it.
- Stable internal IDs should survive user-facing renames where practical.
- Large-library selectors should use searchable lightweight indexes rather than unbounded dropdowns.
- V1 parity is judged by useful workflow capability, not literal screen-for-screen reproduction.
- Collaborator source handoffs preserve structured source snapshots/provenance. At most one existing Workspace character is the explicit refinement target.
- Character Card PNG/APNG metadata and Vision-derived evidence stay linked but distinct; embedded UserPersona/user-profile residue is excluded from AI-facing source context by default.
- Collaborator transcript deletion is chronological rewind and never silently removes independent Reference Context.
- Existing-character refinement remains selection-based, stale-source/conflict checked and non-destructive by default.
- Linked Variants may remain sparse internally while exports materialise complete standalone cards.
- Provider/model token limits remain data-driven and role-specific; concurrent AI work keeps isolated request/job state and is selectively cancellable.
- Safe generation fails narrowly and preserves accepted sections. Failed attempts remain inspectable through credential-redacted, binary-free, bounded Diagnostics.
- Forward+ is the standard desktop renderer with Compatibility/OpenGL fallback.
- Normal Godot import/open operations leave the Git checkout clean. `update.sh` and `release.sh` fail closed around real user work.
- Every major supported workflow has representative cross-feature regression coverage.
- Image provider discovery belongs to Image profiles and never leaks into Character Text/Vision profile configuration.
- Image Studio is first-class main navigation; passive browsing/search/preset editing never spends provider tokens.
- **Generate Prompt from Character** is an explicit Text-role AI workflow; deterministic local prompt construction remains available separately.
- **Creative image intent is provider-independent; generation capabilities are provider, backend, model or workflow specific.**
- Image Studio does not hardcode per-model capability tables when authoritative runtime discovery exists; missing metadata remains `unknown`, not automatically unsupported.
- Capability provenance is retained across provider metadata, backend knowledge, model-family profiles, ComfyUI workflow mappings, inference and explicit user overrides.
- Backend/model support is distinct from current Image Studio execution readiness.
- Provider-specific parameter metadata is additive and unknown future parameters should be preserved.
- Local Stable Diffusion / Forge / A1111 and ComfyUI remain first-class Image Studio targets alongside cloud APIs.
- ComfyUI is a workflow execution backend; capabilities may belong to a saved Generation Profile/workflow rather than one checkpoint.
- Image Studio uses progressive disclosure: common creative workflow stays prominent while optional technical/provider controls live in dedicated surfaces.
- Image-input operations are explicit workflow state: source images, masks and references are never inferred from unrelated Vision attachments.
- Non-A1111 image-input transports require explicit provider/profile mapping rather than guessed API compatibility.
- Image Style Presets contain creative intent only; provider/model/checkpoint/workflow execution settings remain separate.
- Cross-tool image handoffs preserve raw image evidence and provenance.
- Idea Generator detail depth is author intent, remains versioned/data-driven, and must never weaken `{{user}}` agency safeguards or invent unnecessary user backstory.

## Current Development Phase

**v0.16.9 — Image Style Presets**

v0.15.40 remains the public release baseline. The v0.16.x development line now includes Collaborator rewind (v0.16.0), normalized Image capability architecture (v0.16.1), structured creative prompt composition (v0.16.2), tabbed Image Studio workflow (v0.16.3), dynamic provider model capabilities (v0.16.4), local Forge/A1111 checkpoint profiles (v0.16.5), ComfyUI workflow Generation Profiles (v0.16.6), Idea Generator detail levels (v0.16.7), and explicit Image-to-Image / Reference / Inpainting operations (v0.16.8).

v0.16.9 adds reusable provider-independent **Image Style Presets**. A versioned external built-in catalog provides starter styles; user-created **Global** presets are reusable across projects; **Project Visual Identity** supplies a project-level default; and **Character Default** provides an optional per-character override. Character defaults take precedence over project identity.

Applying a style preset populates the existing v0.16.2 Structured Creative controls and leaves the editable final Image Prompt untouched until the author explicitly composes it. Presets never store provider, model, checkpoint, sampler, steps, CFG, seed, transport or ComfyUI workflow settings.

The running development build displays **v0.16.9**, uses Godot **4.7.1 stable**, keeps Forward+ with Compatibility/OpenGL fallback and retains the complete v0.16.8→v0.15.40 safety baseline. Public release metadata remains at v0.15.40 until `release.sh` performs a release transaction.

## Completed

### v0.16.9 — Image Style Presets

- Added versioned external `data/image_style_presets_v0169.json` with portable starter styles referencing stable v0.16.2 creative IDs.
- Added `CCFImageStylePresetServiceV0169` for built-in loading, reusable Global preset persistence, project visual identity, character defaults and precedence.
- Added Image Studio controls to Apply, Save Global, Set Project Identity, Set Character Default, clear defaults and delete Global presets.
- Kept style presets strictly provider-independent: technical provider/model/checkpoint/workflow settings are excluded.
- Project/character defaults populate Creative controls without silently overwriting the final prompt or making provider calls.
- Added focused v0.16.9 regression coverage, inherited regression manifest, Godot 4.7.1 CI and `docs/v0169-image-style-presets.md`.

### v0.16.8 — Image-to-Image, Reference Images and Inpainting

- Added explicit Text→Image, Image→Image, Inpainting and Reference Images operations.
- Added gallery/external source images, multiple references, mask selection, denoise strength and mask blur.
- Added live Forge/A1111 `/sdapi/v1/img2img` transport and explicit non-A1111 `image_input_transport_v0168` mappings.
- Preserved ComfyUI workflow reference mappings as offline-only until live queue/upload/history transport exists.
- Extended generated-image provenance and added focused regressions/CI/docs.

### v0.16.7 — Idea Generator Detail Levels

- Added versioned/data-driven Quick, Standard, Detailed and Extended modes.
- Added live Detail selector, Standard fallback/session persistence, prompt-depth instructions and profile-budget multipliers.
- Preserved Idea Notebook, Structured Builder, Collaborator handoffs and `{{user}}` agency validation/repair.

### v0.16.6 — ComfyUI Workflow Generation Profiles

- Added versioned saved workflow profiles with complete workflow snapshots separate from explicit CCF mappings.
- Added Prompt, Negative Prompt, Seed, Steps, CFG, Width, Height, Denoise and Reference Image mappings.
- Added deterministic offline materialisation/validation while preserving custom nodes; live ComfyUI transport remains deferred.

### v0.16.5 — Local Stable Diffusion / Forge / A1111 Profiles

- Added versioned local model-family defaults and checkpoint-specific records with Auto / Supported / Unsupported / Unknown overrides.
- Added preferred resolution/sampler/steps/CFG defaults and Local checkpoint profile controls.

### v0.16.4 — Dynamic Provider Model Capabilities

- Added rich per-profile model catalogs, preserved unknown provider fields, cached provenance/staleness and dynamic Advanced controls.
- Provider parameters remain additive and cannot overwrite authoritative CCF core fields.

### v0.16.3 — Image Studio Tabbed Workflow

- Added Prompt & Results, Creative and Advanced tabs while preserving existing Image Studio state.

### v0.16.2 — Structured Creative Prompt Composer

- Added versioned external provider-independent creative catalog and deterministic composition for style, medium, composition, lighting, palette, material, atmosphere and modifiers.

### v0.16.1 — Image Studio 2 Capability Foundation

- Added normalized supported/unsupported/unknown capabilities with provenance/confidence and separate execution readiness.

### v0.16.0 — Character Collaborator Conversation Rewind

- Added Delete From Here chronological rewind with summary invalidation and preserved independent Reference Context.

### v0.15.40 — Public Release Baseline

- Public release promoted on 2026-08-09 after Godot 4.7.1 validation and inherited release regressions passed.
- The v0.15 line delivered modern Collaborator, Safe Section generation, AI Jobs, Idea Notebook, multi-source provenance, Vision/Card dual ingestion, Image Studio integration, scalable character selection and release/update hardening.

### Historical Milestone Index

Detailed history remains preserved in versioned docs, PRs, tests/manifests and Git history.

- v0.15.40-hotfix1..9 — Collaborator source/layout/runtime fixes, Diagnostics hardening, Godot 4.7.1 release gate, updater recovery.
- v0.15.39 + hotfixes — Character Card PNG/APNG metadata + Vision dual ingestion and UserPersona exclusion.
- v0.15.38 + hotfix1 — scalable Image Studio character picker and safer updater local-change handling.
- v0.15.37 + hotfix1 — multi-source Collaborator and Safe Section contamination protection.
- v0.15.36 + hotfixes — Compare & Apply, Forward+, default template, AI Ideas agency/backstory validation, empty-project save guard.
- v0.15.35 — Collaborator completion routing.
- v0.15.34 — Existing Character → Collaborator and Godot 4.7.1 baseline.
- v0.15.33 + hotfixes — structured Collaborator source context, Builder/Idea handoffs and user-agency contract.
- v0.15.32 + hotfix1 — Idea Notebook and layout fixes.
- v0.15.31 — AI Jobs visibility/selective cancellation.
- v0.15.28..30 — Image Studio live provider/project state, embedded Studio + AI prompt generation and wrapping.
- v0.15.26..27 — concurrent AI scheduler and runtime cleanup.
- v0.15.22..25 — Safe Section Build, Diagnostics, token settings/budget and live service wiring.
- v0.15.20..21 — broad regression safety and unified Collaborator attachments.
- v0.15.18..19 — checkout hygiene and release checkout selection.
- v0.15.12..17 — synthesis experiments, Blueprint-first handoff, restored generation pipeline and supplementary materialisation.
- v0.15.10..11 — FileDialog state and visible Vision Analysis.
- v0.15.0..9 — Collaborator foundation, persistence/UX, Vision pipeline/routing/limits and token/context controls.
- v0.14.x — relationship/route graphs, Linked Variants, `.ccfchar`, focused builders, Lorebook, Idea generation, Manual Guided parity, Alternative Greetings and Library assignment UX.

## In Progress

- Runtime-test v0.16.9 built-in/Global/Project/Character style precedence with real saved projects and multiple Image providers.
- Confirm project/character styles survive repeated Studio/project reloads and never mutate provider technical settings.
- Runtime-test v0.16.8 Image→Image and Inpainting against a real Forge/A1111 profile, including gallery/external inputs.
- Runtime-test explicit non-A1111 `image_input_transport_v0168` mappings against representative JSON Image providers.
- Confirm source/reference/mask selection remains non-canonical until generation occurs.
- Runtime-test v0.16.7 Quick/Standard/Detailed/Extended against representative Text profiles and compare useful depth/token use.
- Follow up Idea Generator diagnostics: clamp detail-expanded output budgets against known model/provider output ceilings and reduce false-positive agency repair triggers such as genuinely conditional `if {{user}} prefers...` wording.
- Preserve usable first-pass Idea results when a semantic repair request fails transiently, with clear warning/retry UX rather than unnecessarily losing the whole batch.
- Runtime-test v0.16.6 against real ComfyUI API workflow exports; implement live ComfyUI queue/upload/history transport without reusing A1111/OpenAI request semantics.
- Decide the cleanest first-class ComfyUI Image-profile/backend representation before live transport promotion.
- Continue runtime testing of v0.16.5 local checkpoint defaults/overrides, v0.16.4 rich provider metadata, v0.16.3 layout, v0.16.2 composition and v0.16.0 rewind persistence.
- Continue hardening forward-compatible tests so later shells/services cannot drop historical hotfix invariants.
- Continue V1 parity review where V1 still has useful workflows V2 has not surpassed.

## Next Up — v0.16.x

### v0.16.10 — Studio Workflow & Results Polish

- Improve generation history and preserve exact composed prompt plus provider/model/settings used for each result.
- Add robust Reuse Settings, Regenerate, New Seed/Variation, comparison, favourites and batch-result workflows where supported.
- Improve project/character asset assignment and recovery.
- Surface optional cost information without making paid-provider metadata a requirement for local backends.
- Continue refining tab/progressive-disclosure layout based on real desktop use.

## Planned — v0.17.x and Later Authoring Work

### Structured Image Studio → Collaborator handoff

- Add **Send to Character Collaborator** from an Image Studio result.
- Treat the generated image as a structured Collaborator source rather than an anonymous attachment.
- Preserve raw image provenance plus useful generation prompt/model/profile/settings metadata.
- Optionally run/use Vision analysis while keeping Vision-derived evidence distinct from the image itself.
- Allow the image to become Reference Context for an existing target or seed a new Collaborator workflow.
- Keep all canonical character writes explicit.

### Other accepted v0.17.x+ work

- Improve multi-source precedence/conflict presentation, especially Card metadata vs linked Vision evidence.
- Add denser/multi-selection source controls for family/cast/ensemble Collaborator sessions if runtime use confirms need.
- Extract the v0.15.38 character-search/index behaviour into a reusable Character Picker for Collaborator, relationship tools, Image Studio and other large-library workflows.
- Preserve source/relationship provenance for Collaborator-created characters while keeping exports standalone.
- Suggest Relationship Graph edges without silently making them canonical.
- Extend multi-source Collaborator for richer family, relationship, cast, scenario, continuity and ensemble development while preserving one-target safety.
- Expose derivation/lineage history for future/past variants, side-character promotions, descendants, related characters and characters created from Ideas.
- Add optional provider/API execution pools and local hardware/GPU pools.
- Extend AI Jobs with pause/resume, priority/reorder, richer parent/child progress and clearer project/character labels.
- Consider scheduler fairness refinements and a Custom Section Build strategy while retaining validation/deterministic assembly.
- Expand Diagnostics into optional recent-attempt history/retry tooling if provider use shows value.
- Evaluate pending-message attachment strips/per-message attachment association while retaining long-lived Reference Context.
- Decide whether Blueprint supplementary material needs a dedicated review dialog.
- Revisit full-Workspace synthesis only if it composes through the validated parity pipeline.
- Improve Generation Group/component participation reporting and clarify Blueprint/Detailed Draft/Generate Character/Controlled Build/AI Suggest/manual authoring boundaries.
- Continue Relationship Graph, Route Graph, Linked Variant, Library/search/filter, template tooling and import/export diagnostics work.
- Continue V1 parity only where it improves V2 rather than reproducing obsolete architecture.

## Level and Content Tools

Character Card Forge is an authoring application rather than a level-based game. The equivalent content-tool priority is externally editable/versioned templates, `.ccfchar` interchange, project packages, lorebooks, Idea Notebook entries, Collaborator source snapshots, Image creative catalogs/presets/Generation Profiles and schema/editor tooling. Loading and saving should use the same underlying models exposed to authoring tools.

## Technical Improvements

- Keep generation services modular and preserve older project/card compatibility as schemas evolve.
- Treat runtime generation-service composition as a capability-tested compatibility boundary; historical hotfix behaviour should be active-leaf invariants rather than exact filename/inheritance-depth assumptions.
- Keep first-save persistence content-aware, source collections versioned/backwards-compatible and raw evidence distinct from normalized AI-facing context.
- Keep AI worker request/retry/repair/Diagnostics/cancellation state isolated and Safe Section dependency/context/template order deterministic.
- Maintain the versioned regression registry as a release compatibility boundary and Godot 4.7.x warning-as-error hygiene.
- Keep large-library pickers index-based/bounded and audit deferred UI callbacks for node/tree validity.
- Keep detached tools synchronized through explicit signals/stable IDs.
- Keep Image capability caches per Image profile, preserve legacy conversion, unknown states and provenance/confidence.
- Keep Creative Prompt Composer and Image Style Preset data separate from provider technical settings.
- Normalize provider/model capabilities behind one CCF model and preserve opaque provider parameter values/unknown fields.
- Never silently replace a selected model because it disappeared from discovery; dynamic provider parameters cannot overwrite CCF core model/prompt/count/size.
- Keep Forge/A1111 endpoint capability separate from checkpoint-family assumptions; `/sdapi/v1/img2img` remains authoritative for live img2img/inpainting.
- Keep source/reference/mask inputs explicit and require non-A1111 `image_input_transport_v0168` mappings before image-input execution readiness.
- Keep local family defaults as workflow hints; capability state changes require provider evidence or explicit overrides.
- Keep checkpoint profiles keyed by stable checkpoint ID.
- Keep ComfyUI workflow mapping versioned/separate from arbitrary workflow JSON, preserve custom nodes, and do not claim execution readiness until live transport is tested.
- Provider discovery must be cacheable/refreshable; opening Studio and passive browsing/preset editing must not spend credits.
- Keep Character Text/Vision and Image profile lookup paths separate.
- Preserve explicit action boundaries for AI image prompting; generated-image records remain backwards-compatible as provenance grows.
- Keep tab layout presentation-only and avoid duplicate generation state.
- Keep Idea Detail data backwards-compatible, unknown IDs falling back to Standard, and output budgets based on profile/model limits rather than hardcoded provider assumptions.
- Keep normal Godot import/open checkout-clean; revisit canonical `.gd.uid` migration later.
- Keep release/update executable modes version-controlled and release version synchronization owned by `set_version.py`.
- Keep persistent app state under `user://` separate from portable project/card data unless deliberately included.
- Keep Idea Notebook independent of Character Project persistence and generation-service topology.
- Keep Collaborator source seeding public/structured and completion/refinement project-scoped/stale-source checked/non-destructive.
- Validate provider envelopes before parsing layers and report malformed failures once through bounded Diagnostics.
- Continue reducing synchronous whole-library work from interactive paths.
- Keep attachment decoding/classification separate from UI composition/project-write boundaries.
- Keep Generation Component/section dependency semantics data-driven and Generation Concept Blueprint preserved as source.
- Carry `generation.template_id` through character-creation handoffs.
- Keep regression subprocesses on the approved Godot binary and replace noisy arbitrary-text JSON probes with quiet parsing where appropriate.
- Continue headless ObjectDB/resource/RID cleanup without treating leak warnings as functional failure.

## Polish

- Improve semantic colour/theme consistency, keyboard navigation, detachable-window behaviour, multi-monitor use, resizing and long-text editing.
- Improve visible progress/error states for long AI operations and queue labels for project/character/workflow/role/provider/model/section/dependency state.
- Improve Idea Notebook browsing and source-aware Collaborator provenance/conflict/target/reference/completion guidance.
- Keep Image Studio creative controls compact through progressive disclosure and provider-specific controls visible only when relevant.
- Continue replacing silent button no-ops with visible actionable status messages.

## Long-Term Ideas

- Expand graph tooling into richer character/route planning without contaminating exported card data.
- Make Collaborator increasingly capable of project-wide creative planning while keeping brainstorming/canonical boundaries explicit.
- Add navigable creative lineage across Ideas, characters, variants, side-character promotions, descendants/family trees and Collaborator sessions.
- Continue portable user-created templates/content and external AI-assisted authoring workflows.
- Let Image Studio presets/Generation Profiles become portable authoring assets where doing so does not expose credentials/machine-specific paths.
- Consider richer automatic ComfyUI workflow inspection after explicit mapping is stable.
- Consider durable server-owned background jobs for future remote/mobile workflows while keeping generation logic shared and credentials server-side.

## Deferred / Experimental Ideas

- The v0.15.12–v0.15.14 full-Workspace synthesis shortcut remains outside the normal Generate Character path unless it can compose through the validated parity pipeline.
- Provider-specific concurrency heuristics remain opt-in until limits can be modeled safely.
- Shared GPU resource pools remain deferred until real local Vision/Image testing establishes useful controls.
- Persistent local queue recovery across application restarts remains deferred; current queues are process-local.
- More elaborate graph-layout automation beyond the current draggable anchor system.
- Advanced context compression beyond explicit user-triggered summarisation.
- Fully automatic arbitrary-ComfyUI-workflow interpretation remains experimental; explicit Generation Profile mapping comes first.
