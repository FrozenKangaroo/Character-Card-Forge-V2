class_name CCFGenerationServiceV0157
extends "res://scripts/services/generation_service_v0154.gd"


func queue_collaborator_vision_summary(
	image_path: String,
	profile: Dictionary,
	retry_count: int,
	session_id: String
) -> Dictionary:
	var image_result := _image_data_url_from_file(image_path)
	if not bool(image_result.get("ok", false)):
		return image_result

	var detail := str(profile.get("vision_detail", "auto"))
	if detail not in ["auto", "low", "high"]:
		detail = "auto"

	var prompt := """Analyse the user-attached image as complete visual reference material for a separate text-only Character Collaborator model.

Describe the ENTIRE visible image, not merely a character's physical appearance. Be comprehensive and grounded. Cover whatever is actually visible and relevant, including:
- every visible person/character and their apparent physical presentation, hair, clothing, accessories, expression, gaze, posture and pose;
- relative positions, body language, interactions between people/characters, and what they appear to be doing;
- the full setting/environment, background, foreground, furniture, architecture, weather, landscape, room type or other scene context;
- visible objects, props, food, drinks, devices, vehicles, weapons, signs, screens and other notable items;
- readable or partially readable text, signage, labels, UI, captions or written material, quoted accurately when legible;
- lighting, colour, atmosphere, visual mood, composition, camera angle/framing and depth where useful;
- whether it appears photographic, illustrated, anime/manga, 3D-rendered, game art, screenshot, comic panel or another visual style, plus notable stylistic traits;
- the apparent action/event/situation occurring in the scene when that can reasonably be inferred from visible evidence.

Separate direct visual observations from uncertain interpretation. When intent, relationship, identity, emotion or off-screen context cannot be known from the image alone, say that clearly instead of inventing it. You may provide cautious possible interpretations after the grounded description, but do not turn possibilities into facts. Do not identify real people.

Return plain text only. This output will be labelled explicitly as a Vision-model description of the user's attached image and then supplied to a separate text model. Give that text model enough scene information to decide what is relevant based on the user's later instructions."""

	var messages: Array = [
		{
			"role": "system",
			"content": "You are Character Card Forge's dedicated Vision analyst. You inspect user-attached images and produce faithful, comprehensive full-scene descriptions for a separate text-only creative model. The text model will not receive the original image, so include all materially useful visible information while distinguishing observation from inference."
		},
		{
			"role": "user",
			"content": [
				{"type": "text", "text": prompt},
				{"type": "image_url", "image_url": {"url": str(image_result.get("data_url", "")), "detail": detail}}
			]
		}
	]

	return _queue_chat_job(
		"collaborator_vision",
		"Analyse collaborator reference image with Vision model",
		profile,
		messages,
		"collaborator_text",
		{
			"session_id": session_id,
			"image_path": image_path,
			"image_name": image_path.get_file(),
			"source_role": CCFSettingsService.ROLE_VISION,
			"vision_profile_id": str(profile.get("id", "")),
			"vision_profile_name": str(profile.get("name", "Vision profile")),
			"vision_model": str(profile.get("model", "")),
			"context_provenance": "vision_description_of_user_attached_image"
		},
		retry_count
	)
