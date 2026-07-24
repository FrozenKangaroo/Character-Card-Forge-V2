# Character Card Forge Series Format

## Purpose

A series definition is a reusable project-external bible shared by any number of Character Card Forge projects. Projects store only a stable `metadata.series_id` reference; the detailed continuity and generation guidance remains in one standalone series JSON file.

Series files are stored under:

```text
user://character_card_forge/series/<series_id>.json
```

The current series format version is **1**.

## Example

```json
{
  "format_version": 1,
  "series_id": "89fb259f-a395-4fc8-a4bb-80876f25ba89",
  "created_at": "2026-07-24T09:00:00Z",
  "updated_at": "2026-07-24T09:15:00Z",
  "name": "Astral Courier Guild",
  "aliases": ["ACG", "Astral Couriers"],
  "description": "A science-fantasy setting about couriers crossing unstable star roads.",
  "categories": ["Original", "Science Fantasy"],
  "setting_guidance": "Interstellar travel uses ritualised gates maintained by guild navigators.",
  "canon_notes": "The Obsidian Route has been closed for twelve years.",
  "visual_direction": "Practical courier uniforms, luminous route maps, worn brass instruments.",
  "generation_rules": "Do not introduce ordinary faster-than-light engines. Keep guild ranks internally consistent.",
  "default_tags": ["science fantasy", "courier", "space travel"],
  "matching_keywords": ["star road", "routekeeper", "astral courier"]
}
```

## Fields

| Field | Type | Meaning |
| --- | --- | --- |
| `format_version` | integer | Version of this standalone series schema. |
| `series_id` | string | Stable UUID-style identifier referenced by projects. |
| `created_at` | string | Creation timestamp. |
| `updated_at` | string | Last-save timestamp. |
| `name` | string | Primary display name. |
| `aliases` | array of strings | Alternate names useful for display and matching. |
| `description` | string | High-level summary of the series or setting. |
| `categories` | array of strings | Organisational categories, genres, franchises, or continuities. |
| `setting_guidance` | string | World rules, locations, institutions, technology, magic, and other setting guidance. |
| `canon_notes` | string | Facts that generated characters and scenes should preserve. |
| `visual_direction` | string | Shared visual design language for later image and character work. |
| `generation_rules` | string | Explicit reusable constraints supplied to AI generation tools. |
| `default_tags` | array of strings | Optional tags that can be copied into assigned project metadata. |
| `matching_keywords` | array of strings | Distinctive local matching terms used by Auto Series. |

Unknown properties are retained when the file is normalised and saved, allowing future additive extensions.

## Project reference

A project assignment is stored inside its ordinary `character.json`:

```json
{
  "metadata": {
    "series_id": "89fb259f-a395-4fc8-a4bb-80876f25ba89"
  }
}
```

An empty string means unassigned. A non-empty ID whose local file is missing remains a valid recoverable reference; CCF displays it as missing rather than erasing it.

## Compatibility rules

- Adding a series assignment does not change project format version 2.
- New optional series fields should receive sensible defaults during normalisation.
- Future incompatible schema changes must increment `format_version`.
- Series data is not copied into every project, preventing stale duplicated bibles.
- Character Card V2 exports preserve only the CCF series reference in the namespaced CCF extension. The series definition itself belongs in a `.ccfproject` or `.ccfseries` package when portability is required.
