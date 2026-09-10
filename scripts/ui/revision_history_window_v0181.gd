class_name CCFRevisionHistoryWindowV0181
extends Window

signal project_changed_v0181(
	project: Dictionary, active_character_id: String, message: String
)

const REVISION_SERVICE = preload(
	"res://scripts/services/revision_service_v0181.gd"
)

var _project_data: Dictionary = {}
var _character_id := ""
var _checkpoint_label: LineEdit
var _checkpoint_note: TextEdit
var _left_selector: OptionButton
var _right_selector: OptionButton
var _diff_tree: Tree
var _left_preview: TextEdit
var _right_preview: TextEdit
var _fork_name: LineEdit
var _retention: SpinBox
var _include_packages: CheckBox
var _summary: Label
var _confirm: ConfirmationDialog
var _export_dialog: FileDialog
var _pending_action := ""
var _selected_revision_id := ""


func _ready() -> void:
	title = "Revision History"
	size = Vector2i(1100, 760)
	min_size = Vector2i(860, 600)
	close_requested.connect(hide)
	_build_ui()
	_build_dialogs()


func open_for_character(project: Dictionary, character_id: String) -> void:
	_project_data = project.duplicate(true)
	_character_id = character_id
	var character_record := CCFStorageService.get_character(
		_project_data, _character_id
	)
	REVISION_SERVICE.ensure_history(character_record)
	_replace_character(character_record)
	_refresh_controls()
	popup_centered()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	margin.add_child(page)

	var heading := Label.new()
	heading.text = "Revision Safety, Diff and Recovery"
	heading.add_theme_font_size_override("font_size", 22)
	page.add_child(heading)
	var intro := Label.new()
	intro.text = (
		"Create durable checkpoints, compare any saved revision with the current "
		+ "character, restore safely, or copy selected fields. Restores and merges "
		+ "create recovery points instead of deleting later history."
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(intro)

	var checkpoint_panel := _panel(page)
	var checkpoint_heading := Label.new()
	checkpoint_heading.text = "New checkpoint"
	checkpoint_panel.add_child(checkpoint_heading)
	var checkpoint_row := HBoxContainer.new()
	checkpoint_panel.add_child(checkpoint_row)
	_checkpoint_label = LineEdit.new()
	_checkpoint_label.placeholder_text = "Milestone label"
	_checkpoint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	checkpoint_row.add_child(_checkpoint_label)
	var create_button := Button.new()
	create_button.text = "Create Checkpoint"
	create_button.pressed.connect(_create_checkpoint)
	checkpoint_row.add_child(create_button)
	_checkpoint_note = TextEdit.new()
	_checkpoint_note.placeholder_text = "Optional note"
	_checkpoint_note.custom_minimum_size.y = 58
	_checkpoint_note.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	checkpoint_panel.add_child(_checkpoint_note)

	var selector_row := HBoxContainer.new()
	page.add_child(selector_row)
	selector_row.add_child(_small_label("Compare"))
	_left_selector = OptionButton.new()
	_left_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_selector.item_selected.connect(func(_index: int) -> void: _refresh_diff())
	selector_row.add_child(_left_selector)
	selector_row.add_child(_small_label("with"))
	_right_selector = OptionButton.new()
	_right_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_selector.item_selected.connect(func(_index: int) -> void: _refresh_diff())
	selector_row.add_child(_right_selector)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(split)
	_diff_tree = Tree.new()
	_diff_tree.columns = 3
	_diff_tree.column_titles_visible = true
	_diff_tree.set_column_title(0, "Field")
	_diff_tree.set_column_title(1, "Left")
	_diff_tree.set_column_title(2, "Right")
	_diff_tree.set_column_expand(0, true)
	_diff_tree.set_column_expand(1, true)
	_diff_tree.set_column_expand(2, true)
	_diff_tree.hide_root = true
	_diff_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_diff_tree.item_selected.connect(_show_selected_diff)
	split.add_child(_diff_tree)
	var previews := VBoxContainer.new()
	previews.custom_minimum_size.x = 360
	split.add_child(previews)
	previews.add_child(_small_label("Left value"))
	_left_preview = _read_only_preview()
	previews.add_child(_left_preview)
	previews.add_child(_small_label("Right value"))
	_right_preview = _read_only_preview()
	previews.add_child(_right_preview)

	var actions := HBoxContainer.new()
	page.add_child(actions)
	var apply_button := Button.new()
	apply_button.text = "Apply Checked from Right"
	apply_button.pressed.connect(_request_apply_checked)
	actions.add_child(apply_button)
	var restore_button := Button.new()
	restore_button.text = "Restore Right"
	restore_button.pressed.connect(_request_restore)
	actions.add_child(restore_button)
	_fork_name = LineEdit.new()
	_fork_name.placeholder_text = "Optional fork name"
	_fork_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(_fork_name)
	var fork_button := Button.new()
	fork_button.text = "Fork Right"
	fork_button.pressed.connect(_fork_revision)
	actions.add_child(fork_button)
	var export_button := Button.new()
	export_button.text = "Export Right…"
	export_button.pressed.connect(_request_export)
	actions.add_child(export_button)

	var settings_row := HBoxContainer.new()
	page.add_child(settings_row)
	settings_row.add_child(_small_label("Keep"))
	_retention = SpinBox.new()
	_retention.min_value = REVISION_SERVICE.MIN_RETENTION
	_retention.max_value = REVISION_SERVICE.MAX_RETENTION
	_retention.step = 1
	_retention.custom_minimum_size.x = 90
	settings_row.add_child(_retention)
	settings_row.add_child(_small_label("revisions"))
	_include_packages = CheckBox.new()
	_include_packages.text = "Include history in portable project packages"
	_include_packages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_row.add_child(_include_packages)
	var save_settings := Button.new()
	save_settings.text = "Apply Retention"
	save_settings.pressed.connect(_apply_retention)
	settings_row.add_child(save_settings)
	var prune_button := Button.new()
	prune_button.text = "Prune Now"
	prune_button.pressed.connect(_prune_now)
	settings_row.add_child(prune_button)

	_summary = Label.new()
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(_summary)


func _build_dialogs() -> void:
	_confirm = ConfirmationDialog.new()
	_confirm.confirmed.connect(_run_confirmed_action)
	add_child(_confirm)
	_export_dialog = FileDialog.new()
	_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_export_dialog.filters = PackedStringArray(["*.json ; Character Card V2 JSON"])
	_export_dialog.file_selected.connect(_export_revision)
	add_child(_export_dialog)


func _panel(parent: Control) -> VBoxContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)
	return box


