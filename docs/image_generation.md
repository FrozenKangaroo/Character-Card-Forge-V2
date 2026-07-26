# Image Generation Foundation

Character Card Forge v0.11 development adds the first native image-generation workflow to the Godot rewrite. The implementation follows the same project-first architecture as the rest of V2: generated artwork is stored as ordinary image files and `character.json` stores only lightweight metadata and relative paths.

## Provider role

Settings format version 4 adds a third reusable provider assignment:

- **Text generation** — character/card writing and planning workflows.
- **Vision analysis** — multimodal analysis of attached reference images.
- **Image generation** — text-to-image requests used by Image Generation Studio.

Existing v3 settings migrate without changing the user's Text or Vision assignments. The new Image role initially inherits the previously active API profile. Image Generation Studio can select any reusable profile and make it the new Image-role default.

The v0.11 foundation uses the profile's existing `base_url`, `api_key`, and `model` fields. The model can be overridden per generation inside Image Generation Studio, which is useful when a provider exposes text and image models through the same OpenAI-compatible base URL.

## OpenAI-compatible image adapter

`CCFImageGenerationService` sends a POST request to:

```text
<profile base URL>/images/generations
```

If the configured base URL already ends in `/images/generations`, it is used unchanged.

The initial payload contains:

```json
{
  "model": "provider-model-id",
  "prompt": "...",
  "n": 1,
  "size": "1024x1024"
}
```

`size` is omitted when the Image Studio size field is `auto`.

The adapter accepts several common response shapes so the core gallery does not depend on one provider's envelope:

- OpenAI-style `data[].b64_json`;
- `base64`, `b64`, `image`, or `image_base64` fields;
- `data:image/...;base64,...` strings;
- HTTP/HTTPS image URLs;
- raw PNG, JPEG, or WebP response bodies.

Remote URLs are downloaded after the generation response. Received PNG/JPEG/WebP images are decoded by Godot and normalised to PNG before entering the project.

## Image Studio

**Image Studio** is a detachable native tool window available from the main sidebar. It deliberately operates on saved projects instead of silently serialising unsaved workspace edits.

The studio provides:

- saved project and character selection;
- reusable API-profile selection;
- Image-role assignment;
- per-run model override;
- editable resolution/size input;
- Auto, Natural language, and Stable Diffusion-style prompt modes;
- deterministic prompt building from the central character model;
- freeform visual direction and exclusion/negative guidance;
- cancellable image requests;
- a persistent generated-image gallery;
- image preview and open-in-system-app action;
- **Set as Portrait** without duplicating the image file;
- non-destructive removal of gallery records while retaining the PNG as a recoverable asset.

When the main workspace has unsaved edits, opening Image Studio warns that image prompts use the saved project state.

## Prompt building

Natural-language prompt generation draws from the selected character's central V2 model, including the character name, optional group role, description or concept, personality cues, and additional visual direction.

Stable Diffusion-style mode builds a concise comma-separated prompt from the same authoritative character data. It is intentionally a foundation rather than a full tag editor; later versions can add provider-specific prompt presets, LoRA/embedding controls, sampler settings, and dedicated local Stable Diffusion adapters without changing the character model.

The OpenAI-compatible route has no universal negative-prompt field. In this foundation, exclusion text is appended to the prompt as provider-neutral `Avoid or exclude:` guidance rather than sending a backend-specific parameter.

## Generated image records

Each generated image is stored under the selected character's existing asset directory:

```text
characters/<project UUID>/
└── characters/
    └── <character UUID>/
        └── generated_images/
            └── generated_<timestamp>_<suffix>.png
```

The character's existing `assets.generated_images[]` array receives a lightweight format-v1 record similar to:

```json
{
  "format_version": 1,
  "image_id": "image_...",
  "path": "characters/<character UUID>/generated_images/generated_....png",
  "created_at": "...",
  "provider": "openai_compatible",
  "profile_id": "default",
  "profile_name": "Default",
  "model": "image-model-id",
  "size": "1024x1024",
  "prompt_style": "natural",
  "prompt": "...",
  "negative_prompt": "...",
  "width": 1024,
  "height": 1024
}
```

Older string-only entries in `assets.generated_images[]` remain displayable by the studio where a valid relative path is present.

Assigning a gallery image as the portrait stores the same relative path in:

```text
characters[].assets.portrait
```

No image bytes or base64 data are duplicated into `character.json`.

## Portability

Generated images live under the existing character project tree, so the current `.ccfproject` packaging system includes them automatically alongside other project assets. Character Card PNG export can continue using `assets.portrait` as the selected card artwork.

## Current limitations and next expansion

The v0.11 foundation intentionally establishes the shared storage, provider-role, prompt, and gallery architecture first. Still planned:

- dedicated Stable Diffusion Forge / Automatic1111 adapter and backend-specific settings;
- provider capability detection and image-model discovery/filtering;
- multiple-image batches and variations;
- image-to-image/reference-image generation;
- emotion-image generation and regeneration;
- per-emotion prompt editing;
- richer gallery management and asset cleanup;
- provider-specific quality/aspect/resolution controls;
- optional prompt presets and reusable visual styles.

These additions should extend `CCFImageGenerationService` through provider adapters and continue writing to the same central character asset model rather than creating parallel image databases.
