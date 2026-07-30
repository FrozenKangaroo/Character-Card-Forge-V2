extends SceneTree

const PROMPT_SERVICE = preload("res://scripts/services/image_prompt_generation_service_v01312.gd")


func _init() -> void:
	var service = PROMPT_SERVICE.new()
	var character := {
		"character_id": "char_test",
		"character": {
			"name": "Mina",
			"description": "Age: 27\nAppearance: short black hair, amber eyes, athletic build\nOutfit Style: fitted red jacket and dark jeans",
			"personality": "Confident and curious, but guarded around strangers.",
			"scenario": "Mina is waiting under neon signs outside a late-night train station in light rain.",
			"first_mes": "Mina checks the station clock, notices {{user}}, and raises one eyebrow."
		},
		"concept": {"prompt": "A night-shift rail engineer who keeps stumbling into strange incidents after work."}
	}
	var messages: Array = service.build_image_prompt_messages(
		{}, character, "stable_diffusion", "three-quarter portrait, wet pavement reflections"
	)
	_expect(messages.size() == 2, "Image prompt generation should build one system and one user message.")
	var user_message: Dictionary = messages[1]
	var user_prompt := str(user_message.get("content", ""))
	_expect(user_prompt.contains("PURPOSE-BUILT image-generation prompt"), "Prompt generation must ask the text model to author a new image prompt rather than extract tags.")
	_expect(user_prompt.contains("short black hair"), "Physical description must be supplied as visual grounding.")
	_expect(user_prompt.contains("late-night train station"), "Scenario should be available for visually expressible scene choices.")
	_expect(user_prompt.contains("Confident and curious"), "Personality may guide visible pose/expression without becoming literal image text.")
	_expect(user_prompt.contains("three-quarter portrait, wet pavement reflections"), "Explicit user visual direction must be preserved as authoritative input.")
	_expect(user_prompt.contains("20–40 visual phrases"), "Stable Diffusion mode should request a concise prompt rather than a huge tag dump.")

	var natural_messages: Array = service.build_image_prompt_messages(
		{}, character, "natural", "cinematic portrait"
	)
	var natural_user_message: Dictionary = natural_messages[1]
	var natural_prompt := str(natural_user_message.get("content", ""))
	_expect(natural_prompt.contains("80–160 words"), "Natural prompt mode should request concise image-specific prose.")
	_expect(natural_prompt.contains('"prompt"'), "Image prompt generation should request a structured positive prompt result.")
	_expect(natural_prompt.contains('"negative_prompt"'), "Image prompt generation should support an optional generated negative prompt.")

	print("v0.13.12 AI image prompt planning regression passed.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
