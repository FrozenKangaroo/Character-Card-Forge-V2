class_name CCFSeriesManagerView
extends VBoxContainer

signal series_changed()

var _settings: Dictionary = {}
var _series_rows: Array[Dictionary] = []
var _active_series: Dictionary = {}
var _loading := false
var _generation_service: CCFGenerationService
var _active_generation_job_id := ""
var _search: LineEdit
var _series_list: ItemList
var _usage_label: Label
var _status: Label
var _name_edit: LineEdit
var _aliases_edit: LineEdit
var _categories_edit: LineEdit
var _default_tags_edit: LineEdit
var _matching_keywords_edit: LineEdit
var _description_edit: TextEdit
var _setting_guidance_edit: TextEdit
var _canon_notes_edit: TextEdit
var _visual_direction_edit: TextEdit
var _generation_rules_edit: TextEdit
var _ai_seed_edit: TextEdit
var _delete_confirm: ConfirmationDialog
var _import_dialog: FileDialog
var _json_export_dialog: FileDialog
var _pack_export_dialog: FileDialog


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_generation_service = CCFGenerationService.new()
	add_child(_generation_service)
	_generation_service.job_completed.connect(_on_generation_completed)
	_generation_service.job_failed.connect(_on_generation_failed)
	_generation_service.job_cancelled.connect(_on_generation_cancelled)
	_build_toolbar()
	_build_body()
	_build_dialogs()
	refresh_series()


func load_settings(settings: Dictionary) -> void:
	_settings = settings.duplicate(true)


func refresh_series(preferred_series_id: String = "") -> void:
	_series_rows = CCFSeriesService.list_series()
	_rebuild_list(preferred_series_id)


func _build_toolbar() -> void:
	var toolbar := HFlowContainer.new()
	toolbar.add_theme_constant_override("h_separation", 8)
	toolbar.add_theme_constant_override("v_separation", 8)
	add_child(toolbar)
	_search = LineEdit.new()
	_search.placeholder_text = "Search series, aliases, categories, guidance, tags, and matching keywords..."
	_search.custom_minimum_size.x = 420
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(func(_text: String): _rebuild_list(_active_series_id()))
	toolbar.add_child(_search)
	toolbar.add_child(_button("New Series", _create_series))
	toolbar.add_child(_button("Duplicate", _duplicate_series))
	toolbar.add_child(_button("Save", _save_active_series))
	toolbar.add_child(_button("Delete", _request_delete))
	toolbar.add_child(_button("Import", _open_import_dialog))
	toolbar.add_child(_button("Export JSON", _export_json))
	toolbar.add_child(_button("Export Pack", _export_pack))
	toolbar.add_child(_button("Auto Assign Unassigned", _auto_assign_unassigned))
	_status = Label.new()
	_status.text = "Series definitions are stored separately from character projects."
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.68, 0.71, 0.82)
	add_child(_status)


