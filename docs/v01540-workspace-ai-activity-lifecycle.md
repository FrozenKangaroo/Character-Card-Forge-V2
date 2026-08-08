# v0.15.40 — Workspace AI Activity Lifecycle

## Problem

The Workspace status label could remain stuck on an AI activity message such as `Generating ideas…` after the owning job had completed. The AI Jobs panel and queue status were already correct and could show zero running/queued work while the general Workspace status still displayed the old activity.

This was misleading rather than a scheduler failure: the job lifecycle finished correctly, but the general status label was not reconciled against the newer authoritative AI Jobs state.

## Root cause

The Workspace status label predates the concurrent AI scheduler and AI Jobs panel. Individual workflows opportunistically wrote start/queue/completion text into that shared label. After v0.15.31, `ai_job_records_v01531()` became the better source of truth for running, coordinating, queued and waiting work, but the Workspace activity text was still left to each workflow callback.

A workflow that completed without replacing its start text could therefore leave stale activity behind indefinitely.

## Changes

### Authoritative lifecycle reconciliation

v0.15.40 adds a Workspace leaf that reconciles visible AI activity after:

- job start;
- job completion;
- job failure;
- job cancellation;
- worker queue changes;
- scheduler state changes.

Reconciliation is deferred/coalesced so it sees the settled queue/scheduler state rather than an intermediate signal ordering.

### Idle cleanup

When there are no live AI Job records, an activity message that is still owned by the AI lifecycle is replaced with `Ready.`.

The cleanup is ownership-aware. If another Workspace action changed the status after the AI activity text was shown—for example `Saved at 12:34:56`—the idle transition does not erase that newer message.

### Overlapping jobs

If one job finishes while another remains live, Workspace switches to the remaining job instead of clearing too early or retaining the completed job's label.

The activity resolver distinguishes:

- running;
- coordinating;
- waiting for capacity;
- queued;
- waiting for dependencies.

Running work receives the highest priority. Safe Section child records remain visible when they are genuinely running, while equal-state parent/top-level work is preferred over child noise.

### Compatibility

v0.15.40 layers on the v0.15.39 Workspace and retains:

- Character Card metadata + Vision dual ingestion;
- UserPersona exclusion at the AI-facing source boundary;
- v0.15.39-hotfix2 dialog layout fixes;
- v0.15.38 scalable Image Studio picker;
- v0.15.31 AI Jobs visibility/selective cancellation;
- v0.15.37-hotfix1 Safe Section contamination protection;
- v0.15.38-hotfix1 `update.sh` project.godot preservation.

## Regression coverage

`tools/test_v01540_workspace_ai_activity.gd` reproduces the reported stale `Generating ideas…` state and verifies:

- idle AI Jobs state clears owned stale activity;
- running work outranks queued work;
- completing one of several jobs switches to another live job;
- capacity-waiting and queued jobs remain visible as live activity;
- a newer non-AI Workspace message survives an idle transition;
- Safe Section child/parent activity ordering remains deterministic;
- final idle transition releases AI status ownership.

The dedicated CI workflow also reruns AI Jobs, Character Card dual ingestion/dialog layout, Safe Section contamination protection, updater preservation, and the inherited quick cross-feature regression profile.
