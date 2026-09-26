class_name CCFIdeaSourceServiceV0213
extends RefCounted

const FORMAT_ID := "character-card-forge-idea-source"
const SCHEMA_VERSION := 1
const EXTENSION := ".ccfideasource.json"
const DEFAULT_ROOT := "user://character_card_forge/idea_sources"

const STRING_FIELDS := [
	"id", "title", "description", "source_version", "summary",
	"core_premise", "setup", "notes", "raw_prompt"
]
const LIST_FIELDS := [
	"core_variables", "generation_rules", "guardrails", "diversity_axes",
	"cross_links", "tags", "elements_not_to_copy"
]

var _root_dir: String
var _sources_dir: String


func _init(root_dir: String = "") -> void:
	_root_dir = root_dir.strip_edges()
	if _root_dir.is_empty():
		_root_dir = DEFAULT_ROOT
	_sources_dir = _root_dir.path_join("sources")


func blank_source() -> Dictionary:
	return {
		"format": FORMAT_ID,
		"schema_version": SCHEMA_VERSION,
		"id": _new_id(),
		"title": "",
		"description": "",
		"source_version": "",
		"bible": {},
		"summary": "",
		"core_premise": "",
		"setup": "",
		"core_variables": [],
		"generation_rules": [],
		"guardrails": [],
		"diversity_axes": [],
		"cross_links": [],
		"tags": [],
		"notes": "",
		"sections": [],
		"raw_prompt": ""
	}


func parse_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _error("file_unreadable", "Could not open the selected Idea Source.")
	var text := file.get_as_text()
	file.close()
	var result := parse_text(text)
	result["source_path"] = path
	result["external"] = true
	result["saved_in_library"] = false
	return result


func parse_text(text: String) -> Dictionary:
	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		return _error(
			"invalid_json",
			"Invalid JSON: %s (line %d)." % [
				json.get_error_message(), json.get_error_line()
			]
		)
	if not json.data is Dictionary:
		return _error("unsupported_structure", "The Idea Source root must be a JSON object.")
	var raw: Dictionary = json.data
	var errors: Array[Dictionary] = []
	var warnings: Array[Dictionary] = []
	if str(raw.get("format", "")) != FORMAT_ID:
		errors.append(_issue("wrong_format", "format must equal '%s'." % FORMAT_ID))
	var schema_value: Variant = raw.get("schema_version", null)
	if not (schema_value is int or schema_value is float):
		errors.append(_issue("missing_schema_version", "schema_version must be an integer."))
	var schema_version := int(schema_value) if schema_value is int or schema_value is float else 0
	if schema_version < 1:
		errors.append(_issue("unsupported_schema", "schema_version must be 1 or newer."))
	elif schema_version > SCHEMA_VERSION:
		warnings.append(_issue(
			"newer_schema",
			"This source uses schema version %d; this CCF version supports version %d. It can be previewed but not edited or used." % [schema_version, SCHEMA_VERSION]
		))
	if str(raw.get("id", "")).strip_edges().is_empty():
		errors.append(_issue("missing_id", "id is required and must be a stable non-empty string."))
	var source := _normalise_source(raw, true)
	if not _has_generator_content(source):
		errors.append(_issue(
			"missing_source_content",
			"At least one of summary, core_premise, setup, raw_prompt, rules, variables or sections is required."
		))
	var supported := schema_version == SCHEMA_VERSION
	return {
		"ok": errors.is_empty(),
		"load_allowed": errors.is_empty() and supported,
		"read_only": errors.is_empty() and not supported,
		"supported": supported,
		"schema_version": schema_version,
		"source": source,
		"raw": raw.duplicate(true),
		"errors": errors,
		"warnings": warnings,
		"external": false,
		"saved_in_library": false
	}


func save_source(raw_source: Dictionary) -> Dictionary:
	var source := _normalise_source(raw_source, true)
	if str(source.get("id", "")).is_empty():
		source["id"] = _new_id()
	if not _has_generator_content(source):
		return {"ok": false, "error": "Add source content before saving."}
	var now := _now()
	if str(source.get("created_at", "")).is_empty():
		source["created_at"] = now
	source["updated_at"] = now
	source["format"] = FORMAT_ID
	source["schema_version"] = SCHEMA_VERSION
	var path := _source_path(str(source.get("id", "")))
	var result := _write_json_atomic(path, source)
	if not bool(result.get("ok", false)):
		return result
	return {"ok": true, "source": source.duplicate(true), "path": path}


