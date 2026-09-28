# v0.21.7 Folder-only Idea Library

## One organisation model

The current Idea Library uses a familiar file-browser model:

```text
Folder
├─ Ideas
└─ Child Folder
   └─ Ideas
```

Folders may contain both direct Ideas and child Folders. **All Ideas** and **Unfiled** are
pinned built-in views. Folder names remain organisational only; Bible, Series, tags,
priority and Idea Source metadata keep their separate semantic meaning.

Save Generated Ideas, Idea Details reassignment and Idea Pack import show **Unfiled** plus
every Folder's full path. Selecting a Folder displays its direct and descendant Ideas.
Recursive Folder export includes the same population without changing the Idea Pack
schema.

## Moving and deleting safely

Drag one Idea—or a Ctrl/Shift multi-selection—from Saved Ideas onto a Folder or Unfiled.
The batch uses stable Idea IDs and refreshes the hierarchy once. All Ideas is a view, not
a destination. Folders retain cycle prevention and may be moved back to the root.

Deleting a Folder never deletes its Ideas. Direct Ideas and direct child Folders move to
the deleted Folder's parent. When a root Folder is deleted, its direct Ideas become
Unfiled. Ideas inside child Folders remain assigned to those children.

## Storage migration

`library.json` advances to format version 3. Its canonical hierarchy collection is
`folders`; saved Idea format version 2 uses `folder_id` (empty means Unfiled).

On first load, every legacy Notebook becomes a Folder with the same ID, parent, name and
timestamps. Each legacy Idea's `notebook_id` becomes the matching `folder_id`. If a Folder
and Notebook already share an ID, both are preserved: the former Notebook receives a
deterministic `-legacy-notebook` alias and its Ideas follow that alias. Migration never
merges same-named records or discards inaccessible data.

Historical internal method names remain as narrow compatibility aliases while active UI
and canonical writes use Folder terminology and fields.

## Hierarchical save destinations

Save Generated Ideas now uses a searchable Folder tree instead of a flat list of complete
paths. It supports nested expansion, **Unfiled**, duplicate Folder names and a clear
selected-path indicator while retaining stable Folder IDs internally. **All Ideas** is
never offered because it is a view rather than a destination.

**New Folder…** uses the same reusable picker for its parent, with **Root level** as an
explicit choice. The native, transient dialog opens at 660 × 560 pixels with a 600 × 500
minimum; after creation, the new Folder is refreshed into the hierarchy and selected as
the save destination.

## Context-aware similarity review

The optional final AI similarity pass now receives a frozen snapshot of the primary
prompt or Additional Direction, canonical active Idea Source context and Series context
from the start of the generation session. Explicitly requested common traits are treated
as shared invariants. The reviewer instead compares discretionary relationship,
motivation, consent, boundary, progression, reveal, consequence and ongoing-tension
choices, while preserving the existing `duplicate`, `near_duplicate` and
`related_distinct` result contract and Reject-mode behavior.
