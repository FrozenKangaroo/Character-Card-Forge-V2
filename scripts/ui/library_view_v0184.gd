class_name CCFLibraryV0184View
extends "res://scripts/ui/library_view_v0149.gd"

signal ai_review_requested_v0184(project_id: String)
signal front_porch_requested_v0184(project_id: String)

const WORKFLOW_SERVICE = preload(
	"res://scripts/services/library_workflow_service_v0184.gd"
)

var _v0184_ready := false
var _workflow_filter: OptionButton
var _review_filter: OptionButton
var _token_filter: OptionButton
var _front_porch_filter: OptionButton
var _include_archived: CheckButton
var _sensitive_policy: OptionButton
var _reveal_sensitive: CheckButton
var _recent_only: CheckButton
var _show_stats: CheckButton
var _saved_view_option: OptionButton
var _detail_workflow: OptionButton
var _detail_notes: TextEdit
var _detail_adult: CheckBox
var _detail_private: CheckBox
var _detail_notices: Label
var _detail_archive: Button
var _quick_actions: MenuButton
var _export_directory_dialog: FileDialog
var _report_window: Window
var _report_text: TextEdit
var _save_view_dialog: ConfirmationDialog
var _save_view_name: LineEdit
var _group_dialog: ConfirmationDialog
var _group_name: LineEdit
var _rename_dialog: ConfirmationDialog
var _rename_name: LineEdit
var _context_menu: PopupMenu
var _duplicate_window: Window
var _duplicate_list: ItemList
var _duplicate_detail: TextEdit
var _duplicate_matches: Array[Dictionary] = []
var _duplicate_confirmation: ConfirmationDialog
var _pending_duplicate_decision := ""
var _pending_duplicate_preferred := "first"
var _pending_export_mode := "packages"


func _ready() -> void:
	super._ready()
	_build_workflow_filter_bar_v0184()
	_build_context_menu_v0184()
	_list_view.gui_input.connect(_on_list_context_input_v0184)
	_v0184_ready = true
	_restore_workflow_view_state_v0184()
	_refresh_saved_views_v0184()
	refresh_projects(false)


func refresh_projects(force_rebuild: bool = false) -> void:
	super.refresh_projects(force_rebuild)
	_projects = WORKFLOW_SERVICE.enhance_rows(_projects)
	if _v0184_ready:
		_rebuild_facets()
		_apply_filters()


func _build_bulk_toolbar() -> Control:
	var panel := super._build_bulk_toolbar()
	var rows := panel.get_child(0).get_child(0) as VBoxContainer
	if rows == null:
		return panel
	var batch_row := HFlowContainer.new()
	batch_row.add_theme_constant_override("h_separation", 6)
	batch_row.add_theme_constant_override("v_separation", 6)
	rows.add_child(batch_row)
	batch_row.add_child(_row_label("Batch", 82))
	var batch_actions := MenuButton.new()
	batch_actions.text = "Selected Project Actions"
	var popup := batch_actions.get_popup()
	popup.add_item("Validate Selected", 0)
	popup.add_item("Export Selected Project Packages…", 1)
	popup.add_item("Export Selected Character Cards…", 8)
	popup.add_separator()
	popup.add_item("Mark Needs Review", 2)
	popup.add_item("Mark Stable", 3)
	popup.add_item("Archive Selected", 4)
	popup.add_item("Restore Selected", 5)
	popup.add_separator()
	popup.add_item("Find Duplicates", 6)
	popup.add_item("Create Multi-Character Project / Group…", 7)
	popup.id_pressed.connect(_on_batch_action_v0184)
	batch_row.add_child(batch_actions)
	var safety := Label.new()
	safety.text = "Every item produces an outcome; no batch merge, replace or install is automatic."
	safety.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	safety.modulate = Color(0.66, 0.69, 0.78)
	batch_row.add_child(safety)
	return panel


