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
- Large-library selectors should use searchable lightweight indexes rather than unbounded dropdowns.
- V1 parity is judged by useful workflow capability, not literal screen-for-screen reproduction.
- Generated ideas remain disposable until the user explicitly saves them; persistent Idea Notebook material is independent versioned app data.
- Collaborator source handoffs preserve structured source snapshots and provenance rather than paste opaque text into private UI state.
- Multi-source Collaborator sessions keep every character, Idea, external card, and pasted source individually identifiable. At most one existing Workspace character is the explicit refinement target; all other sources remain read-only references.
- Collaborator source ingestion preserves raw evidence separately from AI-facing normalised snapshots.
- Character Card PNG/APNG metadata and Vision-derived evidence stay linked but distinct; neither representation silently overwrites the other.
- Embedded UserPersona/user-profile residue is excluded from AI-facing source context by default without deleting the raw source.
- Collaborator source-aware reasoning distinguishes established facts, author-requested changes, and proposals.
- Collaborator transcript deletion is chronological rewind: deleting an author message removes that message and all later transcript messages, invalidates derived summaries when needed, and never silently removes independent Reference Context.
- Existing-character refinement remains selection-based, conflict-checks newer manual edits, and is non-destructive by default.
- Linked Variants may remain sparse internally while exports materialise complete standalone cards.
- Visual graph layout metadata stays separate from authoritative character, relationship, and route data.
- Long-running AI collaboration accounts for model context limits and keeps lossy summarisation explicit.
- Provider/model token limits remain data-driven and role-specific.
- Concurrent AI work keeps isolated request/job state, is inspectable, and is selectively cancellable.
- Parallel generation remains deterministic: dependency/template order, not network completion timing, determines context and final assembly.
- Safe generation fails narrowly and preserves accepted sections.
- Safe Section output must match requested field/component identity as well as JSON/type contracts.
- Failed provider generations remain inspectable through credential-redacted, binary-free, bounded Diagnostics.
- Forward+ is the standard desktop renderer with Compatibility/OpenGL fallback.
- Normal Godot import/open operations leave the Git checkout clean.
- `update.sh` and `release.sh` fail closed around real user work and treat release metadata as one generated transaction.
- Every major supported workflow has representative cross-feature regression coverage.
- Automated tests that exercise `user://` run in isolated temporary app-data directories.
- Image provider discovery belongs to Image profiles and never leaks into Character Text/Vision profile configuration.
- Image Studio is a first-class main-navigation page; passive browsing/search never spends provider tokens.
- **Generate Prompt from Character** is an explicit Text-role AI workflow; deterministic local prompt construction remains available separately.
- Long-form Image Prompt and Negative Prompt fields wrap visually without mutating stored text.
- **Creative image intent is provider-independent; generation capabilities are provider, backend, model, or workflow specific.**
- Image Studio must not hardcode per-model capability tables when authoritative runtime discovery exists.
- Missing capability metadata is not proof of lack of support. Capability state may be `supported`, `unsupported`, or `unknown`.
- Capability provenance is retained. Provider metadata, backend knowledge, model-family profiles, ComfyUI workflow mappings, inference, and explicit user overrides are distinguishable sources.
- A backend/model capability is distinct from current Image Studio execution readiness; the Studio may know a backend supports an operation before its own workflow exposes it.
- Provider-specific parameter metadata is additive. Unknown future supported parameters should be preserved rather than silently discarded.
- Local Stable Diffusion / Forge / A1111 and ComfyUI remain first-class Image Studio targets alongside paid/cloud APIs.
- ComfyUI is treated as a workflow execution backend; capabilities may belong to a saved Generation Profile/workflow rather than one checkpoint alone.

## Current Development Phase

**v0.16.1 — Image Studio 2 Capability Foundation**

v0.15.40 remains the public release baseline. v0.16.0 started the new development line with Character Collaborator conversation rewind; v0.16.1 begins the larger Image Studio 2 cycle.

The current build introduces a versioned normalized image capability document, tri-state capability semantics, provenance/confidence, backend-support versus Studio-execution separation, backward-compatible conversion of v0.15.28 capability caches, a rich provider-model record parser, and an explicit future user-override layer.

