# v0.16.9 — Image Style Presets

v0.16.9 adds reusable, provider-independent visual style presets to Image Studio.

## Scope

Image Style Presets capture **creative intent only**. They store the Structured Creative Prompt Composer selection from v0.16.2: visual style, medium, composition, lighting, colour palette, material/surface, atmosphere/elements and modifiers.

They deliberately do **not** store provider, model, checkpoint, sampler, steps, CFG, seed, ComfyUI workflow, transport mapping or other technical execution settings. Those remain in the existing Image provider/profile architecture.

## Preset layers

### Built-in presets

`data/image_style_presets_v0169.json` is a versioned external catalog of starter styles. The first catalog includes Anime Key Visual, Cinematic Portrait, Natural Character Photo, Fantasy Concept Art and Monochrome Manga.

Built-ins are read-only examples and remain portable because they reference stable IDs from the v0.16.2 creative prompt catalog.

### Global presets

**Save Global** captures the current Structured Creative controls into a reusable user preset stored under `user://character_card_forge/settings/image_style_presets_v0169.json`.

Global presets are independent of any one Character Project and can be applied across projects and Image providers.

### Project visual identity

**Set Project Identity** stores the current creative selection inside the project metadata. It becomes the project's default visual direction in Image Studio.

### Character defaults

**Set Character Default** stores a character-specific creative selection in that character's generation metadata. Character defaults override the project visual identity. Clearing the character default reveals the project identity again.

## Application behaviour

Applying a preset populates the Structured Creative controls. It does not immediately rewrite the editable Image Prompt. The author can review the selections and use the existing **Compose into Image Prompt** action when ready.

Project/character defaults are applied to the Creative controls when the relevant saved project/character becomes active. This is a presentation/authoring default, not a provider request.

Preset browsing, application and editing never call a provider and therefore do not spend provider credits.

## Compatibility

- Existing projects require no migration.
- Existing v0.16.2 creative selections and v0.16.8 image-input operations remain unchanged.
- Unknown extra project/character fields remain additive through the existing project model.
- Public `VERSION` remains v0.15.40 during the v0.16.x development line.
- Godot baseline remains 4.7.1 stable, Forward+ with Compatibility/OpenGL fallback.

## Validation

`tools/test_v0169_image_style_presets.gd` verifies:

- built-in preset catalog loading;
- every built-in selection references valid creative catalog IDs;
- global preset persistence round-trip;
- project visual identity storage;
- character-default precedence over project identity;
- fallback to project identity after clearing a character override;
- real `main.tscn` v0.16.9 wiring;
- preservation of the v0.16.8 shell;
- explicit exclusion of technical provider/model settings from the style-preset contract.
