# v0.21.1 Idea Request Batching

## Purpose

Some Text models reliably produce several distinct ideas in one structured response,
while smaller models perform better with one or only a few ideas at a time. Idea
Generator therefore separates the total result count from the number requested in each
provider call.

## Controls

- **Ideas** is the total requested result count, bounded from 1 to 50.
- **Ideas per provider request** is bounded from 1 to 12 and defaults to 12.
- A visible plan states the exact number of sequential provider requests before the
  author presses **Generate Ideas**.

The existing default of six ideas still makes one request. Setting six total ideas and
one per request makes six sequential requests. Setting 50 and 12 produces request sizes
of 12, 12, 12, 12 and 2.

## Aggregation and recovery

Every child request retains a group ID, zero-based position, total request count,
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

Smaller request sizes increase the number of provider calls and can increase billed
usage. The plan is intentionally visible before generation; no extra request is made
until the author starts the run explicitly.
