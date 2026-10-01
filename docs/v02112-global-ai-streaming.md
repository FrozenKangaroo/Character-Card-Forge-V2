# v0.21.12 — Global AI response streaming

v0.21.12 adds one application-wide preference under **Settings → AI / Generation →
Stream AI responses**. It is off by default. When enabled, Character Card Forge asks
eligible OpenAI-compatible chat-completions endpoints for a real streamed response and
falls back to the established completed-response path when the endpoint opts out, rejects
streaming in a recognizable way, or returns an ordinary response envelope.

Streaming changes delivery and presentation only. It does not add prompt instructions,
change generated schemas, move Idea Source or Direction Preset context, or bypass the
existing parser, repair, semantic validation, review and application stages.

## Provisional and final content

The generation service owns HTTP chunking, SSE decoding, response accumulation, attempt
identity, fallback, retries and cancellation. Feature windows receive provider-independent
events tied to the stable job ID and current attempt.

Content shown before the complete response has passed normal checking is labelled
**Provisional**. It cannot be saved, applied, developed or otherwise committed as a final
result. The visible lifecycle distinguishes **Generating**, **Checking** and **Ready**.

- Character Collaborator shows ordinary reply prose as it arrives.
- AI Ideas shows an Idea only after its whole array member is safely parseable.
- Other structured generation surfaces report complete provisional units and generation
  phase without inserting incomplete JSON into project data.
- Small background tasks use the same transport but do not add intrusive animation.

## Structured output safety

The incremental parser is a conservative state machine, not a brace regex. It tracks
nested objects and arrays, JSON strings, escaped quotes and backslashes, commas and braces
inside strings, Unicode and chunks split at any byte/event boundary. An object field or
array member is emitted only after Godot's JSON parser accepts that complete unit.

The accumulated final assistant text is still handed to CCF's established full-response
parser, repair and validation pipeline. Incremental parsing is presentation framing, not a
second definition of valid generated content.

## Failure, retry and cancellation

Every streamed event carries a job and attempt identity. Starting a retry discards the
failed attempt's provisional buffer; delayed chunks from that attempt cannot mutate the
retry or another queued job. Cancellation closes the streaming transport as promptly as
the provider connection allows, removes provisional output and emits the normal cancelled
job state. Partial output is never promoted or saved.

A malformed event, timeout, premature stream end or HTTP failure enters the normal
retry/failure system. A successful endpoint that ignores `stream=true` is processed as an
ordinary completed response. No existing project, provider profile, card, Idea Source,
Idea Pack or Front Porch data requires migration.

## Provider scope and current limitations

Streaming is currently attempted for HTTP(S) OpenAI-compatible `/chat/completions`
endpoints unless a profile explicitly reports `streaming_supported: false`. Compatibility
varies across custom endpoints; fallback preserves ordinary generation, but the app does
not claim that every provider supports SSE.

The first progressive UI pass prioritizes readable prose in Character Collaborator and
complete objects in AI Ideas. Structured card, AI Fill, Front Porch and evaluator jobs
share the transport, safe-unit events and lifecycle states, while their existing final
preview/apply views remain the authority. More detailed per-field provisional rendering
can be added without another provider transport implementation.