The live Image Studio exposes a passive capability summary and **Capability Details…** inspector. These controls do not spend tokens or perform provider requests by themselves.

Provider records can preserve capability flags, arbitrary `supported_parameters`, provider-specific resolution strings, max/fixed image counts, speed tiers, pricing metadata, content flags, and unknown additive parameters. Forge/A1111 discovery is normalized into the same model while generic OpenAI-compatible APIs retain `unknown` states where their `/models` response cannot describe image features reliably.

The running development build displays **v0.16.1**, uses Godot **4.7.1 stable**, keeps Forward+ with Compatibility/OpenGL fallback, and retains the complete v0.16.0/v0.15.40 safety baseline. Release metadata remains at the last promoted public version until `release.sh` performs the next release transaction.

## Completed

### v0.16.1 — Image Studio 2 Capability Foundation

- Added `CCFImageModelCapabilityServiceV0161` with a versioned normalized capability document.
- Added `supported` / `unsupported` / `unknown` semantics so incomplete discovery does not create false negatives.
- Added operation-level `execution_ready` separately from backend/model capability state.
- Added provenance sources for provider, backend, model family, workflow, inference, and user override plus separate confidence.
- Added rich provider-model normalization for IDs/names/descriptions/tags, capability flags, arbitrary supported parameters, resolution choices, image-count limits, rendering-speed tiers, pricing, and content metadata.
- Unknown additive provider parameters remain represented as generic descriptors.
- Existing Forge/A1111 model/sampler discovery normalizes into the same capability representation.
- Generic OpenAI-compatible discovery uses conservative unknown-safe defaults.
- Added user-override capability layering for later local-model/profile UI.
- Added `CCFImageCapabilityCacheServiceV0161`, which reads legacy v0.15.28 discovery and writes normalized metadata without destructive migration.
- Added a passive live capability summary and **Capability Details…** inspector to Image Studio.
- Added `tools/test_v0161_image_studio_foundation.gd`, `tools/regression_suites_v0161.json`, dedicated Godot 4.7.1 CI, and `docs/v0161-image-studio-foundation.md`.

### v0.16.0 — Character Collaborator Conversation Rewind

- Added **Delete From Here…** to author messages.
- Rewind truncates the selected message and all later transcript history, including assistant variants.
- Summaries containing deleted history are invalidated; summaries strictly before the rewind point remain valid.
- Pending regeneration state is cleared and rewind is blocked during an active Collaborator generation.
- Structured TARGET/REFERENCE sources, Character Card metadata, attachments, and Vision Reference Context remain independently managed.
- Rewind persists through the existing independent Collaborator autosave store.
- Added real-main-scene regression coverage, v0.16.0 broad-regression inheritance, CI, and documentation.

### v0.15.40 — Public Release Baseline

- Public release promoted on 2026-08-09 after Godot 4.7.1 validation and all 76 inherited release regressions passed before staging.
- The v0.15 line delivered the modern Character Collaborator, Safe Section generation, AI Jobs, Idea Notebook, multi-source provenance, Vision/Card dual ingestion, Image Studio integration, scalable character selection, release/update hardening, and extensive runtime/UI regression coverage.
- v0.15.40-hotfix7 through hotfix9 closed the failed-Vision Diagnostics freeze path, exact Godot 4.7.1 release gate, nested assistant-response compatibility, and interrupted release-metadata updater recovery.

### Historical Milestone Index

Detailed implementation history remains preserved in versioned docs, pull requests, regression manifests/tests, and Git history. The milestone index below remains part of the roadmap so development history is understandable without reproducing every historical hotfix note inline.

