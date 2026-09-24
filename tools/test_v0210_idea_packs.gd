extends SceneTree

const IDEA_PACK_SERVICE = preload("res://scripts/services/idea_pack_service_v0210.gd")
const FIXTURE_PATH := "res://examples/idea-packs/japan-by-rail-roommates.ccfideas.json"

var _failed := false
var _root := ""


func _init() -> void:
	_root = "user://ccf_v0210_idea_pack_test_%d" % Time.get_ticks_usec()
	var service := IDEA_PACK_SERVICE.new(_root)
	_run_parser_checks(service)
	if not _failed:
		_run_import_conflict_checks(service)
	if not _failed:
		_run_round_trip_checks(service)
	_remove_tree(_root)
	if _failed:
		quit(1)
		return
	print("V0210_IDEA_PACKS_OK")
	quit(0)


func _run_parser_checks(service: CCFIdeaPackServiceV0210) -> void:
	var fixture_text := FileAccess.get_file_as_string(FIXTURE_PATH)
	var valid := service.parse_text(fixture_text)
	_require(bool(valid.get("ok", false)), "The example Idea Pack must validate.")
	_require(bool(valid.get("import_allowed", false)), "Schema version 1 must be importable.")
	var summary: Dictionary = valid.get("summary", {})
	_require(int(summary.get("seeds", 0)) == 1, "The sample must contain one Seed.")
	var entries: Array = valid.get("entries", [])
	_require(entries.size() == 1, "The sample must retain its entry.")
	if not entries.is_empty() and entries[0] is Dictionary:
		var entry: Dictionary = entries[0]
		_require("{{user}}" in str(entry.get("setup", "")), "{{user}} must survive parsing.")
		_require("{{char}}" in str(entry.get("setup", "")), "{{char}} must survive parsing.")
		var sections: Array = entry.get("sections", [])
		_require(sections.size() == 1, "Arbitrary labelled sections must be retained.")
		if not sections.is_empty() and sections[0] is Dictionary:
			_require(str((sections[0] as Dictionary).get("label", "")) == "Transport rule", "The arbitrary section label must survive.")

	var malformed := service.parse_text("{not json")
	_require(not bool(malformed.get("ok", true)), "Malformed JSON must fail validation.")
	_require(_has_issue(malformed.get("errors", []), "invalid_json"), "Malformed JSON needs a specific fatal error.")

	var wrong_format := service.parse_text(JSON.stringify({
		"format": "not-character-card-forge-ideas",
		"schema_version": 1,
		"pack": {},
		"entries": []
	}))
	_require(not bool(wrong_format.get("ok", true)), "The wrong format identifier must fail.")
	_require(_has_issue(wrong_format.get("errors", []), "wrong_format"), "Wrong format needs a specific fatal error.")

	var missing_pack := service.parse_text(JSON.stringify({
		"format": "character-card-forge-ideas",
		"schema_version": 1,
		"entries": []
	}))
	_require(not bool(missing_pack.get("ok", true)), "A missing top-level pack object must fail validation.")
	_require(_has_issue(missing_pack.get("errors", []), "missing_pack"), "A missing pack needs a specific fatal error.")

	var missing_required := service.parse_text(JSON.stringify({
		"format": "character-card-forge-ideas",
		"schema_version": 1,
		"pack": {},
		"entries": [{"id": "missing-title", "kind": "seed"}]
	}))
	_require(not bool(missing_required.get("ok", true)), "Missing required entry fields must fail.")
	_require(_has_issue(missing_required.get("errors", []), "missing_required_field"), "Missing fields need a specific error.")

	var minimal := service.parse_text(JSON.stringify({
		"format": "character-card-forge-ideas",
		"schema_version": 1,
		"pack": {"id": "minimal", "title": "最小限のアイデア"},
		"entries": [{"id": "unicode-一", "kind": "character_note", "title": "ミカのメモ"}]
	}))
	_require(bool(minimal.get("ok", false)), "Optional fields may be omitted and Unicode must remain valid.")
	var minimal_entries: Array = minimal.get("entries", [])
	if not minimal_entries.is_empty() and minimal_entries[0] is Dictionary:
		_require(str((minimal_entries[0] as Dictionary).get("title", "")) == "ミカのメモ", "Unicode text must survive normalization.")

	var malformed_section := service.parse_text(JSON.stringify({
		"format": "character-card-forge-ideas",
		"schema_version": 1,
		"pack": {"id": "section-warning", "title": "Section warning"},
		"entries": [{
			"id": "section-warning-entry",
			"kind": "character_note",
			"title": "Malformed extension section",
			"sections": ["not an object", {"label": "", "content": "Preserved content"}]
		}]
	}))
	_require(bool(malformed_section.get("ok", false)), "Malformed optional sections should warn without corrupting the pack.")
	_require(_has_issue(malformed_section.get("warnings", []), "invalid_section"), "Non-object sections need a validation warning.")
	_require(_has_issue(malformed_section.get("warnings", []), "unnamed_section"), "Unnamed extension sections need a validation warning.")

	var fixture_data: Variant = JSON.parse_string(fixture_text)
	if fixture_data is Dictionary:
		var duplicate_pack: Dictionary = (fixture_data as Dictionary).duplicate(true)
		var duplicate_entries: Array = duplicate_pack.get("entries", []).duplicate(true)
		duplicate_entries.append((duplicate_entries[0] as Dictionary).duplicate(true))
		duplicate_pack["entries"] = duplicate_entries
		var duplicate_result := service.parse_text(JSON.stringify(duplicate_pack))
		_require(bool(duplicate_result.get("ok", false)), "Duplicate IDs inside a pack are warnings, not parser corruption.")
		_require(_has_issue(duplicate_result.get("warnings", []), "duplicate_pack_id"), "Duplicate pack IDs must be reported.")

		var future_pack: Dictionary = (fixture_data as Dictionary).duplicate(true)
		future_pack["schema_version"] = 2
		var future_result := service.parse_text(JSON.stringify(future_pack))
		_require(bool(future_result.get("ok", false)), "A newer basic structure may be shown in preview.")
		_require(not bool(future_result.get("import_allowed", true)), "A newer schema must not silently import.")
		_require(_has_issue(future_result.get("warnings", []), "newer_schema"), "A newer schema needs a clear warning.")

		var extra_pack: Dictionary = (fixture_data as Dictionary).duplicate(true)
		var extra_entries: Array = extra_pack.get("entries", []).duplicate(true)
		var extra_entry: Dictionary = (extra_entries[0] as Dictionary).duplicate(true)
		extra_entry["future_generator_axis"] = {"mode": "retained"}
		extra_entries[0] = extra_entry
		extra_pack["entries"] = extra_entries
		var extra_result := service.parse_text(JSON.stringify(extra_pack))
		_require(bool(extra_result.get("ok", false)), "Unknown entry fields must not invalidate schema version 1.")
		_require(_has_issue(extra_result.get("warnings", []), "unknown_field"), "Unknown entry fields need a preservation warning.")
		var extra_result_entries: Array = extra_result.get("entries", [])
		if not extra_result_entries.is_empty() and extra_result_entries[0] is Dictionary:
			_require((extra_result_entries[0] as Dictionary).has("future_generator_axis"), "Unknown fields must be preserved.")


