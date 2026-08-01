class_name CCFIdeaGeneratorOptionServiceV01411
extends RefCounted

const DEFAULT_PATH := "res://data/idea_generator_options.json"
const USER_PATH := "user://character_card_forge/settings/idea_generator_options.json"


static func load_options() -> Dictionary:
	var loaded := _read_json(USER_PATH)
	if loaded.is_empty():
		loaded = _read_json(DEFAULT_PATH)
	return normalise(loaded)


static func default_options() -> Dictionary:
	return normalise(_read_json(DEFAULT_PATH))


static func save_options(options: Dictionary) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(USER_PATH.get_base_dir()))
	var file := FileAccess.open(USER_PATH, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not save Idea Generator options."}
	file.store_string(JSON.stringify(normalise(options), "  "))
	file.close()
	return {"ok": true}


static func reset_all() -> Dictionary:
	var defaults := default_options()
	var result := save_options(defaults)
	result["data"] = defaults
	return result


static func reset_field(options: Dictionary, field_id: String) -> Dictionary:
	var result := normalise(options)
	var defaults := default_options()
	var default_field := field_by_id(defaults, field_id)
	if default_field.is_empty():
		return result
	var fields: Array = result.get("fields", [])
	for index in range(fields.size()):
		if str(fields[index].get("id", "")) == field_id:
			fields[index] = default_field.duplicate(true)
			break
	result["fields"] = fields
	return result


static func field_by_id(options: Dictionary, field_id: String) -> Dictionary:
	for raw_field in options.get("fields", []):
		if raw_field is Dictionary and str(raw_field.get("id", "")) == field_id:
			return raw_field.duplicate(true)
	return {}


static func normalise(raw: Dictionary) -> Dictionary:
	var result := {"format_version": 1, "fields": []}
	var fields: Array = []
	for raw_field in raw.get("fields", []):
		if not raw_field is Dictionary:
			continue
		var field: Dictionary = raw_field
		var field_id := str(field.get("id", "")).strip_edges()
		if field_id.is_empty():
			continue
		var options: Array[String] = []
		for value in field.get("options", []):
			var clean := str(value).strip_edges()
			if not clean.is_empty() and not options.has(clean):
				options.append(clean)
		fields.append({
			"id": field_id,
			"label": str(field.get("label", field_id.capitalize())),
			"multi_select": bool(field.get("multi_select", false)),
			"max_random_choices": maxi(1, int(field.get("max_random_choices", 1))),
			"options": options
		})
	result["fields"] = fields
	return result


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