- v0.15.40-hotfix1..6 — Collaborator Reference Context/source-row/helper/composer/resize structural fixes and runtime guards.
- v0.15.39 + hotfixes — Character Card PNG/APNG metadata + Vision dual ingestion, UserPersona exclusion, bounded chooser, warning cleanup.
- v0.15.38 + hotfix1 — scalable Image Studio character picker and safe `update.sh` handling of local `project.godot` drift.
- v0.15.37 + hotfix1 — multi-source Collaborator and Safe Section field-identity/contamination protection.
- v0.15.36 + hotfixes — Compare & Apply, Forward+, configured default template, AI Ideas agency/backstory validation, empty-project save guard.
- v0.15.35 — Collaborator completion routing.
- v0.15.34 — Existing Character → Collaborator and Godot 4.7.1 baseline.
- v0.15.33 + hotfixes — generic structured Collaborator source context, Builder/Idea handoffs, user-agency contract.
- v0.15.32 + hotfix1 — Idea Notebook and layout fixes.
- v0.15.31 — AI Jobs queue visibility/selective cancellation.
- v0.15.28..30 — Image Studio live provider/project state, embedded Studio + AI prompt generation, prompt wrapping.
- v0.15.26..27 — concurrent AI scheduler and runtime lifecycle cleanup.
- v0.15.22..25 — Safe Section Build, Diagnostics, token settings/budget, live service wiring.
- v0.15.20..21 — broad regression safety and unified Collaborator attachments.
- v0.15.18..19 — checkout hygiene and release checkout selection.
- v0.15.12..17 — full synthesis experiments, Blueprint-first handoff, restored generation pipeline, supplementary materialisation.
- v0.15.10..11 — persistent FileDialog state and visible Vision Analysis messages.
- v0.15.0..9 — Character Collaborator foundation, persistence/UX, Vision pipeline/routing/limits, token/context controls.
- v0.14.20..22 — relationship/route graph foundation, Linked Variants, `.ccfchar` interchange.
- v0.14.14..19 — focused builders, Lorebook generation/tools, Idea identity/POV/user-centric generation, detachable Lorebook, live Ideas wiring.
- v0.14.10..13 — related-character/AI variation, structured/unified Idea Generator, user-POV safety.
- v0.14.2..9 — transfer/text conventions, recoverable review, Manual Guided, Lorebook foundation, preview safety, component parity, Alternative Greetings, Library assignment UX.

## In Progress

- Runtime-test v0.16.1 on the normal desktop build: open Image Studio, switch between an OpenAI-compatible Image profile and a local Forge/A1111 profile, and confirm the capability summary/details update without triggering an AI/provider request.
- Confirm legacy cached Image profile discovery still populates existing model/sampler controls after the normalized cache layer is present.
- Runtime-test v0.16.0 rewind persistence and summary invalidation on a long real Collaborator conversation.
- Runtime-test v0.15.40-hotfix7 with a real provider-side Collaborator Vision failure and **View Diagnostics…**.
- Continue hardening forward-compatible tests so later shells/services cannot drop historical capabilities/hotfix invariants.
- Continue V1 parity review where V1 still has useful workflows V2 has not surpassed.

## Next Up — v0.16.x Image Studio 2

### v0.16.2 — Structured Creative Prompt Composer

- Add provider-independent **Visual Style** controls including Anime, Realistic/Photo, Hyper-real, Cinematic, Editorial, Illustration, 3D Render, Pixel Art, Poster, Claymation, Surrealism, Manga, Concept Art, Cel-shaded, Noir, Chibi, Line Art, Sketch, Game Splash Art, and Key Visual.
- Add **Medium** controls such as Watercolor, Oil Painting, Charcoal, Ink Wash, Marker Illustration, Collage, Mosaic, Papercraft, Stained Glass, Digital Painting, Acrylic, Gouache, Pencil, Pastel, Linocut, Embroidery, Clay Sculpture, and Voxel Art.
- Add **Colour Palette** controls including warm/cool tones, pastels, vibrant, earth tones, duotone, monochrome, grayscale, sepia, primary colours, rainbow, metallics, jewel tones, cyberpunk neon, autumn, deep-sea blues, forest greens, desert ochres, and other reusable palettes.
- Add **Lighting** controls including natural, light/shadow, volumetric, neon, golden hour, blue hour, backlight, god rays, studio, candlelight, street light, softbox, moonlight, fairy lights, rim light, ambient, overcast, firelight, and holographic/bioluminescent glow.
- Separate **Camera / Composition** from photographic exposure/look: close-up/full-body/wide shot, low/high/bird's-eye/worm's-eye/Dutch angles, silhouette, over-the-shoulder, symmetry, depth of field, bokeh, high/low key, long exposure, motion blur, etc.
- Separate **Material / Surface** from **Atmosphere / Environment**: metal/glass/wood/ceramic/plastic/crystal/fabric/paper/stone versus rain/bubbles/smoke/dust/fog/sand/water/frost/sparks.
- Add reusable **Modifiers** such as Keep Minimal, Rich Detail, Natural Texture, Premium Materials, Clean/Busy Background, Sharp/Soft Focus, Glossy/Matte Finish, and Motion Blur.
- Implement these through a reusable Prompt Composer service rather than UI-local string concatenation.
- Preserve the final composed prompt as editable text and show what structured controls contributed.

