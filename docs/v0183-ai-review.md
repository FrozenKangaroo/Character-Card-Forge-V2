# v0.18.3 — AI Review, Rating and Selective Improvement

v0.18.3 adds an optional AI interpretation layer beside the deterministic Card
Inspector. It does not replace deterministic validation, decide whether a card is
good, or change authored fields automatically.

## Review boundary

- AI Review runs only after the author presses **Run AI Review**.
- The request includes the deterministic health/token reports, relevant character
  and project context, the permitted editable paths and visible rubric v1.
- The locally calculated advisory score covers consistency, clarity, depth,
  scenario quality, greeting quality, lore quality, prompt efficiency and roleplay
  readiness. The UI explicitly labels it as non-objective.
- Each stored review records its content hash, model, profile, rubric version,
  timestamp, findings, score and complete proposed change set.
- A review becomes **Stale** when relevant character, shared-context or lore content
  changes. CCF will not apply a stale review and never reruns one on library open.

## Explicit decisions and recovery

Every proposal is shown with its current value and complete replacement value.
Reject is the default. The author may approve, reject, or edit a proposed value
before applying it. **Approve All Visible Changes** is enabled only after the full
proposal set is rendered.

Rejected proposals and intentionally dismissed findings remain in private review
history so later reviews can distinguish an accepted design choice from an
unresolved suggestion. Applying an accepted batch creates recovery checkpoints
before and after the change. A later re-review remains a separate explicit action.

AI Review history is private CCF workflow data. It is excluded from ordinary
Character Card export and from revision snapshots, preventing both leakage and
recursive history growth.
