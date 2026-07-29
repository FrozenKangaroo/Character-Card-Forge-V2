# Character Card Forge — Project Roadmap

## Project Vision

Rebuild Character Card Forge as a responsive, native Godot desktop application for creating, generating, editing, organising, importing, exporting, analysing, and illustrating AI roleplay character cards.

The existing PyWebView application remains a feature and behaviour reference, not an architecture or interface specification. Useful V1 behaviour should be re-expressed as maintainable Godot-native systems rather than copied literally.

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
- Wider desktop windows expose additional workspace instead of letterboxing a fixed interface.
- Detachable native tool windows are used where multi-monitor workflows benefit; primary navigation pages may remain embedded when clearer.
- Generation parity ports useful V1 behaviour into the Godot architecture rather than recreating PyWebView-specific implementation details.
- Workspace/editing structure, AI-generation structure, planning controls, and interoperable Character Card output fields are related but distinct layers.
- Major interface restructuring and visual polish should follow stable workflow architecture where practical, avoiding repeated UI rewrites while core authoring/generation systems are still changing.

## Current Development Phase

**v0.13.6 development candidate — Project Draft Lifecycle & Usability**

The v0.12 source milestone is already merged into `main`: it contains expanded image generation, separated image providers, and Generation Parity Phase 1. v0.13 moves parity into the generation engine, makes V1-style structured Description/Personality expectations editable template data, adds a bounded private planning interview, defines Builder precedence, restores Mode & Style author intent, adds conservative concept-fidelity correction, and is now tightening project/character lifecycle and usability problems exposed by real runtime testing.

The running development build displays **v0.13.6**. Published/tagged release metadata remains controlled by the release workflow until an actual release promotion is performed.

The current v0.13 candidate now includes:

