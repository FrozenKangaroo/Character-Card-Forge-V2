# v0.16.3 — Image Studio Tabbed Workflow

## Goal

Keep Image Studio approachable as its capability-aware and structured-authoring systems grow. v0.16.3 reorganises the existing v0.16.2 Studio instead of replacing its controls or state model.

## Layout

The provider/model context remains visible above the workflow tabs. The primary working area is split into three tabs:

1. **Prompt & Results** — additional direction, editable prompt/negative prompt, generation actions, gallery and preview.
2. **Creative** — the provider-independent v0.16.2 Structured Creative Prompt Composer.
3. **Advanced** — capability inspection plus optional backend/model controls such as sampler, steps, CFG and seed.

This is progressive disclosure, not separate generation state. Changing tabs never creates a second prompt, second provider selection or second image session.

## Compatibility

- v0.16.2 structured creative selections and local composition remain authoritative.
- v0.16.1 capability/provenance controls remain live and move into Advanced.
- Existing Image Studio provider/profile/model discovery, image generation, prompt generation, gallery, portrait assignment and scheduler wiring remain inherited.
- Prompt and results stay the default tab.

## Future Collaborator handoff

A generated Image Studio result should later be sendable to Character Collaborator as a structured image source rather than a blind attachment. The handoff should preserve the raw image and source provenance, optionally retain generation prompt/model/settings metadata, and allow Vision-derived evidence to remain distinct from the image itself. This belongs with the later cross-tool structured-source/provenance work rather than v0.16.3's layout-only scope.

## Validation

`tools/test_v0163_image_studio_tabs.gd` loads the real application scene and verifies:

- the v0.16.3 shell and Image Studio are active;
- Prompt & Results, Creative and Advanced tabs are mounted;
- the prompt editor remains under Prompt & Results;
- v0.16.2 creative controls remain under Creative;
- sampler/technical controls and v0.16.1 capability inspection remain under Advanced;
- inherited v0.16.2 and v0.16.1 behaviours remain available.
