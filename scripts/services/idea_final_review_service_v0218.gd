class_name CCFIdeaFinalReviewServiceV0218
extends RefCounted

const CONTRACT_VERSION := 1
const ADHERENCE_MATCH := "match"
const ADHERENCE_PARTIAL := "partial_mismatch"
const ADHERENCE_CLEAR := "clear_mismatch"
const ADHERENCE_VALUES := [ADHERENCE_MATCH, ADHERENCE_PARTIAL, ADHERENCE_CLEAR]
const SIMILARITY_VALUES := ["duplicate", "near_duplicate", "related_distinct"]


static func review_requested(session: Dictionary) -> bool:
	if bool(session.get("final_review_check_adherence", false)):
		return true
	if bool(session.get("final_review_check_similarity", false)):
		return true
	# Narrow compatibility for callers that still set the old flag-only mode.
	return str(session.get("final_review_mode", "off")) != "off"


static func final_review_prompt(session: Dictionary) -> String:
	var check_adherence := bool(session.get("final_review_check_adherence", false))
	var check_similarity := bool(session.get("final_review_check_similarity", false))
	if not check_adherence and not check_similarity:
		check_similarity = str(session.get("final_review_mode", "off")) != "off"
	var context_value: Variant = session.get("generation_context", {})
	var context: Dictionary = context_value if context_value is Dictionary else {}
	var context_lines: Array[String] = []
	context_lines.append("Prompt mode: %s" % (
		"Additional Direction"
		if str(context.get("prompt_mode", "")) == "additional_direction"
		else "Primary prompt"
	))
	for pair in [
		["Original user / batch direction", "seed_text"],
		["Active Idea Source", "idea_source_title"],
		["Active Idea Source / canonical source context", "idea_source_context"],
		["Series context", "series_context"]
	]:
		var value := str(context.get(str(pair[1]), "")).strip_edges()
		if not value.is_empty():
			context_lines.append("%s:\n%s" % [str(pair[0]), value])
	var records: Array[String] = []
	for record_value in session.get("accepted", []):
		if not record_value is Dictionary:
			continue
		var record: Dictionary = record_value
		records.append("- %s | %s | %s" % [
			str(record.get("id", "")),
			str(record.get("title", "Untitled idea")),
			str(record.get("fingerprint", ""))
		])
	var requested: Array[String] = []
	if check_adherence:
		requested.append(
			"For every Idea, classify request adherence as match, partial_mismatch or clear_mismatch. "
			+ "A mismatch contradicts or omits an explicit central requirement, relationship, participant role or scenario structure. "
			+ "Do not penalise discretionary variation. When uncertain, prefer partial_mismatch."
		)
	if check_similarity:
		requested.append(
			"Identify scenario-level groups as duplicate, near_duplicate or related_distinct. "
			+ "Requested shared traits are invariants, not duplicate evidence. Cosmetic renaming is not novelty. "
			+ "When uncertain, prefer near_duplicate and preserve genuinely distinct variants."
		)
	return "\n\n".join([
		"FINAL IDEA REVIEW — ADVISORY ONLY",
		"AI findings are advisory. The application will never delete or uncheck an Idea from your answer. Report findings only; the user decides what to keep.",
		"FROZEN GENERATION CONTEXT\n" + "\n\n".join(context_lines),
		"REVIEW DIMENSIONS\n" + "\n\n".join(requested),
		(
			"Return JSON only as {\"ideas\":[{\"idea_id\":\"idea-001\",\"adherence\":\"match\",\"reason\":\"concise reason\"}],"
			+ "\"similarity_clusters\":[{\"idea_ids\":[\"idea-001\",\"idea-002\"],\"classification\":\"near_duplicate\",\"reason\":\"concise reason\"}]}. "
			+ "Omit a section only when that review dimension was not requested. Use only supplied Idea IDs."
		),
		"IDEAS\n" + "\n".join(records)
	])


