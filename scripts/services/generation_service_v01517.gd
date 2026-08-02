class_name CCFGenerationServiceV01517
extends "res://scripts/services/generation_service_v01516.gd"

const INTERVIEW_REVIEW_FORMAT_VERSION_V01517 := 1


func _prepare_character_stage(job_value: Dictionary) -> Dictionary:
	var job: Dictionary = super._prepare_character_stage(job_value)
	var review := build_interview_review_v01517(job)
	var entries_value: Variant = review.get("entries", [])
	if not entries_value is Array or entries_value.is_empty():
		return job
	var metadata_value: Variant = job.get("metadata", {})
	var metadata: Dictionary = metadata_value.duplicate(true) if metadata_value is Dictionary else {}
	metadata["generation_interview_review"] = review
	job["metadata"] = metadata
	return job


func build_interview_review_v01517(job: Dictionary) -> Dictionary:
	var questions_value: Variant = job.get("interview_questions", [])
	var answers_value: Variant = job.get("interview_answers", {})
	if not questions_value is Array or not answers_value is Dictionary:
		return {"format_version": INTERVIEW_REVIEW_FORMAT_VERSION_V01517, "entries": []}

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
		entries.append(
			{
				"id": question_id,
				"label": str(question.get("label", question_id)),
				"question": str(question.get("question", "")),
				"answer": answer,
				"required": bool(question.get("required", false)),
				"source": "manual" if manual_ids.has(question_id) else "ai"
			}
		)

	return {
		"format_version": INTERVIEW_REVIEW_FORMAT_VERSION_V01517,
		"entries": entries
	}


func queue_collaborator_blueprint(
	conversation_messages: Array,
	context_blocks: Array[String],
	memory_summary: String,
	profile: Dictionary,
	retry_count: int,
	session_id: String
) -> Dictionary:
	var transcript := _collaborator_transcript_v01515(conversation_messages)
	if transcript.is_empty() and memory_summary.strip_edges().is_empty():
		return {"ok": false, "error": "Develop the character in the Collaborator before creating a Generation Blueprint."}

	var prompt := """Create a LOSS-MINIMISING CHARACTER GENERATION BLUEPRINT from this authoring collaboration.

This blueprint will become Character Card Forge's authoritative Generation Concept. A later validated generation pass will materialise the normal template fields from it, so preserving detail matters more than brevity.

BLUEPRINT RULES:
1. Preserve every established character fact and accepted author decision you can recover: names, ages, appearance, clothing, relationships, chronology, history, habits, preferences, boundaries, sexuality/romance details when established, motivations, secrets, setting facts, scene beats, dialogue mannerisms, props, occupations, family details, and other concrete specifics.
2. Do NOT compress several specific facts into a vague summary merely to make the blueprint shorter. Prefer useful redundancy over losing an established detail.
3. Treat the author's corrections, later decisions and explicit accept/reject statements as authoritative. Do not resurrect rejected ideas as canon.
4. Distinguish still-open alternatives from settled canon. If an alternate route/idea remains intentionally available, place it in a clearly labelled optional/alternate section rather than silently mixing it into the main character.
5. Preserve literal {{user}} and {{char}} placeholders where appropriate. Never replace {{user}} with a named protagonist.
6. Include final-card intent as well as facts: how Description should present the character, Personality/behaviour requirements, Scenario, First Message beats, Example Dialogue/voice requirements, System/Post-History rules, and any creator-facing guidance that matters.
7. Include a dedicated ALTERNATIVE GREETINGS section in concept_prompt. Preserve any exact or substantially developed alternate openings from the collaboration; if only opening concepts were developed, retain enough detail for faithful materialisation.
8. Include a dedicated LOREBOOK section in concept_prompt. Preserve planned lorebook entries, trigger keys, world/relationship facts, recurring locations, named side characters, secrets, organisations, terminology or other information that benefits from triggerable recall.
9. Include unresolved questions only when they genuinely remain unresolved. Do not replace settled facts with questions.
10. The Generation Concept may be long. Detail retention is the priority.

SUPPLEMENTARY MATERIALISATION RULES:
- alternate_greetings must contain complete playable alternative first messages when the collaboration contains developed alternate openings or explicit alternate-opening plans. Preserve exact/developed wording where appropriate and expand only what is needed to make a planned opening playable. Return an empty array if there is genuinely no alternative-opening material.
- lorebook must be a Character Card-compatible Character Book object with `name` and `entries`. Preserve explicit trigger keys and named facts. Each useful entry may contain keys, secondary_keys, content, comment, enabled, constant, selective, case_sensitive, priority, insertion_order, and position. Use an empty entries array only when there truly is no useful lorebook material.
- The supplementary arrays/object are structured copies of material that also remains represented in the canonical concept_prompt. They are not a replacement for the detailed blueprint.

Use clear internal headings such as CHARACTER IDENTITY, RELATIONSHIP TO {{user}}, APPEARANCE, PERSONALITY & BEHAVIOUR, HISTORY, SETTING / WORLD FACTS, ROLEPLAY SCENARIO, FIRST MESSAGE REQUIREMENTS, EXAMPLE DIALOGUE / VOICE, ALTERNATIVE GREETINGS, LOREBOOK, SYSTEM / BEHAVIOURAL RULES, and OPTIONAL / ALTERNATE DIRECTIONS where relevant.
"""
	var clean_memory := memory_summary.strip_edges()
	if not clean_memory.is_empty():
		prompt += "\nCOMPRESSED EARLIER MEMORY (lossy; prefer newer verbatim decisions on conflict):\n%s\n" % clean_memory
	var context_text := _join_non_empty(context_blocks, "\n\n---\n\n")
	if not context_text.is_empty():
		prompt += "\nREFERENCE CONTEXT:\n%s\n" % context_text
	if not transcript.is_empty():
		prompt += "\nCURRENT COLLABORATION TRANSCRIPT:\n%s\n" % transcript
	prompt += """
Return one valid JSON object with exactly these keys:
- suggested_name: the settled character name if known, otherwise an empty string.
- concept_prompt: the complete detailed blueprint as one string.
- alternate_greetings: an array of complete playable alternate openings grounded in the collaboration, or an empty array when none exist.
- lorebook: a Character Card-compatible Character Book object with `name` and `entries`.

Do not return the normal Character Card template fields separately. Do not return markdown fences or commentary outside the JSON object.
"""

	return _queue_chat_job(
		"collaborator_blueprint",
		"Build loss-minimising character blueprint",
		profile,
		[
			{
				"role": "system",
				"content": "You are Character Card Forge's continuity editor. Convert a long creative collaboration into an exhaustive canonical generation blueprint while also returning structured Alternative Greetings and Character Lorebook material when present. Preserve concrete accepted detail and final author intent rather than aggressively summarising it. Return valid JSON only."
			},
			{"role": "user", "content": prompt}
		],
		"object",
		{
			"session_id": session_id,
			"handoff_mode": "blueprint",
			"preserve_detail": true,
			"supplementary_material": true
		},
		retry_count
	)


