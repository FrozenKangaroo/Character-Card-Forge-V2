class_name CCFImageGenerationWindowV01531
extends "res://scripts/ui/image_generation_window_v01530.gd"


func ai_job_records_v01531() -> Array:
	var records: Array = []
	records.append_array(_prompt_job_records_v01531())
	records.append_array(_image_job_records_v01531())
	return records


func cancel_ai_job_v01531(worker_id: String, cancel_job_id: String) -> bool:
	var clean_worker := worker_id.strip_edges()
	if clean_worker.begins_with("image_prompt"):
		if _prompt_generation_service_v01529 == null:
			return false
		if (
			_prompt_generation_service_v01529.has_active_job()
			and _prompt_generation_service_v01529.active_job_id() == cancel_job_id
		):
			_prompt_generation_service_v01529.cancel_active_job()
			return true
		if _prompt_generation_service_v01529.pending_count() > 0:
			_prompt_generation_service_v01529.clear_pending_jobs()
			_reset_prompt_generation_ui_v01529()
			if _status != null:
				_status.text = "Queued image-prompt generation cancelled from AI Jobs."
			return true
		return false
	if clean_worker.begins_with("image_generation"):
		if _image_service == null:
			return false
		_image_service.cancel()
		return true
	return false


func _prompt_job_records_v01531() -> Array:
	var records: Array = []
	if _prompt_generation_service_v01529 == null:
		return records
	var worker_id := str(
		_prompt_generation_service_v01529.get("_scheduler_worker_id_v01526")
	)
	if worker_id.is_empty():
		worker_id = "image_prompt"
	var active_value: Variant = _prompt_generation_service_v01529.get("_active_job")
	if active_value is Dictionary and not active_value.is_empty():
		var active: Dictionary = active_value
		var status := "running"
		if bool(
			_prompt_generation_service_v01529.get("_scheduler_waiting_v01526")
		):
			status = "waiting_capacity"
		records.append(
			_prompt_job_record_v01531(active, worker_id, status, 0)
		)
	var queue_value: Variant = _prompt_generation_service_v01529.get("_queue")
	if queue_value is Array:
		var queue: Array = queue_value
		for index in range(queue.size()):
			var queued_value: Variant = queue[index]
			if queued_value is Dictionary:
				records.append(
					_prompt_job_record_v01531(
						queued_value, worker_id, "queued", index + 1
					)
				)
	return records


func _prompt_job_record_v01531(
	job: Dictionary, worker_id: String, status: String, queue_position: int
) -> Dictionary:
	return {
		"record_id": "%s::%s" % [worker_id, str(job.get("id", ""))],
		"job_id": str(job.get("id", "")),
		"job_type": "image_prompt",
		"label": str(job.get("label", "Generate image prompt")),
		"worker_id": worker_id,
		"worker_label": "Image Prompt Writer",
		"role": CCFAIJobSchedulerV01526.ROLE_TEXT,
		"status": status,
		"parent_id": "",
		"cancel_job_id": str(job.get("id", "")),
		"can_cancel": true,
		"queue_position": queue_position,
		"profile_name": str(job.get("profile_name", "")),
		"model": str(job.get("model", "")),
		"generation_strategy": "",
		"stage": "Image prompt generation",
		"detail": ""
	}


func _image_job_records_v01531() -> Array:
	var records: Array = []
	if not _image_service is CCFImageGenerationServiceV01526:
		return records
	var image_service := _image_service as CCFImageGenerationServiceV01526
	var worker_id := str(image_service.get("_worker_id_v01526"))
	if worker_id.is_empty():
		worker_id = "image_generation"
	var pending_value: Variant = image_service.get("_pending_generate_v01526")
	var pending: Dictionary = (
		pending_value if pending_value is Dictionary else {}
	)
	if not image_service.is_active() and pending.is_empty():
		return records
	var status := "running" if image_service.is_active() else "waiting_capacity"
	var profile := _selected_profile()
	if not pending.is_empty() and pending.get("profile") is Dictionary:
		profile = pending.get("profile", {}).duplicate(true)
	var model_id := str(pending.get("model_override", "")).strip_edges()
	if model_id.is_empty():
		model_id = str(profile.get("model", ""))
	records.append(
		{
			"record_id": "%s::image_generation" % worker_id,
			"job_id": "image_generation",
			"job_type": "image_generation",
			"label": "Generate character image",
			"worker_id": worker_id,
			"worker_label": "Image Studio",
			"role": CCFAIJobSchedulerV01526.ROLE_IMAGE,
			"status": status,
			"parent_id": "",
			"cancel_job_id": "image_generation",
			"can_cancel": true,
			"queue_position": 0,
			"profile_name": str(profile.get("name", "Image Provider")),
			"model": model_id,
			"generation_strategy": "",
			"stage": "Image generation",
			"detail": ""
		}
	)
	return records
