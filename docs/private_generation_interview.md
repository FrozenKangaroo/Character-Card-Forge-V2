# Private Pre-Generation Interview

v0.13.1 adds a V1-inspired private planning interview before full-character generation.

The interview is not another Character Card output format. Its answers exist only as temporary planning context inside the active generation job and are not applied to the project or exported as card fields.

## Generation flow

```text
Generate Character
  ↓
Private planning interview
  ↓
Required answers complete?
  ├─ no → targeted missing-answer retry (maximum 2)
  └─ yes
       ↓
Full character generation
       ↓
Semantic completeness validation
       ↓
Optional one-pass semantic repair
       ↓
Generation Preview
```

Network retries configured in Settings remain separate from the two missing-answer retries. Cancelling the active AI job cancels whichever stage is currently running.

## Default interview

When a template has no section whose kind is `interview`, Character Card Forge uses the bundled default interview in:

```text
data/generation_interviews/default.json
```

The current default asks about:

- core identity;
- primary motivation;
- inner conflict;
- the dynamic with `{{user}}`;
- boundaries;
- dialogue voice;
- important visual anchors;
- the opening hook;
- an optional private complication.

These questions are intended to make the model resolve useful connective character details before it has to write all card fields at once.

## Template-defined Interview / Q&A sections

Template Manager already supports the **Interview / Q&A** section kind. v0.13.1 gives that kind a specific role during full-character generation.

When at least one Interview / Q&A section exists, its AI-generatable fields replace the bundled default questions.

For an interview field:

- `id` is the JSON key requested from the planning pass;
- `label` is the human-readable name shown in planning notes;
- `generation_prompt` is the question/instruction;
- `generate = true` means the question participates in the private interview;
- `required = true` means generation cannot proceed while that answer is missing;
- the field's project path may contain a manually entered answer.

A manually entered non-empty value is treated as an already answered planning question. The AI is not asked to replace it, and the value is included in the private planning context for the final generation.

If a template contains an Interview / Q&A section but none of its fields are AI-generatable, the automatic interview is effectively disabled for that template. This provides an editor-compatible opt-out without introducing a separate hard-coded template ID list.

## Missing-answer retry

After the first interview response, Character Card Forge checks every required question.

If required answers are missing, it sends a second request containing only the missing required questions plus the answers already obtained. This can happen at most twice.

If required answers are still missing after the second targeted retry, the character-generation job fails cleanly and no full-card request is started.

Optional unanswered questions do not block generation.

## Privacy and persistence

AI-generated interview answers are intentionally ephemeral:

- they are not written to character project fields;
- they are not emitted as Character Card fields;
- they are not stored in completed-job metadata;
- completed metadata stores only counts, whether the bundled/default interview was used, and retry statistics.

The completed answers are appended to the full-character request under an explicit **PRIVATE PRE-GENERATION INTERVIEW NOTES** block. The model is told to use them as planning context, not to copy the question/answer framing into the card or mention that an interview occurred.

Manually entered values in a custom Interview / Q&A workspace field remain ordinary project data because the user entered them deliberately. The automatic AI answers do not overwrite those fields.

## Interaction with generation components

The private interview and generation components solve different problems:

- **Interview questions** resolve planning decisions before card writing starts.
- **Generation components** define the labelled structure expected inside output fields such as Description and Personality.
- **Semantic repair** checks the finished card against the output contract.

A typical run may therefore use all three layers:

```text
concept → interview planning → structured generation → semantic validation/repair → review
```

## Compatibility

No project-format or template-format bump is required for this slice.

Older templates with no Interview / Q&A sections use the bundled default interview. Existing Interview / Q&A sections become private planning definitions for full-character generation, while their workspace fields remain available for manual planning notes and per-field AI suggestions.
