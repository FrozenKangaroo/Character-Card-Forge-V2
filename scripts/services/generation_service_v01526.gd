class_name CCFGenerationServiceV01526
extends "res://scripts/services/generation_service_v01525.gd"

signal parallel_safe_section_completed(
	worker_id: String, section_index: int, section_id: String, result: Dictionary
)

const SCHEDULER_FORMAT_VERSION_V01526 := 1

var _scheduler_v01526: CCFAIJobSchedulerV01526
var _scheduler_worker_id_v01526 := "generation"
var _scheduler_worker_label_v01526 := "AI generation"
var _scheduler_parent_id_v01526 := ""
var _scheduler_waiting_v01526 := false
var _scheduler_lease_v01526 := false
var _scheduler_lease_key_v01526 := ""

var _parallel_child_mode_v01526 := false
var _parallel_child_index_v01526 := -1
var _parallel_coordinator_v01526: Dictionary = {}
var _parallel_child_serial_v01526 := 0
var _parallel_cancel_in_progress_v01526 := false


func configure_scheduler_v01526(
	scheduler: CCFAIJobSchedulerV01526,
	worker_id: String,
	worker_label: String,
	job_number_base: int = 0,
	parent_id: String = ""
) -> void:
	if (
		_scheduler_v01526 != null
		and _scheduler_v01526.capacity_changed.is_connected(
			_on_scheduler_capacity_changed_v01526
		)
	):
		_scheduler_v01526.capacity_changed.disconnect(_on_scheduler_capacity_changed_v01526)
	_scheduler_v01526 = scheduler
	_scheduler_worker_id_v01526 = worker_id.strip_edges()
	if _scheduler_worker_id_v01526.is_empty():
		_scheduler_worker_id_v01526 = "generation_%d" % get_instance_id()
	_scheduler_worker_label_v01526 = worker_label.strip_edges()
	_scheduler_parent_id_v01526 = parent_id.strip_edges()
	if job_number_base > 0:
		_next_job_number = job_number_base
	if (
		_scheduler_v01526 != null
		and not _scheduler_v01526.capacity_changed.is_connected(
			_on_scheduler_capacity_changed_v01526
		)
	):
		_scheduler_v01526.capacity_changed.connect(_on_scheduler_capacity_changed_v01526)


func concurrent_capabilities_v01526() -> Dictionary:
	return {
		"format_version": SCHEDULER_FORMAT_VERSION_V01526,
		"scheduler_gated_requests": true,
		"parallel_safe_sections": true,
		"interview_barrier": true,
		"dependency_waves": true,
		"frozen_wave_context": true,
		"deterministic_template_order_assembly": true,
		"token_budget_invariant": true
	}


func scheduler_snapshot_v01526() -> Dictionary:
	if _scheduler_v01526 == null:
		return {}
	return _scheduler_v01526.snapshot()


func _start_active_request() -> void:
	if bool(_active_job.get("parallel_safe_waiting_v01526", false)):
		if not bool(_parallel_coordinator_v01526.get("started", false)):
			call_deferred("_start_parallel_safe_build_v01526")
		return
	if _scheduler_v01526 == null:
		super._start_active_request()
		return
	if not _scheduler_lease_v01526:
		var request_key := _scheduler_request_key_v01526()
		if not _scheduler_v01526.request_slot(
			request_key,
			_active_request_role_v01526(),
			_scheduler_parent_id_v01526,
			null,
			str(_active_job.get("label", _scheduler_worker_label_v01526))
		):
			_scheduler_waiting_v01526 = true
			_emit_queue_changed()
			return
		_scheduler_lease_key_v01526 = request_key
		_scheduler_lease_v01526 = true
		_scheduler_waiting_v01526 = false
	super._start_active_request()


func _on_request_completed(
	result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray
) -> void:
	_release_scheduler_lease_v01526()
	super._on_request_completed(result, response_code, headers, body)


