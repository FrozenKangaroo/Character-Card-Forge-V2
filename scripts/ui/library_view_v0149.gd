class_name CCFLibraryV0149View
extends "res://scripts/ui/library_view_v0135.gd"

var _folder_option: OptionButton
var _collection_option: OptionButton
var _new_folder_dialog: ConfirmationDialog
var _new_folder_name: LineEdit
var _new_collection_dialog: ConfirmationDialog
var _new_collection_name: LineEdit


func _ready() -> void:
	super._ready()
	_build_assignment_dialogs()
	_refresh_assignment_options()


func _build_bulk_toolbar() -> Control:
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	margin.add_child(rows)

	var selection_row := HFlowContainer.new()
	selection_row.add_theme_constant_override("h_separation", 6)
	selection_row.add_theme_constant_override("v_separation", 6)
	rows.add_child(selection_row)
	_selection_label = Label.new()
	_selection_label.text = "No project selected"
	_selection_label.custom_minimum_size.x = 230
	_selection_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selection_row.add_child(_selection_label)
	selection_row.add_child(_small_button("Favourite", func(): _set_selected_favorite(true)))
	var selection_actions := MenuButton.new()
	selection_actions.text = "Actions"
	selection_actions.get_popup().add_item("Remove Favourite", 0)
	selection_actions.get_popup().add_item("Clear Selection", 1)
	selection_actions.get_popup().id_pressed.connect(_on_selection_action)
	selection_row.add_child(selection_actions)

	var series_row := HFlowContainer.new()
	series_row.add_theme_constant_override("h_separation", 6)
	series_row.add_theme_constant_override("v_separation", 6)
	rows.add_child(series_row)
	series_row.add_child(_row_label("Series", 82))
	_bulk_series_option = OptionButton.new()
	_bulk_series_option.custom_minimum_size.x = 230
	series_row.add_child(_bulk_series_option)
	series_row.add_child(_small_button("Assign", _assign_bulk_series))
	var series_actions := MenuButton.new()
	series_actions.text = "Series Actions"
	series_actions.get_popup().add_item("Clear Series", 0)
	series_actions.get_popup().add_item("Auto Match", 1)
	series_actions.get_popup().add_item("Apply Default Tags", 2)
	series_actions.get_popup().id_pressed.connect(_on_series_action)
	series_row.add_child(series_actions)

	var tags_row := HFlowContainer.new()
	tags_row.add_theme_constant_override("h_separation", 6)
	tags_row.add_theme_constant_override("v_separation", 6)
	rows.add_child(tags_row)
	tags_row.add_child(_row_label("Tags", 82))
	_bulk_tags = LineEdit.new()
	_bulk_tags.placeholder_text = "fantasy, rival, healer"
	_bulk_tags.custom_minimum_size.x = 280
	tags_row.add_child(_bulk_tags)
	tags_row.add_child(_small_button("Add Tags", _add_bulk_tags))
	_bulk_tags_characters = CheckBox.new()
	_bulk_tags_characters.text = "Also add to characters"
	tags_row.add_child(_bulk_tags_characters)

	var folder_row := HFlowContainer.new()
	folder_row.add_theme_constant_override("h_separation", 6)
	folder_row.add_theme_constant_override("v_separation", 6)
	rows.add_child(folder_row)
	folder_row.add_child(_row_label("Folder", 82))
	_folder_option = OptionButton.new()
	_folder_option.custom_minimum_size.x = 230
	folder_row.add_child(_folder_option)
	folder_row.add_child(_small_button("Move", _assign_selected_folder))
	var folder_actions := MenuButton.new()
	folder_actions.text = "Folder Actions"
	folder_actions.get_popup().add_item("New Folder…", 0)
	folder_actions.get_popup().add_item("Clear Folder", 1)
	folder_actions.get_popup().id_pressed.connect(_on_folder_action)
	folder_row.add_child(folder_actions)

	var collection_row := HFlowContainer.new()
	collection_row.add_theme_constant_override("h_separation", 6)
	collection_row.add_theme_constant_override("v_separation", 6)
	rows.add_child(collection_row)
	collection_row.add_child(_row_label("Collection", 82))
	_collection_option = OptionButton.new()
	_collection_option.custom_minimum_size.x = 230
	collection_row.add_child(_collection_option)
	collection_row.add_child(_small_button("Add", _add_selected_collection))
	var collection_actions := MenuButton.new()
	collection_actions.text = "Collection Actions"
	collection_actions.get_popup().add_item("Remove from Selected Collection", 0)
	collection_actions.get_popup().add_item("New Collection…", 1)
	collection_actions.get_popup().id_pressed.connect(_on_collection_action)
	collection_row.add_child(collection_actions)

	return panel


func _rebuild_facets() -> void:
	super._rebuild_facets()
	_refresh_assignment_options()


func _refresh_assignment_options() -> void:
	if _folder_option == null or _collection_option == null:
		return
	var facets: Dictionary = CCFLibraryService.facet_values(_projects)
	_populate_assignment_option(_folder_option, facets.get("folders", []), "Choose folder…")
	_populate_assignment_option(_collection_option, facets.get("collections", []), "Choose collection…")


