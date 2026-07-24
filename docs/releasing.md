# Building and Publishing Releases

Character Card Forge V2 publishes desktop builds from GitHub Actions in:

- Windows x86-64 ZIP
- Linux x86-64 tar.gz
- unsigned macOS Universal ZIP
- `SHA256SUMS.txt`

The source repository is:

```text
https://github.com/FrozenKangaroo/Character-Card-Forge-V2
```

## Requirements for the release operator

- Git and GitHub CLI (`gh`) authenticated for the repository.
- Python 3.
- Godot 4.6.3 available as `godot`, `godot4`, or through `GODOT_BIN` for local engine validation.
- A clean local clone on the `main` branch.

The local helper does not build platform binaries. It validates and pushes the source/tag; GitHub Actions performs the reproducible exports.

## Source-only update

Run:

```bash
./release.sh
```

Choose option `2`. The script validates project metadata and bundled JSON, uses local Godot when available, stages changes, optionally creates a commit, and pushes `main` without making a tag.

## Production release

Run:

```bash
./release.sh
```

Choose option `1`, then confirm the semantic version. The script:

1. synchronises all application-version markers;
2. validates project metadata and runtime JSON;
3. parses the project with local Godot when available;
4. commits outstanding changes;
5. pushes `main`;
6. creates an annotated `vX.Y.Z` tag;
7. pushes the tag to trigger `.github/workflows/release.yml`.

Do not delete or recreate a published release tag. Use a new patch version when a correction is required.

## GitHub Actions release process

The tagged workflow:

1. checks out the exact tag;
2. installs the official Godot 4.6.3 Linux editor and export templates;
3. checks that the tag matches `VERSION`;
4. validates all bundled JSON and version markers;
5. imports and parses the project headlessly;
6. exports all three committed presets;
7. packages the downloads and writes SHA-256 checksums;
8. retains a short-lived workflow artifact for diagnostics;
9. creates the GitHub Release using the repository `GITHUB_TOKEN`.

The repository must allow Actions **Read and write permissions** so the workflow can publish releases.

## macOS unsigned build

The macOS artifact is a Universal 2 application supporting Apple Silicon and Intel Macs, but it is neither Developer ID signed nor notarised.

A user may be able to launch it by right-clicking the app and choosing **Open**. When Gatekeeper still blocks it, the user can remove the downloaded quarantine attribute after extracting the ZIP:

```bash
xattr -dr com.apple.quarantine "Character Card Forge.app"
```

Proper Developer ID signing and Apple notarisation are deferred until a later public-release phase. Signing credentials must never be committed; they would be stored as encrypted GitHub Actions secrets.

## Manual workflow retry

The release workflow supports `workflow_dispatch` with an existing tag. Use this only to rebuild a tag whose GitHub Release was not successfully published. The source at that tag remains immutable.

## Local version tool

To synchronise a version without tagging:

```bash
python3 tools/set_version.py 0.9.2
python3 tools/validate_project.py
```

The version tool updates:

- `VERSION`
- `project.godot`
- `scripts/main.gd`
- `.ccfproject` manifest metadata
- `.ccfseries` manifest metadata
- Windows and macOS export metadata
