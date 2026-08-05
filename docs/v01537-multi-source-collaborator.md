# v0.15.37 — Multi-source Character Collaborator

## Purpose

v0.15.37 lets one Character Collaborator conversation use several structured sources at the same time without flattening them into one invented character or losing their provenance.

A conversation may contain one explicit existing-character **TARGET** plus any number of read-only **REFERENCE** sources such as other Workspace characters, generated/saved Ideas, pasted source text, and external Character Card JSON/PNG files.

## Target and reference semantics

- At most one source may be the explicit TARGET.
- Only an existing Workspace character with a stable character ID can become the TARGET.
- v0.15.36 Compare & Apply continues to operate against that one target only.
- All other sources remain REFERENCE material and cannot be overwritten through the conversation.
- Source IDs, types, labels, author intent, roles, raw snapshots, AI-facing snapshots and provenance remain separate.
- When sources conflict, the model is instructed to identify the conflict rather than silently merge incompatible facts.

Existing v0.15.33 single-source Collaborator sessions are migrated into the v0.15.37 source collection when opened.

## Adding sources

### Existing Workspace characters

Use **Author → Add Current Character to Open Collaborator…**. Switch the Workspace to another character and repeat to build a cast/family/relationship reference set.

Starting an existing-character development conversation through the normal **Develop Current Character in Collaborator…** flow makes that character the initial target. A different eligible Workspace character can later be made the target explicitly from the source list.

### Saved Ideas

Use **Add Saved Idea…** in the Collaborator source area to choose an Idea Notebook entry as another reference.

Generated Ideas and existing source-aware handoffs remain compatible with the same v0.15.37 source schema, so a conversation that begins from an Idea may subsequently gain character/card/pasted references.

### Pasted source

Use **Paste Source…** for copied Character Card text, extraction text, or Character Card JSON.

If pasted JSON is a recognised Character Card, it is represented as an external card source. Otherwise pasted text remains a structured pasted-source reference.

### JSON / PNG Character Cards

The normal Collaborator **Attach Files…** path now attempts Character Card detection before falling back to the older attachment behaviour:

- recognised Character Card JSON/PNG/APNG → structured Collaborator source;
- ordinary JSON → normal text attachment;
- ordinary PNG/JPG/WebP → normal Vision attachment path.

External Character Cards are source references only. Attaching a card to Collaborator does not import it into the CCF Library.

## Embedded UserPersona exclusion

Some extracted cards include a separate roleplayer profile such as:

```text
<Character Persona>
...actual character source...
</Character Persona>

<UserPersona>
...profile belonging to the person who previously used the card...
</UserPersona>
```

That UserPersona is not character canon and must not become the identity of `{{user}}` in new authoring work.

v0.15.37 therefore keeps two representations of every source:

1. **Raw snapshot** — preserved unchanged for provenance/recovery.
2. **AI-facing snapshot** — normalised before it enters model context.

The normaliser excludes distinct UserPersona/user-profile residue expressed as tagged blocks, separate User Persona headings, or recognised structured fields such as `user_persona`/user-profile keys.

The rule is deliberately narrow. CCF does **not** delete normal character-source statements merely because they mention `{{user}}`.

For example, if the actual character card says that Miya has been `{{user}}`'s girlfriend for two years, that relationship remains established source canon. A separate block saying that the previous roleplayer was a particular age, nationality, appearance, name or hobby profile is excluded.

The AI-facing source contract states that `{{user}}` remains an unspecified roleplayer except for facts established by the actual character source or explicitly supplied by the author.

The source panel visibly reports when embedded UserPersona material was excluded.

## Persistence and provenance

- Multi-source collections are stored in Collaborator session documents as versioned `source_contexts` data.
- Removing a source removes it from future model context but does not rewrite the existing chat transcript.
- Raw snapshots remain local source evidence and are not modified by source normalisation.
- Source normalisation is applied again when sessions are loaded so older source material receives current exclusion rules.

## Compatibility

v0.15.37 retains:

- v0.15.36 Compare & Apply and Create Improved Copy semantics;
- v0.15.35 completion routing;
- v0.15.34 existing-character author-intent/provenance;
- v0.15.33 generated/saved Idea and Structured Builder source formats;
- v0.15.21 normal attachment/Vision fallback behaviour for files that are not detected as Character Cards;
- v0.15.36-hotfix3 deferred first-save protection;
- Forward+ as the desktop renderer with Compatibility fallback.

## Regression coverage

The focused v0.15.37 regression verifies:

- raw versus AI-facing source separation;
- tagged UserPersona exclusion;
- preservation of actual character-to-`{{user}}` relationship facts;
- one-target/many-reference semantics;
- saved Idea coexistence;
- multi-source model-context construction;
- actual Character Card PNG export/read-back as a Collaborator source;
- UserPersona exclusion from that PNG card's AI-facing context;
- real `scenes/main.tscn` v0.15.37 wiring and Workspace capability reporting.

The v0.15.37 broad manifest inherits all v0.15.36-hotfix3 and historical representative regression gates.
