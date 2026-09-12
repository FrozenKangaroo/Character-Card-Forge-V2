class_name CCFLibraryProjectCard
extends PanelContainer

signal primary_requested(project_id: String, additive: bool)
signal selection_changed(project_id: String, selected: bool)
signal open_requested(project_id: String)
signal context_requested(project_id: String, screen_position: Vector2)

var _project_id := ""
var _selection_box: CheckBox
var _normal_style: StyleBoxFlat
var _selected_style: StyleBoxFlat


func configure(row: Dictionary, selected: bool, density_level: int = 3) -> void:
	_project_id = str(row.get("project_id", ""))
	var density := clampi(density_level, 0, 3)
	var card_widths := [130.0, 160.0, 195.0, 230.0]
	var card_heights := [170.0, 226.0, 286.0, 330.0]
	var portrait_heights := [146.0, 145.0, 164.0, 180.0]
	custom_minimum_size = Vector2(card_widths[density], card_heights[density])
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
	var card_margin := 7 if density <= 1 else (9 if density == 2 else 12)
	margin.add_theme_constant_override("margin_left", card_margin)
	margin.add_theme_constant_override("margin_right", card_margin)
	margin.add_theme_constant_override("margin_top", card_margin)
	margin.add_theme_constant_override("margin_bottom", card_margin)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5 if density <= 2 else 8)
	margin.add_child(content)

	var portrait_panel := PanelContainer.new()
	portrait_panel.name = "CardPortraitPanel"
	portrait_panel.custom_minimum_size.y = portrait_heights[density]
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
		fallback.text = (
			"Artwork\nblurred"
			if bool(row.get("artwork_blurred", false))
			else _initials(str(row.get("name", "Untitled Project")))
		)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", 42)
		fallback.modulate = Color(0.68, 0.64, 0.86)
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_panel.add_child(fallback)
	if density == 0:
		var overlay_layer := Control.new()
		overlay_layer.name = "CardOverlayLayer"
		overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_panel.add_child(overlay_layer)
		_selection_box = CheckBox.new()
		_selection_box.name = "CardSelectionOverlay"
		_selection_box.button_pressed = selected
		_selection_box.tooltip_text = "Select this project for bulk actions"
		_selection_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_selection_box.position = Vector2(5, 5)
		_selection_box.toggled.connect(_on_checkbox_toggled)
		overlay_layer.add_child(_selection_box)
		var overlay_panel := PanelContainer.new()
		overlay_panel.name = "CardTitleOverlay"
		overlay_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		overlay_panel.offset_top = -38.0
		overlay_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var overlay_style := StyleBoxFlat.new()
		overlay_style.bg_color = Color(0.035, 0.035, 0.055, 0.88)
		overlay_style.content_margin_left = 7.0
		overlay_style.content_margin_right = 7.0
		overlay_style.content_margin_top = 5.0
		overlay_style.content_margin_bottom = 5.0
		overlay_panel.add_theme_stylebox_override("panel", overlay_style)
		overlay_layer.add_child(overlay_panel)
		var overlay_title := Label.new()
		overlay_title.text = "%s%s" % [
			"★ " if bool(row.get("favorite", false)) else "",
			str(row.get("name", "Untitled Project"))
		]
		overlay_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		overlay_title.add_theme_font_size_override("font_size", 14)
		overlay_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay_panel.add_child(overlay_title)

	var title_row := HBoxContainer.new()
	title_row.name = "CardTitleRow"
	title_row.visible = density > 0
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title_row)
	if density > 0:
		_selection_box = CheckBox.new()
		_selection_box.button_pressed = selected
		_selection_box.tooltip_text = "Select this project for bulk actions"
		_selection_box.toggled.connect(_on_checkbox_toggled)
		title_row.add_child(_selection_box)
	var title_label := Label.new()
	title_label.text = str(row.get("name", "Untitled Project"))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if density >= 2 else TextServer.AUTOWRAP_OFF
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.add_theme_font_size_override("font_size", 16 if density <= 2 else 18)
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
	count_label.name = "CardCharacterCount"
	count_label.visible = density >= 2
	var character_count := int(row.get("character_count", 0))
	count_label.text = "%d character%s" % [character_count, "" if character_count == 1 else "s"]
	count_label.modulate = Color(0.67, 0.69, 0.78)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(count_label)
	var workflow_state := str(row.get("workflow_state", "")).strip_edges()
	if not workflow_state.is_empty():
		var workflow_label := Label.new()
		workflow_label.name = "CardWorkflow"
		workflow_label.visible = density >= 1
		workflow_label.text = workflow_state.replace("_", " ").capitalize()
		if bool(row.get("archived", false)):
			workflow_label.text += " • Archived"
		if bool(row.get("sensitive", false)):
			workflow_label.text += " • Sensitive"
		workflow_label.modulate = Color(0.91, 0.69, 0.39)
		workflow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(workflow_label)

	var summary_label := Label.new()
	summary_label.name = "CardSummary"
	summary_label.visible = density >= 2
	var summary_text := str(row.get("summary", "")).strip_edges()
	if summary_text.is_empty():
		summary_text = _join_values(row.get("character_names", []), ", ")
	if summary_text.is_empty():
		summary_text = "No summary yet."
	summary_label.text = summary_text.left(170)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.max_lines_visible = 2 if density == 2 else 3
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
		organisation_label.name = "CardOrganisation"
		organisation_label.visible = density >= 3
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
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		context_requested.emit(_project_id, get_screen_position() + mouse_event.position)
		accept_event()
		return
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
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
