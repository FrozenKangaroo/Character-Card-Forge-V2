# v0.15.35 — Character Collaborator Completion Routing

## Purpose

v0.15.35 closes the completion-routing gap left deliberately open by v0.15.34. Character Collaborator can now finish a Blueprint or Detailed Workspace Draft without immediately and blindly appending/replacing Workspace character data.

The completion payload is generated first, then Character Card Forge asks where that completed character should go.

## Safety contract

The routing rules are intentionally conservative:

- if the current Workspace character is an untouched placeholder, **Populate Current Empty Character** is recommended;
- if the current Workspace character contains authored material, **Create New Character in This Project** is recommended;
- **Create as New Project** is always available as a non-destructive alternative;
- an occupied current character is never overwritten by v0.15.35;
- refinement/replacement of an existing character remains reserved for v0.15.36 **Compare & Apply**.

This means exploratory Collaborator work cannot silently destroy the card it was based on.

## Empty Workspace detection

A fresh `new_character_record()` is considered an empty slot even though it already has a stable ID, timestamps, default `Untitled Character` names, template metadata and Workspace state.

The slot becomes occupied when meaningful author data exists, including:

- Generation Concept or concept notes;
- metadata summary, group role, creator/version or tags;
- configured template generation fields;
- Description, Personality, Scenario, First Message and other card text;
- Alternative Greetings;
- Character Lorebook/card extensions;
- portrait/generated/emotion images;
- character attachments.

The current-slot destination is not even offered once that meaningful content exists.

## Empty-slot materialisation

When **Populate Current Empty Character** is selected, v0.15.35 materialises the Collaborator result into a normal standalone character record but preserves the empty placeholder's:

- `character_id`;
- original `created_at`.

This avoids leaving a useless blank sibling in a newly created project and keeps stable references to the placeholder character intact.

## Same-project completion

When the Workspace is occupied, **Create New Character in This Project** is the default.

The completed character receives its own stable character ID and is appended to the existing project. The previous active character is left unchanged. Project-level shared context, relationship/group tooling, Card Workflows and the rest of the project container remain available around the new character because it joins the same project rather than creating an unrelated card copy.

This is particularly important for v0.15.34 Existing Character → Collaborator workflows such as future versions, descendants, connected characters and same-setting characters.

## New-project completion

**Create as New Project** materialises a standalone character into a fresh Character Project and saves that project to the Library while leaving the current Workspace project untouched.

The separate project is named from the completed character. This route is intentionally non-destructive and does not force an unsaved current project to be replaced in memory just to create the new destination.

## Handoff formats

v0.15.35 keeps both existing Collaborator handoff formats:

1. **Blueprint → Generation Concept** — produces the detailed canonical Generation Concept for later Generate Character materialisation.
2. **Detailed Workspace Draft** — produces template fields plus Alternative Greetings and Character Lorebook material immediately.

The completion destination is chosen after either format has been generated.

## Provenance

Completed characters keep Character Collaborator provenance including:

- handoff mode;
- selected destination;
- Collaborator session title;
- source-context ID/type when available;
- generation timestamp.

If the source carries v0.15.34 derivation provenance, that derivation record is copied into the completed standalone character. Future/past versions, relatives, descendants, connected characters and other derived cards therefore retain their source lineage after materialisation.

## Pending completion recovery

Closing/cancelling the destination chooser does not throw away an already-generated AI result.

The payload remains pending in the current Workspace and can be reopened through:

**Author → Place Pending Collaborator Completion…**

This avoids paying for another provider request simply because the destination decision was postponed.

Pending routing is project-scoped; changing projects clears/hides unsafe routing state rather than allowing a completion generated for one project to be silently inserted into another.

## v0.15.36 boundary

v0.15.35 deliberately does not add direct replacement of an occupied source character.

v0.15.36 remains the refinement phase and should provide an explicit comparison between the current/source character and the Collaborator result, with selective/whole-card apply controls. That is the appropriate place for destructive replacement semantics because the user can inspect the differences first.

## Regression coverage

The focused v0.15.35 regression validates:

- empty-slot detection and recommendation;
- occupied-character detection and safe recommendation;
- current-slot option removal when occupied;
- stable character-ID preservation for empty-slot reuse;
- Blueprint materialisation;
- Detailed Workspace Draft materialisation;
- Alternative Greetings and Character Lorebook preservation;
- v0.15.34 derivation provenance preservation;
- live v0.15.35 app/Workspace/Collaborator/destination-window wiring;
- pending-completion recovery menu presence;
- a live empty-slot completion that keeps character count at one;
- a live occupied completion that creates a second same-project character without changing the original.

CI continues on Godot 4.7.1 stable and the broad regression manifest inherits all earlier authoring, generation, Collaborator, Idea Notebook, Vision and Image Studio coverage.
