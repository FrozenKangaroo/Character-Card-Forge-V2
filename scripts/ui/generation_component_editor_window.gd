class_name CCFGenerationComponentEditorWindow
extends Window

signal groups_applied(groups: Array)

var _template: Dictionary = {}
var _groups: Array = []
var _read_only := false
var _selected_group := -1
var _selected_component := -1
var _loading := false

var _group_list: ItemList
var _component_list: ItemList
var _group_editor: VBoxContainer
var _component_editor: VBoxContainer
var _group_id: LineEdit
var _group_title: LineEdit
var _output_field: OptionButton
var _group_enabled: CheckBox
var _allow_extra: CheckBox
var _component_id: LineEdit
var _component_label: LineEdit
var _component_enabled: CheckBox
var _component_required: CheckBox
var _component_instruction: TextEdit
var _apply_button: Button
var _status: Label


func _ready() -> void:
	close_requested.connect(hide)
	_build_interface()


func open_for_template(template: Dictionary, read_only: bool) -> void:
	_template = template.duplicate(true)
	_read_only = read_only
	var raw_groups: Variant = _template.get("generation_groups", [])
	_groups = raw_groups.duplicate(true) if raw_groups is Array else []
	_selected_group = 0 if not _groups.is_empty() else -1
	_selected_component = 0
	_refresh_group_list()
	_update_read_only_state()
	_status.text = (
		"Built-in template: duplicate it before changing generation structure."
		if _read_only
		else "Enabled components are sent to generation; required components are also checked after generation."
	)
	popup_centered(Vector2i(1160, 760))


func _build_interface() -> void:
	title = "Generation Components"
	min_size = Vector2i(900, 620)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 14)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var intro := Label.new()
	intro.text = "Generation components are structured AI expectations that fold into normal Character Card fields. They do not create extra exported top-level fields."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(intro)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 300
	root.add_child(split)

	var group_column := VBoxContainer.new()
	group_column.custom_minimum_size.x = 270
	group_column.add_theme_constant_override("separation", 8)
	split.add_child(group_column)
	var group_heading := Label.new()
	group_heading.text = "Output groups"
	group_heading.add_theme_font_size_override("font_size", 18)
	group_column.add_child(group_heading)
	_group_list = ItemList.new()
	_group_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_group_list.item_selected.connect(_on_group_selected)
	group_column.add_child(_group_list)
	group_column.add_child(_group_actions())

	var detail_split := HSplitContainer.new()
	detail_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_split.split_offset = 300
	split.add_child(detail_split)

	var component_column := VBoxContainer.new()
	component_column.custom_minimum_size.x = 260
	component_column.add_theme_constant_override("separation", 8)
	detail_split.add_child(component_column)
	var component_heading := Label.new()
	component_heading.text = "Components"
	component_heading.add_theme_font_size_override("font_size", 18)
	component_column.add_child(component_heading)
	_component_list = ItemList.new()
	_component_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_component_list.item_selected.connect(_on_component_selected)
	component_column.add_child(_component_list)
	component_column.add_child(_component_actions())

	var property_scroll := ScrollContainer.new()
	property_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	property_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_split.add_child(property_scroll)
	var property_margin := MarginContainer.new()
	property_margin.add_theme_constant_override("margin_left", 10)
	property_margin.add_theme_constant_override("margin_right", 10)
	property_scroll.add_child(property_margin)
	var properties := VBoxContainer.new()
	properties.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	properties.add_theme_constant_override("separation", 9)
	property_margin.add_child(properties)
	_build_group_editor(properties)
	properties.add_child(HSeparator.new())
	_build_component_editor(properties)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(actions)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(hide)
	actions.add_child(close_button)
	_apply_button = Button.new()
	_apply_button.text = "Apply to Template"
	_apply_button.pressed.connect(_apply)
	actions.add_child(_apply_button)


func _group_actions() -> HBoxContainer:
	var row := HBoxContainer.new()
	for spec in [
		["+ Group", _add_group],
		["↑", _move_group.bind(-1)],
		["↓", _move_group.bind(1)],
		["−", _delete_group]
	]:
		var button := Button.new()
		button.text = str(spec[0])
		button.pressed.connect(spec[1])
		button.set_meta("generation_edit", true)
		row.add_child(button)
	return row


