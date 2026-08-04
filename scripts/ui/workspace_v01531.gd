class_name CCFWorkspaceV01531View
extends "res://scripts/ui/workspace_v01526.gd"

const GENERATION_SERVICE_V01531 = preload(
	"res://scripts/services/generation_service_v01531.gd"
)
const AI_JOBS_PANEL_V01531 = preload(
	"res://scripts/ui/ai_jobs_panel_v01531.gd"
)

var _ai_jobs_panel_v01531: CCFAIJobsPanelV01531
var _ai_jobs_toggle_v01531: Button
var _image_jobs_controller_v01531: Node


func _ready() -> void:
	super._ready()
	_install_ai_jobs_panel_v01531()
	_refresh_ai_jobs_panel_v01531()


func set_image_jobs_controller_v01531(controller: Node) -> void:
	_image_jobs_controller_v01531 = controller
	_refresh_ai_jobs_panel_v01531()


func ai_jobs_panel_v01531() -> CCFAIJobsPanelV01531:
	return _ai_jobs_panel_v01531


func ai_job_records_v01531() -> Array:
	var records: Array = []
	for service_value in _worker_services_v01526:
		if not service_value is CCFGenerationServiceV01526:
			continue
		var service: CCFGenerationServiceV01526 = (
			service_value as CCFGenerationServiceV01526
		)
		if not service.has_method("job_records_v01531"):
			continue
		var service_records: Variant = service.call("job_records_v01531")
		if service_records is Array:
			records.append_array(service_records)
	if (
		_image_jobs_controller_v01531 != null
		and is_instance_valid(_image_jobs_controller_v01531)
		and _image_jobs_controller_v01531.has_method("ai_job_records_v01531")
	):
		var image_records: Variant = _image_jobs_controller_v01531.call(
			"ai_job_records_v01531"
		)
		if image_records is Array:
			records.append_array(image_records)
	return records


func cancel_ai_job_v01531(
	worker_id: String, cancel_job_id: String, _record_id: String = ""
) -> bool:
	var clean_worker: String = worker_id.strip_edges()
	var clean_job: String = cancel_job_id.strip_edges()
	for service_value in _worker_services_v01526:
		if not service_value is CCFGenerationServiceV01526:
			continue
		var service: CCFGenerationServiceV01526 = (
			service_value as CCFGenerationServiceV01526
		)
		if (
			not service.has_method("worker_identity_v01531")
			or not service.has_method("cancel_job_v01531")
		):
			continue
		var identity_value: Variant = service.call("worker_identity_v01531")
		var identity: Dictionary = (
			identity_value if identity_value is Dictionary else {}
		)
		if str(identity.get("worker_id", "")) != clean_worker:
			continue
		if bool(service.call("cancel_job_v01531", clean_job)):
			if _status != null:
				_status.text = "Cancelled the selected AI job."
			_refresh_ai_jobs_panel_v01531()
			return true
	# Safe child rows point at their parent Character job. Job number ranges are
	# distinct per live worker, so a capability-based fallback can locate it.
	for service_value in _worker_services_v01526:
		if not service_value is CCFGenerationServiceV01526:
			continue
		var fallback_service: CCFGenerationServiceV01526 = (
			service_value as CCFGenerationServiceV01526
		)
		if not fallback_service.has_method("cancel_job_v01531"):
			continue
		if bool(fallback_service.call("cancel_job_v01531", clean_job)):
			if _status != null:
				_status.text = "Cancelled the selected AI job."
			_refresh_ai_jobs_panel_v01531()
			return true
	if (
		_image_jobs_controller_v01531 != null
		and is_instance_valid(_image_jobs_controller_v01531)
		and _image_jobs_controller_v01531.has_method("cancel_ai_job_v01531")
	):
		var cancelled: bool = bool(
			_image_jobs_controller_v01531.call(
				"cancel_ai_job_v01531", clean_worker, clean_job
			)
		)
		if cancelled:
			if _status != null:
				_status.text = "Cancelled the selected Image Studio AI job."
			_refresh_ai_jobs_panel_v01531()
			return true
	return false


func show_ai_jobs_v01531(show_panel: bool = true) -> void:
	if _ai_jobs_panel_v01531 == null:
		_install_ai_jobs_panel_v01531()
	if _ai_jobs_panel_v01531 == null:
		return
	_ai_jobs_panel_v01531.visible = show_panel
	_update_ai_jobs_toggle_v01531()
	if show_panel:
		_refresh_ai_jobs_panel_v01531()


