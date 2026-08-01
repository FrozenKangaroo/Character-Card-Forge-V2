class_name CCFCharSourceServiceV01421
extends RefCounted

const FORMAT_ID := "character_card_forge_character_source"
const FORMAT_VERSION := 1

const SECTION_PATHS := {
	"metadata": ["name", "summary", "tags", "role", "creator", "character_version", "favorite"],
	"concept": ["prompt", "notes"],
	"character": [
		"name", "description", "personality", "scenario", "first_message",
		"example_dialogue", "creator_notes", "system_prompt",
		"post_history_instructions", "alternate_greetings", "card_extensions"
	],
	"generation": ["template_id", "mode", "style"]
}


static func load_file(path: String) -> Dictionary:
	if path.get_extension().to_lower() != "ccfchar":
		return {"ok": false, "error": "Choose a .ccfchar Character Card Forge source file."}
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "The selected .ccfchar file does not exist."}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "The selected .ccfchar file could not be opened."}
	var text := file.get_as_text()
	var parsed := JSON.new()
	var error := parsed.parse(text)
	if error != OK:
		return {"ok": false, "error": "Invalid JSON at line %d: %s" % [parsed.get_error_line(), parsed.get_error_message()]}
	if not parsed.data is Dictionary:
		return {"ok": false, "error": "A .ccfchar document must contain one JSON object."}
	return normalise_source(parsed.data)


static func normalise_source(raw: Dictionary) -> Dictionary:
	var format_id := str(raw.get("format", "")).strip_edges()
	if format_id != FORMAT_ID:
		return {"ok": false, "error": "Unsupported .ccfchar format '%s'. Expected '%s'." % [format_id, FORMAT_ID]}
	var version := int(raw.get("format_version", 0))
	if version < 1 or version > FORMAT_VERSION:
		return {"ok": false, "error": "Unsupported .ccfchar format_version %d." % version}
	var values: Dictionary = {}
	var labels: Dictionary = {}
	for section_name in SECTION_PATHS.keys():
		var section_value: Variant = raw.get(section_name, null)
		if not section_value is Dictionary:
			continue
		var section: Dictionary = section_value
		for field_name in SECTION_PATHS[section_name]:
			if not section.has(field_name):
				continue
			var value: Variant = section.get(field_name)
			if not _valid_field_type(section_name, field_name, value):
				return {"ok": false, "error": "Invalid type for %s.%s." % [section_name, field_name]}
			var path := "%s.%s" % [section_name, field_name]
			values[path] = _copy_value(value)
			labels[path] = _label_for(path)
	var lorebook_value: Variant = raw.get("lorebook", null)
	if lorebook_value is Dictionary:
		values["character.character_book"] = lorebook_value.duplicate(true)
		labels["character.character_book"] = "Character Lorebook"
	elif raw.has("lorebook"):
		return {"ok": false, "error": "lorebook must be a JSON object when supplied."}
	if values.is_empty():
		return {"ok": false, "error": "The .ccfchar file did not contain any recognised workspace fields."}
	return {
		"ok": true,
		"format": FORMAT_ID,
		"format_version": version,
		"values": values,
		"labels": labels,
		"unknown_top_level": _unknown_top_level_keys(raw)
	}


static func apply_values(workspace_document: Dictionary, source: Dictionary, selected_paths: Array[String]) -> Dictionary:
	var values_value: Variant = source.get("values", {})
	if not values_value is Dictionary:
		return {"ok": false, "error": "The parsed .ccfchar source has no values."}
	var values: Dictionary = values_value
	var applied: Array[String] = []
	for path in selected_paths:
		if not values.has(path):
			continue
		CCFStorageService.set_value_at_path(workspace_document, path, _copy_value(values[path]))
		applied.append(path)
	return {"ok": true, "applied": applied, "count": applied.size()}


static func preview_rows(source: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var values_value: Variant = source.get("values", {})
	var labels_value: Variant = source.get("labels", {})
	if not values_value is Dictionary:
		return rows
	var values: Dictionary = values_value
	var labels: Dictionary = labels_value if labels_value is Dictionary else {}
	var paths: Array = values.keys()
	paths.sort()
	for raw_path in paths:
		var path := str(raw_path)
		rows.append({
			"path": path,
			"label": str(labels.get(path, path)),
			"summary": _summary(values[path])
		})
	return rows


static func _valid_field_type(section: String, field: String, value: Variant) -> bool:
	if field == "tags" or field == "alternate_greetings":
		return value is Array
	if field == "favorite":
		return value is bool
	if field == "card_extensions":
		return value is Dictionary
	if section == "generation":
		return value is String
	return value is String


static func _copy_value(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value


static func _unknown_top_level_keys(raw: Dictionary) -> Array[String]:
	var known := ["format", "format_version", "metadata", "concept", "character", "generation", "lorebook"]
	var result: Array[String] = []
	for raw_key in raw.keys():
		var key := str(raw_key)
		if not known.has(key):
			result.append(key)
	return result


static func _label_for(path: String) -> String:
	var labels := {
		"metadata.name": "Metadata name",
		"metadata.summary": "Library summary",
		"metadata.tags": "Tags",
		"metadata.role": "Group role",
		"metadata.creator": "Creator",
		"metadata.character_version": "Character version",
		"metadata.favorite": "Favourite",
		"concept.prompt": "Generation concept",
		"concept.notes": "Private concept notes",
		"character.name": "Character name",
		"character.description": "Description",
		"character.personality": "Personality",
		"character.scenario": "Scenario",
		"character.first_message": "First message",
		"character.example_dialogue": "Example dialogue",
		"character.creator_notes": "Creator notes",
		"character.system_prompt": "System prompt",
		"character.post_history_instructions": "Post-history instructions",
		"character.alternate_greetings": "Alternative greetings",
		"character.card_extensions": "Card extensions",
		"generation.template_id": "Workspace template",
		"generation.mode": "Generation mode",
		"generation.style": "Generation style"
	}
	return str(labels.get(path, path))


static func _summary(value: Variant) -> String:
	if value is Array:
		return "%d item%s" % [value.size(), "" if value.size() == 1 else "s"]
	if value is Dictionary:
		return "%d key%s" % [value.size(), "" if value.size() == 1 else "s"]
	if value is bool:
		return "true" if value else "false"
	var text := str(value).replace("\n", " ").strip_edges()
	return text.left(100) + ("…" if text.length() > 100 else "")
