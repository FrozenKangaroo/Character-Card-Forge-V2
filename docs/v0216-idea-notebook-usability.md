# v0.21.6 Idea Notebook Usability

## Clear hierarchy identity

Every hierarchy row now carries a persistent semantic icon and tooltip:

- **Folder** uses a tabbed-folder shape and may contain subfolders and Notebooks;
- **Notebook** uses a bound-notebook shape and contains saved Ideas; and
- **All Ideas / Unfiled** use a separate built-in-view shape.

An empty Folder has the same identity, count and drop behavior as a populated Folder. It
does not need a fake child merely to look expandable. Icons provide shape semantics rather
than relying on color alone.

Selecting a Folder, Notebook or built-in view updates the Saved Ideas summary with the
scope kind, full path and current idea count. Folder summaries additionally disclose the
number of descendant Notebooks included by the recursive view.

## Context-aware hierarchy dialogs

Create and Rename dialogs now identify the exact operation throughout their title,
description, input placeholder and confirmation action. Creation descriptions show
**Root** or the full destination Folder path. Stable IDs remain the stored identity;
paths are presentation only.

## Delete one or many saved Ideas

The Idea Details delete action reads the live Saved Ideas selection:

- one checked row shows **Delete Idea…**;
- multiple checked rows show the exact **Delete N Ideas…** count; and
- no checked rows disables deletion.

One confirmation permanently deletes the captured stable IDs. Character Projects and
characters already created from those Ideas are unaffected. A batch attempts every item,
reports successes and failures, then refreshes the tree, counts, tags and visible list
once. The active Folder/Notebook scope remains selected and Idea Details moves to a
sensible survivor.

The desktop **Delete** key opens the same confirmation only while Saved Ideas itself has
focus. LineEdit and TextEdit controls—including Title, Concept, Notes, Tags, search and
hierarchy naming—retain ordinary text-editing behavior.

## Performance and compatibility

Live Ctrl/Shift selection remains independent from the one focused Idea Details record.
Range selection performs no per-row saved-Idea loads, hierarchy reads or tree rebuilds.
The v0.21.5 Folder Tree storage model, migration, drag/drop, recursive views, safe Folder
and Notebook deletion, path-aware destinations and Idea Pack export semantics are
unchanged.
