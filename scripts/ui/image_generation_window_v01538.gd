class_name CCFImageGenerationWindowV01538
extends "res://scripts/ui/image_generation_window_v01531.gd"

const CHARACTER_PICKER_MAX_VISIBLE_V01538 := 250

var _character_picker_button_v01538: Button
var _character_picker_dialog_v01538: ConfirmationDialog
var _character_picker_search_v01538: LineEdit
var _character_picker_results_v01538: ItemList
var _character_picker_status_v01538: Label
var _character_picker_rows_v01538: Array[Dictionary] = []
var _character_picker_visible_rows_v01538: Array[Dictionary] = []


func _ready() -> void:
	super._ready()
	_upgrade_character_source_controls_v01538()
	_build_character_picker_dialog_v01538()
	_update_character_picker_button_v01538()


func character_picker_capabilities_v01538() -> Dictionary:
	return {
		"version": "0.15.38",
		"searchable_character_picker": true,
		"direct_character_selection": true,
		"project_name_search": true,
		"character_name_search": true,
		"role_search": true,
		"tag_search": true,
		"series_search": true,
		"folder_collection_search": true,
		"bounded_unfiltered_results": true,
		"max_visible_results": CHARACTER_PICKER_MAX_VISIBLE_V01538,
		"legacy_project_dropdown_hidden": true,
		"legacy_character_dropdown_hidden": true,
		"ai_jobs_compatibility": true
	}


func build_character_picker_index_v01538(project_rows: Array) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for raw_project_row in project_rows:
		if not raw_project_row is Dictionary:
			continue
		var project_row: Dictionary = raw_project_row
		var project_id := str(project_row.get("project_id", "")).strip_edges()
		if project_id.is_empty():
			continue
		var project_label := str(project_row.get("name", "Untitled Project")).strip_edges()
		if project_label.is_empty():
			project_label = "Untitled Project"
		var project_tags := _picker_string_array_v01538(project_row.get("all_tags", project_row.get("tags", [])))
		var collections := _picker_string_array_v01538(project_row.get("collections", []))
		var project_search_parts: Array[String] = [
			project_label,
			str(project_row.get("summary", "")),
			str(project_row.get("series_id", "")),
			str(project_row.get("folder", "")),
			" ".join(project_tags),
			" ".join(collections)
		]
		for raw_character_row in project_row.get("characters", []):
			if not raw_character_row is Dictionary:
				continue
			var character_row: Dictionary = raw_character_row
			var character_id := str(character_row.get("character_id", "")).strip_edges()
			if character_id.is_empty():
				continue
			var character_label := str(character_row.get("name", "Untitled Character")).strip_edges()
			if character_label.is_empty():
				character_label = "Untitled Character"
			var character_tags := _picker_string_array_v01538(character_row.get("tags", []))
			var search_parts := project_search_parts.duplicate()
			search_parts.append_array([
				character_label,
				str(character_row.get("summary", "")),
				str(character_row.get("role", "")),
				str(character_row.get("creator", "")),
				str(character_row.get("character_version", "")),
				" ".join(character_tags),
				project_id,
				character_id
			])
			rows.append({
				"project_id": project_id,
				"project_name": project_label,
				"character_id": character_id,
				"character_name": character_label,
				"role": str(character_row.get("role", "")).strip_edges(),
				"tags": character_tags,
				"project_tags": project_tags,
				"series_id": str(project_row.get("series_id", "")).strip_edges(),
				"folder": str(project_row.get("folder", "")).strip_edges(),
				"collections": collections,
				"updated_at": str(project_row.get("updated_at", "")),
				"search_text": "\n".join(search_parts).to_lower()
			})
	rows.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			var first_character := str(first.get("character_name", "")).to_lower()
			var second_character := str(second.get("character_name", "")).to_lower()
			if first_character == second_character:
				return str(first.get("project_name", "")).to_lower() < str(second.get("project_name", "")).to_lower()
			return first_character < second_character
	)
	return rows


