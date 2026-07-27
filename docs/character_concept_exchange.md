# Character Concept Exchange — Planning Notes

Character Concept Exchange is a later Character Card Forge feature for importing and exporting **pre-generation source material**. A concept document is not a completed Character Card and is not a snapshot of the internal project or template schema.

The exact file extension and JSON schema are intentionally **not frozen yet**. The generation/template architecture, especially the v0.13 Q&A system, should stabilise first so concept files do not need disruptive format changes every few releases.

## Intended workflow

An external AI, another writing tool, or Character Card Forge itself can flesh out a rough character idea into a structured concept document. Character Card Forge imports that document through a review/mapping step, then uses the normal Forge pipeline — active template, generation components, Q&A, builders, concept-fidelity checks, semantic repair, and Generation Preview — to create the finished character.

A concept should remain valid even when most optional sections are absent. The authoritative main concept is the minimum useful payload.

## Planned concept material

The future format may carry:

- authoritative main concept;
- identity ideas;
- physical/visual direction;
- personality direction;
- background/history;
- relationships;
- setting/world information;
- scenario and opening ideas;
- constraints and must-preserve facts;
- freeform planning notes;
- Q&A planning material.

These are source/planning concepts, not final Character Card output fields.

## Q&A support

Once the Character Card Forge Q&A system and Q&A-template format are stable, concept documents should support two distinct kinds of Q&A data.

### Template Q&A answers

A concept may contain answers to questions that belong to a recognised Character Card Forge Q&A template. The format should preserve enough information to map those answers safely when imported, without assuming that an internal template identifier will remain meaningful forever.

Possible identifying information may include a stable question ID plus the question text and answer. The exact representation should be chosen only after the Q&A-template design is finalised.

On import, Character Card Forge should review/map compatible answers into the active Q&A plan. An answer should not be silently discarded merely because the importing user has selected a different Q&A template.

### Extra Q&A

A concept may also carry arbitrary one-off question/answer pairs that are **not part of the Q&A template**. This restores the useful V1 behaviour where a particular character could have extra planning questions without those questions becoming permanent reusable template entries.

Examples might include:

- `What happened the last time {{char}} told someone about this hobby?`
- `What specific object does {{char}} always carry?`
- `Why does {{char}} distrust this particular organisation?`

Extra Q&A belongs to that concept/character unless the user explicitly promotes a question into a reusable Q&A template later.

Imported extra Q&A should be available to generation as private planning context in the same way as ordinary completed Q&A. It should not automatically become Character Card output text.

## Import behaviour

The eventual importer should distinguish between:

1. recognised template questions with supplied answers;
2. supplied answers whose original template question cannot be matched safely;
3. explicitly extra/custom Q&A;
4. unanswered questions from the currently selected Q&A template.

The review step should allow the user to keep unmatched answers as supplemental Q&A, map them to a current question, ignore them, or promote an appropriate extra question into the current reusable Q&A template.

After import, the ordinary Q&A completeness system may ask only the still-required unanswered questions rather than regenerating or overwriting answers already supplied by the concept.

## Stability goals

- Concept format versioning is independent from Character Card, project, template, and Q&A-template format versions.
- The concept schema should remain higher-level than internal implementation details.
- Optional sections and sensible defaults should allow older concepts to remain useful as Forge evolves.
- External AI assistants should eventually have a published schema/example describing how to produce a valid concept document.
- The future format should support concept export, refinement elsewhere, and re-import without requiring the concept to become a finished Character Card first.
