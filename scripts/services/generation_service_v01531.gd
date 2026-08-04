extends "res://scripts/services/generation_service_v01526.gd"


func job_records_v01531() -> Array:
	var records: Array = []
	if not _active_job.is_empty():
		var active_id: String = str(_active_job.get("id", ""))
		var active_status: String = "running"
		if bool(_active_job.get("parallel_safe_waiting_v01526", false)):
			active_status = "coordinating"
		elif bool(get("_scheduler_waiting_v01526")):
			active_status = "waiting_capacity"
		records.append(
			_job_record_v01531(
				_active_job,
				active_status,
				str(get("_scheduler_worker_id_v01526")),
				str(get("_scheduler_worker_label_v01526")),
				"",
				active_id,
				true,
				0
			)
		)
		if bool(_active_job.get("parallel_safe_waiting_v01526", false)):
			records.append_array(_safe_section_records_v01531())

	for queue_index in range(_queue.size()):
		var queued_value: Variant = _queue[queue_index]
		if not queued_value is Dictionary:
			continue
		var queued_job: Dictionary = queued_value
		var queued_id: String = str(queued_job.get("id", ""))
		records.append(
			_job_record_v01531(
				queued_job,
				"queued",
				str(get("_scheduler_worker_id_v01526")),
				str(get("_scheduler_worker_label_v01526")),
				"",
				queued_id,
				true,
				queue_index + 1
			)
		)
	return records


func cancel_job_v01531(job_id: String) -> bool:
	var clean_id: String = job_id.strip_edges()
	if clean_id.is_empty():
		return false
	if not _active_job.is_empty() and str(_active_job.get("id", "")) == clean_id:
		cancel_active_job()
		return true
	for index in range(_queue.size()):
		var queued_value: Variant = _queue[index]
		if not queued_value is Dictionary:
			continue
		var queued_job: Dictionary = queued_value
		if str(queued_job.get("id", "")) != clean_id:
			continue
		var cancelled_type: String = str(queued_job.get("type", ""))
		_queue.remove_at(index)
		job_cancelled.emit(clean_id, cancelled_type)
		_emit_queue_changed()
		return true
	return false


func worker_identity_v01531() -> Dictionary:
	return {
		"worker_id": str(get("_scheduler_worker_id_v01526")),
		"label": str(get("_scheduler_worker_label_v01526"))
	}


func _job_record_v01531(
	job: Dictionary,
	status: String,
	worker_id: String,
	worker_label: String,
	parent_id: String,
	cancel_job_id: String,
	can_cancel: bool,
	queue_position: int
) -> Dictionary:
	var metadata_value: Variant = job.get("metadata", {})
	var metadata: Dictionary = metadata_value if metadata_value is Dictionary else {}
	var role: String = CCFAIJobSchedulerV01526.ROLE_TEXT
	if (
		str(metadata.get("request_role", "")).to_lower() == "vision"
		or str(job.get("type", "")) == "vision_analysis"
	):
		role = CCFAIJobSchedulerV01526.ROLE_VISION
	return {
		"record_id": "%s::%s" % [worker_id, str(job.get("id", ""))],
		"job_id": str(job.get("id", "")),
		"job_type": str(job.get("type", "")),
		"label": str(job.get("label", worker_label)),
		"worker_id": worker_id,
		"worker_label": worker_label,
		"role": role,
		"status": status,
		"parent_id": parent_id,
		"cancel_job_id": cancel_job_id,
		"can_cancel": can_cancel,
		"queue_position": queue_position,
		"profile_name": str(job.get("profile_name", "")),
		"model": str(job.get("model", "")),
		"generation_strategy": str(
			metadata.get("generation_strategy", job.get("generation_strategy", ""))
		),
		"stage": _record_stage_v01531(job),
		"detail": ""
	}