func _build_body() -> void:
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(split)

	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 300
	left.add_theme_constant_override("separation", 8)
	split.add_child(left)
	var list_label := Label.new()
	list_label.text = "Series Library"
	list_label.add_theme_font_size_override("font_size", 18)
	left.add_child(list_label)
	_series_list = ItemList.new()
	_series_list.select_mode = ItemList.SELECT_MULTI
	_series_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_series_list.item_selected.connect(_on_series_selected)
	_series_list.multi_selected.connect(_on_series_multi_selected)
	left.add_child(_series_list)
	_usage_label = Label.new()
	_usage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_usage_label.modulate = Color(0.66, 0.69, 0.78)
	left.add_child(_usage_label)

	var editor_scroll := ScrollContainer.new()
	editor_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(editor_scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 20)
	editor_scroll.add_child(margin)
	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 10)
	margin.add_child(form)

	var title_label := Label.new()
	title_label.text = "Series Bible"
	title_label.add_theme_font_size_override("font_size", 22)
	form.add_child(title_label)
	var hint := Label.new()
	hint.text = "Series guidance is injected into character, builder, controlled-build, relationship, group-scene, and card-workflow AI prompts for assigned projects."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.68, 0.71, 0.82)
	form.add_child(hint)

	_name_edit = _add_line_field(form, "Series name")
	_aliases_edit = _add_line_field(form, "Aliases", "Comma-separated alternate names")
	_categories_edit = _add_line_field(form, "Categories", "Comma-separated categories or franchises")
	_default_tags_edit = _add_line_field(form, "Default tags", "Tags that can be copied into assigned projects")
	_matching_keywords_edit = _add_line_field(
		form, "Auto-match keywords", "Distinctive terms used by Auto Series assignment"
	)
	_description_edit = _add_text_field(form, "Description", 100)
	_setting_guidance_edit = _add_text_field(form, "Setting guidance", 130)
	_canon_notes_edit = _add_text_field(form, "Canon notes", 130)
	_visual_direction_edit = _add_text_field(form, "Visual direction", 110)
	_generation_rules_edit = _add_text_field(form, "Generation rules", 140)

	form.add_child(HSeparator.new())
	var ai_label := Label.new()
	ai_label.text = "AI Series Draft"
	ai_label.add_theme_font_size_override("font_size", 18)
	form.add_child(ai_label)
	_ai_seed_edit = TextEdit.new()
	_ai_seed_edit.custom_minimum_size.y = 100
	_ai_seed_edit.placeholder_text = "Describe the franchise, setting, tone, continuity rules, or imported notes you want converted into a structured series bible. Existing filled fields are provided as context."
	form.add_child(_ai_seed_edit)
	var ai_row := HFlowContainer.new()
	ai_row.add_theme_constant_override("h_separation", 8)
	ai_row.add_theme_constant_override("v_separation", 8)
	form.add_child(ai_row)
	ai_row.add_child(_button("Generate / Improve Draft", _generate_series_draft))
	ai_row.add_child(_button("Cancel AI", _cancel_generation))


func _build_dialogs() -> void:
	_delete_confirm = ConfirmationDialog.new()
	_delete_confirm.visible = false
	_delete_confirm.title = "Delete Series"
	_delete_confirm.confirmed.connect(_delete_active_series)
	add_child(_delete_confirm)
	_delete_confirm.hide()

	_import_dialog = _file_dialog(
		FileDialog.FILE_MODE_OPEN_FILE,
		["*.json, *.ccfseries ; Series JSON or Character Card Forge Series Pack"]
	)
	_import_dialog.file_selected.connect(_import_file)
	_json_export_dialog = _file_dialog(
		FileDialog.FILE_MODE_SAVE_FILE, ["*.json ; Character Card Forge series JSON"]
	)
	_json_export_dialog.file_selected.connect(_write_json_export)
	_pack_export_dialog = _file_dialog(
		FileDialog.FILE_MODE_SAVE_FILE, ["*.ccfseries ; Character Card Forge Series Pack"]
	)
	_pack_export_dialog.file_selected.connect(_write_pack_export)


func _file_dialog(file_mode: int, filters: Array[String]) -> FileDialog:
	var dialog := FileDialog.new()
	dialog.visible = false
	dialog.file_mode = file_mode as FileDialog.FileMode
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = filters
	dialog.use_native_dialog = true
	add_child(dialog)
	dialog.hide()
	return dialog


func _rebuild_list(preferred_series_id: String = "") -> void:
	var selected_ids: Array[String] = _selected_series_ids()
	if not preferred_series_id.is_empty():
		selected_ids.clear()
		selected_ids.append(preferred_series_id)
	var usage_counts: Dictionary = CCFSeriesService.usage_counts()
	var needle := _search.text.strip_edges().to_lower() if _search != null else ""
	_series_list.clear()
	var preferred_index := -1
	for series in _series_rows:
		var search_text := _series_search_text(series)
		if not needle.is_empty() and not search_text.contains(needle):
			continue
		var series_id := str(series.get("series_id", ""))
		var usage_count := int(usage_counts.get(series_id, 0))
		var label := "%s   •   %d project%s" % [
			str(series.get("name", "Untitled Series")),
			usage_count,
			"" if usage_count == 1 else "s"
		]
		var item_index := _series_list.item_count
		_series_list.add_item(label)
		_series_list.set_item_metadata(item_index, series_id)
		if selected_ids.has(series_id):
			_series_list.select(item_index, false)
		if series_id == preferred_series_id:
			preferred_index = item_index
	if preferred_index >= 0:
		_series_list.select(preferred_index, true)
		_load_series_by_id(preferred_series_id)
	elif _series_list.item_count > 0:
		var active_id := _active_series_id()
		var active_index := _index_for_series_id(active_id)
		if active_index < 0:
			active_index = 0
		_series_list.select(active_index, true)
		_load_series_by_id(str(_series_list.get_item_metadata(active_index)))
	else:
		_active_series.clear()
		_clear_editor()
		_usage_label.text = "No series definitions yet."


