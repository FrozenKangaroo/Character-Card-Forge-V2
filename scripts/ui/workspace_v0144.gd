class_name CCFWorkspaceV0144View
extends "res://scripts/ui/workspace_v0143.gd"

const MANUAL_GUIDED_WINDOW = preload("res://scripts/ui/manual_guided_window_v0144.gd")

var _manual_guided_window: CCFManualGuidedWindowV0144


func _ready() -> void:
	super._ready()
	_add_manual_guided_button()
	_build_manual_guided_window()


func _add_manual_guided_button() -> void:
	var top: Control = null
	for child in get_children():
		if child is HFlowContainer:
			top = child
			break
	if top == null:
		return
	var button := Button.new()
	button.text = "Manual Guided"
	button.tooltip_text = "Fill the active template directly without AI or Interview / Q&A."
	button.pressed.connect(_open_manual_guided)
	top.add_child(button)
	var builder_index := -1
	for index in range(top.get_child_count()):
		var candidate := top.get_child(index)
		if candidate is Button and candidate.text == "Character Builder":
			builder_index = index
			break
	if builder_index >= 0:
		top.move_child(button, builder_index + 1)


func _build_manual_guided_window() -> void:
	_manual_guided_window = MANUAL_GUIDED_WINDOW.new()
	_manual_guided_window.draft_saved.connect(_on_manual_guided_draft_saved)
	_manual_guided_window.apply_requested.connect(_on_manual_guided_apply_requested)
	add_child(_manual_guided_window)
	_manual_guided_window.hide()


func _open_manual_guided() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		_status.text = "Open a character before using Manual Guided."
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_project = CCFStorageService.character_workspace_document(_project_container, _active_character_id)
	var workspace_value: Variant = _project.get("workspace", {})
	var workspace: Dictionary = workspace_value if workspace_value is Dictionary else {}
	var saved_value: Variant = workspace.get("manual_guided", {})
	var saved_state: Dictionary = saved_value if saved_value is Dictionary else {}
	_manual_guided_window.open_for_character(_project, _template, saved_state)
	_status.text = "Manual Guided opened. This workflow does not call AI."


func _on_manual_guided_draft_saved(state: Dictionary) -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_project = CCFStorageService.character_workspace_document(_project_container, _active_character_id)
	var workspace_value: Variant = _project.get("workspace", {})
	var workspace: Dictionary = workspace_value.duplicate(true) if workspace_value is Dictionary else {}
	workspace["manual_guided"] = state.duplicate(true)
	_project["workspace"] = workspace
	CCFStorageService.update_character(_project_container, _project)
	_dirty = true
	_status.text = "Manual Guided draft saved into the active character."


func _on_manual_guided_apply_requested(values_by_path: Dictionary, state: Dictionary) -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_project = CCFStorageService.character_workspace_document(_project_container, _active_character_id)
	for raw_path in values_by_path:
		var path := str(raw_path).strip_edges()
		if path.is_empty():
			continue
		CCFStorageService.set_value_at_path(_project, path, values_by_path[raw_path])
	var workspace_value: Variant = _project.get("workspace", {})
	var workspace: Dictionary = workspace_value.duplicate(true) if workspace_value is Dictionary else {}
	workspace["manual_guided"] = state.duplicate(true)
	_project["workspace"] = workspace
	CCFStorageService.update_character(_project_container, _project)
	_project = CCFStorageService.character_workspace_document(_project_container, _active_character_id)
	_apply_attachment_runtime_context()
	_dirty = true
	_rebuild_form()
	_update_header()
	_populate_project_controls()
	_update_project_level_window_contexts()
	_status.text = "Manual Guided content applied directly. No AI or Interview / Q&A was used. Save the project when ready."


func _close_tool_windows_for_project_change() -> void:
	if _manual_guided_window != null and _manual_guided_window.visible:
		_manual_guided_window.hide()
	super._close_tool_windows_for_project_change()
