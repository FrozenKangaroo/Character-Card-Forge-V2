class_name CCFGenerationServiceV01533
extends "res://scripts/services/generation_service_v01526.gd"


func _on_request_completed(
	result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray
) -> void:
	if _active_job.is_empty():
		return

	var body_text := body.get_string_from_utf8()
	var safe_parse := _safe_provider_envelope_v01533(body_text)
	if result != HTTPRequest.RESULT_SUCCESS:
		_record_invalid_provider_response_v01533(
			result,
			response_code,
			body_text,
			"network_error",
			"Network request failed (result %s)." % result
		)
		_handle_failure("Network request failed (result %s)." % result, true)
		return

	if not bool(safe_parse.get("ok", false)):
		var reason := str(safe_parse.get("reason", "malformed_json"))
		var detail := str(safe_parse.get("detail", "Provider response was not valid JSON."))
		_record_invalid_provider_response_v01533(
			result, response_code, body_text, reason, detail
		)
		var retryable := _provider_envelope_failure_retryable_v01533(response_code)
		_handle_failure(detail, retryable)
		return

	# Valid provider envelopes continue through the established v0.15.25/v0.15.22
	# diagnostics, termination metadata and normal response-processing pipeline.
	super._on_request_completed(result, response_code, headers, body)


func provider_response_hardening_capabilities_v01533() -> Dictionary:
	return {
		"format_version": 1,
		"silent_envelope_parse": true,
		"empty_body_guard": true,
		"malformed_body_guard": true,
		"raw_body_diagnostics": true,
		"http_and_network_diagnostics": true
	}


func _safe_provider_envelope_v01533(body_text: String) -> Dictionary:
	if body_text.strip_edges().is_empty():
		return {
			"ok": false,
			"reason": "empty_body",
			"detail": "Provider returned an empty response body. The request may have timed out or been interrupted."
		}
	var parser := JSON.new()
	var parse_error := parser.parse(body_text)
	if parse_error != OK:
		return {
			"ok": false,
			"reason": "malformed_json",
			"detail": "Provider returned an incomplete or non-JSON response (HTTP %d): %s at line %d." % [
				int(_active_job.get("response_code_v01533", 0)),
				parser.get_error_message(),
				parser.get_error_line()
			]
		}
	return {"ok": true, "data": parser.data}


func _record_invalid_provider_response_v01533(
	result: int,
	response_code: int,
	body_text: String,
	reason: String,
	detail: String
) -> void:
	# Store the same diagnostic keys used by v0.15.22 so the existing Diagnostics
	# window can still explain exactly what came back from the provider.
	_active_job["response_code_v01533"] = response_code
	var response_snapshot := {
		"timestamp": Time.get_datetime_string_from_system(true),
		"stage": _diagnostic_stage_v01522(),
		"network_result": result,
		"response_code": response_code,
		"raw_body": body_text,
		"extracted_assistant_text": "",
		"provider_envelope_valid": false,
		"provider_envelope_failure": reason,
		"provider_envelope_failure_detail": detail
	}
	_active_job["diagnostics_last_response"] = response_snapshot
	_active_job["diagnostics_last_raw_response"] = body_text
	_active_job["diagnostics_last_assistant_text"] = ""
	_append_diagnostic_event_v01522("response", response_snapshot)


func _provider_envelope_failure_retryable_v01533(response_code: int) -> bool:
	if response_code >= 500:
		return true
	if response_code in [0, 408, 409, 425, 429]:
		return true
	# A successful HTTP status with a truncated/invalid provider envelope is
	# commonly a transient proxy/connection failure and is safe to retry using the
	# existing bounded retry count.
	return response_code >= 200 and response_code < 300
