# v0.15.28 Image Studio Live State

v0.15.28 fixes the boundary between the saved Workspace, Image provider settings, and the detached Image Studio window.

## Saved project handoff

Workspace Save now sends the saved project snapshot directly to Image Studio. Image Studio does not have to wait for an application restart or depend only on a fresh directory scan before it can show the project.

When Image Studio opens, it prefers the current saved Workspace project and active character. **Reload Projects** still performs a disk rescan, reports how many projects were found, and preserves the preferred project selection where possible.

The saved in-memory project snapshot is allowed to fill the dropdown immediately when the platform directory listing has not reflected the new project folder in the same frame. The project remains an ordinary saved CCF project; unsaved Workspace edits are not silently transferred.

## Prompt building

**Build Prompt from Character** remains a local deterministic transformation of the selected character data. It does not call the Character Text generation pipeline.

It now reports a visible reason when it cannot run:

- no saved project is selected;
- no active character exists;
- the selected character no longer exists in the project;
- the selected character contains no usable visual/character source material.

## Image profile separation

Image Studio now enumerates `image_profiles` and resolves the selected profile through `CCFSettingsService.image_profile_by_id()`.

Character Text/Vision `api_profiles` are no longer shown in the Image Studio provider dropdown and are no longer modified by **Save Image Defaults**.

## Persistent discovery

Model/checkpoint and sampler discovery is stored per Image provider profile under a normalised `discovered_capabilities` record.

Discovery run from either location updates the same cache:

- Settings → Image Generation → **Test / Discover**;
- Image Studio → **Discover Models / Samplers**.

Cached lists are restored when the Image profile is selected again and survive view changes and application restarts. Settings emits the updated settings immediately so an already-created Image Studio window refreshes without needing to close and reopen the app.

## Compatibility

The scheduler-aware Image generation service from v0.15.26 remains installed. The v0.15.28 window only corrects project/provider state and discovery persistence; it does not bypass the configured Image concurrency limits or generation queue.