static func normalise_review(data: Variant, session: Dictionary) -> Dictionary:
	var known_ids := _known_ids(session)
	var adherence: Array[Dictionary] = []
	var clusters: Array[Dictionary] = []
	if not data is Dictionary:
		return {"ideas": adherence, "similarity_clusters": clusters}
	var ideas_value: Variant = (data as Dictionary).get("ideas", [])
	if ideas_value is Array:
		var seen: Dictionary = {}
		for finding_value in ideas_value as Array:
			if not finding_value is Dictionary:
				continue
			var finding: Dictionary = finding_value
			var idea_id := str(finding.get("idea_id", "")).strip_edges()
			var classification := str(finding.get("adherence", "")).strip_edges().to_lower()
			if not known_ids.has(idea_id) or seen.has(idea_id):
				continue
			if classification not in ADHERENCE_VALUES:
				continue
			seen[idea_id] = true
			adherence.append({
				"idea_id": idea_id,
				"adherence": classification,
				"reason": str(finding.get("reason", "No reason supplied.")).strip_edges()
			})
	var clusters_value: Variant = (data as Dictionary).get(
		"similarity_clusters", (data as Dictionary).get("clusters", [])
	)
	if clusters_value is Array:
		for cluster_value in clusters_value as Array:
			if not cluster_value is Dictionary:
				continue
			var cluster: Dictionary = cluster_value
			var classification := str(cluster.get("classification", "")).strip_edges().to_lower()
			if classification not in SIMILARITY_VALUES:
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
			clusters.append({
				"idea_ids": ids,
				"classification": classification,
				"reason": str(cluster.get("reason", "No reason supplied.")).strip_edges()
			})
	return {"ideas": adherence, "similarity_clusters": clusters}


static func apply_advisory_review(session: Dictionary, review: Dictionary) -> void:
	session["final_review_started"] = true
	session["final_review_completed"] = true
	session["final_review_findings"] = (
		(review.get("ideas", []) as Array).duplicate(true)
		if review.get("ideas", []) is Array else []
	)
	session["final_review_clusters"] = (
		(review.get("similarity_clusters", []) as Array).duplicate(true)
		if review.get("similarity_clusters", []) is Array else []
	)
	# Deliberately do not mutate accepted records. AI review is advisory.


static func apply_user_selection(session: Dictionary, kept_ids_value: Variant) -> Dictionary:
	var kept_ids: Dictionary = {}
	if kept_ids_value is Array:
		for id_value in kept_ids_value as Array:
			kept_ids[str(id_value)] = true
	elif kept_ids_value is Dictionary:
		kept_ids = (kept_ids_value as Dictionary).duplicate()
	var retained: Array = []
	var rejected_ids: Array[String] = []
	for record_value in session.get("accepted", []):
		if not record_value is Dictionary:
			continue
		var record: Dictionary = (record_value as Dictionary).duplicate(true)
		var idea_id := str(record.get("id", ""))
		if kept_ids.has(idea_id):
			retained.append(record)
			continue
		record["state"] = "rejected"
		record["rejection_reason"] = "rejected_by_user_review"
		record["final_review_findings"] = findings_for_idea(session, idea_id)
		(session.get("rejected", []) as Array).append(record)
		rejected_ids.append(idea_id)
	session["accepted"] = retained
	session["user_review_applied"] = true
	session["user_review_rejected_count"] = int(
		session.get("user_review_rejected_count", 0)
	) + rejected_ids.size()
	return {
		"kept_count": retained.size(),
		"rejected_count": rejected_ids.size(),
		"rejected_ids": rejected_ids
	}


static func findings_for_idea(session: Dictionary, idea_id: String) -> Dictionary:
	var result := {"adherence": {}, "similarity_clusters": []}
	for finding_value in session.get("final_review_findings", []):
		if finding_value is Dictionary and str(
			(finding_value as Dictionary).get("idea_id", "")
		) == idea_id:
			result["adherence"] = (finding_value as Dictionary).duplicate(true)
			break
	for cluster_value in session.get("final_review_clusters", []):
		if not cluster_value is Dictionary:
			continue
		var ids_value: Variant = (cluster_value as Dictionary).get("idea_ids", [])
		if ids_value is Array and idea_id in (ids_value as Array):
			(result["similarity_clusters"] as Array).append(
				(cluster_value as Dictionary).duplicate(true)
			)
	return result


static func remove_visible_idea(
	curation: Dictionary, visible_index: int, reason: String = "rejected_by_user_after_generation"
) -> Dictionary:
	var visible_value: Variant = curation.get("visible_ideas", [])
	if not visible_value is Array:
		return {"ok": false}
	var visible: Array = visible_value
	if visible_index < 0 or visible_index >= visible.size():
		return {"ok": false}
	var idea_value: Variant = visible[visible_index]
	if not idea_value is Dictionary:
		return {"ok": false}
	var idea: Dictionary = (idea_value as Dictionary).duplicate(true)
	visible.remove_at(visible_index)
	var serial := int(curation.get("next_ledger_id", 1))
	curation["next_ledger_id"] = serial + 1
	var record := CCFIdeaDiversityGuardrailsV0214.ledger_record_for_idea(
		idea, "curated-%03d" % serial, "rejected", reason
	)
	(curation.get("rejected", []) as Array).append(record)
	curation["user_deleted_count"] = int(curation.get("user_deleted_count", 0)) + 1
	return {"ok": true, "idea": idea, "record": record}


