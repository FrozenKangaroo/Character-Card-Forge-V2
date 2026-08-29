class_name CCFImageStylePresetServiceV0169
extends RefCounted

const FORMAT_VERSION := 1
const BUILTIN_CATALOG_PATH := "res://data/image_style_presets_v0169.json"
const GLOBAL_STORE_PATH := "user://character_card_forge/settings/image_style_presets_v0169.json"
const PROJECT_KEY := "image_style_preset_v0169"
const CHARACTER_KEY := "image_style_preset_v0169"


static func load_builtin_presets() -> Array[Dictionary]:
	if not FileAccess.file_exists(BUILTIN_CATALOG_PATH):
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BUILTIN_CATALOG_PATH))
	if not parsed is Dictionary:
		return []
	var catalog: Dictionary = parsed
	if int(catalog.get("format_version", 0)) != FORMAT_VERSION:
		return []
	return _normalise_preset_array(catalog.get("presets", []), "builtin")


static func load_global_presets() -> Array[Dictionary]:
	if not FileAccess.file_exists(GLOBAL_STORE_PATH):
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GLOBAL_STORE_PATH))
	if not parsed is Dictionary:
		return []
	var document: Dictionary = parsed
	if int(document.get("format_version", 0)) != FORMAT_VERSION:
		return []
	return _normalise_preset_array(document.get("presets", []), "global")


