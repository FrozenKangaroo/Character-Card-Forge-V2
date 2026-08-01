class_name CCFCharacterBuilderWindowV01414
extends "res://scripts/ui/character_builder_window_v014.gd"

const FOCUSED_SERVICE = preload("res://scripts/services/focused_builder_service_v01414.gd")

var _focused_state: Dictionary = {}
var _focused_controls: Dictionary = {}
var _focused_outputs: Dictionary = {}
var _root_tabs: TabContainer


func _build_interface() -> void:
	super._build_interface()
	var legacy_root: Control = get_child(0) as Control
	remove_child(legacy_root)
	_root_tabs = TabContainer.new()
	_root_tabs.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root_tabs)
	legacy_root.name = "Full Character"
	_root_tabs.add_child(legacy_root)
	for tab_data in FOCUSED_SERVICE.tabs():
		if tab_data is Dictionary:
			_add_focused_tab(tab_data)


func open_for_project(project: Dictionary, settings: Dictionary) -> void:
	super.open_for_project(project, settings)
	var workspace: Dictionary = project.get("workspace", {})
	_focused_state = FOCUSED_SERVICE.normalise_state(workspace.get("focused_builders_v01414", {}))
	_refresh_focused_controls()


func current_state() -> Dictionary:
	_capture_focused_controls()
	var next := super.current_state()
	next["focused_builders_v01414"] = _focused_state.duplicate(true)
	return next


func release_project() -> void:
	super.release_project()
	_focused_state = {}
	_focused_outputs.clear()


func _add_focused_tab(tab_data: Dictionary) -> void:
	var tab_id := str(tab_data.get("id", "focused"))
	var scroll := ScrollContainer.new()
	scroll.name = str(tab_data.get("title", tab_id.capitalize()))
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root_tabs.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 18)
	scroll.add_child(margin)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var heading := Label.new()
	heading.text = "%s Builder" % str(tab_data.get("title", "Focused"))
	heading.add_theme_font_size_override("font_size", 23)
	root.add_child(heading)
	var intro := Label.new()
	intro.text = "V1-complete focused fields with editable choices. Build reviewable guidance, then sync it into the Full Character scratchpad before applying."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.modulate = Color(0.68, 0.71, 0.8)
	root.add_child(intro)

	var columns := GridContainer.new()
	columns.columns = 2
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("h_separation", 12)
	columns.add_theme_constant_override("v_separation", 12)
	root.add_child(columns)
	for group_data in tab_data.get("groups", []):
		if group_data is Dictionary:
			_add_group(columns, tab_id, group_data)

	var output_label := Label.new()
	output_label.text = str(tab_data.get("output_label", "Built Guidance"))
	output_label.add_theme_font_size_override("font_size", 16)
	root.add_child(output_label)
	var output := TextEdit.new()
	output.custom_minimum_size.y = 170
	output.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	root.add_child(output)
	_focused_outputs[tab_id] = output

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)
	var build_button := Button.new()
	build_button.text = "Build %s Guidance" % str(tab_data.get("title", "Focused"))
	build_button.pressed.connect(_build_focused_guidance.bind(tab_id))
	actions.add_child(build_button)
	var sync_button := Button.new()
	sync_button.text = "Sync to Full Character"
	sync_button.tooltip_text = "Copies the focused result into the compatible Full Character fields without applying it to the card yet."
	sync_button.pressed.connect(_sync_focused_to_full.bind(tab_id))
	actions.add_child(sync_button)
	var clear_button := Button.new()
	clear_button.text = "Clear Builder"
	clear_button.pressed.connect(_clear_focused_tab.bind(tab_id))
	actions.add_child(clear_button)