func load_source(source_id: String) -> Dictionary:
	var path := _source_path(source_id.strip_edges())
	var loaded := _read_json(path)
	if not bool(loaded.get("ok", false)):
		return loaded
	var value: Variant = loaded.get("data", {})
	if not value is Dictionary:
		return {"ok": false, "error": "Saved Idea Source is not a JSON object."}
	var parsed := parse_text(JSON.stringify(value))
	if not bool(parsed.get("ok", false)):
		return {"ok": false, "error": _issues_text(parsed.get("errors", []))}
	return {
		"ok": true,
		"source": (parsed.get("source", {}) as Dictionary).duplicate(true),
		"saved_in_library": true,
		"path": path
	}


func list_sources() -> Array[Dictionary]:
	_ensure_directories()
	var result: Array[Dictionary] = []
	for file_name in DirAccess.get_files_at(_sources_dir):
		if not file_name.to_lower().ends_with(".json"):
			continue
		var loaded := _read_json(_sources_dir.path_join(file_name))
		if not bool(loaded.get("ok", false)):
			continue
		var value: Variant = loaded.get("data", {})
		if not value is Dictionary:
			continue
		var parsed := parse_text(JSON.stringify(value))
		if bool(parsed.get("ok", false)) and bool(parsed.get("load_allowed", false)):
			result.append((parsed.get("source", {}) as Dictionary).duplicate(true))
	result.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		return str(first.get("updated_at", "")) > str(second.get("updated_at", ""))
	)
	return result


func rename_source(source_id: String, title: String) -> Dictionary:
	var loaded := load_source(source_id)
	if not bool(loaded.get("ok", false)):
		return loaded
	var source: Dictionary = loaded.get("source", {})
	source["title"] = title.strip_edges()
	return save_source(source)


func duplicate_source(source_id: String) -> Dictionary:
	var loaded := load_source(source_id)
	if not bool(loaded.get("ok", false)):
		return loaded
	var source: Dictionary = (loaded.get("source", {}) as Dictionary).duplicate(true)
	source["id"] = _new_id()
	source.erase("created_at")
	source.erase("updated_at")
	var title := str(source.get("title", "")).strip_edges()
	source["title"] = "%s Copy" % title if not title.is_empty() else "Untitled Source Copy"
	return save_source(source)


func delete_source(source_id: String) -> Dictionary:
	var path := _source_path(source_id.strip_edges())
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "Idea Source was not found."}
	var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if error != OK:
		return {"ok": false, "error": "Could not delete Idea Source (error %d)." % error}
	return {"ok": true}


func export_to_file(path: String, raw_source: Dictionary) -> Dictionary:
	var source := _normalise_source(raw_source, true)
	if str(source.get("id", "")).is_empty():
		source["id"] = _new_id()
	if not _has_generator_content(source):
		return {"ok": false, "error": "Add source content before exporting."}
	source["format"] = FORMAT_ID
	source["schema_version"] = SCHEMA_VERSION
	var output_path := path
	if not output_path.to_lower().ends_with(EXTENSION):
		output_path += EXTENSION
	var result := _write_json_atomic(output_path, source)
	if not bool(result.get("ok", false)):
		return result
	return {"ok": true, "path": output_path, "source": source.duplicate(true)}


