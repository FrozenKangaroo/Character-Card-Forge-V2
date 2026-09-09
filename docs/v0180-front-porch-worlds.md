# v0.18.0 — Front Porch Worlds and The Stoop Preparation

Character Card Forge v0.18.0 adds a project-level **Front Porch Worlds** tab to Import / Export. It creates, imports, edits and exports portable `.fpworld` files without opening the Front Porch database or changing conversations.

## Portable format

The implementation follows Front Porch's current version-1 JSON envelope:

```json
{
  "formatVersion": 1,
  "id": "stable-world-id",
  "name": "World name",
  "description": "World description",
  "cover": "data:image/jpeg;base64,...",
  "lorebook": {"entries": []},
  "lorebooks": [{"entries": []}],
  "climate_enabled": true,
  "biome": {},
  "place_traits": {},
  "meta": {
    "author": "Creator",
    "createdAt": "2026-09-09T00:00:00Z",
    "appVersion": "Character Card Forge 0.18.0",
    "sourceId": "stable-update-id"
  }
}
```

The single `lorebook` and `lorebooks` forms are both supported. Bare lorebook JSON can also be imported and is retained as a format-version-0 compatibility record.

## Lossless editing contract

CCF stores the complete imported JSON envelope in the project. Visible edits are merged into that envelope rather than rebuilding it from a fixed schema. Unknown top-level keys, metadata, biome values, place traits, additional lorebooks and unknown lore-entry fields therefore survive import, project save and later export.

The editor deliberately focuses on the primary lorebook. Additional imported lorebooks remain unchanged. Selecting **Preserve imported/custom biome** keeps an unrecognised biome object intact; choosing a built-in biome is an explicit replacement.

## World authoring

Each world can be created or completed manually with:

- name and description;
- an embedded cover image, resized to at most 1024 pixels on its longest edge and compressed toward Front Porch's 350 KiB portable-cover guideline;
- optional climate simulation and a data-driven built-in biome;
- atmosphere and gravity place traits while preserving other imported traits;
- primary lorebook entries with name, keys, content, enabled state and always-active state.

Worlds are saved at project level under `front_porch_worlds`, so one CCF character project can prepare several reusable settings.

## Stoop preparation

CCF stores optional submission preparation beside the portable envelope:

- publishing summary;
- creator and original creator;
- tags;
- adult-content declaration;
- comments preference;
- stable update identity.

Creator and stable identity map into portable `meta.author` and `meta.sourceId`. The other submission-only values remain in the CCF project because they are Stoop request fields rather than `.fpworld` envelope fields.

Readiness checks identify missing summary, cover or stable identity. A world may still be exported locally when those Stoop-only requirements are incomplete.

## Required review and safety boundary

Before every `.fpworld` export, the author must confirm that lore and descriptions were reviewed for private project context. When the world is declared adult, a second confirmation verifies that declaration. Only then does the destination picker open.

v0.18.0 makes no Stoop or Front Porch network request. It does not store Stoop credentials, publish content, write a Front Porch database or mutate live conversations. Direct Stoop publishing remains a later capability that must use a verified authenticated Front Porch contract and preserve the same review boundary.

## Compatibility sources

The envelope and cover behavior are aligned with Front Porch Rawhide's `fp_world_package.dart`. Stoop preparation follows its current moderated `WORLD` submission surface and keeps portable `.fpworld` exchange as the independent baseline.
