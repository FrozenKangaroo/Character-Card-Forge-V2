# Portable CCF Project Packages

Character Card Forge v0.7 introduced `.ccfproject`, a renamed ZIP archive for moving complete CCF projects between installations.

This format is separate from Character Card V2. Character cards are intended for ecosystem interoperability; `.ccfproject` preserves CCF-specific project structure and assets.

## Package format version 1

Typical layout:

```text
example.ccfproject
├── manifest.json
├── project/
│   ├── character.json
│   ├── assets/
│   ├── generated_images/
│   ├── emotion_images/
│   └── characters/
│       └── <character UUID>/
│           ├── assets/
│           ├── generated_images/
│           └── emotion_images/
└── templates/
    └── <referenced custom template>.json
```

The exact project asset tree may be sparse. Empty directories do not need to be stored.

## Manifest

`manifest.json` contains package-level metadata similar to:

```json
{
  "package_type": "character_card_forge_project",
  "package_format_version": 1,
  "created_at": "...",
  "application": "Character Card Forge",
  "application_version": "0.8.1",
  "project_format_version": 2,
  "project_id": "source project UUID",
  "project_name": "Example Project",
  "project_file": "project/character.json",
  "character_count": 3,
  "included_template_ids": ["my_custom_template"]
}
```

The manifest's source project ID is descriptive. Import creates a fresh local project ID rather than overwriting a project with the same UUID.

## Project data

`project/character.json` is the authoritative project snapshot at the moment of export. It contains the complete current CCF project model, including:

- project metadata;
- all character records;
- active character ID;
- shared context;
- relationships;
- card workflows;
- relative asset references.

The package writer serialises the current in-memory project state instead of blindly copying the on-disk `character.json`, so recently committed workspace changes can be included after the workspace refreshes the export context.

## Assets

All ordinary files below the project's user-data directory are copied under `project/`, excluding the old on-disk `character.json` because the package already contains the freshly serialised snapshot.

On import, only archive entries below `project/` with safe relative paths are extracted. Absolute paths and `..` traversal components are rejected.

## Custom templates

Every non-default template referenced by a character is included under `templates/` when available.

During import:

- missing local template IDs are installed;
- an identical existing template is reused;
- a conflicting template with the same ID but different content is installed under a generated imported ID;
- affected character template references are remapped to the imported ID.

The built-in `default` template is not packaged because it ships with the application.

## Import behaviour

Importing a package:

1. validates `manifest.json` and the package type/version;
2. reads the packaged project JSON;
3. installs/remaps packaged custom templates;
4. assigns a fresh project UUID and timestamps;
5. saves the new project through the normal CCF storage service;
6. safely extracts project assets into the new project directory;
7. reloads the project through normal project normalisation.

This deliberately makes package import additive rather than destructive.

## Compatibility policy

`package_format_version` versions the archive/container contract independently from `project_format_version`, which versions the internal project JSON model.

Future package revisions should increase the package format only when the archive structure or import contract changes incompatibly. Additive project-model fields can continue using normal project-format compatibility rules.

## Assigned series

When the source project has a non-empty `metadata.series_id` and the matching local series definition exists, export adds:

```text
series/<series_id>.json
```

The manifest records `included_series_id`. During import, an unrelated local series using the same ID is not overwritten: the packaged series receives a fresh ID and the imported project's `metadata.series_id` is remapped to it.

A missing series reference does not block project export; the project retains the ID and can be repaired later.
