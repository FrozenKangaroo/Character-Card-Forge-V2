class_name CCFWorkspaceV01537View
extends "res://scripts/ui/workspace_v01536_hotfix3.gd"

const CHARACTER_COLLABORATOR_WINDOW_V01537 = preload(
	"res://scripts/ui/character_collaborator_window_v01537.gd"
)
const SOURCE_SERVICE_V01537 = preload(
	"res://scripts/services/collaborator_source_context_service_v01537.gd"
)

const AUTHOR_ADD_CHARACTER_SOURCE_MENU_ID_V01537 := 15370


func _ready() -> void:
	super._ready()
	_add_multi_source_author_menu_v01537()


func _build_character_collaborator_window_v015() -> void:
	_character_collaborator_window = CHARACTER_COLLABORATOR_WINDOW_V01537.new()
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


func _add_multi_source_author_menu_v01537() -> void:
	for node in find_children("*", "MenuButton", true, false):
		if not node is MenuButton or (node as MenuButton).text != "Author":
			continue
		var popup := (node as MenuButton).get_popup()
		popup.add_item(
			"Add Current Character to Open Collaborator…",
			AUTHOR_ADD_CHARACTER_SOURCE_MENU_ID_V01537
		)
		popup.id_pressed.connect(_on_multi_source_author_menu_v01537)
		return


func _on_multi_source_author_menu_v01537(id: int) -> void:
	if id != AUTHOR_ADD_CHARACTER_SOURCE_MENU_ID_V01537:
		return
	_add_current_character_source_v01537()


func _add_current_character_source_v01537() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		_status.text = "Open a character before adding it to Character Collaborator."
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_capture_project_name()
	var character := CCFStorageService.get_character(
		_project_container,
		_active_character_id
	)
	if character.is_empty():
		_status.text = "The active character could not be found."
		return
	var project_name := _project_display_name_v01535()
	var source := SOURCE_SERVICE_V01537.from_character(
		character,
		str(_project_container.get("project_id", "")),
		project_name,
		SOURCE_SERVICE_V01537.ROLE_REFERENCE
	)
	if source.is_empty():
		_status.text = "Could not build a structured Collaborator source from the active character."
		return
	_character_collaborator_window.open_for_project(
		_project_container,
		_settings,
		_active_character_id,
		_template
	)
	var result: Dictionary = _character_collaborator_window.call(
		"add_source_v01537",
		source,
		false
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not add character source to Collaborator."))
		return
	_status.text = "%s added to the open Collaborator conversation as a read-only reference." % CCFStorageService.character_display_name(character)


func add_collaborator_source_v01537(
	source: Dictionary,
	make_target: bool = false
) -> Dictionary:
	if _character_collaborator_window == null:
		return {"ok": false, "error": "Character Collaborator is unavailable."}
	if _project_container.is_empty() or _active_character_id.is_empty():
		return {"ok": false, "error": "Open a Character Project first."}
	_character_collaborator_window.open_for_project(
		_project_container,
		_settings,
		_active_character_id,
		_template
	)
	return _character_collaborator_window.call(
		"add_source_v01537",
		source,
		make_target
	)


func collaborator_source_capabilities_v01533() -> Dictionary:
	var result := super.collaborator_source_capabilities_v01533()
	result.merge(SOURCE_SERVICE_V01537.capabilities(), true)
	result["multi_source"] = true
	result["add_current_character_to_open_session"] = true
	result["single_explicit_refinement_target"] = true
	return result


func multi_source_collaborator_capabilities_v01537() -> Dictionary:
	return {
		"version": "0.15.37",
		"multi_source": true,
		"one_refinement_target": true,
		"additional_character_references": true,
		"saved_or_generated_idea_sources_supported": true,
		"pasted_source_supported": true,
		"json_png_card_sources_supported": true,
		"embedded_user_persona_excluded": true,
		"compare_apply_target_compatible_v01536": true
	}
