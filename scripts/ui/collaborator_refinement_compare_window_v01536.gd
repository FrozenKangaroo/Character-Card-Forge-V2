class_name CCFCollaboratorRefinementCompareWindowV01536
extends Window

signal apply_requested(mode: String, selected_paths: Array[String])
signal compare_cancelled

const REFINEMENT_SERVICE_V01536 = preload(
	"res://scripts/services/collaborator_refinement_service_v01536.gd"
)

var _tree_v01536: Tree
var _summary_v01536: Label
var _status_v01536: Label
var _update_original_v01536: Button
var _create_copy_v01536: Button
var _rows_v01536: Array[Dictionary] = []
var _update_allowed_v01536 := false


func _ready() -> void:
	visible = false
	title = "Collaborator Compare & Apply"
	size = Vector2i(1180, 760)
	min_size = Vector2i(880, 600)
	force_native = true
	transient = false
	exclusive = false
	close_requested.connect(_cancel_v01536)
	_build_ui_v01536()


func open_compare_v01536(
	source_name: String,
	proposal_name: String,
	rows: Array[Dictionary],
	update_original_allowed: bool
) -> void:
	_rows_v01536 = rows.duplicate(true)
	_update_allowed_v01536 = update_original_allowed
	_summary_v01536.text = (
		"Compare the captured source version of %s with the Collaborator proposal %s. Tick only the changes you want to keep."
	) % [
		source_name if not source_name.strip_edges().is_empty() else "the source character",
		proposal_name if not proposal_name.strip_edges().is_empty() else "the proposal"
	]
	_update_original_v01536.disabled = not _update_allowed_v01536
	_update_original_v01536.tooltip_text = (
		"Apply the selected changes back to the original source character. Character ID, unselected fields, assets, attachments and unrelated data are preserved."
		if _update_allowed_v01536
		else "Update Original is disabled for branch/related-character directions. Use Create Improved Copy so the source remains canonical."
	)
	_status_v01536.text = ""
	_rebuild_tree_v01536()
	popup_centered()


func selected_paths_v01536() -> Array[String]:
	var result: Array[String] = []
	if _tree_v01536 == null:
		return result
	var root_item := _tree_v01536.get_root()
	if root_item == null:
		return result
	var item := root_item.get_first_child()
	while item != null:
		if item.is_checked(0):
			var path := str(item.get_metadata(0)).strip_edges()
			if not path.is_empty():
				result.append(path)
		item = item.get_next()
	return result


func show_status_v01536(text: String) -> void:
	if _status_v01536 != null:
		_status_v01536.text = text


