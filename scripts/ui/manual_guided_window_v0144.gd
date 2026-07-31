class_name CCFManualGuidedWindowV0144
extends Window

signal draft_saved(state: Dictionary)
signal apply_requested(values_by_path: Dictionary, state: Dictionary)

const PAGE_DEFINITIONS := [
	{"id": "description", "title": "Description", "hint": "Identity and visible/description fields from the active template."},
	{"id": "personality", "title": "Personality", "hint": "Personality, behaviour, relationships, backstory, and related template fields."},
	{"id": "scenario", "title": "Scenario", "hint": "Starting situation and immediate roleplay context."},
	{"id": "first", "title": "First Message(s)", "hint": "Main opening plus optional alternative greetings."},
	{"id": "examples", "title": "Example Dialogues", "hint": "Dialogue examples, lorebook/supporting entries, and creator-facing material."},
	{"id": "tags_system", "title": "Tags and System Prompt", "hint": "Tags, system behaviour, and post-history instructions."},
	{"id": "state_image", "title": "State Tracking and Image Prompts", "hint": "State/extension fields and image-prompt-related template content."}
]

var _template: Dictionary = {}
var _project: Dictionary = {}
var _state: Dictionary = {}
var _page_index := 0
var _page_title: Label
var _page_hint: Label
var _page_progress: Label
var _page_buttons: HFlowContainer
var _content: VBoxContainer
var _preview: TextEdit
var _back_button: Button
var _next_button: Button
var _status: Label
var _controls: Dictionary = {}
var _include_controls: Dictionary = {}


func _ready() -> void:
	title = "Manual Guided"
	size = Vector2i(960, 760)
	min_size = Vector2i(720, 560)
	force_native = true
	transient = true
	exclusive = false
	close_requested.connect(_close_and_save)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var head := HBoxContainer.new()
	root.add_child(head)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title_box)
	var heading := Label.new()
	heading.text = "Manual Guided"
	heading.add_theme_font_size_override("font_size", 22)
	title_box.add_child(heading)
	var intro := Label.new()
	intro.text = "Fill the active Character Card template directly. No AI is called and private Interview / Q&A is skipped."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.modulate = Color(0.70, 0.75, 0.84)
	title_box.add_child(intro)
	var apply_top := Button.new()
	apply_top.text = "Apply to Character"
	apply_top.tooltip_text = "Write included Manual Guided fields directly into the active character."
	apply_top.pressed.connect(_apply)
	head.add_child(apply_top)

	var page_head := HBoxContainer.new()
	root.add_child(page_head)
	var page_text := VBoxContainer.new()
	page_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_head.add_child(page_text)
	_page_title = Label.new()
	_page_title.add_theme_font_size_override("font_size", 18)
	page_text.add_child(_page_title)
	_page_hint = Label.new()
	_page_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_page_hint.modulate = Color(0.68, 0.72, 0.82)
	page_text.add_child(_page_hint)
	_page_progress = Label.new()
	page_head.add_child(_page_progress)

	_page_buttons = HFlowContainer.new()
	_page_buttons.add_theme_constant_override("h_separation", 6)
	_page_buttons.add_theme_constant_override("v_separation", 6)
	root.add_child(_page_buttons)

	var split := VSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 430
	root.add_child(split)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_content)

	var preview_box := VBoxContainer.new()
	preview_box.add_theme_constant_override("separation", 6)
	split.add_child(preview_box)
	var preview_title := Label.new()
	preview_title.text = "Manual Output Preview"
	preview_title.add_theme_font_size_override("font_size", 16)
	preview_box.add_child(preview_title)
	_preview = TextEdit.new()
	_preview.editable = false
	_preview.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_box.add_child(_preview)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.72, 0.77, 0.86)
	root.add_child(_status)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)
	_back_button = Button.new()
	_back_button.text = "Back"
	_back_button.pressed.connect(_previous_page)
	actions.add_child(_back_button)
	_next_button = Button.new()
	_next_button.text = "Next"
	_next_button.pressed.connect(_next_page)
	actions.add_child(_next_button)
	var save_button := Button.new()
	save_button.text = "Save Draft"
	save_button.pressed.connect(_save_draft)
	actions.add_child(save_button)
	var apply_button := Button.new()
	apply_button.text = "Apply to Character"
	apply_button.pressed.connect(_apply)
	actions.add_child(apply_button)

	hide()


