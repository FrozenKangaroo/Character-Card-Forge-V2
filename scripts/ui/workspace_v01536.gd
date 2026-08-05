class_name CCFWorkspaceV01536View
extends "res://scripts/ui/workspace_v01535_project_scope.gd"

const COMPLETION_DESTINATION_WINDOW_V01536 = preload(
	"res://scripts/ui/collaborator_completion_destination_window_v01536.gd"
)
const REFINEMENT_COMPARE_WINDOW_V01536 = preload(
	"res://scripts/ui/collaborator_refinement_compare_window_v01536.gd"
)
const REFINEMENT_SERVICE_V01536 = preload(
	"res://scripts/services/collaborator_refinement_service_v01536.gd"
)

var _refinement_compare_window_v01536: CCFCollaboratorRefinementCompareWindowV01536
var _refinement_proposal_v01536: Dictionary = {}


func _ready() -> void:
	super._ready()
	_build_refinement_compare_window_v01536()


func _build_completion_destination_window_v01535() -> void:
	_completion_destination_window_v01535 = (
		COMPLETION_DESTINATION_WINDOW_V01536.new()
	)
	_completion_destination_window_v01535.visible = false
	_completion_destination_window_v01535.destination_selected.connect(
		_on_completion_destination_selected_v01535
	)
	_completion_destination_window_v01535.routing_cancelled.connect(
		_on_completion_routing_cancelled_v01535
	)
	add_child(_completion_destination_window_v01535)
	_completion_destination_window_v01535.hide()


func _build_refinement_compare_window_v01536() -> void:
	_refinement_compare_window_v01536 = REFINEMENT_COMPARE_WINDOW_V01536.new()
	_refinement_compare_window_v01536.visible = false
	_refinement_compare_window_v01536.apply_requested.connect(
		_on_refinement_apply_requested_v01536
	)
	_refinement_compare_window_v01536.compare_cancelled.connect(
		_on_refinement_compare_cancelled_v01536
	)
	add_child(_refinement_compare_window_v01536)
	_refinement_compare_window_v01536.hide()


func _open_pending_completion_destination_v01535() -> void:
	if _pending_completion_payload_v01535.is_empty():
		_status.text = "There is no pending Collaborator completion to place."
		return
	if str(_project_container.get("project_id", "")) != _pending_completion_project_id_v01535:
		_status.text = (
			"The pending Collaborator completion belongs to a different project. Return to that project or complete it as a new project from the original Workspace."
		)
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	var current_character := CCFStorageService.get_character(
		_project_container,
		_active_character_id
	)
	var project_name := _project_display_name_v01535()
	var current_name := CCFStorageService.character_display_name(current_character)
	var destination_window := (
		_completion_destination_window_v01535
		as CCFCollaboratorCompletionDestinationWindowV01536
	)
	destination_window.open_for_completion_v01536(
		current_character,
		_template,
		project_name,
		current_name,
		_pending_completion_source_v01535,
		REFINEMENT_SERVICE_V01536.source_exists_in_project(
			_pending_completion_source_v01535,
			_project_container
		)
	)


func _on_completion_destination_selected_v01535(destination_id: String) -> void:
	if destination_id == REFINEMENT_SERVICE_V01536.DEST_COMPARE_APPLY:
		_open_refinement_compare_v01536()
		return
	super._on_completion_destination_selected_v01535(destination_id)


func _open_refinement_compare_v01536() -> void:
	if _pending_completion_payload_v01535.is_empty():
		_status.text = "The pending Collaborator completion is no longer available."
		return
	if not REFINEMENT_SERVICE_V01536.source_exists_in_project(
		_pending_completion_source_v01535,
		_project_container
	):
		_status.text = (
			"Compare & Apply is unavailable because the original source character is no longer present in this project. The pending completion is still available for a non-destructive destination."
		)
		return

	var source_snapshot := REFINEMENT_SERVICE_V01536.source_snapshot(
		_pending_completion_source_v01535
	)
	var proposal_result := REFINEMENT_SERVICE_V01536.build_proposal(
		_pending_completion_payload_v01535,
		_pending_completion_title_v01535,
		_template,
		_pending_completion_source_v01535
	)
	if not bool(proposal_result.get("ok", false)):
		_status.text = str(
			proposal_result.get("error", "Could not build the Collaborator comparison proposal.")
		)
		return
	var proposal_value: Variant = proposal_result.get("character", {})
	if not proposal_value is Dictionary:
		_status.text = "The Collaborator proposal could not be materialised for comparison."
		return
	_refinement_proposal_v01536 = (proposal_value as Dictionary).duplicate(true)
	var rows := REFINEMENT_SERVICE_V01536.comparison_rows(
		_pending_completion_payload_v01535,
		source_snapshot,
		_refinement_proposal_v01536,
		_template
	)
	var source_name := CCFStorageService.character_display_name(source_snapshot)
	_refinement_compare_window_v01536.open_compare_v01536(
		source_name,
		str(proposal_result.get("display_name", "Collaborator proposal")),
		rows,
		REFINEMENT_SERVICE_V01536.allows_update_original(
			_pending_completion_source_v01535
		)
	)
	_status.text = (
		"Compare & Apply opened. Review the proposal field-by-field before choosing Update Original or Create Improved Copy."
	)


