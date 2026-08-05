class_name CCFGenerationServiceV01536Hotfix2
extends "res://scripts/services/generation_service_v01533_hotfix3.gd"

const IDEA_USER_AGENCY_CONTRACT_VERSION_V01536_HOTFIX2 := 2
const IDEA_VALIDATION_CONTRACT_VERSION_V01536_HOTFIX2 := "user_centric_roleplay_v4"

const REFINED_USER_AGENCY_PROMPT_V01536_HOTFIX2 := (
	"USER AGENCY & BACKSTORY CONTRACT — REFINED RULE (this supersedes any earlier blanket wording about all {{user}} actions):\n"
	+ "- {{user}} remains controlled by the person roleplaying. Do not invent substantive canon for {{user}}.\n"
	+ "- Do NOT invent {{user}}'s personality, long-term emotional tendencies, beliefs, preferences, profession/career identity, upbringing, trauma, major family history, sexual preferences, ongoing suspicions, plans, motives, or other durable backstory unless SOURCE PREMISE establishes it.\n"
	+ "- Do NOT force {{user}}'s meaningful opening response, dialogue, consent, confrontation, forgiveness, accusation, investigation, decision, or other consequential choice.\n"
	+ "- Minor temporary scene-setting circumstances ARE allowed when they simply make the opening playable and do not define {{user}} as a character. Examples: {{user}} passed out early, works late, is on a work call, is asleep, is in another room, is at work, arrives home, or has stepped out on an ordinary errand.\n"
	+ "- Ordinary past logistics may also be used as setup when they do not create a durable personality/history for {{user}}.\n"
	+ "- Describe the generated character's actions, motives, secrets, fears, plans, and pressures. Leave {{user}}'s meaningful reaction open.\n"
	+ "- Conditional wording such as 'whether {{user}} forgives her' or 'if {{user}} chooses to investigate' is allowed because it preserves the roleplayer's choice."
)

const USER_FORCED_RESPONSE_PATTERN_V01536_HOTFIX2 := (
	"(?i)\\{\\{user\\}\\}\\s+(?:then\\s+|eventually\\s+|immediately\\s+|finally\\s+)?"
	+ "(confronts?|accuses?|demands?|agrees?|refuses?|accepts?|rejects?|forgives?|attacks?|fights?|investigates?|searches?|decides?|chooses?|promises?|confesses?|responds?|reacts?|suspects?|discovers?|realizes?|realises?|notices?|asks?|says?|tells?)\\b"
)
const USER_FORCED_CONTINUOUS_PATTERN_V01536_HOTFIX2 := (
	"(?i)\\{\\{user\\}\\}\\s+(?:is|starts?|begins?|has\\s+started|has\\s+begun)\\s+"
	+ "(confronting|accusing|demanding|asking|saying|telling|investigating|searching|checking|reading|forgiving|deciding|choosing|reacting|responding|suspecting)\\b"
)
const USER_PRESCRIPTION_PATTERN_V01536_HOTFIX2 := (
	"(?i)\\{\\{user\\}\\}\\s+(must|should|needs\\s+to|has\\s+to|is\\s+expected\\s+to)\\b"
)
const USER_STATE_PATTERN_V01536_HOTFIX2 := (
	"(?i)\\{\\{user\\}\\}\\s+is\\s+"
	+ "(angry|jealous|attracted|upset|happy|sad|furious|afraid|scared|disgusted|curious|suspicious|willing|reluctant|determined|conflicted|forgiving|hostile|supportive|controlling|possessive)\\b"
)
const USER_STABLE_CANON_PATTERN_V01536_HOTFIX2 := (
	"(?i)\\{\\{user\\}\\}\\s+(has\\s+always|has\\s+never|always|usually|often|routinely|typically|tends\\s+to|prefers?|dislikes?|believes?|values?|struggles\\s+with|suffers\\s+from|is\\s+known\\s+for|is\\s+the\\s+kind\\s+of\\s+person\\s+who)\\b"
)
const USER_PROFESSION_PATTERN_V01536_HOTFIX2 := (
	"(?i)\\{\\{user\\}\\}\\s+(?:works|worked)\\s+as\\s+(?:an?\\s+)?[a-z][a-z0-9 _-]{1,60}"
)
const USER_HISTORY_POSSESSIVE_PATTERN_V01536_HOTFIX2 := (
	"(?i)\\{\\{user\\}\\}(?:'s|’s)\\s+"
	+ "(childhood|upbringing|parents?|mother|father|family\\s+history|trauma|career|profession|sexual\\s+preferences?|kinks?|fetishes?|personality|temper|trust\\s+issues|jealousy|coping\\s+style|way\\s+of\\s+coping)\\b"
)

