# Character Builder

The Character Builder is a guided planning system that lives inside the existing character project rather than creating a separate database or alternate character record.

## State location

Builder state is stored under:

```text
workspace.builder
```

A typical project contains data shaped roughly like:

```json
{
  "workspace": {
    "builder": {
      "format_version": 1,
      "preset_id": "custom",
      "selected_step": "personality",
      "foundation": {},
      "personality": {},
      "background": {},
      "scene": {}
    }
  }
}
```

The builder is planning state. Final character-card fields continue to live below `character`, `metadata`, and `concept`.

## Data-driven schema

Builder steps and fields are defined by:

```text
res://data/builder_schema.json
```

The UI reads this schema instead of permanently hardcoding every question into the window script. New builder fields can therefore be added without redesigning the storage model.

Current steps are:

- Foundation
- Personality
- Background
- Scene
- Review

## Presets

Built-in presets live as JSON files under:

```text
res://data/builder_presets/
```

A preset supplies partial builder values. Applying a preset merges those supplied values into the existing builder state rather than deleting unrelated details.

## AI jobs

Builder AI jobs run through the shared `CCFGenerationService` queue.

### AI Fill This Step

Requests values only for fields in the currently selected builder step. Existing builder context is supplied so generated details should remain consistent.

### AI Fill All Builder Fields

Requests all known builder fields in one structured generation job.

### Analyse Current Concept

Reads the current `concept.prompt` and asks the model to conservatively extract information into known builder paths. Unsupported or unknown details should be omitted rather than freely invented.

AI results modify only builder state until the user explicitly applies them.

## Applying builder data

### Send to Concept

Builds a structured generation-ready brief and writes it to:

```text
concept.prompt
```

A working name can also replace the default `Untitled Character` placeholder.

### Apply to Character

The builder can transfer suitable information to:

```text
character.name
concept.prompt
character.description
character.personality
character.scenario
metadata.tags
```

By default, existing non-empty destination fields are preserved. The user may explicitly enable overwrite mode when replacement is desired.

Fields such as first message remain outside the deterministic builder transfer because they are better produced by normal generation or edited manually after the core character is established.

## Assigned series context

When the current project has a valid assigned series, AI Fill This Step, AI Fill All Builder Fields, and Analyse Current Concept receive the current series bible as protected continuity and style context. Builder state remains per-character; the series definition remains project-external and shared.