static func create_curation_session(
	session: Dictionary, metadata: Dictionary
) -> Dictionary:
	return {
		"contract_version": CONTRACT_VERSION,
		"project_id": str(session.get("project_id_snapshot", "")),
		"visible_ideas": CCFIdeaDiversityGuardrailsV0214.accepted_ideas(session),
		"rejected": (session.get("rejected", []) as Array).duplicate(true),
		"generation_context": (session.get("generation_context", {}) as Dictionary).duplicate(true),
		"seed_snapshot": str(session.get("seed_snapshot", "")),
		"series_context_snapshot": str(session.get("series_context_snapshot", "")),
		"profile_snapshot": (session.get("profile_snapshot", {}) as Dictionary).duplicate(true),
		"retry_count_snapshot": int(session.get("retry_count_snapshot", 1)),
		"detail_level_snapshot": str(session.get("detail_level_snapshot", "standard")),
		"custom_target_snapshot": int(session.get("custom_target_snapshot", 0)),
		"batch_limit": int(session.get("batch_limit", 1)),
		"prevent_repeats": bool(session.get("prevent_repeats", true)),
		"review_adherence": bool(session.get("final_review_check_adherence", false)),
		"review_similarity": bool(session.get("final_review_check_similarity", false)),
		"final_top_up_enabled": bool(session.get("final_top_up_enabled", false)),
		"metadata": metadata.duplicate(true),
		"next_ledger_id": int(session.get("next_ledger_id", 1)),
		"manual_generate_more_count": 0,
		"user_deleted_count": 0
	}


static func create_extension_session(
	curation: Dictionary, additional_count: int, batch_limit: int
) -> Dictionary:
	var visible_value: Variant = curation.get("visible_ideas", [])
	var visible: Array = visible_value if visible_value is Array else []
	var additional := maxi(1, additional_count)
	var limit := maxi(1, batch_limit)
	var target := visible.size() + additional
	var session := CCFIdeaDiversityGuardrailsV0214.create_session(
		target,
		limit,
		bool(curation.get("prevent_repeats", true)),
		"flag" if bool(curation.get("review_similarity", false)) else "off",
		bool(curation.get("final_top_up_enabled", false)),
		curation.get("generation_context", {}) as Dictionary
	)
	session["normal_request_limit"] = int(ceil(float(additional) / float(limit)))
	session["final_review_check_adherence"] = bool(curation.get("review_adherence", false))
	session["final_review_check_similarity"] = bool(curation.get("review_similarity", false))
	session["seed_snapshot"] = str(curation.get("seed_snapshot", ""))
	session["series_context_snapshot"] = str(curation.get("series_context_snapshot", ""))
	session["profile_snapshot"] = (curation.get("profile_snapshot", {}) as Dictionary).duplicate(true)
	session["retry_count_snapshot"] = int(curation.get("retry_count_snapshot", 1))
	session["project_id_snapshot"] = str(curation.get("project_id", ""))
	session["detail_level_snapshot"] = str(curation.get("detail_level_snapshot", "standard"))
	session["custom_target_snapshot"] = int(curation.get("custom_target_snapshot", 0))
	for idea_value in visible:
		if not idea_value is Dictionary:
			continue
		var ledger_id := "idea-%03d" % int(session.get("next_ledger_id", 1))
		session["next_ledger_id"] = int(session.get("next_ledger_id", 1)) + 1
		(session.get("accepted", []) as Array).append(
			CCFIdeaDiversityGuardrailsV0214.ledger_record_for_idea(
				idea_value as Dictionary, ledger_id, "accepted", ""
			)
		)
	for rejected_value in curation.get("rejected", []):
		if rejected_value is Dictionary:
			(session.get("rejected", []) as Array).append(
				(rejected_value as Dictionary).duplicate(true)
			)
	return session


static func _known_ids(session: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for record_value in session.get("accepted", []):
		if record_value is Dictionary:
			var idea_id := str((record_value as Dictionary).get("id", ""))
			if not idea_id.is_empty():
				result[idea_id] = true
	return result


static func capabilities() -> Dictionary:
	return {
		"contract_version": CONTRACT_VERSION,
		"advisory_only": true,
		"request_adherence": true,
		"similarity_clusters": true,
		"user_checkbox_retention": true,
		"post_review_top_up": true,
		"temporary_delete": true,
		"repeatable_generate_more": true,
		"project_scoped_curation": true
	}
