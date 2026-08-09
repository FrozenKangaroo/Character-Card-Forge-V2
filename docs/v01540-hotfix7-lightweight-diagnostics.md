# v0.15.40-hotfix7 — Lightweight Diagnostics + Vision Failure Safety

## Runtime symptom

A failed Collaborator Vision request could show the failure dialog normally, but choosing **View Diagnostics…** could make every Character Card Forge window stop responding. No GDScript exception or useful debugger/log output was required because the application could remain alive while Godot's main UI thread was occupied processing diagnostic content.

## Root cause

Collaborator Vision sends the selected image to the configured Vision provider as a base64 `data:image/...;base64,...` URL inside the request payload. Generation Diagnostics preserved request snapshots and Full Trace events, but the previous sanitizer only redacted credentials. The encoded image could therefore be retained several times in one failed diagnostic bundle.

The previous Diagnostics window then deep-copied the full bundle and eagerly JSON-formatted every tab into wrapped `TextEdit` controls before showing the window. A multi-megabyte image could consequently become several multi-megabyte strings that were copied, formatted and laid out synchronously on the UI thread.

## Data-boundary fix

`CCFGenerationServiceV01540Hotfix7` extends the active v0.15.37-hotfix1 generation service used by all concurrent workers.

Before diagnostic evidence is stored it now:

- preserves the existing credential/header redaction rules;
- detects base64 data URIs, including Vision image URLs;
- replaces their binary payload with compact evidence containing MIME type, encoded character count and approximate decoded byte count;
- caps any single diagnostic string at 180,000 characters;
- caps the total text budget of one sanitized diagnostic value at 700,000 characters;
- preserves head/tail evidence and explicit truncation markers instead of silently dropping oversized text.

The provider request itself is unchanged. This affects diagnostic evidence only; it does not resize, recompress or alter the image sent to the Vision provider.

## Viewer hardening

`CCFGenerationDiagnosticsWindowV01540Hotfix7` adds a second defensive boundary for older or otherwise unsanitized bundles.

- The viewer builds a bounded, binary-free view model instead of deep-copying arbitrary provider payloads directly into UI controls.
- Only **Overview** renders when the window opens.
- Request, Raw API Response, Assistant Text, Parsed Output, Validation, Repair and Full Trace are rendered lazily when selected.
- Individual rendered tabs are capped at 220,000 characters.
- Copy/Save operate on the bounded diagnostic bundle, so user-triggered export cannot accidentally serialize an embedded multi-megabyte image from this viewer path.
- Status text explicitly explains that credentials and embedded binary/image data are omitted.

## Failure labelling

`collaborator_vision` failures now use **Vision Analysis Failed** as the native failure-window title and **Vision analysis failed** as the heading. Generic generation jobs retain the existing Character Generation failure wording.

## Regression

`tools/test_v01540_hotfix7_lightweight_diagnostics.gd` uses the real main scene and builds an unsanitized failed Vision bundle containing a 4 MiB fake PNG data URI in both Request and Full Trace.

The regression proves that:

1. every concurrent AI worker is the hotfix7 diagnostics-safe service;
2. stored diagnostics remove the data URI and remain bounded;
3. pathological non-image strings are bounded as well;
4. the normal diagnostics-available → Vision failure dialog → View Diagnostics path returns control instead of blocking indefinitely;
5. the failure dialog is labelled as a Vision failure;
6. heavy diagnostic tabs are lazy before selection;
7. Request and Full Trace render compact omission evidence on demand;
8. the Diagnostics window remains interactive and closable afterward.

The strict Python wrapper has a finite timeout specifically so a future main-thread stall becomes a regression failure rather than an apparently hung CI job.

## Compatibility

Hotfix7 retains:

- v0.15.40-hotfix6 shared-scroll Reference Context and actual-window composer protection;
- v0.15.40-hotfix5 composer lifecycle/warning cleanup;
- v0.15.40-hotfix4/hotfix3 sidebar guards;
- Character Card PNG metadata + Vision dual ingestion;
- structured-source/UserPersona exclusion and provenance;
- Safe Section identity/contamination guards;
- concurrent AI scheduler/AI Jobs behavior;
- `update.sh` project.godot preservation;
- Forward+ desktop default with Compatibility/OpenGL fallback.
