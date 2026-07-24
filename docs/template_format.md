# Character Card Forge Template Format

Current format version: **2**

User templates are stored as JSON under `user://character_card_forge/templates/`. The built-in Default template is shipped in `res://data/templates/default.json` and is read-only at runtime.

## Top-level structure

```json
{
  "format_version": 2,
  "template_id": "example_template",
  "name": "Example Template",
  "description": "A custom character format.",
  "global_generation_instructions": [
    "Keep all fields internally consistent."
  ],
  "output_policy": {
    "mode": "strict",
    "unexpected_fields": "ignore"
  },
  "sections": []
}
```

`output_policy.mode` is either `strict` or `flexible`.

`output_policy.unexpected_fields` is either `ignore` or `store`. Stored extra generation fields are placed below `character.custom.generated_extra` after review in Generation Preview.

## Sections

```json
{
  "id": "identity",
  "title": "Identity",
  "description": "Core identity fields.",
  "kind": "standard",
  "fields": []
}
```

`kind` may be `standard` or `interview`. Interview sections use the same data model but are intended for question-led fields and guided-generation workflows.

## Fields

Common properties:

```json
{
  "id": "occupation",
  "label": "Occupation",
  "type": "line",
  "path": "character.custom.occupation",
  "placeholder": "What does the character do?",
  "generate": true,
  "required": false,
  "generation_prompt": "Give the character a specific occupation that creates roleplay hooks."
}
```

Supported field types:

- `line`
- `multiline`
- `tags`
- `number`
- `checkbox`
- `select`

Multiline fields may add `height`.

Number fields may add `minimum`, `maximum`, and `step`.

Select fields use an `options` array.

Field IDs must be unique across the whole template because they are used as AI response keys. Project paths must also be unique within a template.

## Project paths

A field path is a dot-separated path inside the character project JSON. Existing paths such as `character.name` or `metadata.tags` may be reused.

Custom fields should normally use paths such as:

```text
character.custom.occupation
character.custom.world.faction
```

The project loader preserves custom project data even when a different template is currently active.

## Migration

Format-v1 templates are normalised to format version 2 when loaded or imported. New properties receive sensible defaults. The original imported file is not modified until the template is saved through the Template Manager.
