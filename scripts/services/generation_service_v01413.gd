class_name CCFGenerationServiceV01413
extends "res://scripts/services/generation_service_v0135.gd"


func queue_idea_generation(
	seed_text: String,
	profile: Dictionary,
	idea_count: int,
	retry_count: int,
	project_id: String = "",
	series_context: String = ""
) -> Dictionary:
	var safe_count := clampi(idea_count, 1, 12)
	var idea_seed := seed_text.strip_edges()
	var prompt := "Generate %d distinct roleplay character concepts." % safe_count
	if not idea_seed.is_empty():
		prompt += (
			" Use the following theme, fragments, constraints, or inspiration:\n\n%s" % idea_seed
		)
	else:
		prompt += " Make the concepts varied in genre, personality, role, and dramatic hook."
	var clean_series_context := series_context.strip_edges()
	if not clean_series_context.is_empty():
		prompt += (
			"\n\nASSIGNED SERIES BIBLE:\n%s"
			+ "\n\nKeep every concept compatible with this series while still making the ideas distinct."
		) % clean_series_context
	prompt += (
		"\n\nPOINT-OF-VIEW CONTRACT:\n"
		+ "- Describe the proposed character and scenario in neutral third person.\n"
		+ "- Use the proposed character's name, or 'the character', as the grammatical subject.\n"
		+ "- Never write 'You are <character name>' and never treat the reader as the generated character.\n"
		+ "- {{user}} always means the eventual chat user. Preserve it literally when useful.\n"
		+ "- Do not give {{user}} a name, appearance, private thoughts, dialogue, or actions unless the user's seed explicitly establishes them.\n"
		+ "- Preserve relationship roles from the seed, such as girlfriend, wife, fiancee, partner, friend, rival, or coworker.\n"
		+ "- Write each concept so it can be copied directly into Main Concept for later character generation."
	)
	prompt += (
		"\n\nReturn a JSON array only. Each array item must be an object with exactly these keys: title, concept, tags. "
		+ "title is a short working character name or concept title, concept is a detailed generation-ready third-person paragraph, and tags is an array of short strings."
	)

	var messages := [
		{
			"role": "system",
			"content": (
				"You are Character Card Forge's Idea Generator. Produce specific, roleplay-ready concepts with strong hooks rather than generic archetypes. "
				+ "Every concept must describe the generated character in neutral third person. Never use second-person phrasing such as 'You are Eden' for the generated character. "
				+ "Treat {{user}} as the future chat user and preserve that placeholder literally. Return valid JSON only."
			)
		},
		{"role": "user", "content": prompt}
	]

	return _queue_chat_job(
		"ideas",
		"Generate %d character ideas" % safe_count,
		profile,
		messages,
		"ideas",
		{
			"idea_count": safe_count,
			"seed": idea_seed,
			"project_id": project_id,
			"concept_point_of_view": "neutral_third_person",
			"user_placeholder": "{{user}}"
		},
		retry_count
	)
