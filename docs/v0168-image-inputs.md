# v0.16.8 — Image-to-Image, Reference Images and Inpainting

## Scope

v0.16.8 makes image input a first-class Image Studio concept instead of treating every generation as Text → Image. The Studio now distinguishes:

- Text → Image
- Image → Image
- Inpainting
- Reference Images

The operation selector is capability-gated. A capability being known at backend/model/workflow level remains separate from CCF being able to execute it through the selected profile.

## Forge / Automatic1111

Forge/A1111 is the first live image-input transport in CCF.

Image → Image and Inpainting use `/sdapi/v1/img2img` and send the existing prompt, negative prompt, sampler, steps, CFG, seed, checkpoint override and requested dimensions together with:

- `init_images`
- `denoising_strength`
- `mask` for Inpainting
- `mask_blur`
- standard full-resolution inpainting flags

Reference Images are intentionally not claimed as a generic A1111 capability. Reference/ControlNet/IP-Adapter behaviour depends on extensions or custom APIs, so it remains unavailable unless an explicit provider transport is configured.

## Provider-specific transports

OpenAI-compatible and other JSON-style Image providers vary significantly. v0.16.8 therefore does not guess field names or endpoints.

An Image provider profile may define `image_input_transport_v0168.operations` entries. Each operation can explicitly name an endpoint suffix and JSON fields such as `source_field`, `mask_field`, `references_field` and `denoise_field`. When present, that operation becomes execution-ready with user-defined capability provenance.

This mapping is additive and forward-compatible. It does not overwrite the provider's existing model/prompt/count/size authority.

## ComfyUI

v0.16.6 already supports explicit `reference_image` workflow mapping and offline workflow materialisation. v0.16.8 preserves that architecture but does not falsely promote ComfyUI image-input operations to live execution: ComfyUI queue/upload/history transport is still a separate future milestone.

## Image Studio UI

The Prompt & Results tab now exposes a compact Generation Operation panel with:

- operation selector
- source image from the selected generated gallery item or an external PNG/JPEG/WebP
- multiple reference images from gallery/external files
- inpainting mask selection
- denoise/strength
- mask blur

Unsupported or non-executable operations are disabled according to normalized capability metadata.

Generated records retain the operation, denoise strength, whether a mask was supplied and reference-image count while preserving the existing record format fields and gallery behaviour.

## Compatibility

- Text → Image remains the default.
- Existing image provider profiles require no migration.
- Existing gallery records remain valid.
- v0.16.7 Idea Generator Detail Levels remain inherited unchanged.
- Public `VERSION` remains at the last promoted release during v0.16.x development.
- Godot 4.7.1, Forward+ desktop rendering and Compatibility/OpenGL fallback remain unchanged.
