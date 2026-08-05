class_name CCFWorkspaceV01536Hotfix2View
extends "res://scripts/ui/workspace_v01536_hotfix1.gd"

const GENERATION_SERVICE_V01536_HOTFIX2 = preload(
	"res://scripts/services/generation_service_v01536_hotfix2.gd"
)


func _create_worker_service_v01526(
	worker_id: String, worker_label: String, job_number_base: int
) -> CCFGenerationServiceV01526:
	var service := GENERATION_SERVICE_V01536_HOTFIX2.new() as CCFGenerationServiceV01526
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


func idea_agency_capabilities_v01536_hotfix2() -> Dictionary:
	var service_value: Variant = _idea_service_v01526
	if service_value != null and service_value.has_method(
		"idea_agency_capabilities_v01536_hotfix2"
	):
		return service_value.call(
			"idea_agency_capabilities_v01536_hotfix2"
		) as Dictionary
	return {}
