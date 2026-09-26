extends SceneTree

const SOURCE_SERVICE = preload(
	"res://scripts/services/idea_source_service_v0213.gd"
)
const SIMILAR_SERVICE = preload(
	"res://scripts/services/similar_idea_source_service_v0213.gd"
)
const PACK_SERVICE = preload(
	"res://scripts/services/idea_pack_service_v0210.gd"
)
const NOTEBOOK_SERVICE = preload(
	"res://scripts/services/idea_notebook_service_v01532.gd"
)
const IDEA_WINDOW = preload(
	"res://scripts/ui/idea_generator_window_current.gd"
)
const ALTERNATIVE_WORKSPACE = preload(
	"res://scripts/ui/workspace_v01410.gd"
)
const GENERATION_SERVICE = preload(
	"res://scripts/services/generation_service_current.gd"
)

var _failed := false
var _root_dir := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_root_dir = "res://.godot/v0213-test-%d" % Time.get_ticks_usec()
	_test_parser_contract()
	_test_storage_and_round_trip()
	_test_existing_workflows_unchanged()
	_test_similar_idea_extraction()
	if not _failed:
		await _test_live_ui_and_active_source()
	_remove_tree(_root_dir)
	if _failed:
		quit(1)
		return
	print("V0213_IDEA_SOURCES_OK")
	quit(0)


func _sample_source(title_value: String = "She Got Pregnant") -> Dictionary:
	return {
		"format": "character-card-forge-idea-source",
		"schema_version": 1,
		"id": "source-pregnancy-series",
		"title": title_value,
		"description": "A reusable dramatic relationship engine.",
		"source_version": "2026.1",
		"bible": {
			"series_id": "series-family-pressure",
			"title": "Family Pressure",
			"summary": "Stories about relationships under life-changing pressure."
		},
		"summary": "A pregnancy changes an established relationship.",
		"core_premise": "A couple must face pregnancy, trust and uncertain consequences.",
		"setup": "Begin shortly before or after discovery.",
		"core_variables": ["paternity certainty", "relationship length", "confession timing"],
		"generation_rules": ["Create genuinely different casts", "Keep {{user}} agency open"],
		"guardrails": ["All sexual participants are adults", "Do not decide {{user}}'s response"],
		"diversity_axes": ["setting", "motive", "reveal mechanism"],
		"cross_links": ["Family Pressure", "Second Chances"],
		"tags": ["drama", "romance", "日本語"],
		"notes": "Keep {{char}} varied across outputs.",
		"sections": [{
			"id": "truth",
			"label": "Ground truth",
			"content": "Every idea must know the truth even if {{user}} does not.",
			"future_section_option": {"preserve": true}
		}],
		"raw_prompt": "Vary emotional tone without losing the engine.",
		"future_top_level": {"nested": [1, "é", true]}
	}


