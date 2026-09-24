class_name CCFIdeaGeneratorWindowCurrent
extends "res://scripts/ui/idea_generator_window_v01533_hotfix1.gd"

const IDEA_PACK_SERVICE_V0210 = preload(
	"res://scripts/services/idea_pack_service_v0210.gd"
)

var _idea_pack_service_v0210 := IDEA_PACK_SERVICE_V0210.new()
var _import_dialog_v0210: FileDialog
var _import_preview_v0210: Window
var _import_preview_data_v0210: Dictionary = {}
var _import_rows_v0210: Array[Dictionary] = []
var _import_detail_v0210: TextEdit
var _import_status_v0210: Label
var _import_confirm_v0210: Button
var _import_notebook_v0210: OptionButton

var _export_window_v0210: Window
var _export_dialog_v0210: FileDialog
var _export_scope_v0210: OptionButton
var _export_rows_v0210: Array[Dictionary] = []
var _export_title_v0210: LineEdit
var _export_id_v0210: LineEdit
var _export_description_v0210: TextEdit
var _export_version_v0210: LineEdit
var _export_status_v0210: Label
var _pending_export_ideas_v0210: Array[Dictionary] = []
var _structured_detail_v0210: TextEdit


func _ready() -> void:
	super._ready()
	_build_idea_pack_dialogs_v0210()


func _build_notebook_tab_v01532() -> void:
	super._build_notebook_tab_v01532()
	if _notebook_tab_v01532 == null:
		return
	var toolbar := VBoxContainer.new()
	toolbar.name = "IdeaPackActionsV0210"
	toolbar.add_theme_constant_override("separation", 8)
	var action_row := HFlowContainer.new()
	action_row.name = "IdeaPackActionButtonsV0210"
	action_row.add_theme_constant_override("separation", 8)
	toolbar.add_child(action_row)
	var import_button := Button.new()
	import_button.name = "ImportIdeaPackV0210"
	import_button.text = "Import Idea Pack…"
	import_button.tooltip_text = "Validate and preview a .ccfideas.json file before adding selected entries to Idea Notebook."
	import_button.pressed.connect(_open_import_dialog_v0210)
	action_row.add_child(import_button)
	var export_button := Button.new()
	export_button.name = "ExportIdeaPackV0210"
	export_button.text = "Export Idea Pack…"
	export_button.tooltip_text = "Export selected ideas, a Bible, a Series or the complete notebook as a structured Idea Pack."
	export_button.pressed.connect(_open_export_window_v0210)
	action_row.add_child(export_button)
	var explanation := Label.new()
	explanation.name = "IdeaPackExplanationV0210"
	explanation.text = "Idea Packs preserve Series, Seeds, rules, guardrails, links and custom sections."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	explanation.modulate = Color(0.72, 0.76, 0.86)
	toolbar.add_child(explanation)
	_notebook_tab_v01532.add_child(toolbar)
	_notebook_tab_v01532.move_child(toolbar, 1)

	if _idea_notebook_v01532 == null or _idea_notebook_v01532.get_parent() == null:
		return
	var notebook_box := _idea_notebook_v01532.get_parent()
	var editor := notebook_box.get_parent()
	if not editor is VBoxContainer:
		return
	var structured_box := VBoxContainer.new()
	structured_box.name = "StructuredIdeaDetailsV0210"
	structured_box.add_theme_constant_override("separation", 3)
	var label := Label.new()
	label.text = "Structured Idea Pack details"
	structured_box.add_child(label)
	_structured_detail_v0210 = TextEdit.new()
	_structured_detail_v0210.custom_minimum_size.y = 180
	_structured_detail_v0210.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_structured_detail_v0210.editable = false
	_structured_detail_v0210.placeholder_text = "Ordinary saved ideas have no additional structured fields."
	structured_box.add_child(_structured_detail_v0210)
	(editor as VBoxContainer).add_child(structured_box)
	(editor as VBoxContainer).move_child(structured_box, notebook_box.get_index() + 1)


