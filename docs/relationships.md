# Relationship Matrix

Character Card Forge v0.6 adds project-level structured relationships for multi-character projects.

Relationships are stored once per unordered character pair. Directional feelings and behaviour remain separate, so an asymmetric relationship does not have to be duplicated across two character records.

## Relationship record

Each defined relationship uses this structure:

```json
{
  "relationship_id": "<stable pair key>",
  "character_a_id": "<character UUID>",
  "character_b_id": "<character UUID>",
  "label": "Rivals",
  "status": "Uneasy truce",
  "summary": "A concise shared overview.",
  "a_to_b": "How character A sees or treats character B.",
  "b_to_a": "How character B sees or treats character A.",
  "dynamic": "How the relationship behaves and may develop.",
  "notes": "Private planning notes.",
  "tags": ["rivalry", "slow trust"],
  "intensity": 75,
  "updated_at": "<timestamp>"
}
```

The pair is canonicalised internally so only one record can exist for the same two character IDs. Directional fields are swapped automatically if canonical ordering changes during project duplication.

## Relationship Matrix window

Open **Relationships** from the Character Workspace.

The left-hand pair matrix always shows every possible pair in the project. Undefined pairs remain available for editing without creating empty relationship records.

The editor supports:

- relationship label and current status;
- 0–100 intensity metadata;
- tags;
- shared summary;
- independent A → B and B → A descriptions;
- evolving dynamic;
- private planning notes.

Edits remain local to the window until **Apply Matrix to Project** is pressed. The project itself is not written to disk until the normal workspace **Save** action is used.

## AI-assisted relationship generation

Select two or more characters in the Relationship Matrix and choose **Generate Selected Relationships**.

The AI receives:

- selected character IDs and character information;
- shared project context;
- existing relationships among the selected characters;
- optional user instructions.

It is asked to return every pair within the selected set. Generated relationships are loaded into the local matrix for review and editing rather than being applied directly to the project.

## Generation context

Once relationships are applied to the project, relevant relationship information is available as read-only context to:

- full-character generation;
- per-field AI suggestions;
- Controlled Build;
- Group Scene Generator;
- Card Workflow Studio.

This keeps relationship continuity centralised instead of copying the same relationship prose into every character card.

## Character removal and project duplication

Removing a character automatically removes relationship records involving that character.

Duplicating an entire project remaps both ends of every relationship to the duplicated character UUIDs while preserving directional meaning.

## Assigned series context

Relationship AI drafting receives the project's current series bible. This helps generated dynamics respect shared canon, institutions, tone, and continuity without storing a second copy of the series inside each relationship record.