func _test_parser_contract() -> void:
	var service := SOURCE_SERVICE.new(_root_dir)
	var source := _sample_source()
	var parsed := service.parse_text(JSON.stringify(source))
	_require(
		bool(parsed.get("ok", false))
		and bool(parsed.get("load_allowed", false))
		and str((parsed.get("source", {}) as Dictionary).get("id", "")) == "source-pregnancy-series",
		"1. A valid Idea Source must parse with its stable ID."
	)
	var invalid := service.parse_text("{not-json")
	_require(
		not bool(invalid.get("ok", true))
		and _has_issue(invalid, "invalid_json"),
		"2. Invalid JSON must be rejected with a precise issue."
	)
	var wrong := source.duplicate(true)
	wrong["format"] = "character-card-forge-ideas"
	var wrong_result := service.parse_text(JSON.stringify(wrong))
	_require(
		not bool(wrong_result.get("ok", true))
		and _has_issue(wrong_result, "wrong_format"),
		"3. Idea Packs must not be accepted as Idea Sources."
	)
	var newer := source.duplicate(true)
	newer["schema_version"] = 99
	var newer_result := service.parse_text(JSON.stringify(newer))
	_require(
		bool(newer_result.get("ok", false))
		and bool(newer_result.get("read_only", false))
		and not bool(newer_result.get("load_allowed", true)),
		"4. Newer schemas must be preserved for read-only preview rather than used unsafely."
	)
	var missing := source.duplicate(true)
	missing.erase("id")
	var missing_result := service.parse_text(JSON.stringify(missing))
	_require(
		not bool(missing_result.get("ok", true))
		and _has_issue(missing_result, "missing_id"),
		"5. Missing stable IDs must be reported."
	)
	var untitled := _sample_source("")
	var untitled_result := service.parse_text(JSON.stringify(untitled))
	_require(
		bool(untitled_result.get("load_allowed", false))
		and str((untitled_result.get("source", {}) as Dictionary).get("title", "")).is_empty(),
		"6. A title must remain optional."
	)
	var suggested := service.suggested_title_fallback(untitled)
	var generation_service := GENERATION_SERVICE.new()
	var naming_job := generation_service.queue_idea_source_title_v0213(
		service.generation_context(untitled),
		{
			"base_url": "http://127.0.0.1:9/v1",
			"model": "test-model",
			"max_output_tokens": 64
		},
		0,
		"test-project",
		"source-pregnancy-series"
	)
	var queued_jobs: Array = generation_service.get("_queue")
	_require(
		not suggested.is_empty()
		and service.suggested_title_fallback(source) == "She Got Pregnant"
		and bool(naming_job.get("ok", false))
		and queued_jobs.size() == 1
		and str((queued_jobs[0] as Dictionary).get("type", "")) == "idea_source_title"
		and JSON.stringify((queued_jobs[0] as Dictionary).get("payload", {})).contains("editable reusable Idea Source name"),
		"7. Blank titles need a non-blocking fallback while user titles stay unchanged."
	)
	generation_service.free()
	var reparsed: Dictionary = parsed.get("source", {})
	_require(
		JSON.stringify(reparsed).contains("{{user}}")
		and JSON.stringify(reparsed).contains("{{char}}")
		and JSON.stringify(reparsed).contains("日本語"),
		"8. Unicode and card placeholders must round-trip exactly."
	)
	_require(
		(reparsed.get("sections", []) as Array).size() == 1
		and str(((reparsed.get("sections", []) as Array)[0] as Dictionary).get("label", "")) == "Ground truth",
		"9. Arbitrary labelled sections must survive parsing."
	)
	_require(
		(reparsed.get("future_top_level", {}) as Dictionary).has("nested")
		and (((reparsed.get("sections", []) as Array)[0] as Dictionary).get("future_section_option", {}) as Dictionary).get("preserve", false),
		"10. Unknown top-level and section fields must be preserved."
	)
	var context := service.generation_context(reparsed)
	_require(
		context.contains("Core premise / reusable engine")
		and context.contains("Core variables")
		and context.contains("Generation rules")
		and context.contains("Guardrails")
		and context.contains("Suggested diversity axes")
		and context.contains("Cross-links / related Series")
		and context.contains("Custom section — Ground truth")
		and context.contains("Raw / custom prompt"),
		"14. Generation context must retain every structured source dimension as labelled context."
	)


func _test_storage_and_round_trip() -> void:
	var service := SOURCE_SERVICE.new(_root_dir)
	var notebook_before := NOTEBOOK_SERVICE.list_ideas({"include_archived": true}).size()
	var external_path := _root_dir.path_join("temporary.ccfideasource.json")
	_write_text(external_path, JSON.stringify(_sample_source(), "  "))
	var external := service.parse_file(external_path)
	_require(
		bool(external.get("load_allowed", false))
		and service.list_sources().is_empty()
		and NOTEBOOK_SERVICE.list_ideas({"include_archived": true}).size() == notebook_before,
		"11 and 23. Loading an external source must create neither a library record nor an Idea Notebook record."
	)
	var saved := service.save_source(external.get("source", {}))
	var loaded := service.load_source("source-pregnancy-series")
	_require(
		bool(saved.get("ok", false))
		and bool(loaded.get("ok", false))
		and service.list_sources().size() == 1
		and str((loaded.get("source", {}) as Dictionary).get("title", "")) == "She Got Pregnant",
		"12. Explicit internal save/load must retain a reusable source independently."
	)
	var export_path := _root_dir.path_join("round-trip.ccfideasource.json")
	var exported := service.export_to_file(export_path, loaded.get("source", {}))
	var imported := service.parse_file(str(exported.get("path", "")))
	var imported_future: Dictionary = (
		(imported.get("source", {}) as Dictionary).get(
			"future_top_level", {}
		) as Dictionary
	)
	_require(
		bool(exported.get("ok", false))
		and bool(imported.get("load_allowed", false))
		and imported_future.has("nested")
		and (imported_future.get("nested", []) as Array).size() == 3
		and str((imported_future.get("nested", []) as Array)[1]) == "é",
		"13. Export then import must preserve the source and future fields."
	)
	var duplicated := service.duplicate_source("source-pregnancy-series")
	_require(
		bool(duplicated.get("ok", false))
		and str((duplicated.get("source", {}) as Dictionary).get("id", "")) != "source-pregnancy-series",
		"Saved sources must be duplicable with a new stable identity."
	)


func _test_existing_workflows_unchanged() -> void:
	var pack := {
		"format": "character-card-forge-ideas",
		"schema_version": 1,
		"pack": {"id": "legacy-pack", "title": "Existing Idea Pack"},
		"entries": [{
			"id": "legacy-idea",
			"kind": "seed",
			"title": "Existing generated Idea",
			"summary": "A finished Idea output."
		}]
	}
	var pack_result := PACK_SERVICE.new(_root_dir.path_join("notebook")).parse_text(
		JSON.stringify(pack)
	)
	_require(
		bool(pack_result.get("import_allowed", false))
		and (pack_result.get("entries", []) as Array).size() == 1,
		"16. Existing .ccfideas.json data must remain an importable Idea Pack output."
	)
	var alternative := ALTERNATIVE_WORKSPACE.new()
	_require(
		alternative.has_method("_build_derivation_concept")
		and alternative.has_method("_on_derivation_create_requested"),
		"17. Existing Related Character / Alternative Version behavior must remain present."
	)
	alternative.free()