func _on_series_selected(index: int) -> void:
	if _loading or index < 0 or index >= _series_list.item_count:
		return
	_load_series_by_id(str(_series_list.get_item_metadata(index)))


func _on_series_multi_selected(index: int, selected: bool) -> void:
	if selected and index >= 0 and index < _series_list.item_count:
		_load_series_by_id(str(_series_list.get_item_metadata(index)))


func _load_series_by_id(series_id: String) -> void:
	var loaded := CCFSeriesService.load_series(series_id)
	if not loaded.get("ok", false):
		_status.text = str(loaded.get("error", "Could not load the series."))
		return
	var series_value: Variant = loaded.get("data", {})
	if not series_value is Dictionary:
		_status.text = "The selected series file is invalid."
		return
	_active_series = series_value.duplicate(true)
	_populate_editor()
	var usage_count := int(CCFSeriesService.usage_counts().get(series_id, 0))
	_usage_label.text = "%d project%s currently assigned\nID: %s" % [
		usage_count, "" if usage_count == 1 else "s", series_id
	]


func _populate_editor() -> void:
	_loading = true
	_name_edit.text = str(_active_series.get("name", ""))
	_aliases_edit.text = _join(_string_array(_active_series.get("aliases", [])), ", ")
	_categories_edit.text = _join(_string_array(_active_series.get("categories", [])), ", ")
	_default_tags_edit.text = _join(_string_array(_active_series.get("default_tags", [])), ", ")
	_matching_keywords_edit.text = _join(
		_string_array(_active_series.get("matching_keywords", [])), ", "
	)
	_description_edit.text = str(_active_series.get("description", ""))
	_setting_guidance_edit.text = str(_active_series.get("setting_guidance", ""))
	_canon_notes_edit.text = str(_active_series.get("canon_notes", ""))
	_visual_direction_edit.text = str(_active_series.get("visual_direction", ""))
	_generation_rules_edit.text = str(_active_series.get("generation_rules", ""))
	_loading = false


func _capture_editor() -> void:
	if _active_series.is_empty():
		return
	_active_series["name"] = _name_edit.text.strip_edges()
	_active_series["aliases"] = _split_values(_aliases_edit.text)
	_active_series["categories"] = _split_values(_categories_edit.text)
	_active_series["default_tags"] = _split_values(_default_tags_edit.text)
	_active_series["matching_keywords"] = _split_values(_matching_keywords_edit.text)
	_active_series["description"] = _description_edit.text
	_active_series["setting_guidance"] = _setting_guidance_edit.text
	_active_series["canon_notes"] = _canon_notes_edit.text
	_active_series["visual_direction"] = _visual_direction_edit.text
	_active_series["generation_rules"] = _generation_rules_edit.text


func _clear_editor() -> void:
	for control in [
		_name_edit,
		_aliases_edit,
		_categories_edit,
		_default_tags_edit,
		_matching_keywords_edit
	]:
		if control != null:
			control.text = ""
	for control in [
		_description_edit,
		_setting_guidance_edit,
		_canon_notes_edit,
		_visual_direction_edit,
		_generation_rules_edit,
		_ai_seed_edit
	]:
		if control != null:
			control.text = ""


func _create_series() -> void:
	var series := CCFSeriesService.new_series()
	var result := CCFSeriesService.save_series(series)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not create a series."))
		return
	_status.text = "New series created."
	series_changed.emit()
	refresh_series(str(result.get("series_id", "")))


func _save_active_series() -> void:
	if _active_series.is_empty():
		_status.text = "Create or select a series first."
		return
	_capture_editor()
	var result := CCFSeriesService.save_series(_active_series)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not save the series."))
		return
	_status.text = "Series saved. Assigned projects will use the updated guidance immediately."
	series_changed.emit()
	refresh_series(str(result.get("series_id", "")))


