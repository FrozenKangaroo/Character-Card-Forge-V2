# Generation Parity Plan

Character Card Forge V2 is not intended to recreate the PyWebView implementation, but V1 remains an important behavioural reference for character-generation quality.

A source audit of the public V1.0.13 code showed that the old application did substantially more than send one broad prompt. This document records the behaviours worth carrying forward, what is already implemented in Godot, and what remains staged for later parity work.

## Goals

Generation Parity should:

- keep V2's modular Godot services, portable project model, and review-first workflow;
- port the useful generation behaviours that made V1 more reliable;
- avoid copying PyWebView-specific state/UI architecture;
- preserve Character Card interoperability;
- keep templates and generation contracts data-driven and migratable;
- distinguish authoring structure from the final interoperable card schema.

## Source-audited V1 behaviours

### Description and Personality had distinct responsibilities

V1's Description focused on visible appearance and external traits. Its structured guidance included age, appearance, and outfit style.

Personality focused on internal traits and roleplay behaviour, including motivation, behaviour toward `{{user}}`, and speech style.

Early V2 blurred these responsibilities by describing Description as appearance, background, role, habits, and important facts. v0.12 Generation Parity Phase 1 corrected that prompt/template problem.

### Structured authoring could fold into standard Character Card fields

V1's authoring/generation structure could be richer than the final Character Card schema. Multiple Description-oriented components could fold into Description, and multiple Personality-oriented components could fold into Personality.

The long-term V2 model therefore needs three related layers:

1. **Workspace fields** — persistent editable project information.
2. **Generation components** — structured expectations/questions used while producing content.
3. **Output bindings** — interoperable destinations such as Character Card Description or Personality.

These layers may overlap, but should not be forced to be identical.

### Enabled fields affected generation

In V1, disabling a configured subfield removed that expectation from generation. Enabled state was not merely visual hiding.

V2 already has `generate` and `required` on workspace fields. A later v0.13 slice will add an explicit enabled/required model for generation components rather than overloading workspace-field semantics.

### V1 validated generated content after the model answered

V1 did not treat syntactically valid output as automatically complete. It checked enabled sections/fields and special structural rules such as:

- requested alternative greeting count;
- exactly one `<START>` marker in Example Dialogues;
- non-empty tags;
- non-empty enabled ordinary sections.

When content was missing, V1 could request corrected content and validate again.

This behaviour is now beginning to exist as an engine feature in V2 v0.13.

### V1 had private pre-generation Q&A

When enabled, V1 first generated private planning answers for configured questions, checked for missing answers, retried missing questions, canonicalised the answer set, and fed it into final generation without exporting it as ordinary card content.

This remains planned for v0.13 after the semantic-validation foundation.

### V1 checked source-concept fidelity

V1 treated the user's source concept as authoritative and later logic could detect obvious drift such as losing a supplied primary name or distinctive literal markers.

V2 v0.12 restored the prompt-side fidelity rule. Conservative reusable fidelity diagnostics/retry remain planned for v0.13.

### V1 supported multi-pass generation

Public V1.0.13 included Full, Lite, and Compact Lite strategies. Lite modes divided generation into broad passes and carried earlier generated context forward.

A later V1 beta UI also showed finer section progress/continuation. Equivalent multi-pass and section-level workflows remain later parity work after the core contract/validator model is stable.

## v0.12 — Generation Parity Phase 1

Phase 1 changed generation behaviour through the existing format-v2 Default template without changing project or template schemas.

### Concept fidelity prompt rules

The Default template now says the source Generation Concept is authoritative and asks the model to preserve supplied names, relationships, premise/setting, visual details, clothing, props, requested dynamics, and opening-scene beats.

### Description contract

`character.description` remains the normal interoperable Description field, but the default generation instruction asks for:

```text
Age: ...
Appearance: ...
Outfit Style: ...
Distinguishing Features: ...
```

Biography, motivations, internal personality, relationship history, and scenario events should not be dumped into Description unless directly relevant to visible presentation.

### Personality contract

`character.personality` remains the normal interoperable Personality field, but the default generation instruction asks for:

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

These structured components remain inside the standard Personality field rather than becoming incompatible top-level card properties.

### Scenario, First Message, and Example Dialogue

Scenario describes the current starting situation rather than biography. First Message begins in that same situation and should preserve explicit opening material from the concept.

Example Dialogue asks for exactly one `<START>` marker followed by one continuous example conversation.

Phase 1 improved the requested contract but still relied on the model to obey it.

## v0.13 — Generation Parity Core

v0.13 begins turning those expectations into actual engine behaviour.

### Implemented: data-driven generation contracts

The built-in Default template now has a separate versioned contract file:

```text
data/generation_contracts/default.json
```

The current contract format is intentionally small and independent of project format 2 and template format 2.

It currently supports per-field rules such as:

```json
{
  "minimum_characters": 180,
  "required_labels": [
    "Age",
    "Appearance",
    "Outfit Style",
    "Distinguishing Features"
  ]
}
```

and marker rules such as:

```json
{
  "marker_rules": [
    {
      "marker": "<START>",
      "exact_count": 1
    }
  ]
}
```

Generic required top-level keys are not hard-coded into that file: they are derived from the active template's AI-generatable fields where `required` is true.

