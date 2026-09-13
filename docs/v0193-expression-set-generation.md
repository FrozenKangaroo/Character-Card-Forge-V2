# v0.19.3 — Expression Set Generation

Character Card Forge v0.19.3 adds a managed, review-first way to create multiple
Front Porch expression images without introducing another image library.

## Workflow

Open Image Studio for a saved character and choose **Generate Expression Set…**.
Select any subset of Front Porch's 30 supported labels and one explicit visual
identity baseline:

- the current Image Studio prompt and creative style;
- the current character portrait as a reference image; or
- the currently selected Image Studio result as an Image-to-Image source.

Reference and Image-to-Image baselines are available only when the selected
Generation Profile proves that its transport can execute the required operation.
CCF does not guess that an OpenAI-compatible endpoint accepts image inputs.

Each selected label becomes one standard Image Studio request with batch size one.
The visible expression direction asks the provider to retain identity, design,
clothing, framing, lighting, background and style while changing the expression.
The directions live in `data/expression_directions_v0193.json` and use the exact
Front Porch label vocabulary.

## Review, retry and recovery

Every successful image first enters the character's ordinary Image Studio result
gallery. The expression batch stores only workflow state and a reference to that
result. Its exact composed prompt, negative prompt, profile/model, size, sampler,
steps, CFG, seed, provider parameters and image-input settings remain available in
the review window.

Results are accepted one at a time. A failed, cancelled or rejected member can be
retried without resetting successful siblings. Pausing preserves completed work.
If the Avatar Gallery already contains the exact label, ordinary acceptance stops
and requires the separate **Replace Existing Label…** action. Replacement removes
only the old gallery association; the older generated image remains recoverable.

## Front Porch boundary

Accepted members use the existing per-character Avatar Gallery and its exact
expression labels. Authors finish with the existing Import / Export Avatar Gallery
actions: portable expression ZIP export or an explicit supported authenticated Front
Porch gallery installation. Expression generation itself contacts only the selected
Image provider and never contacts Front Porch, writes its database, changes a
character portrait or installs an image automatically.

Batch history is bounded to the newest 12 batches per character. Provider
credentials remain in Settings and are never copied into project expression state.
