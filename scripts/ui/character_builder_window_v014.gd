class_name CCFCharacterBuilderWindowV014
extends CCFCharacterBuilderWindow


func _add_builder_field(builder_field: Dictionary) -> void:
	super._add_builder_field(builder_field)
	var field_path := str(builder_field.get("path", "")).strip_edges()
	if field_path.is_empty():
		return
	var options := CCFAuthoringOptionService.options_for_field(field_path)
	if options.is_empty():
		return
	var control_row_value: Variant = _field_controls.get(field_path, {})
	if not control_row_value is Dictionary:
		return
	var control_value: Variant = (control_row_value as Dictionary).get("control")
	if not control_value is Control:
		return
	var control := control_value as Control
	var field_type := str(builder_field.get("type", "line"))

	var option_row := HBoxContainer.new()
	option_row.add_theme_constant_override("separation", 8)
	_step_content.add_child(option_row)

	var hint := Label.new()
	hint.text = "Try an option"
	hint.tooltip_text = "V1-style Builder suggestions. Selecting one fills or adds to the editable Builder field; you can still type anything you want."
	option_row.add_child(hint)

	var selector := OptionButton.new()
	selector.custom_minimum_size.x = 330
	selector.add_item("Choose from suggestions…")
	selector.set_item_metadata(0, "")
	for option in options:
		var option_index := selector.item_count
		selector.add_item(option)
		selector.set_item_metadata(option_index, option)
	selector.add_separator()
	var custom_index := selector.item_count
	selector.add_item("Custom — keep typing manually")
	selector.set_item_metadata(custom_index, "")
	selector.tooltip_text = (
		"These suggestions come from the shared authoring option catalog. "
		+ "The text field remains fully editable and custom values are always allowed."
	)
	selector.item_selected.connect(
		_on_authoring_option_selected.bind(field_path, field_type, control, selector)
	)
	option_row.add_child(selector)

	var mode_label := Label.new()
	mode_label.text = (
		"adds choices" if CCFAuthoringOptionService.mode_for_field(field_path) == "multi" else "fills field"
	)
	mode_label.modulate = Color(0.58, 0.62, 0.72)
	option_row.add_child(mode_label)


func _on_authoring_option_selected(
	index: int,
	field_path: String,
	field_type: String,
	control: Control,
	selector: OptionButton
) -> void:
	if index < 0 or index >= selector.item_count:
		return
	var option := str(selector.get_item_metadata(index)).strip_edges()
	if option.is_empty():
		selector.select(0)
		return
	var default_value: Variant = ""
	if field_type == "tags":
		default_value = []
	var current_value: Variant = CCFStorageService.get_value_at_path(
		_state,
		field_path,
		default_value
	)
	var next_value: Variant = CCFAuthoringOptionService.apply_option(
		current_value, field_type, option
	)
	if control is LineEdit:
		(control as LineEdit).text = _value_to_text(next_value)
	elif control is TextEdit:
		(control as TextEdit).text = _value_to_text(next_value)
	else:
		selector.select(0)
		return
	_on_builder_control_changed(field_path, field_type, control)
	selector.select(0)
	_status.text = (
		"Added Builder option: %s. Edit the field freely or try another combination." % option
	)
