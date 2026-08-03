# v0.15.29 Image Studio Regression Restoration

v0.15.29 restores two established Image Studio behaviours that regressed in v0.15.28 while preserving the newer live-project and Image-provider state fixes.

## Embedded main-navigation presentation

Image Studio is a first-class main application page. Selecting **Image Studio** from the navigation must show the studio inside the normal Character Card Forge workspace rather than displaying its controller `Window` as a native popup.

The native Window object remains an implementation detail because the existing image-generation controller was originally built as a detachable/native tool. `CCFImageGenerationPage` hosts that controller UI inside the main workspace and provides the established vertical scroll viewport. Normal Image Studio navigation must keep the native controller window hidden.

v0.15.28's direct Workspace-save handoff, current-project preference, Image-profile selection, and persistent model/sampler discovery remain active inside the embedded page.

## AI-authored Character → image prompt

The normal character-to-image prompt action is **Generate Prompt from Character**.

It uses the configured Character AI **Text** role to author a purpose-built image-generation prompt from the selected character. The model receives useful source material such as:

- physical/visual Description;
- Scenario;
- visually useful Personality context;
- First Message/opening-scene context;
- Generation Concept when available;
- explicit Additional visual direction.

The Text role is instructed to preserve established physical identity while converting only visually expressible narrative information into pose, expression, action, composition, setting, lighting, or atmosphere. It must write a new image prompt rather than mechanically copy or concatenate Character Card prose.

Stable Diffusion mode requests concise ordered visual prompt language. Natural mode requests concise modern image-model art direction. The response may also contain an optional negative prompt.

## Local fallback remains separate

**Build Local Fallback** remains the deterministic, token-free path. It uses the local visual-anchor prompt builder and does not call the Character AI Text provider.

This distinction is intentional:

- **Generate Prompt from Character** = AI-authored prompt through the configured Text role.
- **Build Local Fallback** = deterministic local extraction/construction without a provider request.

## Passive browsing must not spend tokens

Loading Image Studio, loading a project, or switching characters must never start prompt generation automatically. The inherited `_build_prompt_from_character()` refresh hook is therefore passive in v0.15.29.

Only the explicit **Generate Prompt from Character** action queues the Text request. If the active character changes before that request completes, its result is not applied to the new character.

## Current scheduler integration

The restored prompt writer is not wired back to the old v0.13.12 service implementation. `CCFImagePromptGenerationServiceV01529` preserves the established v0.13.12 prompt contract while inheriting the current v0.15.26 scheduler-aware generation stack.

This means image-prompt Text requests participate in the same current Text/global concurrency management rather than bypassing newer AI scheduling architecture.

## Regression history

The intended behaviours were already established earlier:

- the separated Image-provider work made Image Studio a selected main navigation page;
- v0.13.12 introduced AI-authored **Generate Prompt from Character** plus **Build Local Fallback**;
- the v0.13.12 startup hotfix separated passive project/character refresh from explicit AI prompting;
- the later Image Studio layout hotfix placed the embedded controller UI inside a scroll viewport.

v0.15.29 treats these as compatibility contracts and adds real-main-scene regression coverage so future Image Studio state work cannot silently replace them again.