func generation_context(raw_source: Dictionary, similarity_mode: String = "") -> String:
	var source := _normalise_source(raw_source, true)
	var lines: Array[String] = [
		"IDEA SOURCE — REUSABLE GENERATOR INPUT",
		"Treat this as structured instructions for producing multiple distinct Ideas. It is not itself a finished Idea or Generation Concept."
	]
	_append_label(lines, "Source title", str(source.get("title", "")))
	if str(source.get("title", "")).is_empty():
		lines.append("Source title: [blank — infer a concise reusable concept/Series name if helpful, but naming failure must not block idea generation]")
	_append_label(lines, "Description", str(source.get("description", "")))
	_append_label(lines, "Source version", str(source.get("source_version", "")))
	var bible_value: Variant = source.get("bible", {})
	if bible_value is Dictionary and not (bible_value as Dictionary).is_empty():
		lines.append("Source Bible / Series:")
		for key in (bible_value as Dictionary).keys():
			var value: Variant = (bible_value as Dictionary).get(key)
			if value is Dictionary or value is Array:
				lines.append("- %s: %s" % [str(key).capitalize(), JSON.stringify(value)])
			elif not str(value).strip_edges().is_empty():
				lines.append("- %s: %s" % [str(key).capitalize(), str(value).strip_edges()])
	_append_label(lines, "Summary", str(source.get("summary", "")))
	_append_label(lines, "Core premise / reusable engine", str(source.get("core_premise", "")))
	_append_label(lines, "Setup / framing", str(source.get("setup", "")))
	_append_list(lines, "Core variables", source.get("core_variables", []))
	_append_list(lines, "Generation rules", source.get("generation_rules", []))
	_append_list(lines, "Guardrails", source.get("guardrails", []))
	_append_list(lines, "Suggested diversity axes", source.get("diversity_axes", []))
	_append_list(lines, "Cross-links / related Series", source.get("cross_links", []))
	_append_list(lines, "Elements not to copy", source.get("elements_not_to_copy", []))
	_append_list(lines, "Tags", source.get("tags", []))
	_append_label(lines, "Notes", str(source.get("notes", "")))
	var sections_value: Variant = source.get("sections", [])
	if sections_value is Array:
		for section_value in sections_value:
			if not section_value is Dictionary:
				continue
			var section: Dictionary = section_value
			var label := str(section.get("label", "Custom section")).strip_edges()
			var content := str(section.get("content", "")).strip_edges()
			if not content.is_empty():
				lines.append("Custom section — %s:\n%s" % [label if not label.is_empty() else "Untitled", content])
	_append_label(lines, "Raw / custom prompt", str(source.get("raw_prompt", "")))
	if not similarity_mode.strip_edges().is_empty():
		lines.append(similarity_instruction(similarity_mode))
	lines.append("Generate genuinely distinct Ideas from this source. Preserve its engine and constraints while varying the permitted axes; do not merely rename a single character.")
	return "\n\n".join(lines)


func similarity_instruction(mode: String) -> String:
	match mode.strip_edges().to_lower():
		"close":
			return "SIMILARITY — CLOSE: strongly preserve the scenario engine, but significantly change all characters and surface circumstances."
		"loose":
			return "SIMILARITY — LOOSE: use the reusable engine as broad inspiration and allow meaningful structural reinterpretation while retaining a recognisable conceptual relationship."
		_:
			return "SIMILARITY — BALANCED: preserve the main reusable concept while changing several structural axes, characters and surface circumstances."


func suggested_title_fallback(raw_source: Dictionary) -> String:
	var source := _normalise_source(raw_source, true)
	var existing := str(source.get("title", "")).strip_edges()
	if not existing.is_empty():
		return existing
	for key in ["core_premise", "summary", "setup", "raw_prompt"]:
		var text := str(source.get(key, "")).strip_edges()
		if text.is_empty():
			continue
		var sentence := text.split(".", false)[0].strip_edges()
		var words := sentence.split(" ", false)
		if words.size() > 8:
			words = words.slice(0, 8)
		var candidate := " ".join(words).strip_edges()
		while not candidate.is_empty() and candidate.right(1) in [",", ":", ";", "-", "—"]:
			candidate = candidate.left(candidate.length() - 1).strip_edges()
		if not candidate.is_empty():
			return candidate.capitalize()
	return "Untitled Idea Source"


func capabilities() -> Dictionary:
	return {
		"format": FORMAT_ID,
		"schema_version": SCHEMA_VERSION,
		"extension": EXTENSION,
		"portable": true,
		"unknown_fields_preserved": true,
		"newer_schema_read_only": true,
		"external_load_is_temporary": true,
		"notebook_separate": true,
		"title_optional": true,
		"structured_generation_context": true,
		"similarity_modes": ["close", "balanced", "loose"]
	}


func _normalise_source(raw: Dictionary, preserve_identity: bool) -> Dictionary:
	var result := raw.duplicate(true)
	result["format"] = FORMAT_ID
	result["schema_version"] = int(result.get("schema_version", SCHEMA_VERSION))
	for key in STRING_FIELDS:
		result[key] = str(result.get(key, "")).strip_edges()
	if not preserve_identity:
		result["id"] = _new_id()
	for key in LIST_FIELDS:
		result[key] = _string_list(result.get(key, []))
	var bible_value: Variant = result.get("bible", {})
	result["bible"] = (bible_value as Dictionary).duplicate(true) if bible_value is Dictionary else {}
	var sections: Array[Dictionary] = []
	var sections_value: Variant = result.get("sections", [])
	if sections_value is Array:
		for section_value in sections_value:
			if section_value is Dictionary:
				var section: Dictionary = (section_value as Dictionary).duplicate(true)
				section["label"] = str(section.get("label", "")).strip_edges()
				section["content"] = str(section.get("content", "")).strip_edges()
				sections.append(section)
	result["sections"] = sections
	return result


