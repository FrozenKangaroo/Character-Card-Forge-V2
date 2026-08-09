# v0.15.40-hotfix9 — Interrupted Release Metadata Recovery

## Runtime symptom

An interrupted `release.sh` run can leave the six files written by `tools/set_version.py` modified even though no release was successfully completed:

- `VERSION`
- `export_presets.cfg`
- `project.godot`
- `scripts/main.gd`
- `scripts/services/project_package_service.gd`
- `scripts/services/series_service.gd`

The existing updater only had a narrowly-scoped exception for a single unstaged `project.godot` drift. The generated six-file release metadata bundle therefore caused `bash update.sh` to stop with the normal local-changes protection message.

## Recovery rule

`update.sh` now recognises this exact interrupted-release state without weakening its general fail-closed policy.

The updater only auto-clears the bundle when all of the following are true:

1. the checkout is on `main`;
2. there are no untracked files;
3. the complete tracked dirty set is exactly the six release metadata paths;
4. `VERSION` contains a candidate version accepted by the checked-in `tools/set_version.py`;
5. each working-tree file byte-for-byte matches what that exact checked-in version synchroniser would generate from `HEAD` for the candidate version;
6. any staged copy is either unchanged from `HEAD` or byte-for-byte identical to the same generated result.

The check reconstructs clean `HEAD` copies in a temporary directory, runs the checked-in version synchroniser there, and compares the generated result to the real working copy. It does not guess based only on filenames.

When the invariant passes, the six generated files are restored from `HEAD` before the normal fetch/fast-forward. The abandoned release candidate is intentionally not reapplied after updating because it was temporary release tooling output rather than authored project data.

## Safety boundary

The updater still refuses to proceed when:

- one of the six metadata files contains additional manual edits;
- an unrelated tracked file is changed;
- an untracked file exists;
- staged content differs from the reproducible generated metadata;
- the dirty path set is only a partial version bundle;
- the candidate cannot be reproduced by the checked-in `set_version.py`.

The historical single-`project.godot` preservation path remains intact and continues to use a temporary stash when that is the only local unstaged change.

## Regression coverage

`tools/test_update_sh_release_metadata.sh` uses temporary real Git repositories to cover:

- exact unstaged interrupted release metadata recovery;
- exact staged interrupted release metadata recovery;
- rejection of a metadata bundle containing an extra manual edit;
- rejection when generated metadata coexists with unrelated local work.

The active development shell displays `v0.15.40-hotfix9`.
