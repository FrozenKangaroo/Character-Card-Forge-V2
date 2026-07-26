# Release Checklist

## Before tagging

- [ ] Keep the Git checkout on the `main` branch.
- [ ] Run `release.sh` from the development project and review the displayed source/destination paths.
- [ ] Confirm the destination checkout has no unexpected uncommitted changes before approving a sync.
- [ ] Pull the latest `origin/main` and resolve any changes.
- [ ] Confirm the application launches in Godot 4.6.3.
- [ ] Confirm no Godot warnings are being treated as errors.
- [ ] Open Settings and confirm Text and Vision provider role selectors retain their saved profiles.
- [ ] Add, edit, and remove a note attachment at both project and character scope.
- [ ] Import a small image and text attachment and confirm their managed paths/context summary.
- [ ] When a vision-capable model is available, confirm analysis opens Generation Preview without directly applying fields.
- [ ] Update `CHANGELOG.md` and `roadmap.md`.
- [ ] Run `python3 tools/validate_project.py`.
- [ ] Confirm ETC2/ASTC texture import remains enabled for the Universal macOS preset.
- [ ] Confirm the GitHub **Validate Godot project** workflow is green on `main`.

## Create the release

- [ ] Run `./release.sh`.
- [ ] Choose option `1`.
- [ ] Confirm the intended semantic version.
- [ ] Allow the script to push `main` and the annotated version tag.

## Verify GitHub Actions

- [ ] The Windows export completes.
- [ ] The Linux export completes.
- [ ] The unsigned Universal macOS export completes.
- [ ] Packaging and SHA-256 generation complete.
- [ ] A GitHub Release is created for the exact tag.

## Verify release assets

- [ ] `CharacterCardForge-vX.Y.Z-windows-x86_64.zip`
- [ ] `CharacterCardForge-vX.Y.Z-linux-x86_64.tar.gz`
- [ ] `CharacterCardForge-vX.Y.Z-macos-universal-unsigned.zip`
- [ ] `SHA256SUMS.txt`
- [ ] Windows launches on a clean test machine or VM.
- [ ] Linux executable retains its executable permission and launches.
- [ ] macOS unsigned instructions are visible to testers.

## After publication

- [ ] Do not delete or move the published tag.
- [ ] Record discovered release issues in the roadmap/changelog.
- [ ] Use a new patch version for corrections.
