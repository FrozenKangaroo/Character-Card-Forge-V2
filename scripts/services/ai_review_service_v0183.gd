class_name CCFAIReviewServiceV0183
extends RefCounted

const VERSION := "0.18.3"
const RUBRIC_VERSION := 1
const REVIEW_KEY := "ai_review_v0183"
const MAX_HISTORY := 25

const RUBRIC := [
	{"id": "consistency", "label": "Consistency", "weight": 20},
	{"id": "clarity", "label": "Clarity", "weight": 10},
	{"id": "depth", "label": "Depth", "weight": 10},
	{"id": "scenario_quality", "label": "Scenario quality", "weight": 10},
	{"id": "greeting_quality", "label": "Greeting quality", "weight": 10},
	{"id": "lore_quality", "label": "Lore quality", "weight": 10},
	{"id": "prompt_efficiency", "label": "Prompt efficiency", "weight": 10},
	{"id": "roleplay_readiness", "label": "Roleplay readiness", "weight": 20}
]

const EDITABLE_PATHS := [
	"metadata.name",
	"metadata.description",
	"metadata.tags",
	"concept.prompt",
	"concept.notes",
	"character.name",
	"character.description",
	"character.personality",
	"character.scenario",
	"character.first_message",
	"character.example_dialogue",
	"character.creator_notes",
	"character.system_prompt",
	"character.post_history_instructions",
	"character.alternate_greetings",
	"character.character_book"
]


static func capabilities() -> Dictionary:
	return {
		"version": VERSION,
		"rubric_version": RUBRIC_VERSION,
		"advisory_score": true,
		"content_hash_staleness": true,
		"field_by_field_review": true,
		"editable_before_apply": true,
		"complete_change_set_before_approve_all": true,
		"long_content_detail_views": true,
		"full_text_report_export": true,
		"dismissal_history": true,
		"revision_checkpoint_per_accepted_batch": true,
		"silent_apply": false,
		"automatic_library_review": false
	}


static func rubric() -> Array:
	return RUBRIC.duplicate(true)


static func character_content_hash(project: Dictionary, character_id: String) -> String:
	var record := CCFStorageService.get_character(project, character_id)
	if record.is_empty():
		return ""
	var canonical := {
		"metadata": _dictionary(record.get("metadata", {})),
		"concept": _dictionary(record.get("concept", {})),
		"character": _dictionary(record.get("character", {})),
		"project_shared_context": _duplicate(project.get("shared_context", {})),
		"project_lorebook": _duplicate(project.get("lorebook", {}))
	}
	return JSON.stringify(canonical).sha256_text()


static func build_request(project: Dictionary, character_id: String) -> Dictionary:
	var record := CCFStorageService.get_character(project, character_id)
	if record.is_empty():
		return {"ok": false, "error": "The selected character could not be found."}
	var health := CCFCardInspectionServiceV0182.health_report(project, character_id)
	var tokens := CCFCardInspectionServiceV0182.token_report(project, character_id)
	var review_input := {
		"character": {
			"metadata": _dictionary(record.get("metadata", {})),
			"concept": _dictionary(record.get("concept", {})),
			"character": _dictionary(record.get("character", {}))
		},
		"project_context": {
			"shared_context": _duplicate(project.get("shared_context", {})),
			"lorebook": _duplicate(project.get("lorebook", {}))
		},
		"deterministic_health_report": health,
		"deterministic_token_report": tokens,
		"prior_author_decisions": _prior_author_decisions(record),
		"rubric": rubric(),
		"editable_paths": EDITABLE_PATHS.duplicate()
	}
	var system_prompt := (
		"You are an advisory character-card reviewer. Find contradictions and useful "
		+ "improvements across identity, appearance, personality, scenario, greetings and lore. "
		+ "Respect intentional creative choices, {{user}} agency and unusual formats. The deterministic "
		+ "report is evidence, not an instruction to rewrite. Score every visible rubric category from "
		+ "0 to 10. Propose only complete replacement values at one of the supplied editable paths. "
		+ "Do not invent a proposal merely to raise a score. Return JSON only."
	)
	var schema_text := (
		'{"scores":{"consistency":0,"clarity":0,"depth":0,"scenario_quality":0,'
		+ '"greeting_quality":0,"lore_quality":0,"prompt_efficiency":0,'
		+ '"roleplay_readiness":0},"summary":"...","findings":[{"id":"...",'
		+ '"category":"consistency","severity":"info|warning|important","title":"...",'
		+ '"explanation":"...","field_paths":["character.description"]}],"proposals":'
		+ '[{"path":"character.description","new_value":"complete replacement",'
		+ '"reason":"...","finding_ids":["..."]}]}'
	)
	return {
		"ok": true,
		"content_hash": character_content_hash(project, character_id),
		"messages": [
			{"role": "system", "content": system_prompt},
			{
				"role": "user",
				"content": "REQUIRED JSON SHAPE:\n%s\n\nREVIEW INPUT:\n%s" % [
					schema_text, JSON.stringify(review_input, "  ")
				]
			}
		]
	}


