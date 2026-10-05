# v0.21.14 Idea Prompt Provenance

Character Card Forge now keeps the original AI generation prompt with each saved Idea.
This makes a good generation instruction reusable instead of leaving it only in the
temporary generation session.

## Save and reuse

When an AI-generated result is saved to Idea Library, its source metadata records the
complete prompt supplied to the generation service. Select the saved Idea to see
**Original AI prompt**, then choose **Send Prompt to Generator** to load it into AI Ideas.
The restored text remains visible and editable before another request is made.

The saved prompt is complete. CCF therefore clears any Idea Source that happens to be
active in the current generator before restoring it, preventing unrelated source context
from being appended a second time.

## Per-Idea accuracy

A working batch may contain Ideas from different requests. For example, the initial ten
Ideas may use one prompt while two Ideas appended through **Generate More Ideas…** use a
new direction. Each Idea retains the prompt belonging to the request that produced it.
Reviewing, deleting or appending Ideas does not replace that provenance with the latest
batch instruction.

## Saved-Idea fields

New AI-generated Ideas use additive source metadata:

```json
{
  "source": {
    "type": "idea_generator",
    "generation_prompt": "Generate reunions at an Antarctic research station.",
    "seed_prompt": "Generate reunions at an Antarctic research station.",
    "visible_instruction": "Set these at an Antarctic research station.",
    "prompt_mode": "additional_direction",
    "idea_source_id": "old-friend-returns",
    "idea_source_title": "Old Friend Returns"
  }
}
```

`generation_prompt` is the explicit current field. `seed_prompt` remains as a compatibility
alias for earlier CCF versions and external tools.

## Idea Packs

Idea Pack entries may include an optional top-level `generation_prompt` string:

```json
{
  "id": "whiteout-reunion",
  "kind": "seed",
  "title": "Whiteout Reunion",
  "summary": "A former friend arrives during an Antarctic whiteout.",
  "generation_prompt": "Generate reunions at an Antarctic research station."
}
```

The field is provenance only. It is not inserted into the Idea's conceptual text when the
Idea is used for character generation. Import restores the prompt so the Idea Library
reuse action remains available.

## Compatibility

- Existing saved Ideas with the historical `source.seed_prompt` field remain reusable.
- Older Ideas without any saved prompt still load and edit normally; the reuse action is
  disabled for those records.
- Existing Idea Packs without `generation_prompt` remain valid and importable.
- The Idea Pack schema version remains unchanged because the new field is optional and
  additive.
