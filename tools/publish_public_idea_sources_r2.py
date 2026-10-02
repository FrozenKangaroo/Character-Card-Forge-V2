#!/usr/bin/env python3
"""Publish one or more public Character Card Forge Idea Sources to Cloudflare R2.

Source snapshots are stored in GitHub as *.ccfideasource.txt so they are not
picked up by Character Card Forge's *.json export include filter. A snapshot
may contain the exact JSON bytes or a CCF_GZIP_BASE64_V1 envelope. Envelopes
are decoded back to the exact JSON bytes before hashing and publishing; only
the object filename extension changes to *.ccfideasource.json.

Publishing order is deliberate:
1. Load and validate the current live manifest directly from R2.
2. Validate each staged Idea Source and calculate its SHA-256 entry.
3. Create immutable content-addressed source objects if they do not exist.
4. Upload manifest.json last.
5. Re-read R2 objects and verify hashes/bytes.
6. Verify each unique public source URL through the custom domain.
"""

from __future__ import annotations

import argparse
import base64
from datetime import datetime, timezone
import gzip
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import time
from typing import Any
from urllib.request import Request, urlopen

import boto3
from botocore.exceptions import ClientError


CATALOG_FORMAT = "character-card-forge-public-idea-source-catalog"
SOURCE_FORMAT = "character-card-forge-idea-source"
SCHEMA_VERSION = 1
MANIFEST_KEY = "manifest.json"
MAX_SOURCE_BYTES = 2 * 1024 * 1024
IMMUTABLE_CACHE_CONTROL = "public, max-age=31536000, immutable"
MANIFEST_CACHE_CONTROL = "public, max-age=60, must-revalidate"
COMPRESSED_ENVELOPE_PREFIX = b"CCF_GZIP_BASE64_V1\n"
PARTS_ENVELOPE_PREFIX = b"CCF_GZIP_BASE64_PARTS_V1\n"
PARTS_ROOT = Path(".github/public-idea-source-publish-data")


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _published_filename(snapshot: Path) -> str:
    name = snapshot.name
    suffix = ".ccfideasource.txt"
    if not name.endswith(suffix):
        raise ValueError(f"{snapshot}: expected filename ending in {suffix}")
    return name[: -len(suffix)] + ".ccfideasource.json"


def _source_entry(snapshot: Path) -> tuple[dict[str, Any], bytes]:
    stored = snapshot.read_bytes()
    if not stored:
        raise ValueError(f"{snapshot}: file is empty")

    if stored.startswith(PARTS_ENVELOPE_PREFIX):
        try:
            part_lines = stored[len(PARTS_ENVELOPE_PREFIX):].decode("utf-8").splitlines()
        except UnicodeDecodeError as exc:
            raise ValueError(f"{snapshot}: invalid CCF_GZIP_BASE64_PARTS_V1 envelope") from exc
        part_paths = [line.strip() for line in part_lines if line.strip()]
        if not part_paths:
            raise ValueError(f"{snapshot}: parts envelope contains no part paths")
        encoded_parts: list[str] = []
        for part_text in part_paths:
            part = Path(part_text)
            try:
                part.relative_to(PARTS_ROOT)
            except ValueError as exc:
                raise ValueError(f"{snapshot}: unsafe part path {part_text!r}") from exc
            if ".." in part.parts or not part.is_file():
                raise ValueError(f"{snapshot}: missing or unsafe part path {part_text!r}")
            encoded_parts.append("".join(part.read_text(encoding="ascii").split()))
        encoded = "".join(encoded_parts).encode("ascii")
        try:
            compressed = base64.b64decode(encoded, validate=True)
            raw = gzip.decompress(compressed)
        except Exception as exc:
            raise ValueError(f"{snapshot}: invalid compressed part data: {exc}") from exc
    elif stored.startswith(COMPRESSED_ENVELOPE_PREFIX):
        encoded = stored[len(COMPRESSED_ENVELOPE_PREFIX):].strip()
        try:
            compressed = base64.b64decode(encoded, validate=True)
            raw = gzip.decompress(compressed)
        except Exception as exc:
            raise ValueError(f"{snapshot}: invalid CCF_GZIP_BASE64_V1 envelope: {exc}") from exc
    else:
        raw = stored

    if not raw:
        raise ValueError(f"{snapshot}: decoded source is empty")
    if len(raw) > MAX_SOURCE_BYTES:
        raise ValueError(f"{snapshot}: decoded source exceeds {MAX_SOURCE_BYTES} bytes")

    try:
        source = json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ValueError(f"{snapshot}: invalid UTF-8 JSON: {exc}") from exc

    if not isinstance(source, dict):
        raise ValueError(f"{snapshot}: source must be a JSON object")
    if source.get("format") != SOURCE_FORMAT:
        raise ValueError(f"{snapshot}: unsupported Idea Source format")
    if int(source.get("schema_version", 0)) != 1:
        raise ValueError(f"{snapshot}: unsupported Idea Source schema_version")

    source_id = str(source.get("id", "")).strip()
    title = str(source.get("title", "")).strip()
    if not source_id or not title:
        raise ValueError(f"{snapshot}: id and title are required")

    raw_tags = source.get("tags", [])
    if not isinstance(raw_tags, list):
        raise ValueError(f"{snapshot}: tags must be an array")
    tags: list[str] = []
    for value in raw_tags:
        tag = str(value).strip()
        if tag and tag not in tags:
            tags.append(tag)

    filename = _published_filename(snapshot)
    order_match = re.match(r"^(\d+)-", filename)
    if not order_match:
        raise ValueError(f"{snapshot}: filename must begin with a numeric order such as 34-")
    order = int(order_match.group(1))
    if order <= 0:
        raise ValueError(f"{snapshot}: order must be positive")

    digest = _sha256(raw)
    object_path = f"idea-sources/{digest[:16]}/{filename}"
    entry = {
        "order": order,
        "id": source_id,
        "title": title,
        "description": str(source.get("description", "")).strip(),
        "source_version": str(source.get("source_version", "")).strip(),
        "content_rating": "adult" if "adult" in {tag.lower() for tag in tags} else "general",
        "tags": tags,
        "path": object_path,
        "size_bytes": len(raw),
        "sha256": digest,
    }
    return entry, raw


