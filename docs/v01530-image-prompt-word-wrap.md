# v0.15.30 — Image Prompt Word Wrapping

v0.15.30 fixes the remaining Image Studio text-editor regression after the v0.15.29 embedded-page and AI-prompt restoration.

## Problem

The **Image Prompt** and **Negative Prompt** controls were multiline `TextEdit` widgets, but line wrapping was not enabled. Long AI-authored Stable Diffusion prompts therefore appeared as one very long horizontal line inside the editor.

## Fix

Both live prompt editors now use:

```gdscript
TextEdit.LINE_WRAPPING_BOUNDARY
```

Their horizontal scroll offset is reset when the editor is configured. The underlying prompt text is unchanged; wrapping is presentation-only, so copying, editing, saving defaults, and image-generation requests still receive the original text.

The existing multiline/vertical-scroll behaviour is retained.

## Compatibility

This release intentionally does not alter the v0.15.29 prompt-generation contract:

- Image Studio remains embedded in the main application page.
- **Generate Prompt from Character** still uses the configured Character AI Text role.
- **Build Local Fallback** remains the deterministic no-provider alternative.
- Passive project/character browsing remains token-free.
- v0.15.28 saved-project handoff, Image-profile separation, and cached model/sampler discovery remain intact.

## Regression

The v0.15.30 real-main-scene regression opens the embedded Image Studio, obtains both live prompt `TextEdit` controls, inserts a long single paragraph into each, and verifies that Godot reports wrapped visual lines. This checks the actual runtime layout rather than only searching source code for the wrapping enum.
