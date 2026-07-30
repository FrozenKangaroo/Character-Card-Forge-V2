extends Node

signal capabilities_loaded(models: Array)
signal capabilities_failed(message: String)

var _request: HTTPRequest
var _busy := false


func _ready() -> void:
	_request = HTTPRequest.new()
	_request.timeout = 60.0
	add_child(_request)
	_request.request_completed.connect(_on_request_completed)


func fetch_capabilities(profile: Dictionary) -> Dictionary:
	if _busy:
		return {"ok": false, "error": "A model capability request is already running."}
	var base_url := str(profile.get("base_url", "")).strip_edges()
	if base_url.is_empty():
		return {"ok": false, "error": "Enter an API base URL first."}
	var headers := PackedStringArray(["Accept: application/json"])
	var api_key := str(profile.get("api_key", "")).strip_edges()
	if not api_key.is_empty():
		headers.append("Authorization: Bearer %s" % api_key)
	_busy = true
	var request_error := _request.request(_models_url(base_url), headers, HTTPClient.METHOD_GET)
	if request_error != OK:
		_busy = false
		return {"ok": false, "error": "Could not start model capability request (error %s)." % request_error}
	return {"ok": true}


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_busy = false
	if result != HTTPRequest.RESULT_SUCCESS:
		capabilities_failed.emit("Model capability request failed (result %s)." % result)
		return
	var body_text := body.get_string_from_utf8()
	var parser := JSON.new()
	if parser.parse(body_text) != OK:
		capabilities_failed.emit("The model endpoint returned invalid JSON.")
		return
	var parsed: Variant = parser.data
	if response_code < 200 or response_code >= 300:
		capabilities_failed.emit("API error %s while fetching model capabilities." % response_code)
		return
	var entries: Array = []
	if parsed is Dictionary:
		var data: Variant = parsed.get("data", parsed.get("models", []))
		if data is Array:
			entries = data
	elif parsed is Array:
		entries = parsed
	var models: Array[Dictionary] = []
	for raw_entry in entries:
		if raw_entry is Dictionary:
			var capability := capability_from_entry(raw_entry)
			if not str(capability.get("id", "")).is_empty():
				models.append(capability)
		else:
			var model_id := str(raw_entry).strip_edges()
			if not model_id.is_empty():
				models.append({"id": model_id, "context_window": 0, "max_output_tokens": 0, "vision": false, "raw": {}})
	models.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("id", "")) < str(b.get("id", "")))
	if models.is_empty():
		capabilities_failed.emit("The model endpoint returned no model IDs.")
		return
	capabilities_loaded.emit(models)


func capability_from_entry(entry: Dictionary) -> Dictionary:
	var model_id := str(entry.get("id", entry.get("name", ""))).strip_edges()
	var context_window := _first_positive_int(entry, [
		"context_length", "context_window", "max_context_length", "max_model_len", "n_ctx", "context_window_tokens"
	])
	if context_window <= 0:
		context_window = _nested_positive_int(entry, ["capabilities", "metadata", "architecture"], [
			"context_length", "context_window", "max_context_length", "max_model_len"
		])
	var max_output := _first_positive_int(entry, [
		"max_output_tokens", "max_completion_tokens", "output_token_limit", "max_generation_tokens", "max_tokens"
	])
	if max_output <= 0:
		max_output = _nested_positive_int(entry, ["capabilities", "metadata", "top_provider"], [
			"max_output_tokens", "max_completion_tokens", "output_token_limit", "max_generation_tokens"
		])
	var vision := _detect_vision(entry)
	return {
		"id": model_id,
		"context_window": context_window,
		"max_output_tokens": max_output,
		"vision": vision,
		"raw": entry.duplicate(true)
	}


func _first_positive_int(data: Dictionary, keys: Array[String]) -> int:
	for key in keys:
		if not data.has(key):
			continue
		var value := int(data.get(key, 0))
		if value > 0:
			return value
	return 0


func _nested_positive_int(data: Dictionary, containers: Array[String], keys: Array[String]) -> int:
	for container_key in containers:
		var nested: Variant = data.get(container_key, {})
		if nested is Dictionary:
			var value := _first_positive_int(nested, keys)
			if value > 0:
				return value
	return 0


func _detect_vision(entry: Dictionary, depth: int = 0) -> bool:
	for key in ["vision", "supports_vision", "multimodal"]:
		if bool(entry.get(key, false)):
			return true
	for key in ["modalities", "input_modalities", "supported_modalities"]:
		var modalities: Variant = entry.get(key, [])
		if modalities is Array:
			for modality in modalities:
				var value := str(modality).to_lower()
				if value.contains("image") or value.contains("vision"):
					return true
	if depth >= 8 or not entry.has("capabilities"):
		return false
	var capabilities: Variant = entry.get("capabilities")
	if capabilities is Dictionary and not capabilities.is_empty():
		return _detect_vision(capabilities, depth + 1)
	return false


func _models_url(base_url: String) -> String:
	var url := base_url.strip_edges().trim_suffix("/")
	if url.ends_with("/chat/completions"):
		url = url.trim_suffix("/chat/completions")
	if url.ends_with("/responses"):
		url = url.trim_suffix("/responses")
	if not url.ends_with("/models"):
		url += "/models"
	return _provider_models_url(url)


func _provider_models_url(models_url: String) -> String:
	# NanoGPT's OpenAI-compatible basic listing intentionally omits the rich
	# metadata Character Card Forge needs. Its documented detailed mode exposes
	# context_length, max_output_tokens, capabilities and pricing. Keep this
	# provider-specific so generic OpenAI-compatible servers are not sent an
	# unknown query parameter they may reject.
	var lower_url := models_url.to_lower()
	if lower_url.contains("nano-gpt.com") and not lower_url.contains("detailed="):
		return models_url + ("&" if models_url.contains("?") else "?") + "detailed=true"
	return models_url