def _load_manifest(
    s3: Any, bucket: str, public_root_url: str
) -> dict[str, Any]:
    try:
        response = s3.get_object(Bucket=bucket, Key=MANIFEST_KEY)
        raw = response["Body"].read()
    except ClientError as exc:
        code = str(exc.response.get("Error", {}).get("Code", ""))
        if code != "AccessDenied":
            raise RuntimeError(
                f"Could not read existing {MANIFEST_KEY} from R2 (error {code or 'unknown'})."
            ) from exc

        # Some narrowly scoped R2 credentials may be able to publish objects while
        # authenticated reads are denied. The catalog is public by design, so use
        # the custom domain as a safe read fallback and continue to require write
        # access for publication.
        url = public_root_url.rstrip("/") + "/" + MANIFEST_KEY
        try:
            request = Request(
                url,
                headers={
                    "Accept": "application/json",
                    "Cache-Control": "no-cache",
                    "User-Agent": "Character-Card-Forge-R2-Publisher/1",
                },
            )
            with urlopen(request, timeout=20) as public_response:
                raw = public_response.read()
        except Exception as public_exc:
            raise RuntimeError(
                "Authenticated R2 manifest read was denied and the public "
                f"manifest fallback also failed: {public_exc}"
            ) from public_exc
        print("Authenticated R2 read denied; loaded live manifest via public catalog URL.")
    try:
        manifest = json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"Existing {MANIFEST_KEY} is not valid UTF-8 JSON: {exc}") from exc

    if not isinstance(manifest, dict):
        raise RuntimeError("Existing manifest must be a JSON object.")
    if manifest.get("format") != CATALOG_FORMAT:
        raise RuntimeError("Existing manifest has an unsupported format.")
    if int(manifest.get("schema_version", 0)) != SCHEMA_VERSION:
        raise RuntimeError("Existing manifest has an unsupported schema_version.")
    sources = manifest.get("sources")
    if not isinstance(sources, list):
        raise RuntimeError("Existing manifest sources must be an array.")
    declared = int(manifest.get("source_count", len(sources)))
    if declared != len(sources):
        raise RuntimeError("Existing manifest source_count does not match sources.")

    seen: set[str] = set()
    for index, entry in enumerate(sources, start=1):
        if not isinstance(entry, dict):
            raise RuntimeError(f"Existing manifest entry {index} is not an object.")
        source_id = str(entry.get("id", "")).strip()
        if not source_id:
            raise RuntimeError(f"Existing manifest entry {index} is missing id.")
        if source_id in seen:
            raise RuntimeError(f"Existing manifest contains duplicate id {source_id!r}.")
        seen.add(source_id)
    return manifest