func _duplicate_series() -> void:
	var series_id := _active_series_id()
	if series_id.is_empty():
		_status.text = "Select a series to duplicate."
		return
	var result := CCFSeriesService.duplicate_series(series_id)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not duplicate the series."))
		return
	_status.text = "Series duplicated."
	series_changed.emit()
	refresh_series(str(result.get("series_id", "")))


func _request_delete() -> void:
	var series_id := _active_series_id()
	if series_id.is_empty():
		_status.text = "Select a series to delete."
		return
	var usage_count := int(CCFSeriesService.usage_counts().get(series_id, 0))
	_delete_confirm.dialog_text = (
		"Delete '%s'? %d project%s will retain the missing series ID so the reference can be repaired later."
		% [
			str(_active_series.get("name", "Series")),
			usage_count,
			"" if usage_count == 1 else "s"
		]
	)
	_delete_confirm.popup_centered()


func _delete_active_series() -> void:
	var series_id := _active_series_id()
	var result := CCFSeriesService.delete_series(series_id)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not delete the series."))
		return
	_active_series.clear()
	_status.text = "Series deleted. Existing project references were left intact for repair."
	series_changed.emit()
	refresh_series()


func _open_import_dialog() -> void:
	_import_dialog.popup_centered_ratio(0.65)


func _import_file(path: String) -> void:
	var result: Dictionary
	if path.to_lower().ends_with(".ccfseries"):
		result = CCFSeriesService.import_pack(path)
	else:
		result = CCFSeriesService.import_json(path)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not import series data."))
		return
	_status.text = (
		"Imported %d series from the Series Pack." % int(result.get("imported", 0))
		if path.to_lower().ends_with(".ccfseries")
		else "Series JSON imported."
	)
	series_changed.emit()
	refresh_series(str(result.get("series_id", "")))


func _export_json() -> void:
	var series_id := _active_series_id()
	if series_id.is_empty():
		_status.text = "Select a series to export."
		return
	_json_export_dialog.current_file = _safe_filename(str(_active_series.get("name", "series"))) + ".json"
	_json_export_dialog.popup_centered_ratio(0.65)


func _write_json_export(path: String) -> void:
	var result := CCFSeriesService.export_json(_active_series_id(), path)
	_status.text = "Series JSON exported." if result.get("ok", false) else str(result.get("error", "Export failed."))


func _export_pack() -> void:
	var selected_ids := _selected_series_ids()
	if selected_ids.is_empty():
		_status.text = "Select one or more series to export as a pack."
		return
	_pack_export_dialog.current_file = CCFSeriesService.suggested_pack_filename(selected_ids)
	_pack_export_dialog.popup_centered_ratio(0.65)


func _write_pack_export(path: String) -> void:
	var result := CCFSeriesService.export_pack(_selected_series_ids(), path)
	_status.text = "Series Pack exported." if result.get("ok", false) else str(result.get("error", "Export failed."))


func _auto_assign_unassigned() -> void:
	var result := CCFSeriesService.auto_assign_unassigned_projects()
	var failures_value: Variant = result.get("failures", [])
	var failure_count := 0
	if failures_value is Array:
		failure_count = failures_value.size()
	var failure_suffix := ""
	if failure_count > 0:
		failure_suffix = " • %d failed" % failure_count
	_status.text = "Auto Series: %d assigned • %d ambiguous • %d unmatched%s" % [
		int(result.get("assigned", 0)),
		int(result.get("ambiguous", 0)),
		int(result.get("unmatched", 0)),
		failure_suffix
	]
	CCFLibraryService.invalidate_index()
	series_changed.emit()
	refresh_series(_active_series_id())


func _generate_series_draft() -> void:
	if _active_series.is_empty():
		_create_series()
	_capture_editor()
	var seed_text := _ai_seed_edit.text.strip_edges()
	if seed_text.is_empty() and str(_active_series.get("description", "")).strip_edges().is_empty():
		_status.text = "Enter source notes or a description for the AI draft."
		return
	var profile := CCFSettingsService.active_profile(_settings)
	var retry_count := int(_settings.get("generation", {}).get("retry_count", 1))
	var result := _generation_service.queue_series_generation(
		seed_text, _active_series, profile, retry_count
	)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Could not queue the series draft."))
		return
	_active_generation_job_id = str(result.get("job_id", ""))
	_status.text = "Series draft queued."


