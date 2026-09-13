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
- Provider/model token limits remain data-driven and role-specific.
- Concurrent AI work keeps isolated request/job state and is selectively cancellable.
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
- Front Porch interoperability uses versioned portable formats or a documented supported local API; Character Card Forge never writes directly into Front Porch's SQLite database.
- Front Porch-specific authoring remains optional, preserves unknown future extension fields and never changes live conversation state unless the user explicitly runs a supported exchange workflow.

## Current Development Phase

**v0.20.0-hotfix1 — Library Panel Controls**

v0.20.0-hotfix1 adds independently collapsible Library Filters and Project Details
side panels with always-visible edge arrows, a unified Panels menu for Filters,
Project Tools and Details, one-click full/focused layouts and opt-in side-panel
auto-hide. Library layout and density preferences now reliably survive restarts.
v0.20.1 remains next.

v0.19.0 is the current public release baseline. The v0.16.x development line includes Collaborator rewind (v0.16.0), normalized Image capability architecture (v0.16.1), structured creative prompt composition (v0.16.2), tabbed Image Studio workflow (v0.16.3), dynamic provider model capabilities (v0.16.4), local Forge/A1111 checkpoint profiles (v0.16.5), ComfyUI workflow Generation Profiles (v0.16.6), Idea Generator detail levels (v0.16.7), and explicit Image-to-Image / Reference / Inpainting operations (v0.16.8).

v0.16.9 adds reusable provider-independent **Image Style Presets**. A versioned external built-in catalog provides starter styles; user-created **Global** presets are reusable across projects; **Project Visual Identity** supplies a project-level default; and **Character Default** provides an optional per-character override. Character defaults take precedence over project identity.

Applying a style preset populates the existing v0.16.2 Structured Creative controls and leaves the editable final Image Prompt untouched until the author explicitly composes it. Presets never store provider, model, checkpoint, sampler, steps, CFG, seed, transport or ComfyUI workflow settings.

v0.16.10 adds versioned exact result provenance, full settings reuse, same-seed regeneration, new-seed variation, persistent favourites, two-result comparison, explicit missing-file recovery and optional provider-supplied cost estimates. Local providers and providers without pricing metadata remain first-class.

v0.17.0 adds a first-class **Send to Character Collaborator** action for generated Image Studio results. The raw managed image, exact prompt and credential-redacted model/profile/settings provenance enter Collaborator as a structured read-only source. Authors can use the current character as the sole explicit target or start a new image-led conversation, and may optionally queue Vision as separate supplementary evidence.

v0.17.1 adds explicit evidence roles across multi-source Collaborator sessions: **Target Canon**, **Structured Facts**, **Author Reference**, **Creative Intent** and separately linked **Vision Observation**. A dedicated panel maps every source to its role, surfaces review notices for structured metadata/Image prompts paired with Vision, and opens a side-by-side evidence review without resolving discrepancies automatically.

v0.17.2 adds a dedicated optional Front Porch authoring surface backed by a versioned Front Porch 2.5 field catalog. Known character-life, opening-state, Needs, verification and presentation fields can be set manually or proposed by AI through the existing editable review boundary. Per-alternative-greeting opening seeds live beside Alternative Greetings. Imported future extension versions and unknown fields remain lossless, while untouched new characters emit no Front Porch extension.

v0.17.3 adds an authenticated, user-initiated **Install to Front Porch** workflow in Import / Export. It detects Front Porch through its supported health/auth endpoints, keeps credentials and session cookies out of persistent storage, verifies the character API, provides a visible card-artwork picker that prefers the active portrait and otherwise the newest generated image, uploads a validated Character Card V2 PNG when artwork is selected (or definition-only JSON when explicitly chosen) and presents explicit create-copy/update/cancel choices for name collisions. Portable JSON remains available whenever direct installation cannot complete.

v0.17.3-hotfix1 adds native OpenRouter Images routing and image-only model discovery. OpenRouter profiles use `/api/v1/images` and `/api/v1/images/models`; unrelated OpenAI-compatible providers retain `/images/generations`. Failed Image Studio requests expose a credential-safe route/transport summary.

v0.17.4 adds Front Porch's custom multi-character card format. One portable group PNG can contain multiple complete characters plus group-level opening, turn-order, Director, realism, objective and lore/world settings without merging those characters into one ordinary Character Card definition. Card Workflow Studio provides manual fields and review-first AI writing assistance; Import / Export validates, builds a collage, preserves complete member card PNGs and remaps stable IDs on non-destructive import.

v0.17.5 connects the existing Image Studio result gallery and manual image import to a versioned Front Porch avatar-gallery model. Authors can assign multiple alternate looks or exact expression labels, choose a canonical favourite independently from the CCF portrait, exchange Front Porch-compatible expression ZIPs and explicitly install a selected image or complete gallery through Front Porch 1.3.2+'s supported authenticated API. Its second hotfix adds a shared export-readiness gate for unfinished concept-only characters and an explicit missing-artwork confirmation across finished-card export paths.

v0.18.0 adds a project-level **Front Porch World Studio**. It creates, imports and exports portable JSON `.fpworld` packages, accepts bare lorebooks, provides manual primary-lorebook and optional climate/place-trait authoring, prepares bounded embedded covers and stores optional Stoop submission metadata. The raw imported envelope is retained and edited by merge so unknown future fields, additional lorebooks, metadata and assets survive round trips. Every package export requires private-context review, adult worlds require a second declaration confirmation, and no Stoop network call or Front Porch database write is introduced.

v0.18.0-hotfix1 hardens the shared Safe Section transport boundary after a model returned valid First Message prose without the requested object wrapper and then produced a nearly valid repair response with one missing outer quote. Plain or JSON-string replies can now be mapped only for an unambiguous standalone text field, focused text-field repair or focused text component. Existing semantic, agency and contamination validation still decides acceptance. Structured types and object/group shapes remain strict, and remote repair receives the exact requested schema.

v0.18.0-hotfix2 adds a disclosed GitHub Release update checker. Packaged builds can check automatically at startup no more than once per 24 hours, and Settings provides manual checking plus an opt-out. A newer stable release produces a sidebar notice, bounded plain-text release notes and the exact repository-hosted platform package. Checks are unauthenticated and send no provider credentials or project data. Download/install remains explicit; CCF does not silently replace a running executable.

v0.18.0-hotfix3 enables automatic boundary word wrapping in the Lorebook Manager's Lore content and Trigger Preview multiline inputs. This changes only visual layout: saved lore text and explicit paragraph breaks remain unchanged.

v0.18.1 adds immutable per-character checkpoints at meaningful boundaries, including
Save, accepted AI previews, imports, merges, forks and restores. The Revision History
window provides milestone labels and notes, field-aware comparison, full value
inspection, selective field application from revisions or related project characters,
non-destructive restore, fork and standard
Character Card V2 JSON export for earlier revisions. Per-character retention and
portable-package controls bound storage, while large assets remain references and
private derivation lineage stays out of ordinary revision export.

