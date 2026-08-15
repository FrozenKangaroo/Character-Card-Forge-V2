class_name CCFIdeaGeneratorDetailLevelServiceV0167
extends RefCounted

const CATALOG_PATH := "res://data/idea_generator_detail_levels_v0167.json"
const SUPPORTED_FORMAT_VERSION := 1
const FALLBACK_LEVEL_ID := "standard"

var _catalog: Dictionary = {}
var _levels: Array[Dictionary] = []
var _levels_by_id: Dictionary = {}
var _default_level_id := FALLBACK_LEVEL_ID


func _init() -> void:
	_load_catalog()


func default_level_id() -> String:
	return _default_level_id


func ordered_levels() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for level: Dictionary in _levels:
		result.append(level.duplicate(true))
	return result


func level_by_id(level_id: String) -> Dictionary:
	var normalised_id := normalise_level_id(level_id)
	var value: Variant = _levels_by_id.get(normalised_id, {})
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


func normalise_level_id(level_id: String) -> String:
	var candidate := level_id.strip_edges().to_lower()
	if _levels_by_id.has(candidate):
		return candidate
	return _default_level_id


func prompt_instruction_for(level_id: String) -> String:
	return str(level_by_id(level_id).get("prompt_instruction", "")).strip_edges()


func output_budget_hint_for(level_id: String) -> float:
	var value: Variant = level_by_id(level_id).get("output_budget_hint", 1.0)
	var parsed := float(value)
	if parsed <= 0.0:
		return 1.0
	return parsed


func description_for(level_id: String) -> String:
	return str(level_by_id(level_id).get("description", "")).strip_edges()


func label_for(level_id: String) -> String:
	return str(level_by_id(level_id).get("label", "Standard")).strip_edges()


func apply_prompt_instruction(base_prompt: String, level_id: String) -> String:
	var instruction := prompt_instruction_for(level_id)
	if instruction.is_empty():
		return base_prompt
	var trimmed_prompt := base_prompt.strip_edges()
	if trimmed_prompt.is_empty():
		return "Idea detail level: %s\n%s" % [label_for(level_id), instruction]
	return "%s\n\nIdea detail level: %s\n%s" % [
		trimmed_prompt,
		label_for(level_id),
		instruction,
	]


func catalog_format_version() -> int:
	return int(_catalog.get("format_version", 0))


func is_valid() -> bool:
	return catalog_format_version() == SUPPORTED_FORMAT_VERSION and not _levels.is_empty()


func _load_catalog() -> void:
	_catalog = {}
	_levels.clear()
	_levels_by_id.clear()
	_default_level_id = FALLBACK_LEVEL_ID

	if not FileAccess.file_exists(CATALOG_PATH):
		_install_builtin_fallback()
		return
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		_install_builtin_fallback()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_install_builtin_fallback()
		return
	var parsed_catalog := parsed as Dictionary
	if int(parsed_catalog.get("format_version", 0)) != SUPPORTED_FORMAT_VERSION:
		_install_builtin_fallback()
		return

	_catalog = parsed_catalog.duplicate(true)
	var raw_levels: Variant = parsed_catalog.get("levels", [])
	if raw_levels is Array:
		for raw_level: Variant in raw_levels:
			if not (raw_level is Dictionary):
				continue
			var level := _normalise_level(raw_level as Dictionary)
			var level_id := str(level.get("id", ""))
			if level_id.is_empty() or _levels_by_id.has(level_id):
				continue
			_levels.append(level)
			_levels_by_id[level_id] = level

	if _levels.is_empty():
		_install_builtin_fallback()
		return

	var requested_default := str(parsed_catalog.get("default_level", FALLBACK_LEVEL_ID)).strip_edges().to_lower()
	if _levels_by_id.has(requested_default):
		_default_level_id = requested_default
	elif _levels_by_id.has(FALLBACK_LEVEL_ID):
		_default_level_id = FALLBACK_LEVEL_ID
	else:
		_default_level_id = str(_levels[0].get("id", FALLBACK_LEVEL_ID))


func _normalise_level(raw_level: Dictionary) -> Dictionary:
	var level := raw_level.duplicate(true)
	level["id"] = str(level.get("id", "")).strip_edges().to_lower()
	level["label"] = str(level.get("label", "")).strip_edges()
	level["description"] = str(level.get("description", "")).strip_edges()
	level["prompt_instruction"] = str(level.get("prompt_instruction", "")).strip_edges()
	var hint := float(level.get("output_budget_hint", 1.0))
	level["output_budget_hint"] = hint if hint > 0.0 else 1.0
	return level


func _install_builtin_fallback() -> void:
	_catalog = {
		"format_version": SUPPORTED_FORMAT_VERSION,
		"default_level": FALLBACK_LEVEL_ID,
	}
	var fallback: Dictionary = {
		"id": FALLBACK_LEVEL_ID,
		"label": "Standard",
		"description": "Balanced detail for normal character ideation.",
		"prompt_instruction": "Provide a balanced and useful character concept with enough detail to continue editing.",
		"output_budget_hint": 1.0,
	}
	_levels = [fallback]
	_levels_by_id = {FALLBACK_LEVEL_ID: fallback}
	_default_level_id = FALLBACK_LEVEL_ID