func _small_label(label_text: String) -> Label:
	var result := Label.new()
	result.text = label_text
	return result


func _read_only_preview() -> TextEdit:
	var editor := TextEdit.new()
	editor.editable = false
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return editor


func _refresh_controls() -> void:
	var character_record := CCFStorageService.get_character(
		_project_data, _character_id
	)
	var revisions := REVISION_SERVICE.list_revisions(character_record)
	_left_selector.clear()
	_right_selector.clear()
	_add_selector_item(_left_selector, "Active • Current", _character_id, "")
	_add_selector_item(_right_selector, "Active • Current", _character_id, "")
	for reverse_index in range(revisions.size() - 1, -1, -1):
		var revision: Dictionary = revisions[reverse_index]
		var item_text := "Active • %s — %s" % [
			str(revision.get("label", "Checkpoint")),
			str(revision.get("created_at", ""))
		]
		var revision_id := str(revision.get("revision_id", ""))
		_add_selector_item(
			_left_selector, item_text, _character_id, revision_id
		)
		_add_selector_item(
			_right_selector, item_text, _character_id, revision_id
		)
	for related_value in _project_data.get("characters", []):
		if not related_value is Dictionary:
			continue
		var related: Dictionary = related_value
		var related_id := str(related.get("character_id", ""))
		if related_id.is_empty() or related_id == _character_id:
			continue
		var related_name := CCFStorageService.character_display_name(related)
		_add_selector_item(
			_left_selector, "%s • Current" % related_name, related_id, ""
		)
		_add_selector_item(
			_right_selector, "%s • Current" % related_name, related_id, ""
		)
		var related_revisions := REVISION_SERVICE.list_revisions(related)
		for reverse_index in range(related_revisions.size() - 1, -1, -1):
			var related_revision: Dictionary = related_revisions[reverse_index]
			var related_text := "%s • %s — %s" % [
				related_name,
				str(related_revision.get("label", "Checkpoint")),
				str(related_revision.get("created_at", ""))
			]
			var related_revision_id := str(
				related_revision.get("revision_id", "")
			)
			_add_selector_item(
				_left_selector,
				related_text,
				related_id,
				related_revision_id
			)
			_add_selector_item(
				_right_selector,
				related_text,
				related_id,
				related_revision_id
			)
	if _left_selector.item_count > 1:
		_left_selector.select(1)
	_right_selector.select(0)
	var history := REVISION_SERVICE.ensure_history(character_record)
	_retention.value = int(history.get("retention_limit", REVISION_SERVICE.DEFAULT_RETENTION))
	_include_packages.button_pressed = bool(history.get("include_in_packages", true))
	_replace_character(character_record)
	_summary.text = "%d saved revision(s). Large images remain path references and are not copied into every checkpoint." % revisions.size()
	_refresh_diff()