func _handle_failure(message: String, retryable: bool) -> void:
	# A failed request attempt must release its slot before an inherited retry is
	# deferred. Repairs and retries then compete fairly for a fresh scheduler slot.
	_release_scheduler_lease_v01526()
	super._handle_failure(message, retryable)


func cancel_active_job() -> void:
	if _active_job.is_empty():
		return
	if _scheduler_v01526 != null and _scheduler_waiting_v01526:
		_scheduler_v01526.cancel_wait(_scheduler_request_key_v01526())
	_release_scheduler_lease_v01526()
	_cancel_parallel_children_v01526()
	super.cancel_active_job()


func _prepare_character_stage(job_value: Dictionary) -> Dictionary:
	var job := super._prepare_character_stage(job_value)
	if _parallel_child_mode_v01526:
		return job
	if str(job.get("generation_strategy", "")) != GENERATION_STRATEGY_SAFE_SECTION:
		return job
	var state := _dictionary_copy_v01522(job.get("safe_build_state", {}))
	var plan_value: Variant = state.get("plan", [])
	if not plan_value is Array or plan_value.size() < 2:
		return job
	var config := (
		_scheduler_v01526.config()
		if _scheduler_v01526 != null
		else CCFAIJobSchedulerV01526.default_config()
	)
	if not bool(config.get("parallel_safe_sections", false)):
		return job
	if int(config.get("max_sections_per_character", 1)) <= 1:
		return job

	# Interview/Q&A has already completed before _prepare_character_stage() is
	# reached. The parent now becomes a coordinator and sends no section request.
	job["parallel_safe_waiting_v01526"] = true
	job["label"] = "Safe Section Build • preparing parallel sections"
	_parallel_coordinator_v01526 = {
		"started": false,
		"completed_indices": {},
		"running": {},
		"wave_indices": [],
		"wave_cursor": 0,
		"wave_snapshot": {},
		"failed": false,
		"waves": [],
		"wave_number": 0
	}
	return job


func queue_parallel_safe_section_v01526(
	parent_job: Dictionary,
	parent_state_snapshot: Dictionary,
	section: Dictionary,
	section_index: int
) -> Dictionary:
	if has_active_job() or pending_count() > 0:
		return {"ok": false, "error": "Parallel Safe Section worker is already occupied."}
	_parallel_child_mode_v01526 = true
	_parallel_child_index_v01526 = section_index
	var job := parent_job.duplicate(true)
	var job_id := "parallel_%s_%03d_%d" % [
		str(parent_job.get("id", "character")), section_index, get_instance_id()
	]
	job["id"] = job_id
	job["type"] = "character"
	job["parallel_safe_child_v01526"] = true
	job["parallel_safe_waiting_v01526"] = false
	job["safe_delegate_to_parent"] = false
	job["safe_stage"] = "section"
	job["safe_active_section"] = section.duplicate(true)
	job["parse_mode"] = "object"
	job["attempt"] = 0
	job["repair_attempts"] = 0
	var state := parent_state_snapshot.duplicate(true)
	state["index"] = section_index
	job["safe_build_state"] = state
	var plan_value: Variant = state.get("plan", [])
	var plan_size: int = plan_value.size() if plan_value is Array else 1
	job["label"] = "Safe Section Build • %d/%d • %s" % [
		section_index + 1, plan_size, str(section.get("title", "Section"))
	]
	job["payload"] = _safe_section_payload_v01522(job, section)
	_queue.append(job)
	_emit_queue_changed()
	call_deferred("_start_next_job")
	return {"ok": true, "job_id": job_id}


func _advance_safe_build_v01522() -> void:
	if not _parallel_child_mode_v01526:
		super._advance_safe_build_v01522()
		return
	var state := _dictionary_copy_v01522(_active_job.get("safe_build_state", {}))
	var section := _dictionary_copy_v01522(_active_job.get("safe_active_section", {}))
	var section_id := str(section.get("id", section.get("field_id", "section")))
	var result := {
		"state": state.duplicate(true),
		"section": section.duplicate(true),
		"accepted_fields": _dictionary_copy_v01522(state.get("accepted_fields", {})),
		"accepted_groups": _dictionary_copy_v01522(state.get("accepted_groups", {}))
	}
	var worker_id := _scheduler_worker_id_v01526
	var section_index := _parallel_child_index_v01526
	_active_job = {}
	_parallel_child_mode_v01526 = false
	_parallel_child_index_v01526 = -1
	_emit_queue_changed()
	parallel_safe_section_completed.emit(worker_id, section_index, section_id, result)
	call_deferred("_start_next_job")