func _has_generator_content(source: Dictionary) -> bool:
	for key in ["summary", "core_premise", "setup", "raw_prompt"]:
		if not str(source.get(key, "")).strip_edges().is_empty():
			return true
	for key in ["core_variables", "generation_rules", "guardrails", "diversity_axes", "sections"]:
		var value: Variant = source.get(key, [])
		if value is Array and not (value as Array).is_empty():
			return true
	return false


func _append_label(lines: Array[String], label: String, value: String) -> void:
	var clean := value.strip_edges()
	if not clean.is_empty():
		lines.append("%s:\n%s" % [label, clean])


func _append_list(lines: Array[String], label: String, value: Variant) -> void:
	var values := _string_list(value)
	if values.is_empty():
		return
	var formatted: Array[String] = []
	for item in values:
		formatted.append("- %s" % item)
	lines.append("%s:\n%s" % [label, "\n".join(formatted)])


func _string_list(value: Variant) -> Array[String]:
	var raw_values: Array = []
	if value is Array:
		raw_values = value
	elif value is PackedStringArray:
		raw_values = Array(value)
	elif value != null and not str(value).strip_edges().is_empty():
		raw_values = str(value).split("\n", false)
	var result: Array[String] = []
	for raw_value in raw_values:
		var clean := str(raw_value).strip_edges()
		if not clean.is_empty():
			result.append(clean)
	return result


func _source_path(source_id: String) -> String:
	return _sources_dir.path_join("%s.json" % source_id.validate_filename())


func _ensure_directories() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_root_dir))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_sources_dir))


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "File does not exist: %s" % path}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not read %s." % path}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		return {"ok": false, "error": "Invalid JSON in %s." % path}
	return {"ok": true, "data": json.data}


func _write_json_atomic(path: String, data: Dictionary) -> Dictionary:
	_ensure_directories()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var stage_path := "%s.tmp-%d" % [path, Time.get_ticks_usec()]
	var file := FileAccess.open(stage_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not stage %s." % path}
	file.store_string(JSON.stringify(data, "  "))
	file.store_string("\n")
	file.flush()
	file.close()
	var verify := _read_json(stage_path)
	if not bool(verify.get("ok", false)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(stage_path))
		return {"ok": false, "error": "The staged Idea Source failed JSON verification."}
	var target_absolute := ProjectSettings.globalize_path(path)
	var stage_absolute := ProjectSettings.globalize_path(stage_path)
	var backup_path := "%s.backup-%d" % [path, Time.get_ticks_usec()]
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	var had_existing := FileAccess.file_exists(path)
	if had_existing:
		var backup_error := DirAccess.rename_absolute(target_absolute, backup_absolute)
		if backup_error != OK:
			DirAccess.remove_absolute(stage_absolute)
			return {"ok": false, "error": "Could not prepare the existing Idea Source for replacement."}
	var replace_error := DirAccess.rename_absolute(stage_absolute, target_absolute)
	if replace_error != OK:
		if had_existing:
			DirAccess.rename_absolute(backup_absolute, target_absolute)
		DirAccess.remove_absolute(stage_absolute)
		return {"ok": false, "error": "Could not commit the Idea Source."}
	if had_existing and FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_absolute)
	return {"ok": true, "path": path}


func _new_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()


func _now() -> String:
	return Time.get_datetime_string_from_system(true)


func _issue(code: String, message: String) -> Dictionary:
	return {"code": code, "message": message}


func _error(code: String, message: String) -> Dictionary:
	return {
		"ok": false,
		"load_allowed": false,
		"read_only": false,
		"supported": false,
		"schema_version": 0,
		"source": {},
		"raw": {},
		"errors": [_issue(code, message)],
		"warnings": [],
		"external": false,
		"saved_in_library": false
	}


func _issues_text(issues: Variant) -> String:
	var values: Array = issues if issues is Array else []
	var messages: Array[String] = []
	for issue_value in values:
		if issue_value is Dictionary:
			messages.append(str((issue_value as Dictionary).get("message", "Invalid source.")))
	return " ".join(messages)
