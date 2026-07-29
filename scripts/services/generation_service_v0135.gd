class_name CCFGenerationServiceV0135
extends CCFConceptFidelityGenerationService


func _queue_chat_job(
	job_type: String,
	label: String,
	profile: Dictionary,
	messages: Array,
	parse_mode: String,
	metadata: Dictionary,
	retry_count: int
) -> Dictionary:
	var effective_profile := profile.duplicate(true)
	if job_type == "vision_analysis":
		if profile.has("vision_model"):
			effective_profile["model"] = str(profile.get("vision_model", "")).strip_edges()
		else:
			effective_profile["model"] = str(profile.get("model", "")).strip_edges()
	return super._queue_chat_job(
		job_type,
		label,
		effective_profile,
		messages,
		parse_mode,
		metadata,
		retry_count
	)