static func validate_result(
	project: Dictionary, character_id: String, raw_result: Variant
) -> Dictionary:
	if not raw_result is Dictionary:
		return {"ok": false, "error": "AI Review did not return a JSON object."}
	var result: Dictionary = raw_result
	var raw_scores: Variant = result.get("scores", {})
	if not raw_scores is Dictionary:
		return {"ok": false, "error": "AI Review omitted the versioned rubric scores."}
	var scores: Dictionary = {}
	var weighted_total := 0.0
	var total_weight := 0.0
	for category in RUBRIC:
		var category_id := str(category.get("id", ""))
		var score_value: Variant = (raw_scores as Dictionary).get(category_id)
		if not score_value is int and not score_value is float:
			return {"ok": false, "error": "AI Review omitted the %s score." % category_id}
		var score := clampf(float(score_value), 0.0, 10.0)
		scores[category_id] = score
		var weight := float(category.get("weight", 0))
		weighted_total += score * weight
		total_weight += weight
	var findings: Array = []
	var raw_findings: Variant = result.get("findings", [])
	if raw_findings is Array:
		for index in range((raw_findings as Array).size()):
			var finding_value: Variant = (raw_findings as Array)[index]
			if not finding_value is Dictionary:
				continue
			var finding: Dictionary = finding_value
			var finding_id := str(finding.get("id", "finding_%03d" % index)).strip_edges()
			if finding_id.is_empty():
				finding_id = "finding_%03d" % index
			findings.append({
				"id": finding_id,
				"category": str(finding.get("category", "consistency")),
				"severity": _severity(str(finding.get("severity", "info"))),
				"title": str(finding.get("title", "Review note")).strip_edges(),
				"explanation": str(finding.get("explanation", "")).strip_edges(),
				"field_paths": _string_array(finding.get("field_paths", []))
			})
	var record := CCFStorageService.get_character(project, character_id)
	var proposals: Array = []
	var seen_paths: Dictionary = {}
	var raw_proposals: Variant = result.get("proposals", [])
	if raw_proposals is Array:
		for proposal_value in raw_proposals as Array:
			if not proposal_value is Dictionary:
				continue
			var proposal: Dictionary = proposal_value
			var field_path := str(proposal.get("path", "")).strip_edges()
			if not field_path in EDITABLE_PATHS or seen_paths.has(field_path):
				continue
			var current_value: Variant = CCFStorageService.get_value_at_path(record, field_path, null)
			var proposed_value: Variant = proposal.get("new_value")
			if not _compatible_value(field_path, current_value, proposed_value):
				continue
			seen_paths[field_path] = true
			proposals.append({
				"path": field_path,
				"label": _label_for_path(field_path),
				"current_value": _duplicate(current_value),
				"new_value": _duplicate(proposed_value),
				"reason": str(proposal.get("reason", "")).strip_edges(),
				"finding_ids": _string_array(proposal.get("finding_ids", []))
			})
	return {
		"ok": true,
		"rubric_version": RUBRIC_VERSION,
		"scores": scores,
		"overall_score": snappedf(weighted_total / maxf(total_weight, 1.0), 0.1),
		"summary": str(result.get("summary", "")).strip_edges(),
		"findings": findings,
		"proposals": proposals
	}