func _component_actions() -> HBoxContainer:
	var row := HBoxContainer.new()
	for spec in [
		["+ Component", _add_component],
		["↑", _move_component.bind(-1)],
		["↓", _move_component.bind(1)],
		["−", _delete_component]
	]:
		var button := Button.new()
		button.text = str(spec[0])
		button.pressed.connect(spec[1])
		button.set_meta("generation_edit", true)
		row.add_child(button)
	return row


func _build_group_editor(parent: VBoxContainer) -> void:
	_group_editor = VBoxContainer.new()
	_group_editor.add_theme_constant_override("separation", 8)
	parent.add_child(_group_editor)
	var heading := Label.new()
	heading.text = "Group properties"
	heading.add_theme_font_size_override("font_size", 18)
	_group_editor.add_child(heading)
	_group_id = _line_field(_group_editor, "Group ID")
	_group_id.text_changed.connect(func(value: String): _update_group("id", value))
	_group_title = _line_field(_group_editor, "Title")
	_group_title.text_changed.connect(func(value: String): _update_group("title", value); _refresh_group_label())
	var output_label := Label.new()
	output_label.text = "Output Character Card field"
	_group_editor.add_child(output_label)
	_output_field = OptionButton.new()
	_output_field.item_selected.connect(_on_output_field_selected)
	_group_editor.add_child(_output_field)
	_group_enabled = CheckBox.new()
	_group_enabled.text = "Enable this generation group"
	_group_enabled.toggled.connect(func(value: bool): _update_group("enabled", value); _refresh_group_label())
	_group_editor.add_child(_group_enabled)
	_allow_extra = CheckBox.new()
	_allow_extra.text = "Allow AI to add extra labelled components"
	_allow_extra.toggled.connect(func(value: bool): _update_group("allow_extra_components", value))
	_group_editor.add_child(_allow_extra)


func _build_component_editor(parent: VBoxContainer) -> void:
	_component_editor = VBoxContainer.new()
	_component_editor.add_theme_constant_override("separation", 8)
	parent.add_child(_component_editor)
	var heading := Label.new()
	heading.text = "Component properties"
	heading.add_theme_font_size_override("font_size", 18)
	_component_editor.add_child(heading)
	_component_id = _line_field(_component_editor, "Component ID")
	_component_id.text_changed.connect(func(value: String): _update_component("id", value))
	_component_label = _line_field(_component_editor, "Output label")
	_component_label.text_changed.connect(func(value: String): _update_component("label", value); _refresh_component_label())
	_component_enabled = CheckBox.new()
	_component_enabled.text = "Enabled — include in generation prompt"
	_component_enabled.toggled.connect(func(value: bool): _update_component("enabled", value); _refresh_component_label())
	_component_editor.add_child(_component_enabled)
	_component_required = CheckBox.new()
	_component_required.text = "Required — missing output triggers completeness repair"
	_component_required.toggled.connect(func(value: bool): _update_component("required", value); _refresh_component_label())
	_component_editor.add_child(_component_required)
	var instruction_label := Label.new()
	instruction_label.text = "AI instruction"
	_component_editor.add_child(instruction_label)
	_component_instruction = TextEdit.new()
	_component_instruction.custom_minimum_size.y = 150
	_component_instruction.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_component_instruction.text_changed.connect(func(): _update_component("instruction", _component_instruction.text))
	_component_editor.add_child(_component_instruction)


func _line_field(parent: VBoxContainer, label_text: String) -> LineEdit:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var edit := LineEdit.new()
	parent.add_child(edit)
	return edit


func _refresh_group_list() -> void:
	_group_list.clear()
	for raw_group in _groups:
		if not raw_group is Dictionary:
			continue
		var label := str(raw_group.get("title", raw_group.get("id", "Group")))
		if not bool(raw_group.get("enabled", true)):
			label += "  [disabled]"
		_group_list.add_item(label)
	if _groups.is_empty():
		_selected_group = -1
	else:
		_selected_group = clampi(_selected_group, 0, _groups.size() - 1)
		_group_list.select(_selected_group)
	_refresh_components()
	_populate_group()


