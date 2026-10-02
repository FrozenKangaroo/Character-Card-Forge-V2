class_name CCFPublicIdeaSourceCatalogV02113
extends RefCounted

const FORMAT_ID := "character-card-forge-public-idea-source-catalog"
const SCHEMA_VERSION := 1
const DEFAULT_MANIFEST_URL := "https://charactercardforge.damee.info/manifest.json"
const DEFAULT_SOURCE_ROOT_URL := "https://charactercardforge.damee.info/"
const MAX_CATALOG_ENTRIES := 500
const MAX_MANIFEST_BYTES := 2 * 1024 * 1024
const MAX_SOURCE_BYTES := 2 * 1024 * 1024

const IDEA_SOURCE_SERVICE_V0213 = preload(
	"res://scripts/services/idea_source_service_v0213.gd"
)


func parse_manifest_text(text: String) -> Dictionary:
	if text.to_utf8_buffer().size() > MAX_MANIFEST_BYTES:
		return _error("Catalog response is larger than the supported limit.")
	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		return _error(
			"Public Idea Source catalog JSON is invalid: %s (line %d)." % [
				json.get_error_message(), json.get_error_line()
			]
		)
	if not json.data is Dictionary:
		return _error("Public Idea Source catalog must be a JSON object.")
	var raw := json.data as Dictionary
	if str(raw.get("format", "")) != FORMAT_ID:
		return _error("Public Idea Source catalog has an unsupported format.")
	if int(raw.get("schema_version", 0)) != SCHEMA_VERSION:
		return _error("Public Idea Source catalog schema is not supported by this CCF version.")
	var raw_sources: Variant = raw.get("sources", [])
	if not raw_sources is Array:
		return _error("Public Idea Source catalog sources must be an array.")
	if (raw_sources as Array).size() > MAX_CATALOG_ENTRIES:
		return _error("Public Idea Source catalog contains too many entries.")
	var entries: Array[Dictionary] = []
	var seen_ids := {}
	for index in range((raw_sources as Array).size()):
		var value: Variant = (raw_sources as Array)[index]
		if not value is Dictionary:
			return _error("Catalog entry %d must be an object." % (index + 1))
		var parsed := _normalise_entry(value as Dictionary)
		if not bool(parsed.get("ok", false)):
			return _error(
				"Catalog entry %d is invalid: %s" % [
					index + 1, str(parsed.get("error", "Unknown error."))
				]
			)
		var entry: Dictionary = parsed.get("entry", {})
		var source_id := str(entry.get("id", ""))
		if seen_ids.has(source_id):
			return _error("Catalog contains duplicate source id '%s'." % source_id)
		seen_ids[source_id] = true
		entries.append(entry)
	entries.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		var first_order := int(first.get("order", 0))
		var second_order := int(second.get("order", 0))
		if first_order != second_order:
			return first_order < second_order
		return str(first.get("title", "")).naturalnocasecmp_to(
			str(second.get("title", ""))
		) < 0
	)
	var declared_count := int(raw.get("source_count", entries.size()))
	if declared_count != entries.size():
		return _error("Public Idea Source catalog count does not match its entries.")
	return {
		"ok": true,
		"catalog": {
			"title": str(raw.get("title", "Public Idea Sources")).strip_edges(),
			"description": str(raw.get("description", "")).strip_edges(),
			"published_at": str(raw.get("published_at", "")).strip_edges(),
			"source_count": entries.size(),
			"sources": entries
		}
	}


func source_url(entry: Dictionary, root_url: String = DEFAULT_SOURCE_ROOT_URL) -> String:
	var path := str(entry.get("path", "")).strip_edges()
	if not _safe_source_path(path):
		return ""
	var clean_root := root_url.strip_edges()
	if not clean_root.ends_with("/"):
		clean_root += "/"
	return "%s%s" % [clean_root, path]