static func record_review(
	project: Dictionary,
	character_id: String,
	validated_result: Dictionary,
	request_metadata: Dictionary
) -> Dictionary:
	if not bool(validated_result.get("ok", false)):
		return {"ok": false, "error": "Only a validated AI Review can be recorded."}
	var index := CCFStorageService.character_index(project, character_id)
	if index < 0:
		return {"ok": false, "error": "The selected character could not be found."}
	var characters: Array = project.get("characters", []).duplicate(true)
	var record: Dictionary = (characters[index] as Dictionary).duplicate(true)
	var state := _review_state(record)
	var reviews: Array = state.get("reviews", []).duplicate(true)
	var review_id := Crypto.new().generate_random_bytes(16).hex_encode()
	var review := {
		"review_id": review_id,
		"created_at": Time.get_datetime_string_from_system(true),
		"content_hash": character_content_hash(project, character_id),
		"rubric_version": RUBRIC_VERSION,
		"model": str(request_metadata.get("model", "")),
		"profile_name": str(request_metadata.get("profile_name", "")),
		"scores": _dictionary(validated_result.get("scores", {})),
		"overall_score": float(validated_result.get("overall_score", 0.0)),
		"summary": str(validated_result.get("summary", "")),
		"findings": _array(validated_result.get("findings", [])),
		"proposals": _array(validated_result.get("proposals", [])),
		"decisions": [],
		"status": "reviewed"
	}
	reviews.append(review)
	while reviews.size() > MAX_HISTORY:
		reviews.pop_front()
	state["format_version"] = 1
	state["latest_review_id"] = review_id
	state["reviews"] = reviews
	record[REVIEW_KEY] = state
	characters[index] = record
	project["characters"] = characters
	return {"ok": true, "project": project, "review": review.duplicate(true)}


static func list_reviews(project: Dictionary, character_id: String) -> Array:
	var record := CCFStorageService.get_character(project, character_id)
	return _array(_review_state(record).get("reviews", []))


static func latest_review(project: Dictionary, character_id: String) -> Dictionary:
	var reviews := list_reviews(project, character_id)
	if reviews.is_empty():
		return {}
	return (reviews[-1] as Dictionary).duplicate(true)


static func get_review(
	project: Dictionary, character_id: String, review_id: String
) -> Dictionary:
	for review_value in list_reviews(project, character_id):
		if (
			review_value is Dictionary
			and str((review_value as Dictionary).get("review_id", "")) == review_id
		):
			return (review_value as Dictionary).duplicate(true)
	return {}


static func review_is_stale(
	project: Dictionary, character_id: String, review: Dictionary
) -> bool:
	return (
		str(review.get("content_hash", "")).is_empty()
		or str(review.get("content_hash", "")) != character_content_hash(project, character_id)
	)


