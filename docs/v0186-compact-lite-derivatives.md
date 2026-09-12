# v0.18.6 Compact/Lite Derivatives

v0.18.6 adds **Create Compact/Lite Derivative…** to the Character Workspace for finished characters. This workflow creates a separate character; it never rewrites or compresses the source record in place.

## Compression controls

The author chooses an approximate whole-card target budget and one of four intent levels:

- **Gentle** removes repetition while retaining most texture;
- **Balanced** tightens every major field while preserving voice and hooks;
- **Aggressive** prioritises playable essentials and distinctive traits;
- **Extreme** retains the smallest coherent roleplay-ready core.

The suggested budget derives from Card Inspector's deterministic character-count estimate. Before and after values remain approximate because exact tokenization depends on the eventual model and runtime prompt.

Independent preservation controls cover lorebook material, alternative greetings, examples, Front Porch/state fields, adult traits, tags and image-prompt material. Preserved examples are not sent for compression. Front Porch private install identity is never copied to a derivative.

## Review boundary

Generation uses the configured Text profile and the shared AI Jobs scheduler. The source content hash is captured with the request; a result is discarded if the source or active character changes while it runs.

Every compactable authored field appears in a complete side-by-side comparison. Source values are read-only. Candidate values are fully visible, wrapped and editable, and each can be deselected to retain the source value. The **Create** action remains disabled until a valid complete preview has been displayed and requires a final confirmation.

## Independent character, lineage and provenance

Final creation appends a new character with a fresh stable ID and the chosen name. The source is re-hashed immediately before creation; stale previews fail closed.

Private lineage records the source project, source character, newest source revision when available, source content hash and derivation kind. Private provenance records the actual producing model/profile, compression level, target, estimated result and preservation choices. The derivative receives its own initial revision checkpoint.

Lineage, model/profile provenance, review history and Front Porch install identity remain outside ordinary Character Card V2 JSON/PNG exports. Assets and explicitly preserved authored data remain ordinary project references/data; the derivative is otherwise independently editable after creation.
