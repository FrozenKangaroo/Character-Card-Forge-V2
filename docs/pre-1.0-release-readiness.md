# Character Card Forge Pre-1.0 Release Readiness

This checklist is the shared release contract for the v0.20.5 public bake period and the eventual 1.0 release candidate. It records evidence that must exist; it is not permission to bypass a failed check or silently narrow supported behaviour.

## Status convention

- `[x]` is proven by the current source, automated checks or an explicitly recorded real-world result.
- `[ ]` still needs evidence, a documented limitation or a deliberate scope decision.
- A third-party combination does not have to be supported merely because it exists. Supported configurations must be named and tested deliberately.

## Product and workflow

- [x] v0.20.1 discoverability and power-user workflow pass is complete.
- [x] v0.20.2 provides a previewed privacy-safe support report with explicit copy/export and no automatic submission.
- [x] v0.20.3 provides a searchable offline Help Center with versioned task guides and direct routes to existing tools.
- [x] v0.20.4 provides deterministic source/package preflight and reviewed version-matched release notes.
- [x] v0.20.5 provides a complete structured offline manual and deterministic reviewed Wiki export source.
- [x] New Project creation has an explained selection and explicit confirmation action.
- [ ] Complete a human task-path pass at ordinary 1080p and an ultrawide size:
  - create a first character;
  - import an existing character;
  - improve an existing card with Card Inspector and AI Review;
  - create a Compact/Lite derivative;
  - create a group and add an existing Library character;
  - create/select a scenario and opening;
  - export a standard PNG card;
  - install/update through Front Porch;
  - open Test Chat;
  - generate artwork and an expression set;
  - restore an older revision;
  - find a character in a large Library.
- [ ] No open data-loss, silent-overwrite or unrecoverable destructive-action defects.
- [ ] Major destructive actions retain preview, confirmation and recovery where applicable.
- [ ] Import/export round trips preserve every supported field and identify intentional loss.

## Library and storage

- [ ] Validate responsive browsing, filtering and thumbnail loading with a large real Library.
- [ ] Prove thumbnail cleanup cannot remove source artwork.
- [ ] Test a portable/shared Library on a real shared folder or NAS.
- [ ] Prove an unavailable portable Library never silently falls back to another location.
- [ ] Verify external-change conflicts and short-lived write locks with the documented single-writer model.
- [ ] Document backup, recovery and the shared-folder single-writer expectation.

## AI and providers

- [x] Provider/model limits and task routing are represented through data-driven profiles.
- [x] Accepted generated content records the actual producer profile/model provenance.
- [x] Fallback is bounded, opt-in and visible.
- [ ] Verify failed generation and repair paths never destroy previously accepted content.
- [ ] Test Primary, Fast, Deep Review and Fallback routing with representative real providers.
- [ ] Test supported local image-provider paths and record known limitations.
- [ ] Recheck model output-budget clamping and conditional agency validation with representative providers.

## Front Porch

- [x] Integration uses supported APIs and portable formats; direct database access is not supported.
- [x] Capability detection disables unsupported operations instead of guessing from version text.
- [x] Test Chat does not change Front Porch global provider/model/runtime settings.
- [ ] Validate install, update, collision handling and reconciliation against supported Front Porch versions.
- [ ] Validate password-only and two-factor authentication flows.
- [ ] Validate Test Chat fresh/resume/stop/reconnect/completion/recovery/export lifecycles.
- [ ] Validate expression gallery installation and expression ZIP round trips.
- [ ] Validate worlds, group cards and chat interchange with representative real data.
- [ ] Record supported Front Porch configurations and known limitations in user documentation.

## Documentation and support

- [ ] Reduce README to a user-facing product front door with installation and first-character guidance.
- [ ] Publish the task-oriented GitHub Wiki described in `roadmap.md`.
- [x] Add searchable offline help for first launch, core workflows, recovery and troubleshooting.
- [ ] Add current screenshots after navigation and labels are frozen.
- [ ] Document troubleshooting, diagnostics, privacy, backup and recovery.
- [x] Add structured Bug Report, Feature Request and Front Porch Integration issue forms.
- [x] Add an in-app Support & Diagnostics entry and document its hard privacy exclusions.

## Repository and release

- [x] Use a small stable GitHub Actions surface driven by the versioned regression manifest.
- [x] Preserve all historical regression test scripts, including 28 tests migrated from workflow-only enforcement into the 153-test release profile.
- [ ] Let the consolidated validation checks prove stable on `main`.
- [ ] Protect `main`: require pull requests and the consolidated validation checks, block force pushes and block deletion.
- [ ] Keep an explicit emergency maintainer bypass only if operationally necessary.
- [x] Keep version metadata synchronized through `tools/set_version.py` and reject mismatched release tags.
- [ ] Smoke-test update notification from an older public build to the candidate release.
- [x] Require the tagged workflow to generate and checksum the exact Windows, Linux and unsigned macOS package set before publication.
- [x] Ensure reviewed release notes explicitly call out migrations, breaking changes and known limitations.

## Technical consolidation

- [ ] Inventory the active implementation chain for each runtime subsystem.
- [ ] Consolidate one subsystem per focused PR into a semantically named current implementation.
- [ ] Preserve public signals, service contracts, project/card schemas and external APIs.
- [ ] Prefer service composition for independent responsibilities over new version-layer inheritance.
- [ ] Retire compatibility wrappers only after the complete inherited regression profile proves equivalence.
- [ ] Consolidate implementation behaviour without deleting milestone documents or regression history.

## Release decision

Before a 1.0 release candidate, every unchecked item above must be either completed or linked to an explicit, user-visible limitation/scope decision. A green automated suite alone does not replace the real-world validation items.