static func full_report_text(
	project: Dictionary, character_id: String, review: Dictionary
) -> String:
	if review.is_empty():
		return "No AI Review is selected."
	var record := CCFStorageService.get_character(project, character_id)
	var lines: Array[String] = []
	lines.append("CHARACTER CARD FORGE — AI REVIEW REPORT")
	lines.append("Advisory assessment; the score is not an objective measure of quality.")
	lines.append("")
	lines.append("Character: %s" % CCFStorageService.character_display_name(record))
	lines.append("Review ID: %s" % str(review.get("review_id", "")))
	lines.append("Created: %s" % str(review.get("created_at", "")))
	lines.append("Status: %s" % str(review.get("status", "reviewed")).capitalize())
	lines.append("Current state: %s" % (
		"STALE — relevant content changed after this review"
		if review_is_stale(project, character_id, review)
		else "Current"
	))
	lines.append("Model: %s" % str(review.get("model", "Not recorded")))
	lines.append("Profile: %s" % str(review.get("profile_name", "Not recorded")))
	lines.append("Rubric version: %d" % int(review.get("rubric_version", 0)))
	lines.append("Reviewed content hash: %s" % str(review.get("content_hash", "")))
	lines.append("Overall advisory score: %.1f / 10" % float(review.get("overall_score", 0.0)))
	lines.append("")
	lines.append("RUBRIC SCORES")
	var scores: Dictionary = _dictionary(review.get("scores", {}))
	for category in RUBRIC:
		var category_id := str(category.get("id", ""))
		lines.append("- %s: %.1f / 10 (weight %d%%)" % [
			str(category.get("label", category_id)),
			float(scores.get(category_id, 0.0)),
			int(category.get("weight", 0))
		])
	lines.append("")
	lines.append("SUMMARY")
	lines.append(str(review.get("summary", "No summary supplied.")))
	lines.append("")
	var dismissed: Array = _array(review.get("dismissed_finding_ids", []))
	var findings: Array = _array(review.get("findings", []))
	lines.append("FINDINGS (%d)" % findings.size())
	if findings.is_empty():
		lines.append("No findings were returned.")
	for index in range(findings.size()):
		var finding: Dictionary = findings[index]
		var finding_id := str(finding.get("id", ""))
		lines.append("")
		lines.append("%d. [%s] %s" % [
			index + 1,
			str(finding.get("severity", "info")).to_upper(),
			str(finding.get("title", "Review note"))
		])
		lines.append("   Category: %s" % str(finding.get("category", "")))
		var field_paths := _string_array(finding.get("field_paths", []))
		lines.append("   Fields: %s" % (
			", ".join(field_paths) if not field_paths.is_empty() else "None specified"
		))
		lines.append("   Author decision: %s" % (
			"Intentionally dismissed" if dismissed.has(finding_id) else "Not dismissed"
		))
		lines.append("   Explanation:")
		lines.append(_indent_text(str(finding.get("explanation", "")), "      "))
	lines.append("")
	var decision_by_path: Dictionary = {}
	for decision_value in review.get("decisions", []):
		if decision_value is Dictionary:
			var decision: Dictionary = decision_value
			var decision_path := str(decision.get("path", ""))
			if not decision_path.is_empty():
				decision_by_path[decision_path] = decision
	var proposals: Array = _array(review.get("proposals", []))
	lines.append("SELECTIVE CHANGES (%d)" % proposals.size())
	if proposals.is_empty():
		lines.append("No field changes were proposed.")
	for index in range(proposals.size()):
		var proposal: Dictionary = proposals[index]
		var field_path := str(proposal.get("path", ""))
		var decision: Dictionary = decision_by_path.get(field_path, {})
		var action := str(decision.get("action", "pending")).capitalize()
		lines.append("")
		lines.append("%d. %s" % [index + 1, str(proposal.get("label", field_path))])
		lines.append("   Path: %s" % field_path)
		lines.append("   Decision: %s" % action)
		lines.append("   Reason:")
		lines.append(_indent_text(str(proposal.get("reason", "")), "      "))
		lines.append("   Current value:")
		lines.append(_indent_text(_report_value(proposal.get("current_value")), "      "))
		lines.append("   Proposed value:")
		lines.append(_indent_text(_report_value(proposal.get("new_value")), "      "))
		if str(decision.get("action", "")) == "approve" and decision.has("value"):
			lines.append("   Applied/edited value:")
			lines.append(_indent_text(_report_value(decision.get("value")), "      "))
	return "\n".join(lines).strip_edges() + "\n"


