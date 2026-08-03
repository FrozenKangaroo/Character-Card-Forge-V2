class_name CCFWorkspaceV01526View
extends "res://scripts/ui/workspace_v01525.gd"

const GENERATION_SERVICE_V01526 = preload(
	"res://scripts/services/generation_service_v01526.gd"
)
const AI_SCHEDULER_V01526 = preload(
	"res://scripts/services/ai_job_scheduler_v01526.gd"
)

var _ai_scheduler_v01526: CCFAIJobSchedulerV01526
var _primary_service_v01526: CCFGenerationServiceV01526
var _collaborator_service_v01526: CCFGenerationServiceV01526
var _idea_service_v01526: CCFGenerationServiceV01526
var _tools_service_v01526: CCFGenerationServiceV01526
var _vision_service_v01526: CCFGenerationServiceV01526
var _worker_services_v01526: Array = []


func _ready() -> void:
	super._ready()
	_install_generation_service_v015()
	_rebind_concurrent_clients_v01526()
	_configure_scheduler_from_settings_v01526()
	_upgrade_cancel_control_v01526()
	_refresh_aggregate_queue_status_v01526()


func load_project(project: Dictionary, template: Dictionary, settings: Dictionary) -> void:
	super.load_project(project, template, settings)
	_configure_scheduler_from_settings_v01526()


func update_settings(settings: Dictionary) -> void:
	super.update_settings(settings)
	_configure_scheduler_from_settings_v01526()


func ai_scheduler_v01526() -> CCFAIJobSchedulerV01526:
	return _ai_scheduler_v01526


func concurrent_services_v01526() -> Dictionary:
	return {
		"primary": _primary_service_v01526,
		"collaborator": _collaborator_service_v01526,
		"ideas": _idea_service_v01526,
		"tools": _tools_service_v01526,
		"vision": _vision_service_v01526
	}


func _install_generation_service_v015() -> void:
	if _has_concurrent_services_v01526():
		_generation_service = _primary_service_v01526
		_rebind_concurrent_clients_v01526()
		return
	_ensure_scheduler_v01526()
	_dispose_generation_services_v01526()

	_primary_service_v01526 = _create_worker_service_v01526(
		"primary", "Character generation", 100000
	)
	_collaborator_service_v01526 = _create_worker_service_v01526(
		"collaborator", "Character Collaborator", 200000
	)
	_idea_service_v01526 = _create_worker_service_v01526(
		"ideas", "Idea Generator", 300000
	)
	_tools_service_v01526 = _create_worker_service_v01526(
		"tools", "Authoring AI tool", 400000
	)
	_vision_service_v01526 = _create_worker_service_v01526(
		"vision", "Vision analysis", 500000
	)
	_worker_services_v01526 = [
		_primary_service_v01526,
		_collaborator_service_v01526,
		_idea_service_v01526,
		_tools_service_v01526,
		_vision_service_v01526
	]
	_generation_service = _primary_service_v01526
	_rebind_concurrent_clients_v01526()
	_refresh_aggregate_queue_status_v01526()


func _ensure_scheduler_v01526() -> void:
	if _ai_scheduler_v01526 != null:
		return
	_ai_scheduler_v01526 = AI_SCHEDULER_V01526.new()
	add_child(_ai_scheduler_v01526)
	_ai_scheduler_v01526.state_changed.connect(_on_scheduler_state_changed_v01526)


func _create_worker_service_v01526(
	worker_id: String, worker_label: String, job_number_base: int
) -> CCFGenerationServiceV01526:
	var service := GENERATION_SERVICE_V01526.new() as CCFGenerationServiceV01526
	add_child(service)
	service.configure_scheduler_v01526(
		_ai_scheduler_v01526, worker_id, worker_label, job_number_base
	)
	service.job_started.connect(_on_job_started)
	service.job_completed.connect(_on_job_completed)
	service.job_failed.connect(_on_job_failed)
	service.job_cancelled.connect(_on_job_cancelled)
	service.queue_changed.connect(_on_worker_queue_changed_v01526)
	service.diagnostics_available.connect(_on_generation_diagnostics_available_v01522)
	return service


