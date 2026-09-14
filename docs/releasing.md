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
- Godot 4.7.1 stable available as `godot`, `godot4`, or through `GODOT_BIN` for local engine validation.
- A local clone on the `main` branch at `~/Projects/Character-Card-Forge-V2`, or another location supplied through `CCF_REPO_DIR`.
- `rsync` when running the helper from a separate development project directory.

The local helper does not build platform binaries. It validates and pushes the source/tag; GitHub Actions performs the reproducible exports.

## Development directory and repository sync

The ordinary development project may remain at:

```text
/home/damee/character-card-forge/
```

The Git checkout remains at:

```text
~/Projects/Character-Card-Forge-V2/
```

Run the helper from the development project:

```bash
cd /home/damee/character-card-forge
./release.sh
```

Before showing the release menu, the helper performs a safe additive `rsync` into the checkout and then re-launches itself from the repository copy. It excludes `.git/`, `.godot/`, build/export folders, Python caches, and logs. It does not use `--delete`, so files that exist only in the repository are preserved.

For another checkout location:

```bash
CCF_REPO_DIR=/path/to/Character-Card-Forge-V2 ./release.sh
```

The helper stops before synchronising when the destination is missing, is not a Git repository, is on a branch other than `main`, or has uncommitted changes that the operator declines to overwrite. Running the helper directly inside the Git checkout skips synchronisation.

## Non-publishing preflight

Before a release, run:

```bash
./release.sh --preflight-only
```

This performs the same source, Godot import and complete regression validation used by
the interactive helper, then stops without committing, pushing, tagging or publishing.
For the fast source/release-notes contract alone, run:

```bash
python3 tools/release_readiness_v0204.py
```

Both paths fail when the synchronized version lacks a complete dated section in
`CHANGELOG.md`.

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

1. checks that the proposed remote tag is still unused;
2. synchronises all application-version markers;
3. validates the matching reviewed changelog notes, project metadata and runtime JSON;
4. parses the project with Godot 4.7.1 stable;
5. runs the complete inherited regression profile;
6. commits outstanding changes and pushes `main`;
7. creates an annotated `vX.Y.Z` tag;
8. pushes the tag to trigger `.github/workflows/release.yml`.

Do not delete or recreate a published release tag. Use a new patch version when a correction is required.

## GitHub Actions release process

The tagged workflow:

1. checks out the exact tag;
2. installs the official Godot 4.7.1 stable Linux editor and export templates;
3. checks that the tag matches `VERSION`;
4. validates all bundled JSON and version markers;
5. imports and parses the project headlessly;
6. exports all three committed presets;
7. packages the downloads and writes SHA-256 checksums;
8. verifies the exact three expected package names, non-empty payloads and every SHA-256 checksum;
9. extracts the exact version-matched reviewed section from `CHANGELOG.md`;
10. retains a short-lived workflow artifact for diagnostics;
11. creates the GitHub Release using those reviewed notes and the repository `GITHUB_TOKEN`.

GitHub's automatically generated notes are not used. Each changelog release section
must contain **Highlights**, **Changes**, **Migration notes**, **Breaking changes** and
**Known limitations**, with an explicit `None` where appropriate. This keeps release
communication complete and reviewable before a tag exists.

The repository must allow Actions **Read and write permissions** so the workflow can publish releases.

## macOS unsigned build

The macOS artifact is a Universal 2 application supporting Apple Silicon and Intel Macs, but it is neither Developer ID signed nor notarised. The project must keep `rendering/textures/vram_compression/import_etc2_astc=true`; Godot requires ETC2/ASTC imports for ARM64 or Universal exports. GitHub Actions starts from a clean checkout and imports these textures automatically. After changing this setting in an existing local clone, delete `.godot/imported/` before a manual macOS export so textures are regenerated.

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
python3 tools/set_version.py 0.10.0
python3 tools/validate_project.py
```

The version tool updates:

- `VERSION`
- `project.godot`
- `scripts/main.gd`
- `.ccfproject` manifest metadata
- `.ccfseries` manifest metadata
- Windows and macOS export metadata
