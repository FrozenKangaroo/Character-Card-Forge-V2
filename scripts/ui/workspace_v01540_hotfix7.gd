class_name CCFWorkspaceV01540Hotfix7View
extends "res://scripts/ui/workspace_v01540_hotfix6.gd"

const GENERATION_SERVICE_V01540_HOTFIX7 = preload(
	"res://scripts/services/generation_service_v01540_hotfix7.gd"
)
const GENERATION_DIAGNOSTICS_WINDOW_V01540_HOTFIX7 = preload(
	"res://scripts/ui/generation_diagnostics_window_v01540_hotfix7.gd"
)


func _ready() -> void:
	super._ready()
	_upgrade_generation_diagnostics_window_v01540_hotfix7()


func _create_worker_service_v01526(
	worker_id: String,
	worker_label: String,
	job_number_base: int
) -> CCFGenerationServiceV01526:
	var service := GENERATION_SERVICE_V01540_HOTFIX7.new() as CCFGenerationServiceV01526
	add_child(service)
	service.configure_scheduler_v01526(
		_ai_scheduler_v01526,
		worker_id,
		worker_label,
		job_number_base
	)
	service.job_started.connect(_on_job_started)
	service.job_completed.connect(_on_job_completed)
	service.job_failed.connect(_on_job_failed)
	service.job_cancelled.connect(_on_job_cancelled)
	service.queue_changed.connect(_on_worker_queue_changed_v01526)
	service.diagnostics_available.connect(
		_on_generation_diagnostics_available_v01522
	)
	return service


func _upgrade_generation_diagnostics_window_v01540_hotfix7() -> void:
	if (
		_generation_diagnostics_window_v01522 != null
		and _generation_diagnostics_window_v01522.get_script()
		== GENERATION_DIAGNOSTICS_WINDOW_V01540_HOTFIX7
	):
		return
	if _generation_diagnostics_window_v01522 != null:
		_generation_diagnostics_window_v01522.hide()
		if _generation_diagnostics_window_v01522.get_parent() == self:
			remove_child(_generation_diagnostics_window_v01522)
		_generation_diagnostics_window_v01522.queue_free()
	_generation_diagnostics_window_v01522 = (
		GENERATION_DIAGNOSTICS_WINDOW_V01540_HOTFIX7.new()
	)
	add_child(_generation_diagnostics_window_v01522)


func _on_job_failed(job_id: String, job_type: String, message: String) -> void:
	super._on_job_failed(job_id, job_type, message)
	_apply_failure_window_job_label_v01540_hotfix7(job_type)


func _apply_failure_window_job_label_v01540_hotfix7(job_type: String) -> void:
	if _generation_failure_window_v01522 == null:
		return
	var is_vision := job_type in [
		"collaborator_vision",
		"attachment_vision",
		"vision"
	]
	_generation_failure_window_v01522.title = (
		"Vision Analysis Failed" if is_vision else "Character Generation Failed"
	)
	for node in _generation_failure_window_v01522.find_children(
		"*",
		"Label",
		true,
		false
	):
		if not node is Label:
			continue
		var label := node as Label
		if label.text in ["Generation failed", "Vision analysis failed"]:
			label.text = (
				"Vision analysis failed" if is_vision else "Generation failed"
			)
			break


func diagnostics_safety_capabilities_v01540_hotfix7() -> Dictionary:
	var service_capabilities: Dictionary = {}
	if (
		_generation_service != null
		and _generation_service.has_method(
			"diagnostic_safety_capabilities_v01540_hotfix7"
		)
	):
		service_capabilities = _generation_service.call(
			"diagnostic_safety_capabilities_v01540_hotfix7"
		) as Dictionary
	var viewer_capabilities: Dictionary = {}
	if (
		_generation_diagnostics_window_v01522 != null
		and _generation_diagnostics_window_v01522.has_method(
			"diagnostic_viewer_capabilities_v01540_hotfix7"
		)
	):
		viewer_capabilities = _generation_diagnostics_window_v01522.call(
			"diagnostic_viewer_capabilities_v01540_hotfix7"
		) as Dictionary
	return {
		"version": "0.15.40-hotfix7",
		"worker_service": service_capabilities,
		"viewer": viewer_capabilities,
		"vision_failure_title": true,
		"all_workers_use_bounded_diagnostics": true
	}
