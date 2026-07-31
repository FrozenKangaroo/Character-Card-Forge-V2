# Character Card Forge — Project Roadmap

## Project Vision

Rebuild Character Card Forge as a responsive, native Godot desktop application for creating, generating, editing, organising, importing, exporting, analysing, and illustrating AI roleplay character cards.

The original PyWebView V1 application remains a feature and behaviour reference, not an architecture or interface specification. Useful V1 behaviour should be re-expressed as maintainable Godot-native systems rather than copied literally.

## Core Design Principles

- Godot-native UI using Control nodes and containers.
- Character project files are the source of truth; the legacy internal database is not a compatibility target.
- Large assets remain ordinary files rather than database blobs or data URLs.
- Search indexes and thumbnails are disposable caches.
- Template-driven fields and generation behaviour.
- Non-blocking networking and long-running tasks.
- Clear separation between project data, UI, AI providers, imports/exports, integrations, and generated assets.
- OpenAI-compatible and useful local/self-hosted backends remain first-class targets.
- Character text/vision providers and image-generation providers are separate configuration domains.
- Data formats are versioned and older content should remain usable where practical.
- New features extend the central project model rather than create parallel copies of character state.
- Wider desktop windows expose additional workspace instead of scaling the interface larger or letterboxing a fixed canvas.
- Detachable native tool windows are used where multi-monitor workflows benefit; primary navigation pages may remain embedded when clearer.
- Generation parity ports useful V1 behaviour into the Godot architecture rather than recreating PyWebView-specific implementation details.
- Workspace/editing structure, authoring/planning structure, AI-generation structure, and interoperable Character Card output fields are related but distinct layers.
- Stable IDs are internal references; user-facing names may change without silently breaking bindings or preferences.
- Major visual redesign should follow stable workflow architecture where practical, while missing core authoring behaviour should be restored before expanding secondary workflows.

## Current Development Phase

**v0.14.4 development candidate — V1 Authoring Workflow Parity**

The v0.13 line established the modern generation, validation, Q&A, provider, vision, project-lifecycle, and AI-authored image-prompt foundations. Runtime use then highlighted an authoring-parity problem: V2's generation architecture is stronger than V1, but several of V1's everyday ways of constructing a character were still missing or simplified.

The running development build displays **v0.14.4**. Published/tagged release metadata remains controlled by the release workflow until an actual release promotion is performed.

v0.14 restores three distinct V1 authoring routes while keeping one shared V2 project model:

- **Character Builder** — option-driven character construction for users who want structured choices without writing everything manually.
- **Manual Guided** — direct template-aware authoring for users who already know what they want; it does not require AI and skips private Interview / Q&A.
- **Idea Generator** — controlled ingredient/pool composition that can be randomised locally, locked/rerolled, and then optionally turned into an editable Generation Concept by AI.

These are intentionally separate workflows. Builder guidance, Manual Guided card values, Idea Generator ingredient pools, generation groups/components, private Interview answers, and final Character Card fields must not collapse into one ambiguous schema.

## Completed

### v0.14.4 — Manual Guided Direct Authoring

- Restored **Manual Guided** as a first-class workspace action separate from Character Builder and Idea Generator.
- Manual Guided opens as a detachable native Godot window and is explicitly a **no-AI** workflow; opening, editing, previewing, saving, and applying Manual Guided content never starts text generation or private Interview / Q&A.
- The workflow is driven by the active V2 Character Template instead of hard-coding a second card schema.
- Active template fields are organised into seven V1-inspired pages: **Description**, **Personality**, **Scenario**, **First Message(s)**, **Example Dialogues**, **Tags and System Prompt**, and **State Tracking and Image Prompts**.
- Each displayed template section has an **Include** toggle so users can retain draft material without applying that section to the character.
- Fields use their template labels, placeholders, types, and configured multiline heights where practical.
- A live **Manual Output Preview** updates from included fields as the draft changes.
- Applying writes values directly to their existing template paths in the active character and rebuilds the normal workspace form; there is no parallel Manual-only card format.
- Tags are converted back to arrays when applied. Alternative-greeting style fields can be authored as paragraph-separated entries and are converted back to arrays.
- Manual Guided state, including current page, include choices, and field drafts, is stored character-locally under `workspace.manual_guided` and therefore follows normal project save/load and character-transfer behaviour.
- Added v0.14.4 regression coverage for seven-page mapping, tags/alternate-greeting conversion, no-AI workspace wording, and build version wiring.

