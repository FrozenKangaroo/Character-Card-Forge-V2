class_name CCFWorkspaceV01516View
extends "res://scripts/ui/workspace_v01515.gd"

const GENERATION_SERVICE_V01516 = preload("res://scripts/services/generation_service_v01516.gd")


func _install_generation_service_v015() -> void:
	var previous_service: CCFGenerationService = _generation_service
	if previous_service != null and previous_service.get_script() == GENERATION_SERVICE_V01516:
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

	var upgraded: CCFGenerationService = GENERATION_SERVICE_V01516.new()
	add_child(upgraded)
	upgraded.job_started.connect(_on_job_started)
	upgraded.job_completed.connect(_on_job_completed)
	upgraded.job_failed.connect(_on_job_failed)
	upgraded.job_cancelled.connect(_on_job_cancelled)
	upgraded.queue_changed.connect(_on_queue_changed)
	_generation_service = upgraded

	# Rebind every known generation client, not only the Collaborator. The v0.14.13
	# regression was caused by runtime composition replacing the proven generation
	# service, so v0.15.16 keeps all authoring tools on the same restored instance.
	for client in [
		_builder_window,
		_controlled_build_window,
		_group_scene_window,
		_relationship_window,
		_card_workflow_window,
		_attachment_window,
		_character_collaborator_window
	]:
		if client != null and client.has_method("set_generation_service"):
			client.call("set_generation_service", _generation_service)
	_wire_ai_idea_controller_to_current_service()


func _ensure_collaborator_generation_service_v015() -> bool:
	if _generation_service == null or _generation_service.get_script() != GENERATION_SERVICE_V01516:
		_install_generation_service_v015()
	if _generation_service == null or _generation_service.get_script() != GENERATION_SERVICE_V01516:
		_status.text = "Character Collaborator could not activate the v0.15.16 restored generation service."
		return false
	if _character_collaborator_window != null:
		_character_collaborator_window.set_generation_service(_generation_service)
	return true


func _generate_character() -> void:
	if _project.is_empty():
		return
	_capture_all_fields()
	var profile := CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_TEXT)
	var generation_settings := _generation_settings()

	# v0.15.12 replaced this call with queue_full_character_synthesis(), which
	# bypassed the v0.13 parity pipeline. Route Generate Character back through
	# queue_character_generation() so the active template contract, Generation
	# Components, semantic validation/repair, Interview/Q&A, Builder precedence,
	# Mode & Style, and concept-fidelity checks all participate again.
	var result: Dictionary = _generation_service.queue_character_generation(
		_project,
		_template,
		profile,
		true,
		int(generation_settings.get("retry_count", 1))
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not queue validated character generation."))
		return
	var queued_ahead := int(result.get("queued_ahead", 0))
	_status.text = (
		"Validated template-driven character generation queued%s. Generation Components and the active template contract will be checked before anything reaches Generation Preview."
		% (" behind %d job(s)" % queued_ahead if queued_ahead > 0 else "")
	)
