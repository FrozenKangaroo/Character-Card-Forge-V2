# v0.17.0 — Structured Image Studio → Collaborator Handoff

v0.17.0 connects Image Studio results to Character Collaborator without reducing a generated image to an anonymous attachment or silently changing character data.

## Result workflow

Select a generated image and choose **Send to Character Collaborator…**. The handoff dialog offers two explicit workflows:

- **Reference for the current character** opens Collaborator with the current Workspace character as the sole Compare & Apply target and the image as read-only Reference Context.
- **Start a new image-led conversation** opens a new Collaborator session with no existing character target. The image can seed a new character or broader visual-development conversation.

The action is unavailable while generation is active or when the selected image file is missing. Use the existing recovery action first when a managed result has lost its file.

## Structured provenance

The dedicated `image_studio_result` source preserves:

- managed image ID, project-relative and resolved paths, dimensions and creation time;
- project and character identity;
- exact composed and negative prompts;
- provider profile, backend and model;
- seed, sampler, steps, CFG and provider-specific parameters;
- image operation provenance, including source-image identity and denoise/mask settings where present.

Potential credential fields are removed recursively from provider-specific parameters. Preparing or opening a handoff does not mutate the project, character or result record.

## Raw image, prompt and Vision evidence

These inputs remain deliberately distinct:

1. The generated image is the raw visual source.
2. Its prompt/settings are creative intent and execution provenance, not proof that every prompted detail appears in the pixels.
3. Optional Vision analysis is a separately linked `vision_reference` produced by the configured Vision profile. The Text Collaborator receives that description as supplementary visual evidence and never claims to inspect the pixels directly.

Authors can request Vision during handoff or use **Analyse Image** / **Re-analyse Image** later from the source row. A Vision failure does not discard a successful structured handoff.

## Canonical safety

An Image Studio result is always a Reference source and can never become the Compare & Apply target. Existing character changes continue through Collaborator's explicit review/apply flow; new-character creation continues through its explicit completion destination flow.
