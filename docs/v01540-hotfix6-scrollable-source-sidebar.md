# v0.15.40-hotfix6 — Scrollable Source Sidebar + Window-Bound Composer Guard

## Runtime finding

Desktop A/B testing narrowed the remaining Collaborator composer disappearance to the Reference Context sidebar rather than the composer itself.

An attachment-only project could survive repeated large-to-small window resizes, while a project with a structured Collaborator source could leave the whole chat/composer layout taller than the native window. Once the composer was below the visible window, enlarging the window again did not reliably restore it; switching projects away and back forced a fuller layout rebuild and recovered the composer.

## Root cause

The original Collaborator UI placed ordinary attachment/context rows inside a `ScrollContainer`, but v0.15.33 inserted the structured Sources panel directly into the outer Reference Context `VBoxContainer`, before and outside that scroll surface. The sidebar and chat panel are siblings in an `HSplitContainer`, so the non-scrollable Sources panel could contribute fixed vertical minimum-height pressure to the whole split.

Hotfix5 correctly made the transcript the chat-side vertical expansion surface, but its visible invariant compared the composer against the chat panel. If the sidebar had already forced that whole split/chat panel below the actual native window, the composer could still be inside its parent while remaining off-screen.

## Hotfix6

- Creates one shared vertical content column inside the existing Reference Context `ScrollContainer`.
- Reparents the structured Sources panel and the ordinary attachment/context list into that shared scroll content.
- Keeps the Reference Context title, general help, and top-level add/import/attach actions outside the scroll surface.
- Clears vertical custom minimum height on the dynamic scroll surface/content so source count and source text cannot set the split's vertical minimum.
- Preserves hotfix3/hotfix4 source row and helper layout guards because the same live source controls are reparented rather than recreated.
- Extends composer validity from chat-panel bounds to the actual Collaborator viewport.
- Treats the old source-panel-outside-scroll architecture as an invalid live layout that the normal visible runtime guard repairs without a project switch.

## Regression contract

The dedicated regression opens the real main scene and real detached Collaborator and exercises two desktop-derived cases:

1. attachment/Vision context only;
2. structured source plus multiple Vision/attachment rows.

Both cases repeatedly resize from large desktop dimensions down to the minimum supported Collaborator size and back. The input, action row, and chat panel must remain within the actual subwindow viewport.

The regression then deliberately recreates the pre-hotfix6 architecture by moving the structured Sources panel back outside the sidebar ScrollContainer. The ordinary runtime/sidebar reconciliation must detect the invalid parent relationship, restore the shared-scroll architecture, and keep the composer visible without switching projects.

## Permanent layout rule

Dynamic Reference Context content belongs under one scroll boundary. Structured sources, source helpers, source rows, attachment cards, and Vision-derived context must not contribute fixed vertical minimum height to the outer `HSplitContainer`. A detached-window composer is considered visible only when it is inside the actual native/subwindow viewport; being inside an oversized parent panel is insufficient.
