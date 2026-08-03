# v0.15.26 Concurrent AI Scheduler

Character Card Forge v0.15.26 replaces the effective one-worker application queue with a dependency-aware scheduler shared by Text, Vision, Safe Section, and Image workflows.

## Settings

Character AI settings now provide:

- Maximum concurrent counted jobs
- Maximum concurrent Text jobs
- Maximum concurrent Vision jobs
- Maximum concurrent Image jobs
- Maximum concurrent Safe Sections per character
- Generate eligible Safe Sections in parallel
- Vision jobs count toward the overall maximum
- Image jobs count toward the overall maximum

The defaults remain equivalent to the previous single-job behaviour. Increasing limits is explicit.

Vision and Image jobs can be excluded from the overall maximum when they use independent backends. Their role-specific limits still apply. For example, four cloud Text requests, one local Vision request, and one local Stable Diffusion request can run together when Vision and Image are configured as independent.

Provider/API-specific and shared-GPU pools are not yet modelled separately. Those remain a future refinement.

## Independent application workers

The live Workspace owns separate generation-service workers for:

- Generate Character and direct Workspace generation
- Character Collaborator
- Idea Generator
- Authoring tools such as Builder, Controlled Build, Group Scene, Relationships, and Card Workflows
- Vision / Attachments

Each worker retains the existing single-job internal state machine, repair pipeline, cancellation, diagnostics, and provider compatibility. The shared scheduler decides when each worker may send its next HTTP request. This avoids unsafe cross-job reuse of `_active_job`, request payload, repair state, or diagnostics state.

Image Studio uses its own scheduler-aware image service while sharing the same capacity manager.

## Parallel Safe Section Build

Interview/Q&A remains a required barrier. No Safe Section worker starts until the Interview has completed and the established planning context is available.

After that barrier, eligible sections are divided into dependency waves. Siblings in one wave receive the same frozen context snapshot. They do not consume one another's partially completed output, so network completion order cannot change their prompts.

Sections may declare `depends_on` IDs in their section, Output Group, or field data. The built-in dependency defaults also ensure:

- First Message waits for Scenario when both are present.
- Alternative Greetings / Example Dialogues wait for Scenario and First Message when those fields are present.

A cyclic or invalid custom dependency cannot deadlock the build; the first remaining template section advances alone in deterministic order.

## Deterministic combination

Parallel workers never write directly into the live card. Each worker returns an isolated section result to the parent build coordinator.

Output Groups and standalone fields are stored by stable IDs. When all required workers have completed, Character Card Forge assembles the final fields using template and Generation Group order—not response completion order. Multiple Output Groups targeting the same Character Card field therefore remain correctly headed and ordered even if the last template group finishes first.

The assembled candidate still passes through the established template contract, semantic repair, concept-fidelity correction, fail-closed validation, and Generation Preview.

## Queue and cancellation

The Workspace status displays aggregate running and queued Text/Vision work. Excess jobs remain queued and are promoted fairly as role/global capacity becomes available. Safe Section workers also obey the per-character limit so one large build does not consume every available slot.

The Workspace **Cancel AI Queue** action cancels running and queued Text/Vision jobs. Image Studio retains its own Cancel action.

## Character Collaborator compatibility fix

The v0.15.22 Workspace introduced an exact script comparison when opening Character Collaborator. Newer compatible services such as v0.15.25 were consequently rejected with:

> Character Collaborator could not activate the v0.15.22 generation service.

v0.15.26 replaces that exact-version requirement with capability checks and binds Character Collaborator to its own current v0.15.26 worker. Future service subclasses can remain compatible without pretending to be the historical v0.15.22 script.
