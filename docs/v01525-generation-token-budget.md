# v0.15.25 — Character Generation Token Budget Invariant

## Problem

Generation Diagnostics exposed a private Interview / Q&A failure where Character Card Forge sent `max_tokens: 2600` even though the active Text provider profile allowed a much larger output. The provider returned exactly 2,600 completion tokens with `finish_reason: length`, leaving the JSON truncated. The automatic JSON-repair request inherited the same 2,600-token ceiling and was truncated again.

The 2,600-token limit was not a provider restriction. It was a historical Character Card Forge stage cap.

## Historical regression

The original v0.13.1 private Interview implementation used:

```gdscript
payload["max_tokens"] = mini(int(payload.get("max_tokens", 6000)), 2600)
```

v0.14.0-hotfix1 had already corrected that behaviour by preserving the resolved Text-role output budget. A later generation-service inheritance restoration started from the v0.13.5 parity service and bypassed that hotfix, allowing the old limit to return in the live v0.15 generation chain.

## v0.15.25 invariant

For Character generation, the Text provider/profile output allowance present on the initial queued Character request is now captured as the authoritative maximum output budget.

Before **every** Character sub-request is sent, the live v0.15.25 service restores that same budget onto the payload. This covers:

- private Interview / Q&A planning;
- targeted missing Interview answers;
- Safe Section Output Groups;
- Safe standalone fields;
- focused missing-component repair;
- focused field repair;
- JSON repair;
- semantic/template repair;
- concept-fidelity correction;
- Fast Full Card generation.

Character Card Forge may change a stage's prompt or temperature, but it must not silently introduce a smaller stage-specific `max_tokens` ceiling. A deliberately smaller Maximum Output Tokens value selected by the author remains authoritative and is preserved exactly.

## Diagnostics

Generation Diagnostics now records the Character token-budget invariant and extracts common provider termination information, including:

- request `max_tokens`;
- configured Character Text maximum output allowance;
- `finish_reason`;
- Responses-style incomplete reason where supplied;
- provider-reported input, output and total token counts;
- whether the provider terminated because the output limit was reached.

When the provider reports a length/output-limit termination, the Diagnostics Overview prominently shows **OUTPUT LIMIT REACHED** instead of requiring the author to find the reason inside the raw response envelope.

## Regression coverage

`tools/test_v01525_generation_token_budget.gd` deliberately:

1. creates a 39-question private Interview with a 32,768-token Character output budget and verifies the Interview receives 32,768 rather than 2,600;
2. verifies a deliberately configured 1,800-token allowance remains 1,800;
3. simulates a later stage replacing `max_tokens` with 2,600 and verifies the final request-time invariant restores 32,768;
4. verifies `finish_reason: length` and provider token usage are exposed as an output-limit termination;
5. instantiates the real `scenes/main.tscn` and verifies the live Workspace uses `CCFGenerationServiceV01525` while retaining Safe Section Build and Generation Diagnostics.

The v0.15.25 regression is also added to the composable broad release-regression registry.
