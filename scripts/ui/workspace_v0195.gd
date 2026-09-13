class_name CCFWorkspaceV0195View
extends "res://scripts/ui/workspace_v0194.gd"

const GENERATION_SERVICE_V0195 = preload(
	"res://scripts/services/generation_service_v0195.gd"
)


func _create_worker_service_v01526(
	worker_id: String, worker_label: String, job_number_base: int
) -> CCFGenerationServiceV01526:
	var service := GENERATION_SERVICE_V0195.new() as CCFGenerationServiceV01526
	add_child(service)
	service.configure_scheduler_v01526(
		_ai_scheduler_v01526, worker_id, worker_label, job_number_base
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


func _suggest_field(field: Dictionary) -> void:
	if _project.is_empty():
		return
	_capture_all_fields()
	var profile := CCFSettingsService.profile_for_text_task(
		_settings, CCFSettingsService.TEXT_TASK_FAST
	)
	var result := _generation_service.queue_field_suggestion(
		_project,
		_template,
		field,
		profile,
		int(_generation_settings().get("retry_count", 1))
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not queue field suggestion."))
		return
	var queued_ahead := int(result.get("queued_ahead", 0))
	_status.text = "%s queued%s using %s." % [
		str(field.get("label", "Field suggestion")),
		" behind %d job(s)" % queued_ahead if queued_ahead > 0 else "",
		_text_route_label_v0195(profile)
	]


func _queue_front_porch_fields_v0172(
	fields: Array[Dictionary], scope_label: String
) -> void:
	if _generation_service == null or not _generation_service.has_method(
		"queue_front_porch_fields_v0172"
	):
		_status.text = "The Front Porch generation service is unavailable."
		return
	var task := (
		CCFSettingsService.TEXT_TASK_FAST
		if fields.size() == 1
		else CCFSettingsService.TEXT_TASK_PRIMARY
	)
	var profile := CCFSettingsService.profile_for_text_task(_settings, task)
	var result := _generation_service.call(
		"queue_front_porch_fields_v0172",
		_project,
		fields,
		profile,
		int(_generation_settings().get("retry_count", 1)),
		scope_label
	) as Dictionary
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not queue Front Porch generation."))
		return
	var queued_ahead := int(result.get("queued_ahead", 0))
	_status.text = "Front Porch %s proposal queued%s using %s." % [
		scope_label,
		" behind %d job(s)" % queued_ahead if queued_ahead > 0 else "",
		_text_route_label_v0195(profile)
	]


func _queue_ai_review_v0183() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	var profile := CCFSettingsService.profile_for_text_task(
		_settings, CCFSettingsService.TEXT_TASK_DEEP
	)
	var service := _generation_service as CCFGenerationServiceV0195
	if service == null:
		_status.text = "The v0.19.5 AI Review routing service is unavailable."
		return
	var result := service.queue_ai_review_v0183(
		_project_container,
		_active_character_id,
		profile,
		int(_generation_settings().get("retry_count", 1))
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not queue AI Review."))
		return
	_ai_review_window_v0183.begin_review(str(result.get("job_id", "")))
	var queued_ahead := int(result.get("queued_ahead", 0))
	_status.text = "AI Review queued%s using %s." % [
		" behind %d job(s)" % queued_ahead if queued_ahead > 0 else "",
		_text_route_label_v0195(profile)
	]


func text_routing_capabilities_v0195() -> Dictionary:
	var service := _generation_service as CCFGenerationServiceV0195
	if service == null:
		return {}
	var capabilities := service.text_routing_capabilities_v0195()
	capabilities["single_field_suggestions_use_fast"] = true
	capabilities["front_porch_single_fields_use_fast"] = true
	capabilities["ai_review_uses_deep"] = true
	capabilities["full_generation_uses_primary"] = true
	return capabilities


func _on_job_completed(
	job_id: String, job_type: String, data: Variant, metadata: Dictionary
) -> void:
	super._on_job_completed(job_id, job_type, data, metadata)
	var fallback_value: Variant = metadata.get("fallback", {})
	if not fallback_value is Dictionary or fallback_value.is_empty():
		return
	var fallback: Dictionary = fallback_value
	var producer: Dictionary = fallback.get("to", {})
	_status.text += " Fallback used: %s / %s." % [
		str(producer.get("profile_name", metadata.get("profile_name", "Fallback Text"))),
		str(producer.get("model", metadata.get("model", "unknown model")))
	]


func _text_route_label_v0195(profile: Dictionary) -> String:
	var routing_value: Variant = profile.get("_ccf_text_routing_v0195", {})
	if not routing_value is Dictionary:
		return "Primary Text"
	var routing: Dictionary = routing_value
	var task := str(routing.get("requested_task", "primary"))
	var label := "Primary Text"
	if task == CCFSettingsService.TEXT_TASK_FAST:
		label = "Fast / Suggestion Text"
	elif task == CCFSettingsService.TEXT_TASK_DEEP:
		label = "Deep Review Text"
	if bool(routing.get("inherited_primary", false)):
		label += " (Primary)"
	return "%s — %s" % [label, str(profile.get("name", "Profile"))]