const DETACHED_SUBJECT_PREFIXES_V01536_HOTFIX2 := [
	"observer", "an observer", "the observer",
	"narrator", "a narrator", "the narrator",
	"omniscient narrator", "world npc", "world character",
	"outsider", "an outsider", "bystander", "a bystander"
]


func queue_idea_generation(
	seed_text: String,
	profile: Dictionary,
	idea_count: int,
	retry_count: int,
	project_id: String = "",
	series_context: String = ""
) -> Dictionary:
	var result := super.queue_idea_generation(
		seed_text, profile, idea_count, retry_count, project_id, series_context
	)
	if bool(result.get("ok", false)):
		_decorate_queued_idea_job_v01536_hotfix2(str(result.get("job_id", "")))
	return result


func _seed_requests_detached_pov(seed_text: String) -> bool:
	var lowered := seed_text.to_lower()
	# Detached mode must be explicitly requested as a card/viewpoint role. A secrecy
	# phrase such as "Without {{user}} realising it" is user-centric and must never
	# trip this detector merely because it contains the words "without {{user}}".
	for marker in [
		"observer card",
		"observer character",
		"observer viewpoint",
		"observer pov",
		"narrator card",
		"narrator character",
		"narrator viewpoint",
		"narrator pov",
		"world npc",
		"world character",
		"omniscient narrator",
		"omniscient viewpoint",
		"detached pov",
		"detached point of view",
		"detached viewpoint"
	]:
		if lowered.contains(marker):
			return true
	return false


func _validate_idea_batch(ideas: Array, idea_seed_text: String) -> Dictionary:
	var valid_ideas: Array = []
	var issues: Array[String] = []
	var lowered_seed := idea_seed_text.to_lower()
	var detached_pov := _seed_requests_detached_pov(idea_seed_text)
	var requires_user_placeholder := idea_seed_text.contains("{{user}}") and not detached_pov

	for index in range(ideas.size()):
		var raw_value: Variant = ideas[index]
		if not raw_value is Dictionary:
			issues.append("Idea %d is not an object." % (index + 1))
			continue
		var normalised := _normalise_ideas([raw_value])
		if normalised.is_empty():
			issues.append("Idea %d: missing concept" % (index + 1))
			continue
		var idea: Dictionary = normalised[0]
		var local_issues: Array[String] = []
		var title := str(idea.get("title", "Untitled idea")).strip_edges()
		var character_name := str(idea.get("character_name", "")).strip_edges()
		var character_role := str(idea.get("character_role", "")).strip_edges()
		var source_anchor := str(idea.get("source_anchor", "")).strip_edges()
		var hook := str(idea.get("roleplay_hook", "")).strip_edges()
		var concept := str(idea.get("concept", "")).strip_edges()

		if character_name.is_empty():
			local_issues.append("missing character_name")
		if character_role.is_empty():
			local_issues.append("missing character_role")
		if hook.is_empty():
			local_issues.append("missing roleplay_hook")
		if concept.is_empty():
			local_issues.append("missing concept")

		if not idea_seed_text.is_empty():
			if source_anchor.is_empty():
				local_issues.append("missing source_anchor")
			elif not lowered_seed.contains(source_anchor.to_lower()):
				local_issues.append("source_anchor is not an exact phrase from the source premise")

		if _role_makes_user_the_card_subject_v01536_hotfix2(character_role):
			local_issues.append("character_role incorrectly makes {{user}} the card subject")
		elif not detached_pov and _role_uses_detached_card_subject_v01536_hotfix2(character_role):
			local_issues.append("character_role invents a detached observer/narrator card subject not requested by the source premise")

		if _contains_second_person_narration(concept):
			local_issues.append("concept uses second-person you/your narration")
		if _contains_second_person_narration(hook):
			local_issues.append("roleplay_hook uses second-person you/your narration")

		if not character_name.is_empty() and not _concept_identifies_character_v01536_hotfix2(
			concept, character_name
		):
			local_issues.append("concept does not identify its intended character in third person")

		if requires_user_placeholder:
			if not character_role.contains("{{user}}"):
				local_issues.append("character_role is not explicitly relative to {{user}}")
			if not hook.contains("{{user}}"):
				local_issues.append("roleplay_hook does not explicitly involve {{user}}")
			if not concept.contains("{{user}}"):
				local_issues.append("concept does not explicitly involve {{user}}")

		for agency_issue in _idea_user_agency_issues_v01536_hotfix2(
			idea, idea_seed_text
		):
			if not local_issues.has(agency_issue):
				local_issues.append(agency_issue)

		if local_issues.is_empty():
			valid_ideas.append(idea)
		else:
			issues.append(
				"Idea %d (%s): %s"
				% [index + 1, title, "; ".join(local_issues)]
			)

	_record_idea_validation_v01536_hotfix2(issues, valid_ideas.size(), ideas.size())
	return {"valid_ideas": valid_ideas, "issues": issues}


