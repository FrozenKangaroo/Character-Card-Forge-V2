class_name CCFWorkspaceV015View
extends "res://scripts/ui/workspace_v01422.gd"

const GENERATION_SERVICE_V015 = preload("res://scripts/services/generation_service_v015.gd")
const CHARACTER_COLLABORATOR_WINDOW_V015 = preload("res://scripts/ui/character_collaborator_window_v015.gd")
const AUTHOR_COLLABORATOR_MENU_ID := 15000

var _character_collaborator_window: CCFCharacterCollaboratorWindowV015


func _ready() -> void:
	super._ready()
	_install_generation_service_v015()
	_build_character_collaborator_window_v015()
	_add_character_collaborator_menu_v015()
	call_deferred("_wire_ai_idea_controller_to_current_service")


func _install_generation_service_v015() -> void:
	var previous_service: CCFGenerationService = _generation_service
	if previous_service != null and previous_service.get_script() == GENERATION_SERVICE_V015:
		return
	if previous_service != null:
		if previous_service.job_started.is_connected(_on_job_started):
			previous_service.job_started.disconnect(_on_job_started)
		if previous_service.job_completed.is_connected(_on_job_completed):
			previous_service.job_completed.disconnect(_on_job_completed)
		if previous_service.job_failed.is_connected(_on_job_failed):
			previous_service.job_failed.disconnect(_on_job_failed)
		if previous_service.job_cancelled.is_connected(_on_job_cancelled):
			previous_service.job_cancelled.disconnect(_on_job_cancelled)
		if previous_service.queue_changed.is_connected(_on_queue_changed):
			previous_service.queue_changed.disconnect(_on_queue_changed)
		if previous_service.get_parent() == self:
			remove_child(previous_service)
		previous_service.queue_free()
	var upgraded: CCFGenerationService = GENERATION_SERVICE_V015.new()
	add_child(upgraded)
	upgraded.job_started.connect(_on_job_started)
	upgraded.job_completed.connect(_on_job_completed)
	upgraded.job_failed.connect(_on_job_failed)
	upgraded.job_cancelled.connect(_on_job_cancelled)
	upgraded.queue_changed.connect(_on_queue_changed)
	_generation_service = upgraded
	if _builder_window != null:
		_builder_window.set_generation_service(_generation_service)
	if _attachment_window != null:
		_attachment_window.set_generation_service(_generation_service)
	_wire_ai_idea_controller_to_current_service()


func _build_character_collaborator_window_v015() -> void:
	_character_collaborator_window = CHARACTER_COLLABORATOR_WINDOW_V015.new()
	_character_collaborator_window.visible = false
	_character_collaborator_window.force_native = true
	_character_collaborator_window.transient = false
	_character_collaborator_window.exclusive = false
	_character_collaborator_window.set_generation_service(_generation_service)
	_character_collaborator_window.sessions_changed.connect(_on_collaborator_sessions_changed_v015)
	_character_collaborator_window.character_draft_ready.connect(_on_collaborator_character_draft_ready_v015)
	add_child(_character_collaborator_window)
	_character_collaborator_window.hide()


func _add_character_collaborator_menu_v015() -> void:
	for node in find_children("*", "MenuButton", true, false):
		if not node is MenuButton:
			continue
		var menu := node as MenuButton
		if menu.text != "Author":
			continue
		var popup_menu := menu.get_popup()
		popup_menu.add_separator()
		popup_menu.add_item("Character Collaborator…", AUTHOR_COLLABORATOR_MENU_ID)
		popup_menu.id_pressed.connect(_on_author_collaborator_menu_v015)
		return


func _on_author_collaborator_menu_v015(id: int) -> void:
	if id != AUTHOR_COLLABORATOR_MENU_ID:
		return
	_open_character_collaborator_v015()


func _open_character_collaborator_v015() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	_capture_project_name()
	_character_collaborator_window.set_generation_service(_generation_service)
	_character_collaborator_window.open_for_project(_project_container, _settings, _active_character_id, _template)
	_status.text = "Character Collaborator opened. Brainstorm freely; project data changes only when you explicitly generate a character into Workspace."


func _on_collaborator_sessions_changed_v015(sessions: Array) -> void:
	_project_container["collaborator_sessions"] = sessions.duplicate(true)
	_dirty = true


func _on_collaborator_character_draft_ready_v015(payload: Dictionary, session_title: String) -> void:
	if _project_container.is_empty():
		return
	var fields_value: Variant = payload.get("fields", {})
	if not fields_value is Dictionary:
		_status.text = "Character Collaborator returned a draft without usable fields."
		return
	var fields: Dictionary = fields_value
	var fallback_name := session_title.strip_edges()
	if fallback_name.is_empty():
		fallback_name = "Collaborator Character"
	var created := CCFStorageService.new_character_record(fallback_name)
	var generated_name := ""
	for raw_field in CCFTemplateService.generation_fields(_template):
		if not raw_field is Dictionary:
			continue
		var field: Dictionary = raw_field
		var field_id := str(field.get("id", "")).strip_edges()
		var field_path := str(field.get("path", "")).strip_edges()
		if field_id.is_empty() or field_path.is_empty() or not fields.has(field_id):
			continue
		var value: Variant = fields.get(field_id)
		CCFStorageService.set_value_at_path(created, field_path, value)
		if field_path == "character.name" or field_path == "metadata.name":
			generated_name = str(value).strip_edges()
	var concept_prompt := str(payload.get("concept_prompt", "")).strip_edges()
	if not concept_prompt.is_empty():
		CCFStorageService.set_value_at_path(created, "concept.prompt", concept_prompt)
	if generated_name.is_empty():
		generated_name = str(CCFStorageService.get_value_at_path(created, "character.name", "")).strip_edges()
	if generated_name.is_empty():
		generated_name = fallback_name
	CCFStorageService.set_value_at_path(created, "metadata.name", generated_name)
	CCFStorageService.set_value_at_path(created, "character.name", generated_name)
	var provenance: Dictionary = created.get("provenance", {}).duplicate(true)
	provenance["character_collaborator"] = {
		"source": "character_collaborator_v015",
		"session_title": session_title,
		"generated_at": Time.get_datetime_string_from_system(true)
	}
	created["provenance"] = provenance
	var characters: Array = _project_container.get("characters", []).duplicate(true)
	characters.append(created)
	_project_container["characters"] = characters
	_dirty = true
	_switch_active_character(str(created.get("character_id", "")))
	_status.text = "Character Collaborator generated %s and sent the new draft to Workspace for normal review/editing." % generated_name


func _update_project_level_window_contexts() -> void:
	super._update_project_level_window_contexts()
	if _character_collaborator_window != null and _character_collaborator_window.visible:
		_character_collaborator_window.update_project_context(_project_container, _settings, _active_character_id, _template)


func _close_tool_windows_for_project_change() -> void:
	if _character_collaborator_window != null and _character_collaborator_window.visible:
		_character_collaborator_window.hide()
	super._close_tool_windows_for_project_change()
