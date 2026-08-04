# v0.15.33-hotfix2 — AI Ideas → Idea Notebook Capture Reliability

## Reported symptom

A completed AI Ideas request could display its generated cards normally while the Idea Notebook header still reported:

> No completed AI Ideas batch captured yet.

When this happened, **Save Generated Ideas…** and **Develop Generated Idea…** remained disabled even though the generated results were visible and usable through the older **Use This Idea** action.

This was not intentional. Generated ideas are disposable until explicitly saved, but a completed batch must become available to the selective-save and Collaborator-handoff workflows.

## Root cause

The current Idea generation contract still uses the job type `ideas`. The regression was not caused by a new `idea_generation` job type.

The real weakness was the completion bridge introduced with Idea Notebook. It connected only to Workspace's dedicated `_idea_service_v01526` reference. The visible AI Ideas controls, however, are still embedded from the retained legacy Idea Generator controller. That controller has a generation-service reference of its own and is explicitly rebound as Workspace services evolve.

This means the UI that rendered the completed ideas and the Notebook listener could temporarily observe different compatible live service instances. The old result cards could update successfully while the Notebook never received the same completion signal.

The v0.15.32 regression did not catch this because it called `_on_idea_job_completed_v01532()` directly with a synthetic `ideas` result instead of emitting a completion through the live service topology.

## Hotfix

v0.15.33-hotfix2 keeps the normal dedicated Idea worker but makes the Notebook bridge capability/topology based:

- connect the Idea completion callback to the dedicated Idea worker;
- also connect it to every live `CCFGenerationService` descendant owned by the Workspace/embedded workflow;
- refresh these connections after concurrent-client rebinding;
- refresh them immediately before and after opening the unified Idea Generator, where legacy-controller service rebinding can occur;
- continue filtering completions so unrelated Character, Collaborator, Vision, and authoring jobs do not enter Idea Notebook;
- retain `ideas` as the current canonical job type while accepting `idea_generation` as a forward-compatible alias;
- accept either a direct result array or an `{ "ideas": [...] }` result envelope;
- never auto-save captured results.

Once a valid completed batch is captured, the existing v0.15.32/v0.15.33 UI contract applies unchanged:

- **Save Generated Ideas…** becomes enabled;
- **Develop Generated Idea…** becomes enabled;
- the header reports the number of unsaved generated ideas available;
- the user still chooses which ideas, if any, are persisted.

## Regression coverage

The focused regression now exercises the failure boundary rather than calling the Notebook callback directly. It:

1. instantiates the real main scene;
2. confirms the live v0.15.33-hotfix2 Workspace and existing hotfix1 Idea Generator are installed;
3. creates a second compatible live generation service under the embedded workflow, modelling the legacy-controller/service divergence that can occur at runtime;
4. emits a real `job_completed` signal with job type `ideas` from that alternate service;
5. verifies the batch reaches `_last_generated_ideas_v01532`;
6. verifies **Save Generated Ideas…** and **Develop Generated Idea…** both enable;
7. verifies the batch-status label changes from the empty-state message;
8. verifies capture alone does not create an Idea Notebook entry;
9. verifies the normal dedicated Idea worker path still captures correctly.

The broad regression default advances to `regression_suites_v01533_hotfix2.json`.

## Version scope

This is deliberately **v0.15.33-hotfix2**. It repairs the v0.15.32/v0.15.33 Idea workflow without consuming **v0.15.34**, which remains reserved for Existing Character → Character Collaborator.
