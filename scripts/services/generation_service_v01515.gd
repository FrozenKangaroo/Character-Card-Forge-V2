class_name CCFGenerationServiceV01515
extends "res://scripts/services/generation_service_v01514.gd"


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

This blueprint will become Character Card Forge's authoritative Generation Concept. A later generation pass will materialise the actual card from it, so preserving detail matters more than brevity.

BLUEPRINT RULES:
1. Preserve every established character fact and accepted author decision you can recover: names, ages, appearance, clothing, relationships, chronology, history, habits, preferences, boundaries, sexuality/romance details when established, motivations, secrets, setting facts, scene beats, dialogue mannerisms, props, occupations, family details, and other concrete specifics.
2. Do NOT compress several specific facts into a vague summary merely to make the blueprint shorter. Prefer useful redundancy over losing an established detail.
3. Treat the author's corrections, later decisions and explicit accept/reject statements as authoritative. Do not resurrect rejected ideas as canon.
4. Distinguish still-open alternatives from settled canon. If an alternate route/idea remains intentionally available, place it in a clearly labelled optional/alternate section rather than silently mixing it into the main character.
5. Preserve literal {{user}} and {{char}} placeholders where appropriate. Never replace {{user}} with a named protagonist.
6. Include final-card intent as well as facts: how Description should present the character, Personality/behaviour requirements, Scenario, First Message beats, Example Dialogue/voice requirements, System/Post-History rules, and any creator-facing guidance that matters.
7. Include a dedicated ALTERNATIVE GREETINGS section. Preserve any exact or substantially developed alternate openings from the collaboration; otherwise record distinct opening concepts that a later generation pass can turn into complete greetings.
8. Include a dedicated LOREBOOK section. Preserve planned lorebook entries, trigger keys, world/relationship facts, recurring locations, named side characters, secrets, organisations, terminology or other information that benefits from triggerable recall.
9. Include unresolved questions only when they genuinely remain unresolved. Do not replace settled facts with questions.
10. The Generation Concept may be long. Detail retention is the priority.

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

Do not return the normal Character Card fields separately. Do not return markdown fences or commentary outside the JSON object.
"""

	return _queue_chat_job(
		"collaborator_blueprint",
		"Build loss-minimising character blueprint",
		profile,
		[
			{
				"role": "system",
				"content": "You are Character Card Forge's continuity editor. Convert a long creative collaboration into an exhaustive canonical generation blueprint. Preserve concrete accepted detail and final author intent rather than aggressively summarising it. Return valid JSON only."
			},
			{"role": "user", "content": prompt}
		],
		"object",
		{
			"session_id": session_id,
			"handoff_mode": "blueprint",
			"preserve_detail": true
		},
		retry_count
	)


func queue_collaborator_detailed_draft(
	conversation_messages: Array,
	context_blocks: Array[String],
	memory_summary: String,
	template: Dictionary,
	profile: Dictionary,
	retry_count: int,
	session_id: String,
	alternate_greeting_count: int = 3
) -> Dictionary:
	var generation_fields := CCFTemplateService.generation_fields(template)
	if generation_fields.is_empty():
		return {"ok": false, "error": "The active template has no AI-generatable character fields."}

	var requested_lines: Array[String] = []
	var field_ids: Array[String] = []
	for raw_field in generation_fields:
		if not raw_field is Dictionary:
			continue
		var field: Dictionary = raw_field
		var field_id := str(field.get("id", "")).strip_edges()
		if field_id.is_empty():
			continue
		field_ids.append(field_id)
		var line := "- %s: %s (%s)" % [field_id, str(field.get("label", field_id)), _field_type_instruction(field)]
		var custom := str(field.get("generation_prompt", "")).strip_edges()
		if not custom.is_empty():
			line += " — %s" % custom
		requested_lines.append(line)

	var component_plan := _full_synthesis_plan_v01514(template)
	var component_blocks_value: Variant = component_plan.get("component_blocks", [])
	var component_blocks: Array[String] = component_blocks_value if component_blocks_value is Array else []
	var component_text := "No Generation Groups are configured. Follow the field instructions directly."
	if not component_blocks.is_empty():
		component_text = _join_values(component_blocks, "\n\n")

	var transcript := _collaborator_transcript_v01515(conversation_messages)
	var prompt := """Create a HIGH-DETAIL Workspace draft from this Character Collaborator session.

