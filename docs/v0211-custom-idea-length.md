# v0.21.1 Custom Idea Length Targets

## Purpose

Idea Generator already offers four data-driven depth presets: Quick, Standard,
Detailed and Extended. Custom adds an approximate text-character target when an author
wants a more specific amount of development per idea without changing those presets.

## Author workflow

1. Open Idea Generator and choose **Custom** from Detail.
2. Set **Target characters per idea** between 500 and 50,000.
3. Generate normally. The target applies to each result's concept body, not its title,
   character name, role, source anchor, roleplay hook, tags or JSON syntax.
4. Review the completion summary, which reports actual minimum, maximum and average
   concept lengths and how many results landed within the guide range.

The prompt gives the model a ±15% guide. This is deliberately advisory: coherence,
schema validity, the requested number of ideas and `{{user}}` agency remain more
important than padding or cutting prose to reach an exact number.

## Output budgeting

CCF estimates the output tokens needed from the character target, idea count, JSON
overhead and a safety margin. The effective request is always capped by the configured
Text model/profile maximum output. If that ceiling cannot accommodate the estimate, the
queued status says it is capped so the author can lower the target, generate fewer ideas
or use a model with a larger output limit.

This calculation changes only the current request. It does not rewrite the saved model
capability setting.

## Validation and diagnostics

An otherwise valid result is not rejected, repaired or discarded merely because its
concept misses the requested length. Generation metadata records the target, requested
and effective token budgets, whether the cap limited the request, actual per-result
character counts and the number within the guide range.

Character counts use Godot string length. They are useful author-facing measurements,
not estimates of any provider's proprietary tokenization.
