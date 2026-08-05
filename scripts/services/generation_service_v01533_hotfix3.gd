class_name CCFGenerationServiceV01533Hotfix3
extends "res://scripts/services/generation_service_v01533.gd"

const IDEA_USER_AGENCY_CONTRACT_VERSION_V01533_HOTFIX3 := 1
const USER_AGENCY_PROMPT_V01533_HOTFIX3 := (
	"USER AGENCY CONTRACT:\n"
	+ "- {{user}} is controlled exclusively by the person roleplaying.\n"
	+ "- Never decide or assert {{user}}'s new actions, dialogue, thoughts, feelings, opinions, reactions, intentions, decisions, consent, attraction, jealousy, forgiveness, hostility, or other behaviour.\n"
	+ "- Do not advance the scenario by saying {{user}} confronts, agrees, refuses, asks, follows, comforts, kisses, forgives, attacks, leaves, investigates, chooses, decides, or otherwise acts unless that specific action is already established in SOURCE PREMISE.\n"
	+ "- Facts or actions explicitly supplied for {{user}} in SOURCE PREMISE may be preserved as established setup, but do not invent what {{user}} does next.\n"
	+ "- Describe what the generated character does, wants, fears, plans, offers, reveals, hides, expects, or hopes for instead.\n"
	+ "- Set up choices, pressures, uncertainty, and consequences for {{user}} without choosing how {{user}} responds.\n"
	+ "- Conditional language such as 'whether {{user}} forgives her' or 'if {{user}} chooses to investigate' is acceptable because it leaves the roleplayer's choice open."
)

const USER_ACTION_PATTERN_V01533_HOTFIX3 := (
	"(?i)\\{\\{user\\}\\}\\s+(?:then\\s+|eventually\\s+|immediately\\s+|finally\\s+)?"
	+ "(confronts?|asks?|agrees?|refuses?|accepts?|rejects?|forgives?|leaves?|stays?|follows?|helps?|comforts?|kisses?|touches?|attacks?|fights?|investigates?|decides?|chooses?|promises?|confesses?|demands?|responds?|reacts?|becomes?|feels?|thinks?|believes?|wants?|hopes?|loves?|hates?|trusts?|distrusts?|suspects?|discovers?|realizes?|realises?|notices?|approaches?|invites?|calls?|texts?|goes?|returns?|takes?|gives?|says?|tells?|catches?|sees?)\\b"
)
const USER_PRESCRIPTION_PATTERN_V01533_HOTFIX3 := (
	"(?i)\\{\\{user\\}\\}\\s+(must|should|needs\\s+to|has\\s+to|is\\s+expected\\s+to)\\b"
)
const USER_STATE_PATTERN_V01533_HOTFIX3 := (
	"(?i)\\{\\{user\\}\\}\\s+is\\s+"
	+ "(angry|jealous|attracted|upset|happy|sad|furious|afraid|scared|disgusted|curious|suspicious|willing|reluctant|determined|conflicted|forgiving|hostile|supportive)\\b"
)

const USER_ACTION_ALIASES_V01533_HOTFIX3 := {
	"catches": ["catch", "catches", "caught"],
	"catch": ["catch", "catches", "caught"],
	"sees": ["see", "sees", "saw"],
	"see": ["see", "sees", "saw"],
	"leaves": ["leave", "leaves", "left"],
	"leave": ["leave", "leaves", "left"],
	"goes": ["go", "goes", "went"],
	"go": ["go", "goes", "went"],
	"gives": ["give", "gives", "gave"],
	"give": ["give", "gives", "gave"],
	"takes": ["take", "takes", "took"],
	"take": ["take", "takes", "took"],
	"says": ["say", "says", "said"],
	"say": ["say", "says", "said"],
	"tells": ["tell", "tells", "told"],
	"tell": ["tell", "tells", "told"]
}


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
		_decorate_queued_idea_job_v01533_hotfix3(str(result.get("job_id", "")))
	return result


