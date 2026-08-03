class_name CCFGenerationServiceV01525
extends "res://scripts/services/generation_service_v01522.gd"

const TOKEN_BUDGET_FORMAT_VERSION_V01525 := 1
const TOKEN_BUDGET_JOB_KEY_V01525 := "authoritative_text_max_output_tokens_v01525"


func generation_token_budget_capabilities_v01525() -> Dictionary:
	return {
		"format_version": TOKEN_BUDGET_FORMAT_VERSION_V01525,
		"character_text_budget_invariant": true,
		"interview_budget_invariant": true,
		"repair_budget_invariant": true,
		"safe_section_budget_invariant": true,
		"provider_termination_diagnostics": true
	}


func _queue_chat_job(
	job_type: String,
	label: String,
	profile: Dictionary,
	messages: Array,
	parse_mode: String,
	metadata: Dictionary,
	retry_count: int
) -> Dictionary:
	# Capture the actual Text payload budget at the moment the base character job
	# is queued, before Interview/Q&A or any later generation stage can transform
	# the payload. Every subsequent character-generation request must keep this
	# same provider/profile-derived maximum output allowance.
	var result: Dictionary = super._queue_chat_job(
		job_type,
		label,
		profile,
		messages,
		parse_mode,
		metadata,
		retry_count
	)
	if not bool(result.get("ok", false)) or job_type != "character":
		return result
	var job_id := str(result.get("job_id", ""))
	if not job_id.is_empty():
		_capture_initial_character_token_budget_v01525(job_id)
	return result


func _build_interview_payload(
	base_payload_value: Dictionary,
	concept: String,
	questions: Array,
	known_answers: Dictionary,
	missing_only: bool
) -> Dictionary:
	var payload: Dictionary = super._build_interview_payload(
		base_payload_value,
		concept,
		questions,
		known_answers,
		missing_only
	)
	# The original v0.13.1 interview implementation silently capped every
	# interview at 2,600 tokens. v0.14.0-hotfix1 removed that ceiling, but the
	# later v0.14.13/v0.15 parity inheritance restoration started from v0.13.5
	# and bypassed that hotfix. Reassert the invariant at the current leaf.
	var configured_budget := int(base_payload_value.get("max_tokens", 0))
	if configured_budget > 0:
		payload["max_tokens"] = configured_budget
	return payload


func _start_active_request() -> void:
	# This guard intentionally runs for every Character job request: initial
	# interview planning, missing-answer retries, Safe Section requests, focused
	# component/field repairs, JSON repair, semantic repair, concept-fidelity
	# correction, and Fast Full Card. A later inherited stage cannot silently
	# replace the configured output allowance with its own hard-coded ceiling.
	_enforce_character_output_budget_v01525()
	super._start_active_request()


func _on_request_completed(
	result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray
) -> void:
	if not _active_job.is_empty():
		var body_text := body.get_string_from_utf8()
		var parsed_response: Variant = JSON.parse_string(body_text)
		if parsed_response is Dictionary:
			var termination := provider_termination_from_response_v01525(parsed_response)
			if not termination.is_empty():
				_active_job["provider_termination_v01525"] = termination.duplicate(true)
				_append_diagnostic_event_v01522(
					"provider_termination", termination.duplicate(true)
				)
	super._on_request_completed(result, response_code, headers, body)


func _build_failure_diagnostics_v01522(message: String) -> Dictionary:
	var bundle: Dictionary = super._build_failure_diagnostics_v01522(message)
	var payload := _dictionary_copy_v01525(_active_job.get("payload", {}))
	var configured_budget := int(_active_job.get(TOKEN_BUDGET_JOB_KEY_V01525, 0))
	var request_budget := int(payload.get("max_tokens", 0))
	bundle["token_budget"] = {
		"format_version": TOKEN_BUDGET_FORMAT_VERSION_V01525,
		"configured_character_max_output_tokens": configured_budget,
		"request_max_tokens": request_budget,
		"hidden_stage_caps_allowed": false
	}

	var termination := _dictionary_copy_v01525(
		_active_job.get("provider_termination_v01525", {})
	)
	if not termination.is_empty():
		var finish_reason := str(termination.get("finish_reason", "")).to_lower()
		var limit_reached := bool(termination.get("limit_reached", false))
		if not limit_reached and finish_reason in ["length", "max_tokens", "max_output_tokens"]:
			limit_reached = true
		termination["limit_reached"] = limit_reached
		if limit_reached:
			termination["summary"] = (
				"The provider stopped generation because the output-token allowance was reached."
			)
		bundle["provider_termination"] = termination
	return sanitise_diagnostic_value_v01522(bundle)


