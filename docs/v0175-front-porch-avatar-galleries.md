# v0.17.5 — Front Porch Expressions & Avatar Galleries

v0.17.5 connects Character Card Forge's existing Image Studio results and managed image assets to Front Porch AI's current avatar-gallery model. It supports alternate looks, the complete set of 30 Front Porch expression labels, one canonical favourite, Front Porch-compatible sprite ZIPs and authenticated direct installation.

## Authoring

The **Avatar Gallery** tab in Import / Export accepts either an existing character portrait, an Image Studio result or a manually selected PNG/JPEG/WebP image. The author explicitly assigns each image one role:

- **Alternate Look** for an outfit, pose, location or other user-selected appearance.
- **Expression** with one of Front Porch's exact supported emotion labels.

Image Studio also exposes **Add as Front Porch Look** and **Add as Expression…** on its selected-result actions. This makes AI-generated images and manually supplied images equal inputs to the same saved gallery model. Merely browsing the gallery or assigning a role makes no provider request.

Gallery records live below `characters[].assets.front_porch_avatar_gallery`. Each record has a stable gallery ID, role, optional expression label, managed relative image path, timestamp and provenance. Image Studio sources retain the source image ID plus the credential-safe model, prompt, seed and execution details already stored by the result workflow.

## Explicit image boundaries

These are deliberately separate actions:

1. Add an image to the Front Porch gallery.
2. Mark one gallery image as CCF's canonical Front Porch favourite.
3. Assign a gallery image as the CCF character portrait.
4. Embed selected artwork in an ordinary Character Card PNG.
5. Export an expression ZIP.
6. Install gallery images into a selected Front Porch library character.

Choosing a favourite does not rewrite `assets.portrait`. Removing a gallery role removes only the association; it does not delete the underlying file or its Image Studio result record.

## Portable expression ZIPs

**Export Expression ZIP…** writes a standard ZIP with expression files named using Front Porch's matching contract: `joy.png`, `anger-2.png`, and so on. Files may be inside folders because Front Porch matches the basename. The archive also includes `ccf-expression-pack.json` with a versioned manifest and CCF provenance; Front Porch ignores this non-image entry while CCF and other tools can inspect it.

**Import Expression ZIP…** accepts community/SillyTavern-style packs. A filename is accepted only when its basename is exactly a Front Porch emotion label or begins with that label followed by `-`, `.`, or `_`. For example, `sadness-2.png` is accepted and `sadness2.png` is reported as unrecognised. Imported files are converted to managed PNG assets. Front Porch's 30-expression limit is enforced before new expression entries are added; alternate looks remain a separate collection.

Portable ZIP export contains expressions only. Alternate looks remain portable inside the complete `.ccfproject` package because the common Front Porch sprite-pack importer intentionally recognises emotion-named images, not looks.

## Direct Front Porch installation

After connecting through the existing **Install to Front Porch** tab, the Avatar Gallery tab can refresh the current Front Porch library. The user selects the exact target character and then explicitly chooses **Install Selected Image** or **Install Complete Gallery**.

CCF uses Front Porch 1.3.2+'s supported authenticated web API:

- `GET /api/characters?scope=allCharacters&sort=name`
- `GET /api/characters/<id>/avatars`
- `POST /api/characters/<id>/avatars?label=<emotion>` for expressions
- `POST /api/characters/<id>/looks` for alternate looks
- `POST /api/characters/<id>/favorite?avatarId=<id>` for an explicitly selected favourite

The selected-image favourite checkbox and the local canonical favourite are applied only after the uploaded avatar ID is confirmed in Front Porch's response. Re-running a complete installation creates another gallery set, so the UI states that behaviour before the action.

Passwords, two-factor codes and session cookies remain memory-only. CCF does not open, migrate or write `front_porch.db`, does not change conversations and performs no background synchronisation.

## Compatibility and validation

v0.17.5 is additive. Existing projects without `front_porch_avatar_gallery` load with an empty gallery. Ordinary Character Card V2 JSON/PNG export is unchanged; Front Porch gallery images are not silently embedded into universal card formats that do not define them. Full `.ccfproject` packages already include the referenced managed images.

`tools/test_v0175_front_porch_avatar_galleries.gd` verifies generated-image provenance, independent favourite/portrait actions, portable ZIP export/import, exact Front Porch filename matching, supported API routes/response handling, live v0.17.5 UI wiring and retention of the v0.17.4 shell.