- semantic completeness validation after ordinary JSON parsing;
- one targeted repair pass for valid-but-incomplete full-character results;
- revalidation before Generation Preview;
- repair diagnostics and a visible cancellable repair queue stage;
- fail-closed template-contract protection and a regression test for the v0.13.3 Mode & Style decorator collision;
- template format **3**, adding first-class `generation_groups` and generation components;
- automatic loading/normalisation of older format-2 templates;
- generation groups that bind many structured components into an existing interoperable card/workspace field rather than creating extra Character Card top-level fields;
- add/remove/reorder generation groups and components;
- per-group enable/disable, output-field binding, and allow-extra-components policy;
- per-component label, AI instruction, enabled state, required state, and ordering;
- disabled components omitted from both generation prompts and completeness validation;
- enabled required components used by semantic missing-component repair;
- a Template Manager **Edit Generation Components** workflow with safe close protection for unapplied edits;
- the Default Description structure: Age, Appearance, Outfit Style, Distinguishing Features;
- a richer V1-inspired Default Personality structure: Mind, Moral Alignment, Emotional Tendencies, Decision Style, Occupation, Likes, Dislikes, Hobbies, Skills, Boundaries, Risk Tolerance, Secrecy, Relationship Behavior toward `{{user}}`, Loyalty, and Speech Style;
- standard Character Card Description and Personality remain the final interoperable output fields;
- a private pre-generation interview before full-character generation;
- a bundled default interview covering identity, motivation, inner conflict, `{{user}}` dynamic, boundaries, voice, visual anchors, opening hook, and an optional complication;
- template-defined **Interview / Q&A** sections overriding the bundled interview when present;
- inherited bundled questions surfaced in Template Manager so they can be viewed and duplicated/customised rather than remaining hidden runtime data;
- existing non-empty Interview / Q&A workspace values treated as manual planning answers rather than replaced;
- required-answer completeness checking and up to two targeted retries containing only still-missing required answers;
- clean failure before full-card generation when required planning answers remain missing after the bounded retries;
- completed interview answers fed into final generation as ephemeral private planning context rather than card output or persisted completion metadata;
- visible cancellable queue stages for planning, missing-answer completion, full generation, and semantic repair;
- explicit character-planning precedence: source concept → manual Interview/Q&A → current Builder guidance → AI-inferred interview notes → existing card values/generic inference;
- non-empty Builder state fed into the private interview, missing-answer retries, full generation, and semantic repair rather than remaining isolated from Generate Character;
- compact Builder participation diagnostics stored in generation metadata without duplicating the raw Builder scratchpad;
- direct Builder projection aligned with parity semantics so Character Card Description receives physical Appearance rather than role/backstory/skills/secrets/boundaries;
- an app-level **Mode & Style** Workspace tab available regardless of active template;
- V1-inspired Full Prompt, Lite, and Compact Lite author-intent modes, with split/multi-pass execution still planned as a later strategy upgrade;
- independent Writing Style, First Message Style, First Message Length, and greeting-specific custom instructions;
- **Cinematic + Detailed** as the default opening behavior, targeting roughly 350–650 words, while Brief remains an explicit 60–160 word option;
- Mode & Style guidance preserved through full generation and semantic repair;
- conservative concept-fidelity plans built from high-confidence source markers after template validation;
- supplied non-placeholder character names, explicit numeric ages, and distinctive cup-size measurements treated as critical fidelity markers;
- quoted/backticked literal concept markers retained as advisory diagnostics without forcing automatic rewrites;
- at most one stricter full-JSON concept-fidelity correction pass for clear critical drift, preserving source concept precedence, template structure, planning context, and Mode & Style;
- compact fidelity metadata including retry use and any remaining clear drift rather than an unbounded retry loop;
- Generation Preview **Apply Selected** now autosaves accepted generated fields immediately;
- Image Studio automatic prompt building no longer falls back to raw Generation Concept prose;
- deterministic Stable Diffusion tag-style prompt synthesis from physical Description content plus visually detectable Scenario setting/time/weather/lighting/objects;
- natural-language image prompts restricted to visually useful character/setting information rather than Personality or hidden story explanation;
- Auto image-prompt style resolving to SD tags for Forge/A1111 and natural language for OpenAI-compatible image providers;
- Generate/Cancel moved into the upper Image Studio controls so the primary action cannot be pushed below the visible prompt workspace;
- V2 PNG export uses the active portrait automatically when available instead of always asking for another source image;
- Character AI profiles expose separate Text and Vision model selections while retaining shared provider credentials where desired;
- default Vision Analysis now keeps Character Card Description strictly physical/visual and no longer proposes Personality;
- single-character project presentation and terminology now distinguish Character Projects from contained Characters more clearly;
- new Character Projects begin as in-memory drafts instead of immediately creating empty Library entries;
- empty added-character drafts are discarded before save rather than becoming repeated placeholder characters;
- unnamed meaningful characters are blocked from being persisted under placeholder names;
- unnamed projects automatically use the first name of the first real character, while an explicitly entered project name remains authoritative;
- null AI proposals are filtered before Generation Preview so values such as `<null>` are not offered as real edits.

## Completed

### v0.12 source milestone — Image Expansion + Generation Parity Phase 1

Source merged to `main`; it was a source milestone rather than a separate published release.

- Separated Character AI profiles from dedicated Image Generation providers with settings-format-v6 migration.
- Added separate Character AI and Image Generation Settings tabs.
- Added Forge/Automatic1111 WebUI generation alongside OpenAI-compatible Images APIs.
- Added `/sdapi/v1/txt2img`, checkpoint/sampler discovery, OpenAI `/models` discovery, batches, sampler/steps/CFG/seed controls, returned-seed capture, Regenerate, and New Seed Variant workflows.
- Kept Image Studio as a selected main workspace while provider credentials live in Settings.
- Source-audited V1 generation behaviour and documented the quality/architecture gaps.
- Made Generation Concept authoritative in the Default template.
- Restored Description to physical/external semantics.
- Expanded Personality generation guidance and strengthened Scenario / First Message continuity and Example Dialogue formatting.

### v0.11.0 — Image Generation Foundation

- Added an independent Image generation role.
- Added OpenAI-compatible image generation, flexible response decoding, PNG normalisation, generated-image storage, prompt construction, gallery/preview, portrait assignment, metadata, documentation, and validation.

### Release Workflow Maintenance after v0.11.0

- `release.sh` automatically fetches/fast-forwards a clean destination `main`, reconciles already-merged synced content, stops for genuine local divergence, and removes the normal manual post-merge fetch/reset step.

