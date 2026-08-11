# v0.16.1 — Image Studio 2 Capability Foundation

## Purpose

v0.16.1 begins the Image Studio 2 development cycle by separating portable creative intent from provider/backend/model/workflow-specific generation capabilities.

The existing v0.15 Image Studio remains usable. This build deliberately focuses on the compatibility architecture required before structured Style/Palette/Lighting controls, richer API model discovery, ComfyUI workflow mapping, and image-to-image execution are added.

## Design rule

**Creative image intent is provider-independent; generation capabilities are provider, backend, model, or workflow specific.**

Image Studio must not hardcode per-model capability tables when authoritative runtime discovery is available. Where discovery is incomplete, CCF may combine backend knowledge, model-family profiles, workflow mappings, inference, and explicit user overrides while retaining where each conclusion came from.

## Normalized capability document

`CCFImageModelCapabilityServiceV0161` introduces a versioned capability document with:

- backend and selected model identity;
- operation capabilities for Text→Image, Image→Image, Inpainting, and Reference Images;
- technical parameter descriptors;
- discovered model descriptors;
- provider pricing/content metadata where supplied;
- provenance and confidence;
- a separate `execution_ready` flag so a backend capability is not confused with a feature the current Studio can already execute;
- preservation of additive/unknown provider parameters.

Capability state is tri-state:

- `supported`
- `unsupported`
- `unknown`

`unknown` is intentional. Missing metadata is not treated as evidence that a model lacks a feature.

## Capability provenance

The format reserves these sources:

- `provider`
- `backend`
- `model_family`
- `workflow`
- `inferred`
- `user_override`

Confidence is retained separately as authoritative, known, inferred, or user-defined.

This allows future UI to distinguish, for example, a NanoGPT capability explicitly supplied by its model endpoint from an SDXL capability inferred from a local checkpoint profile or a parameter mapped from a ComfyUI workflow.

## Rich provider model records

The normalized parser already accepts a rich provider model record containing fields such as:

- model ID/name/description/owner/tags;
- `capabilities.image_generation`;
- `capabilities.image_to_image`;
- `capabilities.inpainting`;
- NSFW/content flags;
- arbitrary `supported_parameters`;
- `resolutions`;
- `max_images`;
- `fixed_image_count`;
- `rendering_speed`;
- pricing metadata.

Unknown additive supported-parameter fields are preserved with generic type/choice metadata instead of being discarded. This is the foundation the later NanoGPT normalized model-discovery adapter can feed without coupling Image Studio to one fixed provider schema.

## Local Forge / Automatic1111

Existing local model/sampler discovery remains intact and is normalized into the same capability document.

The backend currently records Text→Image as supported and executable. Image→Image is recorded as a backend-supported operation but not yet `execution_ready`; the dedicated Image→Image phase will expose the actual Studio workflow later.

Sampler, steps, CFG, seed, negative prompt, batch/image count, and freeform resolution are represented as backend-known parameters.

## Generic OpenAI-compatible providers

Generic OpenAI-compatible providers deliberately receive conservative capability metadata. Text→Image is the existing execution path, while capabilities that cannot be determined from `/models` remain `unknown` instead of being falsely disabled.

## User override layer

The normalized service supports explicit operation/parameter overrides with `user_override` provenance. v0.16.1 establishes the data contract only; the author-facing override editor belongs to a later local-model/profile phase.

## Backwards compatibility

`CCFImageCapabilityCacheServiceV0161` reads the existing v0.15.28 `discovered_capabilities` data and converts it on demand. New discovery continues to retain the legacy cache for older code while also writing the normalized v0.16.1 cache.

No existing Character Project, generated image record, Image profile, prompt, sampler, model, or gallery format is migrated destructively.

## Image Studio UI

The live Studio now exposes a passive capability summary and **Capability Details…** inspector. These surfaces do not call any AI/provider by themselves.

The inspector shows:

- capability provenance/confidence;
- Text→Image / Image→Image / Inpaint / Reference state;
- whether a supported operation is currently executable by Image Studio;
- normalized technical parameters and discovered choice values;
- unknown states explicitly rather than hiding uncertainty.

## Still planned for v0.16.x

1. Structured creative Prompt Composer: Visual Style, Medium, Colour Palette, Lighting, Camera/Composition, Material/Surface, Atmosphere/Environment, and Modifiers.
2. Dynamic NanoGPT/provider model discovery using provider-supplied supported parameters and capability flags.
3. Local Stable Diffusion / Forge / A1111 model-family profiles and author overrides.
4. ComfyUI workflow Generation Profiles with explicit workflow-input mapping.
5. Image→Image, reference-image guidance, and inpainting execution where supported.
6. Global/project/character image style presets.
7. Generation history/results polish, exact settings reuse, and optional provider-supplied cost estimates.

## Validation

`tools/test_v0161_image_studio_foundation.gd` validates:

- Forge/A1111 normalization;
- tri-state unknown handling for generic APIs;
- backend support versus Studio execution readiness;
- provider-rich model records patterned after the discussed NanoGPT schema;
- provider-specific resolution values;
- max image count and rendering-speed/unknown additive parameters;
- pricing metadata preservation;
- user-override provenance;
- real `main.tscn` wiring to the v0.16.1 Image Studio;
- the passive capability summary/details controls.

The v0.16.1 broad-regression manifest inherits the complete v0.16.0/v0.15.40 release baseline.
