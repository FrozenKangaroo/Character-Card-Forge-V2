# v0.19.2 — Test Chat and Explicit Chat Exchange

Character Card Forge v0.19.2 adds a lightweight Test Chat that delegates runtime
behavior to Front Porch. It does not embed a second simulation engine and does not read
or write Front Porch's database.

## Verified Front Porch boundary

The versioned contract in `data/front_porch_chat_contract_v0192.json` records the
supported Front Porch 1.3.x web routes used by CCF: chat state, character and session
selection, fresh-chat creation, send, stop, personas, WebSocket events, `.fpchat`
export, JSONL export and chat import. CCF verifies the authenticated endpoints before
enabling chat actions.

Front Porch currently exposes its active runtime but not a safe per-chat model or
preset switch. CCF therefore shows the observed runtime and lets a Local Test Profile
record what the author intends to compare. It never silently changes Front Porch's
global provider, model or preset.

## Local Test Profiles

Profiles contain only:

- a local profile name;
- a Front Porch persona ID;
- an expected runtime label; and
- private test notes.

They live under CCF's local settings directory, not in card or project data. Passwords,
two-factor codes, session cookies and API keys are not accepted by the profile model and
are never persisted.

## Explicit test lifecycle

An authored character must already have a Front Porch remote ID from the supported
Install/Sync workflow. Opening Test Chat is inert. **Open Latest / Resume**, **Start
Fresh**, **Select Session**, **Send**, **Stop**, imports, exports and deletion each need a
separate author action.

WebSocket token events provide live presentation. A completed or externally changed
turn is reloaded from `/api/chat/state` so Front Porch remains the canonical history.
Group chat is not claimed in v0.19.2.

## Portable chat exchange

The exchange inspector accepts:

- `.fpchat`, a ZIP package containing `chat.json` with `format: fpai_chat` version 1;
- compatible raw Front Porch chat JSON; and
- SillyTavern JSON/JSONL message histories.

The inspector validates format and limits, rejects unsafe archive paths and shows a
bounded normalized preview. Front Porch's private `fpai` suitcase is not reinterpreted
or rewritten. Managed copies retain the original bytes plus source filename, timestamp,
project/character association and SHA-256 digest outside card data.

Every current-chat export also keeps a managed recovery copy. Deleting a session first
downloads and validates a `.fpchat` backup; if backup creation fails, deletion is not
attempted. Import preserves the selected source before invoking Front Porch's supported
API and surfaces character mismatch choices instead of guessing.