func _concept_identifies_character_v01536_hotfix2(
	concept: String, character_name: String
) -> bool:
	var lowered := concept.to_lower()
	var clean_name := character_name.strip_edges().to_lower()
	if clean_name.is_empty():
		return false
	if lowered.contains(clean_name) or lowered.contains("the character"):
		return true
	# Allow a clean pronoun-led paragraph when the object already supplies an
	# explicit character_name. This avoids a brittle wording requirement while
	# still rejecting second-person/generated-user POV.
	var first := lowered.strip_edges()
	return (
		first.begins_with("she ")
		or first.begins_with("he ")
		or first.begins_with("they ")
	)


func _role_makes_user_the_card_subject_v01536_hotfix2(character_role: String) -> bool:
	var lowered := character_role.strip_edges().to_lower()
	return (
		lowered == "{{user}}"
		or lowered == "user"
		or lowered.begins_with("{{user}} as ")
		or lowered.begins_with("the user as ")
	)


func _role_uses_detached_card_subject_v01536_hotfix2(character_role: String) -> bool:
	var lowered := character_role.strip_edges().to_lower()
	for prefix in DETACHED_SUBJECT_PREFIXES_V01536_HOTFIX2:
		if lowered.begins_with(str(prefix)):
			return true
	return false


func _idea_user_agency_issues_v01536_hotfix2(
	idea: Dictionary, source_premise: String
) -> Array[String]:
	var issues: Array[String] = []
	for field_id in ["concept", "roleplay_hook"]:
		var text := str(idea.get(field_id, "")).strip_edges()
		if text.is_empty():
			continue
		for violation in _user_agency_violations_in_text_v01536_hotfix2(
			text, source_premise
		):
			var issue := "%s %s" % [field_id, str(violation)]
			if not issues.has(issue):
				issues.append(issue)
	return issues


func _user_agency_violations_in_text_v01536_hotfix2(
	text: String, source_premise: String
) -> Array[String]:
	var issues: Array[String] = []
	_collect_user_regex_issues_v01536_hotfix2(
		issues,
		text,
		source_premise,
		USER_FORCED_RESPONSE_PATTERN_V01536_HOTFIX2,
		"forces a meaningful {{user}} action/response instead of leaving it to the roleplayer",
		true
	)
	_collect_user_regex_issues_v01536_hotfix2(
		issues,
		text,
		source_premise,
		USER_FORCED_CONTINUOUS_PATTERN_V01536_HOTFIX2,
		"forces a meaningful current {{user}} action/dialogue instead of leaving it to the roleplayer",
		false
	)
	_collect_user_regex_issues_v01536_hotfix2(
		issues,
		text,
		source_premise,
		USER_PRESCRIPTION_PATTERN_V01536_HOTFIX2,
		"prescribes what {{user}} must/should do",
		false
	)
	_collect_user_regex_issues_v01536_hotfix2(
		issues,
		text,
		source_premise,
		USER_STATE_PATTERN_V01536_HOTFIX2,
		"assigns a new {{user}} emotional/personality state",
		true
	)
	_collect_user_regex_issues_v01536_hotfix2(
		issues,
		text,
		source_premise,
		USER_STABLE_CANON_PATTERN_V01536_HOTFIX2,
		"invents durable {{user}} personality/history instead of temporary scene setting",
		false
	)
	_collect_user_regex_issues_v01536_hotfix2(
		issues,
		text,
		source_premise,
		USER_PROFESSION_PATTERN_V01536_HOTFIX2,
		"invents a profession/career identity for {{user}}",
		false
	)
	_collect_user_regex_issues_v01536_hotfix2(
		issues,
		text,
		source_premise,
		USER_HISTORY_POSSESSIVE_PATTERN_V01536_HOTFIX2,
		"invents substantive {{user}} backstory",
		false
	)
	return issues


