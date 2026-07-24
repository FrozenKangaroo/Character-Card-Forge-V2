class_name CCFBuilderService
extends RefCounted

const SCHEMA_PATH := "res://data/builder_schema.json"
const PRESETS_DIR := "res://data/builder_presets"
const BUILDER_FORMAT_VERSION := 1

static func load_schema() -> Dictionary:
	var loaded := _read_json(SCHEMA_PATH)
	if not loaded.get("ok", false):
		return {"format_version": BUILDER_FORMAT_VERSION, "steps": []}
	var schema = loaded.get("data", {})
	if not schema is Dictionary:
		return {"format_version": BUILDER_FORMAT_VERSION, "steps": []}
	return schema.duplicate(true)

static func default_state() -> Dictionary:
	var state := {
		"format_version": BUILDER_FORMAT_VERSION,
		"preset_id": "custom",
		"selected_step": "foundation",
		"updated_at": ""
	}
	for builder_field in all_fields():
		var field_path := str(builder_field.get("path", ""))
		if field_path.is_empty():
			continue
		CCFStorageService.set_value_at_path(
			state,
			field_path,
			_default_value_for_type(str(builder_field.get("type", "line")))
		)
	return state

static func normalise_state(incoming_state: Dictionary) -> Dictionary:
	var state := default_state()
	_deep_merge(state, incoming_state)
	state["format_version"] = BUILDER_FORMAT_VERSION
	if str(state.get("preset_id", "")).is_empty():
		state["preset_id"] = "custom"
	return state

static func list_presets() -> Array:
	var rows: Array = [
		{
			"preset_id": "custom",
			"name": "Custom / Blank",
			"description": "Start with an empty builder and enter only the details you want."
		}
	]
	var absolute_dir := ProjectSettings.globalize_path(PRESETS_DIR)
	if not DirAccess.dir_exists_absolute(absolute_dir):
		return rows
	var files := DirAccess.get_files_at(PRESETS_DIR)
	files.sort()
	for file_name in files:
		if not file_name.to_lower().ends_with(".json"):
			continue
		var loaded := _read_json(PRESETS_DIR + "/" + file_name)
		if not loaded.get("ok", false):
			continue
		var preset = loaded.get("data", {})
		if not preset is Dictionary:
			continue
		rows.append({
			"preset_id": str(preset.get("preset_id", file_name.get_basename())),
			"name": str(preset.get("name", file_name.get_basename().capitalize())),
			"description": str(preset.get("description", ""))
		})
	return rows

static func load_preset(preset_id: String) -> Dictionary:
	if preset_id == "custom" or preset_id.is_empty():
		return {
			"format_version": BUILDER_FORMAT_VERSION,
			"preset_id": "custom",
			"name": "Custom / Blank",
			"description": "",
			"values": {}
		}
	var absolute_dir := ProjectSettings.globalize_path(PRESETS_DIR)
	if not DirAccess.dir_exists_absolute(absolute_dir):
		return {}
	for file_name in DirAccess.get_files_at(PRESETS_DIR):
		if not file_name.to_lower().ends_with(".json"):
			continue
		var loaded := _read_json(PRESETS_DIR + "/" + file_name)
		if not loaded.get("ok", false):
			continue
		var preset = loaded.get("data", {})
		if preset is Dictionary and str(preset.get("preset_id", "")) == preset_id:
			return preset.duplicate(true)
	return {}

static func apply_preset(current_state: Dictionary, preset_id: String) -> Dictionary:
	if preset_id == "custom":
		return default_state()
	var preset := load_preset(preset_id)
	if preset.is_empty():
		return normalise_state(current_state)
	var state := normalise_state(current_state)
	var values = preset.get("values", {})
	if values is Dictionary:
		_deep_merge(state, values)
	state["preset_id"] = preset_id
	state["updated_at"] = Time.get_datetime_string_from_system(true)
	return state

static func clear_step(current_state: Dictionary, step_id: String) -> Dictionary:
	var state := normalise_state(current_state)
	var defaults := default_state()
	for builder_field in fields_for_step(step_id):
		var field_path := str(builder_field.get("path", ""))
		if field_path.is_empty():
			continue
		CCFStorageService.set_value_at_path(
			state,
			field_path,
			CCFStorageService.get_value_at_path(
				defaults,
				field_path,
				_default_value_for_type(str(builder_field.get("type", "line")))
			)
		)
	state["preset_id"] = "custom"
	state["updated_at"] = Time.get_datetime_string_from_system(true)
	return state

static func steps() -> Array:
	var schema := load_schema()
	var schema_steps = schema.get("steps", [])
	return schema_steps.duplicate(true) if schema_steps is Array else []

static func step_by_id(step_id: String) -> Dictionary:
	for builder_step in steps():
		if builder_step is Dictionary and str(builder_step.get("id", "")) == step_id:
			return builder_step.duplicate(true)
	return {}