### v0.14.3 — Recoverable Generation Review

- Changed post-generation semantic/template review from a destructive gate into a recoverable Preview state when a usable parsed character candidate exists.
- The existing bounded automatic repair pass still runs first.
- If review still fails after repair, the generated candidate is preserved and its diagnostics are attached to Generation Preview instead of discarding the work.
- Users can keep/edit/selectively apply useful fields and then use the existing field-level AI Suggest action for weak sections.
- Truly unparseable output, provider/network failures, and internal pipeline faults without a trustworthy candidate still fail normally.
- Added dedicated regression coverage for recoverable review metadata and Preview behaviour.

### v0.14.2 — Character Transfer + Multiline Input Convention

- Added **Move / Copy…** for transferring the active character into an existing Character Project or a new project.
- Copy creates an independent character ID and remaps character-local managed paths; Move preserves character identity where practical.
- Character-local card data, Generation Concept, Builder state, Interview review/provenance, assigned template, generation history/settings, portrait/generated/emotion-image records, managed files, and character attachments travel with the character.
- Shared project context, shared attachments and project relationships remain project-level rather than silently following a transferred character.
- Move is destination-first: files are copied and the destination is saved before the source roster/files are changed.
- Moving a project's sole character leaves a fresh empty draft in the source so project-level context/attachments are preserved.
- Added an application-level `Shift+Enter` convention for multiline `TextEdit` controls.

### v0.14.1 — Desktop-Native Layout + Interview Review

- Switched the desktop app away from game-style canvas stretching so resizing/maximising exposes additional usable workspace instead of enlarging every control.
- Private Interview / Q&A planning carries answered question text and provenance into final generation metadata.
- The latest Interview review persists character-locally and is visible with **Manual answer** versus **AI Interview** provenance.

### v0.14.0 — Authoring Option Foundation

- Added `data/authoring_option_pools.json`, a versioned shared catalog keyed to existing Builder paths.
- Added reusable option pools for genre, setting, role/archetype, traits, strengths, flaws, speech style, relationship style, skills, scene location, user role, initial relationship, and tone.
- Character Builder presents **Try an option** controls while leaving all values editable.
- Single-choice suggestions fill; multi-value/tag suggestions append.
- Builder state and precedence remain compatible with existing `workspace.builder`, AI fill/extraction, Apply to Character, concept composition, and generation planning.
- `v0.14.0-hotfix1` removed the historical fixed 2,600-token private Interview output ceiling.
- `v0.14.0-hotfix2` made embedded Image Studio overflow vertically scrollable.

### v0.13.x — Generation Parity and Provider/Workflow Stabilisation

- Added semantic completeness validation, one targeted repair pass, generation-contract protection, diagnostics, and concept-fidelity checking.
- Added template format 3 generation groups/components with editable ordering, required/enabled state, AI instructions, output bindings, and same-output composition.
- Restored structured V1-inspired Description and Personality generation expectations.
- Added private Interview / Q&A planning, manual answers, required-answer checking, and bounded retries.
- Defined planning precedence: source concept → manual Interview/Q&A → Builder guidance → AI interview answers → existing card values/generic inference.
- Added Mode & Style controls for Full/Lite/Compact Lite intent, writing style, First Message style/length, and greeting guidance.
- Added configurable Alternative First Messages and Character Card V2 alternate-greeting export.
- Added separate Text and Vision models with independent context/output settings and capability discovery.
- Added two-stage Creative Concept vision workflows, recoverable malformed-provider JSON handling, broader assistant-response compatibility, default-template selection, project drafts, and AI-authored image prompts with deterministic local fallback.

### v0.12 — Image Expansion + Generation Parity Phase 1

- Separated Character AI profiles from Image Generation providers.
- Added Forge/Automatic1111 WebUI generation and OpenAI-compatible image APIs, discovery, batch controls, seeds, regeneration, and Image Studio.
- Made Generation Concept authoritative and strengthened core Character Card field guidance.

### v0.11.0 — Image Generation Foundation