func _load_selected_idea_v01532(idea_id: String) -> void:
	super._load_selected_idea_v01532(idea_id)
	if _structured_detail_v0210 == null:
		return
	var loaded := _idea_pack_service_v0210.load_local_idea(idea_id)
	if not bool(loaded.get("ok", false)):
		_structured_detail_v0210.text = ""
		return
	var idea_value: Variant = loaded.get("data", {})
	if not idea_value is Dictionary:
		_structured_detail_v0210.text = ""
		return
	var idea: Dictionary = idea_value
	var structured_value: Variant = idea.get("structured_idea", {})
	if not structured_value is Dictionary or (structured_value as Dictionary).is_empty():
		_structured_detail_v0210.text = ""
		return
	_structured_detail_v0210.text = _idea_pack_service_v0210.generation_context_for_idea(idea)


func _clear_editor_v01532() -> void:
	super._clear_editor_v01532()
	if _structured_detail_v0210 != null:
		_structured_detail_v0210.text = ""


func _use_selected_idea_v01532() -> void:
	if _selected_idea_id_v01532.is_empty():
		return
	var loaded := _idea_pack_service_v0210.load_local_idea(_selected_idea_id_v01532)
	if not bool(loaded.get("ok", false)):
		_status_v01532.text = str(loaded.get("error", "Could not load idea."))
		return
	var idea_value: Variant = loaded.get("data", {})
	if not idea_value is Dictionary:
		_status_v01532.text = "The selected idea is not a valid Idea Notebook record."
		return
	var idea: Dictionary = idea_value
	var concept := str(idea.get("concept", "")).strip_edges()
	var structured_value: Variant = idea.get("structured_idea", {})
	if structured_value is Dictionary and not (structured_value as Dictionary).is_empty():
		concept = _idea_pack_service_v0210.generation_context_for_idea(idea)
	if concept.is_empty():
		_status_v01532.text = "This saved idea has no concept text."
		return
	concept_selected.emit(concept)
	hide()


func _build_idea_pack_dialogs_v0210() -> void:
	_import_dialog_v0210 = FileDialog.new()
	_import_dialog_v0210.visible = false
	_import_dialog_v0210.title = "Import Character Card Forge Idea Pack"
	_import_dialog_v0210.access = FileDialog.ACCESS_FILESYSTEM
	_import_dialog_v0210.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_import_dialog_v0210.filters = PackedStringArray([
		"*.ccfideas.json ; Character Card Forge Idea Pack",
		"*.json ; JSON files"
	])
	_import_dialog_v0210.file_selected.connect(_preview_idea_pack_file_v0210)
	add_child(_import_dialog_v0210)
	_import_dialog_v0210.hide()

	_import_preview_v0210 = Window.new()
	_import_preview_v0210.visible = false
	_import_preview_v0210.title = "Review Idea Pack Import"
	_import_preview_v0210.size = Vector2i(1180, 760)
	_import_preview_v0210.min_size = Vector2i(900, 600)
	_import_preview_v0210.force_native = true
	_import_preview_v0210.transient = false
	_import_preview_v0210.exclusive = false
	_import_preview_v0210.close_requested.connect(_import_preview_v0210.hide)
	add_child(_import_preview_v0210)
	_import_preview_v0210.hide()

	_export_window_v0210 = Window.new()
	_export_window_v0210.visible = false
	_export_window_v0210.title = "Export Character Card Forge Idea Pack"
	_export_window_v0210.size = Vector2i(980, 720)
	_export_window_v0210.min_size = Vector2i(760, 560)
	_export_window_v0210.force_native = true
	_export_window_v0210.transient = false
	_export_window_v0210.exclusive = false
	_export_window_v0210.close_requested.connect(_export_window_v0210.hide)
	add_child(_export_window_v0210)
	_export_window_v0210.hide()

	_export_dialog_v0210 = FileDialog.new()
	_export_dialog_v0210.visible = false
	_export_dialog_v0210.title = "Save Idea Pack"
	_export_dialog_v0210.access = FileDialog.ACCESS_FILESYSTEM
	_export_dialog_v0210.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_export_dialog_v0210.filters = PackedStringArray([
		"*.ccfideas.json ; Character Card Forge Idea Pack"
	])
	_export_dialog_v0210.file_selected.connect(_write_export_v0210)
	add_child(_export_dialog_v0210)
	_export_dialog_v0210.hide()


