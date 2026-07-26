# Vision and Attachments Foundation

Character Card Forge v0.10.0 adds managed project attachments and separates ordinary text generation from multimodal vision analysis. Attachments extend the existing project model; they do not create a second character database.

## Provider roles

Application settings format version 3 assigns existing OpenAI-compatible API profiles to explicit roles:

- **Text generation** — normal card generation, field suggestions, Character Builder jobs, Controlled Build, group scenes, relationships, card workflows, and Series drafting.
- **Vision analysis** — image-reference analysis from the Vision and Attachments window.

A single API profile may serve both roles. Existing settings migrate by assigning the previously active profile to both roles, preserving earlier behaviour. Each profile also stores a `vision_detail` preference of `auto`, `low`, or `high` for providers that implement the OpenAI-compatible image-detail field.

An image-capable model must be selected in the profile assigned to the Vision role. Character Card Forge sends multimodal content using an OpenAI-compatible `image_url` data URL. Provider and model support varies; a text-only model will reject the request rather than silently falling back.

## Attachment scopes

Attachments can belong to either:

- the **shared project**, where they are available to every character; or
- the **active character**, where they are available only to that character and workflows that include it.

Project-level metadata is stored in `character.json` under `attachments[]`. Character-specific metadata is stored in the matching `characters[].attachments[]` array.

## Managed files

Selected files are copied into the project's ordinary asset tree:

```text
<project UUID>/
├── character.json
├── attachments/
│   └── <attachment ID>_<original filename>
└── characters/
    └── <character UUID>/
        └── attachments/
            └── <attachment ID>_<original filename>
```

The JSON stores relative paths. Binary content is never converted into a database blob or embedded permanently as base64. Portable `.ccfproject` packages already include the whole project tree, so managed attachment files travel with the project package.
Project duplication remaps per-character attachment paths to the duplicated character UUIDs and copies the referenced managed attachment files into the new project tree.

## Attachment record

Attachment records use format version 1 and contain fields such as:

```json
{
  "format_version": 1,
  "attachment_id": "attachment_...",
  "display_name": "reference.png",
  "kind": "image",
  "relative_path": "characters/<character UUID>/attachments/<stored filename>",
  "source_filename": "reference.png",
  "mime_type": "image/png",
  "size_bytes": 123456,
  "added_at": "2026-07-25T00:00:00Z",
  "include_in_context": true,
  "notes": "Pay attention to the jacket and hairstyle.",
  "note_text": "",
  "preprocess": {
    "status": "ready",
    "summary": "Image, 1024 × 1024 pixels, 120.6 KB.",
    "character_count": 0,
    "estimated_tokens": 0,
    "image_width": 1024,
    "image_height": 1024,
    "truncated": false
  }
}
```

Unknown attachment fields are preserved so the format can expand without discarding newer metadata.

## Supported attachment kinds

The initial manager recognises:

- images: PNG, JPEG, WebP, BMP, TGA, and SVG;
- GIF files;
- text and Markdown;
- JSON, YAML, CSV, and logs as text references;
- PDF documents;
- subtitle formats including SRT, VTT, ASS, SSA, and SUB;
- transcript files;
- notes stored directly in project JSON;
- arbitrary files stored as ordinary assets.

The attachment type can be corrected manually when an uncommon extension is classified as a generic file.

## Preprocessing and context budget

The manager shows a preprocessing summary and a combined prompt-budget estimate before generation.

- Notes and supported text files contribute their text to generation context.
- Subtitle and transcript files are treated as text.
- Text preprocessing currently has a 4 MB per-file safety limit.
- Images and GIFs contribute descriptive file metadata and user notes to ordinary text prompts; actual pixels are sent only during an explicit vision-analysis job. PNG, JPEG, WebP, and GIF data is sent directly, while other Godot-readable image formats are converted to PNG in memory when possible.
- PDFs are stored and summarised by file metadata in v0.10.0. Native PDF text extraction is not yet included.
- Generic files contribute stored metadata and user notes.

The default combined limit is 24,000 characters and can be changed in Settings from 2,000 to 120,000 characters. Context is assembled deterministically in project-attachment order followed by character-attachment order. Entries beyond the limit are omitted or truncated and reported in the summary.

## Review-first vision analysis

Select an image or GIF and choose one of two modes:

- **Concept Extraction** proposes a generation concept plus a conservative subset of visual card fields.
- **Full-card Suggestions** proposes all AI-generatable fields from the active template.

The model is instructed to distinguish visible evidence from creative inference. Results enter the existing detachable Generation Preview, where every changed field can be edited, accepted, or discarded. Vision output never writes directly to project content.

## Removal behaviour

Removing an attachment currently removes its metadata entry but deliberately keeps the managed file as an orphan asset. This avoids destructive file deletion before the user saves and makes accidental metadata removal recoverable manually. A later asset-cleanup tool can identify and remove unreferenced files safely.

## Current limitations

- PDF text extraction and document page rendering are not included yet.
- GIF frame selection is delegated to the provider; local preprocessing may only report stored file metadata.
- Remote image URLs are not yet attachment records; v0.10.0 imports local files.
- Vision capability detection is not automatic. The selected Vision model must support OpenAI-compatible multimodal requests.
- Image generation is a later roadmap phase and is separate from reference-image analysis.
