#!/usr/bin/env python3
"""Build the checksummed public Idea Source catalog manifest."""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re


FORMAT_ID = "character-card-forge-public-idea-source-catalog"
SOURCE_FORMAT = "character-card-forge-idea-source"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_dir", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    entries: list[dict[str, object]] = []
    files = sorted(args.source_dir.glob("*.ccfideasource.json"))
    for source_path in files:
        raw_bytes = source_path.read_bytes()
        source = json.loads(raw_bytes.decode("utf-8"))
        if source.get("format") != SOURCE_FORMAT:
            raise ValueError(f"{source_path.name}: unsupported Idea Source format")
        source_id = str(source.get("id", "")).strip()
        title = str(source.get("title", "")).strip()
        if not source_id or not title:
            raise ValueError(f"{source_path.name}: id and title are required")
        order_match = re.match(r"^(\d+)-", source_path.name)
        order = int(order_match.group(1)) if order_match else len(entries) + 1
        tags = [str(value).strip() for value in source.get("tags", []) if str(value).strip()]
        digest = hashlib.sha256(raw_bytes).hexdigest()
        entries.append(
            {
                "order": order,
                "id": source_id,
                "title": title,
                "description": str(source.get("description", "")).strip(),
                "source_version": str(source.get("source_version", "")).strip(),
                "content_rating": "adult" if "adult" in {tag.lower() for tag in tags} else "general",
                "tags": tags,
                # Content-addressed paths keep cached public objects immutable. A
                # changed source receives a new URL before manifest publication.
                "path": f"idea-sources/{digest[:16]}/{source_path.name}",
                "size_bytes": len(raw_bytes),
                "sha256": digest,
            }
        )

    if not entries:
        raise ValueError("No .ccfideasource.json files were found")
    ids = [entry["id"] for entry in entries]
    if len(ids) != len(set(ids)):
        raise ValueError("Duplicate Idea Source ids were found")
    manifest = {
        "format": FORMAT_ID,
        "schema_version": 1,
        "title": "Character Card Forge Public Idea Sources",
        "description": "Public reusable Idea Sources maintained for Character Card Forge.",
        "published_at": datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z"),
        "source_count": len(entries),
        "sources": entries,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Built {args.output} with {len(entries)} sources")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
