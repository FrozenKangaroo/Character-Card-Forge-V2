# Changelog

## 0.9.3

### Fixed

- Enabled `rendering/textures/vram_compression/import_etc2_astc` so Godot can export the Universal macOS preset containing Apple Silicon ARM64 support.
- Extended release validation to reject a universal/ARM64 macOS configuration when ETC2/ASTC texture import is disabled, catching this before the export step.
- Preserved the Windows, Linux, and unsigned macOS release workflow and all v0.9.2 application features unchanged.

### Release note

- GitHub Actions performs a clean import, so the newly enabled texture format is generated automatically. Local clones that previously imported textures may delete `.godot/imported/` before a manual macOS export to force reimport.

## 0.9.2

### Added

- Committed Godot export presets for Windows x86-64, Linux x86-64, and unsigned Universal macOS builds.
- GitHub Actions validation on pushes, pull requests, and manual runs using the official Godot 4.6.3 editor and export templates.
- Tag-triggered release workflow that validates, exports, packages, checksums, and publishes all three desktop builds.
- Windows ZIP and Linux tar.gz packaging plus `SHA256SUMS.txt` generation.
- Godot-native `release.sh` with source-only and production-release paths.
- `tools/set_version.py` for synchronising runtime, project, package-manifest, and export-preset versions.
- `tools/validate_project.py`, `tools/setup_godot_ci.sh`, and `tools/package_release.sh`.
- Release documentation and checklist.

### Changed

- The official source/release target is now `FrozenKangaroo/Character-Card-Forge-V2`.
- Published version tags are treated as immutable; corrections use a new patch version instead of deleting release history.
- macOS builds are explicitly labelled unsigned and unnotarised.

### Compatibility

- Application features and internal data formats remain unchanged from v0.9.1.
- Character project format remains version 2; series and portable package format versions remain version 1.

## 0.9.1

### Fixed

- Wired assigned-series context into Idea Generator prompts, resolving the unused `series_context` parameter while making generated concepts continuity-aware.
- Renamed local and parameter identifiers named `remap` in project-package imports to avoid shadowing Godot's built-in `remap()` function.
- Added explicit `FileDialog.FileMode` enum casts in the Import / Export Studio and Series Manager dialog builders.
- Removed all six reported Godot 4.6 warnings when warnings are treated as errors.
- Updated `.ccfproject` and `.ccfseries` manifests to identify application version `0.9.1`.

### Compatibility

- All v0.9.0 Series System features and data formats remain unchanged.
- Character project format remains version 2; series and project package format versions remain version 1.

## 0.9.0

### Added

- Native **Series Manager** main workspace with create, edit, save, duplicate, delete, search, usage counts, JSON import/export, and multi-select Series Pack export.
- Standalone versioned series JSON definitions stored under `user://character_card_forge/series/`.
- Series fields for name, aliases, description, categories, setting guidance, canon notes, visual direction, generation rules, default tags, and matching keywords.
- AI-assisted series-bible generation and improvement through the existing queued OpenAI-compatible text service.
- Project-level Series selector, Auto Series matching, Apply Series Tags, and Manage Series controls in the Character Workspace.
- Deterministic local Auto Series scoring across series names, aliases, keywords, categories, and project tags, with ambiguous ties left unapplied.
- Series and Unassigned filters in Character Library 2.0.
- Bulk library actions for series assignment, clearing, Auto Series matching, and default-tag application.
- Series display in library grid cards, compact rows, project details, search results, recent-project buttons, and Dashboard statistics.
- Assigned-series guidance in full generation, field suggestions, Controlled Build, Character Builder, Group Scene Generator, Relationship Matrix generation, and Card Workflow Studio planning.
- Portable `.ccfseries` renamed-ZIP packs with versioned manifests and collision-safe import ID remapping.
- Assigned-series inclusion and collision remapping in portable `.ccfproject` packages.
- CCF series-reference round trips through the namespaced `character_card_forge/v1` Character Card V2 extension.
- `docs/series_system.md` and `docs/series_format.md`.

