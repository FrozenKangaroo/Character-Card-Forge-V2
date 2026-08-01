# Character Card Forge `.ccfchar` Format

## Purpose

`.ccfchar` is Character Card Forge's **single-character authoring interchange format**. It is intended for external tools, scripts, other character creators, and AI assistants that want to hand a partially or fully authored character to Character Card Forge.

It is **not** a replacement for Character Card V2 JSON/PNG export and it is **not** a complete `.ccfproject` package.

A `.ccfchar` source can contain as little as the Generation Concept or as much as every supported Overview, Character, Advanced, generation, alternative-greeting, and character-lorebook field.

## Core import rule

**Missing property = do nothing.**

If a property is absent, Character Card Forge leaves the existing workspace value unchanged. If a property is present with an empty value, that empty value is intentional and can clear the selected workspace field when applied.

The importer always shows a review list of supplied fields before applying them. Every supplied field is individually selectable.

## Header

Every file is UTF-8 JSON and begins with:

```json
{
  "format": "character_card_forge_character_source",
  "format_version": 1
}
```

The recommended file extension is `.ccfchar`.

## Recognised top-level objects

| Object | Purpose |
| --- | --- |
| `metadata` | Overview/library and creator metadata |
| `concept` | Generation Concept and private concept notes |
| `character` | Character Card workspace fields |
| `generation` | Workspace template, generation mode and style |
| `lorebook` | Character lorebook / Character Book data |

Unknown top-level objects are ignored and reported in the import preview. Unknown nested fields are ignored in format version 1.

## Overview and metadata fields

```json
"metadata": {
  "name": "Mika",
  "summary": "A racing-obsessed university student who pulls {{user}} into her hobby.",
  "tags": ["racing", "university", "romance"],
  "role": "{{user}}'s classmate",
  "creator": "Example Author",
  "character_version": "1.0",
  "favorite": false
}
```

Supported paths:

- `metadata.name`
- `metadata.summary`
- `metadata.tags` — array of strings
- `metadata.role`
- `metadata.creator`
- `metadata.character_version`
- `metadata.favorite` — boolean

## Generation Concept

A concept-only `.ccfchar` is completely valid:

```json
{
  "format": "character_card_forge_character_source",
  "format_version": 1,
  "concept": {
    "prompt": "A racer girl who drags {{user}} to the track after class. She has karting experience and a racing simulator at home."
  }
}
```

Supported paths:

- `concept.prompt` — Generation Concept
- `concept.notes` — private author notes

After importing a concept-only file, use Character Card Forge's normal generation workflow to create the remaining fields.

## Character fields

```json
"character": {
  "name": "Mika",
  "description": "...",
  "personality": "...",
  "scenario": "...",
  "first_message": "...",
  "example_dialogue": "...",
  "creator_notes": "...",
  "system_prompt": "...",
  "post_history_instructions": "...",
  "alternate_greetings": [
    "Hey {{user}}, hurry up! We're going to the track.",
    "Don't tell me you've never driven a kart before, {{user}}."
  ],
  "card_extensions": {}
}
```

These map directly to the normal Overview, Character and Advanced workspace data model. `alternate_greetings` must be an array of strings.

## Generation mode, style and template

```json
"generation": {
  "template_id": "default",
  "mode": "full",
  "style": "anime romantic comedy"
}
```

All three are optional. They are imported into the character's generation authoring state. A supplied `template_id` causes the workspace to reload that template after import.

External generators should use values meaningful to the target Character Card Forge installation. Omitting these fields is safer than inventing unsupported values.

## Character lorebook

`lorebook` maps to the active character's interoperable Character Book data (`character.character_book`). It can contain the full Character Card-compatible lorebook object used by Character Card Forge.

Example:

```json
"lorebook": {
  "name": "Mika Lore",
  "entries": [
    {
      "keys": ["karting", "race track"],
      "content": "Mika competed in amateur karting events before university.",
      "enabled": true,
      "constant": false,
      "priority": 100
    }
  ]
}
```

Character Card Forge's Lorebook Manager can be used after import to inspect or edit the entries.

## Complete example

```json
{
  "format": "character_card_forge_character_source",
  "format_version": 1,
  "metadata": {
    "name": "Mika",
    "summary": "A competitive racing fan and {{user}}'s classmate.",
    "tags": ["racing", "university", "competitive"],
    "creator": "Example Author",
    "character_version": "1.0"
  },
  "concept": {
    "prompt": "Mika is {{user}}'s classmate and an obsessive racing fan who decides after class to drag {{user}} to a local track.",
    "notes": "Keep the atmosphere energetic and playful."
  },
  "character": {
    "name": "Mika",
    "description": "A young woman with ...",
    "personality": "Energetic, competitive and excitable about motorsport...",
    "scenario": "After class, Mika intercepts {{user}} and insists on taking {{user}} to the track...",
    "first_message": "Mika grabs {{user}} by the sleeve...",
    "alternate_greetings": [
      "Mika leans across {{user}}'s desk. 'You're free after class, right?'"
    ],
    "example_dialogue": "<START>\n{{user}}: ...\n{{char}}: ...",
    "creator_notes": "",
    "system_prompt": "",
    "post_history_instructions": ""
  },
  "generation": {
    "template_id": "default",
    "mode": "full",
    "style": "anime romantic comedy"
  },
  "lorebook": {
    "name": "Mika Lore",
    "entries": []
  }
}
```

## Guidance for AI-generated `.ccfchar` files

When asking an AI to produce this format, a useful instruction is:

> Create a Character Card Forge `.ccfchar` JSON document using `format: character_card_forge_character_source` and `format_version: 1`. Populate only fields supported by the supplied character information. Do not invent filler merely to make every field present. Keep `{{user}}` and `{{char}}` placeholders literal where appropriate. Omit fields that should be left for Character Card Forge to generate later. Return JSON only.

A model may therefore return only `concept.prompt`, a handful of completed character fields, or a nearly complete character. Character Card Forge treats all three cases as valid authoring sources.

## Difference from other CCF formats

- `.ccfchar` — partial or complete authoring source for one character; designed for importing into a workspace.
- `.ccfproject` — complete portable Character Card Forge project package, including multi-character/project data and assets.
- Character Card `.json` / `.png` — fully materialised runtime/export card intended for SillyTavern and other compatible software.
