# Generation Components

Character Card Forge template format 3 separates three related concepts:

1. **Workspace fields** are editable project values such as `character.description` and `character.personality`.
2. **Generation components** are structured expectations used while the AI builds those values.
3. **Output bindings** connect a generation group to an existing workspace/Character Card field.

This allows a rich authoring structure without inventing incompatible top-level Character Card properties.

## Example

```json
{
  "id": "personality_structure",
  "title": "Personality structure",
  "output_field_id": "personality",
  "enabled": true,
  "allow_extra_components": true,
  "components": [
    {
      "id": "mind",
      "label": "Mind",
      "enabled": true,
      "required": true,
      "instruction": "Core traits, motivations, goals, values, and internal conflicts."
    },
    {
      "id": "occupation",
      "label": "Occupation",
      "enabled": false,
      "required": false,
      "instruction": "Work, studies, profession, or regular social role."
    }
  ]
}
```

The model is instructed to produce an enabled component as a labelled line inside the bound output field. In the example above, `Mind` participates in generation and semantic completeness checking. `Occupation` does neither because it is disabled.

## Enabled vs required

`enabled` and `required` are deliberately separate.

- **Disabled:** omitted from the generation prompt and completeness validator.
- **Enabled + optional:** requested from the model, but omission does not trigger semantic repair.
- **Enabled + required:** requested and checked; omission may trigger the bounded semantic-repair pass.

This means a template can ask for useful optional detail without treating every optional omission as a failed generation.

## Output binding

`output_field_id` is the ID of an existing template workspace field. For example:

```text
personality_structure → personality → character.personality
```

The generation components do not become separate Character Card V2 fields. They organise content inside the interoperable Personality field.

A generation group must bind to a real workspace field ID or template validation rejects it.

## Editing

Open **Templates**, select a user template, then choose **Edit Generation Components**.

The built-in Default template remains read-only. Duplicate it first when creating a customised version.

The editor supports:

- add/remove/reorder groups;
- enable/disable a group;
- select the bound output field;
- allow or disallow extra AI-labelled components;
- add/remove/reorder components;
- rename component IDs and labels;
- enable/disable components;
- mark components required/optional;
- edit per-component AI instructions.

After applying changes in the component editor, press **Save Template** in Template Manager to persist them.

## Default Personality structure

The v0.13 Default template uses a V1-inspired Personality structure containing:

- Mind
- Moral Alignment
- Emotional Tendencies
- Decision Style
- Occupation
- Likes
- Dislikes
- Hobbies
- Skills
- Boundaries
- Risk Tolerance
- Secrecy
- Relationship Behavior toward `{{user}}`
- Loyalty
- Speech Style

Not every enabled component is required. Templates can tune which omissions should cause a repair pass.

## Default Description structure

Description remains dedicated to visible/external information:

- Age
- Appearance
- Outfit Style
- Distinguishing Features

Biography, internal motivations, relationship history, and scenario events should live elsewhere unless directly necessary to explain a visible trait.

## Format compatibility

Template format 3 adds `generation_groups`.

Format-2 templates continue to load. During normalisation they receive an empty generation-group collection and keep their existing top-level field generation behaviour. They are not forced into the Default template's Description or Personality structure.

Saving an older template through the current Template Manager writes the normalised format-3 representation.

Project format 2 and Character Card V1/V2 import/export are unchanged by this feature.
