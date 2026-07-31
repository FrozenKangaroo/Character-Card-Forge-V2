class_name CCFManualGuidedWindowV0148
extends "res://scripts/ui/manual_guided_window_v0147.gd"

var _alternative_editors: Array[TextEdit] = []
var _building_alternatives := false
var _skip_alternative_capture_once := false


func open_for_character(project: Dictionary, template: Dictionary, saved_state: Dictionary = {}) -> void:
	_alternative_editors.clear()
	var incoming_state: Dictionary = saved_state.duplicate(true)
	if not incoming_state.has("alternative_greetings"):
		var existing: Variant = _value_at_path(project, "character.alternate_greetings")
		incoming_state["alternative_greetings"] = _normalise_alternative_greetings(existing)
	super.open_for_character(project, template, incoming_state)


func _render_page() -> void:
	super._render_page()
	var definition: Dictionary = PAGE_DEFINITIONS[_page_index]
	if str(definition.get("id", "")) == "first":
		_add_alternative_greetings_editor()
		_update_preview()
	else:
		_alternative_editors.clear()


func _capture_controls() -> void:
	if _skip_alternative_capture_once:
		_skip_alternative_capture_once = false
	elif not _building_alternatives and not _alternative_editors.is_empty():
		var greetings: Array[String] = []
		for editor in _alternative_editors:
			var clean := editor.text.strip_edges()
			if not clean.is_empty():
				greetings.append(clean)
		_state["alternative_greetings"] = greetings
	super._capture_controls()


func _add_alternative_greetings_editor() -> void:
	_building_alternatives = true
	_alternative_editors.clear()
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var head := HBoxContainer.new()
	box.add_child(head)
	var heading := Label.new()
	heading.text = "Alternative Greetings"
	heading.add_theme_font_size_override("font_size", 17)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(heading)
	var add_button := Button.new()
	add_button.text = "+ Add Alternative Greeting"
	add_button.pressed.connect(_add_alternative_greeting)
	head.add_child(add_button)

	var hint := Label.new()
	hint.text = "Optional additional openings. Each entry is stored separately in the Character Card alternate_greetings array."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.67, 0.72, 0.82)
	box.add_child(hint)

	var greetings := _normalise_alternative_greetings(_state.get("alternative_greetings", []))
	if greetings.is_empty():
		var empty := Label.new()
		empty.text = "No alternative greetings yet."
		empty.modulate = Color(0.62, 0.66, 0.75)
		box.add_child(empty)
	else:
		for index in range(greetings.size()):
			_add_alternative_greeting_row(box, index, greetings[index], greetings.size())
	_building_alternatives = false


func _add_alternative_greeting_row(parent: VBoxContainer, index: int, value: String, total: int) -> void:
	var row_head := HBoxContainer.new()
	parent.add_child(row_head)
	var label := Label.new()
	label.text = "Alternative Greeting %d" % (index + 1)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_head.add_child(label)
	var up := Button.new()
	up.text = "↑"
	up.tooltip_text = "Move this greeting earlier"
	up.disabled = index == 0
	up.pressed.connect(_move_alternative_greeting.bind(index, -1))
	row_head.add_child(up)
	var down := Button.new()
	down.text = "↓"
	down.tooltip_text = "Move this greeting later"
	down.disabled = index >= total - 1
	down.pressed.connect(_move_alternative_greeting.bind(index, 1))
	row_head.add_child(down)
	var remove := Button.new()
	remove.text = "Remove"
	remove.pressed.connect(_remove_alternative_greeting.bind(index))
	row_head.add_child(remove)

	var editor := TextEdit.new()
	editor.text = value
	editor.placeholder_text = "Write an alternative playable opening for {{user}}…"
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	editor.custom_minimum_size.y = 150
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.text_changed.connect(_on_alternative_greeting_changed)
	parent.add_child(editor)
	_alternative_editors.append(editor)


func _on_alternative_greeting_changed() -> void:
	_capture_controls()
	_update_preview()


func _add_alternative_greeting() -> void:
	_capture_controls()
	var greetings := _normalise_alternative_greetings(_state.get("alternative_greetings", []))
	greetings.append("")
	_state["alternative_greetings"] = greetings
	_skip_alternative_capture_once = true
	_render_page()


func _remove_alternative_greeting(index: int) -> void:
	_capture_controls()
	var greetings := _normalise_alternative_greetings(_state.get("alternative_greetings", []))
	if index >= 0 and index < greetings.size():
		greetings.remove_at(index)
	_state["alternative_greetings"] = greetings
	_skip_alternative_capture_once = true
	_render_page()


func _move_alternative_greeting(index: int, offset: int) -> void:
	_capture_controls()
	var greetings := _normalise_alternative_greetings(_state.get("alternative_greetings", []))
	var target := index + offset
	if index < 0 or index >= greetings.size() or target < 0 or target >= greetings.size():
		return
	var value := greetings[index]
	greetings[index] = greetings[target]
	greetings[target] = value
	_state["alternative_greetings"] = greetings
	_skip_alternative_capture_once = true
	_render_page()


func _update_preview() -> void:
	super._update_preview()
	var greetings := _normalise_alternative_greetings(_state.get("alternative_greetings", []))
	if greetings.is_empty():
		return
	var lines: Array[String] = []
	for index in range(greetings.size()):
		var clean := greetings[index].strip_edges()
		if not clean.is_empty():
			lines.append("Alternative Greeting %d:\n%s" % [index + 1, clean])
	if lines.is_empty():
		return
	var block := "## Alternative Greetings\n%s" % "\n\n".join(lines)
	_preview.text = block if _preview.text.strip_edges().is_empty() else "%s\n\n%s" % [_preview.text, block]


func _normalise_alternative_greetings(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	elif value != null and not str(value).strip_edges().is_empty():
		result.append(str(value))
	return result
