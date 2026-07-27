class_name CCFInterviewContextGenerationService
extends CCFInterviewGenerationService


func _build_interview_payload(
	base_payload_value: Dictionary,
	concept: String,
	questions: Array,
	known_answers: Dictionary,
	missing_only: bool
) -> Dictionary:
	var payload := super._build_interview_payload(
		base_payload_value, concept, questions, known_answers, missing_only
	)
	if known_answers.is_empty():
		return payload

	var messages_value: Variant = payload.get("messages", [])
	if not messages_value is Array or messages_value.is_empty():
		return payload
	var messages: Array = messages_value.duplicate(true)
	var last_index := messages.size() - 1
	var message_value: Variant = messages[last_index]
	if not message_value is Dictionary:
		return payload
	var message: Dictionary = message_value.duplicate(true)
	if str(message.get("role", "")) != "user":
		return payload

	var existing_content := str(message.get("content", ""))
	if existing_content.contains("KNOWN INTERVIEW ANSWERS — preserve these; do not contradict them:"):
		return payload

	var answer_lines: Array[String] = []
	for question_id_value in known_answers:
		var question_id := str(question_id_value).strip_edges()
		var answer := _value_to_text(known_answers.get(question_id_value, "")).strip_edges()
		if question_id.is_empty() or answer.is_empty():
			continue
		answer_lines.append("%s: %s" % [question_id, answer])
	if answer_lines.is_empty():
		return payload

	message["content"] = (
		existing_content
		+ "\n\nAUTHOR-SUPPLIED OR PREVIOUS INTERVIEW ANSWERS — authoritative planning facts:\n"
		+ _join_string_array(answer_lines, "\n")
		+ "\nDo not contradict or replace these answers. Use them when resolving the remaining questions."
	)
	messages[last_index] = message
	payload["messages"] = messages
	return payload