### Changed

- Library index format advanced to version 2 to add series-aware filters and display metadata while keeping the index disposable.
- The library cache now stores undecorated base project rows and resolves current series names during refresh, preventing renamed series names from accumulating in cached search text.
- User-data directory creation now includes the standalone `series/` directory.
- Dashboard statistics now include local series count.
- `.ccfproject` manifests now identify application version `0.9.0` and the included series ID.

### Compatibility

- Character project format remains version 2; existing projects simply remain unassigned until a series is chosen.
- Missing or deleted series IDs remain visible and repairable instead of being silently erased.
- Series definitions are adapters and shared guidance, not a replacement character database.
- Compatibility with the original legacy PyWebView database remains intentionally out of scope.

## 0.8.1

- Fixed a Godot parse error in `card_format_service.gd` by changing the PNG signature from a constructor-backed constant to an explicitly typed static `PackedByteArray`.
- Swept the script constants for other runtime-constructor initialisers; no additional instances were found.

## 0.8.0

### Added

- Character Library 2.0 with thumbnail-grid and compact-list browsing modes.
- Disposable project index that fingerprints each `character.json`, reuses unchanged rows, and rescans only new or edited projects.
- Disposable portrait-thumbnail cache with source-image modification checks, full rebuild support, and stale-thumbnail cleanup.
- Rich search across project names, character names, summaries, card text, creators, versions, roles, tags, folders, collections, and recorded interoperability metadata.
- Sorting by updated time, created time, name, character count, and favourites.
- Favourites-only, virtual-folder, collection, tag, and unfiled filters.
- Project detail panel with portrait, organisation metadata, import-format summary, and per-character details.
- Multi-project selection in both grid and list modes.
- Bulk favourite, tag, virtual-folder, collection, and delete actions.
- Library-wide case-insensitive tag merging with duplicate collapse across project and character metadata.
- Remembered library view, sorting, and organisation-filter preferences.
- `docs/character_library.md`.

### Changed

- Project metadata now includes additive `metadata.library.folder` and `metadata.library.collections[]` fields.
- Character/project library rows are generated through `storage_service.gd`, while cache management and library mutations live in the dedicated `library_service.gd`.
- Dashboard project and character totals now reuse the incremental library index.
- The old basic project list has been replaced by a responsive three-pane management workspace.

### Compatibility

- Existing format-v2 projects receive empty library-organisation defaults during normalisation; no migration or database conversion is required.
- `character.json` remains authoritative. Deleting `library_index.json` or `library_thumbnails/` only removes rebuildable cache data.

## 0.7.1

### Fixed

- Replaced a `Dictionary.get()`-derived workflow instruction local in `generation_service.gd` with an explicitly typed `String` selected through `match`.
- Removed the Godot 4.6 `INFERRED_DECLARATION` warning at the former line 715 when warnings are treated as errors.
- Updated portable `.ccfproject` manifests to report application version `0.7.1`.

### Compatibility

- No project, template, card, package-format, or database migration is required.
- Import/export behaviour and generated prompt text remain unchanged.

## 0.7.0

### Added

- Detachable native **Import / Export Studio** with Export Card, Import Card, Portable Project, and Batch Export workflows.
- Character Card V2 JSON export for the active character, including the full standard V2 field set used by CCF.
- Character Card V2 JSON import into a fresh clean CCF project.
- Legacy Character Card V1 JSON detection and normalisation into the V2-backed CCF mapping.
- PNG/APNG Character Card metadata reader for embedded `chara` data.
- PNG Character Card writer that copies an existing image and replaces/adds its V2 `chara` metadata chunk.
- Export compatibility preview showing direct mappings, preserved data, and CCF-only namespaced fields before writing a card.
- Round-trip preservation for unknown V2 extension data, alternate greetings, embedded character lorebooks, creator metadata, and character-version metadata.
- A namespaced `character_card_forge/v1` extension carrying template-specific and CCF-only round-trip data.
- `creator` and `character_version` fields in the default template's Advanced section.
- `.ccfproject` portable project packages containing a versioned manifest, current project JSON, project assets, and referenced custom templates.
- Safe package import with fresh project UUIDs, relative-path validation, and custom-template ID collision remapping.
- Batch Character Card V2 JSON export using saved Split-card batch workflows.
- `docs/import_export.md` and `docs/project_packages.md`.

