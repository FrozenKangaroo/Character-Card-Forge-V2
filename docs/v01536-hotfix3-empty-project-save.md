# v0.15.36-hotfix3 — Empty Project Save Guard

## Problem

Character Card Forge was persisting a brand-new Character Project immediately when **New Character** was pressed, before the author had entered any meaningful content.

That produced Library entries whose character fields, Generation Concept, lorebook, alternate greetings, assets, attachments, and project-shared content were all empty.

The behaviour conflicted with the existing v0.15.35 empty-character model, which already treated untouched placeholder slots as non-authored content.

## Root cause

The New Character shell path called `CCFStorageService.new_project()` and then immediately called `CCFStorageService.save_project(project)` before loading Workspace.

The configured-default-template hotfix preserved that save call while fixing template assignment, which made the premature persistence path especially visible.

The normal Workspace **Save** action also had no distinction between a brand-new empty shell and a project containing authored content.

## Fix

v0.15.36-hotfix3 introduces a dedicated project-persistence guard and moves the current shell/Workspace to it.

### Deferred first save

**New Character** now creates the project and character IDs in memory, assigns the configured application default template, and opens Workspace without creating `character.json` or a Library entry.

Stable IDs therefore still exist immediately for Workspace/tool wiring, but an abandoned untouched project leaves no persistent project behind.

### Meaningful-content boundary

A new project becomes persistable when it contains meaningful authored data, including:

- a deliberately changed project name;
- project summary, tags, series assignment, or shared context;
- relationships, card workflows, or project attachments;
- a real non-placeholder character name;
- Generation Concept or notes;
- normal/card/template generation fields;
- alternate greetings, lorebook/extensions, assets, or character attachments.

The following do not make a project persistable by themselves:

- UUIDs;
- timestamps;
- Workspace selection/state;
- `Untitled Project`;
- `Untitled Character` / numbered untouched placeholders;
- the configured/default template assignment.

### Manual Save

Pressing **Save** on a never-saved empty project now leaves it in memory and shows:

> Nothing to save yet. Empty projects stay in Workspace and are not added to the Library.

No `project_saved` signal is emitted and no Library refresh can expose a non-existent file.

### Existing saved projects

The guard is intentionally non-destructive. If a project already has a saved `character.json`, normal Save remains allowed even if the author later clears its content.

The hotfix does not silently delete, hide, or rewrite already-existing empty projects created by older builds. Those can still be removed explicitly through the Library.

## Regression coverage

The focused regression runs in isolated app-data and verifies:

1. a pristine project is classified as empty;
2. template assignment alone does not make it meaningful;
3. a real project name, real character name, or shared context does count as authored content;
4. the live **New Character** path creates stable in-memory IDs but no `character.json`;
5. the Library remains empty after creation;
6. pressing Save while still blank creates no file and reports **Nothing to save yet**;
7. meaningful Generation Concept content persists normally;
8. the current hotfix3 shell and Workspace are installed.

The hotfix regression manifest inherits v0.15.36-hotfix2 so the refined AI Ideas agency rules, configured-default-template behavior, Compare & Apply, Forward+, and historical cross-feature gates remain active.
