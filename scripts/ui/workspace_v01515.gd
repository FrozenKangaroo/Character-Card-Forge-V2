class_name CCFWorkspaceV01515View
extends "res://scripts/ui/workspace_v01514.gd"

const GENERATION_SERVICE_V01515 = preload("res://scripts/services/generation_service_v01515.gd")
const CHARACTER_COLLABORATOR_WINDOW_V01515 = preload("res://scripts/ui/character_collaborator_window_v01515.gd")


func _install_generation_service_v015() -> void:
	var previous_service: CCFGenerationService = _generation_service
	if previous_service != null and previous_service.get_script() == GENERATION_SERVICE_V01515:
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

	var upgraded: CCFGenerationService = GENERATION_SERVICE_V01515.new()
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
	if _character_collaborator_window != null:
		_character_collaborator_window.set_generation_service(_generation_service)
	_wire_ai_idea_controller_to_current_service()


func _ensure_collaborator_generation_service_v015() -> bool:
	if _generation_service == null or _generation_service.get_script() != GENERATION_SERVICE_V01515:
		_install_generation_service_v015()
	if _generation_service == null or _generation_service.get_script() != GENERATION_SERVICE_V01515:
		_status.text = "Character Collaborator could not activate the v0.15.15 generation service."
		return false
	if _character_collaborator_window != null:
		_character_collaborator_window.set_generation_service(_generation_service)
	return true


func _build_character_collaborator_window_v015() -> void:
	_character_collaborator_window = CHARACTER_COLLABORATOR_WINDOW_V01515.new()
	_character_collaborator_window.visible = false
	_character_collaborator_window.force_native = true
	_character_collaborator_window.transient = false
	_character_collaborator_window.exclusive = false
	_character_collaborator_window.set_generation_service(_generation_service)
	_character_collaborator_window.sessions_changed.connect(_on_collaborator_sessions_changed_v015)
	_character_collaborator_window.character_draft_ready.connect(_on_collaborator_character_draft_ready_v015)
	add_child(_character_collaborator_window)
	_character_collaborator_window.hide()


func _on_collaborator_character_draft_ready_v015(payload: Dictionary, session_title: String) -> void:
	var handoff_mode := str(payload.get("handoff_mode", "")).strip_edges()
	if handoff_mode == "blueprint":
		_apply_collaborator_blueprint_v01515(payload, session_title)
		return
	if handoff_mode == "detailed_workspace_draft":
		_apply_collaborator_detailed_draft_v01515(payload, session_title)
		return
	super._on_collaborator_character_draft_ready_v015(payload, session_title)


func _apply_collaborator_blueprint_v01515(payload: Dictionary, session_title: String) -> void:
	if _project_container.is_empty():
		return
	var concept_prompt := str(payload.get("concept_prompt", "")).strip_edges()
	if concept_prompt.is_empty():
		_status.text = "Character Collaborator returned a Blueprint without a usable Generation Concept."
		return

	var suggested_name := str(payload.get("suggested_name", "")).strip_edges()
	var fallback_name := session_title.strip_edges()
	if fallback_name.is_empty():
		fallback_name = "Collaborator Character"
	var display_name := suggested_name if not suggested_name.is_empty() else fallback_name
	var created := CCFStorageService.new_character_record(display_name)
	CCFStorageService.set_value_at_path(created, "concept.prompt", concept_prompt)
	CCFStorageService.set_value_at_path(created, "metadata.name", display_name)
	CCFStorageService.set_value_at_path(created, "character.name", display_name)

	var provenance: Dictionary = created.get("provenance", {}).duplicate(true)
	provenance["character_collaborator"] = {
		"source": "character_collaborator_v01515",
		"handoff_mode": "blueprint",
		"session_title": session_title,
		"generated_at": Time.get_datetime_string_from_system(true)
	}
	created["provenance"] = provenance

	var characters: Array = _project_container.get("characters", []).duplicate(true)
	characters.append(created)
	_project_container["characters"] = characters
	_dirty = true
	_switch_active_character(str(created.get("character_id", "")))
	_status.text = "%s was created from the Collaborator as a detailed Generation Blueprint. Review Generation Concept, then use Generate Character to materialise the final card." % display_name


func _apply_collaborator_detailed_draft_v01515(payload: Dictionary, session_title: String) -> void:
	if _project_container.is_empty():
		return
	var fields_value: Variant = payload.get("fields", {})
	if not fields_value is Dictionary:
		_status.text = "Character Collaborator returned a detailed draft without usable template fields."
		return
	var fields: Dictionary = fields_value
	var fallback_name := session_title.strip_edges()
	if fallback_name.is_empty():
		fallback_name = "Collaborator Character"
	var created := CCFStorageService.new_character_record(fallback_name)
	var generated_name := str(payload.get("suggested_name", "")).strip_edges()

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
		if field_path in ["character.name", "metadata.name"]:
			generated_name = str(value).strip_edges()

	var concept_prompt := str(payload.get("concept_prompt", "")).strip_edges()
	if not concept_prompt.is_empty():
		CCFStorageService.set_value_at_path(created, "concept.prompt", concept_prompt)

	var alternatives: Array[String] = []
	var alternatives_value: Variant = payload.get("alternate_greetings", [])
	if alternatives_value is Array:
		for raw_greeting in alternatives_value:
			var greeting := str(raw_greeting).strip_edges()
			if not greeting.is_empty():
				alternatives.append(greeting)
	CCFStorageService.set_value_at_path(created, "character.alternate_greetings", alternatives)

	var lorebook_value: Variant = payload.get("lorebook", {})
	if lorebook_value is Dictionary:
		var lorebook: Dictionary = (lorebook_value as Dictionary).duplicate(true)
		if not lorebook.get("entries", []) is Array:
			lorebook["entries"] = []
		CCFStorageService.set_value_at_path(created, "character.character_book", lorebook)

	if generated_name.is_empty():
		generated_name = str(CCFStorageService.get_value_at_path(created, "character.name", "")).strip_edges()
	if generated_name.is_empty():
		generated_name = fallback_name
	CCFStorageService.set_value_at_path(created, "metadata.name", generated_name)
	CCFStorageService.set_value_at_path(created, "character.name", generated_name)

	var provenance: Dictionary = created.get("provenance", {}).duplicate(true)
	provenance["character_collaborator"] = {
		"source": "character_collaborator_v01515",
		"handoff_mode": "detailed_workspace_draft",
		"session_title": session_title,
		"generated_at": Time.get_datetime_string_from_system(true),
		"alternate_greetings_count": alternatives.size(),
		"lorebook_entries_count": _lorebook_entry_count_v01515(lorebook_value)
	}
	created["provenance"] = provenance

	var characters: Array = _project_container.get("characters", []).duplicate(true)
	characters.append(created)
	_project_container["characters"] = characters
	_dirty = true
	_switch_active_character(str(created.get("character_id", "")))
	_status.text = "Character Collaborator created a detailed Workspace draft for %s with %d Alternative Greeting(s) and %d Lorebook entr%s. Review/edit before saving." % [
		generated_name,
		alternatives.size(),
		_lorebook_entry_count_v01515(lorebook_value),
		"y" if _lorebook_entry_count_v01515(lorebook_value) == 1 else "ies"
	]


func _lorebook_entry_count_v01515(value: Variant) -> int:
	if not value is Dictionary:
		return 0
	var entries_value: Variant = (value as Dictionary).get("entries", [])
	return entries_value.size() if entries_value is Array else 0