func _build_detail_panel() -> Control:
	var panel := super._build_detail_panel()
	var detail := _delete_button.get_parent() as VBoxContainer
	if detail == null:
		return panel
	detail.add_child(HSeparator.new())
	var workflow_title := Label.new()
	workflow_title.text = "Private Library Workflow"
	workflow_title.add_theme_font_size_override("font_size", 18)
	detail.add_child(workflow_title)
	var workflow_hint := Label.new()
	workflow_hint.text = "Notes, workflow and privacy markers stay out of Character Card exports."
	workflow_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	workflow_hint.modulate = Color(0.66, 0.69, 0.78)
	detail.add_child(workflow_hint)
	_detail_workflow = OptionButton.new()
	for workflow_state in WORKFLOW_SERVICE.WORKFLOW_STATES:
		_detail_workflow.add_item(_workflow_label_v0184(workflow_state))
		_detail_workflow.set_item_metadata(_detail_workflow.item_count - 1, workflow_state)
	detail.add_child(_detail_workflow)
	_detail_notes = TextEdit.new()
	_detail_notes.placeholder_text = "Private author notes for this project…"
	_detail_notes.custom_minimum_size.y = 110
	_detail_notes.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	detail.add_child(_detail_notes)
	var privacy_row := HFlowContainer.new()
	_detail_adult = CheckBox.new()
	_detail_adult.text = "Adult"
	privacy_row.add_child(_detail_adult)
	_detail_private = CheckBox.new()
	_detail_private.text = "Private"
	privacy_row.add_child(_detail_private)
	detail.add_child(privacy_row)
	var save_workflow := Button.new()
	save_workflow.text = "Save Private Workflow"
	save_workflow.pressed.connect(_save_detail_workflow_v0184)
	detail.add_child(save_workflow)
	_detail_archive = Button.new()
	_detail_archive.text = "Archive Project"
	_detail_archive.pressed.connect(_toggle_archive_primary_v0184)
	detail.add_child(_detail_archive)
	_detail_notices = Label.new()
	_detail_notices.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_notices.modulate = Color(0.91, 0.72, 0.38)
	detail.add_child(_detail_notices)
	_quick_actions = MenuButton.new()
	_quick_actions.text = "Quick Actions…"
	_populate_project_actions_v0184(_quick_actions.get_popup())
	_quick_actions.get_popup().id_pressed.connect(_on_project_action_v0184)
	detail.add_child(_quick_actions)
	return panel


func _build_dialogs() -> void:
	super._build_dialogs()
	_export_directory_dialog = FileDialog.new()
	_export_directory_dialog.title = "Export Selected Projects"
	_export_directory_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	_export_directory_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_export_directory_dialog.dir_selected.connect(_export_selected_to_directory_v0184)
	add_child(_export_directory_dialog)

	_report_window = Window.new()
	_report_window.title = "Library Batch Report"
	_report_window.size = Vector2i(900, 680)
	_report_window.min_size = Vector2i(680, 480)
	_report_window.transient = true
	_report_window.close_requested.connect(_report_window.hide)
	add_child(_report_window)
	var report_margin := MarginContainer.new()
	report_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	report_margin.add_theme_constant_override("margin_left", 16)
	report_margin.add_theme_constant_override("margin_right", 16)
	report_margin.add_theme_constant_override("margin_top", 16)
	report_margin.add_theme_constant_override("margin_bottom", 16)
	_report_window.add_child(report_margin)
	var report_column := VBoxContainer.new()
	report_column.add_theme_constant_override("separation", 8)
	report_margin.add_child(report_column)
	_report_text = TextEdit.new()
	_report_text.editable = false
	_report_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_report_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report_column.add_child(_report_text)
	var copy_report := Button.new()
	copy_report.text = "Copy Report"
	copy_report.pressed.connect(func(): DisplayServer.clipboard_set(_report_text.text))
	report_column.add_child(copy_report)

	_save_view_dialog = _name_dialog_v0184(
		"Save Smart Collection", "Collection name", _save_current_view_v0184
	)
	_save_view_name = _save_view_dialog.get_meta("name_input") as LineEdit
	add_child(_save_view_dialog)
	_group_dialog = _name_dialog_v0184(
		"Create Multi-Character Project / Group",
		"Optional group name",
		_create_group_from_selected_v0184
	)
	_group_name = _group_dialog.get_meta("name_input") as LineEdit
	add_child(_group_dialog)
	_rename_dialog = _name_dialog_v0184(
		"Rename Project", "New project name", _rename_primary_v0184
	)
	_rename_name = _rename_dialog.get_meta("name_input") as LineEdit
	add_child(_rename_dialog)

	_build_duplicate_window_v0184()
	_duplicate_confirmation = ConfirmationDialog.new()
	_duplicate_confirmation.title = "Confirm Duplicate Resolution"
	_duplicate_confirmation.confirmed.connect(_confirm_duplicate_resolution_v0184)
	add_child(_duplicate_confirmation)


