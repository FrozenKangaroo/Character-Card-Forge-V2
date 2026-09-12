class_name CCFGenerationServiceV0190
extends "res://scripts/services/generation_service_v0186.gd"

const RICH_AUTHORING_SERVICE = preload(
	"res://scripts/services/rich_authoring_service_v0190.gd"
)


func queue_split_character_set_v0190(
	project: Dictionary,
	batch_id: String,
	retry_character_ids: Array[String],
	profile: Dictionary,
	retry_count: int = 1
) -> Dictionary:
	var request := RICH_AUTHORING_SERVICE.build_split_request(
		project, batch_id, retry_character_ids
	)
	if not bool(request.get("ok", false)):
		return request
	return _queue_chat_job(
		"split_character_set_v0190",
		"Generate split character set",
		profile,
		request.get("messages", []),
		"object",
		{
			"project_id": str(project.get("project_id", "")),
			"batch_id": batch_id,
			"model": str(profile.get("model", "")),
			"profile_id": str(profile.get("id", profile.get("profile_id", ""))),
			"profile_name": str(profile.get("name", "")),
			"requested_character_ids": request.get(
				"requested_character_ids", []
			).duplicate(true)
		},
		retry_count
	)