v0.18.2 adds a consolidated Card Inspector with deterministic advisory health checks,
whole-card and per-section token estimates, an explicitly approximate compiled-prompt
view, technical metadata, validated expert Raw JSON editing, missing asset/group-member
repair and a private configurable quality checklist. Import preview now exposes the
portrait, detected format/version, token size, validation, exact duplicate evidence
and migration/loss mapping before explicit Copy, Merge, Replace or Cancel choices.

v0.18.3 adds an optional AI Review layer built on those deterministic reports. A
visible versioned rubric produces a locally calculated advisory score for consistency,
clarity, depth, scenario/greeting/lore quality, prompt efficiency and roleplay
readiness. Reviews retain their content hash, model/profile, timestamp, findings,
proposals and decisions, become stale after relevant edits, and never run simply by
opening the library. The complete field-by-field change set is visible before Approve
All becomes available; each proposal defaults to Reject and remains editable before
explicit application. Rejections and intentionally dismissed findings remain in
private history, while accepted batches create revision recovery checkpoints.

v0.18.4 adds private project notes and workflow states, recoverable Archive mode,
optional Adult/Private markers and local Show/Blur Artwork/Hide presentation policy.
Saved Smart Collections, review/workflow/token/Front-Porch-data filters, optional
statistics and bounded Recently Used activity extend the existing Library index.
Explainable exact/probable duplicate review never
acts automatically; Merge and Replace archive the non-preferred project. Reusable
multi-selection supports validation, organisation, project-package export and group
creation through the established multi-character and Front Porch workflow formats,
with context menus, quick actions, bounded notices and explicit per-item reports.

v0.18.5 adds credential-safe connection diagnostics, behavior-proven endpoint
capabilities and authenticated bounded portrait caching. Private Front Porch identity,
last-exchanged and last-observed fingerprints expose Not Installed, Installed, Modified
Locally, Changed in Front Porch and Diverged states. Compare-first Update/Reinstall and
Import Front Porch Changes actions require confirmation; imports reuse revision recovery.
A persistent sequential deployment queue records success, failure, skipped and warning
outcomes, while Library filters expose remote and queued state without background network
traffic. Delete and group-card install remain disabled unless the connected server
explicitly proves a supported endpoint, with no raw-database fallback.

v0.18.6 adds a discoverable Compact/Lite derivative workflow for finished characters.
Authors choose an approximate target token budget, one of four compression levels and
independent preservation controls. The configured Text profile produces a complete
field-by-field preview whose replacements remain editable and individually selectable.
Creation rechecks the source hash, requires confirmation and appends a new character with
a fresh ID, private source revision/content-hash lineage, private model/profile provenance
and its own revision checkpoint. The source is never overwritten, and private derivation
or Front Porch install identity does not enter ordinary Character Card exports.

v0.19.0 adds reusable per-character Scenario Presets with alternate openings, active
cast, tags and shared-world references plus explicit single-scenario materialisation for
targets that cannot carry multiple setups. Alternative Greetings now have a compatible
manager for categories, tags, weights, favourites and Front Porch opening seeds while the
ordinary Character Card V2 array remains synchronised.

The coordinated Multi-Character Workspace builds on Card Workflows, Relationships and
Front Porch group cards. It adds discoverable new-group, new-member and independent
library-character-copy entry points, separates persistent roster from active/present
cast and previews a valid combined runtime card without modifying source characters.
Split Character Sets seed independent records before a parent AI job, retain successful
members after partial failure and retry only failed/pending members.

Shared `.fpworld` records are referenced rather than duplicated. Dependency inspection
covers characters, groups/workflows, worlds, scenarios, images and collections; lineage
views include variants, library copies, split sets and existing derivatives. Private
custom metadata remains out of ordinary exports unless an author creates an explicit
key-to-extension mapping, and the mapping has a visible preview. No automatic network
traffic or raw database access is introduced.

The released application displays **v0.19.0** and the current source candidate displays
**v0.20.0-hotfix1**. Both use the Godot **4.7.x stable** project baseline, keep Forward+ with
Compatibility/OpenGL fallback and retain the complete historical regression baseline.
The next planned milestone is v0.20.1 Discoverability and Power-User Workflow Pass.

## Completed

### v0.20.0-hotfix1 — Library Panel Controls

- Added slim edge-arrow controls that independently collapse or reveal Library Filters and Project Details while remaining accessible in the focused card layout.
- Added a unified **Panels** menu for Filters, the existing Project Tools section and Details, plus **Show all panels** and **Focus card area** actions.
- Added opt-in side-panel auto-hide that reveals from the edge and collapses only after interaction returns to the central card area; Project Tools remains explicitly controlled so batch menus are not interrupted.
- Preserved the familiar all-visible side-panel default and retained current selection, filtering and virtualized-card behavior through layout changes.
- Upgraded Library view-state loading so panel visibility, Project Tools visibility and card density genuinely persist between sessions.
- Added focused live UI, persistence, recovery-handle and inherited large-library regression coverage.

### v0.20.0 — Very-Large and Portable Library Architecture

- Virtualized the thumbnail grid so only visible and nearby buffered rows instantiate cards and load artwork, while the native compact list retains lightweight drawn-row behavior.
- Added density-specific local WebP thumbnail derivatives plus a versioned cache manifest, configurable size and unused-age limits, rebuild/cleanup controls and path-bounded deletion that preserves original artwork.
- Namespaced local indexes and thumbnails by library identity so libraries with matching project IDs cannot reuse each other's cached presentation.
- Added an optional **Library Storage** settings page for inspecting, initializing and selecting a portable/shared-folder project library without automatically moving, merging or deleting existing projects.
- Kept settings, indexes and thumbnail derivatives local while storing only portable projects, assets and a minimal versioned library manifest in the selected location.
- Added verified temporary project writes, previous-file recovery, cooperative short-lived save locks and content fingerprints that reject external changes instead of silently overwriting them.
- Blocked an already-open project from being saved into a newly selected library; authors must reopen it from the active location.
- Made unavailable shares an explicit read/write failure with no silent fallback to the local library and documented the supported single-writer expectation.
- Kept multi-user collaboration and automatic cloud sync outside the milestone.
- Added focused storage, cache, thousand-card virtualization and live settings regressions plus Godot 4.7.1 warning-gated CI.

### v0.19.3 — Expression Set Generation

- Added **Generate Expression Set…** to Image Studio with multi-selection across all exact Front Porch expression labels and an explicit prompt/style, portrait-reference or selected-result visual baseline.
- Capability-gated reference and Image-to-Image baselines so generic provider compatibility is never guessed.
- Routed one image per expression through the existing managed Image Studio queue with exact prompt/settings/seed/profile/model snapshots.
- Added detachable batch review with saved progress, pause/resume, per-expression preview, failed-member-only retry and individual acceptance.
- Routed accepted results into the existing Avatar Gallery and retained existing Front Porch gallery install and expression ZIP output paths.
- Required explicit replacement for an existing exact label while retaining old PNG files as recoverable generated assets.
- Added bounded workflow history, external data-driven directions, focused/live-UI regression coverage, inherited quick regression coverage and Godot 4.7.1 CI.