func _build_workflow_filter_bar_v0184() -> void:
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 6)
	margin.add_child(row)
	var title_label := Label.new()
	title_label.text = "Workflow"
	row.add_child(title_label)
	_workflow_filter = OptionButton.new()
	_workflow_filter.add_item("All states")
	_workflow_filter.set_item_metadata(0, "")
	for workflow_state in WORKFLOW_SERVICE.WORKFLOW_STATES:
		_workflow_filter.add_item(_workflow_label_v0184(workflow_state))
		_workflow_filter.set_item_metadata(_workflow_filter.item_count - 1, workflow_state)
	_workflow_filter.item_selected.connect(func(_index: int): _apply_filters())
	row.add_child(_workflow_filter)
	_review_filter = OptionButton.new()
	for review_option in [
		["All reviews", ""], ["Not reviewed", "not_reviewed"],
		["Reviewed", "reviewed"], ["Stale review", "stale"]
	]:
		_review_filter.add_item(str(review_option[0]))
		_review_filter.set_item_metadata(_review_filter.item_count - 1, str(review_option[1]))
	_review_filter.item_selected.connect(func(_index: int): _apply_filters())
	row.add_child(_review_filter)
	_token_filter = OptionButton.new()
	for token_option in [
		["All token sizes", ""], ["Under 4K tokens", "under_4k"],
		["4K–12K tokens", "4k_12k"], ["Over 12K tokens", "over_12k"]
	]:
		_token_filter.add_item(str(token_option[0]))
		_token_filter.set_item_metadata(_token_filter.item_count - 1, str(token_option[1]))
	_token_filter.item_selected.connect(func(_index: int): _apply_filters())
	row.add_child(_token_filter)
	_front_porch_filter = OptionButton.new()
	_front_porch_filter.add_item("All Front Porch data")
	_front_porch_filter.set_item_metadata(0, "")
	_front_porch_filter.add_item("Has Front Porch data")
	_front_porch_filter.set_item_metadata(1, "has_data")
	_front_porch_filter.add_item("No Front Porch data")
	_front_porch_filter.set_item_metadata(2, "none")
	_front_porch_filter.item_selected.connect(func(_index: int): _apply_filters())
	row.add_child(_front_porch_filter)
	_include_archived = CheckButton.new()
	_include_archived.text = "Show archived"
	_include_archived.toggled.connect(func(_pressed: bool): _apply_filters())
	row.add_child(_include_archived)
	_recent_only = CheckButton.new()
	_recent_only.text = "Recently used"
	_recent_only.toggled.connect(func(_pressed: bool): _apply_filters())
	row.add_child(_recent_only)
	_show_stats = CheckButton.new()
	_show_stats.text = "Library statistics"
	_show_stats.tooltip_text = "Opt in to aggregate character and token counts for the current view."
	_show_stats.toggled.connect(func(_pressed: bool): _apply_filters())
	row.add_child(_show_stats)
	_sensitive_policy = OptionButton.new()
	_sensitive_policy.add_item("Sensitive: Show")
	_sensitive_policy.set_item_metadata(0, "show")
	_sensitive_policy.add_item("Sensitive: Blur artwork")
	_sensitive_policy.set_item_metadata(1, "blur")
	_sensitive_policy.add_item("Sensitive: Hide")
	_sensitive_policy.set_item_metadata(2, "hide")
	_sensitive_policy.item_selected.connect(func(_index: int): _apply_filters())
	row.add_child(_sensitive_policy)
	_reveal_sensitive = CheckButton.new()
	_reveal_sensitive.text = "Explicitly reveal hidden"
	_reveal_sensitive.tooltip_text = "Required to show cards hidden by the local Sensitive: Hide policy."
	_reveal_sensitive.toggled.connect(func(_pressed: bool): _apply_filters())
	row.add_child(_reveal_sensitive)
	_saved_view_option = OptionButton.new()
	_saved_view_option.custom_minimum_size.x = 180
	_saved_view_option.item_selected.connect(_apply_saved_view_v0184)
	row.add_child(_saved_view_option)
	var save_view := Button.new()
	save_view.text = "Save Smart Collection…"
	save_view.pressed.connect(func(): _save_view_dialog.popup_centered())
	row.add_child(save_view)
	var delete_view := Button.new()
	delete_view.text = "Delete Saved View"
	delete_view.pressed.connect(_delete_saved_view_v0184)
	row.add_child(delete_view)
	add_child(panel)
	move_child(panel, mini(2, get_child_count() - 1))


