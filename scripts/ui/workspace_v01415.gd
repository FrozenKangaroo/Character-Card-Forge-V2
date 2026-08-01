class_name CCFWorkspaceV01415View
extends "res://scripts/ui/workspace_v01414.gd"

const LOREBOOK_WINDOW_V01415 = preload("res://scripts/ui/lorebook_window_v01415.gd")
const GENERATION_SERVICE_V01415 = preload("res://scripts/services/generation_service_v01415.gd")


func _ready() -> void:
	super._ready()
	_install_generation_service_v01415()


func _build_lorebook_window() -> void:
	_lorebook_window = LOREBOOK_WINDOW_V01415.new()
	_lorebook_window.lorebooks_saved.connect(_on_lorebooks_saved)
	add_child(_lorebook_window)
	_lorebook_window.hide()


func _install_generation_service_v01415() -> void:
	var previous_service: CCFGenerationService = _generation_service
	if previous_service != null and previous_service.get_script() == GENERATION_SERVICE_V01415:
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
	var upgraded: CCFGenerationService = GENERATION_SERVICE_V01415.new()
	add_child(upgraded)
	upgraded.job_started.connect(_on_job_started)
	upgraded.job_completed.connect(_on_job_completed)
	upgraded.job_failed.connect(_on_job_failed)
	upgraded.job_cancelled.connect(_on_job_cancelled)
	upgraded.queue_changed.connect(_on_queue_changed)
	_generation_service = upgraded
	if _builder_window != null:
		_builder_window.set_generation_service(_generation_service)