func dependency_waves_v01526(plan: Array) -> Array:
	var completed: Dictionary = {}
	var waves: Array = []
	while completed.size() < plan.size():
		var wave: Array[int] = []
		for index in range(plan.size()):
			if completed.has(index):
				continue
			var dependencies := _section_dependency_indices_v01526(plan, index)
			var dependencies_satisfied := true
			for dependency_index in dependencies:
				if not completed.has(dependency_index):
					dependencies_satisfied = false
					break
			if dependencies_satisfied:
				wave.append(index)
		if wave.is_empty():
			# Invalid/cyclic custom dependencies must not deadlock the build.
			for index in range(plan.size()):
				if not completed.has(index):
					wave.append(index)
					break
		waves.append(wave.duplicate())
		for index in wave:
			completed[index] = true
	return waves


func _start_parallel_safe_build_v01526() -> void:
	if _active_job.is_empty() or not bool(
		_active_job.get("parallel_safe_waiting_v01526", false)
	):
		return
	_parallel_coordinator_v01526["started"] = true
	var state := _dictionary_copy_v01522(_active_job.get("safe_build_state", {}))
	var plan_value: Variant = state.get("plan", [])
	var plan: Array = plan_value if plan_value is Array else []
	_parallel_coordinator_v01526["waves"] = dependency_waves_v01526(plan)
	_parallel_coordinator_v01526["wave_number"] = 0
	_start_parallel_wave_v01526()


func _start_parallel_wave_v01526() -> void:
	if bool(_parallel_coordinator_v01526.get("failed", false)):
		return
	var waves_value: Variant = _parallel_coordinator_v01526.get("waves", [])
	var waves: Array = waves_value if waves_value is Array else []
	var wave_number := int(_parallel_coordinator_v01526.get("wave_number", 0))
	if wave_number >= waves.size():
		_finish_parallel_safe_build_v01526()
		return
	var wave_value: Variant = waves[wave_number]
	var wave: Array = wave_value.duplicate() if wave_value is Array else []
	var state := _dictionary_copy_v01522(_active_job.get("safe_build_state", {}))
	_parallel_coordinator_v01526["wave_indices"] = wave
	_parallel_coordinator_v01526["wave_cursor"] = 0
	# Every sibling receives this exact snapshot. Completion timing therefore
	# cannot alter another sibling's prompt.
	_parallel_coordinator_v01526["wave_snapshot"] = state.duplicate(true)
	_fill_parallel_wave_v01526()


