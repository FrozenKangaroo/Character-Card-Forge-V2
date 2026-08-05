# v0.15.37-hotfix1 — Safe Section Field Identity & Contamination Guard

## Problem

A generated Character Card could be syntactically valid JSON while still being semantically corrupted because content from one requested section was accepted into another.

The reported Cherry & Jerry card exposed several forms of the same failure:

- the full Scenario was repeated inside unrelated Personality components such as Turn-ons, Turn-offs, Behavioural Tendencies, Protection and Favourite Position;
- the First Message was inserted into a history component;
- Lorebook-style numbered entries were inserted into Kinks;
- the resulting card passed normal JSON parsing and type-oriented validation because the contaminated values were still non-empty strings.

This was a Character Card Forge validation failure rather than an authoring error.

## Root cause

Safe Section Build previously protected JSON shape more strongly than semantic section identity.

For standalone fields, a one-key JSON object could be treated as the requested field even when the returned key was unrelated. For output groups, known component values were accepted largely on non-empty/type checks, so a correctly keyed component could still contain a long Scenario, First Message, Lorebook dump or duplicated sibling content.

Parallel Safe Section workers also instantiated the historical v0.15.26 worker class directly, so a versioned leaf guard would not automatically apply to concurrent child requests unless the child factory path was upgraded.

## Changes

### Exact field identity

Normal standalone Safe Section responses must now contain exactly the requested field ID. An unrelated one-key object is rejected and sent through the focused field-repair path.

The generic `value` response shape remains supported only inside an explicitly focused field/component repair request.

### Exact component identity

Output groups now accept configured component IDs rather than silently substituting component labels for IDs. Missing exact IDs are repaired through the existing narrow component-repair path.

### Cross-section contamination guard

Generated values are checked for several high-confidence contamination patterns:

- long exact/near-exact duplication between sibling components;
- long exact/near-exact duplication between assembled top-level fields;
- repeated long paragraphs inside one assembled field;
- a non-Lorebook target containing Lorebook-entry structure;
- a non-Scenario/First-Message target reproducing the corresponding authoritative Blueprint section;
- obvious Scenario/First Message structure routed into a different target.

The guard intentionally targets high-confidence structural reuse rather than attempting to judge ordinary thematic overlap or legitimate reuse of short facts.

### Final assembled fail-closed check

Sequential and parallel Safe Section builds run a final contamination check over the assembled candidate before handing it back to the established generation contract/fidelity pipeline. If routed/duplicated content is still present, generation fails with Diagnostics instead of emitting a malformed card.

### Parallel worker coverage

v0.15.37-hotfix1 overrides the v0.15.26 parallel worker creation path so concurrent Safe Section children use the hotfix service as well. Parallel generation remains enabled; the fix does not fall back to serial generation merely to obtain validation coverage.

### Diagnostics

Safe Section acceptance/rejection now records useful identity information including:

- requested field/component key;
- returned keys;
- acceptance route;
- rejection kind;
- content fingerprint for contaminated/repaired values.

This makes future exported Generation Diagnostics more useful when a provider returns valid JSON with the wrong semantic section.

## Regression coverage

`tools/test_v01537_hotfix1_safe_section_contamination.gd` uses a non-explicit synthetic version of the reported failure shape and checks:

- unrelated one-key standalone output is rejected;
- correctly keyed Scenario text is rejected from Turn-ons;
- Scenario duplication, First Message leakage and Lorebook structure are rejected inside a Personality group;
- component labels cannot substitute for requested component IDs;
- a clean correctly keyed Personality group remains valid;
- final assembled validation catches repeated/cross-routed content even if a section-level guard were bypassed;
- the real main scene installs the v0.15.37-hotfix1 Workspace and live generation service.

The broad manifest inherits v0.15.37, retaining Multi-source Collaborator/UserPersona coverage and all previous generation, persistence, Compare & Apply, Ideas, Vision, Image Studio and cross-feature gates.
