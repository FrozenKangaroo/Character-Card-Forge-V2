# v0.17.2 — Front Porch Character Extensions

v0.17.2 adds optional Front Porch 2.5 authoring to the Character Workspace. It restores the useful intent of the V1 integration without restoring its unsupported direct SQLite writer.

## Authoring surface

The Workspace has one top-level **Front Porch — Optional** tab. Its internal tabs keep Front Porch-specific data separate from normal Character Card fields:

- **Character Life** — ambitions, plan lines, occupation, work brief, hours/days, birthday, likes, dislikes, optional intimate preferences, wearing and carrying.
- **Opening State** — Realism default, bond/trust values, story day/date/time, emotion/intensity, cooldown, passage-of-time and Chaos defaults.
- **Needs Simulation** — per-character enablement, seven starting baselines, seven decay rates, low-hygiene preference and delta strength.
- **Advanced Front Porch** — verification/Director settings, starting task, stable/tier/avatar metadata, chat colours/font and TTS voice.

Every known field has an **Include** control. A field that is not included is not written merely because its editor displays a default value. A new card with no selected fields receives no `extensions.front_porch` object.

Optional intimate fields stay hidden until the author explicitly unlocks them for the current editing session. Hiding them again does not erase values imported from an existing card.

## Manual and AI workflows

All content-oriented groups support:

- manual editing;
- one-field **AI Suggest**;
- **Generate Section**;
- **Regenerate Selected**;
- **Clear Section**;
- whole-tab **Generate Enabled Front Porch Fields** and validation.

Generated values always enter the existing editable Generation Preview. The author selects, edits, applies or discards proposed fields there. No generation result writes canonical project/card data automatically.

The generation prompt treats the values as character-owned identity or new-conversation seeds. It forbids invented durable history, actions, feelings, consent or preferences for `{{user}}`. Stable IDs, avatar IDs, colours and provider-specific TTS identifiers remain manual-only.

## Alternative greeting seeds

The existing **Alternative Greetings** tab now includes one Front Porch Opening Seed editor per alternate greeting. Each seed is sparse:

- a disabled seed lets Front Porch read the room;
- an enabled empty seed inherits the card-level defaults;
- included fields override only those specific defaults.

Opening seeds cover emotion, intensity, bond/trust, story day/date/time, starting task, seven needs baselines and starting worn/carried items. Seed generation uses the same review-before-apply boundary as the main Front Porch tab.

## Interchange and compatibility

Front Porch data is stored at:

```text
Character Card V2 data.extensions.front_porch
└── version: "2.5"
    └── realism_engine
```

TTS voice remains the standard optional Character Card V2 `data.tts_voice` field rather than being placed inside `realism_engine`.

Imported Front Porch extension versions and unknown keys are retained. Editing known fields changes only those known paths. This includes unknown nested values, future top-level extension data, hidden intimate data and unknown per-greeting seed fields.

Dates use `YYYY-MM-DD`; Front Porch does not accept February 29 as a character birthday. Exact story time uses 24-hour `HH:MM`. Work days use `1` for Monday through `7` for Sunday. Colour overrides accept decimal ARGB, `#RRGGBB` or `#AARRGGBB` input and are exported as integers.

## Deliberate boundary

v0.17.2 authors and round-trips portable card data. It does not find, open or modify `front_porch.db` or any other Front Porch SQLite file.

Direct installation belongs to v0.17.3 and must use a supported Front Porch local API with explicit collision handling and a portable-card fallback. Existing Front Porch conversations and their evolving state are outside this version's write boundary.

## Regression coverage

`tools/test_v0172_front_porch_extensions.gd` verifies:

- empty optional state emits no Front Porch extension;
- the versioned catalog and live four-group Workspace surface;
- manual normalisation and validation;
- adult-data preservation while hidden;
- unknown future extension and greeting-seed round-tripping;
- TTS voice Character Card V2 import/export;
- scoped, agency-safe, review-first AI job metadata;
- the v0.17.2 application shell and generation service;
- the continuing no-SQLite boundary.