func validate_source_body(entry: Dictionary, body: PackedByteArray) -> Dictionary:
	if body.is_empty():
		return _error("The selected public Idea Source was empty.")
	if body.size() > MAX_SOURCE_BYTES:
		return _error("The selected public Idea Source is larger than the supported limit.")
	var declared_size := int(entry.get("size_bytes", 0))
	if declared_size <= 0 or declared_size != body.size():
		return _error("The selected public Idea Source size does not match the catalog.")
	var expected_hash := str(entry.get("sha256", "")).to_lower()
	var hashing := HashingContext.new()
	if hashing.start(HashingContext.HASH_SHA256) != OK:
		return _error("Could not start public Idea Source integrity verification.")
	if hashing.update(body) != OK:
		return _error("Could not verify the public Idea Source download.")
	var actual_hash := hashing.finish().hex_encode()
	if actual_hash != expected_hash:
		return _error("The selected public Idea Source failed its integrity check.")
	var parsed := IDEA_SOURCE_SERVICE_V0213.new().parse_text(body.get_string_from_utf8())
	if not bool(parsed.get("load_allowed", false)):
		return _error(_source_parse_error(parsed))
	var source: Dictionary = parsed.get("source", {})
	if str(source.get("id", "")) != str(entry.get("id", "")):
		return _error("The downloaded Idea Source identity does not match the catalog.")
	return {"ok": true, "source": source.duplicate(true)}


func filter_entries(entries: Array[Dictionary], query: String) -> Array[Dictionary]:
	var clean_query := query.strip_edges().to_lower()
	var result: Array[Dictionary] = []
	for entry in entries:
		if clean_query.is_empty():
			result.append(entry.duplicate(true))
			continue
		var searchable := " ".join([
			str(entry.get("title", "")),
			str(entry.get("description", "")),
			" ".join(entry.get("tags", []))
		]).to_lower()
		if searchable.contains(clean_query):
			result.append(entry.duplicate(true))
	return result


func _normalise_entry(raw: Dictionary) -> Dictionary:
	var source_id := str(raw.get("id", "")).strip_edges()
	var title := str(raw.get("title", "")).strip_edges()
	var path := str(raw.get("path", "")).strip_edges()
	var checksum := str(raw.get("sha256", "")).strip_edges().to_lower()
	var size_bytes := int(raw.get("size_bytes", 0))
	if source_id.is_empty():
		return _error("id is required.")
	if title.is_empty():
		return _error("title is required.")
	if not _safe_source_path(path):
		return _error("path must be a safe relative idea-sources JSON path.")
	if checksum.length() != 64 or not checksum.is_valid_hex_number(false):
		return _error("sha256 must be a 64-character hexadecimal digest.")
	if size_bytes <= 0 or size_bytes > MAX_SOURCE_BYTES:
		return _error("size_bytes is outside the supported range.")
	var tags: Array[String] = []
	var raw_tags: Variant = raw.get("tags", [])
	if raw_tags is Array:
		for raw_tag in raw_tags:
			var tag := str(raw_tag).strip_edges()
			if not tag.is_empty() and not tags.has(tag):
				tags.append(tag)
	return {
		"ok": true,
		"entry": {
			"order": maxi(0, int(raw.get("order", 0))),
			"id": source_id,
			"title": title,
			"description": str(raw.get("description", "")).strip_edges(),
			"source_version": str(raw.get("source_version", "")).strip_edges(),
			"content_rating": str(raw.get("content_rating", "")).strip_edges(),
			"tags": tags,
			"path": path,
			"size_bytes": size_bytes,
			"sha256": checksum
		}
	}


func _safe_source_path(path: String) -> bool:
	if path.is_empty() or path.begins_with("/") or path.contains("\\"):
		return false
	if path.contains("://") or path.contains("?") or path.contains("#"):
		return false
	if path.contains("../") or path.contains("/..") or path.contains("//"):
		return false
	return (
		path.begins_with("idea-sources/")
		and path.to_lower().ends_with(IDEA_SOURCE_SERVICE_V0213.EXTENSION)
	)


func _source_parse_error(parsed: Dictionary) -> String:
	var messages: Array[String] = []
	for issue_value in parsed.get("errors", []):
		if issue_value is Dictionary:
			messages.append(str((issue_value as Dictionary).get("message", "Invalid source.")))
	if messages.is_empty():
		return "The downloaded file is not a supported Idea Source."
	return " ".join(messages)


func _error(message: String) -> Dictionary:
	return {"ok": false, "error": message}