func _on_refinement_apply_requested_v01536(
	mode: String,
	selected_paths: Array[String]
) -> void:
	var result := apply_collaborator_refinement_v01536(
		mode,
		selected_paths
	)
	if not bool(result.get("ok", false)):
		var error_text := str(
			result.get("error", "Could not apply the Collaborator refinement.")
		)
		_status.text = error_text
		if _refinement_compare_window_v01536 != null:
			_refinement_compare_window_v01536.show_status_v01536(error_text)
		return
	if _refinement_compare_window_v01536 != null:
		_refinement_compare_window_v01536.hide()
	_clear_pending_completion_v01535()
	_status.text = str(result.get("message", "Collaborator refinement applied."))


func apply_collaborator_refinement_v01536(
	mode: String,
	selected_paths: Array[String]
) -> Dictionary:
	if _pending_completion_payload_v01535.is_empty():
		return {"ok": false, "error": "There is no pending Collaborator completion to compare."}
	if not REFINEMENT_SERVICE_V01536.source_exists_in_project(
		_pending_completion_source_v01535,
		_project_container
	):
		return {"ok": false, "error": "The original source character is no longer available in this project."}
	if _refinement_proposal_v01536.is_empty():
		var proposal_result := REFINEMENT_SERVICE_V01536.build_proposal(
			_pending_completion_payload_v01535,
			_pending_completion_title_v01535,
			_template,
			_pending_completion_source_v01535
		)
		if not bool(proposal_result.get("ok", false)):
			return proposal_result
		var proposal_value: Variant = proposal_result.get("character", {})
		if not proposal_value is Dictionary:
			return {"ok": false, "error": "The Collaborator proposal is unavailable."}
		_refinement_proposal_v01536 = (proposal_value as Dictionary).duplicate(true)

	_capture_all_fields()
	_commit_active_character_to_container()
	_capture_project_name()
	var target_id := REFINEMENT_SERVICE_V01536.source_character_id(
		_pending_completion_source_v01535
	)
	var current_source := CCFStorageService.get_character(
		_project_container,
		target_id
	)
	if current_source.is_empty():
		return {"ok": false, "error": "The source character could not be loaded for Compare & Apply."}
	var captured_source := REFINEMENT_SERVICE_V01536.source_snapshot(
		_pending_completion_source_v01535
	)
	var apply_result := REFINEMENT_SERVICE_V01536.apply_selected_changes(
		current_source,
		captured_source,
		_refinement_proposal_v01536,
		selected_paths,
		mode,
		_pending_completion_source_v01535,
		_pending_completion_title_v01535
	)
	if not bool(apply_result.get("ok", false)):
		return apply_result
	var character_value: Variant = apply_result.get("character", {})
	if not character_value is Dictionary:
		return {"ok": false, "error": "Compare & Apply did not produce a character record."}
	var character: Dictionary = character_value

	if mode == REFINEMENT_SERVICE_V01536.APPLY_UPDATE_ORIGINAL:
		if not _replace_character_record_v01535(target_id, character):
			return {"ok": false, "error": "Could not update the source character record."}
		_reload_project_after_completion_v01535(target_id)
		return {
			"ok": true,
			"mode": mode,
			"character_id": target_id,
			"message": "%s was updated with %d selected Collaborator change(s). Unselected fields and unrelated data were preserved." % [
				CCFStorageService.character_display_name(character),
				selected_paths.size()
			]
		}

	if mode == REFINEMENT_SERVICE_V01536.APPLY_CREATE_COPY:
		var characters: Array = _project_container.get("characters", []).duplicate(true)
		characters.append(character.duplicate(true))
		_project_container["characters"] = characters
		var character_id := str(character.get("character_id", ""))
		_reload_project_after_completion_v01535(character_id)
		return {
			"ok": true,
			"mode": mode,
			"character_id": character_id,
			"message": "%s was created as an improved copy with %d selected Collaborator change(s). The original source character was left unchanged." % [
				CCFStorageService.character_display_name(character),
				selected_paths.size()
			]
		}

	return {"ok": false, "error": "Unknown Compare & Apply mode."}


func _on_refinement_compare_cancelled_v01536() -> void:
	if _pending_completion_payload_v01535.is_empty():
		return
	_status.text = (
		"Compare & Apply closed without changing the source character. The Collaborator completion is still pending and can be reopened from Author → Place Pending Collaborator Completion…."
	)


func collaborator_refinement_capabilities_v01536() -> Dictionary:
	return REFINEMENT_SERVICE_V01536.capabilities()


func collaborator_completion_capabilities_v01535() -> Dictionary:
	var result := super.collaborator_completion_capabilities_v01535()
	result["version"] = "0.15.36"
	result["compare_apply"] = true
	result["selective_field_apply"] = true
	result["update_original_after_review"] = true
	result["create_improved_copy"] = true
	result["replacement_compare_apply_reserved_v01536"] = false
	return result


func collaborator_source_capabilities_v01533() -> Dictionary:
	var result := super.collaborator_source_capabilities_v01533()
	result["refinement_compare_apply"] = true
	result["selective_refinement_apply"] = true
	result["update_original_after_review"] = true
	result["create_improved_copy"] = true
	result["refinement_compare_apply_reserved_v01536"] = false
	return result


func _clear_pending_completion_v01535() -> void:
	_refinement_proposal_v01536 = {}
	if _refinement_compare_window_v01536 != null and _refinement_compare_window_v01536.visible:
		_refinement_compare_window_v01536.hide()
	super._clear_pending_completion_v01535()


func _close_tool_windows_for_project_change() -> void:
	if (
		_refinement_compare_window_v01536 != null
		and _refinement_compare_window_v01536.visible
	):
		_refinement_compare_window_v01536.hide()
	_refinement_proposal_v01536 = {}
	super._close_tool_windows_for_project_change()
