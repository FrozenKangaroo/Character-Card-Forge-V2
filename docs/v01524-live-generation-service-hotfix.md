# v0.15.24 — Live Generation Service Hotfix

## Regression

v0.15.22 added `queue_character_generation_with_strategy()` and the Safe Section Build / Fast Full Card strategies, but the running Workspace could still retain the older v0.14.3 generation-service instance. Pressing **Generate Character** then failed before any provider request with:

`Invalid call. Nonexistent function 'queue_character_generation_with_strategy (via call)' in base 'Node (CCFGenerationServiceV0143)'.`

## Fix

- Adds a v0.15.24 Workspace leaf that explicitly verifies the live generation-service instance after inherited startup completes.
- The actual **Generate Character** action checks the strategy-aware service again immediately before delegating to the v0.15.22 Safe/Fast implementation.
- If an older service is present, the existing v0.15.22 installer replaces it and rebinds all generation clients.
- The check is capability-based as well as type-aware: the live service must provide `queue_character_generation_with_strategy` and `diagnostics_available` and retain the v0.15.22 generation-service inheritance chain.
- Adds a v0.15.24 app shell so the fixed Workspace is the runtime default.

## Regression coverage

`tools/test_v01524_live_generation_service.gd` instantiates the actual `scenes/main.tscn`, finds the real live Workspace, and verifies that its `_generation_service` is the strategy-aware v0.15.22 service rather than the older v0.14.3 instance. This closes the gap in the original v0.15.22 test, which tested the new service class directly but did not inspect the service actually installed in the running Workspace.
