# v0.17.3 — Front Porch Direct Install

v0.17.3 adds a user-initiated **Install to Front Porch** workflow to the Import / Export Studio. When an active portrait is available, it sends a real Character Card V2 PNG containing both the artwork and embedded card metadata through Front Porch's supported web character-import API. A character without a portrait is sent as Character Card V2 JSON. Character Card Forge does not inspect, open, migrate or modify Front Porch's SQLite database.

## Front Porch setup

1. In Front Porch, open **Settings → Advanced → Web Server**.
2. Enable the web server. Front Porch 1.3.x defaults to `http://127.0.0.1:8085`.
3. Open Front Porch's browser page and create its web login if one is not already configured.
4. In Character Card Forge, open **Import / Export → Install to Front Porch**.
5. Enter the Front Porch address and web-login credentials, then select **Connect & Test**.

The address and optional username can be remembered. The password, two-factor code and `fpa_session` cookie are never written to disk by Character Card Forge. They live only in the running Import / Export window's client service.

Plain HTTP is accepted only for loopback addresses (`127.0.0.1`, `localhost` or `::1`). A Front Porch server on another device must use HTTPS so Character Card Forge never sends the web password over unencrypted LAN traffic.

## Capability detection

Connection uses Front Porch's public `GET /api/health` and `GET /api/auth/state` endpoints, then verifies the authenticated character API with `GET /api/characters`. CCF reports the returned Front Porch version, setup state, login state and whether the character API actually answered.

CCF does not infer compatibility from a running process, a folder on disk or a copied file. The Install button becomes available only after the supported authenticated endpoint succeeds.

## Character installation

CCF first exports the active character in memory as a validated Character Card V2 document, including optional `data.extensions.front_porch`, stable identity and `data.tts_voice`. If the character has an active portrait, CCF converts it to PNG when necessary, embeds the V2 document in its `chara` metadata chunk and uploads the binary PNG bytes to:

`POST /api/characters/import?filename=<card.png>&collision=ask`

This gives Front Porch both the authored definition and the portrait it needs for the library card. If no portrait is assigned, CCF deliberately falls back to definition-only JSON using `filename=<card.json>` and says so in the result report.

Front Porch remains responsible for parsing the card, matching stable identity and committing its own library changes.

When Front Porch returns success, CCF reports the exact accepted name and Front Porch character ID. It does not report success merely because a local file was written.

## Collision review

Stable-identity matching is owned by Front Porch. If there is only a name collision, Front Porch returns HTTP 409 with its candidate character IDs and CCF presents three explicit choices:

- **Create Copy** retries with `collision=keepBoth`.
- **Update Selected** retries with `collision=replace&replaceId=<id>`.
- **Cancel** clears the pending payload and makes no Front Porch change.

Front Porch documents replacement as retaining that character's chats. CCF nevertheless describes the operation narrowly: it replaces the selected library card's authored definition and never claims to modify, migrate or synchronise existing conversation state.

## Portable fallback

**Export Portable JSON Instead…** remains available regardless of connection state. It uses the existing Character Card V2 JSON export, which can be imported through Front Porch's own UI when:

- Front Porch is not running;
- its web server or account is not configured;
- the configured endpoint is incompatible;
- authentication is declined or expires; or
- Front Porch rejects the character.

The fallback is an exported interchange file, not proof that Front Porch installed anything.

## Safety boundaries

- Every install and collision resolution is initiated by the user.
- No background install or synchronisation runs when a project is opened or saved.
- CCF never reads or writes Front Porch database files.
- CCF does not create the Front Porch web account or store its password.
- CCF preserves the v0.17.2 optional-field and unknown-extension round-trip rules in both JSON and embedded PNG metadata.
- Existing Front Porch chats, Needs progression and evolving conversation state remain under Front Porch ownership.

## Audited Front Porch contract

The v0.17.3 adapter targets the supported contract present in Front Porch AI 1.3.x source: default web port 8085, cookie-session login, public health/auth-state probes, raw JSON/PNG character-card upload, stable-ID matching, and `ask`, `keepBoth` and `replace` collision policies. Later Front Porch versions are detected by behavior rather than accepted solely by version-string comparison.