static func apply_review_decisions(
	project: Dictionary,
	character_id: String,
	review_id: String,
	decisions: Array
) -> Dictionary:
	var index := CCFStorageService.character_index(project, character_id)
	if index < 0:
		return {"ok": false, "error": "The selected character could not be found."}
	var characters: Array = project.get("characters", []).duplicate(true)
	var record: Dictionary = (characters[index] as Dictionary).duplicate(true)
	var state := _review_state(record)
	var reviews: Array = state.get("reviews", []).duplicate(true)
	var review_index := -1
	for candidate_index in range(reviews.size()):
		if str((reviews[candidate_index] as Dictionary).get("review_id", "")) == review_id:
			review_index = candidate_index
			break
	if review_index < 0:
		return {"ok": false, "error": "The selected AI Review could not be found."}
	var review: Dictionary = (reviews[review_index] as Dictionary).duplicate(true)
	if review_is_stale(project, character_id, review):
		return {"ok": false, "error": "This review is stale because relevant card content changed. Run a new review before applying it."}
	var proposal_by_path: Dictionary = {}
	for proposal_value in review.get("proposals", []):
		if proposal_value is Dictionary:
			proposal_by_path[str((proposal_value as Dictionary).get("path", ""))] = proposal_value
	var supplied_decisions: Dictionary = {}
	var dismissed_findings: Array[String] = []
	for decision_value in decisions:
		if not decision_value is Dictionary:
			continue
		var supplied: Dictionary = decision_value
		if str(supplied.get("action", "")) == "dismiss_finding":
			var supplied_finding_id := str(supplied.get("finding_id", "")).strip_edges()
			if not supplied_finding_id.is_empty() and not dismissed_findings.has(supplied_finding_id):
				dismissed_findings.append(supplied_finding_id)
			continue
		var supplied_path := str(supplied.get("path", ""))
		if proposal_by_path.has(supplied_path):
			supplied_decisions[supplied_path] = supplied.duplicate(true)
	var accepted: Array[String] = []
	var recorded_decisions: Array = []
	for proposal_value in review.get("proposals", []):
		if not proposal_value is Dictionary:
			continue
		var proposal: Dictionary = proposal_value
		var field_path := str(proposal.get("path", ""))
		var decision: Dictionary = supplied_decisions.get(
			field_path, {"path": field_path, "action": "reject"}
		)
		var action := str(decision.get("action", "reject"))
		if action != "approve":
			action = "reject"
		var recorded := {"path": field_path, "action": action}
		if action == "approve":
			var proposed_value: Variant = decision.get(
				"value", proposal.get("new_value")
			)
			var current_value: Variant = CCFStorageService.get_value_at_path(record, field_path, null)
			if not _compatible_value(field_path, current_value, proposed_value):
				return {"ok": false, "error": "The edited value for %s has an incompatible type." % field_path}
			recorded["value"] = _duplicate(proposed_value)
			accepted.append(field_path)
		recorded_decisions.append(recorded)
	for finding_id in dismissed_findings:
		recorded_decisions.append({
			"action": "dismiss_finding", "finding_id": finding_id
		})
	if not accepted.is_empty():
		CCFRevisionServiceV0181.create_checkpoint(
			record,
			"Before AI Review changes",
			"Recovery point before applying an explicitly reviewed AI change set.",
			"pre_ai_review",
			{"review_id": review_id},
			true
		)
		for recorded in recorded_decisions:
			if str(recorded.get("action", "")) == "approve":
				CCFStorageService.set_value_at_path(
					record, str(recorded.get("path", "")), _duplicate(recorded.get("value"))
				)
		record["updated_at"] = Time.get_datetime_string_from_system(true)
	review["decisions"] = recorded_decisions
	review["status"] = "applied" if not accepted.is_empty() else "dismissed"
	review["decided_at"] = Time.get_datetime_string_from_system(true)
	review["accepted_paths"] = accepted.duplicate()
	review["dismissed_finding_ids"] = dismissed_findings.duplicate()
	reviews[review_index] = review
	state["reviews"] = reviews
	record[REVIEW_KEY] = state
	if not accepted.is_empty():
		CCFRevisionServiceV0181.create_checkpoint(
			record,
			"AI Review applied",
			"Applied %d explicitly approved AI Review field(s)." % accepted.size(),
			"ai_review_apply",
			{"review_id": review_id, "paths": accepted.duplicate()},
			true
		)
	characters[index] = record
	project["characters"] = characters
	return {
		"ok": true,
		"project": project,
		"accepted_count": accepted.size(),
		"review": review.duplicate(true)
	}