def _merge_manifest(
    manifest: dict[str, Any], source_entries: list[dict[str, Any]]
) -> dict[str, Any]:
    current = {
        str(entry.get("id", "")): dict(entry)
        for entry in manifest.get("sources", [])
    }
    for entry in source_entries:
        current[entry["id"]] = entry

    merged = list(current.values())
    merged.sort(
        key=lambda entry: (
            int(entry.get("order", 0)),
            str(entry.get("title", "")).casefold(),
            str(entry.get("id", "")),
        )
    )

    order_owner: dict[int, str] = {}
    for entry in merged:
        order = int(entry.get("order", 0))
        source_id = str(entry.get("id", ""))
        if order <= 0:
            raise RuntimeError(f"Manifest entry {source_id!r} has invalid order {order}.")
        previous = order_owner.get(order)
        if previous is not None and previous != source_id:
            raise RuntimeError(
                f"Manifest order {order} is used by both {previous!r} and {source_id!r}."
            )
        order_owner[order] = source_id

    updated = dict(manifest)
    updated["format"] = CATALOG_FORMAT
    updated["schema_version"] = SCHEMA_VERSION
    updated.setdefault("title", "Character Card Forge Public Idea Sources")
    updated.setdefault(
        "description",
        "Public reusable Idea Sources maintained for Character Card Forge.",
    )
    updated["published_at"] = (
        datetime.now(timezone.utc)
        .isoformat(timespec="seconds")
        .replace("+00:00", "Z")
    )
    updated["source_count"] = len(merged)
    updated["sources"] = merged
    return updated


def _object_bytes(s3: Any, bucket: str, key: str) -> bytes | None:
    try:
        response = s3.get_object(Bucket=bucket, Key=key)
    except ClientError as exc:
        code = str(exc.response.get("Error", {}).get("Code", ""))
        if code in {"NoSuchKey", "404", "NotFound", "AccessDenied"}:
            return None
        raise
    return response["Body"].read()


def _verify_public_url(root: str, key: str, expected_sha: str) -> None:
    url = root.rstrip("/") + "/" + str(PurePosixPath(key))
    last_error: Exception | None = None
    for attempt in range(1, 6):
        try:
            request = Request(
                url,
                headers={
                    "Accept": "application/json",
                    "Cache-Control": "no-cache",
                    "User-Agent": "Character-Card-Forge-R2-Publisher/1",
                },
            )
            with urlopen(request, timeout=20) as response:
                body = response.read()
            actual = _sha256(body)
            if actual != expected_sha:
                raise RuntimeError(
                    f"public URL hash mismatch: expected {expected_sha}, got {actual}"
                )
            return
        except Exception as exc:  # network/CDN propagation retry
            last_error = exc
            if attempt < 5:
                time.sleep(2 * attempt)
    raise RuntimeError(f"Could not verify public URL {url}: {last_error}")


