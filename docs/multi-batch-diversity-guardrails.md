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
per generation batch** limit. A 21-idea run using 12 per batch therefore normally asks
for 12 and 9. If only 11 ideas from the first response survive, the next request asks for
10 instead.

The number of normal generation batches remains bounded by the original plan. CCF does
not keep retrying until the target is filled.

## Temporary diversity ledger

During one Generate action, CCF keeps an in-memory ledger containing:

- an internal session ID, title and compact scenario fingerprint for each result;
- whether it was accepted or rejected; and
- a rejection reason when available.

The fingerprint is derived at generation time from the idea's premise, hook and other
available structural text. Character names are excluded from the inexpensive structural
comparison. When generation finishes, the active provider-job session is discarded and
a lightweight project-scoped curation snapshot retains the visible, rejected and later
deleted concepts. That snapshot does not change the Idea Library, `.ccfideas.json` Idea
Packs or `.ccfideasource.json` Idea Sources.

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

## Optional final AI review

**Check request adherence** and **Check similarity / duplicates** both default to off
because enabling either uses one extra model request. When one or both are enabled, CCF
sends one combined review grounded in the immutable prompt, Idea Source and Series
context captured at the start of generation.

The model may flag partial or clear request mismatches, duplicates, near-duplicates and
related-but-distinct concepts. These findings are advisory: they never remove or uncheck
an Idea. Every valid result starts checked in the scrollable **Final Idea Review**, and
only the author's choices determine which Ideas remain.

The review opens as an independent native desktop window. It can be moved outside CCF,
resized and placed on another monitor without becoming globally always-on-top. Closing
it pauses the pending generation and exposes **Open Final Idea Review…**; it does not
silently accept, reject or discard the pending results.

## Optional one-shot top-up

**One final top-up request if short** is also off by default. After normal requests,
validation and the author applies the Final Idea Review, it can make exactly one
additional request for the missing count, bounded by the configured provider-request
limit.

The recovery request receives the accepted and rejected ledger, including Ideas the
author unchecked during review, plus the original source and Additional Direction and
explicit replacement/novelty guidance. Recovery results still undergo validation, title
warnings and structural duplicate checks. Recovery is not reviewed again, so it cannot
create a review/recovery loop. Cancelling generation never starts automatic recovery.

There is no retry loop. If a request for three replacements produces only two usable
ideas, the session ends at 29/30 and reports that result.

## Progress and usage

The concise status reports accepted ideas against the target, generation batches,
rejected candidates and similarity warnings. A generation batch is a top-level Idea
Generator request, including the optional one-shot top-up; it is not an estimate of all
model/API calls.

The status tooltip provides diagnostic processing counts with distinct meanings:

- **Initial generated candidates** are candidates returned by top-level generation
  batches before semantic repair.
- **Semantic repair passes** count full-array semantic repair operations.
- **Repaired candidates processed** count candidate objects returned by those passes.
- **Total validation-pass candidates** counts initial plus repaired candidate objects
  processed by validation. It does not mean that many distinct ideas were generated.

For example, four 12-candidate generation batches with three full 12-candidate repairs
report 48 initial candidates, three repair passes, 36 repaired candidates and 84 total
validation-pass candidates. The main status still correctly says four generation
batches. CCF does not currently claim an all-inclusive model-call total because retries,
repairs and optional review calls are not centrally accounted as one reliable metric.

Repeat prevention itself adds prompt context but no extra request. **Final AI Idea
Review** can add one model call. **One final top-up request if short** can add one more.
Enabling both may therefore add up to two provider calls beyond the bounded normal batch
plan.

## Curating and extending a completed batch

Completed results expose **Use This Idea** and **Delete This Idea**. Delete changes only
the temporary generated batch; it never deletes a saved Idea or source card. Save
Generated Ideas and Develop Generated Idea remain synchronized with the surviving
results. Deleted concepts remain compact anti-repeat memory for the session.

**Generate More Ideas…** appends to the surviving batch and can be used repeatedly. Each
manual extension reuses the original frozen creative context, includes retained,
review-rejected and deleted concepts in its anti-repeat guidance, respects the normal
per-request and total limits, and creates a fresh provider-job session. A fresh Generate
action or project change clears the lightweight curation snapshot.

## Manual verification

Before release, perform one real provider run with at least two batches and confirm:

1. the second request status uses the accepted count from the first response;
2. Additional Direction and an active Idea Source still influence later batches;
3. Flag mode opens a readable report without removing ideas;
4. Reject mode removes only a deliberately clear duplicate fixture;
5. top-up makes at most one request and reports an unfilled remainder honestly; and
6. canceling generation does not start another normal or recovery request.