static func fields_for_step(step_id: String) -> Array:
	var builder_step := step_by_id(step_id)
	var builder_fields = builder_step.get("fields", [])
	return builder_fields.duplicate(true) if builder_fields is Array else []

static func all_fields() -> Array:
	var result: Array = []
	for builder_step in steps():
		if not builder_step is Dictionary:
			continue
		var builder_fields = builder_step.get("fields", [])
		if not builder_fields is Array:
			continue
		for builder_field in builder_fields:
			if builder_field is Dictionary:
				var copy: Dictionary = builder_field.duplicate(true)
				copy["step_id"] = str(builder_step.get("id", ""))
				copy["step_title"] = str(builder_step.get("title", "Step"))
				result.append(copy)
	return result

static func compose_concept(raw_state: Dictionary) -> String:
	var state := normalise_state(raw_state)
	var sections: Array[String] = []

	var foundation_lines: Array[String] = []
	_append_labelled(foundation_lines, "Working name", _text(state, "foundation.working_name"))
	_append_labelled(foundation_lines, "Genre", _text(state, "foundation.genre"))
	_append_labelled(foundation_lines, "Setting", _text(state, "foundation.setting"))
	_append_labelled(foundation_lines, "Role / archetype", _text(state, "foundation.role"))
	_append_labelled(foundation_lines, "Core hook", _text(state, "foundation.core_hook"))
	_append_labelled(foundation_lines, "Goals", _text(state, "foundation.goals"))
	_append_section(sections, "FOUNDATION", foundation_lines)

	var personality_lines: Array[String] = []
	_append_labelled(personality_lines, "Core traits", _value_text(CCFStorageService.get_value_at_path(state, "personality.traits", [])))
	_append_labelled(personality_lines, "Strengths", _value_text(CCFStorageService.get_value_at_path(state, "personality.strengths", [])))
	_append_labelled(personality_lines, "Flaws", _value_text(CCFStorageService.get_value_at_path(state, "personality.flaws", [])))
	_append_labelled(personality_lines, "Motivations", _text(state, "personality.motivations"))
	_append_labelled(personality_lines, "Fears / vulnerabilities", _text(state, "personality.fears"))
	_append_labelled(personality_lines, "Speech style", _text(state, "personality.speech_style"))
	_append_labelled(personality_lines, "Mannerisms", _text(state, "personality.mannerisms"))
	_append_labelled(personality_lines, "Relationship style", _text(state, "personality.relationship_style"))
	_append_section(sections, "PERSONALITY", personality_lines)

	var background_lines: Array[String] = []
	_append_labelled(background_lines, "Appearance", _text(state, "background.appearance"))
	_append_labelled(background_lines, "Backstory", _text(state, "background.backstory"))
	_append_labelled(background_lines, "Skills / capabilities", _value_text(CCFStorageService.get_value_at_path(state, "background.skills", [])))
	_append_labelled(background_lines, "Secrets / hidden complications", _text(state, "background.secrets"))
	_append_labelled(background_lines, "Behavioural boundaries", _text(state, "background.boundaries"))
	_append_section(sections, "BACKGROUND", background_lines)

	var scene_lines: Array[String] = []
	_append_labelled(scene_lines, "Starting location", _text(state, "scene.location"))
	_append_labelled(scene_lines, "Starting situation", _text(state, "scene.situation"))
	_append_labelled(scene_lines, "User role", _text(state, "scene.user_role"))
	_append_labelled(scene_lines, "Initial relationship", _text(state, "scene.relationship"))
	_append_labelled(scene_lines, "Desired tone", _value_text(CCFStorageService.get_value_at_path(state, "scene.tone", [])))
	_append_labelled(scene_lines, "Opening direction", _text(state, "scene.opening_direction"))
	_append_section(sections, "ROLEPLAY SETUP", scene_lines)

	if sections.is_empty():
		return ""
	return "Create a coherent roleplay character from this guided builder brief. Treat unspecified details as open for creative interpretation.\n\n" + _join_strings(sections, "\n\n")

static func compose_personality(raw_state: Dictionary) -> String:
	var state := normalise_state(raw_state)
	var lines: Array[String] = []
	_append_labelled(lines, "Core traits", _value_text(CCFStorageService.get_value_at_path(state, "personality.traits", [])))
	_append_labelled(lines, "Strengths", _value_text(CCFStorageService.get_value_at_path(state, "personality.strengths", [])))
	_append_labelled(lines, "Flaws", _value_text(CCFStorageService.get_value_at_path(state, "personality.flaws", [])))
	_append_labelled(lines, "Motivations", _text(state, "personality.motivations"))
	_append_labelled(lines, "Fears / vulnerabilities", _text(state, "personality.fears"))
	_append_labelled(lines, "Speech style", _text(state, "personality.speech_style"))
	_append_labelled(lines, "Mannerisms", _text(state, "personality.mannerisms"))
	_append_labelled(lines, "Relationship style", _text(state, "personality.relationship_style"))
	return _join_strings(lines, "\n\n")