### v0.19.2 — Test Chat and Explicit Chat Exchange

- Verified Front Porch's supported state, character/session selection, fresh-chat, send, stop, persona, WebSocket stream, `.fpchat` and JSONL endpoints against its current public implementation.
- Added a detachable Front Porch-backed single-character Test Chat rather than recreating Front Porch's simulation engine.
- Added explicit resume, session selection, fresh-chat, send and stop actions with canonical history refresh after streamed output.
- Added Local Test Profiles for persona, expected runtime and notes outside card data; credentials and cookies are never persisted and global Front Porch settings are never silently changed.
- Added preview and managed preservation for `.fpchat`, raw Front Porch chat JSON and compatible SillyTavern JSON/JSONL with bounded input, traversal rejection and SHA-256 provenance.
- Added supported Front Porch chat import/export, including mismatch policies and managed recovery copies before transfer.
- Made session deletion recoverable by requiring an exact `.fpchat` backup before calling Front Porch's supported delete action.
- Kept group test chat deferred until this single-character lifecycle receives real-world validation.

### v0.19.1 — Export Profiles and Integration Adapters

- Added data-driven, versioned profiles for full-fidelity Character Card V2, Front Porch and clean SillyTavern output.
- Added exact JSON preview plus visible mapped, preserved, transformed and omitted field reporting before JSON or PNG export.
- Added one internal adapter contract for detection, import, export, validation, capability reporting and install/update payload preparation.
- Routed Front Porch install, comparison, update and queued deployment documents through the adapter boundary while keeping the supported authenticated transport and collision review unchanged.
- Preserved unknown extension namespaces by default and kept omitted/private data recoverable in the source project.
- Added an original native-resolution Character Card Forge startup splash without an artificial delay.
- Made the Character Library Active Project tools collapsible and compact by default, while retaining selection, Favourite and Actions access in the header.
- Added a persistent four-level card-size slider with progressive metadata reduction and an artwork name overlay at the smallest size; Compact List remains unchanged.
- Kept public executable plugins deferred pending a permission, sandbox and update model.

### v0.19.0 — Rich Scenario, Greeting, World and Ensemble Authoring

- Added versioned reusable Scenario Presets with alternate scenario, opening, active-cast, world-reference, category/tag and favourite data.
- Added explicit single-scenario Character Card V2 materialisation with a complete preview and no source-character mutation.
- Expanded Alternative Greetings with category, tags, weights, random preview, favourites and optional Front Porch opening seeds while preserving the standard export array.
- Added a dedicated Rich Authoring window and upgraded Card Workflow Studio with separate persistent-roster and active/present-cast controls.
- Added discoverable New Multi-Character / Group Project, Add New Member and Add Existing Library Character actions; library intake makes a fresh revisioned copy and never cross-links managed files.
- Added reviewed combined-card materialisation that preserves distinct member voices and reports target-format limitations.
- Added Split Character Set seeding from a shared concept, a recoverable parent AI job, independent per-character revisions, partial success and failed-member-only retry.
- Kept ordinary group-card controls and existing Relationships/Card Workflows/Front Porch group data canonical; raw JSON remains expert material.
- Added shared `.fpworld` linking, dependency inspection and pre-delete warning data for characters, workflows, worlds, scenarios, images and collections.
- Added lineage rows for variants, alternate timelines, family roles, library copies, split sets and existing derivatives.
- Added private custom metadata with explicit key-to-extension mappings and preview; unmapped fields remain absent from ordinary card exports.
- Added focused live-UI/service regression coverage, an inherited manifest, Godot 4.7.1 CI and `docs/v0190-rich-authoring.md`.

### v0.18.6 — Compact/Lite Derivatives from Existing Characters

- Added a discoverable Workspace action for creating a derivative from an already-finished character, separate from initial template selection.
- Added approximate target-token controls and Gentle, Balanced, Aggressive and Extreme compression intents using Card Inspector's deterministic estimate.
- Added independent preservation controls for lorebook material, greetings, examples, Front Porch/state fields, adult traits, tags and image-prompt material.
- Routed compression through the configured Text profile and shared AI scheduler with source project, character and content-hash guards.
- Added a complete side-by-side field review with wrapped full values, editable candidate text and a per-field choice to retain the source value.
- Kept creation disabled until a valid preview is displayed and required final confirmation before appending a new character.
- Added fresh stable identity, private source revision/content-hash lineage, private model/profile and compression provenance and an initial revision checkpoint.
- Prevented source overwrite, automatic save, copied Front Porch install identity and private provenance leakage into ordinary Character Card exports.
- Added focused service/live-UI regression coverage, an inherited manifest, Godot 4.7.1 CI and `docs/v0186-compact-lite-derivatives.md`.

### v0.18.5 — Front Porch Connection, Sync and Deployment Reliability

- Added credential-safe reachability, authentication, version, library, export and portrait diagnostics with copyable plain-text results.
- Added behavior-based capability evidence and kept destructive delete and group-card import disabled unless explicitly proven by the connected server.
- Added authenticated portrait fetching in a disposable cache bounded separately from authored artwork.
- Added private Front Porch character identity plus last-exchanged and remote fingerprints with five visible sync states.
- Added complete authored-field comparison before confirmed Update/Reinstall, Import Front Porch Changes or supported Remove actions.
- Reused inspected import and revision recovery for remote-to-local changes; no automatic overwrite or database access was introduced.
- Added a persistent sequential install/update queue with per-item success, failure, skipped and warning history.
- Added Library remote-state and queued-deployment filters that make no network requests while browsing.
- Limited advisory source-update opt-in to imported records with a stable public source ID or URL.
- Added focused service/live-UI regression coverage, an inherited manifest, Godot 4.7.1 CI and `docs/v0185-front-porch-reliability.md`.

### v0.18.4 — Library Workflow, Duplicate and Batch Tools

- Added private project notes and Draft, Needs Review, Testing, Stable, Published and Archived workflow states without adding those values to ordinary Character Card exports.
- Added recoverable Archive mode plus optional Adult/Private markers and a local Show, Blur Artwork or Hide presentation policy with explicit reveal for hidden cards.
- Added workflow, review, token-size and local Front Porch-data filters, saved rule-backed Smart Collections, opt-in aggregate statistics and a bounded Recently Used view distinct from updated-time sorting.
- Added bounded open, edit, export, review, install, validation and group-creation activity metadata stored in local Library state.
- Added explainable exact duplicate evidence from stable IDs, normalized content and artwork hashes, followed by probable name/text similarity evidence.
- Added explicit Merge, Replace, Ignore and Keep Both decisions; Merge and Replace archive the non-preferred project rather than permanently deleting it.
- Extended the existing multi-selection layer with deterministic batch validation, workflow changes, archive/restore, direct `.ccfproject` export and export-safety-gated Character Card V2 conversion with per-item reports.
- Added Create Multi-Character Project / Group from Selected using the existing project character model, private source lineage and Front Porch group workflow options.
- Added grid/list context menus and selected-project quick actions for Open, Export, Review, Front Porch, Duplicate, Collection, Rename, Show Location, Archive and Delete.
- Added bounded stale-review, missing-asset and artwork notices without background AI or Front Porch requests.
- Added focused service/live-UI regression coverage, an inherited manifest, Godot 4.7.1 CI and `docs/v0184-library-workflow.md`.

