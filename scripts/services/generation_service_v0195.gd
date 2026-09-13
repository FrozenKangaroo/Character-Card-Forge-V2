class_name CCFGenerationServiceV0195
extends "res://scripts/services/generation_service_v0190.gd"

const ROUTING_FORMAT_VERSION_V0195 := 1
const ROUTING_PROFILE_KEY_V0195 := "_ccf_text_routing_v0195"


func text_routing_capabilities_v0195() -> Dictionary:
	return {
		"format_version": ROUTING_FORMAT_VERSION_V0195,
		"primary_is_default": true,
		"fast_suggestion_route": true,
		"deep_review_route": true,
		"single_technical_fallback": true,
		"content_failure_fallback": false,
		"fallback_chains": false,
		"actual_producer_provenance": true
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
	var routed_metadata := metadata.duplicate(true)
	var routing_value: Variant = profile.get(ROUTING_PROFILE_KEY_V0195, {})
	var routing: Dictionary = (
		routing_value.duplicate(true) if routing_value is Dictionary else {}
	)
	if not routing.is_empty():
		routed_metadata["text_routing"] = {
			"format_version": ROUTING_FORMAT_VERSION_V0195,
			"requested_task": str(routing.get("requested_task", "primary")),
			"requested_role": str(routing.get("requested_role", "text")),
			"selected_profile_id": str(routing.get("selected_profile_id", "")),
			"inherited_primary": bool(routing.get("inherited_primary", false)),
			"fallback_enabled": bool(routing.get("fallback_enabled", false)),
			"fallback_used": false
		}
		routed_metadata["profile_id"] = str(
			routing.get("selected_profile_id", profile.get("id", ""))
		)
	var result := super._queue_chat_job(
		job_type,
		label,
		profile,
		messages,
		parse_mode,
		routed_metadata,
		retry_count
	)
	if not bool(result.get("ok", false)) or routing.is_empty():
		return result
	var job_id := str(result.get("job_id", ""))
	for index in range(_queue.size()):
		var queued_value: Variant = _queue[index]
		if not queued_value is Dictionary:
			continue
		var queued: Dictionary = queued_value
		if str(queued.get("id", "")) != job_id:
			continue
		queued["text_routing_v0195"] = routing.duplicate(true)
		queued["fallback_used_v0195"] = false
		_queue[index] = queued
		break
	return result


func _on_request_completed(
	result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray
) -> void:
	if not _active_job.is_empty():
		_active_job.erase("technical_failure_category_v0195")
		var category := _technical_failure_category_v0195(
			result, response_code, body.get_string_from_utf8()
		)
		if not category.is_empty():
			_active_job["technical_failure_category_v0195"] = category
	super._on_request_completed(result, response_code, headers, body)


func _start_active_request() -> void:
	if not _active_job.is_empty():
		_active_job.erase("technical_failure_category_v0195")
	super._start_active_request()


func _handle_failure(message: String, retryable: bool) -> void:
	if _active_job.is_empty():
		return
	var attempt := int(_active_job.get("attempt", 1))
	var maximum_retries := int(_active_job.get("max_retries", 0))
	var terminal := not (retryable and attempt <= maximum_retries)
	if not terminal:
		super._handle_failure(message, retryable)
		return

	var category := str(
		_active_job.get("technical_failure_category_v0195", "")
	)
	if category.is_empty() and message.begins_with("Could not start API request"):
		category = "request_start"
	if _can_use_fallback_v0195(category):
		_start_fallback_v0195(category, message)
		return
	if bool(_active_job.get("fallback_used_v0195", false)):
		var routing := _routing_from_active_job_v0195()
		var fallback_profile: Dictionary = routing.get("fallback_profile", {})
		message = "Fallback profile %s also failed. %s" % [
			str(fallback_profile.get("name", "Fallback Text")), message
		]
	super._handle_failure(message, retryable)


func _can_use_fallback_v0195(category: String) -> bool:
	if category not in [
		"network", "request_start", "endpoint_or_model", "rate_limit", "service"
	]:
		return false
	if bool(_active_job.get("fallback_used_v0195", false)):
		return false
	var routing := _routing_from_active_job_v0195()
	if routing.is_empty() or not bool(routing.get("fallback_enabled", false)):
		return false
	var fallback_value: Variant = routing.get("fallback_profile", {})
	if not fallback_value is Dictionary or fallback_value.is_empty():
		return false
	var fallback_profile: Dictionary = fallback_value
	var fallback_id := str(fallback_profile.get("id", "")).strip_edges()
	var selected_id := str(routing.get("selected_profile_id", "")).strip_edges()
	if fallback_id.is_empty() or fallback_id == selected_id:
		return false
	return (
		not str(fallback_profile.get("base_url", "")).strip_edges().is_empty()
		and not str(fallback_profile.get("model", "")).strip_edges().is_empty()
	)


func _start_fallback_v0195(category: String, failure_message: String) -> void:
	_release_scheduler_lease_v01526()
	var routing := _routing_from_active_job_v0195()
	var fallback_profile: Dictionary = routing.get("fallback_profile", {}).duplicate(true)
	var previous_profile := {
		"profile_id": str(routing.get("selected_profile_id", "")),
		"profile_name": str(_active_job.get("profile_name", "")),
		"model": str(_active_job.get("model", "")),
		"attempts": int(_active_job.get("attempt", 1))
	}
	var fallback_record := {
		"used": true,
		"category": category,
		"reason": failure_message,
		"from": previous_profile,
		"to": {
			"profile_id": str(fallback_profile.get("id", "")),
			"profile_name": str(fallback_profile.get("name", "Fallback Text")),
			"model": str(fallback_profile.get("model", ""))
		}
	}

	_active_job["fallback_used_v0195"] = true
	_active_job["technical_failure_category_v0195"] = ""
	_active_job["url"] = _completion_url(
		str(fallback_profile.get("base_url", ""))
	)
	_active_job["headers"] = _request_headers(fallback_profile)
	_active_job["profile_name"] = str(
		fallback_profile.get("name", "Fallback Text")
	)
	_active_job["model"] = str(fallback_profile.get("model", ""))
	_active_job["attempt"] = 0
	_active_job["max_retries"] = 0
	var payload: Dictionary = _active_job.get("payload", {}).duplicate(true)
	payload["model"] = str(fallback_profile.get("model", ""))
	payload["temperature"] = float(fallback_profile.get("temperature", 0.8))
	payload["max_tokens"] = int(
		fallback_profile.get("max_output_tokens", 6000)
	)
	_active_job["payload"] = payload
	var metadata: Dictionary = _active_job.get("metadata", {}).duplicate(true)
	metadata["profile_id"] = str(fallback_profile.get("id", ""))
	metadata["fallback"] = fallback_record.duplicate(true)
	var public_routing: Dictionary = metadata.get("text_routing", {}).duplicate(true)
	public_routing["fallback_used"] = true
	public_routing["producing_profile_id"] = str(
		fallback_profile.get("id", "")
	)
	metadata["text_routing"] = public_routing
	_active_job["metadata"] = metadata
	_append_diagnostic_event_v01522("text_fallback", fallback_record)

	job_started.emit(
		str(_active_job.get("id", "")),
		str(_active_job.get("type", "")),
		"Fallback Text: %s → %s" % [
			str(previous_profile.get("profile_name", "Primary Text")),
			str(fallback_profile.get("name", "Fallback Text"))
		]
	)
	call_deferred("_start_active_request")


func _routing_from_active_job_v0195() -> Dictionary:
	var value: Variant = _active_job.get("text_routing_v0195", {})
	return value if value is Dictionary else {}


func _technical_failure_category_v0195(
	result: int, response_code: int, response_body: String = ""
) -> String:
	if result != HTTPRequest.RESULT_SUCCESS:
		return "network"
	if response_code in [404, 408, 410]:
		return "endpoint_or_model"
	if response_code in [400, 422]:
		var detail := response_body.to_lower()
		var names_model := detail.contains("model") or detail.contains("endpoint")
		var unavailable := (
			detail.contains("not found")
			or detail.contains("unavailable")
			or detail.contains("not available")
			or detail.contains("does not exist")
			or detail.contains("no endpoints")
		)
		if names_model and unavailable:
			return "endpoint_or_model"
	if response_code == 429:
		return "rate_limit"
	if response_code >= 500:
		return "service"
	return ""
