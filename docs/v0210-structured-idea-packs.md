# v0.21.0 — Structured Idea Packs

Character Card Forge v0.21.0 adds a versioned interchange format for reusable Series,
scenario/card Seeds, character notes and future Idea Generator material. The primary
extension is `.ccfideas.json`, but validation relies on the JSON content rather than the
filename.

## Format

Schema version 1 requires:

- `format: "character-card-forge-ideas"`;
- `schema_version: 1`;
- a `pack` metadata object; and
- an `entries` array whose entries have `id`, `kind` and `title`.

The initial known kinds are `series`, `seed` and `character_note`. Unknown kinds warn
and retain their data. Optional semantic fields default to empty values. Arbitrary
`sections` retain concept-specific labelled material without requiring another schema
revision. Unknown entry keys are preserved and reported as forward-compatibility
warnings.

An import-ready example is available at
[`examples/idea-packs/japan-by-rail-roommates.ccfideas.json`](../examples/idea-packs/japan-by-rail-roommates.ccfideas.json).

## Existing Idea Notebook mapping

Idea Packs do not create a second idea database. Each imported entry becomes an ordinary
Idea Notebook JSON record with additive fields:

- `structured_idea` retains the complete pack metadata and semantic entry;
- `source.idea_pack` retains pack ID/title, source Bible/version, original entry ID,
  schema version and import time; and
- `concept` contains a deterministic readable rendering used by the existing Idea
  Generator handoff.

Existing readers preserve the added dictionaries because the format-1 normalizer copies
unknown fields. Existing ordinary ideas need no migration and remain editable.

## Import workflow

1. Open **Idea Generator → Idea Notebook** and choose **Import Idea Pack…**.
2. Select `.ccfideas.json` or another JSON file.
3. Review pack metadata, Series/Seed/other counts, fatal errors, warnings and conflicts.
4. Inspect individual semantic entries, select the desired entries and choose a target
   notebook.
5. Resolve stable-ID conflicts with **Skip existing**, **Replace/update existing** or
   **Keep both as copy**.
6. Confirm **Import Selected**.

Parsing and preview never modify Idea Notebook. Selected records are fully staged and
JSON-verified before their exact files are replaced. A failed batch commit restores the
previous files. Newer unsupported schema versions are available for read-only preview
but cannot be imported silently.

## Duplicate behavior

The imported entry `id` is the stable source identity. CCF retains a separate local Idea
Notebook ID, enabling a deliberate Keep-both copy without losing provenance. Re-importing
the same ID defaults to Skip. Replace keeps the local record identity and creation time
while refreshing semantic content and import metadata. Duplicate IDs inside one pack
default to unselected Skip. Matching titles with different IDs produce only a warning.

## Generator use

Choosing **Use as Main Concept** for an imported entry supplies its structured premise,
setup, character engine, ground truth, hidden motive, variables, generation rules,
guardrails, notes and arbitrary sections as labelled generator context. The original
entry remains intact for export.

## Export workflow

Choose **Export Idea Pack…** from Idea Notebook. Selection scopes include all ideas, the
current selected idea, one Bible and one Series, followed by per-entry selection. Pack
title, ID, description and source version remain editable before choosing the file.

Imported structured entries retain semantic and unknown fields. Ordinary saved ideas map
to Seed entries with their concept as `summary`. `{{user}}`, `{{char}}`, Unicode text and
arbitrary sections round-trip unchanged.

## Validation coverage

The v0.21.0 regressions cover valid and malformed JSON, format identity, required and
optional fields, arbitrary sections, duplicate IDs, all conflict actions, Unicode,
template tokens, unknown fields, newer schemas, repeated import, round-trip export and
the live Idea Notebook UI wiring.
