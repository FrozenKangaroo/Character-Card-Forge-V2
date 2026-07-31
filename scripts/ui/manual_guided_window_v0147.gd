class_name CCFManualGuidedWindowV0147
extends "res://scripts/ui/manual_guided_window_v0144.gd"

var _component_controls: Dictionary = {}
var _loading_character_context := false


func open_for_character(project: Dictionary, template: Dictionary, saved_state: Dictionary = {}) -> void:
	# Never let controls from the previously opened character write into the next
	# character's draft. The v0.14.4 implementation rendered after swapping state,
	# and render began by capturing the still-live controls from the old character.
	_loading_character_context = true
	_controls.clear()
	_include_controls.clear()
	_component_controls.clear()
	if _content != null:
		for child in _content.get_children():
			child.queue_free()

	_project = project.duplicate(true)
	_template = template.duplicate(true)
	var incoming_project_id := str(_project.get("project_id", ""))
	var incoming_character_id := str(_project.get("character_id", ""))
	var candidate := saved_state.duplicate(true)
	if (
		str(candidate.get("project_id", incoming_project_id)) != incoming_project_id
		or str(candidate.get("character_id", incoming_character_id)) != incoming_character_id
	):
		candidate = {}
	_state = candidate
	_state["project_id"] = incoming_project_id
	_state["character_id"] = incoming_character_id
	_state["template_id"] = str(_template.get("template_id", "default"))
	_page_index = clampi(int(_state.get("page_index", 0)), 0, PAGE_DEFINITIONS.size() - 1)
	_ensure_state_from_project()
	_loading_character_context = false
	_render_page_buttons()
	_render_page()
	popup_centered()


func _ensure_state_from_project() -> void:
	# Rebuild the saved schema from the active template every time Manual Guided is
	# opened. Existing IDs keep their values; removed/disabled components vanish;
	# newly-added components start blank.
	var old_sections: Dictionary = _state.get("sections", {}).duplicate(true)
	var new_sections: Dictionary = {}
	for raw_section in _template.get("sections", []):
		if not raw_section is Dictionary:
			continue
		var section: Dictionary = raw_section
		if not _manual_section_allowed(section):
			continue
		var section_id := str(section.get("id", "section"))
		var old_section: Dictionary = old_sections.get(section_id, {}).duplicate(true)
		var section_state := {
			"include": bool(old_section.get("include", true)),
			"fields": {}
		}
		var old_fields: Dictionary = old_section.get("fields", {})
		for raw_field in section.get("fields", []):
			if not raw_field is Dictionary:
				continue
			var field: Dictionary = raw_field
			if not _manual_field_allowed(section, field):
				continue
			var field_id := str(field.get("id", "field"))
			if old_fields.has(field_id):
				section_state["fields"][field_id] = str(old_fields[field_id])
			else:
				section_state["fields"][field_id] = _display_value(
					_value_at_path(_project, str(field.get("path", "")))
				)
		new_sections[section_id] = section_state
	_state["sections"] = new_sections

	var old_groups: Dictionary = _state.get("component_groups", {}).duplicate(true)
	var new_groups: Dictionary = {}
	for raw_group in _template.get("generation_groups", []):
		if not raw_group is Dictionary:
			continue
		var group: Dictionary = raw_group
		if not bool(group.get("enabled", true)):
			continue
		var group_id := str(group.get("id", "group"))
		var old_group: Dictionary = old_groups.get(group_id, {})
		var old_values: Dictionary = old_group.get("components", {})
		var component_values: Dictionary = {}
		for raw_component in group.get("components", []):
			if not raw_component is Dictionary:
				continue
			var component: Dictionary = raw_component
			if not bool(component.get("enabled", true)):
				continue
			var component_id := str(component.get("id", "component"))
			component_values[component_id] = str(old_values.get(component_id, ""))
		new_groups[group_id] = {
			"include": bool(old_group.get("include", true)),
			"components": component_values
		}
	_state["component_groups"] = new_groups


