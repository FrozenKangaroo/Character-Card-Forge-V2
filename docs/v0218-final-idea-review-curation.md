# v0.21.8 Final Idea Review and Generated-Idea Curation

v0.21.8 turns the optional final AI comparison into an explicitly intermediate,
advisory review stage and lets the completed AI Ideas result remain a user-curated
working batch.

## Advisory Final Idea Review

The two opt-in checks are **request adherence** and **similarity / duplicates**. When
either is enabled, CCF sends one combined review request using the frozen prompt mode,
primary prompt or Additional Direction, active Idea Source and Series context captured
when generation began.

The AI may flag `partial_mismatch`, `clear_mismatch`, `duplicate`, `near_duplicate` or
`related_distinct` findings. These findings never remove or uncheck an Idea. Every valid
Idea begins checked in a scrollable native **Final Idea Review** window, and only the
user's checked Keep selection determines retention.

CCF does not render the new batch as complete while this review is waiting. Closing the
window leaves generation paused and exposes **Open Final Idea Review…** so the decision
can be resumed safely.

## Review-driven one-shot recovery

**One final top-up request if short** remains opt-in and remains limited to one automatic
request. The shortfall is calculated only after **Apply Review & Continue**. Unchecked
Ideas are retained in temporary session memory as `rejected_by_user_review`, including a
compact fingerprint, so replacements are instructed not to recreate them cosmetically.

Recovery output still passes normal validation and local diversity checks. Recovery is
not reviewed a second time and cannot create a review/recovery loop. Cancellation never
launches automatic recovery.

## Temporary working batch

After finalization, each generated result has **Use This Idea** and **Delete This Idea**.
Delete affects only the temporary generated batch. It does not touch the Idea Library,
project data, separately saved Ideas or the source card. Save Generated Ideas and
Develop Generated Idea remain synchronized with the surviving visible results.

Deleted results remain compact anti-repeat memory as
`rejected_by_user_after_generation`. **Generate More Ideas…** can then be invoked
repeatedly by the user. Each invocation:

- appends accepted results rather than replacing surviving Ideas;
- reuses the original frozen creative context and detail settings;
- includes retained, review-rejected and later-deleted concepts in anti-repeat guidance;
- respects the existing total and per-request limits; and
- creates a fresh active provider-job session instead of keeping stale completed-job
  state alive.

The lightweight curation state is project-scoped and is cleared for an unrelated fresh
Generate action or project change.

## Limits

AI adherence and novelty findings are model-assisted advice, not guarantees. Local
validation and conservative cross-batch repeat prevention remain authoritative safety
layers. A model may miss a mismatch or similarity, and the user may deliberately keep
any flagged Idea.
