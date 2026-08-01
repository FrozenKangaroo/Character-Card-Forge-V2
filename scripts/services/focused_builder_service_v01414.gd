class_name CCFFocusedBuilderServiceV01414
extends RefCounted

const SCHEMA_PATH := "res://data/focused_builder_schema_v01414.json"

static var _schema: Dictionary = {}


static func schema() -> Dictionary:
	if not _schema.is_empty():
		return _schema.duplicate(true)
	var text := FileAccess.get_file_as_string(SCHEMA_PATH)
	var parsed = JSON.parse_string(text)
	_schema = parsed if parsed is Dictionary else {"format_version": 1, "tabs": []}
	return _schema.duplicate(true)


static func tabs() -> Array:
	var raw = schema().get("tabs", [])
	return raw if raw is Array else []


static func normalise_state(raw_state: Variant) -> Dictionary:
	var state: Dictionary = raw_state.duplicate(true) if raw_state is Dictionary else {}
	for tab in tabs():
		if not tab is Dictionary:
			continue
		var tab_id := str(tab.get("id", ""))
		if tab_id.is_empty():
			continue
		if not state.get(tab_id, {}) is Dictionary:
			state[tab_id] = {}
	return state


static func tab_by_id(tab_id: String) -> Dictionary:
	for tab in tabs():
		if tab is Dictionary and str(tab.get("id", "")) == tab_id:
			return (tab as Dictionary).duplicate(true)
	return {}


static func field_value(state: Dictionary, tab_id: String, field_id: String) -> String:
	var tab_state = state.get(tab_id, {})
	if tab_state is Dictionary:
		return str(tab_state.get(field_id, ""))
	return ""


static func set_field_value(state: Dictionary, tab_id: String, field_id: String, value: String) -> Dictionary:
	var next := normalise_state(state)
	var tab_state: Dictionary = next.get(tab_id, {}).duplicate(true)
	tab_state[field_id] = value
	next[tab_id] = tab_state
	return next


static func clear_tab(state: Dictionary, tab_id: String) -> Dictionary:
	var next := normalise_state(state)
	next[tab_id] = {}
	return next


static func build_guidance(state: Dictionary, tab_id: String) -> String:
	var tab := tab_by_id(tab_id)
	if tab.is_empty():
		return ""
	var sections: Array[String] = []
	for group in tab.get("groups", []):
		if not group is Dictionary:
			continue
		var lines: Array[String] = []
		for field in group.get("fields", []):
			if not field is Dictionary:
				continue
			var value := field_value(state, tab_id, str(field.get("id", ""))).strip_edges()
			if value.is_empty():
				continue
			lines.append("%s: %s" % [str(field.get("label", "Field")), value])
		if not lines.is_empty():
			sections.append("%s\n%s" % [str(group.get("title", "Details")), "\n".join(lines)])
	return "\n\n".join(sections)


static func sync_into_full_builder(full_state: Dictionary, focused_state: Dictionary, tab_id: String) -> Dictionary:
	var next := full_state.duplicate(true)
	var guidance := build_guidance(focused_state, tab_id)
	if guidance.is_empty():
		return next
	match tab_id:
		"appearance":
			CCFStorageService.set_value_at_path(next, "background.appearance", guidance)
		"personality":
			CCFStorageService.set_value_at_path(next, "personality.relationship_style", guidance)
			var traits: Array[String] = []
			for field_id in ["archetype", "social_energy", "confidence", "emotional_style"]:
				var value := field_value(focused_state, tab_id, field_id).strip_edges()
				if not value.is_empty():
					traits.append(value)
			CCFStorageService.set_value_at_path(next, "personality.traits", traits)
			CCFStorageService.set_value_at_path(next, "personality.motivations", field_value(focused_state, tab_id, "main_drive"))
			CCFStorageService.set_value_at_path(next, "personality.fears", field_value(focused_state, tab_id, "hidden_fear"))
		"scene":
			CCFStorageService.set_value_at_path(next, "scene.situation", guidance)
			CCFStorageService.set_value_at_path(next, "scene.location", field_value(focused_state, tab_id, "specific_location"))
			CCFStorageService.set_value_at_path(next, "scene.user_role", field_value(focused_state, "personality", "user_role"))
			CCFStorageService.set_value_at_path(next, "scene.relationship", field_value(focused_state, "personality", "current_dynamic"))
			var tone := field_value(focused_state, tab_id, "emotional_tone").strip_edges()
			CCFStorageService.set_value_at_path(next, "scene.tone", [tone] if not tone.is_empty() else [])
			CCFStorageService.set_value_at_path(next, "scene.opening_direction", field_value(focused_state, tab_id, "about_to_happen"))
	return next