### v0.18.3 — AI Review, Rating and Selective Improvement

- Added explicit user-triggered AI consistency review across identity, appearance, personality, scenario, greetings and lore, seeded with the deterministic Card Inspector evidence.
- Added a visible eight-category rubric and locally calculated advisory score without presenting model judgment as objective quality.
- Added reviewed-content hashes and visible stale state so old proposals cannot overwrite later card, shared-context or lore edits.
- Stored bounded private review history with rubric version, model/profile, timestamp, findings, score, complete proposals and author decisions.
- Added separated Score & Rubric, Findings and Selective Changes views with old/new values and Reject-by-default decisions.
- Added readable long-content review cards, a wrapped full-finding detail pane and a complete text-only report with plain-text export.
- Added explicit Approve, Reject, Edit Before Applying and complete-set-only Approve All behavior; no review result silently changes character data.
- Preserved rejected proposals and intentionally dismissed findings as author decisions for later review context.
- Added recovery checkpoints before and after every accepted AI Review batch, while keeping review history out of ordinary card export and recursive revision snapshots.
- Added focused service/live-UI regression coverage, an inherited manifest, Godot 4.7.1 CI and `docs/v0183-ai-review.md`.

### v0.18.2 — Card Health, Token and Interchange Inspection

- Added one Card Inspector with six separated areas for health, tokens/prompt, technical metadata, expert Raw JSON, missing references and the quality checklist.
- Added deterministic advisory findings for empty/malformed fields, duplicates, custom metadata, broken references and suspiciously large sections or cards.
- Added whole-card/per-section token estimates plus an approximate compiled-prompt view that identifies runtime-dependent lore and frontend behavior.
- Added read-only technical identity/extension/revision metadata and schema-validated Raw JSON apply behind an explicit confirmation and recovery checkpoints.
- Expanded import preview with portrait, format/version, token size, validation, exact duplicate evidence and migration/loss mapping before Copy, Merge, Replace or Cancel.
- Added migration explanations for preserved, transformed, defaulted, namespaced, review-required and potentially lossy data.
- Added managed-file relinking for portraits, generated images and attachments, plus explicit replacement of missing group members.
- Added a private configurable checklist for core fields, artwork, lore, token budget, manual review and optional roleplay testing; it does not enter ordinary card export.
- Added focused service/live-UI regression coverage, an inherited manifest, Godot 4.7.1 CI and `docs/v0182-card-health-inspection.md`.

### v0.18.1 — Revision Safety, Diff and Recovery

- Added immutable timestamped character checkpoints with labels, notes, reason and bounded provenance at meaningful authoring actions rather than every keystroke.
- Added a live Revision History workspace window with checkpoint/current selectors, field-aware before/after comparison and full structured-value inspection.
- Added checked-field selective merge, with a recovery checkpoint before the merge and a new merge result checkpoint afterward.
- Added non-destructive restore that preserves the displaced current state and appends the restored state instead of truncating history.
- Added earlier-revision forks with fresh character IDs and private derivation lineage.
- Added standard Character Card V2 JSON export for earlier revisions while excluding revision history and private lineage.
- Added automatic checkpoints for meaningful Save, accepted AI preview changes and imported projects, with identical automatic saves deduplicated.
- Added per-character retention/pruning from 5 to 500 revisions and a choice to include or omit each character's history from portable `.ccfproject` packages.
- Kept portraits, generated images and attachments as stable path/content references rather than duplicating large binary data in each snapshot.
- Added focused service/live-UI regression coverage, an inherited manifest, Godot 4.7.1 CI and `docs/v0181-revision-safety.md`.

### v0.18.0-hotfix3 — Lorebook Word Wrapping

- Enabled boundary word wrapping in the Lorebook Manager's main Lore content editor.
- Enabled the same wrapping in the multiline Trigger Preview sample-text input.
- Kept wrapping visual-only so saved lore and trigger text are not rewritten with inserted newlines.
- Added focused live-UI regression coverage, an inherited manifest, Godot 4.7.1 CI and `docs/v0180-hotfix3-lorebook-word-wrap.md`.

### v0.18.0-hotfix2 — GitHub Release Update Checks

- Added a dedicated **Settings → Updates** tab with the installed/comparison version, latest published release, release notes and status.
- Added an automatic packaged-build startup check enabled by default, limited to once per 24 hours and independently disableable while **Check Now** remains available.
- Used GitHub's public latest stable Release endpoint without authentication or any CCF/provider credential.
- Added conditional ETag reuse, a bounded response size/cache and fail-quiet handling for offline, unavailable and rate-limited checks.
- Added strict semantic/hotfix version comparison plus exact Windows, Linux and unsigned macOS release-asset selection.
- Added a visible sidebar update notice and explicit GitHub release/platform-download actions.
- Kept installation non-destructive: no silent executable replacement, project write, release-note rich-text execution or source/editor startup network request.
- Bumped the backwards-compatible settings document to format 7 for the automatic-check preference.
- Added focused regression coverage, inherited manifest and `docs/v0180-hotfix2-github-update-checks.md`.

### v0.18.0-hotfix1 — Safe Section Text Recovery

- Added local recovery for usable plain prose, valid JSON strings and complete text code fences returned for unambiguous standalone line/multiline Safe Section fields.
- Applied the same recovery boundary to focused text-field and focused output-component repairs.
- Routed every recovered value through the existing exact-field, semantic, agency and cross-section contamination checks rather than accepting transport recovery as content approval.
- Kept tags, numbers, checkboxes, selects, output groups and malformed object/array-shaped replies on the strict JSON path.
- Added exact field/type or component-key guidance to bounded remote JSON repairs.
- Added conservative local recovery for an otherwise valid root JSON string missing only its outer closing quote.
- Updated both workspace workers and their parallel Safe Section children so sequential and concurrent generation use the same behavior.
- Added focused regression coverage, inherited manifest and `docs/v0180-hotfix1-safe-section-text-recovery.md`.

### v0.18.0 — Front Porch Worlds and The Stoop Preparation

- Added a project-level Front Porch World Studio for multiple reusable worlds per CCF project.
- Added lossless `.fpworld` JSON v1 import/export plus bare-lorebook compatibility and future-version warnings.
- Preserved unknown top-level, metadata, biome, place-trait, lorebook and lore-entry fields by merging visible edits into the retained raw envelope.
- Added manual world identity, primary lorebook, climate, built-in data-driven biome, atmosphere and gravity authoring while retaining additional imported lorebooks.
- Added bounded JPEG data-URL cover preparation with a 1024-pixel longest edge and 350 KiB soft target.
- Added local Stoop preparation for summary, creator/original creator, tags, adult declaration, comments preference and stable update identity, with readiness reporting.
- Required explicit private-context review before every package export and an additional confirmation for adult worlds.
- Kept portable packages as the independent baseline; direct Stoop publishing, network calls, raw database writes and live-conversation mutation remain disabled.
- Added focused lossless/future-field/cover/live-UI regression coverage, inherited manifest, Godot 4.7.1 CI and `docs/v0180-front-porch-worlds.md`.