static func compose_description(raw_state: Dictionary) -> String:
	var state := normalise_state(raw_state)
	var lines: Array[String] = []
	_append_labelled(lines, "Role", _text(state, "foundation.role"))
	_append_labelled(lines, "Appearance", _text(state, "background.appearance"))
	_append_labelled(lines, "Backstory", _text(state, "background.backstory"))
	_append_labelled(lines, "Skills", _value_text(CCFStorageService.get_value_at_path(state, "background.skills", [])))
	_append_labelled(lines, "Secrets", _text(state, "background.secrets"))
	_append_labelled(lines, "Behavioural boundaries", _text(state, "background.boundaries"))
	return _join_strings(lines, "\n\n")

static func compose_scenario(raw_state: Dictionary) -> String:
	var state := normalise_state(raw_state)
	var lines: Array[String] = []
	_append_labelled(lines, "Setting", _text(state, "foundation.setting"))
	_append_labelled(lines, "Starting location", _text(state, "scene.location"))
	_append_labelled(lines, "Starting situation", _text(state, "scene.situation"))
	_append_labelled(lines, "User role", _text(state, "scene.user_role"))
	_append_labelled(lines, "Initial relationship", _text(state, "scene.relationship"))
	_append_labelled(lines, "Tone", _value_text(CCFStorageService.get_value_at_path(state, "scene.tone", [])))
	_append_labelled(lines, "Opening direction", _text(state, "scene.opening_direction"))
	return _join_strings(lines, "\n\n")

static func write_concept_to_project(project: Dictionary, raw_state: Dictionary) -> Array[String]:
	var concept := compose_concept(raw_state)
	if concept.is_empty():
		return []
	var changed_paths: Array[String] = []
	_set_if_changed(project, "concept.prompt", concept, true, changed_paths)
	_set_if_changed(
		project,
		"character.name",
		_text(normalise_state(raw_state), "foundation.working_name"),
		false,
		changed_paths
	)
	return changed_paths

static func apply_to_project(project: Dictionary, raw_state: Dictionary, overwrite_existing: bool) -> Array[String]:
	var state := normalise_state(raw_state)
	var changed_paths: Array[String] = []

	_set_if_changed(project, "character.name", _text(state, "foundation.working_name"), overwrite_existing, changed_paths)
	_set_if_changed(project, "concept.prompt", compose_concept(state), overwrite_existing, changed_paths)
	_set_if_changed(project, "character.description", compose_description(state), overwrite_existing, changed_paths)
	_set_if_changed(project, "character.personality", compose_personality(state), overwrite_existing, changed_paths)
	_set_if_changed(project, "character.scenario", compose_scenario(state), overwrite_existing, changed_paths)

	var existing_tags = CCFStorageService.get_value_at_path(project, "metadata.tags", [])
	var merged_tags: Array[String] = _normalise_tags(existing_tags)
	for tag_value in [
		_text(state, "foundation.genre"),
		_text(state, "foundation.setting"),
		_text(state, "foundation.role")
	]:
		_append_tag_fragments(merged_tags, tag_value)
	for tone_tag in _normalise_tags(CCFStorageService.get_value_at_path(state, "scene.tone", [])):
		if not merged_tags.has(tone_tag):
			merged_tags.append(tone_tag)
	if merged_tags != _normalise_tags(existing_tags):
		CCFStorageService.set_value_at_path(project, "metadata.tags", merged_tags)
		changed_paths.append("metadata.tags")

	return changed_paths

static func known_field_paths() -> Array[String]:
	var paths: Array[String] = []
	for builder_field in all_fields():
		var field_path := str(builder_field.get("path", ""))
		if not field_path.is_empty():
			paths.append(field_path)
	return paths

static func apply_ai_patch(raw_state: Dictionary, patch: Dictionary, allowed_paths: Array[String] = []) -> Dictionary:
	var state := normalise_state(raw_state)
	var allow_all := allowed_paths.is_empty()
	var flattened := _flatten_patch(patch)
	var known_paths := known_field_paths()
	for field_path in flattened:
		if not known_paths.has(field_path):
			continue
		if not allow_all and not allowed_paths.has(field_path):
			continue
		var builder_field := _field_by_path(field_path)
		var value = _normalise_value_for_type(flattened.get(field_path), str(builder_field.get("type", "line")))
		CCFStorageService.set_value_at_path(state, field_path, value)
	state["preset_id"] = "custom"
	state["updated_at"] = Time.get_datetime_string_from_system(true)
	return state