### Changed

- Character project records now retain `alternate_greetings`, `character_book`, and raw `card_extensions` as first-class interoperability data without changing project format version 2.
- External card formats remain adapters around the CCF project model rather than becoming CCF's persistence format.
- Imported PNG card images are copied into the new character's asset directory and assigned as the initial portrait reference.
- Card Workflow Studio's split-card planning now has a concrete batch-export destination.

### Compatibility

- Existing format-v2 CCF projects receive empty interoperability defaults during normalisation and do not require migration.
- Original legacy PyWebView database compatibility remains intentionally out of scope.

## 0.6.0

### Added

- Structured project-level Relationship Matrix with one canonical record per character pair.
- Relationship fields for label, status, intensity, tags, shared summary, directional A → B and B → A perspectives, evolving dynamic, and private notes.
- Detachable native Relationship Matrix window showing every possible pair while storing only meaningful relationship records.
- AI-assisted relationship generation across any selected set of two or more characters.
- Review-first AI relationship workflow: generated pairs populate the local matrix and are not applied automatically.
- Relationship context injection into full-character generation, per-field suggestions, Controlled Build, Group Scene Generator, and multi-character card workflow planning.
- Detachable native Card Workflow Studio.
- Project-level saved workflow drafts for multi-character single-card, split-card batch-plan, and group-card modes.
- AI-assisted card workflow planning using selected characters, shared project context, and established relationships.
- Per-character workflow directions for role in output, portrayal/card direction, scenario direction, and opening direction.
- `card_workflows[]` project persistence and workflow UUID reference maintenance.
- `docs/relationships.md` and `docs/card_workflows.md`.

### Changed

- Project duplication now remaps relationship endpoints and card-workflow character references to duplicated character UUIDs.
- Character removal now drops affected relationships and prunes invalid workflow references.
- Group Scene Generator now receives established relationships among selected characters as continuity context.
- Character workspace adapter documents now include project relationships, roster summaries, and workflow drafts as read-only project-level context.
- Project format remains version 2 because the v0.6 structures are additive to the v0.5 container model.

## 0.5.3

- Replaced the fixed single-line workspace action bar with a horizontal flow layout so action buttons wrap onto additional rows when the available width is too narrow.
- Made the project controls, active-character roster controls, and template selector rows responsive using wrapping flow containers.
- Increased practical minimum widths for the project name and active-character selector while allowing later controls to move onto the next line instead of overflowing beyond the window.
- Preserved the compact single-row presentation automatically when enough horizontal space is available, including ultrawide layouts.

## 0.5.2

- Replaced the mixed `Array`/`String` ternary default in `builder_service.gd` with explicit branches, removing the Godot 4.6 `INCOMPATIBLE_TERNARY` warning.
- Replaced the matching mixed-type builder-field default in `character_builder_window.gd` with an explicitly typed `Variant` default.
- Renamed local `mode` variables in `controlled_build_window.gd` to `build_mode` so they no longer shadow the inherited `Window.mode` property.
- Renamed the local preview `title` variable to `preview_title` so it no longer shadows `Window.title`.
- Preserved the existing controlled-build job metadata key (`"mode"`) and behaviour.

## 0.5.1

- Fixed a Godot 4.6 GDScript type-inference error in `workspace_view.gd` when calculating the next character number from the project character array.
- The character count is now explicitly converted to `int`, preserving v0.5.0 behaviour while allowing the script to compile cleanly.

## 0.5.0

### Added