func _open_import_dialog_v0210() -> void:
	_import_dialog_v0210.popup_centered_ratio(0.8)


func _preview_idea_pack_file_v0210(path: String) -> void:
	_import_preview_data_v0210 = _idea_pack_service_v0210.parse_file(path)
	_build_import_preview_v0210()
	_import_preview_v0210.popup_centered()


func _build_import_preview_v0210() -> void:
	for child in _import_preview_v0210.get_children():
		child.queue_free()
	_import_rows_v0210.clear()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_import_preview_v0210.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	var pack: Dictionary = _import_preview_data_v0210.get("pack", {})
	var heading := Label.new()
	heading.text = str(pack.get("title", "Untitled Idea Pack"))
	heading.add_theme_font_size_override("font_size", 21)
	root.add_child(heading)
	var summary: Dictionary = _import_preview_data_v0210.get("summary", {})
	var conflict_summary: Dictionary = _import_preview_data_v0210.get("conflict_summary", {})
	var summary_label := Label.new()
	summary_label.text = (
		"Schema %d • %d Series • %d Seeds • %d other • %d new • %d existing-ID conflicts • %d likely title duplicate%s"
		% [
			int(_import_preview_data_v0210.get("schema_version", 0)),
			int(summary.get("series", 0)),
			int(summary.get("seeds", 0)),
			int(summary.get("other", 0)),
			int(conflict_summary.get("new", 0)),
			int(conflict_summary.get("conflicts", 0)),
			int(conflict_summary.get("title_warnings", 0)),
			"" if int(conflict_summary.get("title_warnings", 0)) == 1 else "s"
		]
	)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(summary_label)
	var issue_text := _format_issues_v0210(
		_import_preview_data_v0210.get("errors", []),
		_import_preview_data_v0210.get("warnings", [])
	)
	if not issue_text.is_empty():
		var issues := TextEdit.new()
		issues.custom_minimum_size.y = 110
		issues.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		issues.editable = false
		issues.text = issue_text
		root.add_child(issues)
	var controls := HFlowContainer.new()
	controls.add_theme_constant_override("separation", 8)
	root.add_child(controls)
	var target_label := Label.new()
	target_label.text = "Import into:"
	controls.add_child(target_label)
	_import_notebook_v0210 = OptionButton.new()
	_import_notebook_v0210.custom_minimum_size.x = 220
	_fill_destination_notebooks_v01532(_import_notebook_v0210, "")
	controls.add_child(_import_notebook_v0210)
	var select_all := Button.new()
	select_all.text = "Select All"
	select_all.pressed.connect(_set_import_selection_v0210.bind(true))
	controls.add_child(select_all)
	var select_none := Button.new()
	select_none.text = "Select None"
	select_none.pressed.connect(_set_import_selection_v0210.bind(false))
	controls.add_child(select_none)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 680
	root.add_child(split)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	split.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)
	var analysed_value: Variant = _import_preview_data_v0210.get("analysed_entries", [])
	if analysed_value is Array:
		for row_value in analysed_value:
			if row_value is Dictionary:
				_add_import_row_v0210(list, row_value as Dictionary)
	_import_detail_v0210 = TextEdit.new()
	_import_detail_v0210.custom_minimum_size.x = 360
	_import_detail_v0210.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_import_detail_v0210.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_import_detail_v0210.editable = false
	split.add_child(_import_detail_v0210)
	if not _import_rows_v0210.is_empty():
		_show_import_detail_v0210(int(_import_rows_v0210[0].get("index", 0)))
	_import_status_v0210 = Label.new()
	_import_status_v0210.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_import_status_v0210)
	var actions := HBoxContainer.new()
	root.add_child(actions)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(_import_preview_v0210.hide)
	actions.add_child(cancel)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	_import_confirm_v0210 = Button.new()
	_import_confirm_v0210.text = "Import Selected"
	_import_confirm_v0210.disabled = not bool(_import_preview_data_v0210.get("import_allowed", false))
	_import_confirm_v0210.tooltip_text = (
		"Nothing is written until this button is pressed. The selected batch is committed atomically."
	)
	_import_confirm_v0210.pressed.connect(_import_selected_v0210)
	actions.add_child(_import_confirm_v0210)