func _dispose_generation_services_v01526() -> void:
	var candidates: Array = []
	if _generation_service != null:
		candidates.append(_generation_service)
	for service in _worker_services_v01526:
		if service != null and service not in candidates:
			candidates.append(service)
	for service_value in candidates:
		if not service_value is CCFGenerationService:
			continue
		var service := service_value as CCFGenerationService
		_disconnect_worker_service_v01526(service)
		if service.get_parent() == self:
			remove_child(service)
		service.queue_free()
	_worker_services_v01526.clear()
	_primary_service_v01526 = null
	_collaborator_service_v01526 = null
	_idea_service_v01526 = null
	_tools_service_v01526 = null
	_vision_service_v01526 = null
	_generation_service = null


func _disconnect_worker_service_v01526(service: CCFGenerationService) -> void:
	if service.job_started.is_connected(_on_job_started):
		service.job_started.disconnect(_on_job_started)
	if service.job_completed.is_connected(_on_job_completed):
		service.job_completed.disconnect(_on_job_completed)
	if service.job_failed.is_connected(_on_job_failed):
		service.job_failed.disconnect(_on_job_failed)
	if service.job_cancelled.is_connected(_on_job_cancelled):
		service.job_cancelled.disconnect(_on_job_cancelled)
	if service.queue_changed.is_connected(_on_queue_changed):
		service.queue_changed.disconnect(_on_queue_changed)
	if service.queue_changed.is_connected(_on_worker_queue_changed_v01526):
		service.queue_changed.disconnect(_on_worker_queue_changed_v01526)
	var diagnostic_callable := Callable(self, "_on_generation_diagnostics_available_v01522")
	if service.has_signal("diagnostics_available") and service.is_connected(
		"diagnostics_available", diagnostic_callable
	):
		service.disconnect("diagnostics_available", diagnostic_callable)


func _has_concurrent_services_v01526() -> bool:
	if _ai_scheduler_v01526 == null:
		return false
	for service in [
		_primary_service_v01526,
		_collaborator_service_v01526,
		_idea_service_v01526,
		_tools_service_v01526,
		_vision_service_v01526
	]:
		if not _service_has_v01526_capabilities(service):
			return false
	return true


func _service_has_v01526_capabilities(service: Variant) -> bool:
	if service == null or not service is CCFGenerationService:
		return false
	return (
		service.has_method("queue_character_generation_with_strategy")
		and service.has_method("queue_collaborator_reply")
		and service.has_method("generation_token_budget_capabilities_v01525")
		and service.has_method("concurrent_capabilities_v01526")
		and service.has_signal("diagnostics_available")
	)


func _rebind_concurrent_clients_v01526() -> void:
	if not _has_concurrent_services_v01526():
		return
	_generation_service = _primary_service_v01526
	for client in [
		_builder_window,
		_controlled_build_window,
		_group_scene_window,
		_relationship_window,
		_card_workflow_window
	]:
		if client != null and client.has_method("set_generation_service"):
			client.call("set_generation_service", _tools_service_v01526)
	if _attachment_window != null and _attachment_window.has_method("set_generation_service"):
		_attachment_window.call("set_generation_service", _vision_service_v01526)
	if (
		_character_collaborator_window != null
		and _character_collaborator_window.has_method("set_generation_service")
	):
		_character_collaborator_window.call(
			"set_generation_service", _collaborator_service_v01526
		)
	_wire_ai_idea_controller_to_current_service()


func _ensure_collaborator_generation_service_v015() -> bool:
	if not _service_has_v01526_capabilities(_collaborator_service_v01526):
		_install_generation_service_v015()
	if not _service_has_v01526_capabilities(_collaborator_service_v01526):
		if _status != null:
			_status.text = "Character Collaborator could not activate a compatible concurrent generation service."
		return false
	if _character_collaborator_window != null:
		_character_collaborator_window.set_generation_service(
			_collaborator_service_v01526
		)
	return true