func _apply_filters() -> void:
	if not _v0184_ready:
		super._apply_filters()
		return
	var needle := _search.text.strip_edges().to_lower() if _search != null else ""
	var workflow_state := _selected_metadata_v0184(_workflow_filter)
	var review_state := _selected_metadata_v0184(_review_filter)
	var token_range := _selected_metadata_v0184(_token_filter)
	var front_porch_state := _selected_metadata_v0184(_front_porch_filter)
	var sensitive_policy := _selected_metadata_v0184(_sensitive_policy)
	_filtered.clear()
	for row in _projects:
		if bool(row.get("archived", false)) and not _include_archived.button_pressed:
			continue
		if (
			bool(row.get("sensitive", false))
			and sensitive_policy == "hide"
			and not _reveal_sensitive.button_pressed
		):
			continue
		if not WORKFLOW_SERVICE.row_matches_rules(row, {
			"query": needle,
			"workflow_state": workflow_state,
			"review_state": review_state,
			"token_range": token_range,
			"front_porch_state": front_porch_state,
			"favorites_only": _favorites_only.button_pressed,
			"recent_only": _recent_only.button_pressed
		}):
			continue
		var row_series_id := str(row.get("series_id", ""))
		if _active_series_id == "__unassigned__":
			if not row_series_id.is_empty():
				continue
		elif not _active_series_id.is_empty() and row_series_id != _active_series_id:
			continue
		if _active_folder == "__unfiled__":
			if not str(row.get("folder", "")).strip_edges().is_empty():
				continue
		elif not _active_folder.is_empty() and str(row.get("folder", "")).nocasecmp_to(_active_folder) != 0:
			continue
		if not _active_collection.is_empty() and not _array_contains_case_insensitive(row.get("collections", []), _active_collection):
			continue
		if not _active_tag.is_empty() and not _array_contains_case_insensitive(row.get("all_tags", []), _active_tag):
			continue
		_filtered.append(row)
	_sort_rows()
	if _recent_only.button_pressed:
		_filtered.sort_custom(
			func(first: Dictionary, second: Dictionary) -> bool:
				return str(first.get("last_used_at", "")) > str(second.get("last_used_at", ""))
		)
	_result_count.text = "%d of %d projects%s" % [
		_filtered.size(), _projects.size(),
		" • archived/private policy applied" if _filtered.size() != _projects.size() else ""
	]
	if _show_stats.button_pressed:
		var character_count := 0
		var token_total := 0
		for row in _filtered:
			character_count += int(row.get("character_count", 0))
			token_total += int(row.get("token_total", 0))
		_result_count.text += " • %d characters • ~%d authored tokens" % [
			character_count, token_total
		]
	_rebuild_content()
	_save_view_state()


func _save_view_state() -> void:
	super._save_view_state()
	if not _v0184_ready:
		return
	_view_state["workflow_filter_v0184"] = _selected_metadata_v0184(_workflow_filter)
	_view_state["review_filter_v0184"] = _selected_metadata_v0184(_review_filter)
	_view_state["token_filter_v0184"] = _selected_metadata_v0184(_token_filter)
	_view_state["front_porch_filter_v0184"] = _selected_metadata_v0184(_front_porch_filter)
	_view_state["include_archived_v0184"] = _include_archived.button_pressed
	_view_state["recent_only_v0184"] = _recent_only.button_pressed
	_view_state["show_stats_v0184"] = _show_stats.button_pressed
	_view_state["sensitive_policy_v0184"] = _selected_metadata_v0184(_sensitive_policy)
	CCFLibraryService.save_view_state(_view_state)


func _update_detail(row: Dictionary) -> void:
	super._update_detail(row)
	if _detail_workflow == null:
		return
	var has_selection := not row.is_empty()
	_detail_workflow.disabled = not has_selection
	_detail_notes.editable = has_selection
	_detail_adult.disabled = not has_selection
	_detail_private.disabled = not has_selection
	_detail_archive.disabled = not has_selection
	_quick_actions.disabled = not has_selection
	if not has_selection:
		_detail_notes.clear()
		_detail_adult.button_pressed = false
		_detail_private.button_pressed = false
		_detail_notices.text = ""
		return
	_select_metadata_v0184(_detail_workflow, str(row.get("workflow_state", "draft")))
	_detail_notes.text = str(row.get("notes", ""))
	var markers := _string_array(row.get("privacy_markers", []))
	_detail_adult.button_pressed = markers.has("adult")
	_detail_private.button_pressed = markers.has("private")
	_detail_archive.text = "Restore from Archive" if bool(row.get("archived", false)) else "Archive Project"
	var notices := _string_array(row.get("notices", []))
	_detail_notices.text = "Notices\n• %s" % "\n• ".join(notices) if not notices.is_empty() else "No current library notices."
	_detail_metadata.text += "\nWorkflow: %s\nEstimated authored tokens: %d" % [
		_workflow_label_v0184(str(row.get("workflow_state", "draft"))),
		int(row.get("token_total", 0))
	]


