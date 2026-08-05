class_name CCFWorkspaceV01535View
extends "res://scripts/ui/workspace_v01534.gd"

const CHARACTER_COLLABORATOR_WINDOW_V01535 = preload(
	"res://scripts/ui/character_collaborator_window_v01535.gd"
)
const COMPLETION_DESTINATION_WINDOW_V01535 = preload(
	"res://scripts/ui/collaborator_completion_destination_window_v01535.gd"
)
const COMPLETION_SERVICE_V01535 = preload(
	"res://scripts/services/collaborator_completion_service_v01535.gd"
)

const AUTHOR_PENDING_COMPLETION_MENU_ID_V01535 := 15350

var _completion_destination_window_v01535: CCFCollaboratorCompletionDestinationWindowV01535
var _pending_completion_payload_v01535: Dictionary = {}
var _pending_completion_source_v01535: Dictionary = {}
var _pending_completion_title_v01535 := ""
var _pending_completion_project_id_v01535 := ""


func _ready() -> void:
	super._ready()
	_build_completion_destination_window_v01535()
	_add_pending_completion_menu_v01535()
	_refresh_pending_completion_menu_v01535()


func _build_character_collaborator_window_v015() -> void:
	_character_collaborator_window = CHARACTER_COLLABORATOR_WINDOW_V01535.new()
	_character_collaborator_window.visible = false
	_character_collaborator_window.force_native = true
	_character_collaborator_window.transient = false
	_character_collaborator_window.exclusive = false
	_character_collaborator_window.set_generation_service(_generation_service)
	_character_collaborator_window.sessions_changed.connect(
		_on_collaborator_sessions_changed_v015
	)
	_character_collaborator_window.character_draft_ready.connect(
		_on_collaborator_character_draft_ready_v015
	)
	add_child(_character_collaborator_window)
	_character_collaborator_window.hide()


func _build_completion_destination_window_v01535() -> void:
	_completion_destination_window_v01535 = COMPLETION_DESTINATION_WINDOW_V01535.new()
	_completion_destination_window_v01535.visible = false
	_completion_destination_window_v01535.destination_selected.connect(
		_on_completion_destination_selected_v01535
	)
	_completion_destination_window_v01535.routing_cancelled.connect(
		_on_completion_routing_cancelled_v01535
	)
	add_child(_completion_destination_window_v01535)
	_completion_destination_window_v01535.hide()


func _add_pending_completion_menu_v01535() -> void:
	for node in find_children("*", "MenuButton", true, false):
		if not node is MenuButton:
			continue
		var menu := node as MenuButton
		if menu.text != "Author":
			continue
		var popup := menu.get_popup()
		popup.add_item(
			"Place Pending Collaborator Completion…",
			AUTHOR_PENDING_COMPLETION_MENU_ID_V01535
		)
		popup.id_pressed.connect(_on_pending_completion_menu_v01535)
		return


func _on_pending_completion_menu_v01535(id: int) -> void:
	if id != AUTHOR_PENDING_COMPLETION_MENU_ID_V01535:
		return
	_open_pending_completion_destination_v01535()


func _on_collaborator_character_draft_ready_v015(
	payload: Dictionary,
	session_title: String
) -> void:
	var handoff_mode := str(payload.get("handoff_mode", "")).strip_edges()
	if handoff_mode not in ["blueprint", "detailed_workspace_draft"]:
		super._on_collaborator_character_draft_ready_v015(payload, session_title)
		return
	if _project_container.is_empty() or _active_character_id.is_empty():
		_status.text = "Open or create a Character Project before placing the Collaborator completion."
		return

	_capture_all_fields()
	_commit_active_character_to_container()
	_capture_project_name()
	_pending_completion_payload_v01535 = payload.duplicate(true)
	_pending_completion_title_v01535 = session_title
	_pending_completion_project_id_v01535 = str(
		_project_container.get("project_id", "")
	)
	_pending_completion_source_v01535 = {}
	if (
		_character_collaborator_window != null
		and _character_collaborator_window.has_method("active_source_context_v01533")
	):
		var source_value: Variant = _character_collaborator_window.call(
			"active_source_context_v01533"
		)
		if source_value is Dictionary:
			_pending_completion_source_v01535 = (
				source_value as Dictionary
			).duplicate(true)
	_refresh_pending_completion_menu_v01535()
	_open_pending_completion_destination_v01535()
	_status.text = (
		"Collaborator completion is ready. Choose where to place it; an occupied current character will not be overwritten."
	)


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
	_completion_destination_window_v01535.open_for_completion_v01535(
		current_character,
		_template,
		project_name,
		current_name
	)