func _test_similar_idea_extraction() -> void:
	var card := {
		"character_id": "character-original",
		"character": {
			"name": "Mika Original",
			"description": "A red-haired university student who works at the exact Blue Café.",
			"personality": "Warm but guarded.",
			"scenario": "An established couple faces a secret reconnection with an ex and a delayed confession.",
			"first_message": "Exact opening dialogue that must not be copied.",
			"tags": ["relationship", "secrecy"]
		}
	}
	var snapshot := JSON.stringify(card)
	var source := SIMILAR_SERVICE.extract_source(card, {}, "balanced")
	var context := SIMILAR_SERVICE.analysis_prompt(source, "balanced")
	_require(
		context.contains("CARD-TO-IDEA-SOURCE EXTRACTION")
		and context.contains("relationship structure")
		and context.contains("reveal mechanism")
		and context.contains("Elements not to copy"),
		"18. A finished card must produce structured reusable-engine generator context."
	)
	_require(
		not str(source.get("core_premise", "")).contains("Mika Original")
		and not str(source.get("core_premise", "")).contains("Blue Café"),
		"18b. The reusable premise must discard source-card names and surface locations."
	)
	_require(
		JSON.stringify(card) == snapshot,
		"19. Similar-Idea extraction must never mutate the source card."
	)
	var edited := source.duplicate(true)
	edited["core_premise"] = "An edited reusable engine."
	_require(
		str(edited.get("core_premise", "")) != str(source.get("core_premise", "")),
		"20. Extracted sources must be editable independently before generation."
	)
	var service := SOURCE_SERVICE.new(_root_dir.path_join("extracted"))
	var saved := service.save_source(edited)
	var exported := service.export_to_file(
		_root_dir.path_join("extracted-source.ccfideasource.json"), edited
	)
	_require(
		bool(saved.get("ok", false)) and bool(exported.get("ok", false)),
		"21. An extracted source must be saveable and exportable for reuse."
	)
	var close_prompt := service.generation_context(source, "close")
	var balanced_prompt := service.generation_context(source, "balanced")
	var loose_prompt := service.generation_context(source, "loose")
	_require(
		close_prompt.contains("SIMILARITY — CLOSE")
		and balanced_prompt.contains("SIMILARITY — BALANCED")
		and loose_prompt.contains("SIMILARITY — LOOSE")
		and close_prompt != loose_prompt,
		"22. Close, Balanced and Loose must produce materially different instructions."
	)


func _test_live_ui_and_active_source() -> void:
	var window := IDEA_WINDOW.new()
	window.set(
		"_idea_source_service_v0213",
		SOURCE_SERVICE.new(_root_dir.path_join("live-ui"))
	)
	root.add_child(window)
	await process_frame
	await process_frame
	var source_tab := window.find_child("Idea Sources", true, false)
	_require(
		source_tab != null
		and window.find_child("ImportIdeaPackV0210", true, false) != null
		and window.find_child("ExportIdeaPackV0210", true, false) != null,
		"Idea Source Library must be a separate UI while existing Idea Pack actions remain available."
	)
	var source := _sample_source("")
	window.load_temporary_source_v0213(source, false, true)
	var first_context := window.active_idea_source_context_v0213()
	var second_context := window.active_idea_source_context_v0213()
	_require(
		first_context == second_context
		and first_context.contains("source-pregnancy-series") == false
		and first_context.contains("Keep {{user}} agency open")
		and not str(window.active_idea_source_v0213().get("title", "")).is_empty(),
		"15. The same active structured source must remain unchanged across batched request preparation, with optional naming non-blocking."
	)
	var capabilities := window.idea_source_capabilities_v0213()
	_require(
		bool(capabilities.get("source_library_ui", false))
		and bool(capabilities.get("idea_pack_actions_preserved", false))
		and str(capabilities.get("active_source_id", "")) == "source-pregnancy-series",
		"The live Idea Generator must expose the separate source pipeline and active source identity."
	)
	window.queue_free()
	await process_frame


func _has_issue(result: Dictionary, code: String) -> bool:
	for issue_value in result.get("errors", []):
		if issue_value is Dictionary and str((issue_value as Dictionary).get("code", "")) == code:
			return true
	return false


func _write_text(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(path.get_base_dir())
	)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failed = true
		push_error("Could not write test fixture: %s" % path)
		return
	file.store_string(text)
	file.close()


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


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_failed = true
	push_error(message)
	return false