func _run_import_conflict_checks(service: CCFIdeaPackServiceV0210) -> void:
	var fixture_text := FileAccess.get_file_as_string(FIXTURE_PATH)
	var first_preview := service.parse_text(fixture_text)
	var first_import := service.import_preview(first_preview, [{"index": 0, "selected": true, "action": "import"}])
	_require(bool(first_import.get("ok", false)), "A valid selected entry must import.")
	_require(int(first_import.get("imported", 0)) == 1, "The first import must create one record.")
	_require(service.list_local_ideas(true).size() == 1, "The first import must create exactly one local idea.")

	var repeat_preview := service.parse_text(fixture_text)
	var analysed: Array = repeat_preview.get("analysed_entries", [])
	_require(not analysed.is_empty(), "The repeat preview must contain the existing entry.")
	if not analysed.is_empty() and analysed[0] is Dictionary:
		_require(str((analysed[0] as Dictionary).get("conflict", "")) == "existing_id", "Stable imported IDs must detect an existing record.")
	var skipped := service.import_preview(repeat_preview, [{"index": 0, "selected": true, "action": "skip"}])
	_require(bool(skipped.get("ok", false)), "Skipping an existing conflict must be a successful no-op.")
	_require(service.list_local_ideas(true).size() == 1, "Importing the same pack with Skip must not duplicate it.")

	var updated_data: Variant = JSON.parse_string(fixture_text)
	if updated_data is Dictionary:
		var updated_pack: Dictionary = (updated_data as Dictionary).duplicate(true)
		var pack_metadata: Dictionary = updated_pack.get("pack", {}).duplicate(true)
		pack_metadata["source_version"] = "0.3"
		updated_pack["pack"] = pack_metadata
		var updated_entries: Array = updated_pack.get("entries", []).duplicate(true)
		var updated_entry: Dictionary = (updated_entries[0] as Dictionary).duplicate(true)
		updated_entry["title"] = "Japan by Rail Roommates — Revised"
		updated_entry["hidden_motive"] = "She selected the trip to test whether she can enjoy travel without following someone else's plan."
		updated_entries[0] = updated_entry
		updated_pack["entries"] = updated_entries
		var update_preview := service.parse_text(JSON.stringify(updated_pack))
		var replaced := service.import_preview(update_preview, [{"index": 0, "selected": true, "action": "replace"}])
		_require(bool(replaced.get("ok", false)), "Replace/update must succeed for the same stable ID.")
		_require(int(replaced.get("replaced", 0)) == 1, "Replace/update must report one update.")
		var after_replace := service.list_local_ideas(true)
		_require(after_replace.size() == 1, "Replace/update must not create a duplicate.")
		if not after_replace.is_empty():
			_require(str(after_replace[0].get("title", "")) == "Japan by Rail Roommates — Revised", "Replace/update must persist the newer entry.")
		var kept := service.import_preview(update_preview, [{"index": 0, "selected": true, "action": "keep_both"}])
		_require(bool(kept.get("ok", false)), "Keep both must succeed.")
		_require(int(kept.get("copies", 0)) == 1, "Keep both must report one copy.")
		_require(service.list_local_ideas(true).size() == 2, "Keep both must create one additional local record.")

	var title_duplicate_data: Variant = JSON.parse_string(fixture_text)
	if title_duplicate_data is Dictionary:
		var title_pack: Dictionary = (title_duplicate_data as Dictionary).duplicate(true)
		var title_entries: Array = title_pack.get("entries", []).duplicate(true)
		var title_entry: Dictionary = (title_entries[0] as Dictionary).duplicate(true)
		title_entry["id"] = "DIFFERENT-STABLE-ID"
		title_entry["title"] = "Japan by Rail Roommates — Revised"
		title_entries[0] = title_entry
		title_pack["entries"] = title_entries
		var title_preview := service.parse_text(JSON.stringify(title_pack))
		var title_rows: Array = title_preview.get("analysed_entries", [])
		if not title_rows.is_empty() and title_rows[0] is Dictionary:
			_require(str((title_rows[0] as Dictionary).get("conflict", "")) == "likely_title_duplicate", "Matching titles with different IDs must warn without becoming identity matches.")