### v0.16.3 — Dynamic Provider Model Capabilities

- Add a dedicated rich model-discovery adapter for NanoGPT/provider APIs that expose model-specific `capabilities` and `supported_parameters`.
- Prefer provider-normalized model endpoints when available; retain compatibility fallbacks where necessary.
- Populate resolution/aspect-ratio/quality/speed/count/reference controls dynamically from authoritative model metadata.
- Treat provider resolution/size values as opaque model-specific strings rather than assuming `width x height` integers.
- Cache capability documents, refresh periodically/on demand, and handle disappeared/new models gracefully.
- Preserve additive future fields and use polished known controls plus safe generic fallbacks where metadata is sufficient.
- Add optional provider-supplied generation cost estimates where reliable pricing metadata is available.

### v0.16.4 — Local Stable Diffusion / Forge / A1111 Profiles

- Keep local generation first-class under the same normalized capability model.
- Combine backend discovery, model-family profiles, and explicit per-checkpoint user overrides rather than assuming all local checkpoints share identical capabilities.
- Add author-facing local capability/profile overrides for unusual/community models.
- Preserve discovered checkpoints, samplers, schedulers/LoRAs where available and expose only relevant controls.

### v0.16.5 — ComfyUI Workflow Generation Profiles

- Treat ComfyUI as a workflow execution backend rather than an A1111-style model endpoint.
- Save a Generation Profile that links a ComfyUI workflow to explicit CCF inputs/outputs.
- Map Prompt, Negative Prompt, Width/Height or Aspect Ratio, Steps, CFG/Guidance, Seed, Reference Image, Denoise/Strength, and other workflow-specific inputs as appropriate.
- Allow explicit mapping even if automatic node/input discovery is later added.
- Retain workflow provenance and unknown/additive fields.

### v0.16.6 — Image-to-Image, Reference, and Inpainting

- Support distinct **Text → Image**, **Image → Image**, **Reference Image Guidance**, and **Inpainting** modes when capabilities allow them.
- Show source-image, denoise/strength, mask, reference weight, preserve-composition, or equivalent controls only when meaningful for the selected backend/model/workflow.
- Reuse existing character/project artwork as explicit image-generation reference without conflating generation reference with Vision analysis.

### v0.16.7 — Image Style Presets

- Add global reusable Image Style presets.
- Add project-level visual identity presets.
- Add optional per-character image defaults.
- Keep creative presets portable across providers; technical provider/model settings remain separate.

### v0.16.8 — Studio Workflow & Results Polish

- Improve generation history and preserve the exact composed prompt plus provider/model/settings used for each result.
- Add robust Reuse Settings, Regenerate, New Seed/Variation, comparison, favourites, and batch-result workflows where supported.
- Improve project/character asset assignment and recovery.
- Surface optional cost information without making paid-provider metadata a requirement for local backends.

## Planned — v0.17.x and Later Authoring Work

The following previously planned work remains accepted; it is moved later rather than removed while v0.16.x concentrates on Image Studio 2.