func _fill_parallel_wave_v01526() -> void:
	var wave_value: Variant = _parallel_coordinator_v01526.get("wave_indices", [])
	var wave: Array = wave_value if wave_value is Array else []
	var cursor := int(_parallel_coordinator_v01526.get("wave_cursor", 0))
	var running_value: Variant = _parallel_coordinator_v01526.get("running", {})
	var running: Dictionary = running_value if running_value is Dictionary else {}
	var config := _scheduler_v01526.config() if _scheduler_v01526 != null else {}
	var per_character_limit := maxi(1, int(config.get("max_sections_per_character", 1)))
	while cursor < wave.size() and running.size() < per_character_limit:
		var section_index := int(wave[cursor])
		cursor += 1
		var child := CCFGenerationServiceV01526.new()
		var child_id := "%s:section:%03d:%03d" % [
			_scheduler_worker_id_v01526, section_index, _parallel_child_serial_v01526
		]
		_parallel_child_serial_v01526 += 1
		add_child(child)
		child.configure_scheduler_v01526(
			_scheduler_v01526,
			child_id,
			"Safe Section",
			700000 + _parallel_child_serial_v01526 * 100,
			str(_active_job.get("id", "character"))
		)
		child.parallel_safe_section_completed.connect(_on_parallel_section_completed_v01526)
		child.job_failed.connect(_on_parallel_section_failed_v01526.bind(child_id))
		child.job_cancelled.connect(_on_parallel_section_cancelled_v01526.bind(child_id))
		child.diagnostics_available.connect(_on_parallel_child_diagnostics_v01526)
		var snapshot := _dictionary_copy_v01522(
			_parallel_coordinator_v01526.get("wave_snapshot", {})
		)
		var plan_value: Variant = snapshot.get("plan", [])
		var plan: Array = plan_value if plan_value is Array else []
		if section_index < 0 or section_index >= plan.size() or not plan[section_index] is Dictionary:
			child.queue_free()
			_parallel_coordinator_v01526["failed"] = true
			_handle_failure("Parallel Safe Section Build encountered an invalid section plan.", false)
			return
		var section: Dictionary = plan[section_index]
		var result := child.queue_parallel_safe_section_v01526(
			_active_job.duplicate(true), snapshot, section, section_index
		)
		if not bool(result.get("ok", false)):
			child.queue_free()
			_parallel_coordinator_v01526["failed"] = true
			_handle_failure(str(result.get("error", "Could not start parallel section.")), false)
			return
		running[child_id] = {"service": child, "section_index": section_index}
	_parallel_coordinator_v01526["wave_cursor"] = cursor
	_parallel_coordinator_v01526["running"] = running
	_emit_queue_changed()


func _on_parallel_section_completed_v01526(
	worker_id: String, section_index: int, _section_id: String, result: Dictionary
) -> void:
	if _parallel_cancel_in_progress_v01526 or _active_job.is_empty():
		return
	var running_value: Variant = _parallel_coordinator_v01526.get("running", {})
	var running: Dictionary = running_value if running_value is Dictionary else {}
	var worker_record_value: Variant = running.get(worker_id, {})
	var worker_record: Dictionary = (
		worker_record_value if worker_record_value is Dictionary else {}
	)
	var child_value: Variant = worker_record.get("service", null)
	running.erase(worker_id)
	_parallel_coordinator_v01526["running"] = running
	if child_value is Node:
		(child_value as Node).queue_free()

	var parent_state := _dictionary_copy_v01522(_active_job.get("safe_build_state", {}))
	var child_state := _dictionary_copy_v01522(result.get("state", {}))
	var plan_value: Variant = parent_state.get("plan", [])
	var plan: Array = plan_value if plan_value is Array else []
	if section_index < 0 or section_index >= plan.size() or not plan[section_index] is Dictionary:
		_parallel_coordinator_v01526["failed"] = true
		_handle_failure("Parallel Safe Section Build returned an invalid section index.", false)
		return
	var section: Dictionary = plan[section_index]
	if str(section.get("kind", "standalone_field")) == "output_group":
		var group := _dictionary_copy_v01522(section.get("group", {}))
		var group_id := str(group.get("id", "generation_group"))
		var accepted_groups := _dictionary_copy_v01522(parent_state.get("accepted_groups", {}))
		var child_groups := _dictionary_copy_v01522(child_state.get("accepted_groups", {}))
		if child_groups.has(group_id):
			accepted_groups[group_id] = child_groups[group_id]
		parent_state["accepted_groups"] = accepted_groups
	else:
		var field_id := str(section.get("field_id", "field"))
		var accepted_fields := _dictionary_copy_v01522(parent_state.get("accepted_fields", {}))
		var child_fields := _dictionary_copy_v01522(child_state.get("accepted_fields", {}))
		if child_fields.has(field_id):
			accepted_fields[field_id] = child_fields[field_id]
		parent_state["accepted_fields"] = accepted_fields
	parent_state["accepted_fields"] = _assembled_safe_fields_v01522(parent_state)
	_active_job["safe_build_state"] = parent_state

	var completed_value: Variant = _parallel_coordinator_v01526.get("completed_indices", {})
	var completed: Dictionary = completed_value if completed_value is Dictionary else {}
	completed[section_index] = true
	_parallel_coordinator_v01526["completed_indices"] = completed

	var wave_value: Variant = _parallel_coordinator_v01526.get("wave_indices", [])
	var wave: Array = wave_value if wave_value is Array else []
	var cursor := int(_parallel_coordinator_v01526.get("wave_cursor", 0))
	if cursor < wave.size():
		_fill_parallel_wave_v01526()
		return
	if not running.is_empty():
		return
	_parallel_coordinator_v01526["wave_number"] = int(
		_parallel_coordinator_v01526.get("wave_number", 0)
	) + 1
	_start_parallel_wave_v01526()


