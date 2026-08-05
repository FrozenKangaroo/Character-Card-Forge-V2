class_name CCFWorkspaceV01534View
extends "res://scripts/ui/workspace_v01533_hotfix3.gd"

const CHARACTER_COLLABORATOR_WINDOW_V01534 = preload(
	"res://scripts/ui/character_collaborator_window_v01534.gd"
)
const EXISTING_CHARACTER_COLLABORATOR_WINDOW_V01534 = preload(
	"res://scripts/ui/existing_character_collaborator_window_v01534.gd"
)
const CHARACTER_INTENT_SERVICE_V01534 = preload(
	"res://scripts/services/collaborator_character_intent_service_v01534.gd"
)

const AUTHOR_EXISTING_CHARACTER_COLLABORATOR_MENU_ID_V01534 := 15340

var _existing_character_collaborator_window_v01534: CCFExistingCharacterCollaboratorWindowV01534


func _ready() -> void:
	super._ready()
	_build_existing_character_collaborator_window_v01534()
	_add_existing_character_collaborator_menu_v01534()


func _build_character_collaborator_window_v015() -> void:
	_character_collaborator_window = CHARACTER_COLLABORATOR_WINDOW_V01534.new()
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


func _build_existing_character_collaborator_window_v01534() -> void:
	_existing_character_collaborator_window_v01534 = (
		EXISTING_CHARACTER_COLLABORATOR_WINDOW_V01534.new()
	)
	_existing_character_collaborator_window_v01534.visible = false
	_existing_character_collaborator_window_v01534.develop_requested.connect(
		_on_existing_character_collaborator_requested_v01534
	)
	add_child(_existing_character_collaborator_window_v01534)
	_existing_character_collaborator_window_v01534.hide()


func _add_existing_character_collaborator_menu_v01534() -> void:
	for node in find_children("*", "MenuButton", true, false):
		if not node is MenuButton:
			continue
		var menu := node as MenuButton
		if menu.text != "Author":
			continue
		var popup := menu.get_popup()
		popup.add_separator()
		popup.add_item(
			"Develop Current Character in Collaborator…",
			AUTHOR_EXISTING_CHARACTER_COLLABORATOR_MENU_ID_V01534
		)
		popup.id_pressed.connect(_on_existing_character_collaborator_menu_v01534)
		return


func _on_existing_character_collaborator_menu_v01534(id: int) -> void:
	if id != AUTHOR_EXISTING_CHARACTER_COLLABORATOR_MENU_ID_V01534:
		return
	_open_existing_character_collaborator_v01534()


func _open_existing_character_collaborator_v01534() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		if _status != null:
			_status.text = "Open a character before developing it in Character Collaborator."
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_capture_project_name()
	var source := CCFStorageService.get_character(
		_project_container, _active_character_id
	)
	if source.is_empty():
		if _status != null:
			_status.text = "The active character could not be found."
		return
	var source_name := CCFStorageService.character_display_name(source)
	_existing_character_collaborator_window_v01534.open_for_character_v01534(
		source_name
	)
	if _status != null:
		_status.text = (
			"Choose how to develop %s in Collaborator. The source card remains read-only."
		) % source_name


func _on_existing_character_collaborator_requested_v01534(
	options: Dictionary
) -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_capture_project_name()
	var source := CCFStorageService.get_character(
		_project_container, _active_character_id
	)
	if source.is_empty():
		if _status != null:
			_status.text = "The existing character source could not be found."
		return
	var source_name := CCFStorageService.character_display_name(source)
	var project_id := str(_project_container.get("project_id", ""))
	var project_name := str(_project_container.get("name", "")).strip_edges()
	if project_name.is_empty():
		var metadata_value: Variant = _project_container.get("metadata", {})
		if metadata_value is Dictionary:
			project_name = str(
				(metadata_value as Dictionary).get("name", "")
			).strip_edges()
	var structured_source := CHARACTER_INTENT_SERVICE_V01534.build_source(
		source,
		project_id,
		project_name,
		source_name,
		options
	)
	if structured_source.is_empty():
		if _status != null:
			_status.text = "Could not build a structured Collaborator source from the active character."
		return
	var result := open_collaborator_with_source_v01533(structured_source)
	if bool(result.get("ok", false)) and _status != null:
		_status.text = (
			"Character Collaborator opened from %s with starting direction: %s. The source snapshot is read-only."
		) % [
			source_name,
			str(options.get("intent_label", "Existing character development"))
		]


func build_existing_character_source_v01534(
	character: Dictionary,
	project_id: String,
	project_name: String,
	source_name: String,
	options: Dictionary
) -> Dictionary:
	return CHARACTER_INTENT_SERVICE_V01534.build_source(
		character,
		project_id,
		project_name,
		source_name,
		options
	)


func collaborator_source_capabilities_v01533() -> Dictionary:
	return {
		"format_version": 1,
		"generated_idea_handoff": true,
		"saved_idea_handoff": true,
		"structured_builder_handoff": true,
		"existing_character_source_schema": true,
		"existing_character_workspace_action": true,
		"existing_character_author_intents": true,
		"derivation_provenance_compatible_v01410": true,
		"multi_source": false
	}


func existing_character_collaborator_capabilities_v01534() -> Dictionary:
	return CHARACTER_INTENT_SERVICE_V01534.capabilities()


func _close_tool_windows_for_project_change() -> void:
	if (
		_existing_character_collaborator_window_v01534 != null
		and _existing_character_collaborator_window_v01534.visible
	):
		_existing_character_collaborator_window_v01534.hide()
	super._close_tool_windows_for_project_change()
