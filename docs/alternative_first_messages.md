# Alternative First Messages

Character Card Forge v0.13.8 adds an app-level **Alternative Greetings** workspace tab.

Alternative First Messages are optional playable openings stored at:

```text
character.alternate_greetings
```

They are separate from `character.first_message`; generating or editing alternatives must never replace the main opening.

## Authoring workflow

- Choose a target count from 1 to 5.
- Choose an overall style or select **Varied**.
- Add optional instructions for alternate meeting points, moods, scenario branches, or opening constraints.
- Generate alternatives through the normal queued Text provider, or add/edit them manually.
- Review the full messages in separate editors before saving the Character Project.

The generation settings are stored under `generation.alternate_greetings_settings` as authoring state. The completed greeting strings remain ordinary character data.

## Interoperability

Character Card V2 supports `data.alternate_greetings`, so JSON and PNG-card exports preserve the array directly. Character Card V1 has no equivalent standard field; V1-oriented workflows must not silently replace the main `first_mes` with an alternative.

## Compatibility

Existing imported V2 cards already map `alternate_greetings` into the project model. Projects without alternatives continue to store/export an empty array. No project-format migration is required.