func _on_parallel_section_failed_v01526(
	_job_id: String, _job_type: String, message: String, worker_id: String
) -> void:
	_remove_parallel_child_v01526(worker_id)
	if _parallel_cancel_in_progress_v01526 or bool(
		_parallel_coordinator_v01526.get("failed", false)
	):
		return
	_parallel_coordinator_v01526["failed"] = true
	_cancel_parallel_children_v01526()
	_handle_failure("Parallel Safe Section Build failed. %s" % message, false)


func _on_parallel_section_cancelled_v01526(
	_job_id: String, _job_type: String, worker_id: String
) -> void:
	_remove_parallel_child_v01526(worker_id)
	if _parallel_cancel_in_progress_v01526 or bool(
		_parallel_coordinator_v01526.get("failed", false)
	):
		return
	_parallel_coordinator_v01526["failed"] = true
	_cancel_parallel_children_v01526()
	_handle_failure("Parallel Safe Section Build was cancelled.", false)


func _on_parallel_child_diagnostics_v01526(
	job_id: String, job_type: String, diagnostics: Dictionary
) -> void:
	diagnostics_available.emit(job_id, job_type, diagnostics.duplicate(true))


func _finish_parallel_safe_build_v01526() -> void:
	var state := _dictionary_copy_v01522(_active_job.get("safe_build_state", {}))
	var assembled := _assembled_safe_fields_v01522(state)
	state["accepted_fields"] = assembled
	var plan_value: Variant = state.get("plan", [])
	var plan: Array = plan_value if plan_value is Array else []
	var completed_sections: Array = []
	for section_value in plan:
		if not section_value is Dictionary:
			continue
		var section: Dictionary = section_value
		completed_sections.append({
			"id": str(section.get("id", section.get("field_id", "section"))),
			"title": str(section.get("title", "Section")),
			"kind": str(section.get("kind", "standalone_field"))
		})
	state["completed_sections"] = completed_sections
	_active_job["safe_build_state"] = state
	_active_job["parallel_safe_waiting_v01526"] = false
	_active_job["safe_delegate_to_parent"] = true
	_active_job["safe_stage"] = "final_validation"
	_active_job["parse_mode"] = "object"
	_active_job["label"] = "Safe Section Build • validating assembled character"
	var metadata := _dictionary_copy_v01522(_active_job.get("metadata", {}))
	var waves_value: Variant = _parallel_coordinator_v01526.get("waves", [])
	metadata["parallel_safe_sections_v01526"] = {
		"used": true,
		"section_count": plan.size(),
		"wave_count": waves_value.size() if waves_value is Array else 0,
		"assembly_order": "template_order",
		"sibling_context": "frozen_per_wave"
	}
	_active_job["metadata"] = metadata
	_parallel_coordinator_v01526 = {}
	_emit_queue_changed()
	# Re-enter the established template-contract / semantic-repair / fidelity /
	# fail-closed path with the deterministically assembled candidate.
	super._process_completed_content(JSON.stringify(assembled))