func _refresh_components() -> void:
	_component_list.clear()
	var group := _group_data()
	var components: Array = group.get("components", []) if not group.is_empty() else []
	for raw_component in components:
		if not raw_component is Dictionary:
			continue
		var label := str(raw_component.get("label", raw_component.get("id", "Component")))
		if not bool(raw_component.get("enabled", true)):
			label += "  [disabled]"
		elif bool(raw_component.get("required", true)):
			label += "  *"
		_component_list.add_item(label)
	if components.is_empty():
		_selected_component = -1
	else:
		_selected_component = clampi(_selected_component, 0, components.size() - 1)
		_component_list.select(_selected_component)
	_populate_component()


func _populate_group() -> void:
	var group := _group_data()
	_group_editor.visible = not group.is_empty()
	if group.is_empty():
		return
	_loading = true
	_group_id.text = str(group.get("id", ""))
	_group_title.text = str(group.get("title", ""))
	_populate_output_fields(str(group.get("output_field_id", "")))
	_group_enabled.button_pressed = bool(group.get("enabled", true))
	_allow_extra.button_pressed = bool(group.get("allow_extra_components", false))
	_loading = false


func _populate_component() -> void:
	var component := _component_data()
	_component_editor.visible = not component.is_empty()
	if component.is_empty():
		return
	_loading = true
	_component_id.text = str(component.get("id", ""))
	_component_label.text = str(component.get("label", ""))
	_component_enabled.button_pressed = bool(component.get("enabled", true))
	_component_required.button_pressed = bool(component.get("required", true))
	_component_instruction.text = str(component.get("instruction", ""))
	_loading = false


func _populate_output_fields(selected_id: String) -> void:
	_output_field.clear()
	var selected_index := 0
	var index := 0
	for raw_field in CCFTemplateService.generation_fields(_template):
		if not raw_field is Dictionary:
			continue
		var field_id := str(raw_field.get("id", ""))
		_output_field.add_item("%s — %s" % [str(raw_field.get("label", field_id)), field_id])
		_output_field.set_item_metadata(index, field_id)
		if field_id == selected_id:
			selected_index = index
		index += 1
	if _output_field.item_count > 0:
		_output_field.select(selected_index)


func _on_group_selected(index: int) -> void:
	_selected_group = index
	_selected_component = 0
	_refresh_components()
	_populate_group()
	_update_read_only_state()


func _on_component_selected(index: int) -> void:
	_selected_component = index
	_populate_component()
	_update_read_only_state()


func _on_output_field_selected(_index: int) -> void:
	if _loading or _output_field.selected < 0:
		return
	_update_group("output_field_id", str(_output_field.get_selected_metadata()))


func _add_group() -> void:
	if _read_only:
		return
	var output_id := "description"
	var fields := CCFTemplateService.generation_fields(_template)
	if not fields.is_empty() and fields[0] is Dictionary:
		output_id = str(fields[0].get("id", "description"))
	_groups.append({"id": "generation_group_%d" % (_groups.size() + 1), "title": "New Generation Group", "output_field_id": output_id, "enabled": true, "allow_extra_components": false, "components": []})
	_selected_group = _groups.size() - 1
	_selected_component = -1
	_refresh_group_list()


func _delete_group() -> void:
	if _read_only or _selected_group < 0 or _selected_group >= _groups.size():
		return
	_groups.remove_at(_selected_group)
	_selected_group = mini(_selected_group, _groups.size() - 1)
	_selected_component = 0
	_refresh_group_list()


func _move_group(direction: int) -> void:
	if _read_only or _selected_group < 0:
		return
	var target := _selected_group + direction
	if target < 0 or target >= _groups.size():
		return
	var moving: Variant = _groups[_selected_group]
	_groups[_selected_group] = _groups[target]
	_groups[target] = moving
	_selected_group = target
	_refresh_group_list()