func _render_page() -> void:
	if not _loading_character_context:
		_capture_controls()
	_controls.clear()
	_include_controls.clear()
	_component_controls.clear()
	for child in _content.get_children():
		child.queue_free()

	var definition: Dictionary = PAGE_DEFINITIONS[_page_index]
	var page_id := str(definition.get("id", ""))
	_page_title.text = "Page %d: %s" % [_page_index + 1, str(definition.get("title", "Manual Guided"))]
	_page_hint.text = str(definition.get("hint", ""))
	_page_progress.text = "Page %d / %d" % [_page_index + 1, PAGE_DEFINITIONS.size()]

	var matched := 0
	for raw_group in _template.get("generation_groups", []):
		if not raw_group is Dictionary:
			continue
		var group: Dictionary = raw_group
		if not bool(group.get("enabled", true)) or _page_for_generation_group(group) != page_id:
			continue
		matched += 1
		_add_component_group(group)

	for raw_section in _template.get("sections", []):
		if not raw_section is Dictionary:
			continue
		var section: Dictionary = raw_section
		if not _manual_section_allowed(section):
			continue
		var fields := _manual_fields_for_page(section, page_id)
		if fields.is_empty():
			continue
		matched += 1
		_add_section(section, fields)

	if matched == 0:
		var empty := Label.new()
		empty.text = "No manual authoring fields from the active template map to this page."
		empty.modulate = Color(0.68, 0.71, 0.79)
		_content.add_child(empty)
	_back_button.disabled = _page_index <= 0
	_next_button.disabled = _page_index >= PAGE_DEFINITIONS.size() - 1
	_next_button.text = "Last Page" if _page_index >= PAGE_DEFINITIONS.size() - 1 else "Next"
	_update_preview()
	_render_page_buttons()