func _add_import_row_v0210(parent: VBoxContainer, row: Dictionary) -> void:
	var entry: Dictionary = row.get("entry", {})
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	parent.add_child(container)
	var check := CheckBox.new()
	check.button_pressed = bool(row.get("selected", true))
	check.set_meta("entry_index_v0210", int(row.get("index", -1)))
	container.add_child(check)
	var inspect := Button.new()
	inspect.text = "%s  [%s]" % [str(entry.get("title", "Untitled")), str(entry.get("kind", "unknown"))]
	inspect.alignment = HORIZONTAL_ALIGNMENT_LEFT
	inspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspect.tooltip_text = "Inspect this entry's complete structured generator context."
	inspect.pressed.connect(_show_import_detail_v0210.bind(int(row.get("index", -1))))
	container.add_child(inspect)
	var conflict := str(row.get("conflict", "new"))
	var conflict_label := Label.new()
	match conflict:
		"existing_id": conflict_label.text = "Existing ID"
		"duplicate_pack_id": conflict_label.text = "Duplicate in pack"
		"likely_title_duplicate": conflict_label.text = "Similar title"
		_: conflict_label.text = "New"
	conflict_label.custom_minimum_size.x = 115
	container.add_child(conflict_label)
	var action := OptionButton.new()
	action.custom_minimum_size.x = 185
	if conflict == "existing_id":
		_add_action_v0210(action, "Skip existing", "skip")
		_add_action_v0210(action, "Replace/update existing", "replace")
		_add_action_v0210(action, "Keep both as copy", "keep_both")
	elif conflict == "duplicate_pack_id":
		_add_action_v0210(action, "Skip duplicate", "skip")
		_add_action_v0210(action, "Keep both as copy", "keep_both")
	else:
		_add_action_v0210(action, "Import as new", "import")
	container.add_child(action)
	_import_rows_v0210.append({
		"index": int(row.get("index", -1)),
		"check": check,
		"action": action
	})


func _add_action_v0210(selector: OptionButton, label: String, value: String) -> void:
	selector.add_item(label)
	selector.set_item_metadata(selector.item_count - 1, value)


func _show_import_detail_v0210(entry_index: int) -> void:
	if _import_detail_v0210 == null:
		return
	var entries_value: Variant = _import_preview_data_v0210.get("entries", [])
	if not entries_value is Array or entry_index < 0 or entry_index >= (entries_value as Array).size():
		_import_detail_v0210.text = ""
		return
	var entry_value: Variant = (entries_value as Array)[entry_index]
	if not entry_value is Dictionary:
		_import_detail_v0210.text = ""
		return
	_import_detail_v0210.text = _idea_pack_service_v0210.render_entry_for_generation(entry_value as Dictionary)


func _set_import_selection_v0210(selected: bool) -> void:
	for row in _import_rows_v0210:
		var check_value: Variant = row.get("check")
		if check_value is CheckBox:
			(check_value as CheckBox).button_pressed = selected


