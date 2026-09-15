# v0.20.7 Runtime Consolidation Phase 2 — Generation Service

v0.20.7 continues the pre-1.0 technical consolidation sequence with the shared
generation service. The change is intentionally narrow: AI Review, Compact/Lite
derivatives, Split Character Sets and task-specific Text profile routing move into one
semantically named runtime layer. Workspace, Library, Image Studio and their other
compatibility chains remain untouched.

## Previous runtime shape

The v0.20.6 Workspace created isolated AI workers from
`generation_service_v0195.gd`. Its complete inheritance chain contained 34 scripts.
The four recent historical layers being consolidated were:

1. `generation_service_v0195.gd` — task-specific Text routing and visible fallback;
2. `generation_service_v0190.gd` — Split Character Set jobs;
3. `generation_service_v0186.gd` — Compact/Lite derivative jobs;
4. `generation_service_v0183.gd` — AI Review jobs.

Those files remain in the repository as historical compatibility and regression
evidence. They are no longer part of the active Workspace worker's inheritance path.

## Current runtime boundary

`scripts/ui/workspace_v0195.gd` now creates
`scripts/services/generation_service_current.gd`, which directly extends the stable
v0.18.0-hotfix1 generation boundary. The current layer owns:

- AI Review queueing and review metadata;
- Compact/Lite derivative queueing and source-lineage metadata;
- Split Character Set parent/member queueing and partial-retry behavior;
- Primary, Fast, Deep Review and Fallback Text routing;
- bounded fallback eligibility, failure classification and visible routing metadata.

This produces an active generation-service depth of 31 scripts, three fewer inheritance
hops than v0.20.6. Future ordinary generation-service changes update the semantic
current layer rather than adding a new `generation_service_v...gd` layer.

## Compatibility contract

The consolidation preserves existing public signals, method signatures, job record
shapes, accepted-result metadata, actual producer provenance and failure categories.
Fallback remains explicit, bounded and visible. It does not add provider calls, change
provider selection or migrate stored project data.

## Measurement and safety

`tools/generation_inheritance_report_v0207.py` traces the active service's real
inheritance path and fails on missing files, cycles, a changed consolidation boundary,
reactivated historical layers or a lost depth reduction. It does not modify project
files.

The v0.20.7 regression checks verify both sides of the migration:

- static structure, preserved history and measured 34-to-31 depth reduction;
- live Godot queue behavior for all four consolidated responsibilities;
- equivalence with the historical v0.19.5 task-routing and failure-classification
  contract.

The complete inherited release profile remains mandatory before another subsystem is
considered for consolidation.