func _add_component_group(group: Dictionary) -> void:
	var group_id := str(group.get("id", "group"))
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(side, 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var head := HBoxContainer.new()
	box.add_child(head)
	var heading := Label.new()
	heading.text = str(group.get("title", group_id.capitalize()))
	heading.add_theme_font_size_override("font_size", 17)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(heading)
	var include := CheckBox.new()
	include.text = "Include"
	include.button_pressed = bool(_component_group_state(group_id).get("include", true))
	include.toggled.connect(func(_pressed: bool): _on_control_changed())
	head.add_child(include)
	_include_controls["component::%s" % group_id] = include

	var target_field := _template_field_by_id(str(group.get("output_field_id", "")))
	if not target_field.is_empty():
		var target_note := Label.new()
		target_note.text = "Composes into %s." % str(target_field.get("label", group.get("output_field_id", "Character field")))
		target_note.modulate = Color(0.66, 0.71, 0.82)
		box.add_child(target_note)

	for raw_component in group.get("components", []):
		if not raw_component is Dictionary:
			continue
		var component: Dictionary = raw_component
		if not bool(component.get("enabled", true)):
			continue
		_add_component_field(box, group_id, component)


func _add_component_field(parent: VBoxContainer, group_id: String, component: Dictionary) -> void:
	var component_id := str(component.get("id", "component"))
	var label := Label.new()
	label.text = "%s%s" % [
		str(component.get("label", component_id.capitalize())),
		" *" if bool(component.get("required", false)) else ""
	]
	parent.add_child(label)
	var instruction := str(component.get("instruction", "")).strip_edges()
	if not instruction.is_empty():
		var help := Label.new()
		help.text = instruction
		help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		help.modulate = Color(0.67, 0.72, 0.82)
		parent.add_child(help)
	var editor := TextEdit.new()
	editor.text = str(_component_group_state(group_id).get("components", {}).get(component_id, ""))
	editor.placeholder_text = "Fill %s manually…" % str(component.get("label", component_id.capitalize()))
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	editor.custom_minimum_size.y = 80
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.text_changed.connect(_on_control_changed)
	parent.add_child(editor)
	_component_controls["%s::%s" % [group_id, component_id]] = editor


func _capture_controls() -> void:
	if _loading_character_context:
		return
	# Capture normal direct fields first, but handle component include controls here
	# because the v0.14.4 base class assumes every include key is a section ID.
	var component_includes: Dictionary = {}
	for key in _include_controls.keys():
		if str(key).begins_with("component::"):
			component_includes[key] = _include_controls[key]
	for key in component_includes:
		_include_controls.erase(key)
	super._capture_controls()
	for key in component_includes:
		_include_controls[key] = component_includes[key]

	var groups_state: Dictionary = _state.get("component_groups", {}).duplicate(true)
	for key in component_includes:
		var group_id := str(key).trim_prefix("component::")
		var group_state: Dictionary = groups_state.get(group_id, {}).duplicate(true)
		group_state["include"] = (component_includes[key] as CheckBox).button_pressed
		group_state["components"] = group_state.get("components", {}).duplicate(true)
		groups_state[group_id] = group_state
	for key in _component_controls:
		var parts := str(key).split("::", false, 1)
		if parts.size() != 2:
			continue
		var group_id := str(parts[0])
		var component_id := str(parts[1])
		var group_state: Dictionary = groups_state.get(group_id, {}).duplicate(true)
		var values: Dictionary = group_state.get("components", {}).duplicate(true)
		values[component_id] = (_component_controls[key] as TextEdit).text
		group_state["components"] = values
		groups_state[group_id] = group_state
	_state["component_groups"] = groups_state
	_state["project_id"] = str(_project.get("project_id", ""))
	_state["character_id"] = str(_project.get("character_id", ""))
	_state["template_id"] = str(_template.get("template_id", "default"))


func _update_preview() -> void:
	_capture_controls()
	var blocks: Array[String] = []
	var component_outputs := _compose_component_outputs()
	for path in component_outputs:
		var label := str(path)
		var field := _template_field_by_path(str(path))
		if not field.is_empty():
			label = str(field.get("label", label))
		blocks.append("## %s\n%s" % [label, str(component_outputs[path])])

	var sections_state: Dictionary = _state.get("sections", {})
	for raw_section in _template.get("sections", []):
		if not raw_section is Dictionary:
			continue
		var section: Dictionary = raw_section
		if not _manual_section_allowed(section):
			continue
		var section_id := str(section.get("id", "section"))
		var section_state: Dictionary = sections_state.get(section_id, {})
		if not bool(section_state.get("include", true)):
			continue
		var lines: Array[String] = []
		for raw_field in section.get("fields", []):
			if not raw_field is Dictionary:
				continue
			var field: Dictionary = raw_field
			if not _manual_field_allowed(section, field) or _field_is_component_output(field):
				continue
			var value := str(section_state.get("fields", {}).get(str(field.get("id", "field")), "")).strip_edges()
			if not value.is_empty():
				lines.append("%s: %s" % [str(field.get("label", field.get("id", "Field"))), value])
		if not lines.is_empty():
			blocks.append("## %s\n%s" % [str(section.get("title", section_id.capitalize())), "\n".join(lines)])
	_preview.text = "\n\n".join(blocks)


func _apply() -> void:
	_capture_controls()
	var values: Dictionary = _compose_component_outputs()
	var sections_state: Dictionary = _state.get("sections", {})
	for raw_section in _template.get("sections", []):
		if not raw_section is Dictionary:
			continue
		var section: Dictionary = raw_section
		if not _manual_section_allowed(section):
			continue
		var section_id := str(section.get("id", "section"))
		var section_state: Dictionary = sections_state.get(section_id, {})
		if not bool(section_state.get("include", true)):
			continue
		for raw_field in section.get("fields", []):
			if not raw_field is Dictionary:
				continue
			var field: Dictionary = raw_field
			if not _manual_field_allowed(section, field) or _field_is_component_output(field):
				continue
			var path := str(field.get("path", "")).strip_edges()
			if path.is_empty():
				continue
			var raw_value := str(section_state.get("fields", {}).get(str(field.get("id", "field")), ""))
			values[path] = _typed_value(field, raw_value)
	apply_requested.emit(values, _state.duplicate(true))
	_status.text = "Manual Guided values applied directly using the active template's component structure."


func _compose_component_outputs() -> Dictionary:
	var groups_by_path: Dictionary = {}
	var groups_state: Dictionary = _state.get("component_groups", {})
	for raw_group in _template.get("generation_groups", []):
		if not raw_group is Dictionary:
			continue
		var group: Dictionary = raw_group
		if not bool(group.get("enabled", true)):
			continue
		var group_id := str(group.get("id", "group"))
		var group_state: Dictionary = groups_state.get(group_id, {})
		if not bool(group_state.get("include", true)):
			continue
		var target := _template_field_by_id(str(group.get("output_field_id", "")))
		var path := str(target.get("path", "")).strip_edges()
		if path.is_empty():
			continue
		var lines: Array[String] = []
		var component_values: Dictionary = group_state.get("components", {})
		for raw_component in group.get("components", []):
			if not raw_component is Dictionary:
				continue
			var component: Dictionary = raw_component
			if not bool(component.get("enabled", true)):
				continue
			var value := str(component_values.get(str(component.get("id", "component")), "")).strip_edges()
			if value.is_empty():
				continue
			lines.append("%s: %s" % [str(component.get("label", component.get("id", "Component"))), value])
		if lines.is_empty():
			continue
		if not groups_by_path.has(path):
			groups_by_path[path] = []
		(groups_by_path[path] as Array).append({"title": str(group.get("title", group_id.capitalize())), "text": "\n".join(lines)})

	var outputs: Dictionary = {}
	for path in groups_by_path:
		var groups: Array = groups_by_path[path]
		var blocks: Array[String] = []
		for row in groups:
			if groups.size() > 1:
				blocks.append("%s:\n%s" % [str(row.get("title", "Section")), str(row.get("text", ""))])
			else:
				blocks.append(str(row.get("text", "")))
		outputs[path] = "\n\n".join(blocks)
	return outputs


func _manual_fields_for_page(section: Dictionary, page_id: String) -> Array:
	var result: Array = []
	for raw_field in section.get("fields", []):
		if not raw_field is Dictionary:
			continue
		var field: Dictionary = raw_field
		if not _manual_field_allowed(section, field) or _field_is_component_output(field):
			continue
		if _page_for_field(section, field) == page_id:
			result.append(field)
	return result


func _manual_section_allowed(section: Dictionary) -> bool:
	return str(section.get("kind", "standard")).to_lower() != "interview"


func _manual_field_allowed(section: Dictionary, field: Dictionary) -> bool:
	if not _manual_section_allowed(section):
		return false
	var path := str(field.get("path", "")).to_lower()
	var field_id := str(field.get("id", "")).to_lower()
	if path.begins_with("concept.") or field_id in ["concept", "generation_concept", "concept_notes"]:
		return false
	if path.begins_with("generation.") or "interview" in path or "interview" in field_id:
		return false
	return true


func _field_is_component_output(field: Dictionary) -> bool:
	var field_id := str(field.get("id", ""))
	for raw_group in _template.get("generation_groups", []):
		if raw_group is Dictionary and bool(raw_group.get("enabled", true)):
			if str(raw_group.get("output_field_id", "")) == field_id:
				return true
	return false


func _page_for_generation_group(group: Dictionary) -> String:
	var target := _template_field_by_id(str(group.get("output_field_id", "")))
	if target.is_empty():
		return "description"
	return _page_for_field({}, target)


func _template_field_by_id(field_id: String) -> Dictionary:
	for raw_section in _template.get("sections", []):
		if not raw_section is Dictionary:
			continue
		for raw_field in raw_section.get("fields", []):
			if raw_field is Dictionary and str(raw_field.get("id", "")) == field_id:
				return raw_field
	return {}


func _template_field_by_path(path: String) -> Dictionary:
	for raw_section in _template.get("sections", []):
		if not raw_section is Dictionary:
			continue
		for raw_field in raw_section.get("fields", []):
			if raw_field is Dictionary and str(raw_field.get("path", "")) == path:
				return raw_field
	return {}


func _component_group_state(group_id: String) -> Dictionary:
	return _state.get("component_groups", {}).get(group_id, {})