- Improve multi-source precedence/conflict presentation, especially when structured Character Card metadata and linked Vision evidence disagree. Show evidence and author resolutions without inventing hidden precedence.
- Add multi-selection/denser source controls for family/cast/ensemble Collaborator sessions if runtime use confirms the need.
- Extract the v0.15.38 character-search/index behaviour into a reusable Character Picker for Collaborator, relationship tools, Image Studio and other large-library workflows.
- Preserve source/relationship provenance for Collaborator-created characters while keeping exports complete and standalone.
- Suggest appropriate Relationship Graph edges without silently making them canonical.
- Extend multi-source Collaborator for richer family, relationship, cast, scenario, continuity and ensemble development while preserving one-target safety.
- Expose derivation/lineage history such as future versions, side-character promotions, descendants, related characters, and characters created from saved Ideas.
- Add optional provider/API execution pools so profiles sharing one cloud provider can share concurrency/rate-limit ceilings.
- Add optional local hardware pools so Vision and Image providers using one GPU can share a configurable resource limit.
- Extend AI Jobs with pause/resume, priority/reorder, richer parent/child progress, and clearer project/character names.
- Consider scheduler fairness refinements so one large parent build cannot dominate all eligible Text slots.
- Consider a **Custom Section Build** strategy for user-defined request batches while retaining validation and deterministic assembly.
- Expand Diagnostics into optional recent-attempt history/retry tooling if real provider use shows value.
- Evaluate a pending-message attachment strip and optional per-message attachment association while retaining long-lived Reference Context.
- Decide whether Blueprint supplementary material needs a dedicated review dialog.
- Revisit full-Workspace synthesis only if it composes through the validated parity pipeline.
- Improve reporting of exactly which Generation Groups/components participated in a result.
- Clarify Blueprint handoff, Detailed Workspace Draft, Generate Character, Controlled Build, AI Suggest, and manual authoring.
- Continue Relationship Graph, Route Graph and Linked Variant usability work.
- Continue Library organisation/search/filter polish and large-library performance work.
- Add more template authoring/validation tools and clearer generation-contract/dependency documentation.
- Improve import/export diagnostics and compatibility reporting for external Character Card ecosystems.
- Continue V1 workflow parity only where it improves V2 rather than reproducing obsolete architecture.

## Level and Content Tools

Character Card Forge is an authoring application rather than a level-based game. The equivalent content-tool priority is externally editable, versioned templates, `.ccfchar` interchange, project packages, lorebooks, Idea Notebook entries, Collaborator source snapshots, Image creative presets/Generation Profiles, and schema/editor tooling. Loading and saving should continue to use the same underlying models exposed to authoring tools.

## Technical Improvements

