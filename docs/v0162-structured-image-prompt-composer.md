# v0.16.2 — Structured Creative Prompt Composer

## Purpose

v0.16.2 is the first user-facing Image Studio 2 creative-authoring layer built on the normalized capability foundation introduced in v0.16.1.

The central rule remains:

> Creative image intent is provider-independent; generation capabilities are provider, backend, model, or workflow specific.

The structured controls therefore do not know or care whether the selected Image profile ultimately uses a cloud API, NanoGPT-style provider metadata, Forge/Automatic1111, or a future ComfyUI workflow profile.

## External creative catalog

Creative choices live in `data/image_prompt_catalog_v1.json` rather than a hardcoded UI table. The catalog is explicitly versioned and currently contains:

- Visual Style
- Medium
- Camera / Composition
- Lighting
- Colour Palette
- Material / Surface
- Atmosphere / Elements
- multi-select Modifiers

Each option has a stable ID, display label, and prompt contribution. Future builds can extend the catalog without redesigning the composer service.

## Prompt composition

`CCFImagePromptComposerServiceV0162` is UI-independent. It accepts:

1. an optional base/subject prompt;
2. structured category selections;
3. selected modifiers;
4. the versioned catalog.

The deterministic contribution order is:

`base subject → visual style → medium → composition → lighting → palette → material → atmosphere → modifiers`

Exact selected phrases already present in the base prompt are not blindly duplicated when controls are reapplied.

The service also returns structured contribution metadata so the UI can explain what each active control adds.

## Image Studio UI

Image Studio adds a **Structured Creative Controls** panel above the existing editable Image prompt area.

The panel contains:

- an optional **Base / subject** field;
- one selector for every catalog category;
- multi-select modifier switches;
- **Compose into Image Prompt**;
- **Reset Controls**;
- a live contribution summary.

If Base / subject is blank, composition uses the current Image prompt as the base. This allows the existing **Generate Prompt from Character** and deterministic local fallback workflows to feed directly into structured art direction.

Composition is entirely local and does not call a Text, Vision, or Image provider. The resulting Image prompt remains ordinary editable text. Resetting creative controls intentionally leaves the current Image prompt unchanged.

## Compatibility

v0.16.2 inherits the complete v0.16.1 Image capability inspector and all historical Image Studio generation behaviour. Existing prompts, negative prompts, generated image records, provider profiles, Forge/A1111 controls, character selection, AI prompt generation, local prompt fallback, and capability caches are unchanged.

This release does not yet implement provider-specific dynamic technical controls, local checkpoint-family overrides, ComfyUI workflow mappings, img2img/reference/inpainting execution, or reusable creative presets; those remain later Image Studio 2 phases.

## Regression coverage

`tools/test_v0162_structured_image_prompt_composer.gd` verifies:

- the external catalog loads and is versioned;
- representative selections across all categories validate;
- deterministic composition ordering;
- contribution metadata;
- duplicate-phrase protection when reapplying controls;
- real `main.tscn` wiring to v0.16.2;
- visible mounted creative controls;
- provider-independent capability advertisement;
- preservation of the v0.16.1 capability surface.

`tools/regression_suites_v0162.json` inherits the entire v0.16.1 regression baseline and adds the focused v0.16.2 test.
