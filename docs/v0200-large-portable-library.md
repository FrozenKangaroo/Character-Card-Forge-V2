# v0.20.0 — Very-Large and Portable Library Architecture

## Virtualized Character Library

The thumbnail grid calculates the visible row range from its scroll position, card
density and current column count. It creates cards only for that range plus a small,
configurable row buffer. Top and bottom spacers retain the full scroll extent, so
filtering, sorting, selection and detail presentation continue to use the complete
lightweight index without creating a Control or loading a texture for every result.

The compact list uses Godot's native drawn item view and does not create one scene node
per row. Library filters, saved views, sensitive-artwork rules, contextual actions and
the v0.19.1 density control remain intact.

## Local thumbnail cache

The existing 320×400 optimized PNG remains the common library derivative. Visible Mini
and Compact cards may create smaller lossy WebP derivatives on demand. Cache filenames
include the active library identity, preventing a project ID shared by two libraries
from displaying the other library's artwork.

A local versioned manifest records size and last-visible access. Configurable maximum
size and unused-age policies remove least-recently-used or expired derivatives. Rebuild
and clear operations are path-bounded to `user://character_card_forge/cache/library_thumbnails`.
Original project artwork is never a cleanup target.

## Portable/shared-folder library

The local library remains the default. **Settings → Library Storage** can explicitly
inspect and initialize an absolute folder. Initialization adds:

```text
Selected Library/
├── .ccf-library.json
└── characters/
    └── <project-id>/
        ├── character.json
        └── assets and managed attachments
```

Switching locations never migrates, merges or deletes data. Settings, indexes and
thumbnail caches stay under the local Godot user-data directory. An open project is
associated with the library from which it was loaded and cannot later be saved into a
different active library; reopen it after switching.

## Write and conflict safety

Project JSON is written to a verified temporary file before replacement. The previous
file is held as a short recovery step and removed only after replacement succeeds.
Portable libraries use a short-lived cooperative lock naming the writer instance. A
content fingerprint captured on load prevents overwriting a file changed by another
writer, even if timestamps are coarse.

This is a **single-writer shared-folder contract**. It reduces accidental concurrent
writes between CCF instances but does not claim distributed locking, collaborative
multi-user editing, merge resolution or automatic cloud sync. If a configured share is
unavailable, CCF reports the condition and does not create it, fall back to the local
library or redirect writes elsewhere.
