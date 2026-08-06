# v0.15.38 — Scalable Image Studio Character Picker + Warning Cleanup

## Why this change

Image Generation Studio previously exposed one Project `OptionButton` followed by one Character `OptionButton`. That is usable with a small library, but it scales poorly once an author has dozens or hundreds of projects/characters: locating one character becomes a long two-stage dropdown hunt.

v0.15.38 makes the character the primary selection target. Project membership remains visible context, but the user no longer has to locate the project first.

## Searchable Character picker

The visible Project and Character dropdowns are replaced by one compact **Character** control showing the current selection as:

`Character Name — Project Name`

Clicking it opens **Choose Character for Image Studio** with an instant search box and a bounded result list.

Search operates on the existing lightweight Library project rows and their embedded character summaries. The picker does not load every full project merely to build its search index.

The searchable fields include:

- Character name
- Project name
- Character role
- Character tags
- Project tags
- Series ID
- Library folder
- Library collections
- Creator/version metadata where present

Exact contiguous phrase matches are preferred when they exist, so searching a full character or project name does not become noisy merely because its individual words appear elsewhere. If there is no phrase match, the picker falls back to AND-style multi-term matching, so queries such as `series-07 folder-04` can still progressively narrow a large library.

Each result is displayed as `Character — Project`, with role information when available. The tooltip exposes additional project/tag/series/folder/collection context.

## Large-library behaviour

The picker deliberately does not render an unlimited number of rows at once.

- Up to 250 matching rows are rendered.
- If more than 250 characters match, the status reports the full match count and asks the user to narrow the query.
- Filtering still runs over the complete lightweight index, so a character outside the first 250 unfiltered entries remains directly searchable.

The v0.15.38 regression uses 540 synthetic characters and verifies that a character beyond the initial visible cutoff can still be found directly.

## Compatibility

The inherited Project and Character `OptionButton`s remain alive but hidden. Existing Image Studio code still uses them as compatibility backing state for project/character refresh, gallery ownership, Workspace synchronisation, and inherited callbacks.

The v0.15.38 Image Studio layer explicitly extends the v0.15.31 Image Studio controller rather than jumping directly to v0.15.30. This preserves the shared **AI Jobs** inspection and selective-cancellation contract (`ai_job_records_v01531` / `cancel_ai_job_v01531`) while adding the new picker. A regression now guards that inheritance boundary because skipping it can make Image Studio jobs disappear from the shared AI Jobs panel even though generation itself still works.

Selecting a search result:

1. Loads that saved project.
2. Selects the exact requested character rather than only the project's active character.
3. Synchronises the hidden compatibility selectors.
4. Refreshes the gallery and passive prompt scope.
5. Updates the compact picker label.

An explicit picker choice clears the temporary Workspace-preferred source hint so a later refresh does not unexpectedly jump back to the character that happened to be active when Image Studio first opened.

A freshly saved in-memory Workspace project can still participate in the picker before a platform directory listing has reflected its folder, preserving the v0.15.28 live-save behaviour.

## Provider-cost boundary

Character selection remains passive. Opening the picker, filtering it, and switching characters do not call Text, Vision, or Image providers.

**Generate Prompt from Character** remains the explicit Character Text-role action, and **Generate** remains the explicit Image-provider action.

## Warning cleanup

v0.15.38 also fixes the three Godot 4.7.1 warnings reported during normal application startup without suppressing warning categories:

- `collaborator_refinement_compare_window_v01536.gd`: `_submit_v01536(mode)` is renamed to `_submit_v01536(apply_mode)` so it no longer shadows `Window.mode`.
- `character_collaborator_window_v01537_sources.gd`: saved-Idea local `title` is renamed to `idea_title` so it no longer shadows `Window.title`.
- `generation_service_v01537_hotfix1.gd`: the output-group `returned_keys` local is renamed to `group_returned_keys`, avoiding the confusable declaration with the later standalone-field block.

The dedicated CI import gate treats `SHADOWED_VARIABLE_BASE_CLASS` and `CONFUSABLE_LOCAL_DECLARATION` as failures.

## Regression coverage

`tools/test_v01538_image_studio_character_picker.gd` verifies:

- 540 lightweight character rows can be indexed;
- an empty query renders at most 250 rows;
- a character beyond that cutoff remains searchable by name;
- project-name search returns the project's characters without unrelated term-only collisions when an exact phrase match exists;
- role, tag, series, folder, and collection search work;
- the current main scene installs the v0.15.38 Image Studio controller;
- the v0.15.38 controller retains the v0.15.31 AI Jobs inheritance layer;
- the old Project/Character dropdowns are hidden;
- the searchable picker button/dialog exist in the live controller.

Dedicated CI additionally rechecks the v0.15.28 live Image Studio state, v0.15.29 embedded/AI-prompt behaviour, v0.15.30 prompt wrapping, v0.15.31 AI Jobs compatibility, v0.15.37 Multi-source Collaborator, v0.15.37-hotfix1 Safe Section contamination guard, Forward+, checkout cleanliness, and the quick broad regression profile.