func _run_round_trip_checks(service: CCFIdeaPackServiceV0210) -> void:
	var ideas := service.list_local_ideas(true)
	if not ideas.is_empty() and ideas[0] is Dictionary:
		var edited_idea: Dictionary = (ideas[0] as Dictionary).duplicate(true)
		edited_idea["notes"] = "Edited after import; preserve this notebook note on export."
		var edited_entry := service.idea_to_entry(edited_idea)
		_require(
			_string_array(edited_entry.get("notes", [])).has("Edited after import; preserve this notebook note on export."),
			"Notebook note edits must round-trip into exported structured entries."
		)
	var exported := service.build_export_pack(ideas, {
		"id": "round-trip-test",
		"title": "Round Trip Test",
		"source_version": "1"
	})
	var reparsed := service.parse_text(JSON.stringify(exported))
	_require(bool(reparsed.get("ok", false)), "An exported pack must re-import successfully.")
	var entries: Array = reparsed.get("entries", [])
	_require(entries.size() == ideas.size(), "Round-trip export must retain every selected entry.")
	if not entries.is_empty() and entries[0] is Dictionary:
		var entry: Dictionary = entries[0]
		_require("{{user}}" in str(entry.get("setup", "")), "{{user}} must survive import/export.")
		_require("{{char}}" in str(entry.get("setup", "")), "{{char}} must survive import/export.")
		_require(not (entry.get("sections", []) as Array).is_empty(), "Arbitrary sections must survive import/export.")
	var context := service.generation_context_for_idea(ideas[0]) if not ideas.is_empty() else ""
	_require("GENERATION RULES" in context, "Imported generation rules must be available to Idea Generator context.")
	_require("GUARDRAILS" not in context, "Empty optional guidance should not add meaningless context.")


func _has_issue(value: Variant, code: String) -> bool:
	if not value is Array:
		return false
	for issue_value in value:
		if issue_value is Dictionary and str((issue_value as Dictionary).get("code", "")) == code:
			return true
	return false


func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if not value is Array:
		return result
	for item in value:
		result.append(str(item))
	return result


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _remove_tree(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	var directory := DirAccess.open(absolute)
	if directory == null:
		return
	directory.list_dir_begin()
	var item_name := directory.get_next()
	while not item_name.is_empty():
		if item_name != "." and item_name != "..":
			var child := absolute.path_join(item_name)
			if directory.current_is_dir():
				_remove_tree(child)
			else:
				DirAccess.remove_absolute(child)
		item_name = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(absolute)
