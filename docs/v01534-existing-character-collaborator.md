# v0.15.34 — Existing Character → Collaborator

## Purpose

v0.15.34 completes the next source-aware Character Collaborator step established by v0.15.33: an existing Workspace/imported character can now be opened directly as structured, read-only Collaborator source.

The workflow is intentionally non-destructive. Opening a character in Collaborator does not rewrite the source card and does not call an AI provider merely by opening the conversation. The author chooses a starting direction first, then develops the idea conversationally.

## Godot baseline

Character Card Forge now targets Godot **4.7.1 stable** for development and CI.

`project.godot` advertises the Godot 4.7 project feature level, while `tools/setup_godot_ci.sh` enforces 4.7.1 as the minimum CI engine even when a historical workflow still requests an older 4.6.x version.

This baseline change does not claim that Godot 4.7.1 fixes the separate Linux/X11 GLX native crash previously observed as `BadAlloc` → `glXMakeCurrent failed` → signal 11. That issue remains a runtime observation point after the engine upgrade.

## Workspace workflow

The **Author** menu adds **Develop Current Character in Collaborator…**.

Before opening the chooser, Workspace captures current edits and commits the active character to the in-memory project container. This means the Collaborator source snapshot represents what is currently visible in Workspace rather than a stale saved copy.

The chooser offers these stable starting directions:

1. Refine / deepen this character
2. Alternative version / route
3. Future version
4. Past version
5. Continue after an event
6. Promote a side character
7. Relative / descendant
8. Connected character
9. New character in the same setting
10. Open-ended development

Every direction has its own explanation and optional starting-direction prompt. The free-text direction is optional except where the author naturally needs to identify an event/person/branch.

## Source semantics

v0.15.34 reuses the v0.15.33 `character_card_forge_collaborator_source` format and its `character` source type rather than creating a second source format.

The entire character record is captured as the structured snapshot. The source remains read-only within the conversation. Model-facing context continues to distinguish:

- established source facts;
- author-requested changes;
- new/proposed details.

The selected starting direction becomes explicit `author_intent` and is therefore included in every source-aware Collaborator request. Optional author direction is appended to that intent rather than being silently interpreted by Workspace.

## Derivation provenance compatibility

The workflow deliberately reuses the v0.14.10 Related Character / AI Variation provenance vocabulary. Source provenance gains a `derivation` object containing:

- `source_project_id`;
- `source_character_id`;
- `source_character_name`;
- `derivation_type`;
- `derivation_prompt`;
- `intent_label`;
- `origin_workflow`;
- `created_at`.

This avoids creating an incompatible second lineage model and gives later releases one stable basis for alternative versions, relatives, descendants, side-character promotions and connected characters.

## Collaborator UI

Character-source conversations show the selected starting direction in the existing Source panel. The source panel continues to state that the snapshot is read-only and that established facts remain authoritative unless the author explicitly asks to change or branch them.

## Completion boundary

v0.15.34 intentionally does **not** make source replacement automatic.

The existing Collaborator completion behavior remains safe and non-destructive. The roadmap keeps the following completion work separate:

- v0.15.35 — completion routing and group integration;
- v0.15.36 — refinement compare/apply;
- v0.15.37 — multi-source Collaborator.

This prevents an exploratory conversation from silently overwriting the character it was based on.

## Warning cleanup

The Idea Notebook refresh loop no longer declares a local `title` variable inside a `Window` subclass. It now uses `idea_title`, removing the Godot `SHADOWED_VARIABLE_BASE_CLASS` debugger warning without suppressing the warning category.

## Regression coverage

v0.15.34 adds focused coverage for:

- all ten author-intent IDs;
- character source construction;
- source snapshot preservation;
- model-facing author intent and optional direction;
- v0.14.10-compatible derivation provenance;
- live v0.15.34 Workspace/Collaborator/chooser wiring;
- the Author-menu action;
- the Godot 4.7 project feature baseline;
- warning-as-error import hygiene.

The v0.15.34 manifest extends the existing broad regression chain so earlier AI Ideas, Idea Notebook, Collaborator, generation and authoring invariants remain active.
