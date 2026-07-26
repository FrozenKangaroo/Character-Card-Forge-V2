# Image Generation

Character Card Forge v0.11 introduced the native image-generation foundation. The v0.12 development candidate expands that architecture with Stable Diffusion Forge / Automatic1111 support, provider discovery, batches, reproducible seeds, regeneration, and image-provider configuration that is independent of character text generation.

Generated artwork remains stored as ordinary image files. `character.json` stores lightweight metadata and relative paths rather than image blobs or base64 data.

## Provider architecture

Settings format version 6 separates two provider collections:

- **Character AI profiles** — OpenAI-compatible text and vision connections used for character/card writing, planning, and multimodal analysis.
- **Image provider profiles** — OpenAI-compatible Images API or Stable Diffusion Forge / Automatic1111 connections used only by Image Studio.

Text and Vision continue to have independent role assignments within the Character AI collection. Image Studio has its own default assignment within the Image Provider collection.

This separation prevents a text provider such as NanoGPT from accidentally donating its URL, API key, or text model to a local Stable Diffusion workflow.

### v5 → v6 migration

Existing v5 settings migrate non-destructively:

- text and vision profile assignments remain character-AI profiles;
- the previous Image role becomes a separate image-provider record;
- legacy image defaults such as sampler, steps, CFG, seed, and batch size are retained;
- if the old profile was marked Forge/A1111 but still had an OpenAI-style `/v1` or `/api/v1` URL, the migrated local image provider uses `http://127.0.0.1:7860` instead of carrying the text-provider URL into Stable Diffusion;
- a normal local Forge/A1111 provider does not inherit or require the character provider's API key.

## Settings UI

**Settings** is split into two tabs:

### Character AI

Contains only:

- Text generation profile assignment;
- Vision analysis profile assignment;
- OpenAI-compatible character-AI profile name, base URL, API key, model, temperature, token limit, and vision detail;
- character-generation context/retry defaults.

No Stable Diffusion server, checkpoint, sampler, or image-backend controls are shown on this tab.

### Image Generation

Contains dedicated image providers and image-wide defaults.

For a local Forge/A1111 provider the normal connection is simply:

```text
Server URL: http://127.0.0.1:7860
```

The local Stable Diffusion form hides the API-key field because a normal local WebUI install does not use one. The API key is shown only for OpenAI-compatible image providers that may require remote authentication.

Image-provider settings can be tested through **Test / Discover** before entering Image Studio.

## Image Studio

Image Studio is a normal main application workspace rather than a detachable provider-configuration window. Its sidebar entry remains selected while active.

The Studio is intentionally focused on image work:

- saved project and character selection;
- dedicated image-provider selection and default assignment;
- backend identification;
- model/checkpoint override;
- model/sampler discovery;
- resolution/size input;
- Auto, Natural language, and Stable Diffusion-style prompt modes;
- deterministic prompt building from the central character model;
- freeform visual direction and negative/exclusion guidance;
- batch size from 1 to 8;
- sampler, steps, CFG, and seed for Forge/A1111;
- cancellable requests;
- persistent generated-image gallery;
- preview/open-in-system-app;
- **Set as Portrait**;
- **Regenerate** and **New Seed Variant**;
- non-destructive gallery-record removal.

Connection credentials are not edited in Image Studio. **Manage Image Providers in Settings** opens the Image Generation settings tab directly.

## OpenAI-compatible image adapter

For an OpenAI-compatible image provider, `CCFImageGenerationService` sends a POST request to:

```text
<image-provider base URL>/images/generations
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

`size` is omitted when Image Studio uses `auto`. Batch size is sent through `n`; providers can impose their own limits.

OpenAI-compatible image routes have no universal negative-prompt field, so exclusion text is appended as provider-neutral `Avoid or exclude:` guidance.

The adapter accepts common response shapes including OpenAI-style base64 data, other common base64 fields, data URLs, downloadable image URLs, and raw PNG/JPEG/WebP responses. Received images are decoded by Godot and normalised to PNG.

### OpenAI model discovery

Image Studio can query `<base URL>/models`. OpenAI-compatible model lists do not reliably identify which entries support image generation, so discovery is a convenience list rather than a capability guarantee.

## Stable Diffusion Forge / Automatic1111 adapter

Image providers using `automatic1111` target the WebUI API used by Automatic1111 and compatible Forge installations.

The recommended local setting is the server root:

```text
http://127.0.0.1:7860
```

The adapter also accepts an `/sdapi/v1` API root. Character Card Forge appends the required endpoint automatically.

Text-to-image requests target:

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

When a checkpoint override is supplied, the request uses `override_settings.sd_model_checkpoint` and asks the WebUI to restore its prior checkpoint afterward.

The WebUI API must be accessible. Some installations require API access to be enabled at launch. If discovery returns an HTML webpage instead of JSON, the configured URL is usually pointing at a website/proxy rather than the WebUI API server.

### Stable Diffusion discovery

Image Studio queries:

```text
/sdapi/v1/sd-models
/sdapi/v1/samplers
```

Checkpoint titles and sampler names can then be selected directly. Discovery does not permanently change the server's active model.

## Seeds, regeneration, and variants

For Forge/A1111, `seed = -1` requests a random seed. Character Card Forge reads WebUI response metadata and records the actual returned seed for each image when available.

- **Regenerate** reloads the stored prompt, negative prompt, image provider, checkpoint, sampler, steps, CFG, size, and seed.
- **New Seed Variant** reloads the same recipe but resets the requested seed to `-1`.

OpenAI-compatible providers do not have a universal seed control, so exact seed reproducibility remains backend-dependent.

## Batch generation

Image Studio supports batches of 1–8 images.

For OpenAI-compatible Images APIs the batch size is sent as `n`.

For Forge/A1111 it is sent as `batch_size` with `n_iter = 1`. Returned images are saved individually, and returned `all_seeds` values are associated with the corresponding gallery records. The project is saved once after the complete batch.

## Prompt building

Natural-language prompt generation draws from the selected character's central V2 model, including character name, optional group role, description/concept, personality cues, and additional visual direction.

Stable Diffusion-style mode builds a concise comma-separated prompt from the same authoritative character data. It stays provider-neutral so LoRA, embedding, preset, and style tools can be added later without creating another character model.

## Generated image records

Each generated image is stored below the selected character's existing asset directory:

```text
characters/<project UUID>/
└── characters/
    └── <character UUID>/
        └── generated_images/
            └── generated_<timestamp>_<batch index>_<suffix>.png
```

v0.12 format-v2 records include the image-provider ID/name, backend, checkpoint/model, prompt, negative prompt, batch context, sampler, steps, CFG, returned seed, generation mode, dimensions, and relative path.

Older v1 dictionary records and string-only path entries remain displayable. Assigning a generated image as portrait stores the same relative path in `characters[].assets.portrait`; image bytes are not duplicated into `character.json`.

## Portability

Generated images live in the existing character project tree, so `.ccfproject` packaging includes them automatically alongside other assets. Character Card PNG export can continue using `assets.portrait` as selected card artwork.

## Current limitations and next expansion

Still planned after the v0.12 local text-to-image path:

- image-to-image/reference-image generation;
- emotion-image generation and regeneration using `emotion_images/`;
- per-emotion prompt editing;
- reusable prompt/style presets;
- richer gallery cleanup and intentional file deletion;
- provider-specific quality/aspect controls;
- LoRA/embedding and deeper SD-specific controls;
- stronger provider capability detection;
- optional authenticated/non-local WebUI connection modes where needed.

These additions should continue using the same image-service boundary and central character asset model.