func _validate_idea_batch(ideas: Array, idea_seed_text: String) -> Dictionary:
	var base_report := super._validate_idea_batch(ideas, idea_seed_text)
	var accepted: Array = []
	var issues: Array[String] = []
	for issue in base_report.get("issues", []):
		issues.append(str(issue))
	var valid_value: Variant = base_report.get("valid_ideas", [])
	var valid_ideas: Array = valid_value if valid_value is Array else []
	for raw in valid_ideas:
		if not raw is Dictionary:
			continue
		var idea: Dictionary = raw
		var agency_issues := _idea_user_agency_issues_v01533_hotfix3(
			idea, idea_seed_text
		)
		if agency_issues.is_empty():
			accepted.append(idea)
		else:
			issues.append(
				"Idea '%s': %s"
				% [
					str(idea.get("title", "Untitled idea")),
					"; ".join(agency_issues)
				]
			)
	return {"valid_ideas": accepted, "issues": issues}


func _start_idea_semantic_repair(ideas: Array, issues: Array) -> void:
	super._start_idea_semantic_repair(ideas, issues)
	if _active_job.is_empty():
		return
	var payload_value: Variant = _active_job.get("payload", {})
	if not payload_value is Dictionary:
		return
	var payload: Dictionary = (payload_value as Dictionary).duplicate(true)
	var messages_value: Variant = payload.get("messages", [])
	var messages: Array = messages_value.duplicate(true) if messages_value is Array else []
	for index in range(messages.size()):
		if not messages[index] is Dictionary:
			continue
		var message: Dictionary = (messages[index] as Dictionary).duplicate(true)
		if str(message.get("role", "")) == "system":
			message["content"] = (
				str(message.get("content", ""))
				+ "\n\n"
				+ USER_AGENCY_PROMPT_V01533_HOTFIX3
				+ "\nRepair every user-agency violation while preserving all valid character and source-premise facts."
			)
			messages[index] = message
		elif str(message.get("role", "")) == "user":
			message["content"] = (
				str(message.get("content", ""))
				+ "\n\nREPAIR REQUIREMENT:\nDo not invent or decide any action, reaction, feeling, thought, choice, dialogue, consent, or intention for {{user}}. Preserve only {{user}} actions already established by SOURCE PREMISE."
			)
			messages[index] = message
	payload["messages"] = messages
	_active_job["payload"] = payload


func idea_user_agency_capabilities_v01533_hotfix3() -> Dictionary:
	return {
		"format_version": IDEA_USER_AGENCY_CONTRACT_VERSION_V01533_HOTFIX3,
		"prompt_contract": true,
		"semantic_validation": true,
		"bounded_repair": true,
		"source_premise_actions_preserved": true,
		"conditional_user_choices_allowed": true,
		"fields_checked": ["concept", "roleplay_hook"]
	}


func _decorate_queued_idea_job_v01533_hotfix3(job_id: String) -> void:
	if job_id.is_empty():
		return
	for index in range(_queue.size()):
		var job_value: Variant = _queue[index]
		if not job_value is Dictionary:
			continue
		var job: Dictionary = (job_value as Dictionary).duplicate(true)
		if str(job.get("id", "")) != job_id or str(job.get("type", "")) != "ideas":
			continue
		var payload_value: Variant = job.get("payload", {})
		if not payload_value is Dictionary:
			return
		var payload: Dictionary = (payload_value as Dictionary).duplicate(true)
		var messages_value: Variant = payload.get("messages", [])
		var messages: Array = messages_value.duplicate(true) if messages_value is Array else []
		for message_index in range(messages.size()):
			if not messages[message_index] is Dictionary:
				continue
			var message: Dictionary = (messages[message_index] as Dictionary).duplicate(true)
			var role := str(message.get("role", ""))
			if role == "system" or role == "user":
				message["content"] = (
					str(message.get("content", ""))
					+ "\n\n"
					+ USER_AGENCY_PROMPT_V01533_HOTFIX3
				)
				messages[message_index] = message
		payload["messages"] = messages
		job["payload"] = payload
		var metadata_value: Variant = job.get("metadata", {})
		var metadata: Dictionary = (
			(metadata_value as Dictionary).duplicate(true)
			if metadata_value is Dictionary
			else {}
		)
		metadata["idea_user_agency_contract_version"] = (
			IDEA_USER_AGENCY_CONTRACT_VERSION_V01533_HOTFIX3
		)
		job["metadata"] = metadata
		_queue[index] = job
		return