func _collect_user_regex_issues_v01536_hotfix2(
	issues: Array[String],
	text: String,
	source_premise: String,
	pattern: String,
	reason: String,
	allow_conditional: bool
) -> void:
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		return
	for match_value in regex.search_all(text):
		var match := match_value as RegExMatch
		if allow_conditional and _match_is_conditional_user_choice_v01533_hotfix3(
			text, match.get_start()
		):
			continue
		var matched_text := match.get_string(0)
		if _source_contains_user_fact_v01536_hotfix2(source_premise, matched_text):
			continue
		if not issues.has("%s ('%s')" % [reason, matched_text]):
			issues.append("%s ('%s')" % [reason, matched_text])


func _source_contains_user_fact_v01536_hotfix2(
	source_premise: String, matched_text: String
) -> bool:
	var source := source_premise.to_lower()
	var clean_match := matched_text.to_lower().strip_edges()
	if source.is_empty() or clean_match.is_empty():
		return false
	if source.contains(clean_match):
		return true
	# Preserve the older action-alias compatibility for explicit source-authored
	# actions such as catch/caught or leave/left.
	var action_regex := RegEx.new()
	if action_regex.compile(USER_FORCED_RESPONSE_PATTERN_V01536_HOTFIX2) == OK:
		var action_match := action_regex.search(matched_text)
		if action_match != null:
			return _source_establishes_user_marker_v01533_hotfix3(
				source_premise, action_match.get_string(1).to_lower()
			)
	return false


func _start_idea_semantic_repair(ideas: Array, issues: Array) -> void:
	var metadata_value: Variant = _active_job.get("metadata", {})
	var metadata: Dictionary = (
		(metadata_value as Dictionary).duplicate(true)
		if metadata_value is Dictionary
		else {}
	)
	metadata["semantic_repair_attempts"] = int(
		metadata.get("semantic_repair_attempts", 0)
	) + 1
	metadata["idea_user_agency_contract_version"] = (
		IDEA_USER_AGENCY_CONTRACT_VERSION_V01536_HOTFIX2
	)
	metadata["idea_validation_contract_version"] = (
		IDEA_VALIDATION_CONTRACT_VERSION_V01536_HOTFIX2
	)
	metadata["idea_validation_issues"] = issues.duplicate(true)
	_active_job["metadata"] = metadata
	_active_job["diagnostics_validation"] = {
		"ok": false,
		"kind": "idea_identity_pov_agency",
		"issues": issues.duplicate(true),
		"contract_version": IDEA_VALIDATION_CONTRACT_VERSION_V01536_HOTFIX2
	}

	var detached_pov := _seed_requests_detached_pov(str(metadata.get("seed", "")))
	var user_rule := (
		"The source explicitly requests a detached viewpoint; preserve that request while keeping supplied {{user}} references literal. "
		if detached_pov
		else "Keep each repaired idea centred on the generated character's relationship and immediate roleplay dynamic with literal {{user}}. "
	)
	var payload_value: Variant = _active_job.get("payload", {})
	var payload: Dictionary = (
		(payload_value as Dictionary).duplicate(true)
		if payload_value is Dictionary
		else {}
	)
	payload["temperature"] = 0.1
	payload["messages"] = [
		{
			"role": "system",
			"content": (
				"You repair Character Card Forge SillyTavern idea objects. Return the full repaired JSON array only. "
				+ user_rule
				+ "The generated character must remain the clear third-person subject. Do not invent an unrelated observer/narrator card character.\n\n"
				+ REFINED_USER_AGENCY_PROMPT_V01536_HOTFIX2
			)
		},
		{
			"role": "user",
			"content": (
				"SOURCE PREMISE:\n%s\n\nVALIDATION FAILURES:\n%s\n\nIDEAS TO REPAIR:\n%s\n\n"
				+ "Repair only the reported contract problems while preserving valid details and diversity. Minor temporary {{user}} scene logistics are allowed under the refined contract. Return the same number of ideas, each with title, character_name, character_role, source_anchor, roleplay_hook, concept, tags. Return JSON only."
			) % [
				str(metadata.get("seed", "")),
				"\n".join(issues),
				JSON.stringify(ideas)
			]
		}
	]
	_active_job["payload"] = payload
	call_deferred("_start_active_request")