func filter_character_picker_rows_v01538(
	rows: Array,
	query: String,
	limit: int = CHARACTER_PICKER_MAX_VISIBLE_V01538
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var terms := query.strip_edges().to_lower().split(" ", false)
	var resolved_limit := maxi(1, limit)
	for raw_row in rows:
		if not raw_row is Dictionary:
			continue
		var row: Dictionary = raw_row
		var haystack := str(row.get("search_text", "")).to_lower()
		var matches := true
		for raw_term in terms:
			var term := str(raw_term).strip_edges()
			if not term.is_empty() and not haystack.contains(term):
				matches = false
				break
		if not matches:
			continue
		result.append(row.duplicate(true))
		if result.size() >= resolved_limit:
			break
	return result


func _upgrade_character_source_controls_v01538() -> void:
	if _project_selector == null or _character_selector == null:
		return
	var source_row := _project_selector.get_parent()
	if source_row == null:
		return
	_project_selector.visible = false
	_character_selector.visible = false
	for child in source_row.get_children():
		if child is Label and str((child as Label).text) in ["Project", "Character"]:
			child.visible = false

	var picker_label := Label.new()
	picker_label.name = "ImageStudioCharacterPickerLabelV01538"
	picker_label.text = "Character"
	source_row.add_child(picker_label)
	source_row.move_child(picker_label, 0)

	_character_picker_button_v01538 = Button.new()
	_character_picker_button_v01538.name = "ImageStudioCharacterPickerButtonV01538"
	_character_picker_button_v01538.custom_minimum_size.x = 430
	_character_picker_button_v01538.text = "Choose Character…"
	_character_picker_button_v01538.tooltip_text = (
		"Search characters directly across every saved project by character name, project name, role, tags, series, folder, or collection."
	)
	_character_picker_button_v01538.pressed.connect(_open_character_picker_v01538)
	source_row.add_child(_character_picker_button_v01538)
	source_row.move_child(_character_picker_button_v01538, 1)


func _build_character_picker_dialog_v01538() -> void:
	_character_picker_dialog_v01538 = ConfirmationDialog.new()
	_character_picker_dialog_v01538.name = "ImageStudioCharacterPickerDialogV01538"
	_character_picker_dialog_v01538.visible = false
	_character_picker_dialog_v01538.title = "Choose Character for Image Studio"
	_character_picker_dialog_v01538.min_size = Vector2i(860, 650)
	_character_picker_dialog_v01538.confirmed.connect(_confirm_character_picker_v01538)
	add_child(_character_picker_dialog_v01538)
	_character_picker_dialog_v01538.get_ok_button().text = "Use Character"

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 8)
	_character_picker_dialog_v01538.add_child(root_box)

	var hint := Label.new()
	hint.text = (
		"Search every saved character directly. You do not need to find the project first. Searches include character/project names, roles, tags, series, folders, and collections."
	)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_box.add_child(hint)

	_character_picker_search_v01538 = LineEdit.new()
	_character_picker_search_v01538.name = "ImageStudioCharacterPickerSearchV01538"
	_character_picker_search_v01538.placeholder_text = "Search characters or projects…"
	_character_picker_search_v01538.clear_button_enabled = true
	_character_picker_search_v01538.text_changed.connect(_filter_character_picker_v01538)
	root_box.add_child(_character_picker_search_v01538)

	_character_picker_status_v01538 = Label.new()
	_character_picker_status_v01538.name = "ImageStudioCharacterPickerStatusV01538"
	_character_picker_status_v01538.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_character_picker_status_v01538.modulate = Color(0.68, 0.75, 0.86)
	root_box.add_child(_character_picker_status_v01538)

	_character_picker_results_v01538 = ItemList.new()
	_character_picker_results_v01538.name = "ImageStudioCharacterPickerResultsV01538"
	_character_picker_results_v01538.custom_minimum_size = Vector2(800, 500)
	_character_picker_results_v01538.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_character_picker_results_v01538.select_mode = ItemList.SELECT_SINGLE
	_character_picker_results_v01538.item_activated.connect(_activate_character_picker_item_v01538)
	root_box.add_child(_character_picker_results_v01538)
	_character_picker_dialog_v01538.hide()


func _open_character_picker_v01538() -> void:
	_rebuild_character_picker_index_v01538()
	_character_picker_search_v01538.text = ""
	_filter_character_picker_v01538("")
	_character_picker_dialog_v01538.popup_centered(Vector2i(900, 700))
	_character_picker_search_v01538.call_deferred("grab_focus")