func _add_component() -> void:
	if _read_only or _selected_group < 0:
		return
	var group := _group_data().duplicate(true)
	var components: Array = group.get("components", []).duplicate(true)
	components.append({"id": "component_%d" % (components.size() + 1), "label": "New Component", "enabled": true, "required": true, "instruction": ""})
	group["components"] = components
	_groups[_selected_group] = group
	_selected_component = components.size() - 1
	_refresh_components()


func _delete_component() -> void:
	if _read_only or _selected_group < 0 or _selected_component < 0:
		return
	var group := _group_data().duplicate(true)
	var components: Array = group.get("components", []).duplicate(true)
	if _selected_component >= components.size():
		return
	components.remove_at(_selected_component)
	group["components"] = components
	_groups[_selected_group] = group
	_selected_component = mini(_selected_component, components.size() - 1)
	_refresh_components()


func _move_component(direction: int) -> void:
	if _read_only or _selected_group < 0 or _selected_component < 0:
		return
	var group := _group_data().duplicate(true)
	var components: Array = group.get("components", []).duplicate(true)
	var target := _selected_component + direction
	if target < 0 or target >= components.size():
		return
	var moving: Variant = components[_selected_component]
	components[_selected_component] = components[target]
	components[target] = moving
	group["components"] = components
	_groups[_selected_group] = group
	_selected_component = target
	_refresh_components()


func _update_group(key: String, value: Variant) -> void:
	if _loading or _read_only or _selected_group < 0 or _selected_group >= _groups.size():
		return
	var group: Dictionary = _groups[_selected_group].duplicate(true)
	group[key] = value
	_groups[_selected_group] = group


func _update_component(key: String, value: Variant) -> void:
	if _loading or _read_only or _selected_group < 0 or _selected_component < 0:
		return
	var group := _group_data().duplicate(true)
	var components: Array = group.get("components", []).duplicate(true)
	if _selected_component >= components.size():
		return
	var component: Dictionary = components[_selected_component].duplicate(true)
	component[key] = value
	components[_selected_component] = component
	group["components"] = components
	_groups[_selected_group] = group


func _refresh_group_label() -> void:
	if _selected_group < 0 or _selected_group >= _group_list.item_count:
		return
	var group := _group_data()
	var label := str(group.get("title", group.get("id", "Group")))
	if not bool(group.get("enabled", true)):
		label += "  [disabled]"
	_group_list.set_item_text(_selected_group, label)


func _refresh_component_label() -> void:
	if _selected_component < 0 or _selected_component >= _component_list.item_count:
		return
	var component := _component_data()
	var label := str(component.get("label", component.get("id", "Component")))
	if not bool(component.get("enabled", true)):
		label += "  [disabled]"
	elif bool(component.get("required", true)):
		label += "  *"
	_component_list.set_item_text(_selected_component, label)


func _group_data() -> Dictionary:
	if _selected_group < 0 or _selected_group >= _groups.size():
		return {}
	var value: Variant = _groups[_selected_group]
	return value if value is Dictionary else {}


func _component_data() -> Dictionary:
	var group := _group_data()
	var components: Variant = group.get("components", [])
	if not components is Array or _selected_component < 0 or _selected_component >= components.size():
		return {}
	var value: Variant = components[_selected_component]
	return value if value is Dictionary else {}


func _update_read_only_state() -> void:
	for node in find_children("*", "Button", true, false):
		if node is Button and bool(node.get_meta("generation_edit", false)):
			node.disabled = _read_only
	for control in [_group_id, _group_title, _component_id, _component_label]:
		control.editable = not _read_only
	_component_instruction.editable = not _read_only
	_output_field.disabled = _read_only
	_group_enabled.disabled = _read_only
	_allow_extra.disabled = _read_only
	_component_enabled.disabled = _read_only
	_component_required.disabled = _read_only
	_apply_button.disabled = _read_only


func _apply() -> void:
	if _read_only:
		return
	groups_applied.emit(_groups.duplicate(true))
	_status.text = "Generation structure applied to the template editor. Press Save Template to persist it."
