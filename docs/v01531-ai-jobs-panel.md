# v0.15.31 — AI Jobs Queue Panel

v0.15.31 turns the v0.15.26 concurrency scheduler from a mostly invisible capacity manager into an inspectable Workspace workflow.

## AI Jobs control

The Workspace queue row now includes **AI Jobs (N)**. The count represents current non-completed job/section records. The control expands a scrollable panel without removing the existing **Cancel AI Queue** emergency action.

The panel can show:

- running jobs;
- jobs waiting for a scheduler capacity slot;
- jobs queued inside an individual worker;
- parallel Safe Sections currently eligible in a wave;
- Safe Sections waiting for declared/built-in dependencies;
- Safe Sections completed while their parent Character build is still active;
- Image Prompt and Image Generation work from Image Studio.

Where available, rows display the owning workflow, Text/Vision/Image role, current stage, provider profile, model, queue position, and dependency explanation.

## Safe Section hierarchy

A parallel Safe Section Character build remains the parent operation. Section rows are child status records rather than independently canonical jobs.

For example, the built-in dependency rules make First Message visibly report that it is waiting for Scenario when Scenario has not completed. Later dialogue/greeting sections can likewise show dependency waits instead of looking stuck.

Cancelling a Safe Section child row cancels the parent Character build. This is deliberate: cancelling one child while leaving its coordinator and sibling dependency graph alive could produce a structurally incomplete build.

## Per-job cancellation

Top-level Text/Vision jobs are cancelled through the worker that owns them. Queued cancellation removes only that job and does not clear another worker's queue.

Image Studio exposes its AI prompt writer and image-generation request to the same panel. Their cancellation is routed back to Image Studio so its own state/buttons/signals remain authoritative.

The existing **Cancel AI Queue** action remains available for the explicit "stop all current Workspace Text/Vision work" case.

## Scope and deferred controls

v0.15.31 does not yet add:

- pause/resume;
- drag-to-reorder;
- move-to-front/priority controls;
- provider/API execution pools;
- shared local-GPU resource pools;
- persistence of queued work across application restart.

Those remain later scheduler-control work. v0.15.31 focuses on trustworthy visibility and selective cancellation first.

## Regression coverage

The real-main-scene regression verifies:

- the active Workspace uses the v0.15.31 inspectable generation workers;
- the Image Studio controller is wired into the shared job view;
- the AI Jobs panel is collapsible and present beside existing queue controls;
- cancelling a queued Collaborator job does not clear an unrelated Idea Generator job;
- Scenario and First Message expose the intended Safe Section dependency state;
- completed sections remain visible until the parent Safe build finishes;
- pending Image generation appears in AI Jobs and can be cancelled from there.
