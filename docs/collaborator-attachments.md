# Character Collaborator Attachments

Character Collaborator supports first-class reference attachments without requiring the author to paste large source material into the chat composer.

## Supported attachment formats

### Text-based references

- `.txt`
- `.md` / `.markdown`
- `.srt`
- `.ass`
- `.ssa`
- `.json`

Text attachments are read as UTF-8-compatible text, embedded into the Collaborator session as read-only reference context, and persisted with the conversation. The original source file is not modified. Subtitle timing, dialogue ordering, ASS/SSA style/speaker fields, JSON structure, and other source text are preserved verbatim rather than silently summarised or rewritten.

Each text attachment is limited to 4 MiB. Context-budget reporting includes attachment token cost so authors can see when a large script is consuming substantial model context.

### Images

- `.png`
- `.jpg` / `.jpeg`
- `.webp`

Images continue to use the existing Vision → Text pipeline. The configured Vision model receives the image and creates a grounded full-scene description. The Character Collaborator Text model receives only that description, never the original image payload.

## Removing attachments

Attachments are listed in **Reference Context** with their filename, format and estimated token cost. Removing an attachment removes it from future model context and autosaves the updated Collaborator session.

For image attachments, the persistent historical **Vision Analysis** transcript card remains visible after the active image reference is removed. This preserves what happened in the conversation while making it clear that the image-derived context no longer participates in future model calls.

## JSON versus Character Card import

**Attach Files…** treats `.json` as raw read-only reference material. It does not assume the JSON is a Character Card and does not normalise or write it into project data.

The existing **Import JSON / V2 PNG…** action remains the dedicated Character Card reference workflow and continues to normalise supported card data before adding it as reference context.

## Persistence and portability

Text contents are embedded into the saved Collaborator conversation rather than depending on the original file path continuing to exist. The source path is retained only as provenance. Images retain their Vision-derived description in the session, consistent with the existing image workflow.

## Design rule

Attachments are source material, not canonical character data. They can influence brainstorming, Blueprint generation and handoff only through the normal Collaborator context path. Nothing in an attached file directly modifies Workspace fields, Lorebooks, Alternative Greetings or project data.
