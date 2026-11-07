# v0.21.17 Front Porch Pockets & Wardrobe defaults

This compatibility update follows Front Porch Rawhide PR #708 at merged commit
`04f260783499728ffc93708132eb36900e280868`. It distinguishes portable defaults for
new chats from the runtime switches stored by an existing conversation.

## Character cards

The portable character setting remains:

```json
{
  "extensions": {
    "front_porch": {
      "realism_engine": {
        "pockets_enabled": false,
        "inventory": {
          "worn": ["Sundress (rain-soaked)"],
          "carrying": ["Phone, keys and a folded note"]
        }
      }
    }
  }
}
```

`pockets_enabled` controls the initial Pockets & Wardrobe choice when a new chat is
created. A missing property uses Rawhide's enabled default. CCF preserves all three
portable states—missing, explicit `true` and explicit `false`—through editing and
Character Card V2 import/export.

`inventory.worn` and `inventory.carrying` remain arrays of complete strings. Commas,
quotes, Unicode and line breaks inside one inventory item do not split it into multiple
items.

## Group cards

The group-wide new-chat default is the optional top-level `pockets_enabled` property
inside the existing JSON-encoded `default_member_realism_state` object. Missing means
enabled; Rawhide's canonical enabled representation omits the property, while disabled
writes `false`.

Each member also keeps the `pockets_enabled` default in their embedded Character Card V2
data. Rawhide starts a member with Pockets tracking only when both the group default and
that member's character default permit it. CCF therefore exposes the group default in
the existing group-card editor and preserves each member default through the embedded
cards.

## Runtime boundary

Rawhide stores live chat choices separately: one-to-one sessions use a database session
field and group member state uses `pockets_switch`. Those are runtime values, not portable
character or group authoring fields. CCF does not write them to Character Card V2 or
group-card exports, and changing an authored default does not alter an existing chat.

No project or card migration is required. Unknown Front Porch and group properties remain
preserved.
