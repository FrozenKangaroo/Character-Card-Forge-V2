# Generation Parity Plan

Character Card Forge V2 is not intended to recreate the PyWebView implementation, but V1 remains an important behavioural reference for character-generation quality.

A source audit of the public V1.0.13 code showed that the old application did substantially more than send a single broad prompt. This document records the behaviours worth carrying forward into the Godot architecture and separates what is implemented now from later work.

## Why this exists

The early Godot rewrite deliberately focused on clean storage, native UI, portable projects, templates, builders, imports/exports, relationships, attachments, and provider services. Its first full-character generator was intentionally simpler: collect every template field marked `generate`, ask for one JSON object, repair malformed JSON when possible, then show the result in Generation Preview.

That is a sound foundation, but it does not reproduce several quality controls that existed in V1.

The goal of Generation Parity is therefore:

- keep V2's modular Godot services and review-first workflow;
- port the useful generation behaviours that made V1 more reliable;
- avoid copying PyWebView-specific state management or UI architecture;
- keep character-card interoperability clean;
- keep templates data-driven and migratable.

## Source-audited V1 behaviours

### Description and Personality had distinct responsibilities

V1's default Description focused on visible appearance and external traits. Its default structured guidance included age, appearance, and outfit style.

V1's Personality guidance focused on internal traits and roleplay behaviour, including motivation, behaviour toward `{{user}}`, and speech style.

The early V2 Default template blurred these responsibilities by describing Description as appearance, background, role, habits, and important facts. Phase 1 corrects this immediately.

### Structured authoring could fold into standard Character Card fields

V1 treated authoring/generation structure as more detailed than the final interoperable Character Card schema. Multiple Description-oriented components could be folded into Description, and multiple Personality-oriented components could be folded into Personality.

This is different from assuming that every editable or generatable concept must become its own top-level Character Card field.

A future template schema should explicitly represent three layers:

1. **Workspace fields** — persistent editable project information.
2. **Generation components** — structured expectations/questions used while producing content.
3. **Output bindings** — interoperable Character Card destinations such as `data.description` or `data.personality`.

These layers may overlap, but they should not be forced to be identical.

### Enabled template fields were generation instructions

In V1, disabling a configured subfield removed that expectation from the generated template. Enabled fields were not merely UI visibility controls.

V2 already distinguishes `generate` and `required` on workspace fields. Generation Parity Core should add an explicit enabled/required model for generation components rather than overloading existing field semantics.

### V1 validated generated content after the model answered

V1 did not treat syntactically valid output as automatically complete.

It checked enabled sections and fields, plus special structural rules such as:

- requested alternative greeting count;
- exactly one `<START>` marker in Example Dialogues;
- non-empty tag output;
- non-empty enabled ordinary sections.

When content was missing, V1 could request replacement content for the affected section and merge the repair back into the original card before validating again.

V2 currently has robust JSON extraction/repair but does not yet have the equivalent template-semantic completeness pass.

### V1 had a private pre-generation Q&A pass

When template Q&A was enabled, V1 first asked the model to answer the configured questions as private planning context.

It then checked whether every question had been answered, retried only missing questions, canonicalised the Q&A ordering, and fed the completed answers into final card generation without exporting the interview as a card section.

This is a useful pattern for extracting motivations, contradictions, hidden relationship dynamics, and other details before prose generation.

### V1 checked source-concept fidelity

The V1 generator included explicit rules that the source concept was authoritative. Later logic checked for obvious drift such as losing a supplied primary name or distinctive markers and could regenerate under stricter fidelity instructions.

V2's Phase 1 Default template restores the prompt-side fidelity rule. A reusable validator/retry path remains planned.

### V1 supported multi-pass generation

Public V1.0.13 included Full, Lite, and Compact Lite generation strategies. Lite modes divided generation into broad passes and carried earlier context forward.

Later V1 beta UI observed during the rewrite also exposed finer section progress/continuation behaviour. Exact recreation of that later beta is not assumed until its source is available or the behaviour is explicitly specified, but section-level progress/continuation remains a useful design direction.

## v0.12 — Generation Parity Phase 1

Phase 1 intentionally changes generation behaviour through the existing format-v2 Default template without changing project or template schemas.

### Concept fidelity

The Default template now tells generation that the user's concept is authoritative and explicitly asks the model to preserve supplied:

- names;
- relationships;
- premise and setting;
- visual details and clothing;
- props;
- requested dynamics;
- opening-scene beats.

The generator should expand and organise those details instead of replacing them with unrelated material.

### Description contract

`character.description` remains the normal interoperable Description field, but its generation instruction now asks for labelled content in this order:

```text
Age: ...
Appearance: ...
Outfit Style: ...
Distinguishing Features: ...
```

Appearance guidance covers visible face, hair, eyes, skin, body/build, and notable traits when supported by the concept.

Biography, motivations, internal personality, relationship history, and scenario events should not be dumped into Description unless a detail is directly visible and necessary to explain appearance.

### Personality contract

`character.personality` remains the normal interoperable Personality field, but generation now asks for:

```text
Core Traits: ...
Motivation: ...
Behavior Toward {{user}}: ...
Speech Style: ...
Strengths: ...
Flaws: ...
Likes: ...
Dislikes: ...
Habits / Mannerisms: ...
```

These are organised inside one standard Character Card field rather than creating nine incompatible top-level card properties.

### Scenario and opening continuity

Scenario now explicitly describes the current starting situation rather than a biography. It should establish context, why `{{char}}` and `{{user}}` are interacting, and the immediate hook.

First Message must begin in that same Scenario, preserve explicit opening material from the concept, include natural dialogue and a small amount of scene/action context, and avoid deciding `{{user}}`'s private thoughts or choices.

### Example Dialogue

The Default template now asks Example Dialogue to use exactly one `<START>` marker followed by one continuous 2-3 exchange `{{user}}` / `{{char}}` conversation.

### What Phase 1 does not claim

Phase 1 improves the contract sent to the existing full-character generation service. It does **not** yet add automatic semantic validation or repair.

A model can still return incomplete but valid JSON. The existing Generation Preview remains the user-facing review boundary.

## v0.13 — Generation Parity Core

The next parity milestone should make the behaviours above first-class engine features.

### Template model

Add a versioned generation-component/output-binding model capable of expressing:

- stable component ID;
- label;
- enabled state;
- required state;
- instruction/question;
- order;
- parent/output binding;
- type/format expectations where needed.

Older format-v2 templates must continue loading with sensible migration/defaults.

### Private Q&A

Add an optional planning stage that:

1. builds the enabled Q&A question list;
2. requests answers before final generation;
3. verifies all required questions were answered;
4. retries only missing questions;
5. canonicalises the final answer set;
6. adds the answers to generation context without exporting them as ordinary card content.

### Concept-fidelity validation

Add reusable fidelity diagnostics for concrete supplied details where checking is defensible, such as a supplied primary name or distinctive literal markers.

Clearly drifted output may be regenerated once under a stricter fidelity prompt before ordinary completeness repair begins.

This check should remain conservative: it must not punish legitimate paraphrasing or nameless concepts.

### Template completeness validation

After parsing a model response, validate the generated proposal against the active template contract.

Checks should include:

- required top-level generation fields;
- non-empty required values;
- required generation components within bound output fields;
- configured special formatting contracts;
- type constraints already represented by the template.

Diagnostics should identify exactly what is missing rather than only saying that the card is invalid.

### Targeted semantic repair

When validation fails, request only the affected field/section/component group.

The repair prompt should receive:

- source concept;
- private Q&A where enabled;
- relevant established project context;
- current generated value;
- exact missing requirements.

The model should return a complete replacement for the affected bound field so useful existing content can be preserved while missing material is filled.

Revalidate after repair before opening Generation Preview.

### Builder precedence

Builder guidance should become explicit generation context with clear precedence rules. User-entered builder values should not be treated as casual suggestions that a later full-card generation can ignore.

The exact policy should remain review-first and should avoid silently overwriting unrelated established character data.

### Progress and diagnostics

Longer generation should expose useful stages such as:

```text
Planning / Q&A
Generating
Checking concept fidelity
Validating template
Repairing missing content
Ready for review
```

This should integrate with the existing queue/cancellation architecture rather than blocking the UI.

## Later parity work

After the core validator/repair model is stable:

- add provider-aware streaming where worthwhile;
- add Full/Lite/Compact-Lite or equivalent multi-pass strategies for smaller context windows;
- consider section-by-section generation/continuation and progress;
- make greeting counts and similar output rules configurable template contracts;
- apply the same validator architecture to split-card and multi-character generation rather than creating separate one-off implementations;
- add Final AI Audit/card-rating workflows as quality tools distinct from generation-time completeness checking.

## Backwards compatibility

Generation Parity should not require users to rebuild existing projects.

- Project format 2 remains the source of truth until a real project-schema change requires a new version.
- Phase 1 keeps template format 2.
- When generation components/output bindings require a template-format bump, old templates should be migrated or interpreted with sensible defaults.
- Character Card V1/V2 import/export should continue using standard interoperable fields.
- CCF-only richer authoring data should remain namespaced/project data unless an external card format has a real corresponding field.