### v0.10.0 — Vision and Attachments Foundation

- Added independent Text/Vision provider assignments, project/per-character attachments, preprocessing/context budgeting, generation context, review-first visual analysis, and portable attachment storage.

### v0.9.x — Series and Release Infrastructure

- Added versioned series bibles, Series Manager, categories/aliases/canon/visual/generation guidance, deterministic Auto Series, categories, import/export, and portable packs.

### v0.8.x — Character Library 2.0

- Added thumbnail/list views, portrait thumbnails, incremental indexing, broad search, sorting, favourites, folders, collections, tags, filters, bulk tools, and dashboard statistics reuse.

### v0.7.x — Import / Export Foundation

- Added Character Card V1/V2 import, V2 export, PNG/APNG metadata support, compatibility reports, lorebook preservation, CCF extension round trips, portable `.ccfproject`, and split-workflow JSON export.

### v0.6.x — Relationships and Multi-Character Card Workflows

- Added relationship matrices, directional editing/generation, relationship-aware context, and multi-character Card Workflow Studio planning.

### v0.5.x — Multi-Character Project Foundation

- Added project format v2 with `characters[]`, migration, shared context, roster tools, independent per-character state/assets/templates, Group Scene generation, and per-character asset directories.

### v0.4.x — Guided and Controlled Building

- Added Guided Character Builder, presets, AI fill/extraction, Safe/Custom Section Build, selected-field revision, protected context, review-first field application, JSON repair, and diagnostics.

### v0.3.x — Template System and Native Tool Windows

- Added Template Manager, versioned user templates, editable sections/fields/types/AI instructions/output policy, migration/validation, Idea Generator, and Generation Preview.

### v0.2.x — Generation Foundation

- Added queued generation, cancellation, retries, editable previews, selective application, field suggestions, Idea Generator, token estimates, API profiles, and model discovery.

### v0.1.x — Application Foundation

- Added the Godot 4.6 shell, project JSON, settings, template-driven editing, Character Library foundation, asynchronous generation, and generation history.

## In Progress

### v0.13 — Generation Parity Core candidate

**Implemented:**

- Semantic completeness validation and one bounded targeted repair pass.
- Revalidation before review and repair diagnostics metadata.
- Fail-closed template contract protection, including regression coverage for the v0.13.3 generation-contract dispatch bug.
- Template format 3 with generation groups/components and backwards loading of format 2.
- Explicit separation between normal workspace/output fields and structured generation components.
- Editable output bindings from a generation group to an existing card/workspace field.
- Add/remove/reorder/enable/disable generation groups and subcomponents.
- Required/optional component semantics and per-component AI instructions.
- Dynamic contract prompts and validation generated from the active template rather than fixed Default Personality labels.
- Default V1-inspired Description and Personality structures stored as data.
- Unsaved-change protection for the Generation Components editor.
- Private pre-generation interview before full-character generation.
- Bundled default interview when a template has no Interview / Q&A section.
- Bundled/inherited Interview / Q&A visibility through Template Manager, with custom templates able to save their own edited question sets.
- Template-defined interview questions using existing `interview` section fields and their AI/required settings.
- Manual non-empty interview-field values respected as existing planning answers.
- Required Q&A completeness checking and up to two targeted missing-answer retries.
- Completed Q&A fed into full generation as private planning context without persisting AI answers as card/project output.
- Queue status exposes interview planning and missing-answer retry stages.
- Character-specific planning precedence: source concept > manual Interview/Q&A > Builder guidance > AI interview answers > existing card values/generic inference.
- Current non-empty Builder state participates in interview planning, missing-answer retries, full generation, and semantic repair.
- Builder participation metadata records only counts/precedence diagnostics rather than duplicating raw planning text.
- Builder direct Description projection corrected to physical Appearance only; role, goals, backstory, skills, secrets, and behavioural boundaries remain on the Personality/lore side.
- App-level Mode & Style state stored with the character generation workspace rather than tied to one template.
- Full/Lite/Compact Lite density guidance foundation.
- Writing Style plus independent First Message style/length/custom guidance.
- Detailed cinematic greeting as the new default instead of universal short greetings.
- Mode & Style participation in semantic repair.
- Conservative concept-fidelity plans for supplied names, explicit numeric ages, distinctive cup-size literals, and advisory quoted markers.
- One bounded concept-fidelity correction for clear critical drift after semantic/template validation.
- Fidelity correction retains source concept precedence, planning context, Mode & Style, and the active template contract.
- Fidelity metadata records marker counts, retry use, advisory misses, and remaining clear drift without unbounded retries.
- Generation Preview Apply Selected autosave.
- Visual-only SD prompt synthesis plus Scenario-derived environment/time/lighting tags.
- Raw Concept removal from automatic SD-prompt fallback behavior.
- Always-visible Image Studio Generate/Cancel controls.
- Portrait-backed Character Card V2 PNG export path.
- Separate Text/Vision model selection for shared Character AI profiles.
- Default Vision Analysis physical-only Description scope and no default Personality inference.
- Character Project vs Character terminology/presentation cleanup.
- In-memory new-project drafts, empty-character pruning, first-character project naming, and placeholder-name save protection.
- Null AI proposal filtering before Generation Preview.
- Existing Generation Preview remains the final review boundary.
- Existing asynchronous queue/cancellation architecture remains authoritative.

