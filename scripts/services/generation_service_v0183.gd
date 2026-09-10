class_name CCFGenerationServiceV0183
extends "res://scripts/services/generation_service_v0180_hotfix1.gd"

const AI_REVIEW_SERVICE_V0183 = preload(
	"res://scripts/services/ai_review_service_v0183.gd"
)


func queue_ai_review_v0183(
	project: Dictionary,
	character_id: String,
	profile: Dictionary,
	retry_count: int = 1
) -> Dictionary:
	var request := AI_REVIEW_SERVICE_V0183.build_request(project, character_id)
	if not bool(request.get("ok", false)):
		return request
	return _queue_chat_job(
		"ai_review",
		"AI character review",
		profile,
		request.get("messages", []),
		"object",
		{
			"project_id": str(project.get("project_id", "")),
			"character_id": character_id,
			"content_hash": str(request.get("content_hash", "")),
			"rubric_version": AI_REVIEW_SERVICE_V0183.RUBRIC_VERSION
		},
		retry_count
	)
