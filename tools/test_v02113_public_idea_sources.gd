extends SceneTree

const TEST_USER_DATA_ISOLATION = preload("res://tools/test_user_data_isolation.gd")
var _test_user_data_isolation := TEST_USER_DATA_ISOLATION.activate("v02113-public-idea-sources")

const CATALOG = preload(
	"res://scripts/services/public_idea_source_catalog_v02113.gd"
)
const IDEA_SOURCE = preload(
	"res://scripts/services/idea_source_service_v0213.gd"
)
const IDEA_WINDOW = preload(
	"res://scripts/ui/idea_generator_window_current.gd"
)
const PUBLIC_BROWSER = preload(
	"res://scripts/ui/public_idea_source_browser_v02113.gd"
)

var _failed := false
var _root_dir := "user://v02113-public-source-test"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_catalog_validation_and_integrity()
	await _test_live_browser_wiring()
	if _failed:
		quit(1)
		return
	print("V02113_PUBLIC_IDEA_SOURCES_OK")
	quit(0)


func _test_catalog_validation_and_integrity() -> void:
	var service := CATALOG.new()
	var source := _sample_source()
	var body := (JSON.stringify(source, "  ") + "\n").to_utf8_buffer()
	var digest := _sha256(body)
	var entry := {
		"order": 1,
		"id": source["id"],
		"title": source["title"],
		"description": source["description"],
		"source_version": "1.0",
		"content_rating": "general",
		"tags": ["reunion", "workplace"],
		"path": "idea-sources/%s/sample.ccfideasource.json" % digest.substr(0, 16),
		"size_bytes": body.size(),
		"sha256": digest
	}
	var manifest := {
		"format": CATALOG.FORMAT_ID,
		"schema_version": CATALOG.SCHEMA_VERSION,
		"title": "Public Idea Sources",
		"description": "Test catalog",
		"published_at": "2026-10-02T00:00:00Z",
		"source_count": 1,
		"sources": [entry]
	}
	var parsed := service.parse_manifest_text(JSON.stringify(manifest))
	_require(
		bool(parsed.get("ok", false))
		and ((parsed.get("catalog", {}) as Dictionary).get("sources", []) as Array).size() == 1,
		"A valid checksummed catalog must parse."
	)
	var source_result := service.validate_source_body(entry, body)
	_require(
		bool(source_result.get("ok", false))
		and str((source_result.get("source", {}) as Dictionary).get("id", "")) == source["id"],
		"A catalog source must pass checksum, identity and production schema validation."
	)
	var unsafe := entry.duplicate(true)
	unsafe["path"] = "../private.json"
	manifest["sources"] = [unsafe]
	_require(
		not bool(service.parse_manifest_text(JSON.stringify(manifest)).get("ok", true)),
		"Catalog entries must reject path traversal and non-catalog paths."
	)
	var wrong_hash := entry.duplicate(true)
	wrong_hash["sha256"] = "0".repeat(64)
	_require(
		not bool(service.validate_source_body(wrong_hash, body).get("ok", true)),
		"A downloaded source whose checksum differs from the manifest must be rejected."
	)
	var wrong_identity_source := source.duplicate(true)
	wrong_identity_source["id"] = "substituted-source"
	var wrong_identity_body := (JSON.stringify(wrong_identity_source, "  ") + "\n").to_utf8_buffer()
	var wrong_identity_entry := entry.duplicate(true)
	wrong_identity_entry["size_bytes"] = wrong_identity_body.size()
	wrong_identity_entry["sha256"] = _sha256(wrong_identity_body)
	_require(
		not bool(
			service.validate_source_body(wrong_identity_entry, wrong_identity_body).get("ok", true)
		),
		"A valid file must still be rejected when its source identity differs from the catalog."
	)
	var entries: Array[Dictionary] = [entry]
	_require(
		service.filter_entries(entries, "workplace").size() == 1
		and service.filter_entries(entries, "not-present").is_empty(),
		"Public catalog search must include source tags while excluding unrelated entries."
	)
	_require(
		service.source_url(entry) == (
			"https://charactercardforge.damee.info/" + str(entry["path"])
		),
		"Public source URLs must be built from the fixed catalog origin and a safe relative path."
	)


func _test_live_browser_wiring() -> void:
	var source_service := IDEA_SOURCE.new(_root_dir)
	var window := IDEA_WINDOW.new()
	window.set("_idea_source_service_v0213", source_service)
	root.add_child(window)
	await process_frame
	await process_frame
	var button := window.find_child("PublicIdeaSourcesButtonV02113", true, false) as Button
	var browser: Variant = window.get("_public_source_browser_v02113")
	_require(
		button != null
		and button.text == "Browse Public Sources…"
		and browser is Window
		and (browser as Window).get_script() == PUBLIC_BROWSER
		and not (browser as Window).transient,
		"Idea Sources must expose a screen-safe independent public catalog window."
	)
	var source := _sample_source()
	window.call("_on_public_source_chosen_v02113", source, {
		"id": source["id"], "title": source["title"]
	})
	var active := window.active_idea_source_v0213()
	var status: Label = window.get("_source_status_v0213")
	_require(
		str(active.get("id", "")) == source["id"]
		and not bool(window.get("_source_saved_v0213"))
		and status.text.contains("temporary until Save Current Source"),
		"Choosing a verified public source must activate a temporary copy without silently overwriting the local library."
	)
	window.queue_free()
	await process_frame


func _sample_source() -> Dictionary:
	return {
		"format": IDEA_SOURCE.FORMAT_ID,
		"schema_version": IDEA_SOURCE.SCHEMA_VERSION,
		"id": "public-old-friend-returns",
		"title": "Old Friend Returns",
		"description": "Reusable reunions with unresolved history.",
		"source_version": "1.0",
		"core_premise": "Someone important from the character's past returns unexpectedly.",
		"generation_rules": ["Keep {{user}}'s prior relationship and choices open."],
		"tags": ["reunion", "workplace"]
	}


func _sha256(body: PackedByteArray) -> String:
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(body)
	return hashing.finish().hex_encode()


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