**Still in v0.13:**

- Improve visible stages beyond the current queue labels: generation, fidelity check, validation, repair, ready for review.
- Present interview, planning-precedence, Mode & Style, concept-fidelity, semantic validation, and repair diagnostics directly in Generation Preview.
- Expand configurable special contracts beyond the current component/minimum-length/marker foundations, including greeting counts and constrained sets where useful.
- Complete V1-equivalent split/multi-pass execution for Lite/Compact Lite rather than only density guidance.
- Restore configurable alternative First Messages with per-alternative style/instructions and interoperable export where supported.
- Test Q&A retries, Builder precedence, Mode & Style, component toggling, semantic repair, and concept-fidelity correction across real text backends and deliberately incomplete/low-token responses.
- Consider expanding automatic concept-fidelity marker types only where runtime evidence shows they can remain high-confidence and avoid false-positive rewrites.
- Consider per-Builder-field provenance only if later workflows need to distinguish manual, preset, concept-extracted, and Builder-AI values inside the accepted scratchpad.

### Ongoing validation

- Real-world testing across multiple OpenAI-compatible text backends.
- Compare fresh characters against pre-parity V2 output, especially Description/Personality separation and concept fidelity.
- Test the v0.13.1 interview → missing-answer retry → full generation → semantic repair sequence, including templates that override or disable the bundled interview.
- Test v0.13.2 conflicts deliberately: concept versus manual Q&A, manual Q&A versus Builder guidance, Builder guidance versus AI-inferred interview answers, and semantic repair after those conflicts.
- Test v0.13.3 First Message modes deliberately: Detailed/Cinematic should be substantially fuller than earlier V2 output while Brief remains intentionally short.
- Test v0.13.4 deliberate fidelity drift: supplied name changes, numeric age changes/omissions, explicit cup-size loss, equivalent written-out ages, and advisory quoted-marker omissions that must not trigger retries.
- Confirm Apply Selected persists accepted generation before immediately entering Image Studio.
- Use the Lila-style regression fixture to confirm SD prompt building produces visual tags rather than `Age:/Appearance:/Outfit Style:` prose or relationship/motive text.
- Confirm scenarios such as **university classroom at sunset** contribute environment/time/lighting tags without leaking nonvisual motivations or hidden relationship details.
- Confirm default Vision Analysis keeps environment/pose information out of Description and filters null optional proposals.
- Test draft lifecycle deliberately: empty new project → leave without Library entry; first named character → first save; empty added character → prune; manual project name → preserve.
- Forge/Automatic1111 and OpenAI-compatible image batch testing.
- Template format-2 → format-3 migration and custom generation-component testing.
- Guided Builder, relationship, group/card workflow, import/export, large-library, series, attachments, vision, and `.ccfproject` interoperability testing.

## Next Up

### Remaining v0.13 Generation Parity Core

Richer multi-stage progress and Generation Preview diagnostics are the next major parity slice once the current runtime usability regressions are settled, followed by alternative greeting parity and eventual true split/multi-pass Lite/Compact Lite execution.