### v0.17.5 — Front Porch Expressions & Avatar Galleries

- Added a versioned per-character avatar-gallery model for multiple alternate looks, exact Front Porch expression labels, one canonical favourite and image provenance.
- Added Image Studio **Add as Front Porch Look** and **Add as Expression…** actions plus manual PNG/JPEG/WebP import in Import / Export.
- Added Front Porch/SillyTavern-compatible expression ZIP import/export with exact label/separator matching, nested-folder support, managed PNG conversion, a versioned CCF manifest and the 30-expression cap.
- Kept gallery association, canonical favourite, CCF portrait assignment, Character Card artwork embedding and Front Porch installation as separate explicit actions.
- Added authenticated character selection and selected/complete-gallery installation through Front Porch 1.3.2+'s supported avatar, look and favourite endpoints.
- Fixed Character Life **AI Suggest** for Work days and Birthday with exact typed output contracts, an editable one-line day-array preview and a visible review when the proposed value matches the current value.
- Added shared export readiness checks across JSON/PNG, split-batch, group-card and direct Front Porch exports: all-empty Description, Personality, Scenario and First Message fields block export, while missing artwork requires explicit confirmation.
- Kept `.ccfproject` draft backups and expression-gallery ZIP exchange available for unfinished work.
- Removed Godot 4.7.2 shadowing, integer-division, confusable-local and incompatible-ternary warnings from direct install, group-card layout/import and Character Life unchanged-value review paths.
- Preserved the session-only credential boundary, no background sync, no live-conversation mutation and no direct Front Porch database writes.
- Added focused regression coverage, inherited manifest, Godot 4.7.1 CI and `docs/v0175-front-porch-avatar-galleries.md`.

### v0.17.4 — Front Porch Multi-Character Group Cards

- Added exact `front_porch_group_card` 1.0 import/export through portable PNG `fpa_group` metadata.
- Added optional Front Porch group fields to Group-card plans, including turn order, auto-advance, Director, prompts, lore/world references, chaos, objectives, inheritance and baseline/per-member realism.
- Added editable manual authoring plus review-first AI drafting for group prompts, lorebook and objectives, with deterministic neutral realism restoration.
- Embedded every complete flattened character definition and full avatar PNG with Character Card V2 `chara` metadata; text-only members receive portable placeholders.
- Added automatic group-cover collage generation, validation preview and duplicate stable-ID rejection.
- Added non-destructive import into a new multi-character CCF project with fresh UUIDs, complete member-keyed setting remapping, managed portrait recovery and unknown future field preservation.
- Kept direct group installation disabled until a verified supported API exists; no Front Porch database writes or live-conversation mutation were introduced.
- Added focused regression coverage, inherited manifest, Godot 4.7.1 CI and `docs/v0174-front-porch-group-cards.md`.

### v0.17.3-hotfix1 — OpenRouter Images Routing

- Added exact-host OpenRouter transport detection with lookalike-domain rejection.
- Added native `POST /api/v1/images` Text to Image routing and `GET /api/v1/images/models` discovery for existing standard OpenRouter profiles.
- Preserved `/images/generations` for other OpenAI-compatible providers and all Forge/A1111 behavior.
- Reused the existing `data[].b64_json` decoder and provider-neutral generation payload.
- Added credential-safe request route/transport detail to visible Image Studio failures.
- Added focused regression coverage, inherited manifest, Godot 4.7.1 CI and `docs/v0173-hotfix1-openrouter-images.md`.

### v0.17.3 — Direct Front Porch Install

- Added a dedicated **Install to Front Porch** tab to Import / Export with connection instructions, endpoint validation and explicit capability reporting.
- Added supported `GET /api/health`, `GET /api/auth/state`, `POST /api/auth/login`, `GET /api/characters` and `POST /api/characters/import` integration for Front Porch 1.3.x-compatible servers.
- Added cookie-session authentication with session-only password, two-factor code and session cookie; only the endpoint and optional username can be remembered.
- Allowed plain HTTP only for loopback Front Porch addresses and required HTTPS before credentials can be sent to a remote host.
- Added validated Character Card V2 PNG installation with a visible artwork picker, active-portrait/newest-generated defaults, embedded metadata, explicit definition-only JSON choice, Front Porch-owned stable-ID matching and exact accepted name/character-ID/payload reporting.
- Added explicit name-collision choices for **Create Copy**, **Update Selected** and **Cancel**, using Front Porch's supported `ask`, `keepBoth` and `replace` policies.
- Kept **Export Portable JSON Instead…** available for unavailable, incompatible, unauthenticated or declining Front Porch instances.
- Preserved the no-SQLite, no-background-sync and no-conversation-mutation boundaries.
- Added focused v0.17.3 regression coverage, inherited manifest, Godot 4.7.1 CI and `docs/v0173-front-porch-direct-install.md`.

### v0.17.2 — Front Porch Character Extensions

- Added a versioned external Front Porch 2.5 catalog covering more than 50 optional character-life, opening-state, Needs and advanced fields.
- Added a dedicated **Front Porch — Optional** Workspace tab with four focused internal tabs, explicit per-field inclusion, validation and clear actions.
- Added manual editing, per-field AI Suggest, section generation, selected regeneration and whole-tab enabled-field generation through the existing editable Generation Preview.
- Added session-only adult-field opt-in that preserves imported hidden values and keeps adult preferences separate from ordinary likes/dislikes.
- Added sparse, per-alternative-greeting Front Porch opening seeds beside the existing Alternative Greetings workflow, with manual and review-first AI authoring.
- Added Character Card V2 `data.tts_voice` import/export while retaining Front Porch data under `data.extensions.front_porch`.
- Preserved imported future extension versions and unknown top-level, nested and greeting-seed fields while known fields are edited.
- Added date/time/range/colour normalisation, `{{user}}` agency rules and an explicit no-SQLite boundary.
- Added focused v0.17.2 regression coverage, inherited manifest, Godot 4.7.1 CI and `docs/v0172-front-porch-character-extensions.md`.

### v0.17.1 — Collaborator Evidence Roles & Conflict Review

- Added a deterministic evidence-role service distinguishing target canon, structured character/card facts, author references, Image Studio creative intent and supplementary Vision observation.
- Added a live **Evidence roles & conflict review** panel with per-source explanations and explicit notices when Character Card metadata or Image Studio prompts have linked Vision evidence.
- Added **Review Evidence…** actions that present the immutable source snapshot and separately linked Vision descriptions together without merging or resolving them.
- Added a model-facing precedence/conflict contract so target safety and evidence distinctions remain active during Collaborator replies and generation.
- Kept source snapshots, Vision context and canonical character fields unchanged by presentation/review actions.
- Added focused v0.17.1 regression coverage, inherited manifest, Godot 4.7.1 CI and `docs/v0171-collaborator-evidence-roles.md`.

