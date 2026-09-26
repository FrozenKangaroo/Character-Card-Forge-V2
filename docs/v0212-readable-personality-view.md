# v0.21.2 Readable Personality View

## Purpose

Generated Personality fields can contain dozens of labelled sections. Models do not
always place blank lines between those sections, which makes an otherwise useful result
difficult to review. CCF now provides a readable presentation without rewriting the
card.

## Presentation contract

- The canonical Personality string remains exactly as authored or generated.
- Readable view inserts blank lines only in the display control.
- **Edit text** reveals the canonical editable `TextEdit`.
- **Readable view** returns to the display-only representation.
- Workspace capture, project saves, Character Card exports, provider context and token
  estimates continue to use the canonical string.

The same view is available in the generated-field review before an author applies a new
Personality value.

## Heading recognition

CCF recognises enabled Personality generation-group titles and component labels from the
active template. It also recognises conservative common labels such as `Mind:`,
`Moral Alignment:`, `Sexual Traits:` and `Background:`. Existing line-start labels are
detected even when they are custom, while known labels can be separated when a model
returns them inline after a completed sentence.

Ordinary prose such as `She explains: this remains ordinary prose.` is not split. The
formatter does not summarise, reword or otherwise interpret content.

## Compatibility

No project, card, template or interchange schema changes. Existing content is rendered
on demand and requires no migration.
