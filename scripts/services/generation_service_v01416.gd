class_name CCFGenerationServiceV01416
extends "res://scripts/services/generation_service_v01415.gd"

const IDEA_CONTRACT_VERSION_V01416 := "identity_pov_v2"
const GUARDED_ROLE_TERMS := [
	"mother", "father", "parent", "sister", "brother", "sibling", "daughter", "son",
	"observer", "outsider", "bystander", "investigator", "detective", "reporter", "therapist",
	"teacher", "boss", "coworker", "colleague", "neighbor", "neighbour", "roommate", "classmate"
]


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
	var prompt := "Generate %d distinct standalone roleplay character-card concepts." % safe_count
	if not idea_seed.is_empty():
		prompt += "\n\nSOURCE PREMISE:\n%s" % idea_seed
	else:
		prompt += "\n\nNo source premise was supplied. Create varied character concepts."
	var clean_series_context := series_context.strip_edges()
	if not clean_series_context.is_empty():
		prompt += "\n\nASSIGNED SERIES BIBLE:\n%s" % clean_series_context
		prompt += "\nKeep every idea compatible with this continuity without copying the bible verbatim."
	prompt += (
		"\n\nCHARACTER IDENTITY CONTRACT:\n"
		+ "- Every idea is for ONE standalone character card.\n"
		+ "- The intended card subject must be one of the people or relationship roles already present in SOURCE PREMISE. You may invent a name for an unnamed person, but NEVER invent a new observer, narrator, relative, investigator, bystander, or viewpoint role merely to tell the scenario.\n"
		+ "- {{user}} is the eventual chat user and can NEVER be the generated character. Preserve {{user}} literally.\n"
		+ "- character_role must state exactly who the generated character is relative to {{user}} or the premise.\n"
		+ "- source_anchor must copy a short, exact, contiguous phrase from SOURCE PREMISE that directly identifies the generated person's role. Do not use a nearby phrase about somebody else. If no source premise exists, use an empty string.\n"
		+ "- Do not reinterpret the premise by silently swapping who cheated, who is pregnant, who is partnered with whom, or any other stated relationship fact."
	)
	prompt += (
		"\n\nPOINT-OF-VIEW CONTRACT:\n"
		+ "- concept must be neutral THIRD PERSON design prose about the generated character.\n"
		+ "- Use character_name, or 'the character', as the grammatical subject.\n"
		+ "- NEVER address the reader in second person. Do not use narrative words such as you, your, yours, yourself, you're, you've, you'll, or you'd.\n"
		+ "- Refer to the future chat user only as the literal placeholder {{user}}.\n"
		+ "- Do not give {{user}} a name, appearance, private thoughts, dialogue, or actions unless SOURCE PREMISE explicitly establishes them.\n"
		+ "- The concept must be directly suitable for Main Concept without rewriting its viewpoint."
	)
	prompt += (
		"\n\nReturn JSON only as an array with exactly %d items. Each item must contain exactly these keys: "
		+ "title, character_name, character_role, source_anchor, concept, tags. "
		+ "title is a short idea title; character_name is the proposed card character's name; character_role identifies the grounded role; source_anchor is copied exactly from SOURCE PREMISE; concept is one third-person generation-ready paragraph; tags is an array of short strings."
	) % safe_count

	var messages := [
		{
			"role": "system",
			"content": (
				"You are Character Card Forge's Idea Generator. Follow the character identity and point-of-view contracts exactly. "
				+ "Each result proposes one grounded card subject from the user's premise. Never make {{user}} the card character, never invent an unrelated viewpoint character, and never narrate a concept using second-person you/your language. Return valid JSON only."
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
			"user_placeholder": "{{user}}",
			"idea_contract_version": IDEA_CONTRACT_VERSION_V01416,
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
			"concept": concept,
			"tags": tags
		})
	return ideas


func _process_completed_content(content: String) -> void:
	if str(_active_job.get("type", "")) != "ideas":
		super._process_completed_content(content)
		return
	var parse_result := _parse_job_output_with_diagnostics(content, "ideas")
	if not bool(parse_result.get("ok", false)):
		super._process_completed_content(content)
		return
	var parsed_value: Variant = parse_result.get("data", [])
	if not parsed_value is Array:
		super._process_completed_content(content)
		return
	var metadata: Dictionary = _active_job.get("metadata", {})
	var seed := str(metadata.get("seed", ""))
	var validation := _validate_idea_batch(parsed_value, seed)
	var issues: Array = validation.get("issues", [])
	if not issues.is_empty() and int(metadata.get("semantic_repair_attempts", 0)) < 1:
		_start_idea_semantic_repair(parsed_value, issues)
		return
	var accepted: Array = validation.get("valid_ideas", [])
	if accepted.is_empty():
		_handle_failure(
			"The generated ideas could not satisfy the character identity and third-person POV contract after one repair pass. No ideas were shown.",
			false
		)
		return
	var finished_job := _active_job.duplicate(true)
	_active_job.clear()
	var completed_metadata: Dictionary = finished_job.get("metadata", {}).duplicate(true)
	completed_metadata["model"] = str(finished_job.get("model", ""))
	completed_metadata["profile_name"] = str(finished_job.get("profile_name", ""))
	completed_metadata["attempts"] = int(finished_job.get("attempt", 1))
	completed_metadata["response_repair_attempts"] = int(finished_job.get("repair_attempts", 0))
	completed_metadata["semantic_repair_attempts"] = int(completed_metadata.get("semantic_repair_attempts", 0))
	completed_metadata["idea_contract_version"] = IDEA_CONTRACT_VERSION_V01416
	completed_metadata["idea_contract_rejected_count"] = issues.size()
	completed_metadata["parse_strategy"] = str(parse_result.get("strategy", "direct"))
	job_completed.emit(
		str(finished_job.get("id", "")),
		str(finished_job.get("type", "")),
		accepted,
		completed_metadata
	)
	_emit_queue_changed()
	call_deferred("_start_next_job")


func _validate_idea_batch(ideas: Array, seed: String) -> Dictionary:
	var valid_ideas: Array = []
	var issues: Array[String] = []
	var lowered_seed := seed.to_lower()
	var requires_user_placeholder := seed.contains("{{user}}")
	for index in range(ideas.size()):
		var raw: Variant = ideas[index]
		if not raw is Dictionary:
			issues.append("Idea %d is not an object." % (index + 1))
			continue
		var idea: Dictionary = raw
		var local_issues: Array[String] = []
		var character_name := str(idea.get("character_name", "")).strip_edges()
		var character_role := str(idea.get("character_role", "")).strip_edges()
		var source_anchor := str(idea.get("source_anchor", "")).strip_edges()
		var concept := str(idea.get("concept", "")).strip_edges()
		if character_name.is_empty():
			local_issues.append("missing character_name")
		if character_role.is_empty():
			local_issues.append("missing character_role")
		if concept.is_empty():
			local_issues.append("missing concept")
		if not seed.is_empty():
			if source_anchor.is_empty():
				local_issues.append("missing source_anchor")
			elif not lowered_seed.contains(source_anchor.to_lower()):
				local_issues.append("source_anchor is not an exact phrase from the source premise")
			if _role_introduces_unseeded_identity(character_role, lowered_seed):
				local_issues.append("character_role introduces a person/relationship type not present in the source premise")
		if _contains_second_person_narration(concept):
			local_issues.append("concept uses second-person you/your narration")
		if requires_user_placeholder and not concept.contains("{{user}}"):
			local_issues.append("concept dropped the literal {{user}} placeholder")
		if not character_name.is_empty():
			var lowered_concept := concept.to_lower()
			if not lowered_concept.contains(character_name.to_lower()) and not lowered_concept.contains("the character"):
				local_issues.append("concept does not identify its intended character in third person")
		var lowered_role := character_role.to_lower()
		if lowered_role == "{{user}}" or lowered_role == "user" or lowered_role.contains("the user as"):
			local_issues.append("character_role incorrectly makes {{user}} the card subject")
		if local_issues.is_empty():
			valid_ideas.append(idea)
		else:
			issues.append("Idea %d: %s" % [index + 1, _join_values(local_issues, "; ")])
	return {"valid_ideas": valid_ideas, "issues": issues}


func _contains_second_person_narration(text: String) -> bool:
	var regex := RegEx.new()
	if regex.compile("(?i)(^|[^a-z])(you|your|yours|yourself|you're|you've|you'll|you'd)([^a-z]|$)") != OK:
		return false
	return regex.search(text) != null


func _role_introduces_unseeded_identity(character_role: String, lowered_seed: String) -> bool:
	var lowered_role := character_role.to_lower()
	for term in GUARDED_ROLE_TERMS:
		var role_term := str(term)
		if lowered_role.contains(role_term) and not lowered_seed.contains(role_term):
			return true
	return false


func _start_idea_semantic_repair(ideas: Array, issues: Array) -> void:
	var metadata: Dictionary = _active_job.get("metadata", {}).duplicate(true)
	metadata["semantic_repair_attempts"] = int(metadata.get("semantic_repair_attempts", 0)) + 1
	_active_job["metadata"] = metadata
	var payload: Dictionary = _active_job.get("payload", {}).duplicate(true)
	payload["temperature"] = 0.15
	payload["messages"] = [
		{
			"role": "system",
			"content": (
				"You repair Character Card Forge idea objects. Return the full repaired JSON array only. Preserve each idea's premise and diversity while fixing every identity/POV violation. "
				+ "Every card subject must be a person/role explicitly present in SOURCE PREMISE, {{user}} can never be the card subject, source_anchor must be copied exactly from the premise, and concept must use neutral third-person prose with no narrative you/your language. Do not invent an observer, outsider, parent, investigator, or other new viewpoint role."
			)
		},
		{
			"role": "user",
			"content": (
				"SOURCE PREMISE:\n%s\n\nVALIDATION FAILURES:\n%s\n\nIDEAS TO REPAIR:\n%s\n\n"
				+ "Return the same number of ideas. Every object must contain title, character_name, character_role, source_anchor, concept, tags. Do not add commentary."
			) % [str(metadata.get("seed", "")), _join_values(issues, "\n"), JSON.stringify(ideas)]
		}
	]
	_active_job["payload"] = payload
	call_deferred("_start_active_request")