func _build_ui_v01536() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 10)
	margin.add_child(root_box)

	var heading := Label.new()
	heading.text = "Compare Collaborator proposal with source character"
	heading.add_theme_font_size_override("font_size", 22)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_box.add_child(heading)

	_summary_v01536 = Label.new()
	_summary_v01536.name = "CollaboratorRefinementSummaryV01536"
	_summary_v01536.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_v01536.modulate = Color(0.76, 0.80, 0.90)
	root_box.add_child(_summary_v01536)

	var safety := Label.new()
	safety.text = (
		"Nothing is changed until you choose an apply action. Update Original performs a conflict check against the captured source snapshot so edits made after Collaborator was opened are not silently overwritten."
	)
	safety.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	safety.modulate = Color(0.82, 0.70, 0.48)
	root_box.add_child(safety)

	var selection_actions := HBoxContainer.new()
	selection_actions.add_theme_constant_override("separation", 8)
	root_box.add_child(selection_actions)

	var select_all := Button.new()
	select_all.text = "Select All Changes"
	select_all.pressed.connect(func() -> void: _set_all_checked_v01536(true))
	selection_actions.add_child(select_all)

	var select_none := Button.new()
	select_none.text = "Select None"
	select_none.pressed.connect(func() -> void: _set_all_checked_v01536(false))
	selection_actions.add_child(select_none)

	_tree_v01536 = Tree.new()
	_tree_v01536.name = "CollaboratorRefinementTreeV01536"
	_tree_v01536.columns = 4
	_tree_v01536.column_titles_visible = true
	_tree_v01536.set_column_title(0, "Apply")
	_tree_v01536.set_column_title(1, "Field / Section")
	_tree_v01536.set_column_title(2, "Original")
	_tree_v01536.set_column_title(3, "Proposed")
	_tree_v01536.set_column_expand(0, false)
	_tree_v01536.set_column_custom_minimum_width(0, 70)
	_tree_v01536.set_column_custom_minimum_width(1, 180)
	_tree_v01536.set_column_expand(2, true)
	_tree_v01536.set_column_expand(3, true)
	_tree_v01536.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree_v01536.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_box.add_child(_tree_v01536)

	_status_v01536 = Label.new()
	_status_v01536.name = "CollaboratorRefinementStatusV01536"
	_status_v01536.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_v01536.modulate = Color(0.86, 0.74, 0.50)
	root_box.add_child(_status_v01536)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	root_box.add_child(actions)

	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(_cancel_v01536)
	actions.add_child(cancel)

	_create_copy_v01536 = Button.new()
	_create_copy_v01536.name = "CreateImprovedCopyV01536"
	_create_copy_v01536.text = "Create Improved Copy"
	_create_copy_v01536.tooltip_text = (
		"Duplicate the current source character with a new character ID, then apply only the selected changes. The original remains unchanged."
	)
	_create_copy_v01536.pressed.connect(
		func() -> void: _submit_v01536(REFINEMENT_SERVICE_V01536.APPLY_CREATE_COPY)
	)
	actions.add_child(_create_copy_v01536)

	_update_original_v01536 = Button.new()
	_update_original_v01536.name = "UpdateOriginalV01536"
	_update_original_v01536.text = "Update Original"
	_update_original_v01536.pressed.connect(
		func() -> void: _submit_v01536(REFINEMENT_SERVICE_V01536.APPLY_UPDATE_ORIGINAL)
	)
	actions.add_child(_update_original_v01536)


func _rebuild_tree_v01536() -> void:
	_tree_v01536.clear()
	var root_item := _tree_v01536.create_item()
	if _rows_v01536.is_empty():
		var item := _tree_v01536.create_item(root_item)
		item.set_text(1, "No changed fields")
		item.set_text(2, "The proposal matches the captured source for every explicitly generated field.")
		item.set_selectable(0, false)
		item.set_selectable(1, false)
		_update_original_v01536.disabled = true
		_create_copy_v01536.disabled = true
		_status_v01536.text = "There is nothing to apply."
		return

	_create_copy_v01536.disabled = false
	_update_original_v01536.disabled = not _update_allowed_v01536
	for row in _rows_v01536:
		var item := _tree_v01536.create_item(root_item)
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_editable(0, true)
		item.set_checked(0, bool(row.get("selected", true)))
		item.set_metadata(0, str(row.get("path", "")))
		item.set_text(1, str(row.get("label", row.get("path", "Field"))))
		item.set_text(2, _display_value_v01536(row.get("original")))
		item.set_text(3, _display_value_v01536(row.get("proposed")))
		item.set_tooltip_text(1, str(row.get("path", "")))


func _set_all_checked_v01536(checked: bool) -> void:
	var root_item := _tree_v01536.get_root()
	if root_item == null:
		return
	var item := root_item.get_first_child()
	while item != null:
		if item.get_cell_mode(0) == TreeItem.CELL_MODE_CHECK:
			item.set_checked(0, checked)
		item = item.get_next()
	_status_v01536.text = ""


func _submit_v01536(apply_mode: String) -> void:
	var paths := selected_paths_v01536()
	if paths.is_empty():
		_status_v01536.text = "Select at least one changed field or section first."
		return
	apply_requested.emit(apply_mode, paths)


func _cancel_v01536() -> void:
	hide()
	compare_cancelled.emit()


func _display_value_v01536(value: Variant) -> String:
	if value == null:
		return "(empty)"
	if value is String:
		var text := (value as String).strip_edges()
		if text.is_empty():
			return "(empty)"
		return _truncate_v01536(text, 1200)
	if value is Array or value is Dictionary:
		return _truncate_v01536(JSON.stringify(value, "  ", false), 1200)
	return str(value)


func _truncate_v01536(text: String, limit: int) -> String:
	if text.length() <= limit:
		return text
	return text.substr(0, maxi(0, limit - 1)).strip_edges() + "…"