func _open_character_collaborator_v015() -> void:
	if _project_container.is_empty():
		return
	if not _ensure_collaborator_generation_service_v015():
		return
	_commit_active_character_to_container()
	_capture_project_name()
	_character_collaborator_window.set_generation_service(
		_collaborator_service_v01526
	)
	_character_collaborator_window.open_for_project(
		_project_container, _settings, _active_character_id, _template
	)
	_status.text = "Character Collaborator opened. It can run alongside other eligible AI jobs; project data changes only when you explicitly apply or generate material."


func _wire_ai_idea_controller_to_current_service() -> void:
	if _idea_service_v01526 == null:
		return
	var legacy_window := _find_legacy_ai_idea_window()
	if legacy_window == null:
		return
	if legacy_window.has_method("set_generation_service"):
		legacy_window.call("set_generation_service", _idea_service_v01526)
		return
	for property_info in legacy_window.get_property_list():
		if not property_info is Dictionary:
			continue
		var property_name := str(property_info.get("name", ""))
		if property_name == "_generation_service" or property_name == "generation_service":
			legacy_window.set(property_name, _idea_service_v01526)
			return


func _configure_scheduler_from_settings_v01526() -> void:
	_ensure_scheduler_v01526()
	var generation_value: Variant = _settings.get("generation", {})
	var raw_config: Variant = {}
	if generation_value is Dictionary:
		raw_config = generation_value.get("ai_concurrency", {})
	_ai_scheduler_v01526.configure(raw_config)


func _upgrade_cancel_control_v01526() -> void:
	if _cancel_button == null:
		return
	if _cancel_button.pressed.is_connected(_cancel_active_job):
		_cancel_button.pressed.disconnect(_cancel_active_job)
	if not _cancel_button.pressed.is_connected(_cancel_all_generation_v01526):
		_cancel_button.pressed.connect(_cancel_all_generation_v01526)
	_cancel_button.text = "Cancel AI Queue"
	_cancel_button.tooltip_text = "Cancel running and queued Text/Vision jobs. Image Studio retains its own Cancel control."


func _cancel_all_generation_v01526() -> void:
	for service_value in _worker_services_v01526:
		if not service_value is CCFGenerationServiceV01526:
			continue
		var service := service_value as CCFGenerationServiceV01526
		service.clear_pending_jobs()
		if service.has_active_job():
			service.cancel_active_job()
	_refresh_aggregate_queue_status_v01526()


func _on_worker_queue_changed_v01526(
	_pending_count: int, _active_job_id: String, _active_label: String
) -> void:
	_refresh_aggregate_queue_status_v01526()


func _on_scheduler_state_changed_v01526(_snapshot: Dictionary) -> void:
	_refresh_aggregate_queue_status_v01526()


func _refresh_aggregate_queue_status_v01526() -> void:
	if _queue_status == null or _cancel_button == null:
		return
	var snapshot := (
		_ai_scheduler_v01526.snapshot()
		if _ai_scheduler_v01526 != null
		else {"running": 0, "waiting": 0}
	)
	var internal_pending := 0
	var has_active_or_pending := false
	for service_value in _worker_services_v01526:
		if not service_value is CCFGenerationService:
			continue
		var service := service_value as CCFGenerationService
		internal_pending += service.pending_count()
		has_active_or_pending = (
			has_active_or_pending
			or service.has_active_job()
			or service.pending_count() > 0
		)
	var running := int(snapshot.get("running", 0))
	var queued := int(snapshot.get("waiting", 0)) + internal_pending
	if running <= 0 and queued <= 0 and not has_active_or_pending:
		_queue_status.text = "AI queue: idle"
		_cancel_button.disabled = true
		return
	_queue_status.text = "AI jobs: %d running • %d queued" % [running, queued]
	_cancel_button.disabled = false
