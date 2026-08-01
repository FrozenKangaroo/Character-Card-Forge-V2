class_name CCFGenerationServiceV01418
extends "res://scripts/services/generation_service_v01416.gd"

const IDEA_CONTRACT_VERSION_V01418 := "user_centric_roleplay_v3"


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
	var detached_pov := _seed_requests_detached_pov(idea_seed)
	var prompt := "Generate %d distinct SillyTavern-style standalone character-card concepts." % safe_count
	if not idea_seed.is_empty():
		prompt += "\n\nSOURCE PREMISE:\n%s" % idea_seed
	else:
		prompt += "\n\nNo source premise was supplied. Create varied character concepts centred on interaction with {{user}}."
	var clean_series_context := series_context.strip_edges()
	if not clean_series_context.is_empty():
		prompt += "\n\nASSIGNED SERIES BIBLE:\n%s" % clean_series_context
		prompt += "\nKeep every idea compatible with this continuity without copying the bible verbatim."
	prompt += (
		"\n\nSILLYTAVERN ROLEPLAY CONTRACT:\n"
		+ "- These are ideas for interactive character cards, not detached fiction synopses.\n"
		+ "- Unless SOURCE PREMISE explicitly asks for an observer, narrator, world NPC, omniscient, or otherwise detached card, EVERY idea must centre the generated character's relationship and immediate roleplay dynamic with the literal placeholder {{user}}.\n"
		+ "- Every normal idea must explicitly mention {{user}} in character_role, concept, and roleplay_hook.\n"
		+ "- character_role must explain who the generated character is to {{user}} (for example: {{user}}'s best friend's girlfriend, {{user}}'s coworker, {{user}}'s rival).\n"
		+ "- roleplay_hook must explain why this character and {{user}} are interacting now and what tension, goal, secret, conflict, attraction, or situation drives the opening roleplay.\n"
		+ "- Preserve the user's stated relationship facts exactly. Do not silently replace {{user}} with a named protagonist and do not shift the scenario to unrelated people.\n"
		+ "- A concept that could remove {{user}} without materially changing the premise is NOT acceptable for the default mode."
	)
	prompt += (
		"\n\nCHARACTER IDENTITY CONTRACT:\n"
		+ "- Every idea is for ONE standalone character card.\n"
		+ "- The intended card subject must be one of the people or relationship roles already present in SOURCE PREMISE. You may invent a name for an unnamed person, but never invent a new observer, relative, investigator, bystander, or narrator merely to tell the scenario.\n"
		+ "- {{user}} is the eventual chat user and can never be the generated character. Preserve {{user}} literally.\n"
		+ "- source_anchor must copy a short exact contiguous phrase from SOURCE PREMISE proving that the card subject is grounded there. If no source premise exists, use an empty string."
	)
	prompt += (
		"\n\nPOINT-OF-VIEW CONTRACT:\n"
		+ "- concept must use neutral third-person design prose ABOUT the generated character while framing {{user}} as that character's roleplay partner.\n"
		+ "- Use character_name, or 'the character', as the grammatical subject.\n"
		+ "- Never address the reader as you/your/you're/etc. Refer to the chat partner only with the literal token {{user}}.\n"
		+ "- Do not invent a name, appearance, private thoughts, dialogue, or actions for {{user}} beyond facts explicitly supplied in SOURCE PREMISE.\n"
		+ "- The result must be directly suitable for Main Concept in a Character Card Forge / SillyTavern workflow."
	)
	if detached_pov:
		prompt += "\n\nSOURCE PREMISE explicitly requests a detached/observer-style role, so the normal requirement that every idea centre {{user}} may be relaxed only as needed to honour that request."
	prompt += (
		"\n\nReturn JSON only as an array with exactly %d items. Each item must contain exactly these keys: "
		+ "title, character_name, character_role, source_anchor, roleplay_hook, concept, tags. "
		+ "roleplay_hook is a concise sentence or two describing the immediate interaction with {{user}}. concept is one generation-ready third-person paragraph. tags is an array of short strings."
	) % safe_count

	var messages := [
		{
			"role": "system",
			"content": (
				"You are Character Card Forge's SillyTavern character-idea designer. By default every idea must be centred on the generated character interacting with {{user}}. "
				+ "Describe the card character in third person, keep {{user}} literal, never substitute a named protagonist for {{user}}, and never drift into detached fiction about unrelated characters. Return valid JSON only."
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
			"concept_point_of_view": "character_third_person_user_centric",
			"user_placeholder": "{{user}}",
			"idea_contract_version": IDEA_CONTRACT_VERSION_V01418,
			"detached_pov_requested": detached_pov,
			"semantic_repair_attempts": 0
		},
		retry_count
	)


func _normalise_ideas(raw_ideas: Array) -> Array:
	var ideas: Array = []
	for raw_idea in raw_ideas:
		if not raw_idea is Dictionary:
			continue
		var concept := str(raw_idea.get("concept", "")).strip_edges()
		if concept.is_empty():
			continue
		var tags: Array[String] = []
		var raw_tags: Variant = raw_idea.get("tags", [])
		if raw_tags is Array:
			for raw_tag in raw_tags:
				var clean_tag := str(raw_tag).strip_edges()
				if not clean_tag.is_empty() and not tags.has(clean_tag):
					tags.append(clean_tag)
		elif not str(raw_tags).strip_edges().is_empty():
			for raw_tag in str(raw_tags).split(",", false):
				var clean_tag := raw_tag.strip_edges()
				if not clean_tag.is_empty() and not tags.has(clean_tag):
					tags.append(clean_tag)
		ideas.append({
			"title": str(raw_idea.get("title", "Untitled idea")).strip_edges(),
			"character_name": str(raw_idea.get("character_name", "")).strip_edges(),
			"character_role": str(raw_idea.get("character_role", "")).strip_edges(),
			"source_anchor": str(raw_idea.get("source_anchor", "")).strip_edges(),
			"roleplay_hook": str(raw_idea.get("roleplay_hook", "")).strip_edges(),
			"concept": concept,
			"tags": tags
		})
	return ideas


func _validate_idea_batch(ideas: Array, idea_seed_text: String) -> Dictionary:
	var base_report := super._validate_idea_batch(ideas, idea_seed_text)
	var base_valid: Array = base_report.get("valid_ideas", [])
	var issues: Array[String] = []
	for issue in base_report.get("issues", []):
		issues.append(str(issue))
	var accepted: Array = []
	var detached_pov := _seed_requests_detached_pov(idea_seed_text)
	for raw in base_valid:
		if not raw is Dictionary:
			continue
		var idea: Dictionary = raw
		var local_issues: Array[String] = []
		var role := str(idea.get("character_role", "")).strip_edges()
		var hook := str(idea.get("roleplay_hook", "")).strip_edges()
		var concept := str(idea.get("concept", "")).strip_edges()
		if hook.is_empty():
			local_issues.append("missing roleplay_hook")
		if not detached_pov:
			if not role.contains("{{user}}"):
				local_issues.append("character_role is not explicitly relative to {{user}}")
			if not hook.contains("{{user}}"):
				local_issues.append("roleplay_hook does not explicitly involve {{user}}")
			if not concept.contains("{{user}}"):
				local_issues.append("concept does not explicitly involve {{user}}")
		if _contains_second_person_narration(hook):
			local_issues.append("roleplay_hook uses second-person you/your narration")
		if local_issues.is_empty():
			accepted.append(idea)
		else:
			issues.append("Idea '%s': %s" % [str(idea.get("title", "Untitled idea")), "; ".join(local_issues)])
	return {"valid_ideas": accepted, "issues": issues}


func _start_idea_semantic_repair(ideas: Array, issues: Array) -> void:
	var metadata: Dictionary = _active_job.get("metadata", {}).duplicate(true)
	metadata["semantic_repair_attempts"] = int(metadata.get("semantic_repair_attempts", 0)) + 1
	_active_job["metadata"] = metadata
	var detached_pov := bool(metadata.get("detached_pov_requested", false))
	var user_rule := (
		"Every repaired idea must explicitly centre {{user}} in character_role, roleplay_hook, and concept. "
		if not detached_pov
		else "The source explicitly requested a detached viewpoint; preserve that request while keeping any supplied {{user}} references literal. "
	)
	var payload: Dictionary = _active_job.get("payload", {}).duplicate(true)
	payload["temperature"] = 0.1
	payload["messages"] = [
		{
			"role": "system",
			"content": (
				"You repair Character Card Forge SillyTavern idea objects. Return the full repaired JSON array only. "
				+ user_rule
				+ "The generated character is described in third person; {{user}} is the literal chat partner and is never renamed or replaced by another protagonist. Do not invent unrelated viewpoint characters."
			)
		},
		{
			"role": "user",
			"content": (
				"SOURCE PREMISE:\n%s\n\nVALIDATION FAILURES:\n%s\n\nIDEAS TO REPAIR:\n%s\n\n"
				+ "Return the same number of ideas. Every object must contain title, character_name, character_role, source_anchor, roleplay_hook, concept, tags. Return JSON only."
			) % [str(metadata.get("seed", "")), "\n".join(issues), JSON.stringify(ideas)]
		}
	]
	_active_job["payload"] = payload
	call_deferred("_start_active_request")


func _seed_requests_detached_pov(seed_text: String) -> bool:
	var lowered := seed_text.to_lower()
	for marker in [
		"observer card",
		"observer character",
		"narrator card",
		"narrator character",
		"world npc",
		"world character",
		"omniscient narrator",
		"detached pov",
		"detached point of view",
		"not from {{user}}",
		"without {{user}}"
	]:
		if lowered.contains(marker):
			return true
	return false
