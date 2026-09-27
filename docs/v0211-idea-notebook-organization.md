# v0.21.1 Idea Notebook Organization

## Save a batch into a new notebook

**Save Generated Ideas…** retains its review-first behavior: every generated idea is
selected or cleared explicitly before anything is written. The destination row now
offers **New Notebook…**. Creating a notebook there immediately selects it as the batch
destination, so the author does not need to close the review window, switch tabs and
reopen the batch.

Duplicate and blank notebook names still use the existing validation. The batch remains
unsaved until **Save Selected** is pressed.

## Work with large collections

The Saved Ideas sidebar adds:

- notebook-name search while retaining All Ideas, Unfiled and the active notebook;
- notebook ordering by name, idea count or recent notebook/idea activity;
- idea ordering by updated time, created time, title or notebook then title;
- a persistent count and active-scope summary; and
- notebook names beneath results shown in All Ideas.

These controls compose with the existing idea text search, tag filter and archived-item
visibility. For example, an author can search all notebooks for a tag, order matching
ideas by notebook then title and still see exactly where every result is filed.

## Superseded navigation

v0.21.5 replaces the flat Notebook picker described above with a persistent nested folder
tree. The idea sorting, filtering, multi-selection and explicit generated-Idea save
semantics remain in place. See [v0.21.5 Idea Notebook Folder Tree](v0215-idea-notebook-folder-tree.md).

## Compatibility

Saved Idea files remain format version 1. v0.21.5 upgrades only `library.json` metadata to
format version 2 so Notebook parent-folder IDs and folder records can be stored. Existing
Notebook and Idea IDs remain unchanged. Deleting a notebook still preserves its ideas by
moving them to Unfiled.
