# v0.19.1 — Export Profiles and Integration Adapters

Character Card Forge v0.19.1 separates authored character data from the rules used to
send that data to another application. The Import / Export Studio now selects a
versioned export profile, shows the exact resulting JSON and explains every mapped,
preserved, transformed or omitted field before a file is written.

## Built-in profiles

- **Character Card V2 — Full Fidelity** preserves the standard card, lorebook and all
  extension namespaces for lossless portable exchange.
- **Front Porch — Complete Character** uses the same complete Character Card V2
  document, retains optional Character Life and unknown extension data, and is the
  profile used by supported Front Porch install/update workflows.
- **SillyTavern — Clean Card** remains Character Card V2 compatible while omitting only
  Character Card Forge's private round-trip namespace and removing empty optional
  fields. Other unknown extension namespaces remain preserved.

The shipped catalog is `data/export_profiles_v0191.json`, format version 1. Each profile
declares its adapter, output formats and explicit include, omit, rename and transform
rules. The rule engine is generic so later targets can add a profile without copying
the card exporter.

## Shared adapter contract

`CCFIntegrationAdapterServiceV0191` provides one internal contract for:

- document detection and import;
- export construction and validation;
- capability reporting;
- exact JSON/PNG preview and output;
- Front Porch install/update payload preparation; and
- preservation/loss reporting.

Character Card V2, Front Porch and SillyTavern are represented as adapter descriptors.
Front Porch's existing supported authenticated API client still performs the explicit
network request, but its card document and install/update payload now come through the
shared adapter contract. Existing JSON/PNG formats and Front Porch collision review are
unchanged.

## Preservation and privacy

Unknown Character Card extension namespaces are preserved unless a profile explicitly
omits one. An omission is visible in the report and never deletes the value from the CCF
project. Workspace state, revision history, provider/model history, managed assets and
attachments remain private project data and are reported as retained locally rather
than silently leaking into an ordinary card.

The preview performs no network request and does not modify the project. Export is
blocked by the existing incomplete-character safety check. Missing artwork remains a
visible warning because JSON export can be intentionally text-only.

## Extension boundary

v0.19.1 is an internal adapter foundation, not a public executable-plugin SDK. Loading
untrusted third-party code remains deferred until permissions, sandboxing, updates and
compatibility boundaries have a dedicated design.