### v0.17.0 — Structured Image Studio → Collaborator Handoff

- Added **Send to Character Collaborator** to the selected Image Studio result workflow, with missing-file recovery required before handoff.
- Added a dedicated `image_studio_result` Collaborator source type preserving the managed image path/ID/dimensions and exact v0.16.10 generation snapshot.
- Added credential redaction for additive provider parameters while retaining useful model/profile/prompt/negative prompt/seed/sampler/steps/CFG/image-operation provenance.
- Added two explicit workflows: current Workspace character as the only Compare & Apply target, or a new image-led Collaborator conversation with the image as Reference Context.
- Added optional Vision queueing and later re-analysis while keeping Vision descriptions separate from raw image evidence and generation metadata.
- Kept all canonical character writes behind existing explicit Collaborator review/apply actions.
- Added focused v0.17.0 regression coverage, inherited manifest, Godot 4.7.1 CI and `docs/v0170-image-collaborator-handoff.md`.

### v0.16.10 — Studio Workflow & Results Polish

- Added versioned result execution snapshots with exact composed prompts and reusable provider/model/settings/image-input provenance, excluding credentials.
- Added explicit Reuse Settings, full-snapshot Regenerate/New Seed Variation, persistent favourites and two-result comparison.
- Added explicit missing-file recovery into managed project assets while retaining the existing portrait-assignment boundary.
- Added optional cost estimates only for explicit numeric per-image provider pricing; missing pricing remains supported.
- Removed inherited v0.16.8 `Window.mode` / `Node.ready` shadowing warnings and added regression guards.
- Added focused v0.16.10 regression coverage, inherited manifest, Godot 4.7.1 CI and `docs/v01610-studio-workflow-results.md`.

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

- Runtime-test v0.17.3 against a configured Front Porch 1.3.x web server with password-only and 2FA accounts, stable-ID updates and multi-candidate name collisions.
- Confirm direct-install reporting against later Front Porch releases and extend behavior-based capability detection only when their supported API contract changes.
- Validate HTTPS remote-host setup while keeping loopback HTTP as the simplest same-computer path.

- Runtime-test v0.17.2 with Front Porch Rawhide card imports/exports, especially future extension keys, alternative greeting seeds, colour integers and TTS identifiers.
- Validate dense Front Porch tab layout across supported desktop window sizes and refine grouping/tooltips without moving optional data into core Character tabs.
- Confirm Front Porch 2.5 card behaviour with real new conversations while keeping existing conversation state out of Character Card Forge's write boundary.

- Runtime-test v0.17.1 evidence-role labels and review layout with large card metadata, long Vision analyses and dense multi-source sessions.
- Evaluate optional author-confirmed conflict annotations after real-world use; keep automatic semantic conflict claims out of the deterministic presentation layer.

- Runtime-test v0.17.0 existing-target and image-led handoffs with real saved projects, including optional Vision success/failure and repeated session reloads.
- Confirm generated PNG/JPEG/WebP recovery and handoff paths remain portable across supported desktop platforms.

- Runtime-test v0.16.10 settings reuse/regeneration with real cloud and local providers, including provider-specific parameters and image-input paths.
- Runtime-test result favourites, comparison and missing-file recovery across repeated project reloads.
- Validate optional cost presentation against representative provider pricing schemas without guessing ambiguous prices.

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
- Maintain a read-only compatibility inventory against current Front Porch Rawhide character, group, world and chat formats before implementing each interoperability stage.

## Planned — v0.17.x and Later Authoring Work

### Front Porch interoperability track — accepted

Restore and substantially expand the useful V1-to-Front-Porch workflow without restoring its obsolete raw SQLite writer. Front Porch's supported local API and portable interchange formats are the integration boundary. The intended user experience can still be direct and convenient, but database ownership, migrations and live state remain Front Porch's responsibility.

All Front Porch fields are optional. A visible **Front Porch — Optional** Workspace tab groups them without crowding the core Character or Advanced tabs. Leaving every field unset emits no `extensions.front_porch` data. Imported Front Porch data must round-trip losslessly, including unknown future fields.

Manual authoring and AI assistance are equal first-class paths. Each group supports **Generate Section**, **AI Suggest**, **Regenerate Selected**, **Clear** and per-field include/exclude review, plus one **Generate Enabled Front Porch Fields** action. AI output is always reviewable before application. Relationship values must not invent prior history with `{{user}}`; intimate preferences require explicit adult-content opt-in. These values seed new Front Porch conversations and do not retroactively rewrite existing chats.

#### v0.17.2 — completed

The versioned Front Porch 2.5 character extension editor, selective manual/AI workflows, Alternative Greeting seeds, TTS interchange and unknown-field preservation are implemented and recorded under **Completed** above. The direct-install boundary remains assigned to v0.17.3.

#### v0.17.3 — completed

Authenticated supported-API connection, capability detection, user-initiated Character Card V2 installation, Front Porch-owned stable identity, explicit name-collision choices, exact result reporting and portable JSON fallback are implemented and recorded under **Completed** above.

#### v0.17.4 — completed

Portable `fpa_group` authoring, validation, embedded-member PNG export, non-destructive multi-character import, stable-ID remapping, unknown-field preservation and the no-database-write boundary are implemented and recorded under **Completed** above.

#### v0.17.5 — completed

Image Studio/manual gallery sources, exact expression labels, multiple looks, independent canonical favourite and portrait actions, portable sprite ZIPs, authenticated supported-API installation and provenance are implemented and recorded under **Completed** above.

#### v0.18.0 — completed

Lossless `.fpworld` exchange, bare-lorebook compatibility, world/lore/climate authoring, embedded cover preparation, Stoop metadata/readiness and mandatory private/adult review are implemented and recorded under **Completed** above. Direct Stoop publishing remains disabled until its authenticated contract is implemented and tested independently.

#### v0.18.0-hotfix1 — completed

Safe Section plain-text recovery, exact typed repair schemas, conservative missing-quote repair and parallel-worker wiring are implemented and recorded under **Completed** above.

#### v0.18.0-hotfix2 — completed

Disclosed, rate-limited GitHub Release checks, a dedicated Updates page, stable version comparison, exact platform-download handoff and the no-silent-install boundary are implemented and recorded under **Completed** above.

#### v0.18.0-hotfix3 — completed

Automatic visual word wrapping for Lore content and Trigger Preview multiline inputs is implemented and recorded under **Completed** above. Stored lore text and explicit paragraph breaks remain unchanged.

### Accepted idea backlog — dependency ordered

The ideas in the living **Character Card Forge Ideas** document are grouped here by implementation dependency rather than their source numbering. Existing capabilities are extended instead of rebuilt, and speculative integrations remain behind verified API/capability checks.

#### v0.18.1 — completed

