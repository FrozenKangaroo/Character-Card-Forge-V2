# v0.18.0-hotfix2 — GitHub Release Update Checks

## User experience

Character Card Forge now has a dedicated **Settings → Updates** tab. It shows the installed/comparison version, the latest published stable GitHub Release, plain-text release notes and the package published for the current operating system.

Packaged builds check automatically at startup when the preference is enabled and the previous check was at least 24 hours ago. The preference is enabled by default and can be disabled independently. **Check Now** remains available regardless of that preference.

When a newer release exists, CCF shows a small sidebar notice. Selecting it opens the Updates tab. The author can review the notes, open the release page or open the exact platform asset in their browser.

## Network and privacy boundary

The checker makes an unauthenticated `GET` request to:

```text
https://api.github.com/repos/FrozenKangaroo/Character-Card-Forge-V2/releases/latest
```

It sends only GitHub's recommended JSON accept header, a CCF user-agent, the pinned REST API version and an optional cached ETag. It does not send:

- Character AI, Vision, Image or Front Porch credentials;
- character cards, worlds, prompts, settings or project data;
- machine identity or a CCF-specific analytics identifier.

Automatic checks are disabled when running the project from the Godot editor/source tree. Developers may use **Check Now** explicitly.

GitHub permits unauthenticated reads of published public releases. CCF checks no more than once per 24 hours automatically, reuses ETags, does not retry rate-limited responses and records the last completed attempt so offline/rate-limited startup does not become a request loop.

## Trusted response boundary

CCF accepts only a non-draft, non-prerelease response with:

- a comparable version tag;
- a release page under this exact GitHub repository;
- download assets under this exact repository's Release download path;
- an uploaded asset whose complete filename matches the release version and current platform.

The response body is capped at 2 MiB. Stored release notes are capped at 16,000 characters and displayed in a non-editable plain-text control, not executable rich text.

Current published packages are selected exactly as:

```text
CharacterCardForge-v<version>-windows-x86_64.zip
CharacterCardForge-v<version>-linux-x86_64.tar.gz
CharacterCardForge-v<version>-macos-universal-unsigned.zip
```

Unknown platforms still receive the release-page link but no guessed package.

## Install boundary

This is an automatic checker with explicit download handoff, not a silent binary replacer. Clicking Download opens GitHub's exact browser download URL. CCF does not:

- overwrite or delete its running executable;
- extract or execute downloaded code;
- write into the installation directory;
- change projects, characters or user settings other than the explicit update-check preference and bounded public-release cache.

The user closes CCF and installs/replaces the downloaded package when ready. Existing projects and settings remain in Godot's normal `user://` data location.

## Version and cache behavior

The comparator supports ordinary numeric versions, prereleases and CCF development hotfix suffixes. Packaged builds compare the synchronized `application/config/version`; editor/source builds use the current development display version so an older public release is never offered as a downgrade.

The cache is stored separately from project data at:

```text
user://character_card_forge/cache/github_update_check_v1.json
```

It contains only the last-check time, ETag and bounded public release metadata.

## Regression coverage

The focused regression verifies version ordering, stable-release filtering, repository-pinned URLs, ETag/304 reuse, rate-limit behavior, exact Linux package selection, settings format 7, the live Updates tab, packaged-only automatic-check capability and the visible sidebar notice.
