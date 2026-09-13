# v0.20.0-hotfix1 Library Panel Controls

The Character Library now gives the card area priority without removing access to
filters, project organization or details.

## Layout controls

- The left **Library Filters** panel and right **Project Details** panel each have a
  slim edge-arrow control that remains visible while its panel is collapsed.
- A compact **Panels** menu controls Filters, the existing Project Tools section and
  Details from one place.
- **Show all panels** restores the complete workspace. **Focus card area** collapses
  both side panels and Project Tools in one action.
- Manual visibility, Project Tools visibility and card density persist between app
  sessions.

## Optional auto-hide

**Auto-hide side panels** is off by default. When enabled, both side panels begin
collapsed. Hovering an edge arrow temporarily reveals that panel; returning to the
central card area collapses temporary side panels after the click completes. This
avoids moving controls under the pointer during the original click.

Auto-hide affects only the two side panels. Project Tools retains its explicit
show/hide control so menus and batch operations are never dismissed while in use.
