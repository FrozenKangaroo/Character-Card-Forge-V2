class_name CCFWorkspaceV01537Hotfix1View
extends "res://scripts/ui/workspace_v01537.gd"

const GENERATION_SERVICE_V01537_HOTFIX1 = preload(
	"res://scripts/services/generation_service_v01537_hotfix1.gd"
)


func _create_worker_service_v01526(
	worker_id: String, worker_label: String, job_number_base: int
) -> CCFGenerationServiceV01526:
	var service := GENERATION_SERVICE_V01537_HOTFIX1.new() as CCFGenerationServiceV01526
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


func safe_section_guard_capabilities_v01537_hotfix1() -> Dictionary:
	var service_value: Variant = _generation_service
	if service_value != null and service_value.has_method(
		"safe_section_guard_capabilities_v01537_hotfix1"
	):
		return service_value.call(
			"safe_section_guard_capabilities_v01537_hotfix1"
		) as Dictionary
	return {}
