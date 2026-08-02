class_name CCFGenerationServiceV0158
extends "res://scripts/services/generation_service_v0157.gd"


func queue_collaborator_vision_summary(
	image_path: String,
	profile: Dictionary,
	retry_count: int,
	session_id: String
) -> Dictionary:
	var vision_model := str(profile.get("vision_model", "")).strip_edges()
	if vision_model.is_empty():
		return {
			"ok": false,
			"error": "The selected Vision profile does not have a Vision model configured. Set Vision model in Settings before attaching images to Character Collaborator."
		}

	# _queue_chat_job uses profile.model as the model sent to the provider. For a
	# Vision-role request, route that field to the profile's dedicated vision_model
	# without mutating the stored profile or changing normal Text-role routing.
	var routed_profile: Dictionary = profile.duplicate(true)
	routed_profile["model"] = vision_model
	return super.queue_collaborator_vision_summary(
		image_path,
		routed_profile,
		retry_count,
		session_id
	)
