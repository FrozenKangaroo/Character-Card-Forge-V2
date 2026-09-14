class_name CCFNewProjectChooserV0201
extends Window

signal method_selected(method_id: String, template_id: String)

var _template_selector: OptionButton
var _method_list: ItemList
var _method_description: Label
var _confirm_button: Button
var _methods: Array[Dictionary] = []


func _ready() -> void:
	title = "Create a New Character Project"
	size = Vector2i(820, 680)
	min_size = Vector2i(680, 540)
	force_native = true
	transient = false
	exclusive = false
	close_requested.connect(hide)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var heading := Label.new()
	heading.text = "How would you like to begin?"
	heading.add_theme_font_size_override("font_size", 24)
	root.add_child(heading)
	var hint := Label.new()
	hint.text = "Every path creates the same editable Character Card Forge project. You can switch tools at any time."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.72, 0.74, 0.82)
	root.add_child(hint)

	var template_row := HBoxContainer.new()
	template_row.add_theme_constant_override("separation", 10)
	root.add_child(template_row)
	var template_label := Label.new()
	template_label.text = "Starting template"
	template_row.add_child(template_label)
	_template_selector = OptionButton.new()
	_template_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	template_row.add_child(_template_selector)

	var method_label := Label.new()
	method_label.text = "Creation method"
	root.add_child(method_label)
	_method_list = ItemList.new()
	_method_list.name = "NewProjectMethodListV0201"
	_method_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_method_list.custom_minimum_size.y = 300
	_method_list.select_mode = ItemList.SELECT_SINGLE
	_method_list.item_selected.connect(_on_method_selected)
	_method_list.item_activated.connect(_on_method_activated)
	root.add_child(_method_list)
	_method_description = Label.new()
	_method_description.name = "NewProjectMethodDescriptionV0201"
	_method_description.custom_minimum_size.y = 48
	_method_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_method_description.modulate = Color(0.72, 0.74, 0.82)
	root.add_child(_method_description)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	root.add_child(actions)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(hide)
	actions.add_child(cancel)
	_confirm_button = Button.new()
	_confirm_button.name = "CreateProjectConfirmV0201"
	_confirm_button.text = "Create Project"
	_confirm_button.custom_minimum_size.x = 180
	_confirm_button.tooltip_text = "Create the project with the selected template and creation method."
	_confirm_button.pressed.connect(_confirm_selection)
	actions.add_child(_confirm_button)
	_populate_methods()


func open_chooser(default_template_id: String) -> void:
	_populate_templates(default_template_id)
	popup_centered()


func _populate_templates(default_template_id: String) -> void:
	_template_selector.clear()
	var selected_index := 0
	var row_index := 0
	for summary in CCFTemplateService.list_templates():
		if not summary is Dictionary:
			continue
		var template_id := str(summary.get("template_id", "default"))
		var template_name := str(summary.get("name", "Template"))
		if bool(summary.get("built_in", false)):
			template_name += " • Built-in"
		_template_selector.add_item(template_name)
		_template_selector.set_item_metadata(row_index, template_id)
		if template_id == default_template_id:
			selected_index = row_index
		row_index += 1
	if _template_selector.item_count > 0:
		_template_selector.select(selected_index)


func _populate_methods() -> void:
	_methods = CCFWorkflowDiscoveryServiceV0201.new_project_methods()
	_method_list.clear()
	for method in _methods:
		var label := str(method.get("label", "Start"))
		var shortcut := str(method.get("shortcut", "")).strip_edges()
		if not shortcut.is_empty():
			label += "    %s" % shortcut
		_method_list.add_item(label)
	if not _methods.is_empty():
		_method_list.select(0)
		_on_method_selected(0)


func _on_method_selected(index: int) -> void:
	if index < 0 or index >= _methods.size():
		_method_description.text = "Choose a creation method to continue."
		_confirm_button.disabled = true
		return
	_method_description.text = str(_methods[index].get("description", ""))
	_confirm_button.disabled = false


func _on_method_activated(index: int) -> void:
	if index < 0 or index >= _methods.size():
		return
	_method_list.select(index)
	_confirm_selection()


func _confirm_selection() -> void:
	var selected := _method_list.get_selected_items()
	if selected.is_empty():
		_method_description.text = "Choose a creation method before creating the project."
		_confirm_button.disabled = true
		return
	var method_index := int(selected[0])
	if method_index < 0 or method_index >= _methods.size():
		return
	var method_id := str(_methods[method_index].get("id", "manual"))
	var template_id := "default"
	if _template_selector.item_count > 0:
		template_id = str(
			_template_selector.get_item_metadata(_template_selector.selected)
		)
	hide()
	method_selected.emit(method_id, template_id)
