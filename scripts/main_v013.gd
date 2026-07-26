extends "res://scripts/main_with_image_page.gd"


func _ready() -> void:
	super._ready()
	_install_generation_parity_service()


func _install_generation_parity_service() -> void:
	if _workspace == null:
		return
	var current_service: CCFGenerationService = _workspace._generation_service
	if current_service is CCFParityGenerationService:
		return

	if current_service != null:
		_disconnect_workspace_generation_signals(current_service)
		if current_service.get_parent() == _workspace:
			_workspace.remove_child(current_service)
		current_service.queue_free()

	var parity_service := CCFParityGenerationService.new()
	_workspace._generation_service = parity_service
	_workspace.add_child(parity_service)
	parity_service.job_started.connect(_workspace._on_job_started)
	parity_service.job_completed.connect(_workspace._on_job_completed)
	parity_service.job_failed.connect(_workspace._on_job_failed)
	parity_service.job_cancelled.connect(_workspace._on_job_cancelled)
	parity_service.queue_changed.connect(_workspace._on_queue_changed)

	_rebind_workspace_generation_clients(parity_service)


func _disconnect_workspace_generation_signals(service: CCFGenerationService) -> void:
	if service.job_started.is_connected(_workspace._on_job_started):
		service.job_started.disconnect(_workspace._on_job_started)
	if service.job_completed.is_connected(_workspace._on_job_completed):
		service.job_completed.disconnect(_workspace._on_job_completed)
	if service.job_failed.is_connected(_workspace._on_job_failed):
		service.job_failed.disconnect(_workspace._on_job_failed)
	if service.job_cancelled.is_connected(_workspace._on_job_cancelled):
		service.job_cancelled.disconnect(_workspace._on_job_cancelled)
	if service.queue_changed.is_connected(_workspace._on_queue_changed):
		service.queue_changed.disconnect(_workspace._on_queue_changed)


func _rebind_workspace_generation_clients(service: CCFGenerationService) -> void:
	var clients: Array[Variant] = [
		_workspace._builder_window,
		_workspace._controlled_build_window,
		_workspace._group_scene_window,
		_workspace._relationship_window,
		_workspace._card_workflow_window,
		_workspace._attachment_window
	]
	for client in clients:
		if client != null and client.has_method("set_generation_service"):
			client.call("set_generation_service", service)
