# Multi-Batch Diversity Guardrails

Large Idea Generator runs may require several model requests. Without shared memory,
each request can independently rediscover an earlier scenario with a new title, name,
occupation or location. CCF now treats those requests as one temporary generation
session.

## Accepted ideas are the target

The Ideas count means the number of accepted, usable ideas CCF should try to produce.
Rejected validation results and clear local duplicates do not fill that target.

After each normal request, CCF recalculates:

`remaining = requested target - accepted count`

The next request asks for the smaller of that remaining count and the configured **Ideas
per provider request** limit. A 21-idea run using 12 per request therefore normally asks
for 12 and 9. If only 11 ideas from the first response survive, the next request asks for
10 instead.

The number of normal provider requests remains bounded by the original plan. CCF does
not keep retrying until the target is filled.

## Temporary diversity ledger

During one Generate action, CCF keeps an in-memory ledger containing:

- an internal session ID, title and compact scenario fingerprint for each result;
- whether it was accepted or rejected; and
- a rejection reason when available.

The fingerprint is derived at generation time from the idea's premise, hook and other
available structural text. Character names are excluded from the inexpensive structural
comparison. The ledger is discarded when the generation session finishes and does not
change Idea Notebook, `.ccfideas.json` Idea Packs or `.ccfideasource.json` Idea Sources.

## Later request guidance

With **Prevent repeats across batches** enabled (the default), every request after the
first receives compact sections for:

- ideas already accepted in this generation; and
- ideas rejected as invalid, duplicate or too similar.

The prompt explains that changing a name, title, cosmetic trait, occupation term,
scenery or location is not structural novelty. It asks the model to explore unrepresented
relationship structures, motivations, initiating events, third-party roles, objectives,
consent or secrecy structures, conflicts, reveals, openings, consequences and emotional
dynamics where relevant.

The original Idea Source, ordinary prompt, Additional Direction, Series context, detail
setting and generation contracts remain in the request. The ledger augments those
instructions; it does not replace them. Generate Similar Ideas may legitimately retain
the source card's reusable engine while its generated results must still differ from one
another.

## Title warnings and structural comparison

CCF cheaply flags identical titles, case/punctuation/apostrophe variants and very obvious
near-title spellings. A title warning is only a comparison signal. It never rejects an
otherwise distinct idea.

Local automatic rejection is deliberately conservative. It is limited to effectively
identical structural fingerprints or extremely high structural-token overlap. Related
variants remain valid when their intent, consent, knowledge, duration, reveal,
uncertainty, consequences or ongoing roleplay engine materially differ. Different titles
do not protect an otherwise identical premise.

## Optional final AI similarity check

The **Final AI similarity check** control defaults to **Off** because it uses one extra
model request.

- **Off** performs no final AI comparison.
- **Flag Similar Ideas** shows clusters classified as duplicate, near-duplicate or
  related-but-distinct and keeps every result.
- **Reject Clear Duplicates** keeps the first representative of clusters classified as
  clear duplicates. Near-duplicates and related-but-distinct variants remain.

The review sends compact IDs, titles and scenario fingerprints rather than full
character-card-sized records. Its report explains each cluster. Reject mode is explicit
and conservative; it never rewrites ideas already saved in Idea Notebook.

## Optional one-shot top-up

**One final top-up request if short** is also off by default. After normal requests,
validation and any final AI rejection, it can make exactly one additional request for
the missing count, bounded by the configured provider-request limit.

The recovery request receives the accepted and rejected ledger, original source and
Additional Direction, and explicit replacement/novelty guidance. Recovery results still
undergo validation, title warnings and structural duplicate checks.

There is no retry loop. If a request for three replacements produces only two usable
ideas, the session ends at 29/30 and reports that result.

## Progress and usage

Status messages report accepted ideas against the target, along with raw and rejected
counts. They also identify batch generation, final similarity review and the one-shot
recovery phase. Raw rejected responses are never presented as completed target ideas.

Repeat prevention itself adds prompt context but no extra request. **Final AI similarity
check** can add one model call. **One final top-up request if short** can add one more.
Enabling both may therefore add up to two provider calls beyond the bounded normal batch
plan.

## Manual verification

Before release, perform one real provider run with at least two batches and confirm:

1. the second request status uses the accepted count from the first response;
2. Additional Direction and an active Idea Source still influence later batches;
3. Flag mode opens a readable report without removing ideas;
4. Reject mode removes only a deliberately clear duplicate fixture;
5. top-up makes at most one request and reports an unfilled remainder honestly; and
6. canceling generation does not start another normal or recovery request.
