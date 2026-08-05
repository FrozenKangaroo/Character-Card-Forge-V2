# v0.15.36 — Collaborator Refinement Compare/Apply + Forward+

## Purpose

v0.15.36 completes the existing-character refinement loop started in v0.15.34 and made safely routable in v0.15.35.

A completed Character Collaborator payload can now be routed to **Compare & Apply to Source Character…** when its read-only source is an existing character that still exists in the originating Character Project.

The release also changes Character Card Forge's normal desktop renderer from Godot **GL Compatibility** to **Forward+** after repeated Linux/X11 GLX instability was observed under Compatibility and runtime use with Forward+ remained stable.

## Compare & Apply workflow

v0.15.36 keeps the v0.15.35 non-destructive default. An occupied Workspace still recommends **Create New Character in This Project**.

For an existing-character Collaborator source, the destination chooser additionally exposes:

**Compare & Apply to Source Character…**

This opens a dedicated comparison window rather than changing project data immediately.

The comparison is based on two stable inputs:

1. the exact read-only source-character snapshot captured when the character was sent to Collaborator;
2. the completed Collaborator proposal materialised from the selected Blueprint or Detailed Workspace Draft handoff.

This is intentionally different from simply diffing the proposal against whichever character happens to be active later.

## Selective changes

The comparison window lists only explicit generated fields/sections whose proposed values differ from the captured source.

Each changed row can be selected independently. Supported comparison material includes:

- Generation Concept;
- Name when explicitly generated;
- template generation fields such as Description, Personality, Scenario and First Message;
- Alternative Greetings;
- Character Lorebook.

Unchanged explicit fields are omitted from the change list so the review remains focused.

## Update Original

**Update Original** applies only the selected changes to the existing source character.

The operation preserves:

- the source character ID;
- unselected fields;
- assets and images;
- attachments;
- unrelated metadata and extensions;
- existing provenance outside the refinement record.

Update Original is deliberately available only for directions that semantically represent refinement of the same character: currently **Refine / deepen** and **Open-ended development**.

Branch or related-character directions such as future/past versions, alternate routes, descendants, side-character promotion, connected characters and same-setting characters cannot use Update Original. They must remain non-destructive.

## Create Improved Copy

**Create Improved Copy** duplicates the latest current source character, assigns a new stable character ID/creation identity, and applies only the selected proposal changes.

This has two useful properties:

- the original source remains unchanged;
- edits made to unselected source fields after Collaborator was opened are retained in the improved copy.

The copy keeps compatible v0.15.34 derivation/source provenance instead of introducing a competing lineage model.

## Stale-source conflict guard

Before Update Original is allowed to write a selected field, v0.15.36 compares the current source value with the captured source snapshot.

If the user manually changed a selected source field after opening Collaborator, and the current value is neither the captured value nor already equal to the proposal, the update is blocked.

This prevents a long-running Collaborator session from silently overwriting newer manual edits.

Create Improved Copy does not need the same destructive-write guard because it never replaces the source record.

## Pending completion behavior

Closing Compare & Apply does not discard the generated Collaborator completion.

The completion remains pending and can be reopened through:

**Author → Place Pending Collaborator Completion…**

The existing v0.15.35 project scoping remains in force; changing projects clears unsafe pending routing state.

## Forward+ renderer default

`project.godot` now uses:

- `config/features = Forward Plus`;
- `rendering/renderer/rendering_method = forward_plus`;
- Godot's `rendering/rendering_device/fallback_to_opengl3 = true` fallback.

Forward+ therefore becomes the normal desktop path, using Godot's RenderingDevice backend instead of the Compatibility renderer's OpenGL path.

The OpenGL fallback remains enabled for systems that genuinely cannot initialise a supported RenderingDevice backend. This keeps a practical legacy-hardware escape path without forcing modern Linux systems through Compatibility by default.

The previous `BadAlloc` / `glXMakeCurrent failed` / signal 11 issue is recorded as **not reproduced after switching to Forward+** rather than being declared universally fixed until more runtime use confirms it.

## Regression coverage

The v0.15.36 focused regression verifies:

- existing-character source recognition;
- source project/character lookup;
- proposal materialisation;
- changed-field comparison and unchanged-field suppression;
- selective Update Original;
- source character ID preservation;
- unselected-field preservation;
- stale-source conflict detection;
- improved-copy creation with a new ID;
- branch-intent Update Original blocking;
- v0.15.36 destination chooser and comparison-window live wiring;
- real Workspace selective application;
- Forward+ project default;
- Compatibility/OpenGL fallback remaining enabled.

The broad regression manifest advances to `regression_suites_v01536.json` and inherits all v0.15.35 and earlier regression coverage.
