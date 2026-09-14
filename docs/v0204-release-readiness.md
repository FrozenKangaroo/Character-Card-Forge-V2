# v0.20.4 Deterministic Release Readiness

v0.20.4 hardens the source-to-release path so a tag cannot silently publish mismatched
metadata, incomplete notes or an unverified platform package set.

## Reviewed release notes

`CHANGELOG.md` is now the canonical release-note source. The current `VERSION` must have
one matching dated section with non-empty **Highlights**, **Changes**, **Migration
notes**, **Breaking changes** and **Known limitations**. The tagged GitHub workflow
extracts only that version's section and passes it to GitHub Releases. Generated release
notes are no longer used. When several development candidates accumulated after the
last public release, the reviewed section summarises that complete range rather than
describing only the final tooling commit.

## Source preflight

`tools/release_readiness_v0204.py` verifies:

- semantic version and optional tag agreement;
- the complete matching changelog section;
- reviewed-note publishing in the tagged workflow;
- release-helper and checksum-package wiring;
- the exact expected versioned platform package names.

`release.sh --preflight-only` adds the normal project validation, Godot 4.7.1 stable
import and complete inherited regression profile, then exits without changing remote
state. The interactive release path runs the same checks before commit, push or tag.

## Package preflight

After GitHub Actions exports and packages the app, the same tool verifies that `dist/`
contains exactly:

- Windows x86-64 ZIP;
- Linux x86-64 tar.gz;
- unsigned macOS Universal ZIP;
- `SHA256SUMS.txt` with one matching SHA-256 entry for each package.

Every package must be non-empty and match its recorded checksum. GitHub Release creation
cannot begin until this check passes.

## Fail-closed boundaries

- A remote tag collision is checked before the release commit is pushed to `main`.
- Missing or incomplete release notes stop local and hosted release paths.
- A missing, extra, empty or modified platform package stops publication.
- The local default version follows synchronized `VERSION` metadata rather than the
  historical v0.15.40 default.
- Existing update discovery and package naming remain compatible.
