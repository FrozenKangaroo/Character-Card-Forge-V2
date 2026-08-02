class_name CCFWorkspaceV01512View
extends "res://scripts/ui/workspace_v01511.gd"

const GENERATION_SERVICE_V01512 = preload("res://scripts/services/generation_service_v01512.gd")


func _install_generation_service_v015() -> void:
	var previous_service: CCFGenerationService = _generation_service
	if previous_service != null and previous_service.get_script() == GENERATION_SERVICE_V01512:
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

	var upgraded: CCFGenerationService = GENERATION_SERVICE_V01512.new()
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
	if _generation_service == null or _generation_service.get_script() != GENERATION_SERVICE_V01512:
		_install_generation_service_v015()
	if _generation_service == null or _generation_service.get_script() != GENERATION_SERVICE_V01512:
		_status.text = "Character Collaborator could not activate the v0.15.12 generation service."
		return false
	if _character_collaborator_window != null:
		_character_collaborator_window.set_generation_service(_generation_service)
	return true


func _generate_character() -> void:
	if _project.is_empty():
		return
	_capture_all_fields()
	var profile := CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_TEXT)
	var retry_count := int(_generation_settings().get("retry_count", 1))
	var result: Dictionary = _generation_service.call(
		"queue_full_character_synthesis",
		_project,
		_template,
		profile,
		retry_count
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not queue full character synthesis."))
		return
	var queued_ahead := int(result.get("queued_ahead", 0))
	_status.text = (
		"Full character synthesis queued%s. All populated Workspace fields are being used as source material for the active template."
		% (" behind %d job(s)" % queued_ahead if queued_ahead > 0 else "")
	)