### v0.14 — Image Workflow Expansion

The immediate Image Studio correctness/usability repairs landed during v0.13 because they blocked normal character → portrait testing. The larger v0.14 expansion remains planned.

- Add image-to-image/reference-image generation where supported.
- Allow generated images and managed visual attachments to become generation references without embedding binary data in JSON.
- Add emotion-image generation/regeneration using the existing `emotion_images/` tree.
- Add named emotions/expressions and per-emotion editable prompts.
- Add reusable visual-style/prompt presets.
- Add richer gallery management including intentional deletion with portrait/reference safety checks.
- Add provider-specific quality/aspect controls where useful.
- Add optional Stable Diffusion advanced helpers such as LoRA/embedding-oriented prompt tools without making one WebUI ecosystem part of the central character schema.
- Consider an optional text-model visual-prompt refinement pass while retaining deterministic/local visual tag synthesis as a no-extra-provider path.

### Post-core Authoring Workflow and Interface Pass — version TBD

Do this after the major generation, Q&A, image, import/export, and project workflows are sufficiently stable that UI changes are unlikely to be immediately invalidated by another architecture change.

- Restore a full **Guided Manual** authoring mode inspired by V1, implemented on top of the same template, generation-component, output-binding, and project data model used everywhere else.
- Expand the existing Builder foundation into richer Character, Personality, and Scene Builder workflows with stronger presets, manual guidance, optional AI assistance, review-first application, and integration with concept/Q&A context.
- Perform a systematic V1 parity and authoring-UX audit to classify features as missing, relocated, evolved/replaced, partial, or intentionally retired before the final interface redesign.
- Hide implementation-facing identifiers such as internal field/component IDs behind sensible automatic defaults and Advanced controls wherever users do not need to manage them directly.
- Revisit Workspace information architecture once the final set of major workflows is known: use clearer tabs/pages/sections, reduce the current top-level button wall, and group related tools by task rather than historical implementation order.
- Perform the larger visual-polish pass only after workflow hierarchy stabilises: spacing, typography, theme/identity, responsive layouts, high-density/ultrawide use, consistent controls, keyboard workflows, onboarding, and better empty/error/progress states.

## Planned Features

### Generation Improvements

- Streaming text support where providers support it.
- Generation components/output bindings and editable per-template semantic contracts. **Core implemented in v0.13 candidate; expand special contracts over time.**
- V1-style private Q&A completeness and targeted missing-answer retries. **Core implemented in v0.13.1 candidate.**
- Conservative concept-fidelity validation/retry. **Core implemented in v0.13.4 candidate; expand marker types only when they remain high-confidence.**
- Semantic completeness validation and targeted repair. **Initial core implemented in v0.13 candidate.**
- Builder guidance precedence for full generation and semantic repair. **Core implemented in v0.13.2 candidate.**
- V1-inspired Mode & Style controls and First Message length/style guidance. **Foundation implemented in v0.13.3 candidate.**
- V1-style Full/Lite/Compact-Lite or equivalent true multi-pass strategies after the core contract is stable; v0.13.3 currently restores the user-facing modes as density guidance, not the old split execution.
- Alternative First Messages with configurable count, preset/custom style, and separate instructions, mapped to interoperable card fields where supported.
- Section-by-section generation/continuation with per-stage progress, inspired by the later V1 beta workflow once its desired Godot behaviour is cleanly specified.
- Configurable special formatting rules such as `<START>` counts, greeting counts, and constrained tag sets.
- Recent/favourite model lists, broader provider capability detection, token-limit metadata/context estimation, and reusable provider presets.

### Authoring Workflows

- **Guided Manual mode:** provide template-driven manual character construction where the user can work through the active sections/components directly, without requiring AI generation. It should use the same underlying data model as generated cards rather than a parallel manual-only representation.
- Guided Manual should understand enabled/disabled template structure, required content, output bindings, section progress/completeness, and the final interoperable Character Card projection.
- Allow optional AI assistance inside Guided Manual where useful, but keep manual authoring fully usable without an AI provider.
- **Builder expansion:** grow the current Guided Character Builder foundation back toward the richer V1 workflow, including distinct Character, Personality, and Scene Builder experiences where that separation remains useful.
- Builders should accept both manual input and AI-assisted fill/extraction, preserve explicit user guidance, feed structured planning context into final generation, and participate in the v0.13 precedence rules rather than acting as isolated tools.
- Add/revisit builder presets, reusable builder templates, clearer completion/progress state, richer selective revision, and smooth handoff between Concept → Q&A → Builders → final generation.
- Keep builder data as planning/source context unless explicitly mapped into card output; do not recreate the old architecture by making every planning field a permanent exported card field.

