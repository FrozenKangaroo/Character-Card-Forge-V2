class_name CCFWorkspaceV01525View
extends "res://scripts/ui/workspace_v01524.gd"

const GENERATION_SERVICE_V01525 = preload("res://scripts/services/generation_service_v01525.gd")
const GENERATION_DIAGNOSTICS_WINDOW_V01525 = preload("res://scripts/ui/generation_diagnostics_window_v01525.gd")


func _ready() -> void:
	super._ready()
	_ensure_token_budget_generation_service_v01525()
	_upgrade_generation_diagnostics_window_v01525()


func _generate_character() -> void:
	if not _ensure_token_budget_generation_service_v01525():
		return
	super._generate_character()


func _install_generation_service_v015() -> void:
	var previous_service: CCFGenerationService = _generation_service
	if previous_service != null and previous_service.get_script() == GENERATION_SERVICE_V01525:
		return
	var diagnostics_callable := Callable(self, "_on_generation_diagnostics_available_v01522")
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
		if previous_service.has_signal("diagnostics_available") and previous_service.is_connected("diagnostics_available", diagnostics_callable):
			previous_service.disconnect("diagnostics_available", diagnostics_callable)
		if previous_service.get_parent() == self:
			remove_child(previous_service)
		previous_service.queue_free()

	var upgraded: CCFGenerationService = GENERATION_SERVICE_V01525.new()
	add_child(upgraded)
	upgraded.job_started.connect(_on_job_started)
	upgraded.job_completed.connect(_on_job_completed)
	upgraded.job_failed.connect(_on_job_failed)
	upgraded.job_cancelled.connect(_on_job_cancelled)
	upgraded.queue_changed.connect(_on_queue_changed)
	upgraded.connect("diagnostics_available", diagnostics_callable)
	_generation_service = upgraded

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


func _ensure_token_budget_generation_service_v01525() -> bool:
	if not _has_token_budget_generation_service_v01525():
		_install_generation_service_v015()
	if not _has_token_budget_generation_service_v01525():
		if _status != null:
			_status.text = "Character Card Forge could not activate the v0.15.25 token-safe generation service. Restart the app and review Generation Diagnostics if the problem continues."
		return false
	return true


func _has_token_budget_generation_service_v01525() -> bool:
	if _generation_service == null:
		return false
	return (
		_generation_service is CCFGenerationServiceV01525
		and _generation_service.has_method("queue_character_generation_with_strategy")
		and _generation_service.has_method("generation_token_budget_capabilities_v01525")
		and _generation_service.has_signal("diagnostics_available")
	)


func _upgrade_generation_diagnostics_window_v01525() -> void:
	if (
		_generation_diagnostics_window_v01522 != null
		and _generation_diagnostics_window_v01522.get_script() == GENERATION_DIAGNOSTICS_WINDOW_V01525
	):
		return
	if _generation_diagnostics_window_v01522 != null:
		if _generation_diagnostics_window_v01522.get_parent() == self:
			remove_child(_generation_diagnostics_window_v01522)
		_generation_diagnostics_window_v01522.queue_free()
	_generation_diagnostics_window_v01522 = GENERATION_DIAGNOSTICS_WINDOW_V01525.new()
	add_child(_generation_diagnostics_window_v01522)
