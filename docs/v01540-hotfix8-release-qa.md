# v0.15.40-hotfix8 — Release QA + Godot 4.7.1 Gate

## Why this hotfix exists

The first attempted promotion of v0.15.40 exposed release-tooling drift that had accumulated while development moved from Godot 4.6.3 to Godot 4.7.1.

The local `release.sh` run discovered the system `godot` executable first and therefore parsed and regression-tested the project under Godot 4.6.3 even though the active CCF V2 development/CI baseline is Godot 4.7.1 stable. The same release run also defaulted the release prompt to the last synchronised application version (`0.15.9`) instead of the intended v0.15.40 promotion, and exposed an assistant-response compatibility regression whose test printed an error but subsequently overwrote its non-zero exit with `quit(0)`.

## Release engine contract

`release.sh` now treats Godot 4.7.1 stable as a hard release prerequisite.

Resolution order is:

1. explicit `GODOT_BIN` when supplied;
2. `${HOME}/Godot/Godot_v4.7.1-stable_linux.x86_64`;
3. `godot` from `PATH`;
4. `godot4` from `PATH`.

Whichever executable is found must report a version beginning with `4.7.1.stable`. A different engine version now aborts before project import, version commit, push, or tag creation. Missing Godot also aborts rather than silently skipping local engine/regression validation.

The repository never hard-codes a particular username or home directory. The `${HOME}/Godot/...` convention happens to match the current development workstation while remaining portable to other users.

## Release version target

`VERSION`, `project.godot`, package manifests and export presets remain the synchronised metadata for the currently prepared/released application version. Development work must not advance only one of those markers because the normal project validator intentionally rejects partial version drift.

Hotfix8 therefore keeps those existing markers internally synchronised until promotion and gives `release.sh` a separate `DEFAULT_RELEASE_VERSION="0.15.40"`. Option 1 now shows the currently synchronised metadata for context but offers **0.15.40** as the default release choice. `CCF_RELEASE_VERSION` can override that prompt default when intentionally preparing another version.

Once a release version is selected, the existing `tools/set_version.py` atomically updates `VERSION`, `project.godot`, `scripts/main.gd`, project/series package manifest versions and all four platform export version fields before validation, commit, push and tagging.

Development build identity remains separate: the live shell displays `0.15.40-hotfix8`.

## Assistant response compatibility

`CCFGenerationServiceV01310Hotfix._extract_content()` previously called its inherited parser before the newer compatibility parser. For nested content such as:

```json
{"type":"text","text":{"value":"{\"name\":\"C\"}"}}
```

the inherited parser could stringify the `text` wrapper first and return `{"value":"..."}` instead of the actual assistant text.

The compatibility parser now processes known Chat Completions / Responses content structures first. The inherited parser remains as a final fallback for historical provider shapes not explicitly handled by the newer code.

## Fail-closed regression behaviour

`tools/test_assistant_response_shapes.gd` now records any failed expectation and refuses to issue the final success `quit(0)` after a failure. The previous test could call `quit(1)` from `_fail()` and then continue far enough to call `quit(0)`, making the broad suite report success despite a visible assertion error.

## Regression coverage

Hotfix8 adds:

- `tools/test_v01540_hotfix8_release_qa.sh` for synchronised release metadata, the v0.15.40 release prompt target, engine-gate, shell wiring, active-shell and parser-order invariants;
- `tools/regression_suites_v01540_hotfix8.json` as the new default broad regression manifest;
- dedicated Godot execution of `tools/test_assistant_response_shapes.gd` under the 4.7.1 CI environment;
- `.github/workflows/validate-v01540-hotfix8-release-qa.yml`;
- continued hotfix7 Vision Diagnostics, hotfix6 sidebar/composer, updater and Forward+ checks.

## Compatibility

Hotfix8 does not change user project/card formats or provider settings. It retains all hotfix7 diagnostics safety, hotfix6 Collaborator resize/sidebar fixes, Character Card metadata + Vision ingestion, UserPersona exclusion, concurrent AI scheduling, Image Studio behaviour and existing authoring workflows.