func _on_completion_destination_selected_v01535(destination_id: String) -> void:
	if _pending_completion_payload_v01535.is_empty():
		_status.text = "The pending Collaborator completion is no longer available."
		return
	var result := apply_collaborator_completion_v01535(
		_pending_completion_payload_v01535,
		_pending_completion_title_v01535,
		destination_id,
		_pending_completion_source_v01535
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not place the Collaborator completion."))
		return
	_clear_pending_completion_v01535()
	_status.text = str(result.get("message", "Collaborator completion placed in Workspace."))


func _on_completion_routing_cancelled_v01535() -> void:
	if _pending_completion_payload_v01535.is_empty():
		return
	_status.text = (
		"Collaborator completion kept pending. Use Author → Place Pending Collaborator Completion… when you are ready."
	)


func apply_collaborator_completion_v01535(
	payload: Dictionary,
	session_title: String,
	destination_id: String,
	source_context: Dictionary = {}
) -> Dictionary:
	if _project_container.is_empty() or _active_character_id.is_empty():
		return {"ok": false, "error": "No active Character Project is available."}
	_capture_all_fields()
	_commit_active_character_to_container()
	_capture_project_name()
	var current_character := CCFStorageService.get_character(
		_project_container,
		_active_character_id
	)
	if current_character.is_empty():
		return {"ok": false, "error": "The active character could not be found."}

	if destination_id == COMPLETION_SERVICE_V01535.DEST_CURRENT_EMPTY:
		if not COMPLETION_SERVICE_V01535.is_effectively_empty_character(
			current_character,
			_template
		):
			return {
				"ok": false,
				"error": "The current character is no longer empty, so it cannot be replaced by the safe empty-slot route. Choose Create New Character in This Project instead."
			}
		var materialised := COMPLETION_SERVICE_V01535.materialise_character(
			payload,
			session_title,
			_template,
			destination_id,
			source_context,
			current_character
		)
		if not bool(materialised.get("ok", false)):
			return materialised
		var character_value: Variant = materialised.get("character", {})
		if not character_value is Dictionary:
			return {"ok": false, "error": "Collaborator completion did not produce a character record."}
		var character: Dictionary = character_value
		if not _replace_character_record_v01535(
			_active_character_id,
			character
		):
			return {"ok": false, "error": "Could not populate the current empty character slot."}
		_reload_project_after_completion_v01535(
			str(character.get("character_id", _active_character_id))
		)
		return {
			"ok": true,
			"destination": destination_id,
			"character_id": str(character.get("character_id", "")),
			"message": "%s populated the current empty character slot. Review/edit it, then Save when ready." % str(materialised.get("display_name", "Collaborator Character"))
		}

	if destination_id == COMPLETION_SERVICE_V01535.DEST_SAME_PROJECT_NEW:
		var materialised := COMPLETION_SERVICE_V01535.materialise_character(
			payload,
			session_title,
			_template,
			destination_id,
			source_context
		)
		if not bool(materialised.get("ok", false)):
			return materialised
		var character_value: Variant = materialised.get("character", {})
		if not character_value is Dictionary:
			return {"ok": false, "error": "Collaborator completion did not produce a character record."}
		var character: Dictionary = character_value
		var characters: Array = _project_container.get("characters", []).duplicate(true)
		characters.append(character.duplicate(true))
		_project_container["characters"] = characters
		var character_id := str(character.get("character_id", ""))
		_reload_project_after_completion_v01535(character_id)
		return {
			"ok": true,
			"destination": destination_id,
			"character_id": character_id,
			"message": "%s was created as a new character in the current project. The previous character was left unchanged." % str(materialised.get("display_name", "Collaborator Character"))
		}

	if destination_id == COMPLETION_SERVICE_V01535.DEST_NEW_PROJECT:
		var materialised := COMPLETION_SERVICE_V01535.materialise_character(
			payload,
			session_title,
			_template,
			destination_id,
			source_context
		)
		if not bool(materialised.get("ok", false)):
			return materialised
		var character_value: Variant = materialised.get("character", {})
		if not character_value is Dictionary:
			return {"ok": false, "error": "Collaborator completion did not produce a character record."}
		var project := COMPLETION_SERVICE_V01535.new_project_for_character(
			character_value as Dictionary
		)
		if project.is_empty():
			return {"ok": false, "error": "Could not create the new Character Project."}
		var save_result := CCFStorageService.save_project(project)
		if not bool(save_result.get("ok", false)):
			return {
				"ok": false,
				"error": str(save_result.get("error", "Could not save the new Character Project."))
			}
		return {
			"ok": true,
			"destination": destination_id,
			"project_id": str(project.get("project_id", "")),
			"character_id": str((character_value as Dictionary).get("character_id", "")),
			"message": "%s was created as a separate Character Project in the Library. The current Workspace project was left unchanged." % str(materialised.get("display_name", "Collaborator Character"))
		}

	return {"ok": false, "error": "Unknown Collaborator completion destination."}


func collaborator_completion_capabilities_v01535() -> Dictionary:
	return COMPLETION_SERVICE_V01535.capabilities()


func collaborator_source_capabilities_v01533() -> Dictionary:
	var result := super.collaborator_source_capabilities_v01533()
	result["completion_routing"] = true
	result["empty_workspace_reuse"] = true
	result["same_project_new_character_default_when_occupied"] = true
	result["new_project_destination"] = true
	result["occupied_character_overwrite"] = false
	result["refinement_compare_apply_reserved_v01536"] = true
	return result


func _replace_character_record_v01535(
	character_id: String,
	replacement: Dictionary
) -> bool:
	var characters_value: Variant = _project_container.get("characters", [])
	if not characters_value is Array:
		return false
	var characters: Array = (characters_value as Array).duplicate(true)
	for index in range(characters.size()):
		var raw_character: Variant = characters[index]
		if (
			raw_character is Dictionary
			and str((raw_character as Dictionary).get("character_id", "")) == character_id
		):
			characters[index] = replacement.duplicate(true)
			_project_container["characters"] = characters
			return true
	return false


func _reload_project_after_completion_v01535(character_id: String) -> void:
	var workspace: Dictionary = _project_container.get("workspace", {}).duplicate(true)
	workspace["active_character_id"] = character_id
	_project_container["workspace"] = workspace
	var refreshed := _project_container.duplicate(true)
	load_project(refreshed, _template, _settings)
	_dirty = true


func _clear_pending_completion_v01535() -> void:
	_pending_completion_payload_v01535 = {}
	_pending_completion_source_v01535 = {}
	_pending_completion_title_v01535 = ""
	_pending_completion_project_id_v01535 = ""
	_refresh_pending_completion_menu_v01535()


func _refresh_pending_completion_menu_v01535() -> void:
	for node in find_children("*", "MenuButton", true, false):
		if not node is MenuButton or (node as MenuButton).text != "Author":
			continue
		var popup := (node as MenuButton).get_popup()
		for index in range(popup.item_count):
			if popup.get_item_id(index) == AUTHOR_PENDING_COMPLETION_MENU_ID_V01535:
				popup.set_item_disabled(
					index,
					_pending_completion_payload_v01535.is_empty()
				)
				return


func _project_display_name_v01535() -> String:
	var metadata_value: Variant = _project_container.get("metadata", {})
	if metadata_value is Dictionary:
		var project_name := str(
			(metadata_value as Dictionary).get("name", "")
		).strip_edges()
		if not project_name.is_empty():
			return project_name
	return "Untitled Project"


func _close_tool_windows_for_project_change() -> void:
	if (
		_completion_destination_window_v01535 != null
		and _completion_destination_window_v01535.visible
	):
		_completion_destination_window_v01535.hide()
	if (
		not _pending_completion_project_id_v01535.is_empty()
		and str(_project_container.get("project_id", "")) != _pending_completion_project_id_v01535
	):
		_clear_pending_completion_v01535()
	super._close_tool_windows_for_project_change()
