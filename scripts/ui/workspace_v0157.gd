class_name CCFWorkspaceV0157View
extends "res://scripts/ui/workspace_v0156.gd"

const GENERATION_SERVICE_V0157 = preload("res://scripts/services/generation_service_v0157.gd")
const CHARACTER_COLLABORATOR_WINDOW_V0157 = preload("res://scripts/ui/character_collaborator_window_v0157.gd")


func _install_generation_service_v015() -> void:
	var previous_service: CCFGenerationService = _generation_service
	if previous_service != null and previous_service.get_script() == GENERATION_SERVICE_V0157:
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

	var upgraded: CCFGenerationService = GENERATION_SERVICE_V0157.new()
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
	if _generation_service == null or _generation_service.get_script() != GENERATION_SERVICE_V0157:
		_install_generation_service_v015()
	if _generation_service == null or _generation_service.get_script() != GENERATION_SERVICE_V0157:
		_status.text = "Character Collaborator could not activate the v0.15.7 Vision-capable generation service."
		return false
	if _character_collaborator_window != null:
		_character_collaborator_window.set_generation_service(_generation_service)
	return true


func _build_character_collaborator_window_v015() -> void:
	_character_collaborator_window = CHARACTER_COLLABORATOR_WINDOW_V0157.new()
	_character_collaborator_window.visible = false
	_character_collaborator_window.force_native = true
	_character_collaborator_window.transient = false
	_character_collaborator_window.exclusive = false
	_character_collaborator_window.set_generation_service(_generation_service)
	_character_collaborator_window.sessions_changed.connect(_on_collaborator_sessions_changed_v015)
	_character_collaborator_window.character_draft_ready.connect(_on_collaborator_character_draft_ready_v015)
	add_child(_character_collaborator_window)
	_character_collaborator_window.hide()