func _rebuild_grid() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_card_nodes.clear()
	var blur_sensitive := (
		_v0184_ready
		and _selected_metadata_v0184(_sensitive_policy) == "blur"
		and not _reveal_sensitive.button_pressed
	)
	for raw_row in _filtered:
		var row := _presentation_row(raw_row)
		if blur_sensitive and bool(row.get("sensitive", false)):
			row = row.duplicate(true)
			row["thumbnail_path"] = ""
			row["artwork_blurred"] = true
		var project_id := str(row.get("project_id", ""))
		var card := CCFLibraryProjectCard.new()
		card.configure(row, _selected_project_ids.has(project_id))
		card.primary_requested.connect(_on_card_primary_requested)
		card.selection_changed.connect(_on_card_selection_changed)
		card.open_requested.connect(_open_project_id)
		card.context_requested.connect(_show_context_menu_v0184)
		_grid.add_child(card)
		_card_nodes[project_id] = card
	call_deferred("_update_grid_columns")


func _open_project_id(project_id: String) -> void:
	if not project_id.is_empty():
		WORKFLOW_SERVICE.record_activity(project_id, "open", "Opened from Library")
	super._open_project_id(project_id)


func _save_detail_workflow_v0184() -> void:
	if _primary_project_id.is_empty():
		return
	var markers: Array[String] = []
	if _detail_adult.button_pressed:
		markers.append("adult")
	if _detail_private.button_pressed:
		markers.append("private")
	var result := WORKFLOW_SERVICE.set_workflow_metadata([_primary_project_id], {
		"workflow_state": _selected_metadata_v0184(_detail_workflow),
		"notes": _detail_notes.text,
		"privacy_markers": markers
	})
	_handle_v0184_result(result, "Private workflow saved.")


func _toggle_archive_primary_v0184() -> void:
	var row := _row_by_id(_primary_project_id)
	if row.is_empty():
		return
	var archived := not bool(row.get("archived", false))
	var result := WORKFLOW_SERVICE.archive_projects([_primary_project_id], archived)
	_handle_v0184_result(result, "Project archived." if archived else "Project restored.")


func _on_batch_action_v0184(action_id: int) -> void:
	var project_ids := _selected_ids_or_primary()
	match action_id:
		0:
			_show_validation_report_v0184(project_ids)
		1:
			_pending_export_mode = "packages"
			_export_directory_dialog.popup_centered_ratio(0.72)
		8:
			_pending_export_mode = "cards"
			_export_directory_dialog.popup_centered_ratio(0.72)
		2:
			_handle_v0184_result(WORKFLOW_SERVICE.set_workflow_metadata(project_ids, {"workflow_state": "needs_review"}), "Selected projects marked Needs Review.")
		3:
			_handle_v0184_result(WORKFLOW_SERVICE.set_workflow_metadata(project_ids, {"workflow_state": "stable"}), "Selected projects marked Stable.")
		4:
			_handle_v0184_result(WORKFLOW_SERVICE.archive_projects(project_ids, true), "Selected projects archived.")
		5:
			_handle_v0184_result(WORKFLOW_SERVICE.archive_projects(project_ids, false), "Selected projects restored.")
		6:
			_scan_duplicates_v0184(project_ids)
		7:
			if project_ids.size() < 2:
				_status.text = "Select at least two projects to create a group."
			else:
				_group_name.clear()
				_group_dialog.popup_centered()


func _show_validation_report_v0184(project_ids: Array[String]) -> void:
	var result := WORKFLOW_SERVICE.batch_validate(project_ids)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Validation failed."))
		return
	_report_text.text = WORKFLOW_SERVICE.batch_report_text(result, "Library Batch Validation")
	_report_window.popup_centered()
	_status.text = "Validated %d character(s) across %d project(s)." % [
		int(result.get("character_count", 0)), int(result.get("project_count", 0))
	]


func _export_selected_to_directory_v0184(directory_path: String) -> void:
	var result := (
		WORKFLOW_SERVICE.export_character_cards(_selected_ids_or_primary(), directory_path)
		if _pending_export_mode == "cards"
		else WORKFLOW_SERVICE.export_project_packages(_selected_ids_or_primary(), directory_path)
	)
	var heading := "Library Character Card Export" if _pending_export_mode == "cards" else "Library Project-Package Export"
	_report_text.text = WORKFLOW_SERVICE.batch_report_text(result, heading)
	_report_window.popup_centered()
	_status.text = "Exported %d project(s); %d failed." % [
		int(result.get("succeeded", 0)), int(result.get("failed", 0))
	]
	refresh_projects(false)


func _create_group_from_selected_v0184() -> void:
	var result := WORKFLOW_SERVICE.create_group_project(
		_selected_ids_or_primary(), _group_name.text
	)
	if bool(result.get("ok", false)):
		_status.text = "Created a %d-character group project." % int(result.get("character_count", 0))
		project_changed.emit()
		refresh_projects(false)
		_primary_project_id = str(result.get("project_id", ""))
		_update_detail(_row_by_id(_primary_project_id))
	else:
		_status.text = str(result.get("error", "Could not create the group project."))