static func completion_percent(raw_state: Dictionary) -> int:
	var state := normalise_state(raw_state)
	var fields := all_fields()
	if fields.is_empty():
		return 0
	var completed := 0
	for builder_field in fields:
		var field_path := str(builder_field.get("path", ""))
		var value = CCFStorageService.get_value_at_path(state, field_path, "")
		if _has_value(value):
			completed += 1
	return int(round(float(completed) / float(fields.size()) * 100.0))

static func _field_by_path(field_path: String) -> Dictionary:
	for builder_field in all_fields():
		if str(builder_field.get("path", "")) == field_path:
			return builder_field
	return {}

static func _set_if_changed(
	project: Dictionary,
	field_path: String,
	proposed_value: Variant,
	overwrite_existing: bool,
	changed_paths: Array[String]
) -> void:
	if not _has_value(proposed_value):
		return
	var current_value = CCFStorageService.get_value_at_path(project, field_path, "")
	var current_has_value := _has_value(current_value)
	if field_path == "character.name" and str(current_value).strip_edges() == "Untitled Character":
		current_has_value = false
	if not overwrite_existing and current_has_value:
		return
	if current_value == proposed_value:
		return
	CCFStorageService.set_value_at_path(project, field_path, proposed_value)
	changed_paths.append(field_path)

static func _append_section(sections: Array[String], heading: String, lines: Array[String]) -> void:
	if lines.is_empty():
		return
	sections.append("%s\n%s" % [heading, _join_strings(lines, "\n")])

static func _append_labelled(lines: Array[String], label_text: String, value_text: String) -> void:
	var clean_value := value_text.strip_edges()
	if clean_value.is_empty():
		return
	lines.append("%s: %s" % [label_text, clean_value])

static func _text(state: Dictionary, field_path: String) -> String:
	return str(CCFStorageService.get_value_at_path(state, field_path, "")).strip_edges()

static func _value_text(value: Variant) -> String:
	if value is Array:
		var parts: Array[String] = []
		for item in value:
			var clean_item := str(item).strip_edges()
			if not clean_item.is_empty():
				parts.append(clean_item)
		return _join_strings(parts, ", ")
	return str(value).strip_edges()

static func _join_strings(values: Array[String], separator: String) -> String:
	var result := ""
	for value_index in range(values.size()):
		if value_index > 0:
			result += separator
		result += values[value_index]
	return result

static func _default_value_for_type(field_type: String) -> Variant:
	if field_type == "tags":
		return []
	return ""

static func _normalise_value_for_type(value: Variant, field_type: String) -> Variant:
	if value == null:
		if field_type == "tags":
			return []
		return ""
	if field_type == "tags":
		return _normalise_tags(value)
	return str(value).strip_edges()

static func _normalise_tags(value: Variant) -> Array[String]:
	var tags: Array[String] = []
	if value is Array:
		for item in value:
			var clean_item := str(item).strip_edges()
			if not clean_item.is_empty() and not tags.has(clean_item):
				tags.append(clean_item)
	else:
		for item in str(value).split(",", false):
			var clean_item := item.strip_edges()
			if not clean_item.is_empty() and not tags.has(clean_item):
				tags.append(clean_item)
	return tags

static func _append_tag_fragments(tags: Array[String], value: String) -> void:
	for fragment in value.split(",", false):
		var clean_fragment := fragment.strip_edges()
		if not clean_fragment.is_empty() and clean_fragment.length() <= 60 and not tags.has(clean_fragment):
			tags.append(clean_fragment)

static func _has_value(value: Variant) -> bool:
	if value is Array:
		return not value.is_empty()
	if value is Dictionary:
		return not value.is_empty()
	return not str(value).strip_edges().is_empty()

static func _deep_merge(target: Dictionary, incoming: Dictionary) -> void:
	for incoming_key in incoming:
		var incoming_value = incoming.get(incoming_key)
		if incoming_value is Dictionary and target.get(incoming_key) is Dictionary:
			var target_child: Dictionary = target[incoming_key]
			_deep_merge(target_child, incoming_value)
			target[incoming_key] = target_child
		else:
			target[incoming_key] = incoming_value.duplicate(true) if incoming_value is Array or incoming_value is Dictionary else incoming_value

static func _flatten_patch(patch: Dictionary, prefix: String = "") -> Dictionary:
	var result := {}
	for patch_key in patch:
		var key_text := str(patch_key)
		var field_path := key_text if prefix.is_empty() else "%s.%s" % [prefix, key_text]
		var patch_value = patch.get(patch_key)
		if patch_value is Dictionary:
			result.merge(_flatten_patch(patch_value, field_path), true)
		else:
			result[field_path] = patch_value
	return result

static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "File does not exist: %s" % path}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not open %s." % path}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		return {"ok": false, "error": "Invalid JSON in %s." % path}
	return {"ok": true, "data": parsed}