func provider_termination_from_response_v01525(response: Dictionary) -> Dictionary:
	var finish_reason := str(response.get("finish_reason", "")).strip_edges()
	var response_status := str(response.get("status", "")).strip_edges()
	var incomplete_reason := ""

	var choices_value: Variant = response.get("choices", [])
	if choices_value is Array:
		for raw_choice in choices_value:
			if not raw_choice is Dictionary:
				continue
			var choice: Dictionary = raw_choice
			if finish_reason.is_empty():
				finish_reason = str(choice.get("finish_reason", "")).strip_edges()
			if not finish_reason.is_empty():
				break

	var incomplete_value: Variant = response.get("incomplete_details", {})
	if incomplete_value is Dictionary:
		incomplete_reason = str(incomplete_value.get("reason", "")).strip_edges()

	var usage := _dictionary_copy_v01525(response.get("usage", {}))
	var prompt_tokens := int(usage.get("prompt_tokens", usage.get("input_tokens", 0)))
	var completion_tokens := int(
		usage.get("completion_tokens", usage.get("output_tokens", 0))
	)
	var total_tokens := int(usage.get("total_tokens", prompt_tokens + completion_tokens))
	var normalized_reason := finish_reason.to_lower()
	var normalized_incomplete := incomplete_reason.to_lower()
	var limit_reached := (
		normalized_reason in ["length", "max_tokens", "max_output_tokens"]
		or normalized_incomplete in ["max_output_tokens", "max_tokens", "length"]
	)

	if (
		finish_reason.is_empty()
		and response_status.is_empty()
		and incomplete_reason.is_empty()
		and usage.is_empty()
	):
		return {}
	return {
		"finish_reason": finish_reason,
		"status": response_status,
		"incomplete_reason": incomplete_reason,
		"prompt_tokens": prompt_tokens,
		"completion_tokens": completion_tokens,
		"total_tokens": total_tokens,
		"limit_reached": limit_reached
	}


func _capture_initial_character_token_budget_v01525(job_id: String) -> void:
	for index in range(_queue.size()):
		var job: Dictionary = _queue[index]
		if str(job.get("id", "")) != job_id:
			continue
		_queue[index] = _job_with_character_token_budget_v01525(job)
		return
	if str(_active_job.get("id", "")) == job_id:
		_active_job = _job_with_character_token_budget_v01525(_active_job)


func _job_with_character_token_budget_v01525(job_value: Dictionary) -> Dictionary:
	var job := job_value.duplicate(true)
	var payload := _dictionary_copy_v01525(job.get("payload", {}))
	var configured_budget := int(payload.get("max_tokens", 0))
	if configured_budget <= 0:
		return job
	job[TOKEN_BUDGET_JOB_KEY_V01525] = configured_budget
	var metadata := _dictionary_copy_v01525(job.get("metadata", {}))
	metadata["text_output_budget"] = {
		"format_version": TOKEN_BUDGET_FORMAT_VERSION_V01525,
		"max_output_tokens": configured_budget,
		"source": "active_text_provider_profile",
		"hidden_stage_caps_allowed": false
	}
	job["metadata"] = metadata
	return job


func _enforce_character_output_budget_v01525() -> void:
	if _active_job.is_empty() or str(_active_job.get("type", "")) != "character":
		return
	var configured_budget := int(_active_job.get(TOKEN_BUDGET_JOB_KEY_V01525, 0))
	if configured_budget <= 0:
		configured_budget = _recover_character_output_budget_v01525(_active_job)
		if configured_budget > 0:
			_active_job[TOKEN_BUDGET_JOB_KEY_V01525] = configured_budget
	if configured_budget <= 0:
		return
	var payload := _dictionary_copy_v01525(_active_job.get("payload", {}))
	payload["max_tokens"] = configured_budget
	_active_job["payload"] = payload


func _recover_character_output_budget_v01525(job: Dictionary) -> int:
	for key in [
		"interview_character_payload",
		"safe_original_character_payload",
		"payload"
	]:
		var candidate := _dictionary_copy_v01525(job.get(key, {}))
		var budget := int(candidate.get("max_tokens", 0))
		if budget > 0:
			return budget
	var metadata := _dictionary_copy_v01525(job.get("metadata", {}))
	var budget_metadata := _dictionary_copy_v01525(metadata.get("text_output_budget", {}))
	return int(budget_metadata.get("max_output_tokens", 0))


func _dictionary_copy_v01525(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}