Durable checkpoints, comparison, selective recovery, non-destructive restore, forks,
earlier-revision export, automatic Save/AI/import boundaries, retention and package
controls are implemented and recorded under **Completed** above. Applying this model
to future format migrations and the v0.18.4 batch-action layer remains an integration
requirement for those milestones rather than a reason to duplicate revision storage.

#### v0.18.2 — completed

Deterministic health/token/prompt inspection, separated technical and validated Raw
JSON views, reviewed import actions with migration/loss and duplicate evidence,
missing file/group-member repair and a private configurable checklist are implemented
and recorded under **Completed** above. AI interpretation remains deliberately reserved
for v0.18.3 rather than being mixed into deterministic diagnostics.

#### v0.18.3 — completed

AI consistency review, visible rubric scoring, content-hash staleness, private decision
history, complete field-by-field review and revision-safe selective application are
implemented and recorded under **Completed** above. Library-level review filters and
batch workflows remain assigned to v0.18.4 so no batch action bypasses these explicit
review and recovery boundaries.

#### v0.18.4 — completed

Private workflow metadata, recoverable archives, local sensitive-card presentation,
saved Smart Collections, recent activity, explainable duplicate decisions, reusable
batch validation/export, multi-project group creation, quick actions and bounded notices
are implemented and recorded under **Completed** above. Front Porch remote-state and
deployment-queue filters remain assigned to v0.18.5 because they require verified
server capabilities rather than inferred local state.

#### v0.18.5 — completed

Credential-safe diagnostics, behavior-proven capabilities, authenticated bounded portrait
caching, private exchange identity/fingerprints, compare-first two-way actions, confirmed
supported removal, a persistent sequential deployment queue, Library remote/queue filters
and stable-public-source update opt-in are implemented and recorded under **Completed**
above. Group-card direct install remains capability-gated because no supported group-card
import endpoint is advertised; `fpa_group` is never sent through character import.

#### v0.18.6 — completed

Independent Compact/Lite derivation, four compression intents, token targets,
preservation controls, source-hash protection, complete editable comparison, private
lineage/model provenance and the first derivative revision are implemented and recorded
under **Completed** above. The later rich-authoring and export-adapter milestones are
also complete.

#### v0.19.0 — completed

- Add versioned Scenario Presets/alternate setups that reference one character without requiring duplicated full cards; define export materialisation rules for targets that support only one scenario.
- Expand Alternative Greetings into a manager with categories, tags, weights, randomisation, favourites, Front Porch opening seeds and preview/test entry points.
- Add a coordinated Multi-Character Workspace for casts, families, teams and group cards using the existing project characters, Relationships and Card Workflows as the source of truth.
- Add **New Multi-Character / Group Project** plus **Add Existing Library Character** entry points. Authors can create new members, select existing members or mix both without first understanding internal project hierarchy.
- Materialise a valid Multi-Character Single Card workflow into a reviewed combined runtime/export artifact without modifying or silently merging the independent source characters. Preserve distinct member voices and warn where the target format cannot express ensemble semantics.
- Generate a **Split Character Set** from one shared concept or project plan: seed independent member records, reuse shared setting/relationship/series/world context, run focused per-character generation and review/save each result separately.
- Give split generation a parent AI job with recoverable per-character results and partial failure/retry; keep per-character Interview/Q&A separate and retain other cast members only as supporting context unless a group card is explicitly requested.
- Make ordinary group-card controls—name, members, shared scenario, opening, system/group prompt, turn behavior, supported Director/chaos settings, objectives, opening state and lore/world references—the primary surface. Keep raw group JSON Expert-only.
- Model the persistent group roster separately from the members active/present in a particular scenario or opening whenever the target runtime supports that distinction.
- Add a Shared World Manager on top of the v0.18.0 `.fpworld` foundation so characters/groups reference common world data instead of silently duplicating it.
- Add dependency inspection for characters, worlds, lorebooks, groups, images and collections, including warnings before deleting referenced content.
- Add optional lorebook/world graph views after the underlying references are explicit; the graph is a view/editor of real data, not a separate canonical store.
- Extend lineage views for variants, alternate timelines, family trees and derived characters using v0.18.1 provenance.
- Add private custom metadata fields with explicit export-profile mappings; unknown user fields remain CCF-private unless the author maps them.

#### v0.19.1 — completed

- Replace the default Godot startup image with an original, version-independent Character Card Forge splash screen sized to the application's native 16:9 viewport.
- Add versioned export profiles for Character Card V2, Front Porch, SillyTavern and future targets, including explicit include/omit/rename/transform rules and a before-export preview.
- Extract a shared internal adapter contract for detection, import, export, validation, capability reporting, install/update and preservation notes.
- Migrate existing Front Porch and standard Character Card behavior behind the internal contract without breaking file formats or duplicating UI/business logic.
- Preserve unknown fields and produce visible loss/preservation reports when a target cannot express a source feature.
- Reclaim Character Library grid space with compact-by-default Active Project tools and a persistent card-density slider whose smaller sizes progressively hide metadata and finally overlay the name on the artwork.
- Keep third-party executable plugins and a public extension SDK deferred until the internal adapter boundary is stable, permission-aware and testable.

#### v0.19.2 — completed

- First verify whether Front Porch's supported web/API mode exposes the required create-chat, character selection, send, stream, history and model/preset contracts; do not infer chat support from server reachability.
- Add Local Test Profiles that store model/runtime test settings separately from card data so behavior can be compared without mutating the character.
- If the verified contract is sufficient, add a lightweight CCF test-chat client using Front Porch as the runtime backend rather than recreating its simulation engine.
- Add explicit `.fpchat` and compatible SillyTavern JSON/JSONL import/export with validation, provenance and separation between authored card data, chat history and evolving simulation state.
- Make chat creation, transfer and deletion user-initiated, previewable and recoverable; never manipulate Front Porch's live database.
- Extend to multi-character/group scenario testing only after single-character lifecycle, streaming/cancellation and privacy boundaries are reliable.

#### v0.19.3 — completed

- Add **Generate Expression Set…** to Image Studio/Avatar Gallery with multi-selection of supported expression labels and an explicit visual identity/source baseline.
- Run each expression through the existing managed Image Studio queue, preserving its exact prompt, settings, seed and provider/model provenance.
- Route accepted results into the existing avatar gallery with their requested exact labels; do not create a parallel expression store.
- Allow per-expression review, retry and replacement without regenerating successful members of the set.
- Finish through the existing supported outputs: direct Front Porch gallery installation or portable expression ZIP export.

#### v0.19.3-hotfix1 — completed

- Decode Front Porch `/api/ws` server frames through their documented `event`
  discriminator while retaining the early-development `type` fallback.
- Restore token, completion, error and canonical chat-history updates in Test Chat.
- Reconcile reconnects through Front Porch's `generating`, `isGenerating` and
  `isSettlingTurn` state without adding background chat creation or database access.

#### v0.19.4 — completed