func open_for_character(project: Dictionary, template: Dictionary, saved_state: Dictionary = {}) -> void:
	_project = project.duplicate(true)
	_template = template.duplicate(true)
	_state = saved_state.duplicate(true)
	_page_index = clampi(int(_state.get("page_index", 0)), 0, PAGE_DEFINITIONS.size() - 1)
	_ensure_state_from_project()
	_render_page_buttons()
	_render_page()
	popup_centered()


func _ensure_state_from_project() -> void:
	var sections_state: Dictionary = _state.get("sections", {}).duplicate(true)
	for raw_section in _template.get("sections", []):
		if not raw_section is Dictionary:
			continue
		var section: Dictionary = raw_section
		var section_id := str(section.get("id", "section"))
		var section_state: Dictionary = sections_state.get(section_id, {}).duplicate(true)
		if not section_state.has("include"):
			section_state["include"] = true
		var fields_state: Dictionary = section_state.get("fields", {}).duplicate(true)
		for raw_field in section.get("fields", []):
			if not raw_field is Dictionary:
				continue
			var field: Dictionary = raw_field
			var field_id := str(field.get("id", "field"))
			if fields_state.has(field_id):
				continue
			fields_state[field_id] = _display_value(_value_at_path(_project, str(field.get("path", ""))))
		section_state["fields"] = fields_state
		sections_state[section_id] = section_state
	_state["sections"] = sections_state


func _render_page_buttons() -> void:
	for child in _page_buttons.get_children():
		child.queue_free()
	for index in range(PAGE_DEFINITIONS.size()):
		var definition: Dictionary = PAGE_DEFINITIONS[index]
		var button := Button.new()
		button.text = "%d. %s" % [index + 1, str(definition.get("title", "Page"))]
		button.toggle_mode = true
		button.button_pressed = index == _page_index
		button.pressed.connect(func(): _go_to_page(index))
		_page_buttons.add_child(button)


func _render_page() -> void:
	_capture_controls()
	_controls.clear()
	_include_controls.clear()
	for child in _content.get_children():
		child.queue_free()
	var definition: Dictionary = PAGE_DEFINITIONS[_page_index]
	_page_title.text = "Page %d: %s" % [_page_index + 1, str(definition.get("title", "Manual Guided"))]
	_page_hint.text = str(definition.get("hint", ""))
	_page_progress.text = "Page %d / %d" % [_page_index + 1, PAGE_DEFINITIONS.size()]
	var matched := 0
	for raw_section in _template.get("sections", []):
		if not raw_section is Dictionary:
			continue
		var section: Dictionary = raw_section
		var fields := _fields_for_page(section, str(definition.get("id", "")))
		if fields.is_empty():
			continue
		matched += 1
		_add_section(section, fields)
	if matched == 0:
		var empty := Label.new()
		empty.text = "No fields from the active template map to this page."
		empty.modulate = Color(0.68, 0.71, 0.79)
		_content.add_child(empty)
	_back_button.disabled = _page_index <= 0
	_next_button.disabled = _page_index >= PAGE_DEFINITIONS.size() - 1
	_next_button.text = "Last Page" if _page_index >= PAGE_DEFINITIONS.size() - 1 else "Next"
	_update_preview()
	_render_page_buttons()


func _add_section(section: Dictionary, fields: Array) -> void:
	var section_id := str(section.get("id", "section"))
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
	box.add_theme_constant_override("separation", 7)
	margin.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	var title_label := Label.new()
	title_label.text = str(section.get("title", section_id.capitalize()))
	title_label.add_theme_font_size_override("font_size", 17)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title_label)
	var include := CheckBox.new()
	include.text = "Include"
	include.button_pressed = bool(_section_state(section_id).get("include", true))
	include.toggled.connect(func(_pressed: bool): _on_control_changed())
	head.add_child(include)
	_include_controls[section_id] = include
	var description := str(section.get("description", "")).strip_edges()
	if not description.is_empty():
		var desc := Label.new()
		desc.text = description
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.modulate = Color(0.68, 0.72, 0.82)
		box.add_child(desc)
	for raw_field in fields:
		if raw_field is Dictionary:
			_add_field(box, section_id, raw_field)