static func _review_state(record: Dictionary) -> Dictionary:
	var state_value: Variant = record.get(REVIEW_KEY, {})
	var state := _dictionary(state_value)
	state["format_version"] = 1
	state["reviews"] = _array(state.get("reviews", []))
	return state


static func _prior_author_decisions(record: Dictionary) -> Array:
	var context: Array = []
	var reviews: Array = _review_state(record).get("reviews", [])
	var first_index := maxi(0, reviews.size() - 5)
	for index in range(first_index, reviews.size()):
		var review_value: Variant = reviews[index]
		if not review_value is Dictionary:
			continue
		var review: Dictionary = review_value
		var proposal_by_path: Dictionary = {}
		for proposal_value in review.get("proposals", []):
			if proposal_value is Dictionary:
				proposal_by_path[str((proposal_value as Dictionary).get("path", ""))] = proposal_value
		var finding_by_id: Dictionary = {}
		for finding_value in review.get("findings", []):
			if finding_value is Dictionary:
				finding_by_id[str((finding_value as Dictionary).get("id", ""))] = finding_value
		var decisions: Array = []
		for decision_value in review.get("decisions", []):
			if not decision_value is Dictionary:
				continue
			var decision: Dictionary = decision_value
			var decision_context := {
				"action": str(decision.get("action", "")),
				"path": str(decision.get("path", "")),
				"finding_id": str(decision.get("finding_id", ""))
			}
			var decision_path := str(decision.get("path", ""))
			if proposal_by_path.has(decision_path):
				var proposal: Dictionary = proposal_by_path[decision_path]
				decision_context["proposal_reason"] = str(proposal.get("reason", ""))
				decision_context["finding_ids"] = _string_array(
					proposal.get("finding_ids", [])
				)
			var decision_finding_id := str(decision.get("finding_id", ""))
			if finding_by_id.has(decision_finding_id):
				var finding: Dictionary = finding_by_id[decision_finding_id]
				decision_context["finding_title"] = str(finding.get("title", ""))
				decision_context["finding_explanation"] = str(
					finding.get("explanation", "")
				)
			decisions.append(decision_context)
		if decisions.is_empty():
			continue
		context.append({
			"review_id": str(review.get("review_id", "")),
			"created_at": str(review.get("created_at", "")),
			"status": str(review.get("status", "")),
			"decisions": decisions
		})
	return context


static func _compatible_value(path: String, current_value: Variant, proposed_value: Variant) -> bool:
	if path == "metadata.tags" or path == "character.alternate_greetings":
		return proposed_value is Array
	if path == "character.character_book":
		return proposed_value is Dictionary
	if current_value == null:
		return proposed_value is String
	return typeof(current_value) == typeof(proposed_value)


static func _label_for_path(path: String) -> String:
	return path.replace("_", " ").replace(".", " › ").capitalize()


static func _report_value(value: Variant) -> String:
	if value is Dictionary or value is Array:
		return JSON.stringify(value, "  ")
	return str(value)


static func _indent_text(value: String, prefix: String) -> String:
	var text := value if not value.is_empty() else "(empty)"
	return prefix + text.replace("\n", "\n" + prefix)


static func _severity(value: String) -> String:
	var clean := value.to_lower()
	return clean if clean in ["info", "warning", "important"] else "info"


static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			var text := str(item).strip_edges()
			if not text.is_empty():
				result.append(text)
	return result


static func _dictionary(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


static func _array(value: Variant) -> Array:
	return (value as Array).duplicate(true) if value is Array else []


static func _duplicate(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value
