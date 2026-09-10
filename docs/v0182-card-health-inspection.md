# v0.18.2 — Card Health, Token and Interchange Inspection

Character Card Forge v0.18.2 adds deterministic inspection and reviewed interchange
tools without turning unusual creative choices into export blockers.

## Card Inspector

Open **Card Inspector** beside Revision History in the main workspace. Its six areas
keep distinct jobs separate:

- **Health** reports missing or malformed core fields, repeated material, custom
  metadata, broken references and unusually large sections. Every finding is advisory.
- **Tokens & Prompt** estimates the whole authored card and each contributing section
  using a deterministic character-count approximation. The compiled view is labelled
  as a CCF approximation because activated lore, frontend templates, chat history and
  runtime settings can change the actual prompt.
- **Technical Metadata** shows internal identity, Character Card format/version,
  extension keys and revision details without mixing them into normal authoring fields.
- **Expert Raw JSON** exposes editable character data only. CCF-managed revision,
  lineage and checklist data is hidden and preserved. Applying requires successful
  validation and a second explicit confirmation, with recovery checkpoints before and
  after the change.
- **Missing Assets** finds unresolved portraits, generated images, emotion images,
  attachments and card-workflow members. Replacement files are copied into the
  project's managed assets for portability; missing group members can be replaced by
  an explicitly selected character already in the project.
- **Quality Checklist** lets each character choose private checks for authored fields,
  artwork, lore, token budget, manual review and optional roleplay testing. Checklist
  state does not block export and is excluded from ordinary Character Card metadata.

## Reviewed import

Selecting a JSON or PNG card in Import / Export now produces a preview before any
current-project mutation. It shows the source portrait when available, detected
format/version, estimated authored token size, validation output, exact or same-name
library duplicate evidence and a field-disposition map.

The author then chooses **Import as New CCF Project**, **Import as Copy in Current
Project**, **Merge into Active Character**, **Replace Active Character** or **Cancel
Preview**. Merge and Replace require confirmation and create revision recovery points.
Replace retains the active character identity; Copy always receives a fresh ID.

## Migration and privacy boundaries

The migration assistant labels data as preserved, transformed, defaulted, namespaced,
review-required or potentially lossy. V2 lorebooks and vendor extensions remain
round-trippable. V1 imports identify where the older format cannot guarantee extension
preservation.

Inspection makes no provider calls. Raw JSON, checklist and private lineage data are
not inserted into normal Character Card V2 export. The public release version remains
unchanged until the normal release transaction publishes v0.18.2.
