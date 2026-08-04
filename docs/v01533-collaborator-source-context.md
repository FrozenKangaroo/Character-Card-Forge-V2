# v0.15.33 — Generic Collaborator Source Context

## Purpose

v0.15.33 gives Character Collaborator a stable source/provenance boundary instead of making other tools paste opaque text into its composer or reach into private session state.

A source-aware conversation owns one versioned, read-only `source_context` snapshot. The snapshot persists with the independent Collaborator session and is injected into every model-facing request separately from removable attachments and lossy conversation summaries.

## Source format

The format is `character_card_forge_collaborator_source`, version 1.

Each source records:

- a stable source-context ID;
- source type;
- user-facing label;
- structured source snapshot;
- provenance metadata;
- capture time;
- author intent.

v0.15.33 defines three source types:

1. `generated_idea` — a result from the latest AI Ideas batch that has not necessarily been saved;
2. `saved_idea` — a persisted Idea Notebook entry with Idea/notebook provenance;
3. `character` — a structured existing-character snapshot established now for the v0.15.34 Workspace workflow.

Only one primary source is attached to a conversation in v0.15.33. Multi-source conversations remain planned for v0.15.37.

## Source semantics

The model-facing source block explicitly requires the Collaborator to keep three concepts distinct:

- **Established source facts** — facts actually present in the source snapshot;
- **Author-requested changes** — branches, retcons, age/time advances, event continuations, relationship changes or other modifications explicitly requested by the user;
- **New/proposed details** — material invented to fill gaps or deepen the design.

Established facts remain authoritative by default. The Collaborator may deepen gaps, but should not casually replace source canon. The stored snapshot itself is never rewritten by normal conversation.

This makes the same architecture suitable for later workflows such as future/past versions, side-character promotion, relatives/descendants, connected characters and new characters in an established setting.

## Idea Generator handoff

The AI Ideas tab adds **Develop Generated Idea…**.

The user chooses one result from the latest completed batch. CCF creates a structured source snapshot and opens a new Collaborator conversation. This does **not** save the result to Idea Notebook and does not spend an additional AI request merely by opening Collaborator.

## Idea Notebook handoff

A selected saved idea adds **Develop in Collaborator**.

The source snapshot preserves the saved idea's structured fields plus stable Idea ID and Notebook ID provenance. The Notebook entry remains unchanged while the conversation develops from it.

## Collaborator UI and persistence

Source-aware conversations show a dedicated Source panel above ordinary Reference Context. The panel identifies the source type and label and provides a concise preview.

The source is not represented as an ordinary removable attachment. It is stored as first-class session data and survives independent Collaborator autosave/reload. Conversation summaries and attachment removal therefore cannot erase the source that the conversation was created from.

Source text participates in normal Collaborator context budgeting and is prepended to the existing model-facing context blocks.

## Existing-character boundary

v0.15.33 deliberately establishes the `character` source schema without yet adding the Workspace **Develop in Collaborator** action. That user-facing workflow is v0.15.34 so its intent selection and relationship/derivation semantics can be designed on top of this stable source boundary.

Likewise, v0.15.33 does not change final character materialisation. The planned v0.15.35 behavior remains:

- empty Workspace character → use the empty slot;
- occupied Workspace → default to a new character in the same group;
- replacing the current character remains explicit rather than automatic.

## Provider-response hardening

The current concurrent workers use `CCFGenerationServiceV01533`.

Before the inherited response handlers run, the v0.15.33 leaf silently validates the provider envelope with `JSON.parse()`. It handles:

- empty response bodies;
- interrupted/truncated JSON;
- HTML or other non-JSON proxy/gateway bodies;
- network failures.

This prevents older inherited diagnostic layers from independently calling `JSON.parse_string()` on the same malformed body and producing repeated Godot parser errors.

The existing bounded retry policy remains authoritative. Network failures, typical transient HTTP statuses, 5xx failures and malformed successful responses may retry within the configured retry count. Diagnostics still retain network result, HTTP status and raw response body.

This hardening addresses the malformed-response behavior observed during a network-saturated API request. It does **not** claim to fix the separate native Linux/X11 GLX crash observed as `BadAlloc` → `glXMakeCurrent failed` → signal 11.

## Compatibility

v0.15.33 preserves:

- the v0.15.32 Idea Notebook storage format and selective-save semantics;
- the v0.15.32-hotfix1 compact AI Ideas header layout;
- independent Collaborator session storage;
- existing Collaborator attachments and Vision → Text routing;
- Blueprint and Detailed Workspace Draft handoffs;
- v0.15.31 AI Jobs visibility/cancellation;
- v0.15.26 concurrency scheduling and Safe Section execution.

No existing conversation requires a source. Historical sessions simply continue with no `source_context` field.
