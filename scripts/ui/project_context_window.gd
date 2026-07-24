class_name CCFProjectContextWindow
extends Window

signal context_applied(context: Dictionary)

var _project_id := ""
var _fields: Dictionary = {}
var _status: Label


func _ready() -> void:
	visible = false
	title = "Shared Project Context"
	size = Vector2i(980, 760)
	min_size = Vector2i(720, 520)
	force_native = true
	transient = true
	exclusive = false
	close_requested.connect(_hide_window)
	_build_ui()
	hide()


func open_for_project(project: Dictionary) -> void:
	_project_id = str(project.get("project_id", ""))
	_load_context(project.get("shared_context", {}))
	_status.text = "Shared context is available to every character in this project."
	CCFToolWindowStateService.show_window(self, "project_context", Vector2i(980, 760))


func update_project_context(project: Dictionary) -> void:
	if str(project.get("project_id", "")) != _project_id:
		return
	_load_context(project.get("shared_context", {}))


func owns_project(project_id: String) -> bool:
	return not _project_id.is_empty() and _project_id == project_id


func release_project() -> void:
	if visible:
		CCFToolWindowStateService.save_window(self, "project_context")
	hide()
	_project_id = ""


func save_window_state() -> void:
	if visible:
		CCFToolWindowStateService.save_window(self, "project_context")


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var intro := Label.new()
	intro.text = "Define the world, premise, and shared scene once. Individual character generation can use this context without duplicating it into every card."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(intro)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

	_add_line_field(content, "title", "Scene / Context Title", "Optional short label for this shared setup.")
	_add_multiline_field(content, "premise", "Premise", "What brings these characters together?", 120)
	_add_multiline_field(content, "setting", "Setting", "World, location, era, technology, magic, or other shared background.", 150)
	_add_multiline_field(content, "situation", "Current Situation", "What is happening when the roleplay begins?", 150)
	_add_multiline_field(content, "shared_rules", "Shared Rules / Constraints", "Continuity rules, tone, boundaries, group behaviour, or facts every character should respect.", 150)
	_add_multiline_field(content, "notes", "Project Notes", "Private planning notes that are not necessarily intended for exported cards.", 140)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.65, 0.68, 0.78)
	root.add_child(_status)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_hide_window)
	actions.add_child(close_button)

	var apply_button := Button.new()
	apply_button.text = "Apply to Project"
	apply_button.pressed.connect(_apply_context)
	actions.add_child(apply_button)


func _add_line_field(parent: VBoxContainer, field_id: String, label_text: String, hint: String) -> void:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var line_edit := LineEdit.new()
	line_edit.placeholder_text = hint
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(line_edit)
	_fields[field_id] = line_edit


func _add_multiline_field(
	parent: VBoxContainer, field_id: String, label_text: String, hint: String, height: int
) -> void:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var text_edit := TextEdit.new()
	text_edit.placeholder_text = hint
	text_edit.custom_minimum_size.y = height
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(text_edit)
	_fields[field_id] = text_edit


func _load_context(raw_context: Variant) -> void:
	var context: Dictionary = raw_context if raw_context is Dictionary else {}
	for field_id in _fields:
		var control: Control = _fields[field_id]
		var value := str(context.get(field_id, ""))
		if control is LineEdit:
			control.text = value
		elif control is TextEdit:
			control.text = value


func _capture_context() -> Dictionary:
	var context := {
		"title": "",
		"premise": "",
		"setting": "",
		"situation": "",
		"shared_rules": "",
		"notes": ""
	}
	for field_id in _fields:
		var control: Control = _fields[field_id]
		if control is LineEdit:
			context[field_id] = control.text
		elif control is TextEdit:
			context[field_id] = control.text
	return context


func _apply_context() -> void:
	if _project_id.is_empty():
		return
	context_applied.emit(_capture_context())
	_status.text = "Shared project context applied. Save the project when ready."


func _hide_window() -> void:
	CCFToolWindowStateService.save_window(self, "project_context")
	hide()
