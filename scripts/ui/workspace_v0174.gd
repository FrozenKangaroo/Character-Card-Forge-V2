class_name CCFWorkspaceV0174View
extends "res://scripts/ui/workspace_v0173.gd"

const IMPORT_EXPORT_WINDOW_V0174 = preload(
	"res://scripts/ui/import_export_window_v0174.gd"
)
const CARD_WORKFLOW_WINDOW_V0174 = preload(
	"res://scripts/ui/card_workflow_window_v0174.gd"
)
const GENERATION_SERVICE_V0174 = preload(
	"res://scripts/services/generation_service_v0174.gd"
)


func _create_worker_service_v01526(
	worker_id: String, worker_label: String, job_number_base: int
) -> CCFGenerationServiceV01526:
	var service := GENERATION_SERVICE_V0174.new() as CCFGenerationServiceV01526
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


func _build_card_workflow_window() -> void:
	_card_workflow_window = CARD_WORKFLOW_WINDOW_V0174.new()
	_card_workflow_window.visible = false
	_card_workflow_window.set_generation_service(_generation_service)
	_card_workflow_window.project_refresh_requested.connect(_refresh_card_workflow_project_context)
	_card_workflow_window.workflow_saved.connect(_on_card_workflow_saved)
	_card_workflow_window.workflow_deleted.connect(_on_card_workflow_deleted)
	add_child(_card_workflow_window)
	_card_workflow_window.hide()


func _build_import_export_window() -> void:
	_import_export_window = IMPORT_EXPORT_WINDOW_V0174.new()
	_import_export_window.visible = false
	_import_export_window.project_refresh_requested.connect(_refresh_import_export_project_context)
	_import_export_window.project_imported.connect(_on_external_project_imported)
	add_child(_import_export_window)
	_import_export_window.hide()


func front_porch_group_capabilities_v0174() -> Dictionary:
	if _import_export_window != null and _import_export_window.has_method(
		"front_porch_group_capabilities_v0174"
	):
		return _import_export_window.call("front_porch_group_capabilities_v0174") as Dictionary
	return {"portable_import": false, "portable_export": false, "direct_database_writes": false}
