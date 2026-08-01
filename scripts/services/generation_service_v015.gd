class_name CCFGenerationServiceV015
extends "res://scripts/services/generation_service_v01418.gd"

const COLLABORATOR_SYSTEM_PROMPT := "You are Character Card Forge's Character Collaborator: a creative character-design partner. Converse naturally with the author, help them explore and refine character ideas, preserve established facts, distinguish suggestions from canon, and ask useful questions when appropriate. You are brainstorming with the author, not roleplaying as the character. Keep {{user}} literal when discussing the eventual roleplay user."


func queue_collaborator_reply(
	conversation_messages: Array,
	context_blocks: Array[String],
	memory_summary: String,
	profile: Dictionary,
	retry_count: int,
	session_id: String,
	regenerate: bool = false
) -> Dictionary:
	var messages: Array = [{"role": "system", "content": COLLABORATOR_SYSTEM_PROMPT}]
	var context_text := _join_non_empty(context_blocks, "\n\n---\n\n")
	if not context_text.is_empty():
		messages.append({
			"role": "system",
			"content": "REFERENCE CONTEXT supplied by the author. Treat this as source material; do not silently overwrite or contradict it:\n\n%s" % context_text
		})
	var clean_memory := memory_summary.strip_edges()
	if not clean_memory.is_empty():
		messages.append({
			"role": "system",
			"content": "COMPRESSED EARLIER CONVERSATION MEMORY. This is a lossy summary of older messages; prefer newer verbatim messages if they conflict:\n\n%s" % clean_memory
		})
	for raw_message in conversation_messages:
		if not raw_message is Dictionary:
			continue
		var role := str(raw_message.get("role", "")).strip_edges()
		var content := str(raw_message.get("content", "")).strip_edges()
		if role not in ["user", "assistant"] or content.is_empty():
			continue
		messages.append({"role": role, "content": content})
	if messages.size() <= 1:
		return {"ok": false, "error": "Enter a message before asking the Character Collaborator."}
	return _queue_chat_job(
		"collaborator_reply",
		"Character Collaborator reply",
		profile,
		messages,
		"collaborator_text",
		{"session_id": session_id, "regenerate": regenerate},
		retry_count
	)


func queue_collaborator_summary(
	messages_to_summarise: Array,
	context_blocks: Array[String],
	previous_memory: String,
	profile: Dictionary,
	retry_count: int,
	session_id: String,
	through_index: int
) -> Dictionary:
	var transcript_lines: Array[String] = []
	for raw_message in messages_to_summarise:
		if not raw_message is Dictionary:
			continue
		var role := str(raw_message.get("role", "")).strip_edges()
		var content := str(raw_message.get("content", "")).strip_edges()
		if content.is_empty():
			continue
		transcript_lines.append("%s: %s" % [role.capitalize(), content])
	if transcript_lines.is_empty():
		return {"ok": false, "error": "There are no older messages available to summarise."}
	var prompt := "Compress the older Character Collaborator conversation into durable authoring memory. Preserve concrete character facts, relationships, decisions, rejected ideas that matter, unresolved questions, and important creative constraints. Remove repetition and conversational filler. Do not invent anything."
	if not previous_memory.strip_edges().is_empty():
		prompt += "\n\nPREVIOUS MEMORY TO MERGE:\n%s" % previous_memory.strip_edges()
	var context_text := _join_non_empty(context_blocks, "\n\n---\n\n")
	if not context_text.is_empty():
		prompt += "\n\nREFERENCE CONTEXT (use only to disambiguate the transcript):\n%s" % context_text
	prompt += "\n\nOLDER TRANSCRIPT:\n%s" % "\n\n".join(transcript_lines)
	prompt += "\n\nReturn a concise but information-dense plain-text memory. Summarisation is allowed to lose wording, but not deliberate character decisions where avoidable."
	return _queue_chat_job(
		"collaborator_summary",
		"Summarise older collaborator context",
		profile,
		[
			{"role": "system", "content": "You create faithful compressed memory for a long-running character-design conversation."},
			{"role": "user", "content": prompt}
		],
		"collaborator_text",
		{"session_id": session_id, "through_index": through_index},
		retry_count
	)


func queue_collaborator_vision_summary(
	image_path: String,
	profile: Dictionary,
	retry_count: int,
	session_id: String
) -> Dictionary:
	var image_result := _image_data_url_from_file(image_path)
	if not bool(image_result.get("ok", false)):
		return image_result
	var prompt := "Analyse this image as reference material for character design. Describe only useful visible evidence: apparent physical traits, hairstyle, clothing, accessories, expression, pose, environment, visual mood/style, and any notable objects. Separate direct observations from cautious inspiration suggestions. Do not identify real people. Return plain text suitable to feed into a separate text model as character-design context."
	var messages := [
		{
			"role": "system",
			"content": "You are Character Card Forge's vision analyst. Produce grounded visual context for a separate character-design text model."
		},
		{
			"role": "user",
			"content": [
				{"type": "text", "text": prompt},
				{"type": "image_url", "image_url": {"url": str(image_result.get("data_url", "")), "detail": str(profile.get("vision_detail", "auto"))}}
			]
		}
	]
	return _queue_chat_job(
		"collaborator_vision",
		"Analyse collaborator reference image",
		profile,
		messages,
		"collaborator_text",
		{"session_id": session_id, "image_path": image_path, "image_name": image_path.get_file()},
		retry_count
	)


