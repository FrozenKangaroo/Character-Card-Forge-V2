class_name CCFGenerationServiceV0174
extends "res://scripts/services/generation_service_v0172.gd"


func queue_front_porch_group_generation_v0174(
	project: Dictionary,
	selected_character_ids: Array[String],
	instructions: String,
	profile: Dictionary,
	retry_count: int
) -> Dictionary:
	if selected_character_ids.size() < 2:
		return {"ok": false, "error": "Select at least two characters for a Front Porch group card."}
	var valid_ids: Array[String] = []
	var character_blocks: Array[String] = []
	for character_id in selected_character_ids:
		var character := CCFStorageService.get_character(project, character_id)
		if character.is_empty():
			continue
		valid_ids.append(character_id)
		var character_data = character.get("character", {})
		var lines: Array[String] = [
			"CHARACTER ID: %s" % character_id,
			"NAME: %s" % CCFStorageService.character_display_name(character)
		]
		if character_data is Dictionary:
			for field_name in ["description", "personality", "scenario", "system_prompt"]:
				var field_text := str(character_data.get(field_name, "")).strip_edges()
				if not field_text.is_empty():
					lines.append("%s: %s" % [field_name.to_upper(), field_text])
		character_blocks.append("\n".join(lines))
	if valid_ids.size() < 2:
		return {"ok": false, "error": "At least two selected characters must still exist."}
	var prompt := (
		"Create the optional Front Porch group-card writing for the selected characters. "
		+ "Preserve every character's identity and established agency. The group system prompt "
		+ "must coordinate turn-taking and shared continuity without inventing durable facts about {{user}}. "
		+ "The group lorebook must be either an empty string or a compact valid JSON object encoded as text. "
		+ "Objectives must be concrete long-term character goals, not instructions to control {{user}}."
	)
	var shared_context := _shared_context_text(project)
	if not shared_context.is_empty():
		prompt += "\n\nSHARED PROJECT CONTEXT:\n%s" % shared_context
	var relationship_context := CCFRelationshipService.context_for_characters(project, valid_ids)
	if not relationship_context.is_empty():
		prompt += "\n\nESTABLISHED RELATIONSHIPS:\n%s" % relationship_context
	prompt += "\n\nSELECTED CHARACTERS:\n\n%s" % "\n\n---\n\n".join(character_blocks)
	var clean_instructions := instructions.strip_edges()
	if not clean_instructions.is_empty():
		prompt += "\n\nUSER INSTRUCTIONS:\n%s" % clean_instructions
	prompt += (
		"\n\nReturn one valid JSON object with exactly these top-level keys: system_prompt, "
		+ "group_lorebook, character_system_prompts, member_objectives. "
		+ "character_system_prompts must be an object keyed by every exact CHARACTER ID, with string values. "
		+ "member_objectives must be an object keyed by every exact CHARACTER ID, with array values. "
		+ "Each objective array item must be an object with title, description, status, and priority. "
		+ "Use status 'active' and integer priority 1 to 5. Return JSON only."
	)
	return _queue_chat_job(
		"front_porch_group_generation_v0174",
		"Generate Front Porch group fields",
		profile,
		[
			{"role": "system", "content": "You design portable Front Porch multi-character group cards for Character Card Forge. Return exact, restrained JSON."},
			{"role": "user", "content": prompt}
		],
		"object",
		{"project_id": str(project.get("project_id", "")), "selected_character_ids": valid_ids,
			"front_porch_group_generation_v0174": true},
		retry_count
	)
