class_name CCFGenerationServiceV0186
extends "res://scripts/services/generation_service_v0183.gd"

const COMPACT_DERIVATIVE_SERVICE = preload(
	"res://scripts/services/compact_derivative_service_v0186.gd"
)


func queue_compact_derivative_v0186(
	project: Dictionary,
	character_id: String,
	options: Dictionary,
	profile: Dictionary,
	retry_count: int = 1
) -> Dictionary:
	var request := COMPACT_DERIVATIVE_SERVICE.build_request(
		project, character_id, options
	)
	if not bool(request.get("ok", false)):
		return request
	return _queue_chat_job(
		"compact_derivative",
		"Compact/lite derivative preview",
		profile,
		request.get("messages", []),
		"object",
		{
			"project_id": str(project.get("project_id", "")),
			"character_id": character_id,
			"source_hash": str(request.get("source_hash", "")),
			"compact_options": request.get("options", {}).duplicate(true)
		},
		retry_count
	)
