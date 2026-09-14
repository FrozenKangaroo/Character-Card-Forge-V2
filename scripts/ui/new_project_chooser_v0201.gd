class_name CCFNewProjectChooserV0201
extends Window

signal method_selected(method_id: String, template_id: String)

var _template_selector: OptionButton


func _ready() -> void:
	title = "Create a New Character Project"
	size = Vector2i(820, 680)
	min_size = Vector2i(680, 540)
	force_native = true
	transient = false
	exclusive = false
	close_requested.connect(hide)

	var margin := MarginContainer.new()
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

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var choices := VBoxContainer.new()
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices.add_theme_constant_override("separation", 8)
	scroll.add_child(choices)
	for method in CCFWorkflowDiscoveryServiceV0201.new_project_methods():
		choices.add_child(_method_button(method))

	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(hide)
	root.add_child(cancel)


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


func _method_button(method: Dictionary) -> Button:
	var button := Button.new()
	var shortcut := str(method.get("shortcut", "")).strip_edges()
	button.text = str(method.get("label", "Start"))
	if not shortcut.is_empty():
		button.text += "    %s" % shortcut
	button.tooltip_text = str(method.get("description", ""))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 58
	button.pressed.connect(_choose_method.bind(str(method.get("id", "manual"))))
	return button


func _choose_method(method_id: String) -> void:
	var template_id := "default"
	if _template_selector.item_count > 0:
		template_id = str(
			_template_selector.get_item_metadata(_template_selector.selected)
		)
	hide()
	method_selected.emit(method_id, template_id)
