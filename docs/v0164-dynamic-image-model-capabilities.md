# v0.16.4 — Dynamic Provider Model Capabilities

v0.16.4 connects the normalized Image capability architecture introduced in v0.16.1 to rich provider model discovery and the v0.16.3 Advanced tab.

## Goals

- Prefer provider endpoints that describe image models with model-specific capability and parameter metadata.
- Keep compatibility with older provider endpoints and generic OpenAI-compatible `/models` responses.
- Never hardcode a table of NanoGPT/provider model IDs.
- Preserve unknown/additive provider metadata for future models and API fields.
- Keep passive Image Studio browsing provider-free: cached metadata is used until the author explicitly presses Refresh.
- Treat a model disappearing from the latest provider list as a recoverable state, not a reason to silently switch models.

## Discovery order

For OpenAI-compatible Image profiles, the v0.16.4 discovery service tries:

1. `/api/v1/images/models`
2. `/api/v1/image-models`
3. `/models`

Forge / Automatic1111 continues using its existing WebUI model/sampler discovery path. The first endpoint that returns a parseable model catalog wins.

Rich provider model records may contain fields such as:

- `id`, `name`, `description`, `owned_by`
- `capabilities`
- `supported_parameters`
- `pricing`
- tags/content metadata
- provider-specific future fields

The raw provider record remains retained. It is normalized through `CCFImageModelCapabilityServiceV0161` for common CCF controls while additive fields remain available.

## Cache and refresh behavior

Each Image profile can store a versioned `image_model_catalog_v0164` document containing:

- the endpoint that supplied the catalog
- fetch timestamp
- raw normalized model records
- model IDs
- whether rich metadata was present

Opening or browsing Image Studio does not automatically perform discovery. The existing Discover action becomes **Refresh Model Capabilities**, and the Advanced tab also exposes an explicit Refresh button. Cached metadata is used for passive browsing.

A manually selected model that is absent from the latest catalog is retained and marked `model_missing_from_latest_catalog`; the Studio warns instead of silently choosing another model.

## Dynamic Advanced controls

The Advanced tab builds a **Dynamic model parameters** surface from the selected model's authoritative provider metadata.

Known normalized fields reuse existing CCF controls where practical:

- provider resolution strings populate a size selector and remain opaque strings
- maximum/fixed image counts constrain Batch

Other supported parameters create generic controls according to provider metadata:

- choice → `OptionButton`
- boolean → `CheckButton`
- integer/number/text/unknown scalar → `LineEdit`

This supports known fields such as quality or rendering speed while also allowing future additive parameters without a CCF release that hardcodes each field name.

## Generation payload

`CCFImageGenerationServiceV0164` carries the selected dynamic provider parameters into OpenAI-compatible image generation payloads. Core fields (`model`, `prompt`, `n`, `size`) cannot be overwritten by dynamic provider parameters.

Forge/A1111 payload behavior remains unchanged in this release.

## Pricing

Provider-supplied pricing metadata is retained and displayed as metadata in Advanced. v0.16.4 does not invent a cost estimate when the provider's pricing schema is not sufficiently explicit. A more polished estimated-cost presentation can build on the preserved metadata later.

## Compatibility

v0.16.4 preserves:

- v0.16.3 tabbed Image Studio workflow
- v0.16.2 Structured Creative Prompt Composer
- v0.16.1 normalized tri-state capability/provenance architecture
- legacy cached Image discovery
- Forge/A1111 discovery and generation behavior
- existing scheduler/gallery/prompt workflows

The public release metadata remains on the last promoted release until the normal release transaction is run.
