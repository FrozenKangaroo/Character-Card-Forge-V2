# Character Library 2.0

Character Card Forge v0.8 replaces the original basic project list with a richer project-and-character library while keeping saved `character.json` projects as the source of truth.

## Browsing modes

The library supports two views:

- **Thumbnail Grid** — portrait-led project cards with favourites, character counts, summaries, virtual organisation, and multi-selection checkboxes.
- **Compact List** — a denser single-line project view suitable for larger libraries and keyboard-style scanning.

The selected view, sort mode, and active filters are stored in disposable UI state under `settings/library_view.json`.

## Search and filters

The disposable index searches across:

- project names, summaries, and tags;
- character names, summaries, roles, and tags;
- creator and character-version metadata;
- description, personality, scenario, first-message, and creator-note text;
- virtual folder and collection names;
- recorded Character Card import format/spec metadata.

Available filters are derived from the current project files:

- favourites;
- virtual folders;
- collections;
- tags;
- unfiled projects.

Sorting currently includes update time, creation time, name, character count, and favourites-first ordering.

## Virtual folders and collections

Virtual organisation never moves project directories.

Project metadata stores:

```json
{
  "metadata": {
    "library": {
      "folder": "Main Cast",
      "collections": ["Fantasy", "Current Campaign"]
    }
  }
}
```

A project can be in one virtual folder and any number of collections. Because these values live in the project JSON, rebuilding or deleting the library index does not destroy organisation.

## Bulk actions

Select projects in either browsing mode to:

- favourite or unfavourite them;
- add one or more tags;
- optionally add those tags to every character in each selected project;
- assign or clear a virtual folder;
- add or remove a collection;
- delete multiple projects after confirmation.

The **Merge Tags** tool replaces a tag case-insensitively across project and character metadata, collapses duplicates, and saves only affected projects.

## Detail summary

The right-hand summary panel surfaces:

- the first available project portrait;
- project summary, tags, folder, collections, update time, and favourite state;
- character names, roles, summaries, creators, and character versions;
- recorded source format/spec information for imported cards.

## Disposable incremental index

The index is stored at:

```text
user://character_card_forge/cache/library_index.json
```

Each cache entry stores a fingerprint of the corresponding `character.json`. During a normal refresh:

- unchanged projects reuse their cached search row;
- edited/new projects are loaded and re-indexed;
- deleted projects disappear from the next index;
- portrait thumbnails are refreshed when their source image is newer.

Thumbnails are stored under:

```text
user://character_card_forge/cache/library_thumbnails/
```

Both the index and thumbnails are disposable. **Rebuild Index** regenerates them from project files. v0.8 performs this work synchronously; asynchronous/background indexing remains a later technical improvement for very large libraries.

## Series integration

The library resolves each project's `metadata.series_id` against the standalone series library at refresh time. Series names appear in grid cards, compact rows, search text, and project details.

The filter sidebar includes every available series plus **Unassigned**. Bulk-selected projects can be assigned, cleared, auto-matched, or given their assigned series' default tags.

Series names are decoration rather than authoritative cached project data. Renaming a series does not rewrite assigned projects, and rebuilding the disposable library index resolves the latest name.