Unlike the Blueprint handoff, this mode intentionally materialises fields immediately. Preserve the same level of specificity the author developed in the conversation; do not turn long-established material into generic short summaries simply because it is being distributed among fields.

DETAIL-PRESERVATION RULES:
1. Later author corrections and accepted decisions are canon. Rejected suggestions are not.
2. Preserve concrete details. If a fact is relevant to more than one field, repeating it where useful for roleplay consistency is preferable to dropping it.
3. Follow the active template's field instructions and enabled Generation Component plan, but use them to ORGANISE the established material rather than to erase details that do not fit a terse summary.
4. Description, Personality, Scenario, First Message, Example Dialogue and Advanced fields should be complete final-form material, not notes or placeholders.
5. Preserve literal {{user}}/{{char}} placeholders and the established relationship with {{user}}.
6. Alternative Greetings must be complete playable openings, not one-line concepts. Preserve exact/developed alternates from the collaboration where available; otherwise produce meaningfully different openings grounded in the same character.
7. Lorebook entries should preserve explicit planned lore and useful triggerable facts. Do not replace named people, places, secrets or terms with vague summaries.

ACTIVE TEMPLATE FIELDS:
%s

GENERATION COMPONENT PLAN:
%s
""" % [_join_values(requested_lines, "\n"), component_text]

	var clean_memory := memory_summary.strip_edges()
	if not clean_memory.is_empty():
		prompt += "\nCOMPRESSED EARLIER MEMORY (lossy):\n%s\n" % clean_memory
	var context_text := _join_non_empty(context_blocks, "\n\n---\n\n")
	if not context_text.is_empty():
		prompt += "\nREFERENCE CONTEXT:\n%s\n" % context_text
	if not transcript.is_empty():
		prompt += "\nCURRENT COLLABORATION TRANSCRIPT:\n%s\n" % transcript

	var safe_alt_count := clampi(alternate_greeting_count, 1, 8)
	prompt += """
Return one valid JSON object with exactly these top-level keys:
- concept_prompt: a detailed generation-ready source summary retaining the important facts behind this draft.
- fields: one object containing every requested active-template field ID above.
- alternate_greetings: an array of %d complete playable alternative first messages unless the collaboration explicitly establishes a different count or explicitly says there should be none.
- lorebook: a Character Card-compatible Character Book object with `name` and `entries`. Each useful entry may contain keys, secondary_keys, content, comment, enabled, constant, selective, case_sensitive, priority, insertion_order, and position. Use an empty entries array only when there truly is no useful lorebook material.

Do not add commentary or markdown fences. Return JSON only.
""" % safe_alt_count

	return _queue_chat_job(
		"collaborator_character_detailed",
		"Build detailed Workspace draft from collaboration",
		profile,
		[
			{
				"role": "system",
				"content": "You are Character Card Forge's detailed character materialiser. Preserve established authoring detail while distributing it into a complete template-aware Workspace draft, Alternative Greetings and Character Lorebook. Return valid JSON only."
			},
			{"role": "user", "content": prompt}
		],
		"object",
		{
			"session_id": session_id,
			"template_id": str(template.get("template_id", "default")),
			"field_ids": field_ids,
			"handoff_mode": "detailed_workspace_draft",
			"alternate_greeting_count": safe_alt_count,
			"preserve_detail": true
		},
		retry_count
	)


func _collaborator_transcript_v01515(conversation_messages: Array) -> String:
	var transcript_lines: Array[String] = []
	for raw_message in conversation_messages:
		if not raw_message is Dictionary:
			continue
		var role := str(raw_message.get("role", "")).strip_edges()
		var content := str(raw_message.get("content", "")).strip_edges()
		if role not in ["user", "assistant"] or content.is_empty():
			continue
		transcript_lines.append("%s: %s" % [role.capitalize(), content])
	return _join_values(transcript_lines, "\n\n")