func _populate_assignment_option(option: OptionButton, raw_values: Variant, placeholder: String) -> void:
	var previous := ""
	if option.selected >= 0 and option.selected < option.item_count:
		previous = str(option.get_item_metadata(option.selected))
	option.clear()
	option.add_item(placeholder)
	option.set_item_metadata(0, "")
	var selected_index := 0
	if raw_values is Array:
		for raw_value in raw_values:
			var value := str(raw_value).strip_edges()
			if value.is_empty():
				continue
			var index := option.item_count
			option.add_item(value)
			option.set_item_metadata(index, value)
			if value.nocasecmp_to(previous) == 0:
				selected_index = index
	option.select(selected_index)


func _sync_selection_controls() -> void:
	var selected_count := _selected_project_ids.size()
	if selected_count > 1:
		_selection_label.text = "%d projects selected" % selected_count
	elif selected_count == 1:
		var selected_id := str(_selected_project_ids.keys()[0])
		var row := _row_by_id(selected_id)
		_selection_label.text = "1 project selected: %s" % str(row.get("name", "Untitled Project"))
	elif not _primary_project_id.is_empty():
		var active_row := _row_by_id(_primary_project_id)
		_selection_label.text = "Active project: %s" % str(active_row.get("name", "Untitled Project"))
	else:
		_selection_label.text = "No project selected"
	_delete_button.disabled = selected_count == 0 and _primary_project_id.is_empty()


func _assign_selected_folder() -> void:
	var folder := _selected_option_value(_folder_option)
	if folder.is_empty():
		_status.text = "Choose a folder first."
		return
	var result := CCFLibraryService.set_project_folder(_selected_ids_or_primary(), folder)
	_handle_bulk_result(result, "%d project(s) moved to %s." % [int(result.get("updated", 0)), folder])


func _add_selected_collection() -> void:
	var collection := _selected_option_value(_collection_option)
	if collection.is_empty():
		_status.text = "Choose a collection first."
		return
	var result := CCFLibraryService.add_project_collection(_selected_ids_or_primary(), collection)
	_handle_bulk_result(result, "%d project(s) added to %s." % [int(result.get("updated", 0)), collection])


func _remove_selected_collection() -> void:
	var collection := _selected_option_value(_collection_option)
	if collection.is_empty():
		_status.text = "Choose the collection to remove first."
		return
	var result := CCFLibraryService.remove_project_collection(_selected_ids_or_primary(), collection)
	_handle_bulk_result(result, "%d project(s) removed from %s." % [int(result.get("updated", 0)), collection])


func _selected_option_value(option: OptionButton) -> String:
	if option == null or option.selected <= 0 or option.selected >= option.item_count:
		return ""
	return str(option.get_item_metadata(option.selected)).strip_edges()


func _on_selection_action(action_id: int) -> void:
	match action_id:
		0:
			_set_selected_favorite(false)
		1:
			_clear_selection()


func _on_series_action(action_id: int) -> void:
	match action_id:
		0:
			_clear_bulk_series()
		1:
			_auto_match_selected_series()
		2:
			_apply_selected_series_tags()


func _on_folder_action(action_id: int) -> void:
	match action_id:
		0:
			_new_folder_name.clear()
			_new_folder_dialog.popup_centered()
		1:
			_clear_bulk_folder()


func _on_collection_action(action_id: int) -> void:
	match action_id:
		0:
			_remove_selected_collection()
		1:
			_new_collection_name.clear()
			_new_collection_dialog.popup_centered()


func _build_assignment_dialogs() -> void:
	_new_folder_dialog = _make_name_dialog("New Folder", "Folder name", _create_and_assign_folder)
	_new_folder_name = _new_folder_dialog.get_meta("name_input") as LineEdit
	add_child(_new_folder_dialog)
	_new_collection_dialog = _make_name_dialog("New Collection", "Collection name", _create_and_assign_collection)
	_new_collection_name = _new_collection_dialog.get_meta("name_input") as LineEdit
	add_child(_new_collection_dialog)


func _make_name_dialog(dialog_title: String, placeholder: String, confirmed_action: Callable) -> ConfirmationDialog:
	var dialog := ConfirmationDialog.new()
	dialog.title = dialog_title
	dialog.dialog_text = "Enter a new name. It will be created by assigning the current project selection."
	var input := LineEdit.new()
	input.placeholder_text = placeholder
	input.custom_minimum_size.x = 320
	dialog.add_child(input)
	dialog.set_meta("name_input", input)
	dialog.confirmed.connect(confirmed_action)
	return dialog


func _create_and_assign_folder() -> void:
	var folder := _new_folder_name.text.strip_edges()
	if folder.is_empty():
		_status.text = "Folder name cannot be empty."
		return
	var result := CCFLibraryService.set_project_folder(_selected_ids_or_primary(), folder)
	_handle_bulk_result(result, "%d project(s) moved to new folder %s." % [int(result.get("updated", 0)), folder])


func _create_and_assign_collection() -> void:
	var collection := _new_collection_name.text.strip_edges()
	if collection.is_empty():
		_status.text = "Collection name cannot be empty."
		return
	var result := CCFLibraryService.add_project_collection(_selected_ids_or_primary(), collection)
	_handle_bulk_result(result, "%d project(s) added to new collection %s." % [int(result.get("updated", 0)), collection])


func _row_label(text: String, width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = width
	return label
