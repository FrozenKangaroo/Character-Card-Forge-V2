# v0.21.1 Idea Request Batching

## Purpose

Some Text models reliably produce several distinct ideas in one structured response,
while smaller models perform better with one or only a few ideas at a time. Idea
Generator therefore separates the total result count from the number requested in each
logical generation batch.

## Controls

- **Ideas** is the accepted-result target, bounded from 1 to 50.
- **Ideas per generation batch** is bounded from 1 to 12 and defaults to 12.
- A visible plan states the maximum number of sequential generation batches before the
  author presses **Generate Ideas**. Later sizes are recalculated from accepted results.

The existing default of six ideas still makes one batch. Setting six total ideas and
one per batch makes up to six sequential batches. Setting 50 and 12 initially plans sizes
of 12, 12, 12, 12 and 2.

## Aggregation and recovery

Every child generation batch retains a group ID, zero-based position, total batch count,
requested result total and individual request size in private job metadata. Successful
results are combined in request order and then sent once to the visible idea list and
Save Generated Ideas workflow.

If one request fails, results from successful requests remain reviewable and saveable.
The completion status reports the requested and received totals plus the number of
request problems. Cancelling an active child cancels the remaining requests in that
logical run.

## Model guidance and limitations

Each request receives its position in the overall run and is told to treat that number
as a variation partition. This reduces repeated default archetypes, but independent
provider calls do not see one another's responses, so uniqueness across every batch is
not guaranteed.

Smaller batch sizes generally increase model usage. “Generation batch” is deliberately
not presented as an all-inclusive model/API call count: semantic repairs, retries and an
optional final similarity review are separate operations. The plan is intentionally
visible before generation; no work begins until the author starts the run explicitly.
