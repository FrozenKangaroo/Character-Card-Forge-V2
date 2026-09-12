# Import / Export Foundation

Character Card Forge v0.7 introduces a dedicated interoperability layer. External card files are translated into and out of the CCF project model; they are not used as the application's internal database.

## Import / Export Studio

Open **Import / Export** from the Character Workspace. The studio is a detachable native window with separate tabs for ordinary cards, portable projects, batch workflows and optional Front Porch interoperability.

## Front Porch connection, sync and deployment

v0.18.5 adds a **Front Porch Sync** tab beside the original direct-install surface. It
provides a copyable credential-safe diagnostic, authenticated remote-card and portrait
access, private install identity/fingerprints, complete authored-field comparison and
explicit Update/Reinstall or Import Front Porch Changes actions. Imports use the inspected
import and revision-recovery path; neither direction overwrites automatically.

A persistent sequential queue reports every install/update as succeeded, failed, skipped
or warning. The Library can filter private remote states and queued deployments without
making background network requests. Remote deletion and group-card direct install stay
disabled until the connected server explicitly proves the relevant supported endpoint.
There is never a direct Front Porch database fallback.

See `v0185-front-porch-reliability.md` for the complete state and safety contract.

## Front Porch avatar galleries

v0.17.5 adds an **Avatar Gallery** tab for alternate looks and labelled expressions. It can link existing portrait/Image Studio assets, import manual images, import/export Front Porch-compatible expression ZIPs, choose a canonical favourite independently from the CCF portrait and install selected or complete galleries through Front Porch's authenticated supported API. None of these actions silently changes ordinary Character Card artwork.

See `v0175-front-porch-avatar-galleries.md` for the complete role, provenance, filename and safety contracts.

## Front Porch worlds

v0.18.0 adds a **Front Porch Worlds** tab for manual world identity, embedded covers, optional climate/place traits, primary-lorebook entries and Stoop submission preparation. It imports and exports portable JSON `.fpworld` envelopes, accepts bare lorebooks and preserves unknown future fields plus additional lorebooks.

Every world export requires an explicit private-context review. Adult worlds require a second declaration confirmation. Stoop metadata can be prepared and checked locally, but v0.18.0 performs no direct publishing, network calls or Front Porch database writes.

See `v0180-front-porch-worlds.md` for the exact round-trip, editing and safety contracts.

## Export Card

The active character can be exported as Character Card V2 JSON.

Before export, CCF builds a compatibility report showing:

- the internal CCF source path;
- the target card field;
- whether the value is directly mapped, preserved, or namespaced;
- a summary of the current value;
- explanatory notes for fields without a direct standard-card equivalent.

### Export readiness safety

CCF blocks ordinary card export when **Description**, **Personality**, **Scenario** and **First Message** are all empty. This commonly means a Generation Concept was written but **Generate Character** was never run. Generate the character or manually complete at least one of those four fields before exporting.

If no usable image is attached, assigned as the portrait or available in generated images, CCF shows a confirmation warning. Authors can deliberately continue with a text-only JSON card or placeholder artwork after acknowledging it.

The same readiness rules cover single-card JSON/PNG export, split-card batches, Front Porch group cards and direct Front Porch character installation. Portable `.ccfproject` backups and expression-gallery ZIPs remain available for incomplete drafts because they are project preservation and asset-exchange formats rather than finished character exports.

The direct mapping currently includes:

| Character Card V2 | CCF project path |
|---|---|
| `data.name` | `character.name` |
| `data.description` | `character.description` |
| `data.personality` | `character.personality` |
| `data.scenario` | `character.scenario` |
| `data.first_mes` | `character.first_message` |
| `data.mes_example` | `character.example_dialogue` |
| `data.creator_notes` | `character.creator_notes` |
| `data.system_prompt` | `character.system_prompt` |
| `data.post_history_instructions` | `character.post_history_instructions` |
| `data.alternate_greetings` | `character.alternate_greetings` |
| `data.character_book` | `character.character_book` |
| `data.tags` | `metadata.tags` |
| `data.creator` | `metadata.creator` |
| `data.character_version` | `metadata.character_version` |
| `data.extensions` | `character.card_extensions` plus CCF extension data |

### CCF namespaced extension

Template-specific fields and other CCF-only character data may not have a direct Character Card V2 equivalent. CCF preserves them under:

```text
data.extensions["character_card_forge/v1"]
```

This extension can contain:

- the originating CCF project and character IDs for reference;
- the selected template ID;
- library summary and group role;
- concept data;
- template-specific field values;
- additional CCF custom character data.

The IDs are informational when imported as a new project; CCF still creates fresh local IDs where required.

Unknown extension keys that came from another application are kept separately in `character.card_extensions` and merged back during export.

## PNG cards

### Reading

CCF can inspect `.png` and `.apng` files for an embedded `chara` text metadata chunk, decode its Base64 JSON, validate it, and import the resulting card.

### Writing

The initial writer deliberately starts from an existing PNG image:

1. Choose **Export V2 PNG Card**.
2. Select the PNG image to use as the card artwork.
3. Choose a destination file.
4. CCF copies the PNG chunk stream, removes an existing `chara` text chunk if present, and inserts fresh V2 metadata before `IEND`.

The source image is not modified.

When importing a PNG card, CCF also copies the selected image into the new character's asset folder as `imported_card.png` and records it as the portrait reference.

## Import Card

The importer accepts:

- Character Card V2 JSON;
- Character Card V2 PNG/APNG metadata;
- legacy V1 JSON objects containing the six original card fields.

Every imported card becomes a **new CCF project**. Import never merges silently into the currently open project.

### Preserved data

CCF stores the following even when there is not yet a dedicated editor for it:

- `alternate_greetings`;
- embedded `character_book` lorebooks;
- arbitrary unknown `extensions` data.

This allows later export to retain data that CCF did not author.

### Tolerant normalisation

The importer reports malformed or missing V2 fields. Where practical, non-critical missing fields receive safe empty defaults so cards from imperfect ecosystem exporters can still be brought into CCF. The original source format and import timestamp are recorded under the character's interoperability metadata.

## Batch export

The Batch Export tab reads saved Card Workflow Studio entries with mode `split_batch`.

Choose a saved split-card workflow and an output directory. CCF exports every still-valid selected character as an individual V2 JSON card, using unique filenames when character names collide.

v0.7 does not yet automatically run full generation for every split-card member and does not yet batch-create PNG cards.

## Scope boundaries

Character Card V2 is fundamentally a single-character interchange format. CCF project-level information such as full rosters, shared context, relationship matrices, and card-workflow drafts therefore stays in the native CCF project and `.ccfproject` package rather than being forced into every exported card.

Selected character-specific CCF data is carried in the namespaced extension only to improve CCF-to-CCF round trips.

## CCF series references

Character Card V2 has no standard field for a Character Card Forge project series. v0.9 therefore adds `series_id` and `series_name` only inside the existing namespaced `character_card_forge/v1` extension.

On import, CCF restores `series_id` into the new project's metadata. The display name is informational; no standalone series definition is fabricated. Use `.ccfproject` or `.ccfseries` when the full series bible must travel with the content.
