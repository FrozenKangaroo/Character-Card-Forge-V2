class_name CCFGenerationServiceV0141
extends "res://scripts/services/generation_service_v014_hotfix1.gd"

const INTERVIEW_REVIEW_FORMAT_VERSION := 1


func _prepare_character_stage(job_value: Dictionary) -> Dictionary:
	var job: Dictionary = super._prepare_character_stage(job_value)
	var review := build_interview_review(job)
	if review.get("entries", []).is_empty():
		return job
	var metadata_value: Variant = job.get("metadata", {})
	var metadata: Dictionary = metadata_value.duplicate(true) if metadata_value is Dictionary else {}
	metadata["generation_interview_review"] = review
	job["metadata"] = metadata
	return job


func build_interview_review(job: Dictionary) -> Dictionary:
	var questions_value: Variant = job.get("interview_questions", [])
	var answers_value: Variant = job.get("interview_answers", {})
	if not questions_value is Array or not answers_value is Dictionary:
		return {"format_version": INTERVIEW_REVIEW_FORMAT_VERSION, "entries": []}

	var manual_ids: Dictionary = {}
	var manual_ids_value: Variant = job.get("interview_manual_ids", [])
	if manual_ids_value is Array:
		for raw_id in manual_ids_value:
			manual_ids[str(raw_id)] = true

	var entries: Array[Dictionary] = []
	for raw_question in questions_value:
		if not raw_question is Dictionary:
			continue
		var question: Dictionary = raw_question
		var question_id := str(question.get("id", "")).strip_edges()
		if question_id.is_empty():
			continue
		var answer := _value_to_text(answers_value.get(question_id, "")).strip_edges()
		if answer.is_empty():
			continue
		entries.append({
			"id": question_id,
			"label": str(question.get("label", question_id)),
			"question": str(question.get("question", "")),
			"answer": answer,
			"required": bool(question.get("required", false)),
			"source": "manual" if manual_ids.has(question_id) else "ai"
		})

	return {
		"format_version": INTERVIEW_REVIEW_FORMAT_VERSION,
		"entries": entries
	}
