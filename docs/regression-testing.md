# Character Card Forge Regression Testing

Character Card Forge has a large inherited feature surface. A new feature can work correctly while accidentally disconnecting or changing an older workflow, so regression coverage is treated as a release requirement rather than an optional manual checklist.

## Broad regression profiles

The regression registry is versioned and composable. `tools/regression_suites_v01520.json` remains the broad baseline introduced in v0.15.20, while later manifests such as `tools/regression_suites_v01521.json` inherit that baseline and append representative tests for newly supported major features.

The resulting merged registry groups representative tests by user-facing area:

- current live wiring
- core project/data behaviour
- generation and template contracts
- authoring workflows
- content/library/lorebook/graph workflows
- Character Collaborator
- image and Vision workflows
- update/release workflow safety

This keeps the registry data-driven without copying the entire historical test list into every patch release.

## Run locally

Quick representative pass while developing:

```bash
python3 tools/run_regression_suite.py --profile quick
```

Full release representative pass:

```bash
python3 tools/run_regression_suite.py --profile release
```

A single area can also be run directly:

```bash
python3 tools/run_regression_suite.py --suite collaborator
python3 tools/run_regression_suite.py --suite generation
```

List available profiles and suites:

```bash
python3 tools/run_regression_suite.py --list
```

Use `--godot /path/to/godot` when Godot is not available as `godot` or `godot4` in `PATH`.

## User-data isolation

The regression runner creates temporary HOME/XDG/AppData directories for every run. This is important because several tests deliberately exercise `user://` persistence. Running the regression suite must never overwrite the author's real saved Character Collaborator chats, FileDialog state, settings, or other app-local data.

The temporary test data is deleted when the run finishes.

## Release gate

`release.sh` automatically runs the full `release` regression profile after project validation/import whenever Godot is available locally. A failed representative regression prevents the release script from reaching commit/tag creation.

GitHub Actions also runs the same broad release profile on every pull request and on `main`, so a new feature is checked against unrelated major workflows even when manual testing is focused only on that new feature.

## Adding a major feature

When a new major feature becomes part of the supported app surface:

1. Add or extend a focused regression test for the feature.
2. Add a new versioned manifest layer that inherits the current registry and appends the representative test to the appropriate suite.
3. Advance `DEFAULT_MANIFEST` in `tools/run_regression_suite.py` to the new manifest layer.
4. Prefer testing the current live service/workspace composition rather than only instantiating an isolated historical helper.
5. Make historical shell/version tests inheritance-aware where later versions are expected to extend them.
6. Keep tests deterministic and offline; provider calls should be mocked, inspected, or validated at the request/response boundary rather than requiring live API credentials.

The broad suite is not intended to replace focused tests. It is a cross-feature release gate that makes it much harder for development focus on one area to hide regressions somewhere else.