func _rebuild_character_picker_index_v01538() -> void:
	var project_rows := CCFStorageService.list_projects()
	var preferred_project_id := str(_preferred_project_v01528.get("project_id", "")).strip_edges()
	if not preferred_project_id.is_empty():
		var found_preferred := false
		for raw_row in project_rows:
			if raw_row is Dictionary and str(raw_row.get("project_id", "")) == preferred_project_id:
				found_preferred = true
				break
		if not found_preferred:
			project_rows.append(CCFStorageService.project_library_row(_preferred_project_v01528))
	_character_picker_rows_v01538 = build_character_picker_index_v01538(project_rows)


func _filter_character_picker_v01538(query: String) -> void:
	if _character_picker_results_v01538 == null:
		return
	_character_picker_visible_rows_v01538 = filter_character_picker_rows_v01538(
		_character_picker_rows_v01538,
		query,
		CHARACTER_PICKER_MAX_VISIBLE_V01538
	)
	_character_picker_results_v01538.clear()
	var selected_index := -1
	for row in _character_picker_visible_rows_v01538:
		var character_label := str(row.get("character_name", "Untitled Character"))
		var project_label := str(row.get("project_name", "Untitled Project"))
		var display := "%s — %s" % [character_label, project_label]
		var role_text := str(row.get("role", "")).strip_edges()
		if not role_text.is_empty():
			display += "  ·  %s" % role_text
		_character_picker_results_v01538.add_item(display)
		var item_index := _character_picker_results_v01538.item_count - 1
		_character_picker_results_v01538.set_item_tooltip(
			item_index,
			_picker_tooltip_v01538(row)
		)
		if (
			str(row.get("project_id", "")) == str(_project.get("project_id", ""))
			and str(row.get("character_id", "")) == _active_character_id
		):
			selected_index = item_index
	if selected_index >= 0:
		_character_picker_results_v01538.select(selected_index)
		_character_picker_results_v01538.ensure_current_is_visible()
	elif _character_picker_results_v01538.item_count > 0:
		_character_picker_results_v01538.select(0)

	var total_matches := _count_character_picker_matches_v01538(
		_character_picker_rows_v01538, query
	)
	if total_matches == 0:
		_character_picker_status_v01538.text = "No saved characters match this search."
	elif total_matches > _character_picker_visible_rows_v01538.size():
		_character_picker_status_v01538.text = (
			"Showing the first %d of %d matching characters. Type more of the name, project, tag, series, folder, or collection to narrow the list."
			% [_character_picker_visible_rows_v01538.size(), total_matches]
		)
	else:
		_character_picker_status_v01538.text = "%d matching character(s)." % total_matches


func _count_character_picker_matches_v01538(rows: Array, query: String) -> int:
	var terms := query.strip_edges().to_lower().split(" ", false)
	var count := 0
	for raw_row in rows:
		if not raw_row is Dictionary:
			continue
		var haystack := str(raw_row.get("search_text", "")).to_lower()
		var matches := true
		for raw_term in terms:
			var term := str(raw_term).strip_edges()
			if not term.is_empty() and not haystack.contains(term):
				matches = false
				break
		if matches:
			count += 1
	return count


func _confirm_character_picker_v01538() -> void:
	if _character_picker_results_v01538 == null:
		return
	var selected := _character_picker_results_v01538.get_selected_items()
	if selected.is_empty():
		return
	_activate_character_picker_item_v01538(int(selected[0]))


func _activate_character_picker_item_v01538(index: int) -> void:
	if index < 0 or index >= _character_picker_visible_rows_v01538.size():
		return
	var row := _character_picker_visible_rows_v01538[index]
	if _select_character_source_v01538(row):
		_character_picker_dialog_v01538.hide()


func _select_character_source_v01538(row: Dictionary) -> bool:
	var project_id := str(row.get("project_id", "")).strip_edges()
	var character_id := str(row.get("character_id", "")).strip_edges()
	if project_id.is_empty() or character_id.is_empty():
		_status.text = "The selected search result no longer has a valid project/character identity."
		return false
	var loaded := CCFStorageService.load_project(project_id)
	if not bool(loaded.get("ok", false)):
		_status.text = str(loaded.get("error", "Could not load the selected project."))
		return false
	var loaded_project: Dictionary = loaded.get("data", {})
	if CCFStorageService.get_character(loaded_project, character_id).is_empty():
		_status.text = "The selected character is no longer present in that project. Reload the picker and try again."
		return false

	# An explicit picker choice takes precedence over the Workspace project that
	# was merely preferred when Image Studio first opened.
	_preferred_project_v01528 = {}
	_preferred_character_id_v01528 = ""
	_project = loaded_project.duplicate(true)
	_active_character_id = character_id
	_refresh_characters()
	_select_or_add_project_id_v01538(project_id, str(row.get("project_name", "Untitled Project")))
	_select_character_id_v01538(character_id)
	_build_prompt_from_character()
	_refresh_gallery()
	_update_character_picker_button_v01538()
	_status.text = "Selected %s from %s." % [
		str(row.get("character_name", "Untitled Character")),
		str(row.get("project_name", "Untitled Project"))
	]
	return true


