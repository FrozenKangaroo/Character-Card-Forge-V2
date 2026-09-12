class_name CCFCardWorkflowWindowV0190
extends "res://scripts/ui/card_workflow_window_v0174.gd"

const AUTHORING_SERVICE = preload(
	"res://scripts/services/rich_authoring_service_v0190.gd"
)

var _active_cast_box_v0190: HFlowContainer
var _active_cast_checks_v0190: Dictionary = {}
var _materialisation_preview_v0190: TextEdit


func _build_ui() -> void:
	super._build_ui()
	var panel := VBoxContainer.new()
	panel.name = "ActiveCastControlsV0190"
	panel.add_theme_constant_override("separation", 7)
	panel.add_child(HSeparator.new())
	var heading := Label.new()
	heading.text = "Persistent roster and active/present cast"
	heading.add_theme_font_size_override("font_size", 17)
	panel.add_child(heading)
	var hint := Label.new()
	hint.text = "Characters selected on the left remain the persistent roster. Choose which roster members are active in this scenario/opening; runtimes that cannot represent this distinction receive a visible export warning."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(hint)
	_active_cast_box_v0190 = HFlowContainer.new()
	_active_cast_box_v0190.add_theme_constant_override("separation", 8)
	panel.add_child(_active_cast_box_v0190)
	var preview_button := Button.new()
	preview_button.text = "Preview Combined Single Card"
	preview_button.pressed.connect(_preview_combined_card_v0190)
	panel.add_child(preview_button)
	_materialisation_preview_v0190 = TextEdit.new()
	_materialisation_preview_v0190.custom_minimum_size.y = 210
	_materialisation_preview_v0190.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_materialisation_preview_v0190.editable = false
	panel.add_child(_materialisation_preview_v0190)
	var fields_parent := _member_root.get_parent()
	fields_parent.add_child(panel)
	if _group_panel_v0174 != null:
		fields_parent.move_child(panel, _group_panel_v0174.get_index())
	_rebuild_active_cast_v0190()


func _rebuild_character_selection() -> void:
	super._rebuild_character_selection()
	if _active_cast_box_v0190 != null:
		_rebuild_active_cast_v0190()


func _new_draft() -> void:
	super._new_draft()
	if _active_cast_box_v0190 != null:
		_rebuild_active_cast_v0190()
		_set_active_cast_v0190(_selected_character_ids())
	if _materialisation_preview_v0190 != null:
		_materialisation_preview_v0190.text = ""


func _load_workflow(workflow: Dictionary) -> void:
	super._load_workflow(workflow)
	_rebuild_active_cast_v0190()
	var rich_value: Variant = workflow.get(AUTHORING_SERVICE.PROJECT_KEY, {})
	var active_ids := _selected_character_ids()
	if rich_value is Dictionary:
		active_ids = _string_array_v0190(
			(rich_value as Dictionary).get("active_character_ids", active_ids)
		)
	_set_active_cast_v0190(active_ids)
	_materialisation_preview_v0190.text = ""


func _save_workflow() -> void:
	var roster_ids := _selected_character_ids()
	if roster_ids.size() < 2:
		_status.text = "Select at least two characters before saving this workflow."
		return
	if _selected_mode() == "group_card":
		var validation := _validate_group_editors_v0174()
		if not validation.is_empty():
			_status.text = validation
			return
	if _current_workflow_id.is_empty():
		_current_workflow_id = "workflow_%d" % Time.get_ticks_usec()
	var timestamp := Time.get_datetime_string_from_system(true)
	var existing := _find_workflow(_current_workflow_id)
	var workflow := {
		"workflow_id": _current_workflow_id,
		"created_at": str(existing.get("created_at", timestamp)),
		"updated_at": timestamp,
		"mode": _selected_mode(),
		"title": _title_edit.text,
		"selected_character_ids": roster_ids,
		"instructions": _instructions.text,
		"summary": _summary_edit.text,
		"shared_scenario": _shared_scenario_edit.text,
		"opening_message": _opening_message_edit.text,
		"notes": _notes_edit.text,
		"members": _capture_members(),
		"front_porch_group": _capture_group_options_v0174()
	}
	workflow = AUTHORING_SERVICE.apply_roster(
		workflow, roster_ids, active_character_ids_v0190()
	)
	workflow_saved.emit(workflow)
	_status.text = "Workflow saved with separate persistent roster and active scenario cast. Save the project file when ready."


func active_character_ids_v0190() -> Array[String]:
	var result: Array[String] = []
	for character_id in _active_cast_checks_v0190:
		var check: CheckBox = _active_cast_checks_v0190[character_id]
		if check.button_pressed and character_id in _selected_character_ids():
			result.append(str(character_id))
	return result


func _rebuild_active_cast_v0190() -> void:
	var previous: Dictionary = {}
	for character_id in _active_cast_checks_v0190:
		var old_check: CheckBox = _active_cast_checks_v0190[character_id]
		previous[character_id] = old_check.button_pressed
	for child in _active_cast_box_v0190.get_children():
		_active_cast_box_v0190.remove_child(child)
		child.queue_free()
	_active_cast_checks_v0190.clear()
	for summary in CCFStorageService.project_character_summaries(_project):
		var character_id := str(summary.get("character_id", ""))
		var check := CheckBox.new()
		check.text = str(summary.get("name", "Untitled Character"))
		check.button_pressed = bool(previous.get(character_id, true))
		_active_cast_box_v0190.add_child(check)
		_active_cast_checks_v0190[character_id] = check


func _set_active_cast_v0190(active_ids: Array[String]) -> void:
	for character_id in _active_cast_checks_v0190:
		var check: CheckBox = _active_cast_checks_v0190[character_id]
		check.button_pressed = character_id in active_ids


func _preview_combined_card_v0190() -> void:
	var roster_ids := _selected_character_ids()
	var draft := {
		"workflow_id": _current_workflow_id,
		"mode": _selected_mode(),
		"title": _title_edit.text,
		"selected_character_ids": roster_ids,
		"summary": _summary_edit.text,
		"shared_scenario": _shared_scenario_edit.text,
		"opening_message": _opening_message_edit.text,
		"members": _capture_members(),
		"front_porch_group": _capture_group_options_v0174()
	}
	draft = AUTHORING_SERVICE.apply_roster(
		draft, roster_ids, active_character_ids_v0190()
	)
	_materialisation_preview_v0190.text = JSON.stringify(
		AUTHORING_SERVICE.materialise_multi_character_card(_project, draft), "  "
	)
	_status.text = "Complete combined-card preview generated. Independent source characters remain unchanged."


func _string_array_v0190(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			var clean := str(item).strip_edges()
			if not clean.is_empty() and clean not in result:
				result.append(clean)
	return result
