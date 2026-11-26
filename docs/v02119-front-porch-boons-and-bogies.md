# v0.21.19 Front Porch Boons & Bogies (trait kit)

Front Porch's Boons & Bogies design (`docs/design/boons-and-bogies.md` in the
Front Porch repository, design v2, 2026-11-20) adds a portable character-card
field so an author can pre-seed the traits a character starts with. CCF now
authors and round-trips that field. It does **not** implement the chat runtime:
rolls, growth passes, milestones and Moments belong to Front Porch.

## The property

```json
{
  "extensions": {
    "front_porch": {
      "realism_engine": {
        "traitKit": [
          {
            "kind": "boon",
            "text": "example novice boon",
            "tier": "emerging",
            "pinned": false
          },
          {
            "kind": "bogey",
            "text": "example novice bogey that pushes against a boon",
            "tier": "emerging",
            "pinned": false,
            "linkedTo": "example novice boon"
          }
        ]
      }
    }
  }
}
```

| Key | Type | Rules |
| --- | --- | --- |
| `kind` | `boon` \| `bogey` | A boon is an ability that can improve; a bogey is a recurring flaw that fires on a pressure roll. |
| `text` | string | Required, non-empty, unique across the kit (compared case-insensitively). Front Porch matches links against this exact text. |
| `tier` | `emerging` \| `developing` \| `established` | Shown in CCF as Novice / Skilled / Master. Front Porch seeds a new chat at 0.30 / 0.60 / 0.80 strength. |
| `pinned` | boolean | A pinned trait is never silently retired. New bogies default to pinned in the editor. |
| `linkedTo` | string, optional | Bogeys only, and must equal one boon's `text` exactly. Front Porch uses the link when the boon grows toward overcoming the flaw. |

Limits, from the design's ruling 11: **at most six entries combined** and **at
most three bogeys**, which share the card's three-flaw budget. Card entries use
a separate budget from the twelve story rings, so a kit never evicts story
growth.

## Editor behaviour

The new **Boons & Bogies** group sits beside Character Life in the optional
Front Porch editor, with one row per entry:

- Kind and tier selectors, a pinned checkbox, a free-text field and, for a
  bogey, a **Pushes against boon** selector.
- **+ Add boon** / **+ Add bogey** disable themselves at the caps, and the
  status line reads `4 of 6 entries • 2 boons • 2 of 3 bogies`.
- Renaming a boon rewrites any bogey that linked to its old text, because Front
  Porch resolves links by exact string.
- A link whose boon was removed stays visible as `… • missing boon` and is
  reported on save instead of being silently dropped.
- Unknown keys on an entry are preserved, so a future Front Porch addition to
  the entry shape survives editing and export.

Validation runs on save and on **Validate Front Porch Data**: caps, empty text,
duplicate text, unknown kind or tier, `linkedTo` on a boon, and a link naming no
boon in the kit are all errors with the entry number in the message.

## Round trips

`traitKit` survives Character Card V2 JSON export, import, PNG cards and group
cards. The kit is copied into a new chat by Front Porch, not shared: each chat's
character grows apart from the card from then on. Turning Boons & Bogies off in
Front Porch loses no data.

## Compatibility notes

- No project or card migration is required.
- Cards without `traitKit` are unchanged; the field stays absent until the
  author includes it.
- Front Porch ships Boons & Bogies **off** by default, and the design doc marks
  the feature as not yet built. CCF writes the documented portable shape ahead
  of the runtime; a Front Porch build that does not know the key ignores it.
