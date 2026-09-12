# v0.18.5 Front Porch Connection, Sync and Deployment Reliability

v0.18.5 turns direct Front Porch installation into an explicit, inspectable exchange workflow. Character Card Forge continues to use authenticated supported web endpoints only. It never reads or writes Front Porch's SQLite database.

## Connection diagnostics

The new **Front Porch Sync** tab can run a non-technical diagnostic after the author connects on **Install to Front Porch**. The copyable report includes reachability, authentication state, reported version, character-library access and—when a remote character is available—detail, JSON export and authenticated portrait access.

Passwords, two-factor codes and session cookies are never included. Endpoint capabilities are learned from successful behavior or an explicit capability payload, not guessed from a version number.

## Identity and sync states

After a successful install, update or import, CCF privately stores the Front Porch character ID, the last exchanged authored-card fingerprint and the last observed remote fingerprint. This metadata stays in the local character workspace and is omitted from Character Card exports.

The Library and sync panel can show:

- **Not Installed** — no exchange identity exists;
- **Installed** — local, remote and last-exchanged fingerprints agree;
- **Modified Locally** — only the CCF definition changed;
- **Changed in Front Porch** — only the remote definition changed;
- **Diverged** — both definitions changed since the last exchange.

Library browsing performs no network requests. Remote state changes are observed only during an explicit authenticated comparison.

## Compare-first changes

**Compare Selected** downloads the chosen remote Character Card JSON and displays each differing authored field in a wrapped text report. **Update / Reinstall**, **Import Front Porch Changes** and **Remove** remain unavailable until that preview exists.

Updating requires confirmation and targets the exact selected remote ID. Importing requires confirmation and uses the existing inspected-import path, including a recoverable v0.18.1 revision checkpoint. No background or automatic overwrite exists.

Remote removal is disabled unless the connected server explicitly advertises a supported authenticated delete capability. CCF does not probe deletion destructively and has no database fallback.

## Portrait cache and deployment queue

Diagnostics and future remote previews can fetch portraits with the authenticated session. These disposable files use a dedicated cache, separate from authored card assets, bounded to 48 files and 32 MiB.

The deployment queue stores local project/character IDs, action, remote ID and timestamp—never card payloads or credentials. It processes one install/update at a time and retains bounded reports with success, failure, skipped and warning outcomes. Install collisions are skipped for individual review rather than silently resolved.

## Group cards and source updates

Group-card direct installation remains unavailable unless Front Porch explicitly proves a supported group-card import capability. CCF never sends an `fpa_group` package to the ordinary character import endpoint.

Advisory source-update opt-in is offered only when an imported character records a stable public source ID or HTTP(S) URL. Checks are advisory and cannot install a change automatically.
