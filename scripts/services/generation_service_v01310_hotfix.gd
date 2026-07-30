class_name CCFGenerationServiceV01310Hotfix
extends CCFGenerationServiceV0135


func _on_request_completed(
	result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	if _active_job.is_empty():
		return

	if result != HTTPRequest.RESULT_SUCCESS:
		_handle_failure("Network request failed (result %s)." % result, true)
		return

	var body_text: String = body.get_string_from_utf8()
	var parsed_response: Variant = JSON.parse_string(body_text)
	if response_code < 200 or response_code >= 300:
		var detail: String = _extract_error_detail(parsed_response, body_text)
		var retryable := (
			response_code == 408
			or response_code == 409
			or response_code == 429
			or response_code >= 500
		)
		_handle_failure("API error %s: %s" % [response_code, detail.left(1000)], retryable)
		return
	if not parsed_response is Dictionary:
		_handle_failure("The API returned an invalid JSON response envelope.", false)
		return

	var response: Dictionary = parsed_response
	var content: String = _extract_content(response).strip_edges()
	if content.is_empty():
		var parse_mode := str(_active_job.get("parse_mode", "object"))
		content = _extract_direct_reasoning_json(response, parse_mode)
	if content.is_empty():
		_handle_failure(_empty_assistant_text_message(response), false)
		return

	_process_completed_content(content)


func _extract_content(response: Dictionary) -> String:
	var inherited: String = super._extract_content(response).strip_edges()
	if not inherited.is_empty():
		return inherited

	var choices: Variant = response.get("choices", [])
	if choices is Array:
		for raw_choice in choices:
			if not raw_choice is Dictionary:
				continue
			var choice: Dictionary = raw_choice
			var message_value: Variant = choice.get("message", {})
			if message_value is Dictionary:
				var message: Dictionary = message_value
				var message_text := _content_value_to_text(message.get("content", null))
				if not message_text.is_empty():
					return message_text
				for key in ["output_text", "text"]:
					var direct_message_text := _text_value_to_string(message.get(key, null))
					if not direct_message_text.is_empty():
						return direct_message_text
			for key in ["output_text", "text"]:
				var direct_choice_text := _text_value_to_string(choice.get(key, null))
				if not direct_choice_text.is_empty():
					return direct_choice_text

	var top_level_text := _text_value_to_string(response.get("output_text", null))
	if not top_level_text.is_empty():
		return top_level_text

	var output_value: Variant = response.get("output", [])
	if output_value is Array:
		for raw_output in output_value:
			if not raw_output is Dictionary:
				continue
			var output_item: Dictionary = raw_output
			var output_text := _content_value_to_text(output_item.get("content", null))
			if not output_text.is_empty():
				return output_text
			if str(output_item.get("type", "")) == "output_text":
				output_text = _text_value_to_string(output_item.get("text", null))
				if not output_text.is_empty():
					return output_text

	return ""


func _content_value_to_text(value: Variant) -> String:
	if value is String:
		return value.strip_edges()
	if value is Array:
		var parts: Array[String] = []
		for raw_part in value:
			var part_text := _content_value_to_text(raw_part)
			if not part_text.is_empty():
				parts.append(part_text)
		return "\n".join(parts).strip_edges()
	if not value is Dictionary:
		return ""

	var part: Dictionary = value
	var part_type := str(part.get("type", "")).strip_edges()
	if part.has("text") and part_type in ["", "text", "output_text"]:
		var text := _text_value_to_string(part.get("text", null))
		if not text.is_empty():
			return text
	if part_type == "message" or part.has("content"):
		var nested := _content_value_to_text(part.get("content", null))
		if not nested.is_empty():
			return nested
	return ""


func _text_value_to_string(value: Variant) -> String:
	if value is String:
		return value.strip_edges()
	if value is Dictionary:
		var text_value: Dictionary = value
		for key in ["value", "text", "content"]:
			var candidate: Variant = text_value.get(key, null)
			if candidate is String and not candidate.strip_edges().is_empty():
				return candidate.strip_edges()
	return ""


func _extract_direct_reasoning_json(response: Dictionary, parse_mode: String) -> String:
	for reasoning_text in _reasoning_text_candidates(response):
		var clean := reasoning_text.strip_edges()
		if clean.is_empty() or (not clean.begins_with("{") and not clean.begins_with("[")):
			continue
		var parser := JSON.new()
		if parser.parse(clean) != OK:
			continue
		var normalised := _normalise_parsed_output(parser.data, parse_mode)
		if bool(normalised.get("ok", false)):
			return clean
	return ""


func _reasoning_text_candidates(response: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var choices: Variant = response.get("choices", [])
	if choices is Array:
		for raw_choice in choices:
			if not raw_choice is Dictionary:
				continue
			var message_value: Variant = raw_choice.get("message", {})
			if not message_value is Dictionary:
				continue
			var message: Dictionary = message_value
			for key in ["reasoning_content", "reasoning"]:
				var candidate: Variant = message.get(key, null)
				if candidate is String and not candidate.strip_edges().is_empty():
					result.append(candidate)
	return result


func _empty_assistant_text_message(response: Dictionary) -> String:
	var finish_reasons: Array[String] = []
	var has_tool_calls := false
	var choices: Variant = response.get("choices", [])
	if choices is Array:
		for raw_choice in choices:
			if not raw_choice is Dictionary:
				continue
			var reason := str(raw_choice.get("finish_reason", "")).strip_edges()
			if not reason.is_empty() and not finish_reasons.has(reason):
				finish_reasons.append(reason)
			var message_value: Variant = raw_choice.get("message", {})
			if message_value is Dictionary:
				var tool_calls: Variant = message_value.get("tool_calls", [])
				if tool_calls is Array and not tool_calls.is_empty():
					has_tool_calls = true

	var reasoning_present := not _reasoning_text_candidates(response).is_empty()
	if finish_reasons.has("length"):
		var message := "The backend stopped before producing final assistant text (finish_reason=length). Increase Maximum output tokens in the Character AI profile"
		if reasoning_present:
			message += " or reduce/disable model reasoning so the final JSON has token budget remaining"
		return message + "."
	if finish_reasons.has("content_filter"):
		return "The backend stopped the response before returning assistant text (finish_reason=content_filter). Check the provider/model moderation or safety settings."
	if reasoning_present:
		return "The backend returned reasoning content but no final assistant answer. Character Card Forge needs the final text/JSON response. Increase Maximum output tokens or reduce/disable reasoning for this model if the provider exposes that control."
	if has_tool_calls:
		return "The backend returned tool calls instead of assistant text. Character Card Forge generation expects a text/JSON assistant response and does not request tools for this job."
	var output_value: Variant = response.get("output", [])
	if output_value is Array and not output_value.is_empty():
		return "The API returned output items, but none contained usable output_text. The provider may be using a response shape Character Card Forge does not recognise yet."
	if not finish_reasons.is_empty():
		return "The API response did not contain assistant text (finish_reason=%s)." % ", ".join(finish_reasons)
	return "The API response did not contain usable assistant text. The provider returned a successful response envelope, but no recognised text content was present."
