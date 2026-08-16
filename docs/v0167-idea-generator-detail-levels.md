# v0.16.7 — Idea Generator Detail Levels

v0.16.7 adds a data-driven detail control to the existing AI Ideas workflow without replacing the Idea Generator, Idea Notebook, Structured Builder, or Character Collaborator handoffs.

## Author-facing levels

The Idea Generator now exposes four ordered levels:

- **Quick** — concise concepts centred on the defining premise and strongest hook.
- **Standard** — the default balanced level for normal ideation.
- **Detailed** — richer motivation, background, tensions, setting integration, relationships and hooks.
- **Extended** — the most expansive coherent treatment, with additional history, contradictions, behavioural detail and roleplay/story hooks.

The selected level is retained for the lifetime of the current workspace/Idea Generator session. Reopening the Idea Generator does not silently reset the selection. A newly constructed workspace starts at Standard.

## Data-driven catalog

The level definitions live in `data/idea_generator_detail_levels_v0167.json` and use format version 1. Each record contains an ID, author-facing label and description, a prompt instruction, and an output-budget multiplier hint.

`CCFIdeaGeneratorDetailLevelServiceV0167` is the single normalization/loading layer. Unknown IDs fall back to Standard, so future saved or externally supplied values fail safely rather than selecting an arbitrary mode.

## Generation integration

`CCFGenerationServiceV0167` extends the existing v0.15.33 user-agency-safe generation service. The workspace queues AI Ideas through `queue_idea_generation_with_detail_v0167()` and the service decorates the real queued job rather than constructing a separate parallel generator.

The selected level:

1. adds an explicit detail block to the queued system prompt;
2. scales the existing provider `max_tokens` output budget from its configured base value;
3. records the normalized level, label, multiplier and resulting max-token budget in job metadata.

The multiplier is a hint applied to the profile's existing output budget, not a hardcoded provider model limit. Quick therefore spends a smaller output allowance than Standard, while Detailed and Extended can ask for progressively richer responses.

## User-agency compatibility

The previous Idea Generator agency contract remains authoritative. Detail-level instructions explicitly state that increasing detail must not:

- choose or invent `{{user}}` actions, reactions, feelings, dialogue, consent or decisions;
- invent unnecessary `{{user}}` backstory;
- weaken the existing source-premise and conditional-choice rules.

The existing semantic validation/repair layer is inherited unchanged.

## UI architecture

The visible AI Ideas controls still come from the established legacy controller embedded in the modern Idea Generator shell. v0.16.7 installs the Detail selector beside the existing idea-count control at the workspace boundary, so its callback remains the real generation callback. Idea Notebook and Collaborator source handoffs remain unchanged.

## Regression coverage

`tools/test_v0167_idea_generator_detail_levels.gd` verifies:

- catalog validity and exact Quick → Standard → Detailed → Extended order;
- Standard default and invalid-ID fallback;
- monotonic output-budget hints;
- prompt decoration and provider budget scaling;
- preservation of the prior user-agency metadata and `{{user}}` safeguards;
- the live v0.16.7 workspace and four-option selector;
- session selection persistence;
- predecessor user-agency semantic validation.

The dedicated GitHub Actions workflow uses Godot 4.7.1, applies the project warning gate, runs the focused regression, rechecks v0.16.6 and v0.16.5, confirms Forward+ defaults, and runs the inherited quick cross-feature regression profile.