func _import_selected_v0210() -> void:
	var selections: Array = []
	for row in _import_rows_v0210:
		var check_value: Variant = row.get("check")
		var action_value: Variant = row.get("action")
		if not check_value is CheckBox or not action_value is OptionButton:
			continue
		var action_selector := action_value as OptionButton
		var action := "skip"
		if action_selector.selected >= 0:
			action = str(action_selector.get_item_metadata(action_selector.selected))
		selections.append({
			"index": int(row.get("index", -1)),
			"selected": (check_value as CheckBox).button_pressed,
			"action": action
		})
	var notebook_id := _selected_metadata_v01532(_import_notebook_v0210, "")
	_import_confirm_v0210.disabled = true
	var result := _idea_pack_service_v0210.import_preview(
		_import_preview_data_v0210, selections, notebook_id
	)
	if not bool(result.get("ok", false)):
		_import_status_v0210.text = str(result.get("error", "Idea Pack import failed. No ideas were changed."))
		_import_confirm_v0210.disabled = not bool(_import_preview_data_v0210.get("import_allowed", false))
		return
	_import_preview_v0210.hide()
	_refresh_notebook_v01532()
	_status_v01532.text = (
		"Idea Pack import complete: %d new, %d updated, %d kept as copies, %d skipped."
		% [
			int(result.get("imported", 0)),
			int(result.get("replaced", 0)),
			int(result.get("copies", 0)),
			int(result.get("skipped", 0))
		]
	)


func _format_issues_v0210(errors_value: Variant, warnings_value: Variant) -> String:
	var lines: Array[String] = []
	if errors_value is Array:
		for issue_value in errors_value:
			if issue_value is Dictionary:
				lines.append("ERROR: %s" % str((issue_value as Dictionary).get("message", "Validation error")))
	if warnings_value is Array:
		for issue_value in warnings_value:
			if issue_value is Dictionary:
				lines.append("WARNING: %s" % str((issue_value as Dictionary).get("message", "Validation warning")))
	return "\n".join(lines)


func _open_export_window_v0210() -> void:
	_build_export_window_v0210()
	_export_window_v0210.popup_centered()


func _build_export_window_v0210() -> void:
	for child in _export_window_v0210.get_children():
		child.queue_free()
	_export_rows_v0210.clear()
	var ideas := _idea_pack_service_v0210.list_local_ideas(true)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_export_window_v0210.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	var heading := Label.new()
	heading.text = "Export semantic Idea Notebook material"
	heading.add_theme_font_size_override("font_size", 20)
	root.add_child(heading)
	var metadata_grid := GridContainer.new()
	metadata_grid.columns = 2
	root.add_child(metadata_grid)
	metadata_grid.add_child(_simple_label_v0210("Pack title"))
	_export_title_v0210 = LineEdit.new()
	_export_title_v0210.text = "Character Card Forge Idea Pack"
	_export_title_v0210.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metadata_grid.add_child(_export_title_v0210)
	metadata_grid.add_child(_simple_label_v0210("Pack ID"))
	_export_id_v0210 = LineEdit.new()
	_export_id_v0210.placeholder_text = "Generated automatically when left empty"
	metadata_grid.add_child(_export_id_v0210)
	metadata_grid.add_child(_simple_label_v0210("Source version"))
	_export_version_v0210 = LineEdit.new()
	metadata_grid.add_child(_export_version_v0210)
	metadata_grid.add_child(_simple_label_v0210("Description"))
	_export_description_v0210 = TextEdit.new()
	_export_description_v0210.custom_minimum_size.y = 70
	_export_description_v0210.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	metadata_grid.add_child(_export_description_v0210)
	var controls := HFlowContainer.new()
	controls.add_theme_constant_override("separation", 8)
	root.add_child(controls)
	controls.add_child(_simple_label_v0210("Selection scope"))
	_export_scope_v0210 = OptionButton.new()
	_export_scope_v0210.custom_minimum_size.x = 260
	_add_export_scope_v0210("All ideas", {"kind": "all", "value": ""})
	if not _selected_idea_id_v01532.is_empty():
		_add_export_scope_v0210("Selected idea", {"kind": "selected", "value": _selected_idea_id_v01532})
	var filter_values := _idea_pack_service_v0210.export_filter_values(ideas)
	for bible in filter_values.get("bibles", []):
		_add_export_scope_v0210("Bible: %s" % str(bible), {"kind": "bible", "value": str(bible)})
	for series_name in filter_values.get("series", []):
		_add_export_scope_v0210("Series: %s" % str(series_name), {"kind": "series", "value": str(series_name)})
	_export_scope_v0210.item_selected.connect(_apply_export_scope_v0210)
	controls.add_child(_export_scope_v0210)
	var select_all := Button.new()
	select_all.text = "Select All"
	select_all.pressed.connect(_set_export_selection_v0210.bind(true))
	controls.add_child(select_all)
	var select_none := Button.new()
	select_none.text = "Select None"
	select_none.pressed.connect(_set_export_selection_v0210.bind(false))
	controls.add_child(select_none)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for idea in ideas:
		var check := CheckBox.new()
		var entry := _idea_pack_service_v0210.idea_to_entry(idea)
		check.text = "%s  [%s • %s]" % [str(entry.get("title", "Untitled")), str(entry.get("kind", "seed")), str(entry.get("id", ""))]
		check.button_pressed = true
		list.add_child(check)
		_export_rows_v0210.append({"check": check, "idea": idea})
	_export_status_v0210 = Label.new()
	_export_status_v0210.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_export_status_v0210)
	var actions := HBoxContainer.new()
	root.add_child(actions)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(_export_window_v0210.hide)
	actions.add_child(cancel)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	var save := Button.new()
	save.text = "Export Selected…"
	save.pressed.connect(_choose_export_path_v0210)
	actions.add_child(save)