- Project format v2 with multiple independent character records in one project.
- Automatic in-memory migration of v0.4 format-v1 single-character projects to the v2 container model.
- Project-level character roster with active-character switching and optional per-character group roles.
- Add, duplicate, and remove-character workflows inside an open project.
- Per-character template choice, generation history, Character Builder state, concept, card data, and asset references.
- Detachable native Shared Project Context editor for premise, setting, situation, shared rules, and planning notes.
- Shared context injection into full-character generation, field suggestions, and Controlled Build prompts.
- Detachable native Group Scene Generator as the first multi-character AI workflow.
- Multi-character selection and optional generation instructions for group-scene generation.
- Review-first shared-context proposal with per-field selection and editing.
- Review-first per-character scenario proposals keyed by stable character UUID.
- Project-level and per-character asset directory foundations.
- Project-aware library rows showing character count and character names.
- Project and character-name searching in the Character Library.
- `docs/multi_character_projects.md` documenting the roster, shared context, and group-scene workflow.

### Changed

- The Character Library now treats each saved folder as a project that may contain one or more characters.
- Dashboard statistics now show both project count and total character count.
- Active-character AI ownership uses a project-plus-character identifier, while group-scene jobs use the project identifier.
- Character-specific tool windows still close when switching active characters; project-level multi-character windows can stay open across character switches.
- `character.json` remains the authoritative project file but now stores project-level context and a `characters[]` collection.

### Compatibility

- Godot-rewrite format-v1 projects created by v0.1-v0.4 are migrated when loaded and are only rewritten as format v2 after an explicit save.
- Compatibility with the original legacy PyWebView database remains intentionally out of scope.

## 0.4.1

### Added

- Detachable native Controlled Build window available directly from the Character Workspace.
- Safe Section Build for regenerating one complete template section while treating every other field as protected context.
- Custom Section Build for selecting an arbitrary subset of AI-generatable template fields across sections.
- Revision mode with freeform instructions for improving selected existing content without rebuilding the rest of the character.
- Hard allowed-field boundaries in Generation Preview so controlled-build jobs cannot apply valid-but-out-of-scope fields returned by an overreaching model.
- Layered generation-response parsing with balanced JSON extraction and local repair for common malformed-output issues.
- One automatic AI JSON-repair pass when local parsing and repair cannot recover the expected response structure.
- Generation Preview diagnostics when response repair was required.
- Generation history metadata for parse strategy and automatic response-repair count.
- `docs/controlled_builds.md` documenting targeted build, revision, scope-protection, and repair behaviour.

### Changed

- Controlled build jobs use the same shared queue, active API profile, retry settings, cancellation controls, and preview workflow as existing generation tools.
- Controlled Build refreshes its project snapshot immediately before queueing, allowing the main workspace to remain editable while the native tool window is open.
- Generation Preview now honours per-job output policy metadata when supplied.

## 0.4.0

### Added

- Detachable native Character Builder window with a guided Foundation → Personality → Background → Scene → Review workflow.
- Data-driven builder schema stored separately from the UI implementation.
- Built-in JSON builder presets for Fantasy Adventure, Sci-Fi Operator, Modern Rivalry, Cozy Slice of Life, and Mystery / Horror.
- Personality Builder fields for traits, strengths, flaws, motivations, vulnerabilities, speech style, mannerisms, and relationship behaviour.
- Scene Builder fields for location, situation, user role, relationship, tone, and opening direction.
- AI Fill This Step and AI Fill All Builder Fields jobs using the existing shared generation queue.
- AI concept analysis that extracts structured builder details from the current freeform generation concept.
- Builder completion indicator and assembled concept review step.
- Send to Concept action for turning builder state into a generation-ready concept.
- Apply to Character action for transferring builder data into name, tags, description, personality, scenario, and concept fields.
- Optional overwrite mode; by default, builder application fills empty destination fields rather than destroying existing card content.
- Builder state is stored inside the character project's `workspace.builder` data so partially completed work survives save/reload without creating a parallel database.
- Character Builder window size and placement use the same disposable native-window state system as the Idea Generator and Generation Preview.
- AI generation jobs now carry their originating character project ID so late results are discarded after switching characters instead of being applied to the wrong project.

### Changed

