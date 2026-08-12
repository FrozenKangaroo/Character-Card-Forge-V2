# v0.16.5 — Local Stable Diffusion / Forge / A1111 Profiles

## Purpose

v0.16.5 adds checkpoint-specific authoring profiles for local Forge / Automatic1111 Image providers. It builds on v0.16.4 dynamic provider/model capabilities without assuming that every locally installed checkpoint behaves identically.

## Capability layers

Local Image capability state now has three explicit layers:

1. **Backend discovery** — facts exposed by Forge/A1111 endpoints, such as available checkpoints and samplers.
2. **Checkpoint family/profile metadata** — optional authoring defaults and notes for one selected checkpoint.
3. **User overrides** — explicit operation/parameter state corrections for that checkpoint.

Family selection never automatically proves that a checkpoint supports a capability. Capability overrides retain `user_override` provenance and user-defined confidence through the v0.16.1 normalized capability service.

## External family catalog

`data/image_local_model_families_v1.json` is a versioned editable catalog. Initial families include generic/unknown, Stable Diffusion 1.x, SDXL, Pony/SDXL-derived and Illustrious/SDXL-derived profiles.

Family entries contain optional workflow defaults such as preferred resolution, steps and CFG. They are not hardcoded capability tables.

## Checkpoint profiles

Each Forge/A1111 Image profile may persist checkpoint records under `local_model_profiles_v0165`, keyed by the exact discovered/manual checkpoint ID. A checkpoint profile may contain:

- family ID;
- author notes;
- preferred resolution, sampler, steps and CFG;
- explicit operation overrides;
- explicit technical-parameter overrides.

Removing/resetting a checkpoint profile returns it to inherited backend behavior without deleting the actual local checkpoint or provider profile.

## Image Studio UI

The Advanced tab gains **Local checkpoint profile**, visible only for Forge/A1111 Image profiles. It provides:

- model-family selector;
- checkpoint notes;
- preferred generation defaults;
- Apply Profile Defaults;
- Auto / Supported / Unsupported / Unknown selectors for core operations and technical parameters;
- Save Checkpoint Profile;
- Reset Checkpoint Profile.

`Auto` deliberately means “use inherited capability information.”

## Compatibility

v0.16.5 preserves:

- v0.16.4 dynamic rich provider capabilities;
- v0.16.3 tabbed Image Studio workflow;
- v0.16.2 Structured Creative Prompt Composer;
- v0.16.1 normalized tri-state capability/provenance model;
- existing Forge/A1111 discovery and generation;
- generic OpenAI-compatible Image profiles;
- the v0.15.40 public release metadata baseline.

## Validation

`tools/test_v0165_local_sd_profiles.gd` validates external family data, family/default merging, explicit user overrides and provenance, checkpoint-profile round-trip data, and the real mounted v0.16.5 Image Studio. The dedicated Godot 4.7.1 workflow also rechecks v0.16.4 through v0.16.1 and treats integer-division warnings as failures.