func _load_project(project_id: String) -> void:
	super._load_project(project_id)
	_update_character_picker_button_v01538()


func _load_project_snapshot_v01528(
	project: Dictionary, preferred_character_id: String = ""
) -> void:
	super._load_project_snapshot_v01528(project, preferred_character_id)
	_update_character_picker_button_v01538()


func _on_character_selected(index: int) -> void:
	super._on_character_selected(index)
	_update_character_picker_button_v01538()


func _update_character_picker_button_v01538() -> void:
	if _character_picker_button_v01538 == null:
		return
	if _project.is_empty() or _active_character_id.is_empty():
		_character_picker_button_v01538.text = "Choose Character…"
		_character_picker_button_v01538.tooltip_text = "Search characters directly across every saved project."
		return
	var character := CCFStorageService.get_character(_project, _active_character_id)
	if character.is_empty():
		_character_picker_button_v01538.text = "Choose Character…"
		return
	var metadata: Dictionary = _project.get("metadata", {})
	var project_label := str(metadata.get("name", "Untitled Project"))
	var character_label := CCFStorageService.character_display_name(character)
	var full_label := "%s — %s" % [character_label, project_label]
	_character_picker_button_v01538.text = _truncate_picker_label_v01538(full_label, 76)
	_character_picker_button_v01538.tooltip_text = (
		"Current character: %s\nProject: %s\n\nClick to search all saved characters directly."
		% [character_label, project_label]
	)


func _select_or_add_project_id_v01538(project_id: String, project_label: String) -> void:
	if _project_selector == null:
		return
	for item_index in range(_project_selector.item_count):
		if str(_project_selector.get_item_metadata(item_index)) == project_id:
			_project_selector.select(item_index)
			return
	_project_selector.add_item(project_label)
	var added_index := _project_selector.item_count - 1
	_project_selector.set_item_metadata(added_index, project_id)
	_project_selector.select(added_index)


func _select_character_id_v01538(character_id: String) -> void:
	if _character_selector == null:
		return
	for item_index in range(_character_selector.item_count):
		if str(_character_selector.get_item_metadata(item_index)) == character_id:
			_character_selector.select(item_index)
			return


func _picker_tooltip_v01538(row: Dictionary) -> String:
	var lines: Array[String] = [
		"Character: %s" % str(row.get("character_name", "Untitled Character")),
		"Project: %s" % str(row.get("project_name", "Untitled Project"))
	]
	var role_text := str(row.get("role", "")).strip_edges()
	if not role_text.is_empty():
		lines.append("Role: %s" % role_text)
	var tags := _picker_string_array_v01538(row.get("tags", []))
	if not tags.is_empty():
		lines.append("Tags: %s" % ", ".join(tags))
	var series_id := str(row.get("series_id", "")).strip_edges()
	if not series_id.is_empty():
		lines.append("Series: %s" % series_id)
	var folder := str(row.get("folder", "")).strip_edges()
	if not folder.is_empty():
		lines.append("Folder: %s" % folder)
	var collections := _picker_string_array_v01538(row.get("collections", []))
	if not collections.is_empty():
		lines.append("Collections: %s" % ", ".join(collections))
	return "\n".join(lines)


func _picker_string_array_v01538(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if not value is Array:
		return result
	for raw_value in value:
		var text_value := str(raw_value).strip_edges()
		if not text_value.is_empty() and text_value not in result:
			result.append(text_value)
	return result


func _truncate_picker_label_v01538(text_value: String, limit: int) -> String:
	if text_value.length() <= limit:
		return text_value
	return text_value.substr(0, maxi(1, limit - 1)).strip_edges() + "…"