func _build_context_menu_v0184() -> void:
	_context_menu = PopupMenu.new()
	_populate_project_actions_v0184(_context_menu)
	_context_menu.id_pressed.connect(_on_project_action_v0184)
	add_child(_context_menu)


func _populate_project_actions_v0184(popup: PopupMenu) -> void:
	popup.add_item("Open", 0)
	popup.add_item("Export…", 1)
	popup.add_item("Review", 2)
	popup.add_item("Front Porch Install / Update", 3)
	popup.add_separator()
	popup.add_item("Duplicate / Variation", 4)
	popup.add_item("Add to Collection…", 5)
	popup.add_item("Rename…", 6)
	popup.add_item("Show Location", 7)
	popup.add_item("Archive / Restore", 8)
	popup.add_item("Delete…", 9)


func _show_context_menu_v0184(project_id: String, screen_position: Vector2) -> void:
	_primary_project_id = project_id
	_update_detail(_row_by_id(project_id))
	_context_menu.position = Vector2i(screen_position)
	_context_menu.popup()


func _on_list_context_input_v0184(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event: InputEventMouseButton = event
	if mouse_event.button_index != MOUSE_BUTTON_RIGHT or not mouse_event.pressed:
		return
	var index := _list_view.get_item_at_position(mouse_event.position, true)
	if index < 0:
		return
	_show_context_menu_v0184(
		str(_list_view.get_item_metadata(index)),
		_list_view.get_screen_position() + mouse_event.position
	)


func _on_project_action_v0184(action_id: int) -> void:
	match action_id:
		0:
			_open_primary()
		1:
			_pending_export_mode = "packages"
			_export_directory_dialog.popup_centered_ratio(0.72)
		2:
			if not _primary_project_id.is_empty():
				WORKFLOW_SERVICE.record_activity(_primary_project_id, "review", "Opened AI Review from Library")
				ai_review_requested_v0184.emit(_primary_project_id)
		3:
			if not _primary_project_id.is_empty():
				WORKFLOW_SERVICE.record_activity(_primary_project_id, "install", "Opened Front Porch deployment from Library")
				front_porch_requested_v0184.emit(_primary_project_id)
		4:
			_duplicate_primary()
		5:
			_status.text = "Choose a Collection in the batch toolbar, then use Add."
		6:
			var row := _row_by_id(_primary_project_id)
			_rename_name.text = str(row.get("name", ""))
			_rename_dialog.popup_centered()
		7:
			OS.shell_show_in_file_manager(ProjectSettings.globalize_path(CCFStorageService.project_folder(_primary_project_id)))
		8:
			_toggle_archive_primary_v0184()
		9:
			_request_delete()


func _rename_primary_v0184() -> void:
	var clean_name := _rename_name.text.strip_edges()
	if _primary_project_id.is_empty() or clean_name.is_empty():
		_status.text = "Enter a project name."
		return
	var loaded := CCFStorageService.load_project(_primary_project_id)
	if not bool(loaded.get("ok", false)):
		_status.text = str(loaded.get("error", "Could not load the project."))
		return
	var project: Dictionary = loaded.get("data", {})
	var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
	metadata["name"] = clean_name
	project["metadata"] = metadata
	var saved := CCFStorageService.save_project(project)
	_handle_v0184_result(saved, "Project renamed.")


func _scan_duplicates_v0184(project_ids: Array[String]) -> void:
	var result := WORKFLOW_SERVICE.scan_duplicates(project_ids)
	_duplicate_matches.clear()
	for match_value in result.get("matches", []):
		if match_value is Dictionary:
			_duplicate_matches.append(match_value)
	_duplicate_list.clear()
	for duplicate_match in _duplicate_matches:
		var first: Dictionary = duplicate_match.get("first", {})
		var second: Dictionary = duplicate_match.get("second", {})
		_duplicate_list.add_item("%s: %s ↔ %s" % [
			str(duplicate_match.get("type", "possible")).capitalize(),
			str(first.get("character_name", "Character")),
			str(second.get("character_name", "Character"))
		])
	if _duplicate_matches.is_empty():
		_duplicate_detail.text = "No unexplained exact or probable duplicates were found."
	else:
		_duplicate_list.select(0)
		_update_duplicate_detail_v0184(0)
	_duplicate_window.popup_centered()
	_status.text = "Duplicate scan examined %d character(s)." % int(result.get("scanned_characters", 0))


func _build_duplicate_window_v0184() -> void:
	_duplicate_window = Window.new()
	_duplicate_window.title = "Explainable Duplicate Review"
	_duplicate_window.size = Vector2i(980, 680)
	_duplicate_window.min_size = Vector2i(760, 520)
	_duplicate_window.transient = true
	_duplicate_window.close_requested.connect(_duplicate_window.hide)
	add_child(_duplicate_window)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_duplicate_window.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var hint := Label.new()
	hint.text = "Exact matches use stable IDs/content/artwork hashes. Probable matches show normalized text evidence. Merge and Replace archive the non-preferred project so recovery remains possible."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(split)
	_duplicate_list = ItemList.new()
	_duplicate_list.custom_minimum_size.x = 330
	_duplicate_list.item_selected.connect(_update_duplicate_detail_v0184)
	split.add_child(_duplicate_list)
	_duplicate_detail = TextEdit.new()
	_duplicate_detail.editable = false
	_duplicate_detail.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	split.add_child(_duplicate_detail)
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 8)
	column.add_child(actions)
	for action in [
		["Merge into First…", "merge", "first"],
		["Merge into Second…", "merge", "second"],
		["Replace with First…", "replace", "first"],
		["Replace with Second…", "replace", "second"],
		["Keep Both", "keep_both", "first"],
		["Ignore Match", "ignore", "first"]
	]:
		var button := Button.new()
		button.text = str(action[0])
		button.pressed.connect(_request_duplicate_resolution_v0184.bind(str(action[1]), str(action[2])))
		actions.add_child(button)


