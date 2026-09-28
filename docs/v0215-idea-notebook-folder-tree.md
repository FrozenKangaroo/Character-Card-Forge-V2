# v0.21.5 Idea Notebook Folder Tree

## Organisation model

Idea Notebook now follows a file-browser model:

```text
Folder
├─ Subfolder
│  └─ Notebook
│     └─ Ideas
└─ Notebook
   └─ Ideas
```

Folders organise other folders and Notebooks. Notebooks contain Ideas. Ideas never live
directly in a folder, and folder names have no semantic meaning. A folder called “High
Priority” is simply a user-created location; it does not change an Idea's priority,
tags, Bible, Series, source or implementation state.

**All Ideas** and **Unfiled** remain pinned built-in views. They cannot be renamed,
moved or deleted.

## Three-pane workflow

The Idea Notebook tab uses resizable panes for:

1. the Folder/Notebook tree;
2. Saved Ideas from the active tree scope; and
3. the focused Idea Details editor.

Selecting a Notebook shows Ideas assigned directly to that stable Notebook ID. Selecting
a folder recursively includes Ideas from all descendant Notebooks. Existing idea search,
tag, archive and sort controls narrow that population further.

Saved Ideas multi-selection is independent from tree navigation. Ctrl/Shift selection
still chooses the complete **Selected Ideas** export set, while the most recently focused
Idea remains the sole Idea Details editing target.

See [v0.21.6 Idea Notebook Usability](v0216-idea-notebook-usability.md) for persistent
Folder/Notebook icons, context-aware hierarchy dialogs, semantic scope summaries and
single/batch Saved Idea deletion.

## Tree actions

The visible toolbar and right-click menu support Folder and Notebook creation, rename and
safe deletion. Drag and drop supports Folder → Folder, Notebook → Folder and moves back to
the root level. Every move changes only the item's `parent_folder_id`; Notebook and Idea
IDs remain unchanged.

A folder cannot be moved into itself or any descendant. Deleting a folder moves its
direct child folders and Notebooks to the deleted folder's parent. No Ideas are deleted.
Deleting a Notebook retains the existing behavior: its Ideas become Unfiled.

Tree search matches Folder and Notebook names while retaining ancestor paths. Folder
expanded state is local UI metadata and is ignored safely when a Folder no longer exists.

## Save and export integration

Notebook destination selectors display full organisational paths but store only stable
Notebook IDs. This applies to:

- Save Generated Ideas;
- Idea Details Notebook reassignment;
- Idea Pack import; and
- Idea Pack export.

Notebook export labels use the full path. A recursive Folder export scope is also
available. Bible and semantic Series export scopes are unchanged and remain completely
separate from folder organisation.

## Storage and migration

`user://character_card_forge/idea_notebook/library.json` advances to format version 2.

Folder records contain:

```json
{
  "id": "stable-folder-id",
  "name": "High Priority",
  "parent_folder_id": "",
  "created_at": "...",
  "updated_at": "..."
}
```

Notebook records add `parent_folder_id`. Root items use an empty parent ID.

Format-v1 libraries load automatically with an empty Folder list and every existing
Notebook at root. Existing Notebook IDs, Idea IDs and individual Idea files are not
rewritten. Missing parents, self-parenting and cycles recover to root rather than causing
recursive failure.
