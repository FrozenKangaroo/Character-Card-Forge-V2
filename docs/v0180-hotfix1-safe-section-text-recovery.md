# v0.18.0-hotfix1 — Safe Section Text Recovery

## Why this hotfix exists

A captured Safe Section job received a successful HTTP response whose First Message was useful plain prose instead of the requested one-key JSON object. The existing parser discarded that prose and requested a generic JSON repair. The repair response was close to valid JSON but omitted the outer string's closing quote, so generation failed even though the original field content was usable.

The failure was a response-shape mismatch, not a network error, provider refusal or output-token limit. This hotfix makes the shape boundary more tolerant without weakening field validation.

## Local recovery boundary

CCF may locally wrap a response only when the target is unambiguous and text-valued:

- a standalone `line`, `multiline`, `string`, `text` or `textarea` Safe Section field;
- a focused repair for one of those text fields;
- a focused missing-component repair, which already names one text component.

The recoverable response shapes are:

- non-empty plain text;
- one valid JSON string;
- a complete Markdown code fence containing text.

Recovery supplies the already-known field key or focused `value` wrapper. It does not infer a target from the model's wording.

## Shapes that remain strict

CCF does not reinterpret plain text as:

- tags or another array;
- a number;
- a checkbox/boolean;
- a select value;
- an output group with multiple component keys;
- a malformed object or array.

Those responses continue through bounded JSON repair. The repair request now states the exact standalone field key and type, the focused `value` type, or the allowed output-group component keys.

## Validation is unchanged

Local transport recovery is not automatic content acceptance. The wrapped value follows the same processing path as a correctly shaped response, including:

- field-required and type/content checks;
- template and Safe Section semantic rules;
- `{{user}}` agency safeguards;
- reserved-source and cross-section contamination detection;
- exact requested-key handling and ordinary preview/apply boundaries.

Diagnostics record the recovery source, character count and a content fingerprint without duplicating the generated field text into the recovery record.

## Conservative malformed-string repair

The existing local JSON cleanup now recognizes one additional narrow case: a root object or array is structurally balanced except that its current string lacks an outer closing quote. CCF inserts or appends the missing quote and required root closers only when the result parses as valid JSON. Other malformed JSON remains on the normal bounded repair path.

## Concurrent generation

The workspace's main generation worker and every parallel Safe Section child use the same recovery-aware service. This avoids a split where sequential generation succeeds but concurrent section generation retains the older parser behavior.

## Regression coverage

The focused regression reproduces the captured First Message failure class and checks:

- plain prose, JSON-string and fenced-text recovery;
- strict handling for tags, booleans, numbers and selects;
- strict handling of malformed object-shaped output;
- the missing outer-string quote repair;
- passage through exact-key acceptance and contamination guards;
- exact remote repair instructions and diagnostics;
- live workspace service wiring.