func _simple_label_v0210(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


func _add_export_scope_v0210(label: String, metadata: Dictionary) -> void:
	_export_scope_v0210.add_item(label)
	_export_scope_v0210.set_item_metadata(_export_scope_v0210.item_count - 1, metadata)


func _apply_export_scope_v0210(_selected_index: int) -> void:
	if _export_scope_v0210.selected < 0:
		return
	var metadata_value: Variant = _export_scope_v0210.get_item_metadata(_export_scope_v0210.selected)
	if not metadata_value is Dictionary:
		return
	var metadata: Dictionary = metadata_value
	var kind := str(metadata.get("kind", "all"))
	var value := str(metadata.get("value", ""))
	for row in _export_rows_v0210:
		var check_value: Variant = row.get("check")
		var idea_value: Variant = row.get("idea")
		if not check_value is CheckBox or not idea_value is Dictionary:
			continue
		var selected := false
		if kind == "selected":
			selected = str((idea_value as Dictionary).get("id", "")) == value
		else:
			selected = _idea_pack_service_v0210.idea_matches_export_scope(idea_value as Dictionary, kind, value)
		(check_value as CheckBox).button_pressed = selected


func _set_export_selection_v0210(selected: bool) -> void:
	for row in _export_rows_v0210:
		var check_value: Variant = row.get("check")
		if check_value is CheckBox:
			(check_value as CheckBox).button_pressed = selected


func _choose_export_path_v0210() -> void:
	_pending_export_ideas_v0210.clear()
	for row in _export_rows_v0210:
		var check_value: Variant = row.get("check")
		var idea_value: Variant = row.get("idea")
		if check_value is CheckBox and (check_value as CheckBox).button_pressed and idea_value is Dictionary:
			_pending_export_ideas_v0210.append((idea_value as Dictionary).duplicate(true))
	if _pending_export_ideas_v0210.is_empty():
		_export_status_v0210.text = "Select at least one idea to export."
		return
	_export_dialog_v0210.current_file = "character-card-forge-ideas.ccfideas.json"
	_export_dialog_v0210.popup_centered_ratio(0.8)


func _write_export_v0210(path: String) -> void:
	var metadata := {
		"id": _export_id_v0210.text,
		"title": _export_title_v0210.text,
		"description": _export_description_v0210.text,
		"source_version": _export_version_v0210.text,
		"created_at": Time.get_datetime_string_from_system(true),
		"source": "Character Card Forge v0.21.0"
	}
	var result := _idea_pack_service_v0210.export_to_file(path, _pending_export_ideas_v0210, metadata)
	if not bool(result.get("ok", false)):
		_export_status_v0210.text = str(result.get("error", "Could not export Idea Pack."))
		return
	_export_window_v0210.hide()
	_status_v01532.text = "Exported %d Idea Pack entr%s to %s" % [
		int(result.get("entry_count", 0)),
		"y" if int(result.get("entry_count", 0)) == 1 else "ies",
		str(result.get("path", path))
	]
