# v0.17.4 — Front Porch Multi-Character Group Cards

Character Card Forge v0.17.4 adds portable import, authoring, validation and export for Front Porch's custom multi-character PNG format.

## Supported format

CCF reads and writes a PNG `tEXt` chunk named `fpa_group`. Its value is base64-encoded UTF-8 JSON using:

```json
{
  "spec": "front_porch_group_card",
  "spec_version": "1.0"
}
```

The visible image is an automatically generated collage of the selected members. Each `raw_member_data` entry also contains a complete base64 PNG avatar with ordinary Character Card V2 `chara` metadata. Front Porch can therefore recover both the group and its individual member cards from one file.

## Authoring

Create or open a **Group-card plan** in Card Workflow Studio. The Front Porch section appears only for that mode and supports:

- round-robin or random turn order;
- automatic advancement and Director mode;
- group scenario and first message from the normal workflow fields;
- group and per-character system prompts;
- group lorebook JSON and world ID/name references;
- character-lorebook inheritance;
- chaos and adult-chaos switches;
- baseline and full per-member realism JSON;
- member objectives keyed by stable character ID;
- optional extension data for forward compatibility.

All fields are editable. **Generate Group Writing** can draft the group system prompt, per-character prompts, lorebook and member objectives through the configured Text profile. Its result remains in the editor until the workflow is explicitly saved. **Restore Neutral Realism** rebuilds Front Porch-compatible defaults for the currently selected members.

## Export

Open **Import / Export → Front Porch Groups**, select a saved Group-card plan and review its validation summary before exporting.

Export uses CCF character UUIDs as the portable group member keys. When a member originated in Front Porch, its original source identity is retained separately as remapping provenance. Current CCF card fields replace their known imported counterparts while unknown raw member and group fields survive round-tripping.

If a member has no portrait, CCF embeds a deterministic placeholder PNG carrying the complete `chara` payload. This keeps the group portable and prevents an otherwise valid text-only character from disappearing during group import.

## Import and identity remapping

Import creates a new multi-character CCF project and one saved Group-card workflow. It never merges over the active project.

Fresh CCF UUIDs are assigned to imported members. CCF remaps all known member-keyed content, including per-character prompts, objectives, baseline realism, default realism, nested relationship keys and extension values. Imported avatar PNGs are copied into each new character's managed asset folder and assigned as portraits.

Unknown future group fields and raw member fields are retained for a later export. This is a forward-compatibility promise, not a claim that CCF can edit the meaning of unknown fields.

## Safety boundary

Group interchange is file-based. CCF does not open or modify Front Porch's SQLite database and does not mutate live conversations. The existing direct character-install API remains separate. Direct group installation will be considered only after Front Porch exposes a verified supported group-import API.

## Regression coverage

The focused v0.17.4 regression verifies the exact spec and metadata key, complete embedded member PNGs, export/load round-trip, unknown-field preservation, fresh-ID remapping, managed portrait recovery, duplicate-ID rejection, AI prompt constraints, active UI wiring and retention of the v0.17.3-hotfix1 OpenRouter behavior.
