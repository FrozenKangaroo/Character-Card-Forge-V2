# v0.16.10 — Studio Workflow & Results Polish

v0.16.10 turns Image Studio's generated-image gallery into a reusable result workflow while keeping all project changes explicit.

## Complete result provenance

New result records preserve a versioned execution snapshot containing the exact composed prompt, negative prompt, provider/profile identity, model, size, prompt style, sampler, steps, CFG, actual seed, batch size, additive provider parameters and v0.16.8 image-input settings. Credentials and request headers are never copied into project history.

Older gallery records remain usable. The result service derives a conservative legacy snapshot from their existing fields when no v0.16.10 snapshot is present.

## Result actions

- **Reuse Settings** restores the selected result into Studio without making a provider request.
- Existing **Regenerate** now restores the full snapshot and retains its seed.
- Existing **New Seed Variant** restores the full snapshot, then requests a provider-selected seed.
- **Favourite / Unfavourite** persists lightweight additive metadata and marks favourites in the gallery.
- **Set Compare A**, **Set Compare B** and **Compare** provide a side-by-side provenance/settings summary without modifying either result.
- Batch results retain their own actual seed and shared request settings, so each image can be reused independently.

## Asset assignment and recovery

The existing explicit **Set as Character Portrait** assignment remains the canonical character-image action. If a gallery record's managed file is missing, **Recover Missing File** can copy a replacement PNG/JPEG/WebP into the character's managed generated-image folder and relink the record. Recovery never silently guesses a file.

## Optional cost information

If normalized provider metadata contains an explicit numeric `cost_per_image`, `price_per_image` or `per_image` value, Studio shows a batch estimate in the provider's declared currency. It does not infer prices from ambiguous metadata. Local providers and providers without pricing metadata continue to work normally and show that no estimate is available.

## Compatibility and safety

- Existing v0.16.9 style presets remain creative-only and separate from execution snapshots.
- Existing projects and legacy gallery records require no migration.
- Reuse, favourites and comparison make no provider calls.
- Recovery requires explicit file selection and copies into managed project storage.
- Public release metadata remains v0.15.40 during the v0.16.x development line.
- Godot remains 4.7.1 stable with Forward+ and Compatibility/OpenGL fallback.
