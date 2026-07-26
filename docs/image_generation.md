# Image Generation

Character Card Forge v0.11 introduced the native image-generation foundation. The v0.12 development candidate expands that same project-first architecture with dedicated Stable Diffusion Forge / Automatic1111 support, image-backend discovery, reproducible seeds, batches, and regenerate/variant workflows.

Generated artwork remains stored as ordinary image files. `character.json` stores lightweight metadata and relative paths rather than image blobs or base64 data.

## Provider roles and image backends

Settings format version 5 keeps the three independent reusable provider roles:

- **Text generation** — character/card writing and planning workflows.
- **Vision analysis** — multimodal analysis of attached reference images.
- **Image generation** — text-to-image work in Image Generation Studio.

Each reusable profile now also has an `image_backend` value:

- `openai_compatible` — OpenAI-compatible Images API.
- `automatic1111` — Stable Diffusion Forge / Automatic1111 WebUI API.

The role assignment and backend type are intentionally separate. A profile can still serve Text, Vision, and Image roles, while Image Studio selects its adapter from the profile's image backend.

Existing settings migrate non-destructively. v3 Text/Vision assignments and v4 Image-role assignments remain unchanged; v5 adds image-backend/default fields to each profile.

## OpenAI-compatible image adapter

For an OpenAI-compatible image profile, `CCFImageGenerationService` sends a POST request to:

```text
<profile base URL>/images/generations
```

If the configured base URL already ends in `/images/generations`, it is used unchanged.

A typical request is:

```json
{
  "model": "provider-model-id",
  "prompt": "...",
  "n": 2,
  "size": "1024x1024"
}
```

`size` is omitted when the Image Studio size field is `auto`. The batch control is sent through `n`; providers remain free to impose their own limits.

OpenAI-compatible image routes have no universal negative-prompt field. Image Studio therefore appends exclusion text as provider-neutral `Avoid or exclude:` guidance for this backend.

The adapter accepts common response shapes:

- OpenAI-style `data[].b64_json`;
- `base64`, `b64`, `image`, or `image_base64` fields;
- `data:image/...;base64,...` strings;
- HTTP/HTTPS image URLs;
- raw PNG, JPEG, or WebP response bodies.

Remote image URLs are downloaded after the generation response. Received images are decoded by Godot and normalised to PNG before entering the project.

### OpenAI model discovery

Image Studio can query `<base URL>/models` and list returned model IDs. The OpenAI-compatible model-list schema does not reliably identify which models support image generation, so discovery is intentionally presented as a model list rather than a guarantee of image capability.

## Stable Diffusion Forge / Automatic1111 adapter

Profiles using `automatic1111` target the WebUI API used by Automatic1111 and compatible Forge installations.

The base URL can be either the server root:

```text
http://127.0.0.1:7860
```

or its API root:

```text
http://127.0.0.1:7860/sdapi/v1
```

Image Studio sends text-to-image requests to:

```text
/sdapi/v1/txt2img
```

A typical request contains:

```json
{
  "prompt": "...",
  "negative_prompt": "...",
  "batch_size": 2,
  "n_iter": 1,
  "steps": 28,
  "cfg_scale": 7.0,
  "seed": -1,
  "sampler_name": "Euler a",
  "width": 1024,
  "height": 1024,
  "save_images": false,
  "send_images": true
}
```

When a checkpoint/model override is supplied, the request uses `override_settings.sd_model_checkpoint` and asks the WebUI to restore its prior checkpoint after the request. This avoids permanently changing the server's global model simply because one Character Card Forge job used another checkpoint.

The WebUI API must be enabled by the server. Local installations commonly expose it with their API option; exact launch/configuration details depend on the installed Forge or Automatic1111 version.

### Stable Diffusion discovery

Image Studio queries:

```text
/sdapi/v1/sd-models
/sdapi/v1/samplers
```

The returned checkpoint titles and sampler names can be selected directly in the studio. Discovery does not mutate the server's active model.

## Image Studio controls

The detachable **Image Generation Studio** operates on saved projects instead of silently serialising unsaved workspace edits.

Shared controls include:

- saved project and character selection;
- reusable Image-provider selection and default assignment;
- backend identification;
- model/checkpoint override;
- model/sampler discovery;
- resolution/size input;
- Auto, Natural language, and Stable Diffusion-style prompt modes;
- deterministic prompt building from the central character model;
- freeform visual direction and negative/exclusion guidance;
- batch size from 1 to 8;
- cancellable requests;
- persistent generated-image gallery;
- preview/open-in-system-app;
- **Set as Portrait**;
- non-destructive gallery-record removal.

Forge/A1111 additionally uses:

- sampler;
- steps;
- CFG scale;
- seed.

These values can be saved back to the selected provider profile with **Save Image Defaults**. Keeping advanced image defaults on the image profile means local SD tuning does not pollute text-generation settings.

## Seeds, regeneration, and variants

For Forge/A1111, `seed = -1` requests a random seed. Character Card Forge reads the WebUI response `info` metadata and stores the actual returned seed for each image whenever it is available.

This makes a generated gallery item reproducible later:

- **Regenerate** reloads the selected image's stored prompt, negative prompt, profile, model/checkpoint, sampler, steps, CFG, size, and seed, then creates a new image.
- **New Seed Variant** reloads the same stored generation recipe but resets the requested seed to `-1` before generation.

OpenAI-compatible providers do not have a universal seed control, so seed reproducibility is backend-dependent.

## Batch generation

Image Studio supports batches of 1–8 images.

For OpenAI-compatible Images APIs the batch size is sent as `n`.

For Forge/A1111 the batch size is sent as `batch_size` with `n_iter = 1`. Returned images are decoded and saved individually, and any returned `all_seeds` values are associated with the corresponding gallery records.

The project is saved once after a completed batch rather than once per image.

## Prompt building

Natural-language prompt generation draws from the selected character's central V2 model, including the character name, optional group role, description or concept, personality cues, and additional visual direction.

Stable Diffusion-style mode builds a concise comma-separated prompt from the same authoritative character data. It is deliberately provider-neutral so later LoRA, embedding, preset, and style tooling can extend the prompt layer without creating a second character model.

## Generated image records

Each generated image is stored under the selected character's existing asset directory:

```text
characters/<project UUID>/
└── characters/
    └── <character UUID>/
        └── generated_images/
            └── generated_<timestamp>_<batch index>_<suffix>.png
```

v0.12 writes format-v2 gallery records similar to:

```json
{
  "format_version": 2,
  "image_id": "image_...",
  "path": "characters/<character UUID>/generated_images/generated_....png",
  "created_at": "...",
  "provider": "automatic1111",
  "backend": "automatic1111",
  "profile_id": "local-sd",
  "profile_name": "Local Forge",
  "model": "checkpoint-name",
  "size": "1024x1024",
  "prompt_style": "stable_diffusion",
  "prompt": "...",
  "negative_prompt": "...",
  "batch_index": 0,
  "batch_size": 2,
  "sampler": "Euler a",
  "steps": 28,
  "cfg_scale": 7.0,
  "seed": 123456789,
  "generation_mode": "new",
  "source_image_id": "",
  "width": 1024,
  "height": 1024
}
```

Older v1 dictionary records and string-only path entries remain displayable. The format is additive: old generated images do not need migration just to remain usable.

Assigning a gallery image as the portrait stores the same relative path in:

```text
characters[].assets.portrait
```

No image bytes are duplicated into `character.json`.

## Portability

Generated images live under the existing character project tree, so `.ccfproject` packaging includes them automatically alongside other project assets. Character Card PNG export can continue using `assets.portrait` as the selected card artwork.

## Current limitations and next expansion

The v0.12 candidate restores the legacy application's major local text-to-image path without introducing a second image database. Still planned:

- image-to-image/reference-image generation;
- emotion-image generation and regeneration using the existing `emotion_images/` tree;
- per-emotion prompt editing;
- reusable prompt/style presets;
- richer gallery cleanup and intentional file deletion;
- provider-specific quality/aspect controls where useful;
- LoRA/embedding and other SD-specific advanced controls;
- stronger capability detection for providers with richer metadata;
- optional API authentication modes beyond the current profile bearer-key behaviour.

These additions should continue extending the same image service boundary and central character asset model.