- Add deterministic local PDF text extraction when a text layer exists while retaining the original PDF as the managed source attachment.
- Store extracted text as derived preprocessing data with page, character, token, status and truncation metadata; preview it and let the author explicitly choose whether it enters context.
- Keep scanned/image-only PDF OCR as a separate explicit future option rather than silently invoking an expensive service.
- Add **Add from URL…** for bounded HTTPS document/image/reference ingestion with download-size, timeout, redirect and content-type limits plus a preview before acceptance.
- Copy accepted remote content into managed project storage and record source URL/fetch time provenance. Treat remote content as untrusted data and make refresh an explicit action rather than background mutation.
- Reuse the existing attachment context-budget and preprocessing pipeline for both sources.

#### v0.19.5 — completed

- Extend provider profiles with optional **Fast/Suggestion Text**, **Deep Review Text** and **Fallback Text** roles while keeping **Use Primary** as every task's default.
- Route small field suggestions/light transforms and deep consistency review independently without changing the established Text, Vision and Image separation.
- Permit bounded automatic fallback only for explicitly enabled technical failures such as unavailable models/endpoints; refusals and content failures do not silently switch models by default.
- Prevent retry chains, report every fallback visibly and retain the actual producing profile/model in accepted-result provenance.

#### v0.20.0 — completed

Virtualized tiles, local bounded thumbnail derivatives, optional portable/shared-folder
storage, verified replacement writes, cooperative locks, conflict/origin checks and
explicit unavailable-share behavior are implemented and recorded under **Completed**
above. Multi-user editing and automatic cloud sync remain explicitly out of scope.

#### v0.20.1 — Discoverability and Power-User Workflow Pass

- Add a **New Project** creation-method chooser for Manual, Idea Generator, Character Collaborator, Idea Notebook, Import, Template and other supported paths, with concise explanations and direct expert shortcuts.
- Add keyboard-first actions for save, search, review, field navigation, compare, export/install and lorebook tools with discoverable shortcut labels.
- Add workspace-layout presets for Editing, Review, Lorebook, Front Porch Deployment and Group Card work, respecting detachable-window and multi-monitor behavior.
- Run a dedicated new-user discoverability pass over navigation, labels, tooltips, grouping and common-action entry points; prefer incremental improvements over a disruptive redesign.
- Add an optional first-run/Getting Started guide that can be skipped and reopened, without slowing experienced users.

### Existing capabilities and cross-cutting accepted work

The current Relationship Matrix, group-card builder/import/export, Interview/Q&A and Character Builder, full-text library search and favourites already cover the core of several source-document ideas. Future milestones extend those implementations rather than adding competing systems.

The September 2026 V1-versus-V2 feature audit is accepted as a roadmap correction,
not a compatibility rewrite. A parity item is complete only when the action is
discoverable, preserves or exceeds the useful V1 workflow, uses V2's canonical data
model, previews and recovers destructive changes, retains AI provenance, keeps private
state out of standard card fields, respects supported Front Porch APIs/formats and has
focused plus inherited regression coverage.

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
- Require new derivative, materialisation, batch and remote-ingestion actions to be explicit and reviewable; preserve source characters and integrate with Revision History, Card Inspector, AI Review, AI Jobs, managed attachments and indexed/searchable character pickers.

## Level and Content Tools

Character Card Forge is an authoring application rather than a level-based game. The equivalent content-tool priority is externally editable/versioned templates, `.ccfchar` interchange, project packages, lorebooks, Idea Notebook entries, Collaborator source snapshots, Image creative catalogs/presets/Generation Profiles, Front Porch character extensions, expression packs, `fpa_group` cards, `.fpworld`/`.fpchat` packages and schema/editor tooling. Loading and saving should use the same underlying models exposed to authoring tools.

## Technical Improvements

- Keep generation services modular and preserve older project/card compatibility as schemas evolve.
- Treat runtime generation-service composition as a capability-tested compatibility boundary; historical hotfix behaviour should be active-leaf invariants rather than exact filename/inheritance-depth assumptions.
- Keep first-save persistence content-aware, source collections versioned/backwards-compatible and raw evidence distinct from normalized AI-facing context.
- Keep AI worker request/retry/repair/Diagnostics/cancellation state isolated and Safe Section dependency/context/template order deterministic.
- Treat Safe Section transport recovery as a narrow shape correction: only unambiguous text targets may accept plain prose, while typed values and multi-key structures require valid JSON and all recovered text still passes normal content validation.
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
- Keep in-app release checks unauthenticated, rate-limited, repository-pinned and separate from provider credentials, project data and executable replacement.
- Keep persistent app state under `user://` separate from portable project/card data unless deliberately included.
- Keep Idea Notebook independent of Character Project persistence and generation-service topology.
- Keep Collaborator source seeding public/structured and completion/refinement project-scoped/stale-source checked/non-destructive.
- Keep the Front Porch schema adapter versioned and capability-aware; preserve unknown `extensions.front_porch` data rather than dropping fields introduced by newer Front Porch versions.
- Separate authored Front Porch starting values from imported live/evolving state, and keep both out of ordinary Character Card fields unless the user explicitly maps them.
- Treat direct Front Porch installation as an API/interchange operation with explicit status and collision handling; raw database writes are never a supported fallback.
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
- Consider a secure self-hosted/headless server mode only after core editing, library, revision, review and integration contracts are mature. The Godot desktop application remains the primary client.
- If server mode proceeds, target the existing information-dense desktop browser workflow first; tablet refinement can follow, while a dedicated phone UI remains lower priority.
- Require authenticated secure sessions, explicit remote-access enablement, HTTPS/reverse-proxy support, scoped filesystem/provider permissions, audit-friendly operations and safe shutdown/recovery before remote access is considered supported.
- Let a future browser client access the same library, Idea Notebook and creation tools through documented service boundaries rather than directly reading project files.

## Deferred / Experimental Ideas

- The v0.15.12–v0.15.14 full-Workspace synthesis shortcut remains outside the normal Generate Character path unless it can compose through the validated parity pipeline.
- Provider-specific concurrency heuristics remain opt-in until limits can be modeled safely.
- Shared GPU resource pools remain deferred until real local Vision/Image testing establishes useful controls.
- Persistent local queue recovery across application restarts remains deferred; current queues are process-local.
- More elaborate graph-layout automation beyond the current draggable anchor system.
- Advanced context compression beyond explicit user-triggered summarisation.
- Fully automatic arbitrary-ComfyUI-workflow interpretation remains experimental; explicit Generation Profile mapping comes first.
- Collaborative multi-user libraries and automatic cloud/self-hosted sync remain experimental until revision identity, locking, merge/conflict handling and privacy controls exist.
- A public third-party extension SDK remains deferred until the internal v0.19.1 adapter contract is stable and a permission/sandbox/update model has been designed.
- Full phone-optimised remote editing remains deferred; dense card, lorebook, review and multi-window workflows make desktop-first browser access the more realistic initial target.
- Provider text streaming remains low priority and presentation-only if revisited; partial streamed text must never become accepted project data.
- A self-installing updater remains optional future work. The current explicit GitHub Release notification/download handoff satisfies the useful V1 update-discovery workflow.
- Direct Stoop publishing remains deferred until a mature supported authenticated contract exists.