func _safe_section_records_v01531() -> Array:
	var records: Array = []
	var state_value: Variant = _active_job.get("safe_build_state", {})
	if not state_value is Dictionary:
		return records
	var state: Dictionary = state_value
	var plan_value: Variant = state.get("plan", [])
	if not plan_value is Array:
		return records
	var plan: Array = plan_value
	var parent_job_id: String = str(_active_job.get("id", ""))
	var coordinator_value: Variant = get("_parallel_coordinator_v01526")
	var coordinator: Dictionary = (
		coordinator_value if coordinator_value is Dictionary else {}
	)
	var completed_value: Variant = coordinator.get("completed_indices", {})
	var completed: Dictionary = (
		completed_value if completed_value is Dictionary else {}
	)
	var running_value: Variant = coordinator.get("running", {})
	var running: Dictionary = running_value if running_value is Dictionary else {}
	var current_wave_value: Variant = coordinator.get("wave_indices", [])
	var current_wave: Array = (
		current_wave_value if current_wave_value is Array else []
	)
	var running_by_index: Dictionary = {}
	for running_record_value in running.values():
		if not running_record_value is Dictionary:
			continue
		var running_record: Dictionary = running_record_value
		var running_section_index: int = int(running_record.get("section_index", -1))
		if running_section_index >= 0:
			running_by_index[running_section_index] = running_record

	for section_index in range(plan.size()):
		var section_value: Variant = plan[section_index]
		if not section_value is Dictionary:
			continue
		var section: Dictionary = section_value
		var section_title: String = str(
			section.get("title", section.get("id", "Section"))
		)
		var section_id: String = str(
			section.get("id", section.get("field_id", "section"))
		)
		var status: String = "waiting_dependency"
		var detail: String = ""
		var can_cancel: bool = true
		if completed.has(section_index):
			status = "completed"
			can_cancel = false
		elif running_by_index.has(section_index):
			status = "running"
			var child_record_value: Variant = running_by_index.get(section_index, {})
			if child_record_value is Dictionary:
				var child_service_value: Variant = child_record_value.get("service", null)
				if child_service_value is Node:
					var child_service: Node = child_service_value as Node
					if bool(child_service.get("_scheduler_waiting_v01526")):
						status = "waiting_capacity"
		elif current_wave.has(section_index):
			status = "queued"
		else:
			var dependency_names: Array[String] = []
			var dependency_indices: Array[int] = _section_dependency_indices_v01526(
				plan, section_index
			)
			for dependency_index in dependency_indices:
				if completed.has(dependency_index):
					continue
				if dependency_index < 0 or dependency_index >= plan.size():
					continue
				var dependency_value: Variant = plan[dependency_index]
				if dependency_value is Dictionary:
					dependency_names.append(
						str(
							dependency_value.get(
								"title",
								dependency_value.get("id", "earlier section")
							)
						)
					)
			if not dependency_names.is_empty():
				var dependency_text: String = _join_strings_v01531(
					dependency_names, ", "
				)
				detail = "Waiting for %s" % dependency_text
			else:
				detail = "Waiting for an earlier Safe Section wave"
		records.append(
			{
				"record_id": "%s::safe::%03d" % [
					str(get("_scheduler_worker_id_v01526")), section_index
				],
				"job_id": "%s::%s" % [parent_job_id, section_id],
				"job_type": "safe_section",
				"label": section_title,
				"worker_id": str(get("_scheduler_worker_id_v01526")),
				"worker_label": str(get("_scheduler_worker_label_v01526")),
				"role": CCFAIJobSchedulerV01526.ROLE_TEXT,
				"status": status,
				"parent_id": parent_job_id,
				"cancel_job_id": parent_job_id,
				"can_cancel": can_cancel,
				"queue_position": section_index + 1,
				"profile_name": str(_active_job.get("profile_name", "")),
				"model": str(_active_job.get("model", "")),
				"generation_strategy": "safe_section",
				"stage": "Safe Section",
				"detail": detail
			}
		)
	return records


func _record_stage_v01531(job: Dictionary) -> String:
	var interview_stage: String = str(job.get("interview_stage", "")).strip_edges()
	if not interview_stage.is_empty():
		return "Interview / Q&A"
	if bool(job.get("parallel_safe_waiting_v01526", false)):
		return "Parallel Safe Section coordinator"
	var safe_stage: String = str(job.get("safe_stage", "")).strip_edges()
	if not safe_stage.is_empty():
		return safe_stage.replace("_", " ").capitalize()
	return str(job.get("type", "Generation")).replace("_", " ").capitalize()


func _join_strings_v01531(values: Array[String], separator: String) -> String:
	var result: String = ""
	for index in range(values.size()):
		if index > 0:
			result += separator
		result += values[index]
	return result
