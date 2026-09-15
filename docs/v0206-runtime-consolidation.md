# v0.20.6 Runtime Consolidation Phase 1

v0.20.6 begins the pre-1.0 technical consolidation sequence with the application shell.
The change is intentionally narrow: Help Center, Support & Diagnostics and current-build
presentation move into one semantically named runtime layer, while Workspace, Library,
generation, Image Studio and their compatibility chains remain untouched.

## Previous runtime shape

The v0.20.5 main scene loaded `main_v0205.gd`. Its complete inheritance chain contained
132 scripts. The four most recent historical layers were:

1. `main_v0205.gd` — manual release label;
2. `main_v0204.gd` — release-readiness label;
3. `main_v0203.gd` — Help Center composition;
4. `main_v0202.gd` — Support & Diagnostics composition.

Those files remain in the repository as historical compatibility and regression evidence.
They are no longer part of the active scene's inheritance path.

## Current runtime boundary

`scenes/main.tscn` now loads `scripts/main_current.gd`, which directly extends the stable
v0.20.1 shell boundary. The current layer owns:

- permanent Support & Diagnostics navigation and Quick Action routing;
- permanent offline Help Center navigation and Quick Action routing;
- the current build label and update-comparison version;
- the actual version passed into privacy-safe support reports.

This produces an active depth of 129 scripts, three fewer inheritance hops than v0.20.5.
Future ordinary version bumps update the semantic current layer rather than adding a new
`main_v...gd` shell.

## Measurement and safety

`tools/runtime_inheritance_report_v0206.py` traces the scene's real inheritance path and
fails on missing files, cycles, a changed consolidation boundary, reactivated historical
layers or a lost depth reduction. It does not modify project files.

The v0.20.6 regression pair verifies both sides of the migration:

- static structure, preserved history and measured 132-to-129 depth reduction;
- live Godot navigation, Help catalog availability, Quick Action routing and current
  v0.20.6 support-report identity.

The complete inherited release profile remains mandatory before the next subsystem is
considered for consolidation.
