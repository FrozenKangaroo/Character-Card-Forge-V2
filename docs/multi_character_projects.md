# Multi-Character Projects

Character Card Forge v0.5 introduced the multi-character project container. v0.6 adds structured relationships and reusable multi-character card workflow drafts on top of that foundation.

## Character roster

The Character Workspace now contains a project-level roster above the template editor.

You can:

- switch the active character without leaving the project;
- assign an optional group role such as leader, rival, handler, or newcomer;
- add a new blank character;
- duplicate the active character as a starting point;
- remove a character while keeping at least one character in the project;
- give each character its own template, Character Builder state, card content, and generation history.

Group roles are lightweight project metadata and are supplied to the Group Scene Generator when present.

Switching characters commits the current in-memory editor values into the project container before loading the next character. Character-specific AI previews and builder windows are closed when the active character changes so a late result cannot be applied to the wrong character.

## Shared Context

**Shared Context** opens a detachable native window for project-wide information:

- scene/context title;
- premise;
- setting;
- current situation;
- shared rules and constraints;
- private project notes.

Applying shared context updates the project in memory. Use the normal workspace **Save** action to write it to disk.

Shared context is supplied to normal full-character generation, field suggestions, and controlled builds so separately generated characters can remain consistent with the same world and situation.

## Group Scene Generator

The detachable **Group Scene Generator** is the first multi-character AI workflow.

1. Select at least two project characters.
2. Optionally add scene-specific instructions.
3. Generate a proposal through the shared AI queue.
4. Review and edit the returned shared context.
5. Review per-character scenario suggestions.
6. Choose exactly which proposal items to apply.

Nothing is applied automatically.

The AI response is expected to contain:

```json
{
  "shared_context": {
    "title": "...",
    "premise": "...",
    "setting": "...",
    "situation": "...",
    "shared_rules": "...",
    "notes": "..."
  },
  "characters": [
    {
      "character_id": "exact supplied character UUID",
      "scenario": "..."
    }
  ]
}
```

Unknown character IDs are ignored. The window only offers scenario suggestions for characters that still exist in the active project.

## Scope of v0.5

v0.5 establishes the project and generation foundation. It does not yet implement:

- relationship-matrix editing;
- one exported card containing multiple characters;
- split-card batch generation;
- dedicated group-card export formats;
- shared lorebook generation.

Those systems can now be built on the v2 project model without redesigning single-character storage again.

## Project-level series

A series assignment belongs to the whole multi-character project. Every roster member shares the same continuity and generation guidance, while retaining independent templates, concepts, cards, builder state, and histories. For rosters that require different continuities, use separate projects rather than per-character series overrides.