### Implemented: semantic completeness validation

`CCFGenerationContractService` validates a parsed full-character proposal after JSON syntax/shape handling.

The current checks include:

- required top-level generation keys are present and non-empty;
- configured minimum useful-content lengths;
- configured labelled components inside bound text fields;
- configured exact marker counts.

For the bundled Default template this currently means, among other things:

- Description should contain all four expected labelled visual components;
- Personality should contain all nine expected labelled personality components;
- First Message must not be trivially short;
- Example Dialogue, when returned, must contain exactly one `<START>`.

This is deliberately a completeness contract, not a subjective prose-quality grader.

### Implemented: targeted semantic repair

`CCFParityGenerationService` layers semantic validation onto the existing queued generation service without replacing the established JSON parsing/repair system.

A full-character run now follows this path:

```text
Generate character
        ↓
Parse / locally repair JSON as before
        ↓
Validate generation contract
        ↓
Complete? ── yes ──→ Generation Preview
        │
        no
        ↓
Targeted semantic repair request
        ↓
Parse response
        ↓
Validate contract again
        ↓
Generation Preview
```

The semantic repair request receives:

- the authoritative source concept;
- the complete current generated JSON;
- the exact detected missing/incomplete requirements;
- the generation contract;
- the original requested top-level keys.

It asks for the complete repaired object rather than a diff or loose missing fragments, and explicitly tells the model to preserve useful content that already satisfies the request.

Only one semantic repair pass is allowed in this initial implementation. This prevents a bad model/provider response from causing an uncontrolled repair loop or unexpected repeated API usage.

### Implemented: revalidation and diagnostics

The repaired result is checked again before it reaches Generation Preview.

Generation metadata records:

- the final generation-contract report;
- whether semantic repair was used;
- semantic repair attempt count;
- the report that triggered repair.

Generation Preview remains review-first: automatic repair does not write generated data directly into the character project.

### Implemented: queue integration

Repair uses the same asynchronous `HTTPRequest`, cancellation, retry, queue, and status architecture as existing generation.

While semantic repair is running, the active label changes to:

```text
Repairing incomplete character generation
```

The upgraded service remains the shared queue used by the workspace's existing AI tools. Semantic contract validation/repair currently activates only for full-character generation; Builder, Controlled Build, Vision/Attachments, relationships, group scenes, and card-workflow jobs retain their existing behaviour.

### Current custom-template behaviour

This first implementation intentionally avoids pretending the richer component/output-binding schema already exists.

For any template, required AI-generatable top-level fields receive generic presence/non-empty validation.

The richer nested Description/Personality/marker rules are currently bundled for the built-in Default template through its external contract file.

A later v0.13 slice will make these nested/component rules part of an editable template-generation model so user templates can define equivalent contracts cleanly.

## Remaining v0.13 work

### Generation components and output bindings

Add a versioned model capable of expressing:

- stable component ID;
- label;
- enabled state;
- required state;
- generation instruction/question;
- order;
- parent/output binding;
- type/format expectations.

This will allow, for example, many editable Personality components to fold into one interoperable Character Card Personality field.

Older format-v2 templates must continue loading with sensible migration/defaults.

### Private Q&A

Add an optional planning stage that:

1. builds enabled questions;
2. generates private answers before final card generation;
3. verifies all required questions were answered;
4. retries only missing questions;
5. canonicalises the final answer set;
6. adds the answers to generation context without exporting them as card content.

### Concept-fidelity validation

Add conservative checks for concrete supplied details where validation is defensible, such as a supplied primary name or distinctive literal marker.

Clearly drifted output may receive one stricter retry before ordinary completeness repair. The system should not punish legitimate paraphrasing or nameless concepts.

### Builder precedence

Explicit builder values should become high-priority generation context rather than casual suggestions that full generation may ignore.

The policy must remain review-first and must not silently rewrite unrelated established content.

### Richer progress and diagnostics

Longer generation should eventually expose stages such as:

```text
Planning / Q&A
Generating
Checking concept fidelity
Validating template
Repairing missing content
Ready for review
```

The current v0.13 slice already exposes the repair stage through the existing queue label; richer per-stage reporting is still planned.

Generation Preview should also surface the semantic contract report and repair history more clearly.

## Later parity work

After the core validator/component model is stable:

- add provider-aware streaming where worthwhile;
- add Full/Lite/Compact-Lite or equivalent multi-pass strategies for smaller context windows;
- consider section-by-section generation/continuation and progress;
- make greeting counts and similar output rules configurable contracts;
- apply the validator architecture to split-card and multi-character generation rather than creating separate one-off implementations;
- add Final AI Audit/card-rating workflows as quality tools distinct from generation-time completeness checking.

## Backwards compatibility

Generation Parity should not require existing projects to be rebuilt.

- Project format 2 remains authoritative until a real project-schema change requires a new version.
- Existing format-v2 templates continue loading.
- The initial Default semantic contract is a separate versioned data file rather than a forced template-schema bump.
- When generation components/output bindings do require a template-format change, older templates should migrate or receive sensible interpreted defaults.
- Character Card V1/V2 import/export continues using standard interoperable fields.
- Rich CCF authoring/generation structure should remain namespaced project/template data unless an external format has a real corresponding field.