func queue_collaborator_character(
	conversation_messages: Array,
	context_blocks: Array[String],
	memory_summary: String,
	template: Dictionary,
	profile: Dictionary,
	retry_count: int,
	session_id: String
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
	var transcript_lines: Array[String] = []
	for raw_message in conversation_messages:
		if raw_message is Dictionary:
			var role := str(raw_message.get("role", "")).strip_edges()
			var content := str(raw_message.get("content", "")).strip_edges()
			if role in ["user", "assistant"] and not content.is_empty():
				transcript_lines.append("%s: %s" % [role.capitalize(), content])
	var prompt := "Materialise the character that the author and Character Collaborator have developed into a complete Character Card Forge workspace draft. Resolve brainstorming into the most recently accepted interpretation. Do not treat every suggestion as canon when the author rejected or revised it."
	if not memory_summary.strip_edges().is_empty():
		prompt += "\n\nCOMPRESSED EARLIER MEMORY:\n%s" % memory_summary.strip_edges()
	var context_text := _join_non_empty(context_blocks, "\n\n---\n\n")
	if not context_text.is_empty():
		prompt += "\n\nREFERENCE CONTEXT:\n%s" % context_text
	prompt += "\n\nCURRENT COLLABORATION TRANSCRIPT:\n%s" % "\n\n".join(transcript_lines)
	prompt += "\n\nREQUESTED CHARACTER FIELDS:\n%s" % "\n".join(requested_lines)
	prompt += "\n\nReturn one JSON object with exactly two top-level keys: concept_prompt and fields. concept_prompt is a concise generation-ready summary of the final character concept. fields is one JSON object containing only the requested field IDs above. Preserve literal {{user}} where the roleplay user is referenced. Return JSON only."
	return _queue_chat_job(
		"collaborator_character",
		"Generate character from collaboration",
		profile,
		[
			{"role": "system", "content": "You are Character Card Forge's final character materialiser. Convert an authoring conversation into a coherent roleplay character card without inventing contradictions or reverting rejected ideas. Return valid JSON only."},
			{"role": "user", "content": prompt}
		],
		"object",
		{"session_id": session_id, "template_id": str(template.get("template_id", "default")), "field_ids": field_ids},
		retry_count
	)


func _process_completed_content(content: String) -> void:
	if str(_active_job.get("parse_mode", "")) != "collaborator_text":
		super._process_completed_content(content)
		return
	var clean_content := content.strip_edges()
	if clean_content.is_empty():
		_handle_failure("The Character Collaborator returned an empty response.", false)
		return
	var finished_job := _active_job.duplicate(true)
	_active_job.clear()
	var completed_metadata: Dictionary = finished_job.get("metadata", {}).duplicate(true)
	completed_metadata["model"] = str(finished_job.get("model", ""))
	completed_metadata["profile_name"] = str(finished_job.get("profile_name", ""))
	completed_metadata["attempts"] = int(finished_job.get("attempt", 1))
	completed_metadata["response_repair_attempts"] = 0
	completed_metadata["parse_strategy"] = "raw_text"
	job_completed.emit(
		str(finished_job.get("id", "")),
		str(finished_job.get("type", "")),
		clean_content,
		completed_metadata
	)
	_emit_queue_changed()
	call_deferred("_start_next_job")


func _image_data_url_from_file(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {"ok": false, "error": "The selected image file no longer exists."}
	var extension := path.get_extension().to_lower()
	var mime := ""
	match extension:
		"png": mime = "image/png"
		"jpg", "jpeg": mime = "image/jpeg"
		"webp": mime = "image/webp"
		_: return {"ok": false, "error": "Character Collaborator vision currently supports PNG, JPG/JPEG, and WebP images."}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not read the selected image."}
	var bytes := file.get_buffer(file.get_length())
	file.close()
	if bytes.is_empty():
		return {"ok": false, "error": "The selected image is empty."}
	return {"ok": true, "data_url": "data:%s;base64,%s" % [mime, Marshalls.raw_to_base64(bytes)]}


func _join_non_empty(values: Array[String], separator: String) -> String:
	var clean: Array[String] = []
	for value in values:
		var text := value.strip_edges()
		if not text.is_empty():
			clean.append(text)
	return separator.join(clean)
