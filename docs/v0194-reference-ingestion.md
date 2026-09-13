# v0.19.4 — PDF and Remote Reference Ingestion

## Local PDF preprocessing

PDF imports retain the original document in the existing managed attachment folder.
When a readable text layer exists, Character Card Forge extracts it locally and stores
only the derived text and inspection metadata in the attachment record. The metadata
includes page count and per-page text presence, character count, estimated token count,
extraction status and whether the bounded extraction was truncated.

The extracted text is visible in **Vision and Attachments**. New PDFs default to being
excluded from generation context, so importing a document and sending its contents to a
model remain separate author decisions. PDFs with no readable text layer report that
state and remain portable; OCR is not started automatically.

## Review-first HTTPS references

**Add from URL…** accepts HTTPS only and performs no work until **Fetch Preview** is
pressed. Each request is limited to 16 MB, 20 seconds and four manually checked HTTPS
redirects. Supported results are PDF, readable UTF-8 text/Markdown/HTML/JSON/YAML/CSV,
PNG, JPEG and WebP. Active HTML script/style content is discarded from the derived text.

Nothing enters the project at preview time. **Add Managed Copy** writes the accepted
bytes into the same project-managed attachment layout used by local files and records
the requested URL, final URL, fetch time, content type, redirect count and SHA-256 hash.
Remote text assembled for generation carries an explicit untrusted-reference boundary.

**Refresh Remote…** is available only for a selected remote attachment. It repeats the
same fetch and preview boundary, preserves the stable attachment identity and records a
bounded refresh history. The previous managed file remains recoverable as an orphan
asset. There is no periodic or on-open remote refresh.

## Compatibility boundary

The feature reuses the versioned attachment model, preprocessing summary, project and
character scopes, prompt character budget, portable project packaging and Vision image
analysis path. Project format version 2 remains unchanged because all new source and
preprocessing keys are additive and unknown attachment keys were already preserved.
