class_name CCFLibraryProjectCard
extends PanelContainer

signal primary_requested(project_id: String, additive: bool)
signal selection_changed(project_id: String, selected: bool)
signal open_requested(project_id: String)

var _project_id := ""
var _selection_box: CheckBox
var _normal_style: StyleBoxFlat
var _selected_style: StyleBoxFlat


func configure(row: Dictionary, selected: bool) -> void:
	_project_id = str(row.get("project_id", ""))
	custom_minimum_size = Vector2(230, 330)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

	_normal_style = StyleBoxFlat.new()
	_normal_style.bg_color = Color("202231")
	_normal_style.border_color = Color("34374f")
	_normal_style.set_border_width_all(1)
	_normal_style.set_corner_radius_all(10)
	_selected_style = _normal_style.duplicate()
	_selected_style.bg_color = Color("2b2d42")
	_selected_style.border_color = Color("a58cff")
	_selected_style.set_border_width_all(2)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var portrait_panel := PanelContainer.new()
	portrait_panel.custom_minimum_size.y = 180
	portrait_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(portrait_panel)
	var portrait := TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture = _load_texture(str(row.get("thumbnail_path", "")))
	portrait_panel.add_child(portrait)
	if portrait.texture == null:
		var fallback := Label.new()
		fallback.text = _initials(str(row.get("name", "Untitled Project")))
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", 42)
		fallback.modulate = Color(0.68, 0.64, 0.86)
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_panel.add_child(fallback)

	var title_row := HBoxContainer.new()
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title_row)
	_selection_box = CheckBox.new()
	_selection_box.button_pressed = selected
	_selection_box.tooltip_text = "Select this project for bulk actions"
	_selection_box.toggled.connect(_on_checkbox_toggled)
	title_row.add_child(_selection_box)
	var title_label := Label.new()
	title_label.text = str(row.get("name", "Untitled Project"))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(title_label)
	if bool(row.get("favorite", false)):
		var favorite_label := Label.new()
		favorite_label.text = "★"
		favorite_label.tooltip_text = "Favourite project"
		favorite_label.modulate = Color(0.96, 0.82, 0.45)
		favorite_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_row.add_child(favorite_label)

	var count_label := Label.new()
	var character_count := int(row.get("character_count", 0))
	count_label.text = "%d character%s" % [character_count, "" if character_count == 1 else "s"]
	count_label.modulate = Color(0.67, 0.69, 0.78)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(count_label)

	var summary_label := Label.new()
	var summary_text := str(row.get("summary", "")).strip_edges()
	if summary_text.is_empty():
		summary_text = _join_values(row.get("character_names", []), ", ")
	if summary_text.is_empty():
		summary_text = "No summary yet."
	summary_label.text = summary_text.left(170)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.max_lines_visible = 3
	summary_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	summary_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(summary_label)

	var organisation_parts: Array[String] = []
	var series_name := str(row.get("series_name", "")).strip_edges()
	if not series_name.is_empty():
		organisation_parts.append("Series: %s" % series_name)
	var folder_text := str(row.get("folder", "")).strip_edges()
	if not folder_text.is_empty():
		organisation_parts.append("Folder: %s" % folder_text)
	var collections: Array[String] = _string_array(row.get("collections", []))
	if not collections.is_empty():
		organisation_parts.append("Collections: %s" % _join_values(collections, ", "))
	if not organisation_parts.is_empty():
		var organisation_label := Label.new()
		organisation_label.text = _join_values(organisation_parts, " • ")
		organisation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		organisation_label.modulate = Color(0.7, 0.64, 0.86)
		organisation_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(organisation_label)

	_set_selected(selected)


func set_selected(selected: bool) -> void:
	if _selection_box != null:
		_selection_box.set_pressed_no_signal(selected)
	_set_selected(selected)


func project_id() -> String:
	return _project_id


func _on_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event: InputEventMouseButton = event
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	if mouse_event.double_click:
		open_requested.emit(_project_id)
	else:
		primary_requested.emit(_project_id, mouse_event.ctrl_pressed or mouse_event.shift_pressed)
	accept_event()


func _on_checkbox_toggled(selected: bool) -> void:
	_set_selected(selected)
	selection_changed.emit(_project_id, selected)


func _set_selected(selected: bool) -> void:
	add_theme_stylebox_override("panel", _selected_style if selected else _normal_style)


func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) != OK or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _initials(project_name: String) -> String:
	var words := project_name.split(" ", false)
	var output := ""
	for word_index in range(mini(2, words.size())):
		var word_text := str(words[word_index]).strip_edges()
		if not word_text.is_empty():
			output += word_text.left(1).to_upper()
	return output if not output.is_empty() else "CCF"


func _string_array(raw_value: Variant) -> Array[String]:
	var result: Array[String] = []
	if raw_value is Array:
		for item in raw_value:
			var text := str(item).strip_edges()
			if not text.is_empty():
				result.append(text)
	return result


func _join_values(raw_values: Variant, separator: String) -> String:
	var values := _string_array(raw_values)
	var output := ""
	for value_index in range(values.size()):
		if value_index > 0:
			output += separator
		output += values[value_index]
	return output