func _update_duplicate_detail_v0184(index: int) -> void:
	if index < 0 or index >= _duplicate_matches.size():
		_duplicate_detail.text = ""
		return
	var duplicate_match := _duplicate_matches[index]
	var first: Dictionary = duplicate_match.get("first", {})
	var second: Dictionary = duplicate_match.get("second", {})
	_duplicate_detail.text = "%s match\n\nFirst\n%s\nProject: %s\n\nSecond\n%s\nProject: %s\n\nEvidence\n• %s\n\nNo action is automatic." % [
		str(duplicate_match.get("type", "possible")).capitalize(),
		str(first.get("character_name", "Character")),
		str(first.get("project_name", first.get("project_id", ""))),
		str(second.get("character_name", "Character")),
		str(second.get("project_name", second.get("project_id", ""))),
		"\n• ".join(_string_array(duplicate_match.get("evidence", [])))
	]


func _request_duplicate_resolution_v0184(decision: String, preferred: String) -> void:
	var selected := _duplicate_list.get_selected_items()
	if selected.is_empty():
		_status.text = "Select a duplicate match first."
		return
	_pending_duplicate_decision = decision
	_pending_duplicate_preferred = preferred
	if decision in ["merge", "replace"]:
		_duplicate_confirmation.dialog_text = (
			"This will keep the preferred project and archive the other project. "
			+ ("Collection/tag organisation is merged first. " if decision == "merge" else "")
			+ "No project is permanently deleted. Continue?"
		)
		_duplicate_confirmation.popup_centered()
	else:
		_confirm_duplicate_resolution_v0184()


func _confirm_duplicate_resolution_v0184() -> void:
	var selected := _duplicate_list.get_selected_items()
	if selected.is_empty():
		return
	var index := int(selected[0])
	if index < 0 or index >= _duplicate_matches.size():
		return
	var result := WORKFLOW_SERVICE.resolve_duplicate(
		_duplicate_matches[index], _pending_duplicate_decision, _pending_duplicate_preferred
	)
	if bool(result.get("ok", false)):
		_status.text = str(result.get("message", "Duplicate decision recorded."))
		_duplicate_matches.remove_at(index)
		_duplicate_list.remove_item(index)
		_duplicate_detail.text = "Decision recorded. The match remains recoverable in private Library history."
		project_changed.emit()
		refresh_projects(false)
	else:
		_status.text = str(result.get("error", "Could not resolve the duplicate match."))


func _save_current_view_v0184() -> void:
	var result := WORKFLOW_SERVICE.save_view(_save_view_name.text, {
		"query": _search.text,
		"workflow_state": _selected_metadata_v0184(_workflow_filter),
		"review_state": _selected_metadata_v0184(_review_filter),
		"token_range": _selected_metadata_v0184(_token_filter),
		"front_porch_state": _selected_metadata_v0184(_front_porch_filter),
		"tag": _active_tag,
		"favorites_only": _favorites_only.button_pressed,
		"recent_only": _recent_only.button_pressed
	}, true)
	if bool(result.get("ok", false)):
		_status.text = "Smart Collection saved."
		_refresh_saved_views_v0184()
	else:
		_status.text = str(result.get("error", "Could not save the Smart Collection."))