func _add_field(parent: VBoxContainer, section_id: String, field: Dictionary) -> void:
	var field_id := str(field.get("id", "field"))
	var label := Label.new()
	label.text = str(field.get("label", field_id.capitalize()))
	parent.add_child(label)
	var placeholder := str(field.get("placeholder", ""))
	var value := str(_section_state(section_id).get("fields", {}).get(field_id, ""))
	var control: Control
	if str(field.get("type", "multiline")) == "line":
		var line := LineEdit.new()
		line.placeholder_text = placeholder
		line.text = value
		line.text_changed.connect(func(_text: String): _on_control_changed())
		control = line
	else:
		var text := TextEdit.new()
		text.placeholder_text = placeholder
		text.text = value
		text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		text.custom_minimum_size.y = float(maxi(80, int(field.get("height", 120))))
		text.text_changed.connect(_on_control_changed)
		control = text
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(control)
	_controls["%s::%s" % [section_id, field_id]] = {"control": control, "field": field.duplicate(true)}

	if field_id == "alternate_greetings" or field_id == "alternate_first_messages":
		var note := Label.new()
		note.text = "Enter one alternative greeting per paragraph separated by a blank line. The Character Card field remains an array when applied."
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.modulate = Color(0.67, 0.72, 0.82)
		parent.add_child(note)


func _fields_for_page(section: Dictionary, page_id: String) -> Array:
	var result: Array = []
	for raw_field in section.get("fields", []):
		if not raw_field is Dictionary:
			continue
		var field: Dictionary = raw_field
		if _page_for_field(section, field) == page_id:
			result.append(field)
	return result


func _page_for_field(section: Dictionary, field: Dictionary) -> String:
	var sid := str(section.get("id", "")).to_lower()
	var fid := str(field.get("id", "")).to_lower()
	var path := str(field.get("path", "")).to_lower()
	var combined := "%s %s %s" % [sid, fid, path]
	if "first_message" in combined or "alternate_greeting" in combined or "alternate_first" in combined:
		return "first"
	if "scenario" in combined:
		return "scenario"
	if "example" in combined or "character_book" in combined or "lore" in combined or "creator_notes" in combined:
		return "examples"
	if "system_prompt" in combined or "post_history" in combined or fid == "tags" or path.ends_with(".tags"):
		return "tags_system"
	if "state" in combined or "image_prompt" in combined or "stable_diffusion" in combined or "extension" in combined:
		return "state_image"
	if "personality" in combined or "behavior" in combined or "behaviour" in combined or "relationship" in combined or "backstory" in combined:
		return "personality"
	return "description"


func _capture_controls() -> void:
	if _controls.is_empty() and _include_controls.is_empty():
		return
	var sections_state: Dictionary = _state.get("sections", {}).duplicate(true)
	for section_id in _include_controls:
		var state: Dictionary = sections_state.get(section_id, {}).duplicate(true)
		state["include"] = (_include_controls[section_id] as CheckBox).button_pressed
		state["fields"] = state.get("fields", {}).duplicate(true)
		sections_state[section_id] = state
	for key in _controls:
		var parts := str(key).split("::", false, 1)
		if parts.size() != 2:
			continue
		var section_id := parts[0]
		var field_id := parts[1]
		var row: Dictionary = _controls[key]
		var state: Dictionary = sections_state.get(section_id, {}).duplicate(true)
		var fields_state: Dictionary = state.get("fields", {}).duplicate(true)
		var control: Control = row.get("control")
		fields_state[field_id] = control.text if control is LineEdit else (control as TextEdit).text
		state["fields"] = fields_state
		sections_state[section_id] = state
	_state["sections"] = sections_state
	_state["page_index"] = _page_index


