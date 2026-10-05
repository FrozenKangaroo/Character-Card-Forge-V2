class_name CCFIdeaDiversityGuardrailsV0214
extends RefCounted

const CONTRACT_VERSION := 1
const FINAL_REVIEW_OFF := "off"
const FINAL_REVIEW_FLAG := "flag"
const FINAL_REVIEW_REJECT := "reject"
const FINAL_REVIEW_MODES := [
	FINAL_REVIEW_OFF,
	FINAL_REVIEW_FLAG,
	FINAL_REVIEW_REJECT
]
const MAX_FINGERPRINT_CHARACTERS := 360
const MAX_LEDGER_PROMPT_ITEMS := 60
const IDEA_PROMPT_PROVENANCE_V02114 = preload(
	"res://scripts/services/idea_prompt_provenance_v02114.gd"
)

const STRUCTURAL_STOP_WORDS := {
	"a": true, "an": true, "and": true, "are": true, "as": true,
	"at": true, "be": true, "because": true, "been": true, "being": true,
	"but": true, "by": true, "can": true, "character": true, "concept": true,
	"could": true, "do": true, "does": true, "during": true, "each": true,
	"for": true, "from": true, "had": true, "has": true, "have": true,
	"he": true, "her": true, "hers": true, "him": true, "his": true,
	"idea": true, "if": true, "in": true, "into": true, "is": true,
	"it": true, "its": true, "may": true, "of": true, "on": true,
	"or": true, "roleplay": true, "she": true, "that": true, "the": true,
	"their": true, "them": true, "they": true, "this": true, "to": true,
	"user": true, "was": true, "were": true, "when": true, "where": true,
	"which": true, "while": true, "who": true, "with": true, "would": true
}


static func create_session(
	target_count: int,
	batch_limit: int,
	prevent_repeats: bool = true,
	final_review_mode: String = FINAL_REVIEW_OFF,
	final_top_up: bool = false,
	generation_context: Dictionary = {}
) -> Dictionary:
	var target := maxi(1, target_count)
	var limit := maxi(1, batch_limit)
	var normal_request_limit := int(ceil(float(target) / float(limit)))
	return {
		"contract_version": CONTRACT_VERSION,
		"target_count": target,
		"batch_limit": limit,
		"normal_request_limit": normal_request_limit,
		"normal_requests_started": 0,
		"normal_requests_completed": 0,
		"initial_generated_candidate_count": 0,
		"semantic_repair_pass_count": 0,
		"semantic_repair_candidate_count": 0,
		"validation_candidate_count": 0,
		# Compatibility alias for diagnostics written by the first v0.21.4 build.
		# User-facing text must call this validation candidates, never simply raw.
		"raw_count": 0,
		"accepted": [],
		"rejected": [],
		"title_warnings": [],
		"duplicate_candidates": [],
		"final_review_mode": normalise_final_review_mode(final_review_mode),
		"final_review_clusters": [],
		"final_review_started": false,
		"final_review_completed": false,
		"final_top_up_enabled": final_top_up,
		"final_top_up_started": false,
		"final_top_up_completed": false,
		"prevent_repeats": prevent_repeats,
		"generation_context": normalise_generation_context(generation_context),
		"next_ledger_id": 1
	}