func queue_blueprint_supplemental_material(
	project: Dictionary,
	profile: Dictionary,
	retry_count: int,
	fill_alternate_greetings: bool,
	fill_lorebook: bool
) -> Dictionary:
	if not fill_alternate_greetings and not fill_lorebook:
		return {"ok": false, "error": "No missing Blueprint supplementary material needs generation."}
	var concept := str(CCFStorageService.get_value_at_path(project, "concept.prompt", "")).strip_edges()
	if concept.is_empty():
		return {"ok": false, "error": "The active character has no Generation Blueprint to materialise."}

	var requested: Array[String] = []
	if fill_alternate_greetings:
		requested.append(
			"ALTERNATIVE GREETINGS: extract every developed alternate opening from the Blueprint. Preserve complete openings; when the Blueprint contains a detailed opening concept rather than final prose, faithfully turn that concept into a complete playable greeting without changing established facts."
		)
	if fill_lorebook:
		requested.append(
			"LOREBOOK: extract the Blueprint's planned triggerable lore into a Character Card-compatible Character Book. Preserve names, trigger keys, side-character facts, locations, secrets, terminology and other explicit lore rather than replacing them with generic summaries."
		)

	var prompt := """Materialise the missing supplementary character data from this authoritative Character Card Forge Generation Blueprint.

This is an extraction/materialisation pass, not a rewrite of the character. Do not alter established facts, invent unrelated lore, or reinterpret rejected ideas as canon.

REQUESTED MATERIAL:
%s

AUTHORITATIVE GENERATION BLUEPRINT:
%s

Return one valid JSON object with exactly these keys:
- alternate_greetings: an array of complete playable alternate first messages. Return [] when this scope was not requested or the Blueprint genuinely contains no alternative-opening material.
- lorebook: a Character Card-compatible Character Book object with `name` and `entries`. Return an object with an empty entries array when this scope was not requested or no useful lorebook material exists.

For lorebook entries, preserve explicit keys where the Blueprint supplies them. Entries may contain keys, secondary_keys, content, comment, enabled, constant, selective, case_sensitive, priority, insertion_order, and position. Return JSON only.
""" % [_join_values(requested, "\n"), concept]

	return _queue_chat_job(
		"blueprint_supplemental_material",
		"Materialise Blueprint Alternative Greetings and Lorebook",
		profile,
		[
			{
				"role": "system",
				"content": "You are Character Card Forge's Blueprint supplementary-material extractor. Materialise only the requested Alternative Greetings and Character Lorebook data from the supplied authoritative blueprint. Preserve established detail. Return valid JSON only."
			},
			{"role": "user", "content": prompt}
		],
		"object",
		{
			"project_id": str(project.get("project_id", "")),
			"fill_alternate_greetings": fill_alternate_greetings,
			"fill_lorebook": fill_lorebook,
			"source": "collaborator_blueprint"
		},
		retry_count
	)