func _on_control_changed() -> void:
	_capture_controls()
	_update_preview()


func _update_preview() -> void:
	_capture_controls()
	var blocks: Array[String] = []
	var sections_state: Dictionary = _state.get("sections", {})
	for raw_section in _template.get("sections", []):
		if not raw_section is Dictionary:
			continue
		var section: Dictionary = raw_section
		var section_id := str(section.get("id", "section"))
		var section_state: Dictionary = sections_state.get(section_id, {})
		if not bool(section_state.get("include", true)):
			continue
		var lines: Array[String] = []
		for raw_field in section.get("fields", []):
			if not raw_field is Dictionary:
				continue
			var field: Dictionary = raw_field
			var value := str(section_state.get("fields", {}).get(str(field.get("id", "field")), "")).strip_edges()
			if value.is_empty():
				continue
			lines.append("%s: %s" % [str(field.get("label", field.get("id", "Field"))), value])
		if not lines.is_empty():
			blocks.append("## %s\n%s" % [str(section.get("title", section_id.capitalize())), "\n".join(lines)])
	_preview.text = "\n\n".join(blocks)


func _save_draft() -> void:
	_capture_controls()
	draft_saved.emit(_state.duplicate(true))
	_status.text = "Manual Guided draft saved into this character."


func _apply() -> void:
	_capture_controls()
	var values: Dictionary = {}
	var sections_state: Dictionary = _state.get("sections", {})
	for raw_section in _template.get("sections", []):
		if not raw_section is Dictionary:
			continue
		var section: Dictionary = raw_section
		var section_id := str(section.get("id", "section"))
		var section_state: Dictionary = sections_state.get(section_id, {})
		if not bool(section_state.get("include", true)):
			continue
		for raw_field in section.get("fields", []):
			if not raw_field is Dictionary:
				continue
			var field: Dictionary = raw_field
			var path := str(field.get("path", "")).strip_edges()
			if path.is_empty():
				continue
			var raw_value := str(section_state.get("fields", {}).get(str(field.get("id", "field")), ""))
			values[path] = _typed_value(field, raw_value)
	apply_requested.emit(values, _state.duplicate(true))
	_status.text = "Manual Guided values applied directly to the character."


func _typed_value(field: Dictionary, value: String) -> Variant:
	var field_id := str(field.get("id", "")).to_lower()
	var path := str(field.get("path", "")).to_lower()
	if str(field.get("type", "")) == "tags":
		var tags: Array[String] = []
		for part in value.replace("\n", ",").split(","):
			var clean := str(part).strip_edges()
			if not clean.is_empty() and not tags.has(clean):
				tags.append(clean)
		return tags
	if "alternate_greeting" in field_id or "alternate_greeting" in path or "alternate_first" in field_id:
		var greetings: Array[String] = []
		for paragraph in value.replace("\r\n", "\n").split("\n\n"):
			var clean := str(paragraph).strip_edges()
			if not clean.is_empty():
				greetings.append(clean)
		return greetings
	return value


func _display_value(value: Variant) -> String:
	if value is Array:
		var out: Array[String] = []
		for item in value:
			out.append(str(item))
		return "\n\n".join(out)
	if value == null:
		return ""
	return str(value)


func _section_state(section_id: String) -> Dictionary:
	return _state.get("sections", {}).get(section_id, {})


func _value_at_path(document: Dictionary, path: String) -> Variant:
	if path.strip_edges().is_empty():
		return null
	var current: Variant = document
	for part in path.split("."):
		if not current is Dictionary or not current.has(part):
			return null
		current = current[part]
	return current


func _go_to_page(index: int) -> void:
	_capture_controls()
	_page_index = clampi(index, 0, PAGE_DEFINITIONS.size() - 1)
	_render_page()


func _previous_page() -> void:
	_go_to_page(_page_index - 1)


func _next_page() -> void:
	_go_to_page(_page_index + 1)


func _close_and_save() -> void:
	_save_draft()
	hide()