- Added an independent image-generation role, generated-image storage/gallery/portrait assignment, metadata, prompt construction, and export integration.

### v0.10.0 — Vision and Attachments Foundation

- Added independent Text/Vision provider assignments, project/per-character attachments, preprocessing/context budgeting, generation context, and review-first visual analysis.

### v0.9.x — Series and Release Infrastructure

- Added versioned series bibles, Series Manager, categories/aliases/canon/visual/generation guidance, deterministic Auto Series, import/export, portable packs, export presets, validation/releases, semantic-version tooling, and release-helper infrastructure.

### v0.8.x — Character Library 2.0

- Added thumbnail/list views, portrait thumbnails, incremental indexing, broad search, sorting, favourites, folders, collections, tags, filters, bulk tools, and dashboard statistics reuse.

### v0.7.x — Import / Export Foundation

- Added Character Card V1/V2 import, V2 export, PNG/APNG metadata support, compatibility reports, lorebook preservation, CCF extension round trips, portable `.ccfproject`, and split-workflow JSON export.

### v0.6.x — Relationships and Multi-Character Card Workflows

- Added relationship matrices, directional editing/generation, relationship-aware context, and multi-character Card Workflow Studio planning.

### v0.5.x — Multi-Character Project Foundation

- Added project format v2 with `characters[]`, migration, shared context, roster tools, independent per-character state/assets/templates, Group Scene generation, and per-character asset directories.

### v0.4.x — Guided and Controlled Building Foundation

- Added Guided Character Builder, whole-builder presets, AI fill/extraction, Safe/Custom Section Build, selected-field revision, protected context, review-first field application, JSON repair, and diagnostics.

### v0.3.x — Template System and Native Tool Windows

- Added Template Manager, versioned user templates, editable sections/fields/types/AI instructions/output policy, migration/validation, initial Idea Generator, and Generation Preview.

### v0.2.x — Generation Foundation

- Added queued generation, cancellation, retries, editable previews, selective application, field suggestions, initial Idea Generator, token estimates, API profiles, and model discovery.

### v0.1.x — Application Foundation

- Added the Godot 4.6 shell, project JSON, settings, template-driven editing, Character Library foundation, asynchronous generation, and generation history.

## In Progress

### v0.14 — V1 Authoring Workflow Parity

The V1 source has now been formally inspected for its mature **Guided Manual**, **Idea Generator**, and Builder behaviour. The audit confirms that the three modes served different purposes and should remain distinct in V2.

**Implemented in the current v0.14 line:**

- Option-driven Character Builder foundation with shared data pools and editable custom values.
- Private Interview output-budget fix and persisted Interview review/provenance.
- Desktop-native resizing and Image Studio overflow fixes.
- Character Move/Copy with character-local authoring/assets.
- Shared `Shift+Enter` multiline convention.
- Recoverable generation-review candidates instead of destructive discard.
- Manual Guided seven-page direct-authoring foundation with live preview, include toggles, direct apply, and character-local draft persistence.

### V1 Authoring Audit — Accepted Behaviour to Restore or Evolve

#### Manual Guided

V1 behaviour confirmed and now represented by the v0.14.4 foundation:

- No AI and no private Q&A/Interview in the manual path.
- Active-template-driven fields rather than a separate hard-coded card schema.
- Seven navigation groups: Description; Personality; Scenario; First Message(s); Example Dialogues; Tags/System Prompt; State Tracking/Image Prompts.
- Per-section Include switches, compact/large editors, live output preview, and direct build/apply.
- Independent alternative first messages and specialised controls for known state fields are part of the parity target.
- V1's old Front Porch-specific manual group-card builder is not to be copied literally. V2 should eventually express equivalent multi-character manual authoring through the existing project/relationship/card-workflow architecture.

#### Idea Generator

The mature V1 Idea Generator was a controlled ingredient composer, not merely an unconstrained AI idea request. Restore/evolve the following:

- Ingredient fields: **Gender, Archetype, Core Conflict, Setting, Tone, Occupation / Role, Relationship to `{{user}}`, Status / Social Position, Personality, Subject Of, Engages In, Engages In (Sexual)**, plus Custom Instructions.
- Restore the broad V1 built-in catalogs as seed defaults where still useful, then adjust them from V2 runtime feedback rather than turning them into restrictive enums.
- Searchable options with editable custom values.
- Default multi-select fields: Personality, Subject Of, Engages In, and Engages In (Sexual).
- Allow any compatible pool to be configured as single- or multi-select.
- Multi-select chips with individual removal.
- User-editable option lists, one entry per line or equivalent native editor.
- Per-field reset and reset-all-to-built-ins.
- Configurable **Maximum Random Choices per Multi-Select Field**, default 3 and supporting the V1 1–20 range unless runtime UX suggests a better cap.
- Field locks, including Gender.
- Local **Randomise / Reroll Unlocked** that spends no AI tokens.
- Single-field local reroll.
- Data-driven conditional option pools; V1 used Gender to filter/extend some relationship/archetype choices.
- AI is optional until the final concept-development step: selected/randomised ingredients are first editable locally, then **Generate Concept** can turn them into one compact editable Generation Concept.
- Concept generation should create premise notes rather than a full card; the resulting concept remains editable before normal generation.
- Add reusable pool presets and template/user overrides using V2's data-driven architecture.

#### Character Builder

Continue using V1 as behavioural reference for the depth of structured choices without recreating its HTML forms literally:

- Character/visual choices should cover overall presentation/build/skin, hair, face/eyes/makeup, body details, clothing/footwear, accessories, distinguishing features, and vibe where useful.
- Personality Builder parity should cover core traits, confidence/social energy, fears/morals/decision style, relationship behaviour, attachment/conflict/secrecy, current relationship/social role, relationship with `{{user}}`, daily-life traits, and optional adult-coded traits where the user chooses to author them.
- Scene Builder parity should cover starting place/time/situation, immediate goal, complication/risk, props, and extra scene notes.
- Builder values remain guidance/planning inputs with higher specificity than loose concept text, not alternate Character Card fields.

## Next Up

### v0.14.x — Idea Generator Pool Workflow

The immediate next major authoring target after v0.14.4 is the V1-style Idea Generator restoration:

1. Move the accepted V1 ingredient catalogs into versioned external data.
2. Add native searchable pool editors and single/multi-select behaviour.
3. Add chips, locks, local single-field reroll, and **Reroll Unlocked**.
4. Add user/template overrides and reusable pool presets.
5. Keep local ingredient composition independent from AI.
6. Add an explicit **Generate Concept** step that turns the edited ingredients into compact Generation Concept notes.

### Remaining v0.14 Authoring and Organisation

- Expand/adjust the built-in Builder/Idea option catalog from V1 source and runtime feedback without turning suggestions into rigid enums.
- Add template/user authoring-option overrides with clear precedence.
- Add specialised Manual Guided controls for known state fields and a more V1-like add/remove UI for alternative greetings.
- Define provenance only where useful: direct manual value, selected preset, Idea Generator choice, concept extraction, Builder AI, or private Interview AI.
- Extend character transfer to future batch Move/Copy Selected workflows; preserve/remap relationships when multiple related characters are transferred together.
- Complete the formal V1 authoring UX matrix: missing / equivalent-relocated / replaced-evolved / partial / intentionally retired, plus V2-only features.

### Remaining v0.13 Generation Parity Core Carried Forward

- Expand configurable special generation contracts beyond component/minimum-length/marker foundations, including greeting counts and constrained sets where useful.
- Complete V1-equivalent split/multi-pass execution for Lite/Compact Lite rather than only density guidance.
- Continue real-provider regression testing of Q&A retries, Builder precedence, Mode & Style, component toggling/composition, semantic repair, concept-fidelity correction, malformed-JSON recovery, response-envelope compatibility, Creative Concept generation, capability discovery, AI image-prompt authoring, and default-template workflows.
- Consider expanding concept-fidelity marker types only where runtime evidence shows they remain high-confidence.

### v0.15 — Image Workflow Expansion

The image milestone remains after primary character-authoring parity:

- Add image-to-image/reference-image generation where supported.
- Allow generated images and managed visual attachments to become generation references without embedding binary data in JSON.
- Add emotion-image generation/regeneration using the existing `emotion_images/` tree.
- Add named emotions/expressions and per-emotion editable prompts.
- Add reusable visual-style/prompt presets.
- Add richer gallery management including intentional deletion with portrait/reference safety checks.
- Add provider-specific quality/aspect controls where useful.
- Add optional Stable Diffusion advanced helpers such as LoRA/embedding-oriented prompt tools without making one WebUI ecosystem part of the central character schema.
- Expand AI-authored prompt refinement/regeneration while retaining deterministic/local visual-anchor fallback.

### Post-core Workspace and Visual Interface Pass — Version TBD

Do the larger navigation/theme/layout redesign after core generation, authoring, Q&A, image, import/export, and project workflows are stable enough that visual restructuring is unlikely to be immediately invalidated. Small usability and data-loss fixes continue as soon as identified.

## Ongoing Validation

- Real-world testing across multiple OpenAI-compatible text and vision backends.
- Compare fresh characters against pre-parity V2 output, especially Description/Personality separation and concept fidelity.
- Deliberately test concept/manual-Q&A/Builder/AI-answer precedence conflicts and semantic repair after those conflicts.
- Test long Generation Concepts and larger custom Interview/Q&A sets with reasoning models; Interview must retain the resolved Text-role output budget.
- Confirm persisted Interview reviews match responses used by generation and preserve Manual versus AI provenance after save/reopen.
- Confirm desktop resizing exposes additional workspace without scaling controls larger; genuine overflow remains reachable through local scroll containers.
- Confirm character Move/Copy preserves exact character-local state/files while excluding project-shared context/relationships; failed destination saves leave source untouched.
- Confirm `Shift+Enter` remains reliable across existing and future multiline editors.
- Confirm recoverable review failures preserve usable generation and still distinguish genuinely unusable output.
- Test Manual Guided across Default and custom templates, save/reopen, character transfer, tags, alternative greetings, and direct apply with zero AI jobs.
- Confirm Detailed/Cinematic First Message modes remain substantially fuller while Brief remains intentionally short.
- Confirm multiple generation groups bound to the same output field compose in template order and repair identifies missing groups/components.
- Confirm malformed provider JSON enters normal repair without noisy engine parser failures.
- Confirm alternate provider envelopes produce usable assistant text and reasoning/length failures produce actionable diagnostics.
- Test Creative Concept with sparse and detailed images.
- Test model capability discovery across rich, partial, and ID-only backends; unknown limits remain unknown rather than guessed.
- Confirm NanoGPT detailed discovery loads `context_length` / `max_output_tokens` when published.
- Test Text and Vision models with different context/output limits and independent Auto/manual behaviour.
- Test default-template lifecycle, project draft lifecycle, Builder option selection, and arbitrary custom Builder values.
- Compare AI-authored image prompts against the local fallback across simple and elaborate cards.
- Forge/Automatic1111 and OpenAI-compatible image batch testing.
- Template format-2 → format-3 migration and custom generation-component testing.
- Guided Builder, Manual Guided, Idea Generator, relationship, group/card workflow, import/export, large-library, series, attachments, vision, and `.ccfproject` interoperability testing.

## Technical Improvements

- Simplify the release workflow around the canonical development Git checkout and retire the unnecessary two-copy staging path when safe.
- Generate and commit canonical Godot 4.6 `.gd.uid` sidecars rather than repeatedly treating them as disposable local noise.
- Synchronise project/release version metadata so `project.godot`, the development build label, VERSION, tags, and release assets cannot drift silently.
- Continue replacing version-layer compatibility bridges with clean named APIs when the surrounding workflow is stable.
- Audit remaining primary pages/tool windows for fixed minimum sizes or game-style assumptions that fight normal desktop resizing; use flexible containers and local scrolling where content genuinely cannot fit.

## Long-Term Ideas

- Visual relationship-map canvas with draggable character cards, directional/mutual connections, labels, notes, grouping, zoom/pan, and future world-entity support.
- Character Concept Exchange format after authoring/planning schemas are stable.
- GitHub-Releases-only packaged updater with explicit user-controlled download/install, release channels, hashes, safe restart/install, and no automatic installation.
- Richer reusable authoring libraries and community-shareable presets after the local data model proves stable.
- V2-native multi-character Manual Guided/group-card workflows layered on the existing project, relationship, and Card Workflow systems rather than reviving V1's Front Porch-specific manual group implementation.
