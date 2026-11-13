# v0.21.18 Workspace density and Recent projects

Two authoring surfaces were spending space on information the author already
had. Both changes are presentation-only; no project, character, template or
Front Porch data moves.

## Collapsible project setup

The Workspace header used to show project name, series, active character, group
role, template and the project-level action buttons on every screen. They
occupied roughly a third of a 1440 × 810 window, leaving room for a single
Front Porch field before scrolling.

- The rows now sit in one **Project setup** block behind a single toggle.
- Loading a project collapses the block automatically and the header keeps the
  project and character name in its title, plus the active template in the
  toggle bar.
- Expanding the block restores exactly the previous controls, unchanged.
- The author's explicit choice is remembered for the rest of the session, so a
  later project load does not collapse it again.
- With no project loaded the block stays expanded, because that is where a new
  project is named.

No field editor, tab or window changed position inside the tab area.

## Recent projects order

The Library index is written in directory order. The Home dashboard showed the
first five rows of that index and labelled them "Recent projects", so a newer
project could appear below an older one or miss the list entirely.

- `CCFDashboardView.recent_rows()` sorts by `updated_at` descending, falls back
  to `created_at`, and sorts undated rows last.
- Ties break by name so the order is stable between refreshes.
- The result is a copy; the shared index rows are never reordered in place.
- Timestamps render as `YYYY-MM-DD HH:MM` instead of raw ISO text with
  fractional seconds and a trailing `Z`.