func _refresh_saved_views_v0184() -> void:
	if _saved_view_option == null:
		return
	_saved_view_option.clear()
	_saved_view_option.add_item("Saved views…")
	_saved_view_option.set_item_metadata(0, "")
	for view_value in WORKFLOW_SERVICE.load_local_state().get("saved_views", []):
		if not view_value is Dictionary:
			continue
		_saved_view_option.add_item(str(view_value.get("name", "Saved View")))
		_saved_view_option.set_item_metadata(
			_saved_view_option.item_count - 1, str(view_value.get("view_id", ""))
		)
		_saved_view_option.set_item_tooltip(
			_saved_view_option.item_count - 1,
			str(view_value.get("kind", "saved_search")).replace("_", " ").capitalize()
		)


func _apply_saved_view_v0184(index: int) -> void:
	if index <= 0:
		return
	var view_id := str(_saved_view_option.get_item_metadata(index))
	for view_value in WORKFLOW_SERVICE.load_local_state().get("saved_views", []):
		if not view_value is Dictionary or str(view_value.get("view_id", "")) != view_id:
			continue
		var rules: Dictionary = view_value.get("rules", {})
		_search.text = str(rules.get("query", ""))
		_select_metadata_v0184(_workflow_filter, str(rules.get("workflow_state", "")))
		_select_metadata_v0184(_review_filter, str(rules.get("review_state", "")))
		_select_metadata_v0184(_token_filter, str(rules.get("token_range", "")))
		_select_metadata_v0184(_front_porch_filter, str(rules.get("front_porch_state", "")))
		_favorites_only.button_pressed = bool(rules.get("favorites_only", false))
		_recent_only.button_pressed = bool(rules.get("recent_only", false))
		_active_tag = str(rules.get("tag", ""))
		_apply_filters()
		_status.text = "Applied saved view: %s" % str(view_value.get("name", "Saved View"))
		return


func _delete_saved_view_v0184() -> void:
	if _saved_view_option.selected <= 0:
		_status.text = "Choose a saved view to delete."
		return
	var view_id := str(_saved_view_option.get_item_metadata(_saved_view_option.selected))
	var result := WORKFLOW_SERVICE.delete_saved_view(view_id)
	if bool(result.get("ok", false)):
		_status.text = "Saved view deleted."
		_refresh_saved_views_v0184()
	else:
		_status.text = str(result.get("error", "Could not delete the saved view."))


func _restore_workflow_view_state_v0184() -> void:
	_select_metadata_v0184(
		_workflow_filter, str(_view_state.get("workflow_filter_v0184", ""))
	)
	_select_metadata_v0184(
		_review_filter, str(_view_state.get("review_filter_v0184", ""))
	)
	_select_metadata_v0184(
		_token_filter, str(_view_state.get("token_filter_v0184", ""))
	)
	_select_metadata_v0184(
		_front_porch_filter, str(_view_state.get("front_porch_filter_v0184", ""))
	)
	_include_archived.button_pressed = bool(_view_state.get("include_archived_v0184", false))
	_recent_only.button_pressed = bool(_view_state.get("recent_only_v0184", false))
	_show_stats.button_pressed = bool(_view_state.get("show_stats_v0184", false))
	_select_metadata_v0184(
		_sensitive_policy, str(_view_state.get("sensitive_policy_v0184", "show"))
	)


func _handle_v0184_result(result: Dictionary, success_message: String) -> void:
	if bool(result.get("ok", false)):
		_status.text = success_message
		project_changed.emit()
		refresh_projects(false)
	else:
		_status.text = str(result.get("error", "The Library action failed."))


func _name_dialog_v0184(
	dialog_title: String, placeholder: String, confirmed_action: Callable
) -> ConfirmationDialog:
	var dialog := ConfirmationDialog.new()
	dialog.title = dialog_title
	var input := LineEdit.new()
	input.placeholder_text = placeholder
	input.custom_minimum_size.x = 380
	dialog.add_child(input)
	dialog.set_meta("name_input", input)
	dialog.confirmed.connect(confirmed_action)
	return dialog


func _selected_metadata_v0184(option: OptionButton) -> String:
	if option == null or option.selected < 0 or option.selected >= option.item_count:
		return ""
	return str(option.get_item_metadata(option.selected))


func _select_metadata_v0184(option: OptionButton, value: String) -> void:
	if option == null:
		return
	for index in range(option.item_count):
		if str(option.get_item_metadata(index)) == value:
			option.select(index)
			return
	option.select(0)


func _workflow_label_v0184(workflow_state: String) -> String:
	return workflow_state.replace("_", " ").capitalize()