static func save_global_presets(presets: Array[Dictionary]) -> Dictionary:
	CCFStorageService.ensure_directories()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GLOBAL_STORE_PATH.get_base_dir()))
	var normalised := _normalise_preset_array(presets, "global")
	var file := FileAccess.open(GLOBAL_STORE_PATH, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not open the global Image Style preset store for writing."}
	file.store_string(JSON.stringify({
		"format_version": FORMAT_VERSION,
		"presets": normalised
	}, "  "))
	file.close()
	return {"ok": true, "presets": normalised}


static func make_preset(name_text: String, selection: Dictionary, preset_id: String = "") -> Dictionary:
	var clean_name := name_text.strip_edges()
	if clean_name.is_empty():
		clean_name = "Untitled Style"
	var clean_id := preset_id.strip_edges()
	if clean_id.is_empty():
		clean_id = "style_%s_%d" % [clean_name.to_lower().validate_filename().replace(" ", "_"), Time.get_unix_time_from_system()]
	var now := Time.get_datetime_string_from_system(true)
	return {
		"format_version": FORMAT_VERSION,
		"id": clean_id,
		"name": clean_name,
		"description": "",
		"scope": "global",
		"selection": _normalise_selection(selection),
		"created_at": now,
		"updated_at": now
	}


static func upsert_global_preset(preset: Dictionary) -> Dictionary:
	var normalised := normalise_preset(preset, "global")
	if normalised.is_empty():
		return {"ok": false, "error": "The Image Style preset is invalid."}
	var presets := load_global_presets()
	var found := false
	for index in range(presets.size()):
		if str(presets[index].get("id", "")) == str(normalised.get("id", "")):
			normalised["created_at"] = str(presets[index].get("created_at", normalised.get("created_at", "")))
			normalised["updated_at"] = Time.get_datetime_string_from_system(true)
			presets[index] = normalised
			found = true
			break
	if not found:
		presets.append(normalised)
	return save_global_presets(presets)


static func delete_global_preset(preset_id: String) -> Dictionary:
	var presets := load_global_presets()
	var kept: Array[Dictionary] = []
	for preset in presets:
		if str(preset.get("id", "")) != preset_id:
			kept.append(preset)
	return save_global_presets(kept)


static func project_default(project: Dictionary) -> Dictionary:
	var metadata: Variant = project.get("metadata", {})
	if not metadata is Dictionary:
		return {}
	var raw: Variant = (metadata as Dictionary).get(PROJECT_KEY, {})
	return normalise_preset(raw, "project") if raw is Dictionary else {}


static func set_project_default(project: Dictionary, preset: Dictionary) -> void:
	var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
	metadata[PROJECT_KEY] = normalise_preset(preset, "project")
	project["metadata"] = metadata


static func clear_project_default(project: Dictionary) -> void:
	var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
	metadata.erase(PROJECT_KEY)
	project["metadata"] = metadata


static func character_default(project: Dictionary, character_id: String) -> Dictionary:
	for raw_character in project.get("characters", []):
		if not raw_character is Dictionary:
			continue
		var character: Dictionary = raw_character
		if str(character.get("character_id", "")) != character_id:
			continue
		var generation: Variant = character.get("generation", {})
		if not generation is Dictionary:
			return {}
		var raw: Variant = (generation as Dictionary).get(CHARACTER_KEY, {})
		return normalise_preset(raw, "character") if raw is Dictionary else {}
	return {}


static func set_character_default(project: Dictionary, character_id: String, preset: Dictionary) -> bool:
	var characters: Array = project.get("characters", [])
	for index in range(characters.size()):
		if not characters[index] is Dictionary:
			continue
		var character: Dictionary = characters[index]
		if str(character.get("character_id", "")) != character_id:
			continue
		var generation: Dictionary = character.get("generation", {}).duplicate(true)
		generation[CHARACTER_KEY] = normalise_preset(preset, "character")
		character["generation"] = generation
		characters[index] = character
		project["characters"] = characters
		return true
	return false


static func clear_character_default(project: Dictionary, character_id: String) -> bool:
	var characters: Array = project.get("characters", [])
	for index in range(characters.size()):
		if not characters[index] is Dictionary:
			continue
		var character: Dictionary = characters[index]
		if str(character.get("character_id", "")) != character_id:
			continue
		var generation: Dictionary = character.get("generation", {}).duplicate(true)
		generation.erase(CHARACTER_KEY)
		character["generation"] = generation
		characters[index] = character
		project["characters"] = characters
		return true
	return false


static func effective_default(project: Dictionary, character_id: String) -> Dictionary:
	var character_style := character_default(project, character_id)
	if not character_style.is_empty():
		return character_style
	return project_default(project)


static func normalise_preset(raw: Variant, fallback_scope: String = "global") -> Dictionary:
	if not raw is Dictionary:
		return {}
	var preset: Dictionary = (raw as Dictionary).duplicate(true)
	var preset_id := str(preset.get("id", "")).strip_edges()
	var preset_name := str(preset.get("name", "")).strip_edges()
	if preset_id.is_empty() or preset_name.is_empty():
		return {}
	return {
		"format_version": FORMAT_VERSION,
		"id": preset_id,
		"name": preset_name,
		"description": str(preset.get("description", "")),
		"scope": str(preset.get("scope", fallback_scope)).strip_edges() if not str(preset.get("scope", fallback_scope)).strip_edges().is_empty() else fallback_scope,
		"selection": _normalise_selection(preset.get("selection", {})),
		"created_at": str(preset.get("created_at", "")),
		"updated_at": str(preset.get("updated_at", ""))
	}


static func selection_is_compatible(selection: Dictionary, creative_catalog: Dictionary) -> bool:
	return CCFImagePromptComposerServiceV0162.selection_is_valid(_normalise_selection(selection), creative_catalog)


static func _normalise_preset_array(raw: Variant, fallback_scope: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not raw is Array:
		return result
	var seen: Dictionary = {}
	for entry in raw:
		var preset := normalise_preset(entry, fallback_scope)
		if preset.is_empty():
			continue
		var preset_id := str(preset.get("id", ""))
		if seen.has(preset_id):
			continue
		seen[preset_id] = true
		result.append(preset)
	return result


static func _normalise_selection(raw: Variant) -> Dictionary:
	var selection := {"categories": {}, "modifiers": []}
	if not raw is Dictionary:
		return selection
	var source: Dictionary = raw
	if source.get("categories", {}) is Dictionary:
		for key in (source.get("categories", {}) as Dictionary).keys():
			selection["categories"][str(key)] = str((source.get("categories", {}) as Dictionary).get(key, "none"))
	if source.get("modifiers", []) is Array:
		for modifier in source.get("modifiers", []):
			var clean := str(modifier).strip_edges()
			if not clean.is_empty() and not selection["modifiers"].has(clean):
				selection["modifiers"].append(clean)
	return selection
