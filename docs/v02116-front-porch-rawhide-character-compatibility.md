# v0.21.16 Front Porch Rawhide Character Compatibility

This compatibility pass was audited against Front Porch Rawhide commit
`2876ee5d8e92290d2f4498bf0f459652010aa735` (2026-10-30). It extends CCF's existing
optional Front Porch editor and portable interchange; it does not add a second editor or
write to Front Porch's database.

## Current character fields

| Rawhide property | CCF control | Portable behaviour |
| --- | --- | --- |
| `pockets_enabled` | Pockets & Wardrobe enabled | Absent means enabled; explicit `false` disables it. Canonical enabled/default is omitted. |
| `needs_sim_enabled` | Needs Simulation default | Nullable/absent remains distinct from explicit `false`. |
| `needs_pace` | Sloth / Normal / Fast | Stored as `sloth`, `normal` or `fast`; Rawhide defaults to `normal`. |
| `needs_off` | Seven independent Disable toggles | Canonical keys are hunger, bladder, energy, social, fun, hygiene and comfort. Empty is omitted. |
| `sex` | Male / Female / Other | Adult-gated and omitted unless explicitly included. |
| `recovery` | Recovery mode, duration choice, minutes and PCD | Modes are `auto`, `hard`, `soft`. Hard duration can be **Personality decides** (no `minutes` property) or **Fixed duration** (0–180, including an explicit zero). PCD is independently `off`, `rare`, `sometimes`. The default auto/off profile is omitted. |

Current Rawhide explicitly ignores the former `needs_sim_strength` and all
`needs_decay_*` properties. CCF keeps those properties visible and round-trip safe for
older projects, labels them as legacy/ignored, and excludes them from AI generation.

## World links and preservation

Character Card V2 `data.world_names` and nullable `data.lore_world_names` now map into
the character project and survive JSON, PNG and group-member round trips. An explicitly
included empty `lore_world_names: []` remains different from an absent property.

Front Porch group cards expose `lore_world_ids` beside their existing world IDs/names.
The Include checkbox preserves Rawhide's nullable distinction: disabled means absent;
enabled with no IDs means an explicit empty list.

Unknown Character Card V2 `data` properties, unknown Front Porch extension properties and
unknown group-card properties are retained during import and merged back during export.
Known edited CCF fields take precedence over their preserved source copies.

## Compatibility notes

- Existing projects require no migration.
- Existing legacy Needs properties are not deleted.
- Character duplication uses the same project record, so world links and preserved data
  copy with the character.
- Chaos boolean compatibility remains: `true` maps to Normal and `false` to Disabled.
- Rawhide's portable character schema still formally carries boolean Chaos enablement;
  CCF also retains the selected frequency for forward-compatible round trips.