### Multi-Character Workflows

- Relationship matrix generation/editing and relationship-aware context. **Foundation completed.**
- Multi-character single-card planning, split-card batch planning, and group-card planning. **Foundations completed; final generation/export execution remains planned.**
- Add a visual **Relationship Map** editor using draggable character cards, directional/named connections, selectable anchor points, and editor-only layout metadata while keeping relationship content independent of canvas geometry.
- Shared lore/deeper continuity and additional relationship visualisation/flowchart views.

### Character Library 2.0

- Thumbnail grid/list, sorting/filtering, tags/tag merging, folders, collections, series filters, favourites, and incremental index. **Foundations completed.**
- Card groups/variations, flowchart/relationship views, and richer image/portrait filtering.

### Series System

- Series definitions/bibles, Manager, generation guidance, deterministic Auto Series, categories, import/export, and portable packs. **Foundations completed.**
- Provider-assisted semantic matching, series artwork, richer hierarchy, and collection-level defaults.

### Vision and Attachments

- Images as concept references and review-first analysis. **Foundation completed.**
- Default concept-mode analysis should remain observational: physical Character Description only, with scene context kept outside Description and no automatic Personality inference. **Implemented in v0.13.5 hotfix.**
- GIF frame selection, image URL references, native PDF text extraction, preprocessing/context refinement, and visual-reference handoff to v0.14 image workflows.

### Image Generation

- OpenAI-compatible generation, prompt builders, gallery, portrait assignment. **Foundation completed.**
- Forge/Automatic1111, provider settings, checkpoint/sampler discovery, batches, seeds, regeneration, and SD defaults. **v0.12 source milestone implemented.**
- Visual-only SD prompt synthesis, Scenario-derived setting/time/lighting tags, no raw Concept fallback, provider-aware Auto prompt style, and always-visible Generate/Cancel. **v0.13.3 repair candidate.**
- Image-to-image/reference generation, emotion workflows, per-emotion prompts, visual presets, richer provider controls, and LoRA/embedding helpers. **v0.14/later.**

### Import / Export

- Character Card V2 JSON/PNG/APNG, SillyTavern-oriented mappings, lorebook preservation, `.ccfproject`, and split-workflow JSON export. **Foundation completed.**
- Broader ecosystem testing, PNG batch export, automatic split-workflow generation, additional meaningful formats, and generated/emotion image export options.

### Character Concept Exchange — later milestone

This is intentionally planned after the generation/template/Q&A architecture has stabilised enough that the concept format can remain durable instead of changing every few releases.

- Add a Character Card Forge-specific, versioned, human-readable concept document for **pre-generation source material**, distinct from a completed Character Card or full `.ccfproject` project.
- Working format idea: JSON content with a dedicated extension such as `.ccfconcept`; exact extension and schema should not be frozen until the generation/template model is mature.
- Make the format easy for external AI assistants to produce from a conversation or partially fleshed-out character idea, with a published schema/example and clear instructions for generating a valid concept file.
- Keep the format deliberately higher-level and more stable than the internal project/template schema. It should describe what the character should become rather than mirror every current workspace field or generation-component ID.
- Require a main concept, with optional structured planning material such as identity ideas, physical/visual direction, personality direction, background, relationships, setting, scenario/opening ideas, constraints, and freeform notes.
- Include optional **template Q&A answers** associated with a recognised Character Card Forge Q&A template once the Q&A template format is stable.
- Include optional **extra Q&A** as arbitrary character-specific question/answer pairs that do not have to exist in the reusable Q&A template, preserving the useful V1 one-off-question workflow.
- During import, map compatible template-Q&A answers to the active Q&A plan, retain unmatched imported answers as supplemental/extra Q&A instead of silently discarding them, and leave unanswered required current-template questions for the normal Q&A completeness pass.
- Treat imported and extra Q&A as private planning context for generation, not automatic Character Card output.
- Allow omitted/unknown sections so a rough concept remains valid and Character Card Forge can perform the detailed generation work later.
- Import through a review/mapping step into a new character or character concept workspace instead of treating the file as a finished card.
- Feed imported concept material into the normal Character Card Forge pipeline: templates, generation components, private Q&A, builders, Mode & Style, concept-fidelity checks, semantic repair, and Generation Preview.
- Consider concept export as well as import so concepts can be shared, archived, refined by another AI, and re-imported without requiring a completed card.
- Version the concept format independently and provide migrations/defaults once it enters active use.