- Keep generation services modular and preserve older project/card compatibility as schemas evolve.
- Treat runtime generation-service composition as a capability-tested compatibility boundary.
- Keep historical hotfix behaviour as active-leaf regression invariants rather than depending on exact old filenames/inheritance depth.
- Keep first-save persistence content-aware; empty never-saved shells stay in memory while existing projects are never silently deleted.
- Keep multi-source collections versioned/backwards-compatible and preserve source IDs/types/roles/provenance.
- Maintain one explicit existing-character target with arbitrary read-only references.
- Keep raw Collaborator evidence separate from AI-facing normalized source data.
- Keep Character Card metadata and Vision evidence independently provenance-linked.
- Keep all dynamic Reference Context surfaces under one scroll boundary and maintain composer visibility against actual native-window bounds.
- Keep each AI worker's request/retry/repair/Diagnostics/cancellation state isolated.
- Expose scheduler state through stable records; status UI should project authoritative job state.
- Preserve deterministic Safe Section dependency/context/template order.
- Maintain the representative versioned regression registry as a release compatibility boundary.
- Continue Godot 4.7.x warning-as-error hygiene with focused regressions where headless import cannot reproduce an editor warning.
- Keep large-library pickers index-based and bounded; load full data only after selection.
- Audit awaited/deferred UI callbacks for node/tree validity when controllers can be replaced.
- Keep detached tools synchronized through explicit signals/stable IDs.
- Keep Image capability caches per Image profile and version their normalized format.
- Maintain backward conversion from legacy Image capability cache shapes for as long as those profiles are in active use.
- Keep Creative Prompt Composer data separate from provider technical settings so a visual preset can move between NanoGPT, local SDXL, ComfyUI, OpenAI-compatible APIs, and future backends.
- Normalize provider model capabilities behind one CCF model rather than leaking provider response shapes throughout UI code.
- Preserve provider-supported parameter values verbatim where the provider treats them as opaque strings.
- Keep unknown capability states explicit; only explicit negative metadata/user configuration becomes `unsupported`.
- Retain capability provenance/confidence through cache, UI and debugging paths.
- Keep backend/model support separate from Image Studio `execution_ready` so future workflows can be developed incrementally without lying about backend capabilities.
- For Forge/A1111, distinguish backend endpoint capabilities from per-checkpoint/model-family assumptions and allow explicit overrides.
- For ComfyUI, keep workflow parameter mapping versioned and separate from arbitrary workflow JSON so mappings can evolve without rewriting original workflows.
- Provider-specific rich discovery should be cacheable and refreshable; opening Image Studio must not block on network discovery.
- Passive capability inspection, model browsing and preset editing must not spend generation tokens/credits.
- Keep Character Text/Vision and Image profile lookup paths separate at every UI/service boundary.
- Keep Image Studio's embedded-page presentation as the user-facing contract even when a Window controller remains internally.
- Preserve the explicit-action boundary for AI image prompting: passive refresh/search is provider-free, Generate Prompt uses Text AI, Local Fallback never calls a provider.
- Keep generated-image records backwards-compatible as richer capability/settings/provenance metadata is added.
- Keep normal Godot import/open operations checkout-clean.
- Replace the temporary `.gd.uid` ignore policy with a deliberate canonical migration later.
- Keep release/update executable modes under version control.
- Keep persistent app-level state under `user://` separate from portable project/card data unless explicitly included for portability.
- Keep Idea Notebook persistence independent of Character Projects and generation-service topology.
- Keep AI Ideas agency validation focused on durable user canon/consequential reactions rather than banning harmless scene logistics.
- Keep Collaborator source seeding public/structured rather than manipulating private composer state.
- Keep completion/refinement writes project-scoped, selection-based, stale-source checked, and non-destructive.
- Validate provider envelopes before inherited parsing layers and report malformed failures once through the normal Diagnostics path.
- Continue reducing synchronous whole-library work from interactive paths.
- Keep attachment decoding/classification separate from UI composition and project-write boundaries.
- Keep Generation Component/section dependency semantics data-driven.
- Treat Generation Concept Blueprint as preserved source rather than disposable intermediate text.
- Carry `generation.template_id` through character-creation handoffs.
- Keep supplementary Blueprint materialisation separate from strict template-field validation unless schema-defined.
- Keep Diagnostics credential-safe, binary-free, bounded and lazily rendered.
- Treat release version synchronization as one generated transaction owned by `set_version.py`.
- Keep regression subprocesses on the approved Godot binary consistently; eliminate stale historical per-workflow version assumptions over time.
- Replace noisy arbitrary-text `JSON.parse_string()` probes with quiet parse paths where normal non-JSON text is expected.
- Continue headless resource/ObjectDB/RID cleanup, especially Image Studio teardown, without treating leak-warning cleanup as evidence of functional failure.

## Polish

- Improve semantic colour/theme consistency, keyboard navigation, detachable-window behaviour, multi-monitor use, resizing, and long-text editing.
- Improve visible progress/error states for long AI operations and distinguish queue wait, local preparation, provider thinking, repair, and validation time.
- Improve queue labels so project, character, workflow, role, provider, model, section, and dependency state are legible without opening Diagnostics.
- Improve Idea Notebook browsing as real libraries grow, including denser cards/list options and multi-selection if needed.
- Improve source-aware Collaborator UX with clearer provenance/conflict/target/reference/completion guidance.
- Give Image Studio structured creative controls a compact progressive-disclosure layout rather than one giant wall of dropdowns.
- Keep common creative controls easy to use while provider/model-specific advanced controls appear only when relevant.
- Continue replacing silent button no-ops with visible actionable status messages.

## Long-Term Ideas

- Expand graph tooling into richer character/route planning without contaminating exported card data.
- Make Character Collaborator capable of increasingly sophisticated project-wide creative planning while keeping brainstorming/canonical boundaries explicit.
- Add navigable creative lineage such as Characters created from this Idea, Ideas involving this character, future/past variants, side-character promotions, descendants/family trees, and related Collaborator sessions.
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
