class_name CCFImagePromptGenerationServiceV01312
extends "res://scripts/services/generation_service_v01311_hotfix.gd"


func queue_image_prompt(
	project: Dictionary,
	character_id: String,
	profile: Dictionary,
	prompt_style: String,
	extra_direction: String,
	retry_count: int
) -> Dictionary:
	var character := CCFStorageService.get_character(project, character_id)
	if character.is_empty():
		return {"ok": false, "error": "Select a saved character before generating an image prompt."}
	var messages := build_image_prompt_messages(
		project, character, prompt_style, extra_direction
	)
	if messages.is_empty():
		return {"ok": false, "error": "The selected character does not contain enough source material for an image prompt."}
	return _queue_chat_job(
		"image_prompt",
		"Generate image prompt",
		profile,
		messages,
		"object",
		{
			"project_id": str(project.get("project_id", "")),
			"character_id": character_id,
			"prompt_style": _normalise_prompt_style(prompt_style)
		},
		retry_count
	)


func build_image_prompt_messages(
	project: Dictionary,
	character: Dictionary,
	prompt_style: String,
	extra_direction: String
) -> Array:
	var character_data_value: Variant = character.get("character", {})
	var character_data: Dictionary = (
		character_data_value if character_data_value is Dictionary else {}
	)
	var source_sections: Array[String] = []
	var character_name := CCFStorageService.character_display_name(character).strip_edges()
	if not character_name.is_empty() and character_name != "Untitled Character":
		source_sections.append("NAME:\n%s" % character_name)

	var description := str(character_data.get("description", "")).strip_edges()
	if not description.is_empty():
		source_sections.append("PHYSICAL / VISUAL DESCRIPTION:\n%s" % description)
	var scenario := str(character_data.get("scenario", "")).strip_edges()
	if not scenario.is_empty():
		source_sections.append("SCENARIO:\n%s" % scenario)
	var personality := str(character_data.get("personality", "")).strip_edges()
	if not personality.is_empty():
		source_sections.append("PERSONALITY CONTEXT:\n%s" % personality)
	var first_message := str(character_data.get("first_mes", "")).strip_edges()
	if not first_message.is_empty():
		source_sections.append("OPENING-SCENE CONTEXT:\n%s" % first_message)

	var concept := str(
		CCFStorageService.get_value_at_path(character, "concept.prompt", "")
	).strip_edges()
	if concept.is_empty():
		concept = str(
			CCFStorageService.get_value_at_path(project, "concept.prompt", "")
		).strip_edges()
	if not concept.is_empty():
		source_sections.append("GENERATION CONCEPT:\n%s" % concept)

	var clean_extra := extra_direction.strip_edges()
	if not clean_extra.is_empty():
		source_sections.append(
			"USER VISUAL DIRECTION — authoritative when it specifies an image choice:\n%s"
			% clean_extra
		)
	if source_sections.is_empty():
		return []

	var style := _normalise_prompt_style(prompt_style)
	var style_instruction := ""
	if style == "stable_diffusion":
		style_instruction = (
			"Write the positive prompt in Stable Diffusion-friendly prompt language: concise visual phrases or tags, ordered by importance, with the character identity first. Avoid turning every sentence into a tag and avoid redundant synonyms. Prefer a coherent 20–40 visual phrases over a giant tag dump."
		)
	else:
		style_instruction = (
			"Write the positive prompt as concise natural-language image direction suitable for a modern image-generation model. Aim for roughly 80–160 words, with a clear subject, appearance, composition, pose/expression, lighting and setting where supported."
		)

	var prompt := (
		"Create a PURPOSE-BUILT image-generation prompt from the character material below. "
		+ "Do not merely extract phrases from Description and do not copy the card prose. Reason about what a strong single image of this character should show, then write a clean visual prompt for that image.\n\n"
		+ style_instruction
	)
	prompt += (
		"\n\nVISUAL GROUNDING RULES:\n"
		+ "- Preserve explicit physical identity, age, body/build, hair, eyes, clothing, accessories and other stable visible traits.\n"
		+ "- Use Scenario, Personality, First Message and Generation Concept only to choose visually expressible pose, expression, composition, action, setting or atmosphere. Never encode invisible internal facts as if they were visible.\n"
		+ "- Do not invent conflicting physical traits. When source prose is ambiguous, prefer the clearest stable identity details.\n"
		+ "- The user visual direction is authoritative for the requested image unless it directly contradicts an explicit immutable identity detail.\n"
		+ "- Avoid excessive ornament, symbolic meaning or ceremonial styling unless the source actually calls for it.\n"
		+ "- Keep the character visually dominant and suitable for character-card artwork.\n"
		+ "- Return an optional negative_prompt only when useful. It should contain concrete visual exclusions, not generic moral or narrative instructions."
	)
	prompt += "\n\nCHARACTER MATERIAL:\n\n%s" % "\n\n---\n\n".join(source_sections)
	prompt += (
		"\n\nReturn valid JSON only in this exact shape: "
		+ '{"prompt":"<final positive image prompt>","negative_prompt":"<optional exclusions or empty string>"}.'
	)
	var system_text := (
		"You are Character Card Forge's visual prompt writer. Convert roleplay-character material into deliberate, coherent image-generation prompts. Preserve visible identity, infer only visually expressible scene choices, and write the final prompt rather than summarising the source. Return valid JSON only."
	)
	return [
		{"role": "system", "content": system_text},
		{"role": "user", "content": prompt}
	]


func _normalise_prompt_style(prompt_style: String) -> String:
	var style := prompt_style.strip_edges().to_lower()
	return "stable_diffusion" if style == "stable_diffusion" else "natural"
