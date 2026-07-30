class_name CCFAuthoringOptionService
extends RefCounted

const CATALOG_PATH := "res://data/authoring_option_pools.json"
const FORMAT_VERSION := 1


static func load_catalog() -> Dictionary:
	if not FileAccess.file_exists(CATALOG_PATH):
		return {"format_version": FORMAT_VERSION, "fields": {}}
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return {"format_version": FORMAT_VERSION, "fields": {}}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		return {"format_version": FORMAT_VERSION, "fields": {}}
	return (parser.data as Dictionary).duplicate(true)


static func configured_field_paths() -> Array[String]:
	var result: Array[String] = []
	var fields_value: Variant = load_catalog().get("fields", {})
	if not fields_value is Dictionary:
		return result
	for raw_path in (fields_value as Dictionary).keys():
		var field_path := str(raw_path).strip_edges()
		if not field_path.is_empty():
			result.append(field_path)
	result.sort()
	return result


static func field_config(field_path: String) -> Dictionary:
	var fields_value: Variant = load_catalog().get("fields", {})
	if not fields_value is Dictionary:
		return {}
	var config_value: Variant = (fields_value as Dictionary).get(field_path, {})
	return config_value.duplicate(true) if config_value is Dictionary else {}


static func options_for_field(field_path: String) -> Array[String]:
	var result: Array[String] = []
	var options_value: Variant = field_config(field_path).get("options", [])
	if not options_value is Array:
		return result
	for raw_option in options_value:
		var option := str(raw_option).strip_edges()
		if option.is_empty() or result.has(option):
			continue
		result.append(option)
	return result


static func mode_for_field(field_path: String) -> String:
	var mode := str(field_config(field_path).get("mode", "single")).strip_edges().to_lower()
	return "multi" if mode == "multi" else "single"


static func apply_option(current_value: Variant, field_type: String, option: String) -> Variant:
	var clean_option := option.strip_edges()
	if clean_option.is_empty():
		return current_value
	if field_type == "tags" or mode_for_field_type_value(current_value) == "multi":
		var values := _normalise_values(current_value)
		var option_key := clean_option.to_lower()
		for existing in values:
			if existing.to_lower() == option_key:
				return values
		values.append(clean_option)
		return values
	return clean_option


static func mode_for_field_type_value(value: Variant) -> String:
	return "multi" if value is Array else "single"


static func validate_catalog() -> Array[String]:
	var problems: Array[String] = []
	var catalog := load_catalog()
	if int(catalog.get("format_version", 0)) != FORMAT_VERSION:
		problems.append("Unsupported authoring option catalog format version.")
	var fields_value: Variant = catalog.get("fields", {})
	if not fields_value is Dictionary:
		problems.append("Authoring option catalog fields must be an object.")
		return problems
	for raw_path in (fields_value as Dictionary).keys():
		var field_path := str(raw_path).strip_edges()
		if field_path.is_empty():
			problems.append("Authoring option catalog contains an empty field path.")
			continue
		var config_value: Variant = (fields_value as Dictionary).get(raw_path, {})
		if not config_value is Dictionary:
			problems.append("%s option configuration must be an object." % field_path)
			continue
		var mode := str((config_value as Dictionary).get("mode", "single"))
		if not mode in ["single", "multi"]:
			problems.append("%s has unsupported option mode '%s'." % [field_path, mode])
		if options_for_field(field_path).is_empty():
			problems.append("%s does not contain any usable authoring options." % field_path)
	return problems


static func _normalise_values(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for raw_value in value:
			_append_clean(result, str(raw_value))
	else:
		for raw_value in str(value).split(",", false):
			_append_clean(result, raw_value)
	return result


static func _append_clean(target: Array[String], raw_value: String) -> void:
	var clean := raw_value.strip_edges()
	if clean.is_empty():
		return
	var clean_key := clean.to_lower()
	for existing in target:
		if existing.to_lower() == clean_key:
			return
	target.append(clean)
