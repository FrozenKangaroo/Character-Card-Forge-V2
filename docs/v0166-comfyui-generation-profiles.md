# v0.16.6 — ComfyUI Workflow Generation Profiles

## Purpose

v0.16.6 introduces a versioned, provider-independent way to describe how Character Card Forge concepts map onto an arbitrary ComfyUI API workflow.

ComfyUI is deliberately treated as a **workflow execution backend**, not as an Automatic1111-style checkpoint endpoint. A Generation Profile stores the workflow snapshot and CCF mappings separately so authors can inspect, edit, migrate and validate those mappings without rewriting the workflow itself.

## Generation Profile format

Each profile contains:

- `format_version`
- stable profile `id`
- display `name`
- optional description
- complete ComfyUI API workflow JSON snapshot
- explicit CCF input mappings
- explicit image-output node mapping
- additive/unknown fields retained for future expansion

Mappings use node ID + input name and may describe their value type. Core CCF concepts currently include:

- Prompt
- Negative Prompt
- Seed
- Steps
- CFG / Guidance
- Width
- Height
- Denoise / Strength
- Reference Image

## Workflow materialisation

`CCFComfyUIGenerationProfileServiceV0166.materialise_workflow()` duplicates the saved workflow and applies only mapped values. Unmapped nodes, custom nodes and unknown workflow fields are preserved unchanged.

The service validates that required mappings point to existing workflow nodes and reports invalid/missing output mappings. Validation is local and makes no network request.

## Capability provenance

A Generation Profile can expose normalized Image capability information using the existing v0.16.1 capability document. Capability provenance is `workflow`, because support comes from explicit saved mappings rather than a provider model table or checkpoint-family assumption.

The v0.16.6 capability document does **not** claim live execution readiness. The workflow editor/materialiser is implemented here; live ComfyUI queue transport remains a separate execution step so CCF cannot accidentally send a ComfyUI workflow through the OpenAI-compatible or A1111 request path.

## Image Studio UI

The Advanced tab gains **ComfyUI Generation Profile** controls:

- enable the saved ComfyUI workflow profile for the selected Image profile
- profile ID and name
- editable ComfyUI API workflow JSON
- explicit node/input mappings for standard CCF concepts
- image output node
- Validate Profile
- Save Generation Profile

Opening or editing the panel does not make a network request.

## Compatibility

v0.16.6 extends v0.16.5 and preserves:

- local Forge/A1111 checkpoint profiles and explicit capability overrides
- v0.16.4 rich provider model capabilities
- v0.16.3 tabbed Image Studio layout
- v0.16.2 Structured Creative Prompt Composer
- v0.16.1 tri-state capability/provenance architecture
- v0.16.0 Collaborator rewind
- v0.15.40 public release metadata baseline

## Validation

The focused regression uses a synthetic ComfyUI workflow and performs no network calls. It verifies exact node/input materialisation, numeric coercion, preservation of custom nodes, invalid mapping rejection, workflow-derived capability provenance, non-execution-ready status, profile round-trip data and the real mounted v0.16.6 Image Studio surface under Godot 4.7.1.