func _cancel_generation() -> void:
	if _generation_service.has_active_job():
		_generation_service.cancel_active_job()
	else:
		_generation_service.clear_pending_jobs()
	_status.text = "Series AI job cancelled or removed from the queue."


func _on_generation_completed(job_id: String, job_type: String, result: Variant, _metadata: Dictionary) -> void:
	if job_id != _active_generation_job_id or job_type != "series_generation":
		return
	_active_generation_job_id = ""
	if not result is Dictionary:
		_status.text = "The AI series draft did not return a JSON object."
		return
	var proposed: Dictionary = result
	for key in [
		"name",
		"aliases",
		"description",
		"categories",
		"setting_guidance",
		"canon_notes",
		"visual_direction",
		"generation_rules",
		"default_tags",
		"matching_keywords"
	]:
		if proposed.has(key):
			var value: Variant = proposed.get(key)
			if value is Array or value is Dictionary:
				_active_series[key] = value.duplicate(true)
			else:
				_active_series[key] = value
	_active_series = CCFSeriesService.normalise_series(_active_series)
	_populate_editor()
	_status.text = "AI series draft applied locally. Review it, then press Save."


func _on_generation_failed(job_id: String, job_type: String, error_message: String) -> void:
	if job_id != _active_generation_job_id or job_type != "series_generation":
		return
	_active_generation_job_id = ""
	_status.text = error_message


func _on_generation_cancelled(job_id: String, job_type: String) -> void:
	if job_id == _active_generation_job_id and job_type == "series_generation":
		_active_generation_job_id = ""
		_status.text = "Series AI generation cancelled."


func _active_series_id() -> String:
	return str(_active_series.get("series_id", ""))


func _selected_series_ids() -> Array[String]:
	var result: Array[String] = []
	if _series_list == null:
		return result
	for index in _series_list.get_selected_items():
		var series_id := str(_series_list.get_item_metadata(index))
		if not series_id.is_empty() and not result.has(series_id):
			result.append(series_id)
	if result.is_empty() and not _active_series_id().is_empty():
		result.append(_active_series_id())
	return result


func _index_for_series_id(series_id: String) -> int:
	for index in range(_series_list.item_count):
		if str(_series_list.get_item_metadata(index)) == series_id:
			return index
	return -1


func _series_search_text(series: Dictionary) -> String:
	var parts: Array[String] = []
	for key in [
		"name",
		"description",
		"setting_guidance",
		"canon_notes",
		"visual_direction",
		"generation_rules"
	]:
		parts.append(str(series.get(key, "")))
	for key in ["aliases", "categories", "default_tags", "matching_keywords"]:
		parts.append(_join(_string_array(series.get(key, [])), " "))
	return _join(parts, "\n").to_lower()


func _add_line_field(parent: VBoxContainer, label_text: String, placeholder: String = "") -> LineEdit:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var control := LineEdit.new()
	control.placeholder_text = placeholder
	parent.add_child(control)
	return control


func _add_text_field(parent: VBoxContainer, label_text: String, minimum_height: int) -> TextEdit:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var control := TextEdit.new()
	control.custom_minimum_size.y = minimum_height
	parent.add_child(control)
	return control


func _button(label_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label_text
	button.pressed.connect(callback)
	return button


func _split_values(value: String) -> Array[String]:
	var result: Array[String] = []
	for raw_item in value.replace(";", ",").split(",", false):
		var text := str(raw_item).strip_edges()
		if text.is_empty():
			continue
		var exists := false
		for existing in result:
			if existing.nocasecmp_to(text) == 0:
				exists = true
				break
		if not exists:
			result.append(text)
	return result


func _string_array(raw_value: Variant) -> Array[String]:
	var result: Array[String] = []
	if raw_value is Array:
		for raw_item in raw_value:
			var text := str(raw_item).strip_edges()
			if not text.is_empty():
				result.append(text)
	return result


func _join(values: Array[String], separator: String) -> String:
	var output := ""
	for index in range(values.size()):
		if index > 0:
			output += separator
		output += values[index]
	return output


func _safe_filename(value: String) -> String:
	var output := ""
	var allowed := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
	for character in value.strip_edges():
		if allowed.contains(character):
			output += character
		elif character == " " and not output.ends_with("_"):
			output += "_"
	return output if not output.is_empty() else "series"
