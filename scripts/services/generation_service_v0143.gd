class_name CCFGenerationServiceV0143
extends "res://scripts/services/generation_service_v0141.gd"

const REVIEW_RECOVERY_FORMAT_VERSION := 1


func _process_completed_content(content: String) -> void:
	if _active_job.is_empty() or str(_active_job.get("type", "")) != "character":
		super._process_completed_content(content)
		return

	var interview_stage := str(_active_job.get("interview_stage", ""))
	if interview_stage == "planning" or interview_stage == "retry":
		super._process_completed_content(content)
		return

	var parse_mode := str(_active_job.get("parse_mode", "object"))
	var parse_result: Dictionary = _parse_job_output_with_diagnostics(content, parse_mode)
	if not bool(parse_result.get("ok", false)):
		# Unparseable output is still a real generation failure. There is no trustworthy
		# candidate to expose to the user, so retain the existing JSON repair/failure path.
		super._process_completed_content(content)
		return

	var parsed_value: Variant = parse_result.get("data")
	if not parsed_value is Dictionary:
		super._process_completed_content(content)
		return
	var parsed_data: Dictionary = parsed_value

	var metadata_value: Variant = _active_job.get("metadata", {})
	var metadata: Dictionary = metadata_value.duplicate(true) if metadata_value is Dictionary else {}
	var contract_value: Variant = metadata.get("generation_contract", {})
	if not contract_value is Dictionary or contract_value.is_empty():
		# A missing contract is an internal pipeline error rather than a review failure.
		super._process_completed_content(content)
		return

	var contract: Dictionary = contract_value
	var report := CCFGenerationContractService.validate_generated_data(parsed_data, contract)
	var semantic_attempts := int(_active_job.get("semantic_repair_attempts", 0))
	if bool(report.get("ok", false)) or semantic_attempts < 1:
		# First semantic failure still receives the existing bounded automatic repair.
		super._process_completed_content(content)
		return

	# The automatic repair has already been tried and usable JSON still exists. Keep
	# the validator authoritative, but treat its failure as recoverable review data
	# instead of destroying the generated character candidate.
	metadata["generation_contract_report"] = report.duplicate(true)
	metadata["semantic_repair_attempts"] = semantic_attempts
	metadata["semantic_repair_used"] = true
	metadata["template_contract_blocked_preview"] = false
	metadata["review_recovery"] = {
		"format_version": REVIEW_RECOVERY_FORMAT_VERSION,
		"recoverable": true,
		"status": "warning",
		"source": "generation_contract",
		"summary": str(report.get("summary", "Generated character needs review.")),
		"issue_count": int(report.get("issue_count", 0)),
		"issues": report.get("issues", []).duplicate(true),
		"repair_attempts": semantic_attempts,
		"guidance": "The generated candidate was preserved after review failed. Apply good fields, edit proposals manually, or use the normal AI Suggest button on an affected field after applying it."
	}
	_active_job["metadata"] = metadata
	_complete_recoverable_character(parsed_data, parse_result)


func _complete_recoverable_character(parsed_data: Dictionary, parse_result: Dictionary) -> void:
	var finished_job := _active_job.duplicate(true)
	_active_job.clear()
	var completed_metadata: Dictionary = finished_job.get("metadata", {}).duplicate(true)
	completed_metadata["model"] = str(finished_job.get("model", ""))
	completed_metadata["profile_name"] = str(finished_job.get("profile_name", ""))
	completed_metadata["attempts"] = int(finished_job.get("attempt", 1))
	completed_metadata["response_repair_attempts"] = int(finished_job.get("repair_attempts", 0))
	completed_metadata["parse_strategy"] = str(parse_result.get("strategy", "direct"))
	job_completed.emit(
		str(finished_job.get("id", "")),
		str(finished_job.get("type", "")),
		parsed_data,
		completed_metadata
	)
	_emit_queue_changed()
	call_deferred("_start_next_job")