func _add_selector_item(
	selector: OptionButton,
	label_text: String,
	character_id: String,
	revision_id: String
) -> void:
	selector.add_item(label_text)
	selector.set_item_metadata(
		selector.item_count - 1,
		{"character_id": character_id, "revision_id": revision_id}
	)


func _selected_source(selector: OptionButton) -> Dictionary:
	if selector.selected < 0:
		return {}
	var source_value: Variant = selector.get_item_metadata(selector.selected)
	return source_value as Dictionary if source_value is Dictionary else {}


func _snapshot_for_selector(selector: OptionButton) -> Dictionary:
	var source := _selected_source(selector)
	var source_character_id := str(source.get("character_id", ""))
	var revision_id := str(source.get("revision_id", ""))
	var character_record := CCFStorageService.get_character(
		_project_data, source_character_id
	)
	if revision_id.is_empty():
		return REVISION_SERVICE.snapshot_character(character_record)
	var revision := REVISION_SERVICE.get_revision(character_record, revision_id)
	var snapshot_value: Variant = revision.get("snapshot", {})
	return (
		(snapshot_value as Dictionary).duplicate(true)
		if snapshot_value is Dictionary
		else {}
	)


func _refresh_diff() -> void:
	if _diff_tree == null:
		return
	_diff_tree.clear()
	var root := _diff_tree.create_item()
	var changes := REVISION_SERVICE.compare_snapshots(
		_snapshot_for_selector(_left_selector),
		_snapshot_for_selector(_right_selector)
	)
	for change in changes:
		var item := _diff_tree.create_item(root)
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_editable(0, true)
		item.set_checked(0, false)
		item.set_text(0, str(change.get("path", "")))
		item.set_text(1, _compact_value(change.get("left")))
		item.set_text(2, _compact_value(change.get("right")))
		item.set_metadata(0, change.duplicate(true))
	_summary.text = "%d changed field(s) in this comparison." % changes.size()
	_left_preview.text = ""
	_right_preview.text = ""


func _show_selected_diff() -> void:
	var item := _diff_tree.get_selected()
	if item == null:
		return
	var change_value: Variant = item.get_metadata(0)
	if not change_value is Dictionary:
		return
	var change: Dictionary = change_value
	_left_preview.text = _full_value(change.get("left"))
	_right_preview.text = _full_value(change.get("right"))


func _compact_value(value: Variant) -> String:
	var text := _full_value(value).replace("\n", " ↵ ")
	return text.left(100) + ("…" if text.length() > 100 else "")