func _add_group(parent: GridContainer, tab_id: String, group_data: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.x = 410
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var title_label := Label.new()
	title_label.text = str(group_data.get("title", "Details"))
	title_label.add_theme_font_size_override("font_size", 18)
	box.add_child(title_label)
	for field_data in group_data.get("fields", []):
		if field_data is Dictionary:
			_add_focused_field(box, tab_id, field_data)


func _add_focused_field(parent: VBoxContainer, tab_id: String, field_data: Dictionary) -> void:
	var field_id := str(field_data.get("id", "field"))
	var key := "%s.%s" % [tab_id, field_id]
	var label := Label.new()
	label.text = str(field_data.get("label", field_id.capitalize()))
	parent.add_child(label)
	var field_type := str(field_data.get("type", "line"))
	var control: Control
	if field_type == "multiline":
		var editor := TextEdit.new()
		editor.custom_minimum_size.y = 95
		editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		editor.text_changed.connect(_on_text_edit_changed.bind(tab_id, field_id, editor))
		control = editor
	elif field_type in ["select", "editable_select"]:
		var selector := OptionButton.new()
		selector.fit_to_longest_item = false
		selector.add_item("Unspecified")
		selector.set_item_metadata(0, "")
		for raw_option in field_data.get("options", []):
			var option := str(raw_option)
			selector.add_item(option)
			selector.set_item_metadata(selector.item_count - 1, option)
		if field_type == "editable_select":
			selector.add_separator()
			selector.add_item("Custom…")
			selector.set_item_metadata(selector.item_count - 1, "__custom__")
		selector.item_selected.connect(_on_selector_changed.bind(tab_id, field_id, selector))
		control = selector
	else:
		var line := LineEdit.new()
		line.placeholder_text = str(field_data.get("placeholder", "Type a custom value…"))
		line.text_changed.connect(_on_line_edit_changed.bind(tab_id, field_id))
		control = line
	parent.add_child(control)
	_focused_controls[key] = {"control": control, "field": field_data.duplicate(true)}


func _refresh_focused_controls() -> void:
	for key in _focused_controls:
		var row: Dictionary = _focused_controls[key]
		var parts := str(key).split(".", false, 1)
		if parts.size() != 2:
			continue
		var value := FOCUSED_SERVICE.field_value(_focused_state, parts[0], parts[1])
		var control: Control = row.get("control") as Control
		if control is LineEdit:
			(control as LineEdit).text = value
		elif control is TextEdit:
			(control as TextEdit).text = value
		elif control is OptionButton:
			var selector := control as OptionButton
			var found := false
			for index in range(selector.item_count):
				if str(selector.get_item_metadata(index)) == value:
					selector.select(index)
					found = true
					break
			if not found:
				selector.select(0)
	for tab_id in _focused_outputs:
		var output: TextEdit = _focused_outputs[tab_id]
		output.text = FOCUSED_SERVICE.build_guidance(_focused_state, tab_id)


func _capture_focused_controls() -> void:
	for key in _focused_controls:
		var row: Dictionary = _focused_controls[key]
		var parts := str(key).split(".", false, 1)
		if parts.size() != 2:
			continue
		var control: Control = row.get("control") as Control
		var value := ""
		if control is LineEdit:
			value = (control as LineEdit).text
		elif control is TextEdit:
			value = (control as TextEdit).text
		elif control is OptionButton:
			value = str((control as OptionButton).get_selected_metadata())
			if value == "__custom__":
				value = ""
		_focused_state = FOCUSED_SERVICE.set_field_value(_focused_state, parts[0], parts[1], value)


func _on_line_edit_changed(value: String, tab_id: String, field_id: String) -> void:
	_focused_state = FOCUSED_SERVICE.set_field_value(_focused_state, tab_id, field_id, value)
	_emit_focused_state()


func _on_text_edit_changed(tab_id: String, field_id: String, editor: TextEdit) -> void:
	_focused_state = FOCUSED_SERVICE.set_field_value(_focused_state, tab_id, field_id, editor.text)
	_emit_focused_state()


func _on_selector_changed(index: int, tab_id: String, field_id: String, selector: OptionButton) -> void:
	var value := str(selector.get_item_metadata(index))
	if value == "__custom__":
		var dialog := AcceptDialog.new()
		dialog.title = "Custom %s" % field_id.replace("_", " ").capitalize()
		var line := LineEdit.new()
		line.placeholder_text = "Type a custom value"
		dialog.add_child(line)
		dialog.confirmed.connect(_apply_custom_value.bind(tab_id, field_id, selector, line, dialog))
		add_child(dialog)
		dialog.popup_centered(Vector2i(520, 140))
		return
	_focused_state = FOCUSED_SERVICE.set_field_value(_focused_state, tab_id, field_id, value)
	_emit_focused_state()


func _apply_custom_value(tab_id: String, field_id: String, selector: OptionButton, line: LineEdit, dialog: AcceptDialog) -> void:
	var value := line.text.strip_edges()
	_focused_state = FOCUSED_SERVICE.set_field_value(_focused_state, tab_id, field_id, value)
	selector.select(0)
	dialog.queue_free()
	_emit_focused_state()


func _build_focused_guidance(tab_id: String) -> void:
	_capture_focused_controls()
	var output: TextEdit = _focused_outputs.get(tab_id) as TextEdit
	if output != null:
		output.text = FOCUSED_SERVICE.build_guidance(_focused_state, tab_id)
	_status.text = "%s guidance built. Review it, then sync it to Full Character." % tab_id.capitalize()
	_emit_focused_state()


func _sync_focused_to_full(tab_id: String) -> void:
	_capture_focused_controls()
	var output: TextEdit = _focused_outputs.get(tab_id) as TextEdit
	if output != null and not output.text.strip_edges().is_empty():
		var tab_state: Dictionary = _focused_state.get(tab_id, {}).duplicate(true)
		tab_state["built_guidance"] = output.text
		_focused_state[tab_id] = tab_state
	_state = FOCUSED_SERVICE.sync_into_full_builder(_state, _focused_state, tab_id)
	_render_step()
	_update_completion()
	builder_state_changed.emit(current_state())
	_status.text = "%s guidance synced into Full Character. Review before applying." % tab_id.capitalize()


func _clear_focused_tab(tab_id: String) -> void:
	_focused_state = FOCUSED_SERVICE.clear_tab(_focused_state, tab_id)
	_refresh_focused_controls()
	_emit_focused_state()
	_status.text = "%s Builder cleared." % tab_id.capitalize()


func _emit_focused_state() -> void:
	var state_with_focused := _state.duplicate(true)
	state_with_focused["focused_builders_v01414"] = _focused_state.duplicate(true)
	builder_state_changed.emit(state_with_focused)