func idea_agency_capabilities_v01536_hotfix2() -> Dictionary:
	return {
		"format_version": IDEA_USER_AGENCY_CONTRACT_VERSION_V01536_HOTFIX2,
		"validation_contract": IDEA_VALIDATION_CONTRACT_VERSION_V01536_HOTFIX2,
		"minor_scene_logistics_allowed": true,
		"substantive_user_backstory_rejected": true,
		"forced_meaningful_user_response_rejected": true,
		"conditional_user_choices_allowed": true,
		"detached_pov_requires_explicit_role_request": true,
		"supporting_npc_roles_do_not_redefine_card_subject": true,
		"third_person_name_or_pronoun_supported": true,
		"diagnostic_validation_report": true
	}


func _decorate_queued_idea_job_v01536_hotfix2(job_id: String) -> void:
	if job_id.is_empty():
		return
	for index in range(_queue.size()):
		var job_value: Variant = _queue[index]
		if not job_value is Dictionary:
			continue
		var job: Dictionary = (job_value as Dictionary).duplicate(true)
		if str(job.get("id", "")) != job_id or str(job.get("type", "")) != "ideas":
			continue
		_queue[index] = _job_with_refined_idea_contract_v01536_hotfix2(job)
		return
	if not _active_job.is_empty() and str(_active_job.get("id", "")) == job_id:
		_active_job = _job_with_refined_idea_contract_v01536_hotfix2(_active_job)


func _job_with_refined_idea_contract_v01536_hotfix2(job_value: Dictionary) -> Dictionary:
	var job := job_value.duplicate(true)
	var payload_value: Variant = job.get("payload", {})
	var payload: Dictionary = (
		(payload_value as Dictionary).duplicate(true)
		if payload_value is Dictionary
		else {}
	)
	var messages_value: Variant = payload.get("messages", [])
	var messages: Array = messages_value.duplicate(true) if messages_value is Array else []
	for index in range(messages.size()):
		if not messages[index] is Dictionary:
			continue
		var message: Dictionary = (messages[index] as Dictionary).duplicate(true)
		var role := str(message.get("role", ""))
		if role == "system" or role == "user":
			message["content"] = (
				str(message.get("content", ""))
				+ "\n\n"
				+ REFINED_USER_AGENCY_PROMPT_V01536_HOTFIX2
			)
			messages[index] = message
	payload["messages"] = messages
	job["payload"] = payload
	var metadata_value: Variant = job.get("metadata", {})
	var metadata: Dictionary = (
		(metadata_value as Dictionary).duplicate(true)
		if metadata_value is Dictionary
		else {}
	)
	metadata["idea_user_agency_contract_version"] = (
		IDEA_USER_AGENCY_CONTRACT_VERSION_V01536_HOTFIX2
	)
	metadata["idea_validation_contract_version"] = (
		IDEA_VALIDATION_CONTRACT_VERSION_V01536_HOTFIX2
	)
	metadata["minor_user_scene_logistics_allowed"] = true
	metadata["detached_pov_requested"] = _seed_requests_detached_pov(
		str(metadata.get("seed", ""))
	)
	job["metadata"] = metadata
	return job


func _record_idea_validation_v01536_hotfix2(
	issues: Array[String], valid_count: int, total_count: int
) -> void:
	if _active_job.is_empty():
		return
	var report := {
		"ok": issues.is_empty(),
		"kind": "idea_identity_pov_agency",
		"contract_version": IDEA_VALIDATION_CONTRACT_VERSION_V01536_HOTFIX2,
		"valid_count": valid_count,
		"total_count": total_count,
		"issues": issues.duplicate(true)
	}
	_active_job["diagnostics_validation"] = report
	var metadata_value: Variant = _active_job.get("metadata", {})
	var metadata: Dictionary = (
		(metadata_value as Dictionary).duplicate(true)
		if metadata_value is Dictionary
		else {}
	)
	metadata["idea_validation_contract_version"] = (
		IDEA_VALIDATION_CONTRACT_VERSION_V01536_HOTFIX2
	)
	metadata["idea_validation_issues"] = issues.duplicate(true)
	metadata["idea_validation_valid_count"] = valid_count
	metadata["idea_validation_total_count"] = total_count
	_active_job["metadata"] = metadata