func _full_value(value: Variant) -> String:
	if value is Dictionary or value is Array:
		return JSON.stringify(value, "  ")
	if value == null:
		return "(missing)"
	return str(value)


func _create_checkpoint() -> void:
	var character_record := CCFStorageService.get_character(
		_project_data, _character_id
	)
	var result := REVISION_SERVICE.create_checkpoint(
		character_record,
		_checkpoint_label.text,
		_checkpoint_note.text,
		"manual",
		{"source": "revision_history_window"},
		true
	)
	if not bool(result.get("ok", false)):
		_summary.text = str(result.get("error", "Could not create checkpoint."))
		return
	_replace_character(character_record)
	_checkpoint_label.clear()
	_checkpoint_note.clear()
	_emit_change("Checkpoint created and project saved.")
	_refresh_controls()


func _request_apply_checked() -> void:
	var source := _selected_source(_right_selector)
	_selected_revision_id = str(source.get("revision_id", ""))
	var paths := _checked_paths()
	if paths.is_empty():
		_summary.text = "Check at least one changed field first."
		return
	_pending_action = "apply"
	_confirm.dialog_text = (
		"Apply %d checked field(s) from the right revision? A recovery checkpoint "
		+ "will be created first."
	) % paths.size()
	_confirm.popup_centered()


func _request_restore() -> void:
	var source := _selected_source(_right_selector)
	_selected_revision_id = str(source.get("revision_id", ""))
	if (
		_selected_revision_id.is_empty()
		or str(source.get("character_id", "")) != _character_id
	):
		_summary.text = (
			"Choose a saved revision of the active character on the right before restoring."
		)
		return
	_pending_action = "restore"
	_confirm.dialog_text = (
		"Restore the right revision as the current character? The current state "
		+ "will be preserved as a new recovery checkpoint."
	)
	_confirm.popup_centered()


func _run_confirmed_action() -> void:
	if _pending_action == "apply":
		var source := _selected_source(_right_selector)
		var source_character_id := str(source.get("character_id", ""))
		var source_revision_id := str(source.get("revision_id", ""))
		var source_character := CCFStorageService.get_character(
			_project_data, source_character_id
		)
		var applied := REVISION_SERVICE.apply_selected_snapshot(
			_project_data,
			_character_id,
			_snapshot_for_selector(_right_selector),
			_checked_paths(),
			_right_selector.get_item_text(_right_selector.selected),
			{
				"source_character_id": source_character_id,
				"source_revision_id": source_revision_id,
				"source_character_name": CCFStorageService.character_display_name(
					source_character
				)
			}
		)
		if not bool(applied.get("ok", false)):
			_summary.text = str(applied.get("error", "Could not apply selected fields."))
			return
		_emit_change("Selected revision fields applied with a recovery checkpoint.")
	elif _pending_action == "restore":
		var restored := REVISION_SERVICE.restore_revision(
			_project_data, _character_id, _selected_revision_id
		)
		if not bool(restored.get("ok", false)):
			_summary.text = str(restored.get("error", "Could not restore revision."))
			return
		_emit_change("Revision restored non-destructively and project saved.")
	_pending_action = ""
	_refresh_controls()


func _fork_revision() -> void:
	var source := _selected_source(_right_selector)
	var revision_id := str(source.get("revision_id", ""))
	var source_character_id := str(source.get("character_id", ""))
	if revision_id.is_empty():
		_summary.text = "Choose a saved revision on the right before forking."
		return
	var result := REVISION_SERVICE.fork_revision(
		_project_data, source_character_id, revision_id, _fork_name.text
	)
	if not bool(result.get("ok", false)):
		_summary.text = str(result.get("error", "Could not fork revision."))
		return
	_character_id = str(result.get("character_id", ""))
	var workspace: Dictionary = _project_data.get("workspace", {}).duplicate(true)
	workspace["active_character_id"] = _character_id
	_project_data["workspace"] = workspace
	_fork_name.clear()
	_emit_change("Revision forked as a new character and project saved.")
	_refresh_controls()