- The Character Workspace now exposes Character Builder directly beside the existing generation tools.
- Builder AI jobs share the same queue, retry, cancellation, profile, and model configuration as other text-generation tasks.
- `Untitled Character` is treated as an empty destination when applying a builder working name.

## 0.3.3

### Fixed

- Native Idea Generator and Generation Preview windows are now hidden immediately after construction, before `force_native` is configured.
- Fixed Godot startup errors reporting that `force_native` could not be changed while a window was displayed.
- Kept the detachable native-window behaviour introduced in v0.3.2 unchanged once the tools are actually opened.

## 0.3.2

### Added

- Idea Generator and Generation Preview now use native operating-system windows instead of being confined to the main application frame.
- Large tool windows are non-exclusive, so the main Character Card Forge workspace remains usable while they are open.
- Tool-window size and position are remembered in a separate lightweight `tool_windows.json` state file.
- Saved window placement is ignored when it no longer intersects an available display, preventing stale multi-monitor layouts from deliberately reopening off-screen.
- Generation Preview is tied to the character that produced it and refuses to apply stale results to a different project.

### Changed

- Switching to a different character closes open character-specific tool windows to avoid applying ideas or generated content to the wrong project.
- Closing the application saves the last used tool-window geometry when those windows have been opened.

## 0.3.1

### Fixed

- Removed an unused `field_type` local from full-character prompt construction.
- Renamed the Idea Generator's local `seed` variable to `idea_seed` so it no longer shadows GDScript's built-in `seed()` function.
- Cleared the two Godot editor warnings reported in `generation_service.gd`.

## 0.3.0

### Added

- Native Template Manager available from the main sidebar and Character Workspace.
- User templates stored as separate versioned JSON files under the Character Card Forge user-data folder.
- Create, duplicate, edit, import, export, and delete template workflows.
- Built-in Default template remains read-only and can be duplicated as a starting point.
- Section creation, deletion, renaming, descriptions, reordering, and Standard/Interview-Q&A section kinds.
- Field creation, deletion, reordering, labels, stable AI JSON keys, project data paths, placeholders, required flags, and per-field AI instructions.
- Template field types: single-line text, multiline text, tags, number, checkbox, and select lists.
- Template-level global AI rules.
- Strict and flexible AI output policies.
- Configurable handling for unexpected AI fields: ignore them or review/store them under `character.custom.generated_extra`.
- Workspace template selector for switching a character between installed templates without deleting hidden project data.
- Template format-v1 to format-v2 normalisation on load/import.
- Template validation for duplicate section IDs, field IDs, and project paths.
- Project loading now preserves custom top-level project data used by future or third-party templates.

### Changed

- Full-character AI prompts now describe each field's expected data type, required status, and optional field-specific instruction.
- Per-field AI suggestions now respect custom field instructions and typed values.
- Generation Preview supports numbers, booleans, select fields, tags, and stored unexpected fields.
- The built-in starter template has been upgraded to format version 2.

## 0.2.2

- Changed viewport stretch aspect from `keep` to `expand` so maximised ultrawide windows use the full available width instead of letterboxing a 16:9 canvas.

## 0.2.1

- Fixed the empty Generation Preview window appearing behind the Idea Generator or at workspace startup.
- Utility windows are now explicitly hidden until opened by their matching action.
- Generation Preview and Idea Generator now use clamped centred popup sizing for smaller application windows.

## 0.2.0

### Added

- Shared queued AI generation service.
- Active-job cancellation and queue status.
- Configurable retry handling for temporary request failures.
- Full-generation preview with selective field application.
- Editable generated proposals before applying them.
- Per-field AI Suggest actions.
- Native Idea Generator with concept/tag transfer.
- Approximate concept token estimate.
- Multiple OpenAI-compatible API profiles.
- API profile creation, duplication, selection, and deletion.
- OpenAI-compatible `/models` discovery.
- Expanded generation history metadata.

## 0.1.1

- Fixed generated `@ScrollContainer@...` workspace tab titles.
- Removed initial GDScript shadowing warnings.

## 0.1.0

- Initial Godot rewrite foundation.
