# Concept Fidelity — v0.13.4

Character Card Forge treats the Generation Concept as the highest-authority source for explicit character facts. v0.13.4 adds a conservative fidelity layer after template semantic validation and before Generation Preview.

## Why this exists

A model can return structurally valid JSON and still drift from an explicit concept fact. Examples include changing a supplied character name, changing a numeric age, or dropping a distinctive literal physical measurement.

The fidelity layer is deliberately narrower than a general AI critic. Creative expansion, paraphrasing, prose tone, and harmless wording differences should not cause automatic regeneration.

## Current critical markers

The first fidelity format recognises a small set of high-confidence markers:

- a non-placeholder character name already supplied in the workspace;
- explicit numeric age forms such as `23 years old`, `23-year-old`, `Age: 23`, `23yo`, and `23 y/o`;
- explicit cup-size literals such as `G cup`, `G-cup`, and equivalent compact formatting.

Equivalent rendering is accepted where practical. For example, an explicit age of `23` also accepts `twenty-three` / `twenty three` in generated text.

Quoted or backticked literals are collected as advisory diagnostics. Their absence does not currently trigger automatic correction because a quoted phrase may be example dialogue or wording that can be safely paraphrased.

## Pipeline order

The full-character path is:

1. private Interview / Q&A planning;
2. full character generation;
3. template semantic validation;
4. bounded semantic repair when required;
5. conservative concept-fidelity check;
6. at most one concept-fidelity correction pass for clear critical drift;
7. template validation again if the correction response is structurally incomplete;
8. Generation Preview.

Template structure therefore remains authoritative. Concept fidelity never bypasses required Description/Personality components, marker rules, or output bindings.

## Fidelity correction

When clear drift is detected, the correction request receives:

- the authoritative source concept;
- the current structurally valid generated JSON;
- only the high-confidence fidelity issues that triggered correction;
- the active template generation contract;
- planning-precedence context from manual Interview / Q&A, Builder guidance, and AI interview notes;
- the active Mode & Style guidance.

The correction request is told to preserve good material and change only the explicit drift. It returns a complete JSON object, not a diff.

Only one fidelity correction is allowed. If a critical marker still appears missing afterward, the final metadata records `remaining_clear_drift` rather than starting an endless retry loop. Generation Preview remains the human review boundary.

## Diagnostics

Full-character completion metadata includes a compact `concept_fidelity` report with:

- anchor count;
- missing marker count;
- critical versus advisory missing counts;
- whether clear drift was detected;
- whether the single correction pass was used;
- remaining drift status;
- issue summaries.

A later v0.13 UI slice will surface these diagnostics directly inside Generation Preview alongside interview, precedence, Mode & Style, semantic-repair, and template-contract information.

## Intentional limits

v0.13.4 does not attempt to decide whether every semantic detail in a free-form concept has been preserved. Broad semantic judging can create false positives and cause good characters to be unnecessarily rewritten.

Future versions may add more configurable high-confidence marker types or carefully scoped semantic checks when runtime evidence shows they are useful.