def _write_step_summary(
    entries: list[dict[str, Any]], source_count: int, manifest_sha: str
) -> None:
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY", "")
    if not summary_path:
        return
    lines = [
        "### R2 public Idea Source publish",
        "",
        f"- Manifest source count: **{source_count}**",
        f"- Manifest SHA-256: `{manifest_sha}`",
        "",
        "| Order | Source | Bytes | SHA-256 prefix | Object |",
        "| ---: | --- | ---: | --- | --- |",
    ]
    for entry in entries:
        lines.append(
            "| {order} | {title} | {size_bytes} | `{prefix}` | `{path}` |".format(
                order=entry["order"],
                title=str(entry["title"]).replace("|", "\\|"),
                size_bytes=entry["size_bytes"],
                prefix=entry["sha256"][:16],
                path=entry["path"],
            )
        )
    with open(summary_path, "a", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bucket", required=True)
    parser.add_argument("--endpoint-url", required=True)
    parser.add_argument("--public-root-url", required=True)
    parser.add_argument("sources", nargs="+", type=Path)
    args = parser.parse_args()

    s3 = boto3.client(
        "s3",
        endpoint_url=args.endpoint_url,
        region_name="auto",
    )

    manifest = _load_manifest(s3, args.bucket, args.public_root_url)

    source_entries: list[dict[str, Any]] = []
    source_payloads: list[tuple[dict[str, Any], bytes]] = []
    seen_input_ids: set[str] = set()
    for snapshot in args.sources:
        entry, raw = _source_entry(snapshot)
        if entry["id"] in seen_input_ids:
            raise RuntimeError(f"Duplicate staged source id {entry['id']!r}.")
        seen_input_ids.add(entry["id"])
        source_entries.append(entry)
        source_payloads.append((entry, raw))

    updated_manifest = _merge_manifest(manifest, source_entries)
    manifest_bytes = (
        json.dumps(updated_manifest, ensure_ascii=False, indent=2).encode("utf-8")
        + b"\n"
    )

    # Source objects are immutable. If the content-addressed key already exists,
    # verify it and leave it untouched.
    for entry, raw in source_payloads:
        key = str(entry["path"])
        existing = _object_bytes(s3, args.bucket, key)
        if existing is None:
            s3.put_object(
                Bucket=args.bucket,
                Key=key,
                Body=raw,
                ContentType="application/json",
                CacheControl=IMMUTABLE_CACHE_CONTROL,
            )
            print(f"Uploaded immutable source: {key}")
        else:
            if existing != raw:
                raise RuntimeError(
                    f"Existing immutable object {key!r} does not match its SHA-addressed bytes."
                )
            print(f"Immutable source already exists and matches: {key}")

    # Manifest is the publication pointer and must always be written last.
    s3.put_object(
        Bucket=args.bucket,
        Key=MANIFEST_KEY,
        Body=manifest_bytes,
        ContentType="application/json",
        CacheControl=MANIFEST_CACHE_CONTROL,
    )
    print(
        f"Published {MANIFEST_KEY} last with "
        f"{updated_manifest['source_count']} sources."
    )

    # Verify exact R2 bytes after publication.
    verified_manifest = _object_bytes(s3, args.bucket, MANIFEST_KEY)
    if verified_manifest is not None and verified_manifest != manifest_bytes:
        raise RuntimeError("R2 manifest verification failed: stored bytes differ.")

    for entry, raw in source_payloads:
        key = str(entry["path"])
        stored = _object_bytes(s3, args.bucket, key)
        if stored is not None:
            if stored != raw:
                raise RuntimeError(f"R2 source verification failed for {key!r}.")
            if len(stored) != int(entry["size_bytes"]):
                raise RuntimeError(f"R2 source size verification failed for {key!r}.")
            if _sha256(stored) != str(entry["sha256"]):
                raise RuntimeError(f"R2 source SHA-256 verification failed for {key!r}.")
        _verify_public_url(args.public_root_url, key, str(entry["sha256"]))
        print(f"Verified published source URL: {key}")

    manifest_sha = _sha256(manifest_bytes)
    # Query-string cache busting is safe here because this is publisher-only
    # verification; catalog source paths themselves remain strict relative paths.
    manifest_verify_url = (
        args.public_root_url.rstrip("/")
        + "/"
        + MANIFEST_KEY
        + "?verify="
        + manifest_sha
    )
    last_manifest_error: Exception | None = None
    for attempt in range(1, 6):
        try:
            request = Request(
                manifest_verify_url,
                headers={
                    "Accept": "application/json",
                    "Cache-Control": "no-cache",
                    "User-Agent": "Character-Card-Forge-R2-Publisher/1",
                },
            )
            with urlopen(request, timeout=20) as response:
                public_manifest = response.read()
            if _sha256(public_manifest) != manifest_sha:
                raise RuntimeError("public manifest hash has not updated yet")
            last_manifest_error = None
            break
        except Exception as exc:
            last_manifest_error = exc
            if attempt < 5:
                time.sleep(2 * attempt)
    if last_manifest_error is not None:
        raise RuntimeError(
            f"Could not verify published manifest through custom domain: {last_manifest_error}"
        )
    _write_step_summary(
        source_entries,
        int(updated_manifest["source_count"]),
        manifest_sha,
    )
    print(f"Verified manifest SHA-256: {manifest_sha}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