func _section_dependency_indices_v01526(plan: Array, section_index: int) -> Array[int]:
	var result: Array[int] = []
	if section_index < 0 or section_index >= plan.size() or not plan[section_index] is Dictionary:
		return result
	var section: Dictionary = plan[section_index]
	var dependency_ids: Array[String] = []
	for source_value in [section, section.get("group", {}), section.get("field", {})]:
		if not source_value is Dictionary:
			continue
		var source: Dictionary = source_value
		var raw_dependencies: Variant = source.get("depends_on", [])
		if raw_dependencies is Array:
			for raw_dependency in raw_dependencies:
				var dependency := str(raw_dependency).strip_edges().to_lower()
				if not dependency.is_empty() and dependency not in dependency_ids:
					dependency_ids.append(dependency)
	var section_id := str(section.get("id", section.get("field_id", ""))).to_lower()
	if section_id in ["first_message", "first_mes", "greeting"]:
		if "scenario" not in dependency_ids:
			dependency_ids.append("scenario")
	elif section_id in [
		"alternate_greetings", "alternative_first_messages", "example_dialogue", "example_dialogues"
	]:
		if "first_message" not in dependency_ids:
			dependency_ids.append("first_message")
		if "scenario" not in dependency_ids:
			dependency_ids.append("scenario")
	for dependency_id in dependency_ids:
		for index in range(plan.size()):
			if not plan[index] is Dictionary:
				continue
			var candidate: Dictionary = plan[index]
			var candidate_ids := [
				str(candidate.get("id", "")).to_lower(),
				str(candidate.get("field_id", "")).to_lower()
			]
			if dependency_id in candidate_ids and index not in result:
				result.append(index)
	return result


func _active_request_role_v01526() -> String:
	var metadata := _dictionary_copy_v01522(_active_job.get("metadata", {}))
	if str(metadata.get("request_role", "")).to_lower() == "vision":
		return CCFAIJobSchedulerV01526.ROLE_VISION
	if str(_active_job.get("type", "")) == "vision_analysis":
		return CCFAIJobSchedulerV01526.ROLE_VISION
	return CCFAIJobSchedulerV01526.ROLE_TEXT


func _on_scheduler_capacity_changed_v01526() -> void:
	if _scheduler_waiting_v01526 and not _active_job.is_empty():
		call_deferred("_start_active_request")


func _scheduler_request_key_v01526() -> String:
	return "%s:%s" % [
		_scheduler_worker_id_v01526, str(_active_job.get("id", "request"))
	]


func _release_scheduler_lease_v01526() -> void:
	if _scheduler_v01526 != null:
		if not _scheduler_lease_key_v01526.is_empty():
			_scheduler_v01526.release_slot(_scheduler_lease_key_v01526)
		elif _scheduler_waiting_v01526:
			_scheduler_v01526.cancel_wait(_scheduler_request_key_v01526())
	_scheduler_lease_key_v01526 = ""
	_scheduler_lease_v01526 = false
	_scheduler_waiting_v01526 = false


func _remove_parallel_child_v01526(worker_id: String) -> void:
	var running_value: Variant = _parallel_coordinator_v01526.get("running", {})
	if not running_value is Dictionary:
		return
	var running: Dictionary = running_value
	var record_value: Variant = running.get(worker_id, {})
	if record_value is Dictionary:
		var child_value: Variant = record_value.get("service", null)
		if child_value is Node:
			(child_value as Node).queue_free()
	running.erase(worker_id)
	_parallel_coordinator_v01526["running"] = running


func _cancel_parallel_children_v01526() -> void:
	var running_value: Variant = _parallel_coordinator_v01526.get("running", {})
	if not running_value is Dictionary:
		_parallel_coordinator_v01526 = {}
		return
	_parallel_cancel_in_progress_v01526 = true
	var running: Dictionary = running_value
	for worker_value in running.values():
		if not worker_value is Dictionary:
			continue
		var child_value: Variant = worker_value.get("service", null)
		if child_value is CCFGenerationServiceV01526:
			var child := child_value as CCFGenerationServiceV01526
			child.clear_pending_jobs()
			if child.has_active_job():
				child.cancel_active_job()
			child.queue_free()
	running.clear()
	_parallel_coordinator_v01526 = {}
	_parallel_cancel_in_progress_v01526 = false