func _idea_user_agency_issues_v01533_hotfix3(
	idea: Dictionary, source_premise: String
) -> Array[String]:
	var issues: Array[String] = []
	for field_id in ["concept", "roleplay_hook"]:
		var text := str(idea.get(field_id, "")).strip_edges()
		if text.is_empty():
			continue
		for violation in _user_agency_violations_in_text_v01533_hotfix3(
			text, source_premise
		):
			var issue := "%s %s" % [field_id, str(violation)]
			if not issues.has(issue):
				issues.append(issue)
	return issues


func _user_agency_violations_in_text_v01533_hotfix3(
	text: String, source_premise: String
) -> Array[String]:
	var issues: Array[String] = []
	var action_regex := RegEx.new()
	if action_regex.compile(USER_ACTION_PATTERN_V01533_HOTFIX3) == OK:
		for match_value in action_regex.search_all(text):
			var match := match_value as RegExMatch
			if _match_is_conditional_user_choice_v01533_hotfix3(text, match.get_start()):
				continue
			var action := match.get_string(1).to_lower()
			if _source_establishes_user_marker_v01533_hotfix3(source_premise, action):
				continue
			issues.append(
				"asserts a new {{user}} action/reaction ('%s') instead of leaving it to the roleplayer"
				% match.get_string(0)
			)

	var prescription_regex := RegEx.new()
	if prescription_regex.compile(USER_PRESCRIPTION_PATTERN_V01533_HOTFIX3) == OK:
		for match_value in prescription_regex.search_all(text):
			var match := match_value as RegExMatch
			if _match_is_conditional_user_choice_v01533_hotfix3(text, match.get_start()):
				continue
			issues.append(
				"prescribes what {{user}} must/should do ('%s')" % match.get_string(0)
			)

	var state_regex := RegEx.new()
	if state_regex.compile(USER_STATE_PATTERN_V01533_HOTFIX3) == OK:
		for match_value in state_regex.search_all(text):
			var match := match_value as RegExMatch
			if _match_is_conditional_user_choice_v01533_hotfix3(text, match.get_start()):
				continue
			var state := match.get_string(1).to_lower()
			if _source_establishes_user_marker_v01533_hotfix3(source_premise, state):
				continue
			issues.append(
				"asserts a new {{user}} feeling/state ('%s') instead of leaving it to the roleplayer"
				% match.get_string(0)
			)
	return issues


func _match_is_conditional_user_choice_v01533_hotfix3(
	text: String, start_index: int
) -> bool:
	var prefix_start := maxi(0, start_index - 36)
	var prefix := text.substr(prefix_start, start_index - prefix_start).to_lower()
	for marker in ["whether ", "if ", "depending on whether ", "depending on how "]:
		if prefix.ends_with(marker):
			return true
	return false


func _source_establishes_user_marker_v01533_hotfix3(
	source_premise: String, marker: String
) -> bool:
	var source := source_premise.to_lower()
	if source.is_empty() or not source.contains("{{user}}"):
		return false
	var aliases: Array = USER_ACTION_ALIASES_V01533_HOTFIX3.get(
		marker.to_lower(), [marker.to_lower()]
	)
	var cursor := 0
	while cursor >= 0 and cursor < source.length():
		var user_index := source.find("{{user}}", cursor)
		if user_index < 0:
			break
		var window := source.substr(user_index, mini(120, source.length() - user_index))
		for alias_value in aliases:
			var alias := str(alias_value).strip_edges()
			if not alias.is_empty() and window.contains(alias):
				return true
		cursor = user_index + 8
	return false