### Front Porch Integration

- Data folder discovery/configuration, character scanning, import, install/export, character management, and chat reading/export where practical.

### Quality Tools

- Final AI Audit, card rating/improvement suggestions, consistency checking, broader missing-field reports, token estimates, revision history/snapshots, and image-recipe comparison.

## Data and Content Tools

- Keep character-project JSON and template schemas documented.
- Maintain project/template migrations as formats evolve.
- Maintain and version the `.ccfproject` renamed-ZIP package format.
- Keep generated assets referenced through relative portable paths.
- Preserve older generated-image records as metadata evolves.
- Add reusable template packs if community template sharing becomes useful.
- Maintain documentation for workspace fields vs generation components vs output bindings.
- Document persistent planning settings such as Mode & Style separately from exported card fields.
- When Character Concept Exchange is implemented, keep its schema/version independent from the internal project/template formats so concept files remain portable across Character Card Forge versions where practical.

## Technical Improvements

- Add automated schema/behaviour tests beyond marker validation.
- Add recovery from interrupted writes, optional autosave/snapshots, async thumbnails, general cancellable tasks, structured logging/diagnostics, secure credential storage, additional authentication modes, UI script decomposition, and provider-adapter abstractions as diversity grows.
- Keep generation validators/repair logic in reusable services rather than embedding V1 assumptions in workspace UI code.
- Keep image-prompt synthesis separate from Character Card Description so prose-card semantics and provider-specific visual prompt formats do not collapse into one field again.
- Add release-aware update checking against **published GitHub Releases/package assets only**, never repository source state. Update installation must remain explicitly user-approved, support staying on older versions, and eventually use safe download/verification/restart-helper/rollback mechanics rather than silently overwriting the running application.

## Polish

Major interface polish is intentionally sequenced after the main systems and authoring workflows are in place, while small usability fixes that prevent data loss or block testing should continue to be addressed immediately.

- Rework Workspace navigation and hierarchy around the final workflows rather than continuing to accumulate unrelated top-level buttons.
- Use tabs/pages/sections where they make task boundaries clearer, while retaining detachable windows where multi-monitor use genuinely benefits.
- Create a stronger application theme and visual identity with consistent spacing, typography, hierarchy, selected states, form controls, dialogs, and status/progress presentation.
- Refine responsive behaviour for normal desktop, ultrawide, high-DPI, and smaller supported windows.
- Add keyboard shortcuts and keyboard-first editing/navigation where practical.
- Add drag-and-drop where it improves file/image workflows.
- Improve onboarding, empty states, inline explanations, validation feedback, error recovery, and progress reporting.
- Standardise unsaved-change protection and safe close/navigation behaviour across editors and tool windows.
- Add native completion notifications where useful and denser gallery/library browsing where large collections benefit.

## Long-Term Ideas

- Optional LAN/mobile companion service, plugin/provider extension API, community template sharing, batch character generation, local semantic library search, and provider-agnostic image recipe presets.

## Deferred / Experimental Ideas

- Legacy database import remains intentionally deferred.
- Reproducing the old PyWebView interface is not planned.
- A mobile browser interface only returns if a strong separated workflow need appears.
- Highly backend-specific Stable Diffusion controls remain optional adapter-owned features rather than mandatory project fields.
- Exact recreation of V1 prompt strings is not a goal; source-audited behaviour should be expressed as maintainable Godot-native data and services.
