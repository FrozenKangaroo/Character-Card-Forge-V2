# v0.21.12 — Global AI response streaming

v0.21.12 adds one application-wide preference under **Settings → AI / Generation →
Stream AI responses**. It is off by default. When enabled, Character Card Forge asks
eligible OpenAI-compatible chat-completions endpoints for a real streamed response and
falls back to the established completed-response path when the endpoint opts out, rejects
streaming in a recognizable way, or returns an ordinary response envelope.

Streaming changes delivery and presentation only. It does not add prompt instructions,
change generated schemas, or move Idea Source or Direction Preset context. Every response
still uses the established structural parser and repair path. The normal checked path also
retains semantic validation and review; the explicit all-checks-off fast path is documented
below.

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

Provider reasoning/thinking channels are separated from final answer content. Recognized
reasoning fields and leading `<think>`, `<reasoning>` or `<analysis>` blocks are never sent
to the incremental JSON parser and are never shown as provisional Ideas. CCF reports only
that reasoning was detected, not the reasoning text.

The provisional AI Ideas list is bounded and scrollable. It follows new Ideas only while
the user is already near the bottom, so reading an earlier Idea is not interrupted. For a
split request, the panel shows the current batch and cumulative Idea count and keeps
completed earlier batches visible. Retry, stream fallback and JSON repair replace a failed
attempt's provisional cards with an explanation instead of silently clearing them.

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

## Idea Generator fast path

When Prevent Repeats, Final Request-Adherence Review, Final Similarity Review, the legacy
Final Idea Review and automatic top-up are all disabled, a structurally valid Idea array is
accepted after parsing and normalization. CCF does not compute duplicate fingerprints,
compare candidates, run semantic curation/repair, open final review or top up the batch in
that mode. This is useful for small or local models and avoids hidden extra model calls.

The fast path can still make another request when the response is malformed and the
existing one-shot JSON repair is required, when a configured network/HTTP retry runs, or
when a rejected/unsupported stream is retried through the completed-response fallback.
Turning any optional Idea check back on restores its established checked workflow.

## Provider scope and current limitations

Streaming is currently attempted for HTTP(S) OpenAI-compatible `/chat/completions`
endpoints unless a profile explicitly reports `streaming_supported: false`. Compatibility
varies across custom endpoints; fallback preserves ordinary generation, but the app does
not claim that every provider supports SSE.

Generation diagnostics record the transport used, stream retry count, JSON repair count,
fallback state and the kind of reasoning signal detected. Diagnostics never store or
display reasoning text, API keys or authorization headers.

The first progressive UI pass prioritizes readable prose in Character Collaborator and
complete objects in AI Ideas. Structured card, AI Fill, Front Porch and evaluator jobs
share the transport, safe-unit events and lifecycle states, while their existing final
preview/apply views remain the authority. More detailed per-field provisional rendering
can be added without another provider transport implementation.
