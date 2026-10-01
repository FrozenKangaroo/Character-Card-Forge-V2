class_name CCFOpenAIStreamDecoderV02112
extends RefCounted

var _pending_bytes := PackedByteArray()
var _raw_body := PackedByteArray()
var _saw_sse_event := false
var _done := false
var _malformed_error := ""


func reset() -> void:
	_pending_bytes = PackedByteArray()
	_raw_body = PackedByteArray()
	_saw_sse_event = false
	_done = false
	_malformed_error = ""


func feed_bytes(chunk: PackedByteArray) -> Dictionary:
	var result := {"deltas": [], "done": _done, "error": ""}
	if chunk.is_empty() or not _malformed_error.is_empty():
		return result
	_raw_body.append_array(chunk)
	_pending_bytes.append_array(chunk)
	while true:
		var newline := _pending_bytes.find(10)
		if newline < 0:
			break
		var line_bytes := _pending_bytes.slice(0, newline)
		_pending_bytes = _pending_bytes.slice(newline + 1)
		if not line_bytes.is_empty() and line_bytes[line_bytes.size() - 1] == 13:
			line_bytes.resize(line_bytes.size() - 1)
		_process_line(line_bytes.get_string_from_utf8(), result)
		if not _malformed_error.is_empty():
			break
	result["done"] = _done
	result["error"] = _malformed_error
	return result


func finish() -> Dictionary:
	var result := {"deltas": [], "done": _done, "error": ""}
	if not _pending_bytes.is_empty() and _saw_sse_event:
		_process_line(_pending_bytes.get_string_from_utf8(), result)
	_pending_bytes = PackedByteArray()
	result["done"] = _done
	result["error"] = _malformed_error
	return result


func saw_sse_event() -> bool:
	return _saw_sse_event


func done_received() -> bool:
	return _done


func raw_body() -> PackedByteArray:
	return _raw_body.duplicate()


func raw_text() -> String:
	return _raw_body.get_string_from_utf8()


func _process_line(line: String, result: Dictionary) -> void:
	var clean := line.strip_edges()
	if clean.is_empty() or clean.begins_with(":"):
		return
	if not clean.begins_with("data:"):
		# A custom OpenAI-compatible endpoint may ignore stream=true and return one
		# ordinary JSON envelope. Leave that body untouched for completed fallback.
		return
	_saw_sse_event = true
	var payload_text := clean.substr(5).strip_edges()
	if payload_text == "[DONE]":
		_done = true
		return
	var parser := JSON.new()
	if parser.parse(payload_text) != OK:
		_malformed_error = "The provider returned a malformed streaming event."
		return
	var payload: Variant = parser.data
	if not payload is Dictionary:
		_malformed_error = "The provider returned a malformed streaming event."
		return
	if payload.has("error"):
		_malformed_error = _error_text(payload.get("error"))
		return
	var choices_value: Variant = payload.get("choices", [])
	if not choices_value is Array or choices_value.is_empty():
		return
	var first: Variant = choices_value[0]
	if not first is Dictionary:
		return
	var delta_value: Variant = first.get("delta", {})
	if first.get("finish_reason") != null:
		_done = true
	if not delta_value is Dictionary:
		return
	var content_value: Variant = delta_value.get("content", "")
	if content_value is String:
		if not content_value.is_empty():
			(result["deltas"] as Array).append(content_value)
		return
	if content_value is Array:
		for part in content_value:
			if part is Dictionary and str(part.get("type", "")) in ["text", "output_text"]:
				var text := str(part.get("text", ""))
				if not text.is_empty():
					(result["deltas"] as Array).append(text)


func _error_text(value: Variant) -> String:
	if value is Dictionary:
		return str(value.get("message", "The provider reported a streaming error."))
	var text := str(value).strip_edges()
	return text if not text.is_empty() else "The provider reported a streaming error."
