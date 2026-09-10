# v0.18.4 Library Workflow, Duplicate and Batch Tools

## Purpose

v0.18.4 extends the existing Character Library without replacing its search, folders,
collections, tags, series, favourites, thumbnail grid or compact list. The new layer is
for organising work, reviewing duplicates and running deliberate actions across several
projects.

## Private workflow data

Each project can store a private Library note and one state: Draft, Needs Review,
Testing, Stable, Published or Archived. Archive removes a project from the normal view
without deleting it; **Show archived** makes it searchable and recoverable again.

Adult and Private are optional presentation markers. They do not alter authored card
content. The local Library policy can show marked cards, hide only their artwork, or
hide their rows. **Explicitly reveal hidden** is required to display rows suppressed by
the Hide policy. These project-level values are not mapped into ordinary Character Card
V2 exports.

## Saved views and recent activity

**Save Smart Collection** stores the current query, workflow/review/token-size/local
Front-Porch-data filters, active tag, favourite flag and Recently Used choice as local
rules. Applying it reruns the rules
against the current index; it is not a copied list of IDs. Recently Used is sorted from
bounded local activity for Library opens, saves, exports, review/deployment handoffs,
validation and group creation, separately from a project's updated timestamp. Aggregate
character and estimated-token statistics are opt-in and apply only to the current view.

## Duplicate review

The duplicate scanner evaluates stable character IDs, normalized authored-card hashes
and artwork hashes before considering normalized name/text similarity. Every match shows
its evidence. Nothing merges, replaces or deletes automatically.

- **Merge** combines project tags/collections/available private notes into the preferred
  project and archives the other project.
- **Replace** keeps the preferred project and archives the other project.
- **Keep Both** and **Ignore** record the author's decision locally.

Matches inside one multi-character project are left for the project workspace; Library
duplicate actions never silently remove one member.

## Batch actions and groups

The existing selection checkboxes now feed one reusable batch layer. Validation uses the
deterministic Card Inspector and reports every character. Export Selected writes portable
`.ccfproject` packages and retains a per-project success/failure report. Character Card
export uses the existing V2 mapper and export-safety gate, with every exported or failed
character named in the report. Tag, collection, folder and series actions continue using
the established Library services.

**Create Multi-Character Project / Group from Selected** copies characters and their
managed character assets into a normal CCF multi-character project, records private
source lineage and creates a standard card workflow with Front Porch group options. It
does not invent a parallel group database or write to Front Porch.

## Quick actions and safety

Right-clicking grid cards or compact-list rows opens the same action set shown in the
detail panel: Open, Export, Review, Front Porch Install/Update, Duplicate/Variation,
Collection, Rename, Show Location, Archive/Restore and Delete. Front Porch and AI Review
actions only open their existing explicit workflows. Batch integrations do not bypass
capability checks, export-safety review, AI approval or revision recovery boundaries.
