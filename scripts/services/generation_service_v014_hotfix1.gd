class_name CCFGenerationServiceV014Hotfix1
extends "res://scripts/services/generation_service_v01311_hotfix.gd"


func _build_interview_payload(
	base_payload_value: Dictionary,
	concept: String,
	questions: Array,
	known_answers: Dictionary,
	missing_only: bool
) -> Dictionary:
	var payload: Dictionary = super._build_interview_payload(
		base_payload_value, concept, questions, known_answers, missing_only
	)

	# The v0.13.1 interview implementation imposed a fixed 2,600-token ceiling on
	# every private interview request. That predates large-context/reasoning models
	# and can consume the entire completion budget in reasoning before any final JSON
	# is emitted. The base character payload already carries the Text role's resolved
	# max_tokens value after Auto/manual capability and context budgeting, so preserve
	# that authoritative budget for the interview instead of applying a hidden stage cap.
	var resolved_output_limit := int(
		base_payload_value.get("max_tokens", payload.get("max_tokens", 6000))
	)
	payload["max_tokens"] = maxi(128, resolved_output_limit)
	return payload
