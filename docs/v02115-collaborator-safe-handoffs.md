# v0.21.15 — Character Collaborator Safe Handoffs

Character Collaborator can send a finished conversation to Workspace as either a
Generation Blueprint or a Detailed Workspace Draft. v0.21.15 gives this handoff its own
build strategy instead of silently inheriting the normal **Generate Character** setting.

## Choose the handoff strategy

Open **Settings → AI / Generation → Character Collaborator → Workspace**.

- **Safe Section Build — Recommended** freezes the current conversation, reference/evidence
  context and compressed memory, then builds the canonical Generation Concept one section
  at a time. Each completed section is continuity context for later sections but is not
  regenerated. A Detailed Workspace Draft then uses the existing template-aware validated
  Safe Section engine for its card fields.
- **Single Response — Faster / fewer requests** retains the established one-request
  Collaborator handoff. It is useful when provider cost or latency matters more than the
  additional protection for very long concepts.

This preference does not change **Generation strategy** for ordinary Generate Character.

## Incomplete Generation Concept recovery

Both handoff strategies require a stable sequence of canonical headings. When
the concept is missing a heading, contains an empty section, or ends partway through a
section, CCF finds the first unsafe boundary.

CCF then:

1. preserves every complete section before that boundary;
2. sends the original Collaborator evidence back to the model;
3. requests a replacement beginning at the malformed section and continuing through every
   remaining section, as one tail in Single Response or section-by-section in Safe Section
   Build;
4. joins the accepted prefix to the validated replacement tail;
5. applies nothing if that one bounded repair is still incomplete.

Malformed JSON uses a conservative string scanner that understands escapes and Unicode.
It does not search for a closing brace with a regular expression, so braces inside a
character quote or example dialogue do not end recovery early.

## Safety and limits

- Handoff output remains provisional until the complete flow succeeds.
- Failed section, field or supplementary generation never partially changes Workspace.
- Safe Section Build makes more provider requests.
- Alternative Greetings and Lorebook material are finalised together after the safe
  blueprint and, for Detailed Workspace Draft, the validated fields.
- Existing projects, Collaborator conversations, templates and Character Cards need no
  migration.