func _request_export() -> void:
	var source := _selected_source(_right_selector)
	_selected_revision_id = str(source.get("revision_id", ""))
	if _selected_revision_id.is_empty():
		_summary.text = "Choose a saved revision on the right before exporting."
		return
	var source_character := CCFStorageService.get_character(
		_project_data, str(source.get("character_id", ""))
	)
	var revision := REVISION_SERVICE.get_revision(
		source_character, _selected_revision_id
	)
	var safe_filename := _safe_filename(str(revision.get("label", "revision")))
	_export_dialog.current_file = safe_filename + ".json"
	_export_dialog.popup_centered_ratio(0.72)


func _export_revision(destination_path: String) -> void:
	var source := _selected_source(_right_selector)
	var source_character := CCFStorageService.get_character(
		_project_data, str(source.get("character_id", ""))
	)
	var revision := REVISION_SERVICE.get_revision(
		source_character, _selected_revision_id
	)
	var snapshot_value: Variant = revision.get("snapshot", {})
	if not snapshot_value is Dictionary:
		_summary.text = "The selected revision has no exportable snapshot."
		return
	var export_character := (snapshot_value as Dictionary).duplicate(true)
	export_character.erase(REVISION_SERVICE.HISTORY_KEY)
	export_character.erase(REVISION_SERVICE.LINEAGE_KEY)
	var temporary_project := _project_data.duplicate(true)
	temporary_project["characters"] = [export_character]
	var workspace: Dictionary = temporary_project.get("workspace", {}).duplicate(true)
	workspace["active_character_id"] = str(export_character.get("character_id", ""))
	temporary_project["workspace"] = workspace
	var result := CCFCardFormatService.export_json(
		temporary_project,
		str(export_character.get("character_id", "")),
		destination_path
	)
	_summary.text = (
		"Earlier revision exported as a standard Character Card V2 JSON file."
		if bool(result.get("ok", false))
		else str(result.get("error", "Could not export revision."))
	)


func _apply_retention() -> void:
	var character_record := CCFStorageService.get_character(
		_project_data, _character_id
	)
	var result := REVISION_SERVICE.configure_history(
		character_record, int(_retention.value), _include_packages.button_pressed
	)
	_replace_character(character_record)
	_emit_change(
		"Revision retention updated; %d old revision(s) pruned."
		% int(result.get("removed", 0))
	)
	_refresh_controls()


func _prune_now() -> void:
	var character_record := CCFStorageService.get_character(
		_project_data, _character_id
	)
	var result := REVISION_SERVICE.prune_history(character_record)
	_replace_character(character_record)
	_emit_change(
		"Revision history pruned; %d old revision(s) removed."
		% int(result.get("removed", 0))
	)
	_refresh_controls()


func _checked_paths() -> Array[String]:
	var result: Array[String] = []
	var root := _diff_tree.get_root()
	if root == null:
		return result
	var item := root.get_first_child()
	while item != null:
		if item.is_checked(0):
			var change_value: Variant = item.get_metadata(0)
			if change_value is Dictionary:
				result.append(str((change_value as Dictionary).get("path", "")))
		item = item.get_next()
	return result


func _replace_character(character_record: Dictionary) -> void:
	var index := CCFStorageService.character_index(_project_data, _character_id)
	if index < 0:
		return
	var characters: Array = _project_data.get("characters", []).duplicate(true)
	characters[index] = character_record.duplicate(true)
	_project_data["characters"] = characters


func _emit_change(message_text: String) -> void:
	project_changed_v0181.emit(
		_project_data.duplicate(true), _character_id, message_text
	)


func _safe_filename(value: String) -> String:
	var result := ""
	for character in value.strip_edges():
		if character.is_valid_filename():
			result += character
		else:
			result += "_"
	return result if not result.is_empty() else "revision"