static func normalise_generation_context(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var source: Dictionary = value
	var result := {
		"prompt_mode": str(source.get("prompt_mode", "primary_prompt")).strip_edges(),
		"seed_text": str(source.get("seed_text", "")).strip_edges(),
		"series_context": str(source.get("series_context", "")).strip_edges(),
		"idea_source_id": str(source.get("idea_source_id", "")).strip_edges(),
		"idea_source_title": str(source.get("idea_source_title", "")).strip_edges(),
		"idea_source_context": str(source.get("idea_source_context", "")).strip_edges()
	}
	if str(result.get("prompt_mode", "")) not in [
		"primary_prompt", "additional_direction"
	]:
		result["prompt_mode"] = (
			"additional_direction"
			if not str(result.get("idea_source_context", "")).is_empty()
			else "primary_prompt"
		)
	var has_context := false
	for field_id in [
		"seed_text", "series_context", "idea_source_id", "idea_source_title",
		"idea_source_context"
	]:
		if not str(result.get(field_id, "")).is_empty():
			has_context = true
			break
	return result if has_context else {}


static func normalise_final_review_mode(value: Variant) -> String:
	var clean := str(value).strip_edges().to_lower()
	return clean if clean in FINAL_REVIEW_MODES else FINAL_REVIEW_OFF


static func accepted_count(session: Dictionary) -> int:
	var value: Variant = session.get("accepted", [])
	return (value as Array).size() if value is Array else 0


static func rejected_count(session: Dictionary) -> int:
	var value: Variant = session.get("rejected", [])
	return (value as Array).size() if value is Array else 0


static func remaining_count(session: Dictionary) -> int:
	return maxi(0, int(session.get("target_count", 0)) - accepted_count(session))


static func next_normal_request_size(session: Dictionary) -> int:
	if (
		int(session.get("normal_requests_started", 0))
		>= int(session.get("normal_request_limit", 0))
	):
		return 0
	return mini(int(session.get("batch_limit", 1)), remaining_count(session))


static func next_top_up_request_size(session: Dictionary) -> int:
	if (
		not bool(session.get("final_top_up_enabled", false))
		or bool(session.get("final_top_up_started", false))
	):
		return 0
	return mini(int(session.get("batch_limit", 1)), remaining_count(session))


static func mark_request_started(
	session: Dictionary, request_size: int, request_kind: String
) -> void:
	if request_kind == "normal":
		session["normal_requests_started"] = int(
			session.get("normal_requests_started", 0)
		) + 1
	elif request_kind == "top_up":
		session["final_top_up_started"] = true
	session["last_request_size"] = maxi(0, request_size)
	session["last_request_kind"] = request_kind


static func record_batch(
	session: Dictionary,
	ideas: Array,
	validation_rejections: Array = [],
	request_kind: String = "normal",
	raw_count_hint: int = -1,
	telemetry: Dictionary = {}
) -> Dictionary:
	var validation_count := int(telemetry.get(
		"validation_candidate_count", raw_count_hint
	))
	if validation_count < 0:
		validation_count = ideas.size() + validation_rejections.size()
	var initial_count := int(telemetry.get(
		"initial_generated_candidate_count", validation_count
	))
	var repair_passes := int(telemetry.get("semantic_repair_pass_count", 0))
	var repair_candidates := int(telemetry.get(
		"semantic_repair_candidate_count", 0
	))
	session["initial_generated_candidate_count"] = int(session.get(
		"initial_generated_candidate_count", 0
	)) + maxi(0, initial_count)
	session["semantic_repair_pass_count"] = int(session.get(
		"semantic_repair_pass_count", 0
	)) + maxi(0, repair_passes)
	session["semantic_repair_candidate_count"] = int(session.get(
		"semantic_repair_candidate_count", 0
	)) + maxi(0, repair_candidates)
	session["validation_candidate_count"] = int(session.get(
		"validation_candidate_count", 0
	)) + maxi(0, validation_count)
	session["raw_count"] = int(session.get("validation_candidate_count", 0))
	if request_kind == "normal":
		session["normal_requests_completed"] = int(
			session.get("normal_requests_completed", 0)
		) + 1
	elif request_kind == "top_up":
		session["final_top_up_completed"] = true

	var newly_accepted: Array[Dictionary] = []
	var newly_rejected: Array[Dictionary] = []
	var comparison_enabled := local_comparison_required(session)
	for idea_value in ideas:
		if not idea_value is Dictionary:
			var malformed := _normalise_rejected_record(
				session, {"summary": str(idea_value)}, "not a generated idea object"
			)
			_append_rejected(session, malformed)
			newly_rejected.append(malformed)
			continue
		var idea := IDEA_PROMPT_PROVENANCE_V02114.attach_to_idea(
			idea_value as Dictionary,
			session.get("generation_context", {}) as Dictionary,
			str(session.get("seed_snapshot", ""))
		)
		var candidate := ledger_record_for_idea(
			idea, _take_ledger_id(session), "accepted", "", comparison_enabled
		)
		if accepted_count(session) >= int(session.get("target_count", 0)):
			candidate["state"] = "rejected"
			candidate["rejection_reason"] = "returned beyond the requested accepted target"
			_append_rejected(session, candidate)
			newly_rejected.append(candidate)
			continue
		var comparison := (
			compare_against_session(candidate, session)
			if comparison_enabled
			else {
				"clear_duplicate": false,
				"title_warnings": [],
				"duplicate_candidates": []
			}
		)
		for warning_value in comparison.get("title_warnings", []):
			var warning: Dictionary = warning_value
			(session.get("title_warnings", []) as Array).append(warning)
		if (
			bool(session.get("prevent_repeats", true))
			and bool(comparison.get("clear_duplicate", false))
		):
			candidate["state"] = "rejected"
			candidate["rejection_reason"] = str(
				comparison.get("reason", "structural duplicate")
			)
			_append_rejected(session, candidate)
			newly_rejected.append(candidate)
			continue
		for duplicate_value in comparison.get("duplicate_candidates", []):
			(session.get("duplicate_candidates", []) as Array).append(
				duplicate_value
			)
		(session.get("accepted", []) as Array).append(candidate)
		newly_accepted.append(candidate)

	# Validation failures from this provider job remain anti-repeat memory for later
	# requests, but they are appended after the repaired/accepted output is judged.
	# This prevents an earlier invalid draft from rejecting its own successful repair.
	for rejected_value in validation_rejections:
		var rejected_record := _normalise_rejected_record(
			session, rejected_value, "generation validation"
		)
		_append_rejected(session, rejected_record)

	return {
		"accepted": newly_accepted,
		"rejected": newly_rejected,
		"accepted_count": accepted_count(session),
		"rejected_count": rejected_count(session),
		"initial_generated_candidate_count": int(session.get(
			"initial_generated_candidate_count", 0
		)),
		"semantic_repair_pass_count": int(session.get(
			"semantic_repair_pass_count", 0
		)),
		"semantic_repair_candidate_count": int(session.get(
			"semantic_repair_candidate_count", 0
		)),
		"validation_candidate_count": int(session.get(
			"validation_candidate_count", 0
		)),
		"raw_count": int(session.get("validation_candidate_count", 0)),
		"remaining": remaining_count(session)
	}


static func ledger_record_for_idea(
	idea: Dictionary,
	ledger_id: String,
	state: String,
	reason: String,
	include_comparison_data: bool = true
) -> Dictionary:
	var title := str(idea.get("title", "Untitled idea")).strip_edges()
	var summary := _idea_summary(idea)
	return {
		"id": ledger_id,
		"title": title if not title.is_empty() else "Untitled idea",
		"summary": summary,
		"fingerprint": semantic_fingerprint(idea) if include_comparison_data else "",
		"structural_tokens": structural_tokens(idea) if include_comparison_data else [],
		"normalised_title": normalise_title(title) if include_comparison_data else "",
		"state": state,
		"rejection_reason": reason,
		"idea": idea.duplicate(true)
	}


static func local_comparison_required(session: Dictionary) -> bool:
	return (
		bool(session.get("prevent_repeats", true))
		or bool(session.get("final_review_check_similarity", false))
		or normalise_final_review_mode(session.get("final_review_mode", "off"))
		!= FINAL_REVIEW_OFF
	)


static func semantic_fingerprint(idea: Dictionary) -> String:
	var text := _idea_summary(idea)
	var character_name := str(idea.get("character_name", "")).strip_edges()
	if not character_name.is_empty():
		text = _replace_case_insensitive(text, character_name, "the generated character")
	text = _collapse_whitespace(text)
	if text.length() > MAX_FINGERPRINT_CHARACTERS:
		text = text.substr(0, MAX_FINGERPRINT_CHARACTERS).strip_edges() + "…"
	return text


static func structural_tokens(idea: Dictionary) -> Array[String]:
	var text := _idea_summary(idea).to_lower()
	var character_name := str(idea.get("character_name", "")).to_lower()
	for part in character_name.split(" ", false):
		var clean_part := str(part).strip_edges()
		if clean_part.length() >= 2:
			text = text.replace(clean_part, " ")
	text = text.replace("{{user}}", " user ").replace("{{char}}", " character ")
	var punctuation := RegEx.new()
	punctuation.compile("[^\\p{L}\\p{N}_]+")
	text = punctuation.sub(text, " ", true)
	var result: Array[String] = []
	for token_value in text.split(" ", false):
		var token := str(token_value).strip_edges()
		if token.length() < 2 or STRUCTURAL_STOP_WORDS.has(token):
			continue
		if not token in result:
			result.append(token)
	result.sort()
	return result


static func normalise_title(title: String) -> String:
	var text := title.to_lower().replace("’", "'").replace("‘", "'")
	var punctuation := RegEx.new()
	punctuation.compile("[^\\p{L}\\p{N}]+")
	return _collapse_whitespace(punctuation.sub(text, " ", true))


static func titles_need_comparison(first: String, second: String) -> bool:
	var a := normalise_title(first)
	var b := normalise_title(second)
	if a.is_empty() or b.is_empty():
		return false
	if a == b:
		return true
	var shorter := mini(a.length(), b.length())
	if shorter < 8:
		return false
	var allowed_distance := maxi(1, int(floor(float(shorter) * 0.12)))
	return _edit_distance(a, b) <= allowed_distance


static func compare_against_session(
	candidate: Dictionary, session: Dictionary
) -> Dictionary:
	var title_warnings: Array[Dictionary] = []
	var duplicate_candidates: Array[Dictionary] = []
	var candidate_tokens: Array = candidate.get("structural_tokens", [])
	for category in ["accepted", "rejected"]:
		var records_value: Variant = session.get(category, [])
		if not records_value is Array:
			continue
		for existing_value in records_value as Array:
			if not existing_value is Dictionary:
				continue
			var existing: Dictionary = existing_value
			if titles_need_comparison(
				str(candidate.get("title", "")), str(existing.get("title", ""))
			):
				title_warnings.append({
					"candidate_id": str(candidate.get("id", "")),
					"existing_id": str(existing.get("id", "")),
					"candidate_title": str(candidate.get("title", "")),
					"existing_title": str(existing.get("title", "")),
					"signal": "title_similarity_only"
				})
			var similarity := _token_similarity(
				candidate_tokens, existing.get("structural_tokens", [])
			)
			var exact_fingerprint := (
				not str(candidate.get("fingerprint", "")).is_empty()
				and str(candidate.get("fingerprint", "")).to_lower()
				== str(existing.get("fingerprint", "")).to_lower()
			)
			if exact_fingerprint or similarity >= 0.96:
				return {
					"clear_duplicate": true,
					"reason": (
						"duplicates %s (%s) at the scenario-structure level"
						% [str(existing.get("title", "Untitled idea")), str(existing.get("id", ""))]
					),
					"title_warnings": title_warnings,
					"duplicate_candidates": duplicate_candidates
				}
			if similarity >= 0.78:
				duplicate_candidates.append({
					"candidate_id": str(candidate.get("id", "")),
					"existing_id": str(existing.get("id", "")),
					"similarity": similarity,
					"classification": "needs_structural_comparison"
				})
	return {
		"clear_duplicate": false,
		"title_warnings": title_warnings,
		"duplicate_candidates": duplicate_candidates
	}


static func anti_repeat_prompt(session: Dictionary) -> String:
	if not bool(session.get("prevent_repeats", true)):
		return ""
	var accepted_lines := _ledger_prompt_lines(session.get("accepted", []), false)
	var rejected_lines := _ledger_prompt_lines(session.get("rejected", []), true)
	if accepted_lines.is_empty() and rejected_lines.is_empty():
		return ""
	var sections: Array[String] = [
		"MULTI-BATCH DIVERSITY GUARDRAILS:",
		"Treat this as the same generation session as earlier requests. Preserve the original Idea Source, ordinary prompt, Additional Direction, detail setting and all existing contracts.",
		"Changing names, title wording, occupation terminology, location, scenery or cosmetic traits does not make an idea different. Do not reproduce the same underlying scenario engine.",
		"Seek meaningful variation in relationship structure, motivations, initiating events, third-party roles, objectives, consent or secrecy structure, conflict source, reveal mechanism, opening situation, consequences, emotional dynamics, uncertainty and other source-relevant structural axes.",
		"Shared genre, Series, broad trope or source engine is allowed. Preserve meaningful variants and creative freedom. If Additional Direction names several branches, prefer branches not yet represented."
	]
	if not accepted_lines.is_empty():
		sections.append(
			"ALREADY ACCEPTED IN THIS GENERATION — DO NOT DUPLICATE:\n"
			+ "\n".join(accepted_lines)
		)
	if not rejected_lines.is_empty():
		sections.append(
			"REJECTED AS DUPLICATE / INVALID / TOO SIMILAR — DO NOT REGENERATE:\n"
			+ "\n".join(rejected_lines)
		)
	return "\n\n".join(sections)


static func final_review_prompt(session: Dictionary) -> String:
	var records: Array[String] = []
	var accepted_value: Variant = session.get("accepted", [])
	if accepted_value is Array:
		for record_value in accepted_value as Array:
			if not record_value is Dictionary:
				continue
			var record: Dictionary = record_value
			records.append(
				"- %s | %s | %s"
				% [
					str(record.get("id", "")),
					str(record.get("title", "Untitled idea")),
					str(record.get("fingerprint", ""))
				]
			)
	var context := normalise_generation_context(session.get("generation_context", {}))
	var context_lines: Array[String] = []
	if context.is_empty():
		context_lines.append("No stored generation context is available for this legacy session.")
	else:
		context_lines.append("Prompt mode: %s" % (
			"Additional Direction"
			if str(context.get("prompt_mode", "")) == "additional_direction"
			else "Primary prompt"
		))
		var seed_text := str(context.get("seed_text", ""))
		if not seed_text.is_empty():
			context_lines.append("Original user / batch direction:\n%s" % seed_text)
		var source_title := str(context.get("idea_source_title", ""))
		if not source_title.is_empty():
			context_lines.append("Active Idea Source: %s" % source_title)
		var source_context := str(context.get("idea_source_context", ""))
		if not source_context.is_empty():
			context_lines.append(
				"Active Idea Source / canonical source context:\n%s" % source_context
			)
		var series_context := str(context.get("series_context", ""))
		if not series_context.is_empty():
			context_lines.append("Series context:\n%s" % series_context)
	return "\n\n".join([
		"SIMILARITY REVIEW",
		"GENERATION CONTEXT\n\n" + "\n\n".join(context_lines),
		(
			"IMPORTANT:\n"
			+ "The requirements above intentionally constrain every generated Idea. "
			+ "Do not classify Ideas as duplicates merely because they satisfy the same explicit generation requirements. Treat those requested traits as shared invariants.\n\n"
			+ "After accounting for those requested invariants, compare the discretionary narrative choices made by each Idea. A clear duplicate means that, after accounting for requested invariants, the Ideas remain materially interchangeable at the scenario/roleplay-engine level.\n\n"
			+ "Cosmetic changes to names, occupation labels, locations, scenery or wording are not meaningful differences when motivation, relationship, boundaries, progression and consequences remain essentially the same.\n\n"
			+ "Differences in relationship to a third party, prior history, motivation, how a person enters the scenario, permission or consent structure, secrecy versus openness, boundaries, which boundary is crossed, initiating event, power dynamic, progression, emotional stakes, reveal mechanism, uncertainty, consequences or ongoing tension are substantive and should normally prevent a duplicate classification.\n\n"
			+ "When uncertain between duplicate and near_duplicate, prefer near_duplicate. Preserve a genuinely distinct variation."
		),
		(
			"Classify each candidate group as exactly one of: duplicate, near_duplicate, related_distinct. Return JSON only as {\"clusters\":[{\"idea_ids\":[\"idea-001\",\"idea-002\"],\"classification\":\"duplicate\",\"reason\":\"concise structural reason\"}]}. Omit unrelated ideas."
		),
		"IDEAS:\n" + "\n".join(records)
	])


static func normalise_review_clusters(
	data: Variant, session: Dictionary
) -> Array[Dictionary]:
	if not data is Dictionary:
		return []
	var known_ids: Dictionary = {}
	for record_value in session.get("accepted", []):
		if record_value is Dictionary:
			known_ids[str((record_value as Dictionary).get("id", ""))] = true
	var result: Array[Dictionary] = []
	var clusters_value: Variant = (data as Dictionary).get("clusters", [])
	if not clusters_value is Array:
		return result
	for cluster_value in clusters_value as Array:
		if not cluster_value is Dictionary:
			continue
		var cluster: Dictionary = cluster_value
		var classification := str(cluster.get("classification", "")).to_lower()
		if classification not in ["duplicate", "near_duplicate", "related_distinct"]:
			continue
		var ids: Array[String] = []
		var ids_value: Variant = cluster.get("idea_ids", [])
		if ids_value is Array:
			for id_value in ids_value as Array:
				var idea_id := str(id_value).strip_edges()
				if known_ids.has(idea_id) and not idea_id in ids:
					ids.append(idea_id)
		if ids.size() < 2:
			continue
		result.append({
			"idea_ids": ids,
			"classification": classification,
			"reason": str(cluster.get("reason", "No reason supplied.")).strip_edges()
		})
	return result


static func apply_final_review(
	session: Dictionary, clusters: Array[Dictionary]
) -> Dictionary:
	session["final_review_started"] = true
	session["final_review_completed"] = true
	session["final_review_clusters"] = clusters.duplicate(true)
	if normalise_final_review_mode(session.get("final_review_mode", "off")) != FINAL_REVIEW_REJECT:
		return {"rejected_ids": [], "accepted_count": accepted_count(session)}
	var rejected_ids: Array[String] = []
	for cluster in clusters:
		if str(cluster.get("classification", "")) != "duplicate":
			continue
		var ids_value: Variant = cluster.get("idea_ids", [])
		if not ids_value is Array or (ids_value as Array).size() < 2:
			continue
		var ordered_ids: Array[String] = []
		for accepted_value in session.get("accepted", []):
			if not accepted_value is Dictionary:
				continue
			var accepted_id := str((accepted_value as Dictionary).get("id", ""))
			if accepted_id in (ids_value as Array):
				ordered_ids.append(accepted_id)
		for index in range(1, ordered_ids.size()):
			var idea_id := ordered_ids[index]
			if not idea_id in rejected_ids:
				rejected_ids.append(idea_id)
	var retained: Array = []
	for record_value in session.get("accepted", []):
		if not record_value is Dictionary:
			continue
		var record: Dictionary = record_value
		if str(record.get("id", "")) in rejected_ids:
			record = record.duplicate(true)
			record["state"] = "rejected"
			record["rejection_reason"] = "final AI review: clear structural duplicate"
			_append_rejected(session, record)
		else:
			retained.append(record)
	session["accepted"] = retained
	return {"rejected_ids": rejected_ids, "accepted_count": accepted_count(session)}


static func accepted_ideas(session: Dictionary) -> Array:
	var result: Array = []
	for record_value in session.get("accepted", []):
		if record_value is Dictionary:
			var idea_value: Variant = (record_value as Dictionary).get("idea", {})
			if idea_value is Dictionary:
				result.append((idea_value as Dictionary).duplicate(true))
	return result


static func summary(session: Dictionary) -> Dictionary:
	var generation_batches := int(session.get("normal_requests_started", 0))
	if bool(session.get("final_top_up_started", false)):
		generation_batches += 1
	return {
		"target_count": int(session.get("target_count", 0)),
		"generation_batch_count": generation_batches,
		"initial_generated_candidate_count": int(session.get(
			"initial_generated_candidate_count", 0
		)),
		"semantic_repair_pass_count": int(session.get(
			"semantic_repair_pass_count", 0
		)),
		"semantic_repair_candidate_count": int(session.get(
			"semantic_repair_candidate_count", 0
		)),
		"validation_candidate_count": int(session.get(
			"validation_candidate_count", 0
		)),
		"raw_count": int(session.get("validation_candidate_count", 0)),
		"accepted_count": accepted_count(session),
		"rejected_count": rejected_count(session),
		"remaining": remaining_count(session),
		"normal_requests_started": int(session.get("normal_requests_started", 0)),
		"normal_request_limit": int(session.get("normal_request_limit", 0)),
		"final_review_mode": str(session.get("final_review_mode", "off")),
		"final_review_clusters": (session.get("final_review_clusters", []) as Array).duplicate(true),
		"final_top_up_started": bool(session.get("final_top_up_started", false)),
		"title_warning_count": (session.get("title_warnings", []) as Array).size()
	}


static func _normalise_rejected_record(
	session: Dictionary, value: Variant, fallback_reason: String
) -> Dictionary:
	var source: Dictionary = value if value is Dictionary else {"summary": str(value)}
	var idea_value: Variant = source.get("idea", source)
	var idea: Dictionary = idea_value if idea_value is Dictionary else {}
	var record := ledger_record_for_idea(
		idea, _take_ledger_id(session), "rejected", str(source.get("reason", fallback_reason))
	)
	if record.get("summary", "").is_empty():
		record["summary"] = str(source.get("summary", "Rejected generated candidate"))
		record["fingerprint"] = str(record.get("summary", ""))
	return record


static func _append_rejected(session: Dictionary, record: Dictionary) -> void:
	(session.get("rejected", []) as Array).append(record)


static func _take_ledger_id(session: Dictionary) -> String:
	var serial := int(session.get("next_ledger_id", 1))
	session["next_ledger_id"] = serial + 1
	return "idea-%03d" % serial


static func _idea_summary(idea: Dictionary) -> String:
	var parts: Array[String] = []
	for field_id in [
		"summary", "core_premise", "premise", "concept", "roleplay_hook",
		"character_role", "setup", "opening_situation", "central_conflict",
		"motivation", "reveal_mechanism", "consequences"
	]:
		var value := str(idea.get(field_id, "")).strip_edges()
		if not value.is_empty() and not value in parts:
			parts.append(value)
	return _collapse_whitespace(" | ".join(parts))


static func _ledger_prompt_lines(records_value: Variant, include_reason: bool) -> Array[String]:
	var result: Array[String] = []
	if not records_value is Array:
		return result
	for record_value in records_value as Array:
		if result.size() >= MAX_LEDGER_PROMPT_ITEMS:
			break
		if not record_value is Dictionary:
			continue
		var record: Dictionary = record_value
		var line := "- %s — %s: %s" % [
			str(record.get("id", "")),
			str(record.get("title", "Untitled idea")),
			str(record.get("fingerprint", ""))
		]
		if include_reason and not str(record.get("rejection_reason", "")).is_empty():
			line += " [Rejected: %s]" % str(record.get("rejection_reason", ""))
		result.append(line)
	return result


static func _token_similarity(first_value: Variant, second_value: Variant) -> float:
	if not first_value is Array or not second_value is Array:
		return 0.0
	var first: Array = first_value
	var second: Array = second_value
	if first.is_empty() or second.is_empty():
		return 0.0
	var union: Dictionary = {}
	var intersection := 0
	for token in first:
		union[str(token)] = true
	for token in second:
		var clean := str(token)
		if union.has(clean):
			intersection += 1
		else:
			union[clean] = true
	return float(intersection) / float(maxi(1, union.size()))


static func _edit_distance(first: String, second: String) -> int:
	var previous: Array[int] = []
	for column in range(second.length() + 1):
		previous.append(column)
	for row in range(1, first.length() + 1):
		var current: Array[int] = [row]
		for column in range(1, second.length() + 1):
			var substitution_cost := 0 if first[row - 1] == second[column - 1] else 1
			current.append(mini(
				mini(current[column - 1] + 1, previous[column] + 1),
				previous[column - 1] + substitution_cost
			))
		previous = current
	return previous[second.length()]


static func _replace_case_insensitive(text: String, needle: String, replacement: String) -> String:
	if needle.is_empty():
		return text
	var expression := RegEx.new()
	var compiled := expression.compile("(?i)" + needle.replace("\\", "\\\\").replace(".", "\\.").replace("[", "\\[").replace("]", "\\]").replace("(", "\\(").replace(")", "\\)").replace("+", "\\+").replace("*", "\\*").replace("?", "\\?").replace("^", "\\^").replace("$", "\\$").replace("|", "\\|").replace("{", "\\{").replace("}", "\\}"))
	return expression.sub(text, replacement, true) if compiled == OK else text


static func _collapse_whitespace(text: String) -> String:
	var whitespace := RegEx.new()
	whitespace.compile("\\s+")
	return whitespace.sub(text.strip_edges(), " ", true)


static func capabilities() -> Dictionary:
	return {
		"contract_version": CONTRACT_VERSION,
		"accepted_target_counting": true,
		"adaptive_sequential_batches": true,
		"session_only_ledger": true,
		"accepted_and_rejected_prompt_memory": true,
		"deterministic_title_warnings": true,
		"structural_duplicate_comparison": true,
		"context_aware_final_review": true,
		"final_review_modes": FINAL_REVIEW_MODES.duplicate(),
		"one_shot_top_up": true,
		"schema_changes": false
	}