func _create_worker_service_v01526(
	worker_id: String, worker_label: String, job_number_base: int
) -> CCFGenerationServiceV01526:
	var service: CCFGenerationServiceV01526 = (
		GENERATION_SERVICE_V01531.new() as CCFGenerationServiceV01526
	)
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


func _install_ai_jobs_panel_v01531() -> void:
	if _ai_jobs_panel_v01531 != null or _queue_status == null:
		return
	var controls_parent: Node = _queue_status.get_parent()
	if controls_parent != null:
		_ai_jobs_toggle_v01531 = Button.new()
		_ai_jobs_toggle_v01531.text = "AI Jobs"
		_ai_jobs_toggle_v01531.tooltip_text = (
			"Show running, queued, capacity-waiting, and dependency-waiting AI jobs."
		)
		_ai_jobs_toggle_v01531.pressed.connect(_toggle_ai_jobs_panel_v01531)
		controls_parent.add_child(_ai_jobs_toggle_v01531)

	var host: Node = controls_parent
	while host != null and not host is VBoxContainer:
		host = host.get_parent()
	if host == null:
		host = self
	_ai_jobs_panel_v01531 = AI_JOBS_PANEL_V01531.new() as CCFAIJobsPanelV01531
	_ai_jobs_panel_v01531.visible = false
	_ai_jobs_panel_v01531.cancel_requested.connect(_on_ai_job_cancel_requested_v01531)
	host.add_child(_ai_jobs_panel_v01531)
	if host is VBoxContainer and controls_parent != null:
		var controls_branch: Node = controls_parent
		while (
			controls_branch.get_parent() != host
			and controls_branch.get_parent() != null
		):
			controls_branch = controls_branch.get_parent()
		if controls_branch.get_parent() == host:
			host.move_child(
				_ai_jobs_panel_v01531,
				mini(controls_branch.get_index() + 1, host.get_child_count() - 1)
			)
	_update_ai_jobs_toggle_v01531()


func _toggle_ai_jobs_panel_v01531() -> void:
	if _ai_jobs_panel_v01531 == null:
		return
	show_ai_jobs_v01531(not _ai_jobs_panel_v01531.visible)


func _on_ai_job_cancel_requested_v01531(
	worker_id: String, cancel_job_id: String, record_id: String
) -> void:
	if not cancel_ai_job_v01531(worker_id, cancel_job_id, record_id):
		if _status != null:
			_status.text = "That AI job already finished or could not be cancelled."
	_refresh_ai_jobs_panel_v01531()


func _on_worker_queue_changed_v01526(
	pending_count: int, active_job_id: String, active_label: String
) -> void:
	super._on_worker_queue_changed_v01526(
		pending_count, active_job_id, active_label
	)
	_refresh_ai_jobs_panel_v01531()


func _on_scheduler_state_changed_v01526(snapshot: Dictionary) -> void:
	super._on_scheduler_state_changed_v01526(snapshot)
	_refresh_ai_jobs_panel_v01531()


func _refresh_aggregate_queue_status_v01526() -> void:
	super._refresh_aggregate_queue_status_v01526()
	_update_ai_jobs_toggle_v01531()


func _refresh_ai_jobs_panel_v01531() -> void:
	if _ai_jobs_panel_v01531 == null:
		return
	var snapshot: Dictionary = (
		_ai_scheduler_v01526.snapshot()
		if _ai_scheduler_v01526 != null
		else {
			"running": 0,
			"running_counted": 0,
			"waiting": 0,
			"active": {},
			"waiting_descriptors": {}
		}
	)
	_ai_jobs_panel_v01531.set_jobs_v01531(ai_job_records_v01531(), snapshot)
	_update_ai_jobs_toggle_v01531()


func _update_ai_jobs_toggle_v01531() -> void:
	if _ai_jobs_toggle_v01531 == null:
		return
	var records: Array = ai_job_records_v01531()
	var live_count: int = 0
	for raw_record in records:
		if not raw_record is Dictionary:
			continue
		if str(raw_record.get("status", "")) != "completed":
			live_count += 1
	_ai_jobs_toggle_v01531.text = "AI Jobs (%d)" % live_count
	_ai_jobs_toggle_v01531.tooltip_text = (
		"Hide the AI Jobs panel."
		if _ai_jobs_panel_v01531 != null and _ai_jobs_panel_v01531.visible
		else "Show running, queued, capacity-waiting, and dependency-waiting AI jobs."
	)
