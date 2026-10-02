# v0.21.13 — Public Idea Sources

## Purpose

Character Card Forge can browse an official public collection of reusable Idea Sources
without bundling that content into the executable or treating remote JSON as trusted.

The **Idea Generator → Idea Sources → Browse Public Sources…** action opens a searchable,
native independent tool window that can move outside the main application window. Choosing
**Use Selected Source** downloads and verifies the source, loads it into the normal Idea Source
editor and activates it for generation.

## Publishing layout

The catalog is hosted in the Cloudflare R2 bucket `charactercardforge` through the custom
domain:

```text
https://charactercardforge.damee.info/
├── manifest.json
└── idea-sources/
    └── <content-hash-prefix>/
        └── <name>.ccfideasource.json
```

Source objects use content-addressed paths and immutable cache headers. Updating a source
therefore creates a new object path; the manifest is published last and has a short cache
lifetime.

## Manifest format

```json
{
  "format": "character-card-forge-public-idea-source-catalog",
  "schema_version": 1,
  "title": "Character Card Forge Public Idea Sources",
  "description": "Public reusable Idea Sources maintained for Character Card Forge.",
  "published_at": "2026-10-02T00:00:00Z",
  "source_count": 1,
  "sources": [
    {
      "order": 1,
      "id": "old-friend-returns",
      "title": "Old Friend Returns",
      "description": "Reusable reunions with unresolved history.",
      "source_version": "1.0",
      "content_rating": "general",
      "tags": ["reunion", "past connection"],
      "path": "idea-sources/0123456789abcdef/old-friend-returns.ccfideasource.json",
      "size_bytes": 2048,
      "sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    }
  ]
}
```

Manifest paths are relative to the fixed catalog origin. Absolute URLs, traversal, query
strings, fragments, backslashes and paths outside `idea-sources/` are rejected.

## Trust boundary

Before a public source is exposed to generation, CCF verifies:

1. bounded manifest and source response sizes;
2. catalog format and schema;
3. unique source IDs and safe relative paths;
4. the downloaded byte count;
5. the exact SHA-256 digest;
6. the source ID against the manifest entry; and
7. the existing `CCFIdeaSourceServiceV0213` production schema.

Failures remain visible in the chooser and do not modify the active source.

## Local behavior

A chosen public source is deliberately temporary. It becomes the active source and may be
edited immediately, but it does not overwrite a same-ID local source. Press **Save Current
Source** to make the current editable copy part of the local Source Library. Once saved,
normal local Idea Source behavior works without internet access.

## Maintenance

`tools/build_public_idea_source_manifest.py` builds the checksummed manifest from a source
directory. `tools/validate_public_idea_source_directory_v02113.gd` runs every candidate
file through the production Idea Source parser. Upload source objects before publishing
the new manifest.


## GitHub Actions R2 publishing

The repository includes `.github/workflows/publish-public-idea-sources.yml` and
`tools/publish_public_idea_sources_r2.py` as a publishing bridge for catalog updates.

Public source snapshots are committed under:

```text
.github/public-idea-source-publish/<number>-<name>.ccfideasource.txt
```

The `.txt` extension is intentional. The snapshot bytes are the exact Idea Source JSON
bytes that will be published, but keeping the repository copy out of `*.json` prevents
Godot's JSON export include filter from bundling the public catalog into the executable.
The publisher changes only the object filename extension back to
`.ccfideasource.json`.

A push that adds or updates one of those snapshots automatically:

1. reads the existing live `manifest.json` directly from R2;
2. validates the staged Idea Source and calculates its exact SHA-256 and byte size;
3. creates `idea-sources/<first-16-sha256>/<number>-<name>.ccfideasource.json`
   if that immutable object does not already exist;
4. replaces or adds the source entry in the manifest by stable source `id`;
5. uploads `manifest.json` last; and
6. re-downloads the R2 objects and verifies the source through the public custom domain.

The workflow uses the bucket `charactercardforge` and public root
`https://charactercardforge.damee.info/`.

### Required GitHub Actions secrets

Configure these repository Actions secrets before publishing:

- `CLOUDFLARE_ACCOUNT_ID`
- `R2_ACCESS_KEY_ID`
- `R2_SECRET_ACCESS_KEY`

Create the R2 credentials with **Object Read & Write** access scoped only to the
`charactercardforge` bucket. Do not commit credentials to the repository.

The workflow can also be run manually with `workflow_dispatch` by supplying one or more
repo-relative `.ccfideasource.txt` snapshot paths. This is useful for retrying a publish
after fixing credentials without modifying the source content.
