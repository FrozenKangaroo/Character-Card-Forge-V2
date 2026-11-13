# v0.21.18 Front Porch Afterglow new-chat defaults

This compatibility update follows Front Porch Rawhide PR #669 at merged commit
`756d1a33959036498a6657bc0d0989438654e2f4`. That release gave Afterglow a
per-chat switch again and added the portable character-card property that seeds
it for new conversations.

## The property

```json
{
  "extensions": {
    "front_porch": {
      "realism_engine": {
        "afterglow_enabled": false
      }
    }
  }
}
```

Rawhide reads `afterglow_enabled` when a **new** one-to-one conversation starts:

- The property is **omitted** when the card leaves Afterglow on, which is the
  default. A missing property reads as enabled, so old cards keep working
  without migration.
- An explicit `false` starts new chats with Afterglow off.
- An explicit `true` is accepted and preserved even though Rawhide's own
  encoder omits it.

Editing a card never reaches conversations that already exist. In a group, a
member's card value is read beside the group conversation's own switch, and the
group switch still turns Afterglow off for the whole cast.

Runtime values are not portable authoring data. CCF therefore writes only
`afterglow_enabled`; it never writes a session switch into a character or group
card.

## Editor behaviour

| Control | Rawhide property | Portable behaviour |
| --- | --- | --- |
| Afterglow default for new chats | `afterglow_enabled` | Missing means enabled. CCF preserves missing, explicit `true` and explicit `false` through editing, Character Card V2 export, import and re-export. |

The control lives in **Front Porch — Optional → Opening State**. Turning
**Include** off restores property absence, which is Rawhide's canonical enabled
representation. Turning it on with the box unticked writes an explicit `false`.

## Checkbox proposal safety

Because the new control is AI-capable, checkbox values are now normalised
explicitly instead of through `bool()`. GDScript's `bool("false")` is `true`,
so a text answer would previously have switched a checkbox **on**:

| Proposal | Result |
| --- | --- |
| `true` / `"true"` / `"yes"` / `"on"` / `1` | enabled |
| `false` / `"false"` / `"no"` / `"off"` / `0` | disabled |
| `"maybe"`, `null` or any other type | validation error; the existing value is preserved |

This applies to every checkbox field, not only Afterglow.

## Compatibility notes

- No project or card migration is required.
- Existing legacy needs properties remain visible and lossless.
- Unknown Front Porch extension properties are still preserved.
- Group cards carry each member's `afterglow_enabled` inside the embedded
  character cards; the group conversation switch is never exported.
