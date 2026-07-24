class_name CCFOpenAIService
extends Node

signal generation_completed(result: Dictionary)
signal generation_failed(message: String)
signal generation_cancelled()

var _request: HTTPRequest
var _cancelled := false
var _template: Dictionary = {}

func _ready() -> void:
    _request = HTTPRequest.new()
    _request.timeout = 300.0
    add_child(_request)
    _request.request_completed.connect(_on_request_completed)

func generate_character(project: Dictionary, template: Dictionary, profile: Dictionary, include_existing_fields := true) -> Dictionary:
    if _request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        return {"ok": false, "error": "A generation request is already running."}

    var base_url := str(profile.get("base_url", "")).strip_edges()
    var model := str(profile.get("model", "")).strip_edges()
    if base_url.is_empty():
        return {"ok": false, "error": "Set an API base URL in Settings first."}
    if model.is_empty():
        return {"ok": false, "error": "Set a text model in Settings first."}

    _cancelled = false
    _template = template
    var url := _completion_url(base_url)
    var headers := PackedStringArray(["Content-Type: application/json"])
    var api_key := str(profile.get("api_key", "")).strip_edges()
    if not api_key.is_empty():
        headers.append("Authorization: Bearer %s" % api_key)

    var fields := CCFTemplateService.generation_fields(template)
    var field_lines: Array[String] = []
    var existing_lines: Array[String] = []
    for field in fields:
        var field_id := str(field.get("id", "field"))
        var label := str(field.get("label", field_id))
        var field_type := str(field.get("type", "multiline"))
        field_lines.append("- %s: %s (%s)" % [field_id, label, field_type])
        if include_existing_fields:
            var current = CCFStorageService.get_value_at_path(project, str(field.get("path", "")), "")
            if current is Array:
                if not current.is_empty():
                    existing_lines.append("%s: %s" % [field_id, _join_values(current, ", ")])
            elif not str(current).strip_edges().is_empty():
                existing_lines.append("%s: %s" % [field_id, str(current)])

    var concept := str(CCFStorageService.get_value_at_path(project, "concept.prompt", "")).strip_edges()
    if concept.is_empty():
        return {"ok": false, "error": "Enter a generation concept before generating."}

    var global_rules: Array[String] = []
    for rule in template.get("global_generation_instructions", []):
        global_rules.append(str(rule))

    var user_prompt := "Create a complete roleplay character from the concept below.\n\nCONCEPT:\n%s\n\nRETURN THESE JSON KEYS:\n%s" % [concept, _join_values(field_lines, "\n")]
    if not existing_lines.is_empty():
        user_prompt += "\n\nEXISTING VALUES TO PRESERVE OR IMPROVE WHEN USEFUL:\n%s" % _join_values(existing_lines, "\n")
    user_prompt += "\n\nReturn one JSON object using exactly the requested keys. For tags, return an array of strings."

    var payload := {
        "model": model,
        "temperature": float(profile.get("temperature", 0.8)),
        "max_tokens": int(profile.get("max_output_tokens", 6000)),
        "messages": [
            {
                "role": "system",
                "content": "You are Character Card Forge, an expert character-card writing assistant. %s" % _join_values(global_rules, " ")
            },
            {"role": "user", "content": user_prompt}
        ]
    }

    var error := _request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
    if error != OK:
        return {"ok": false, "error": "Could not start API request (error %s)." % error}
    return {"ok": true}

func cancel_generation() -> void:
    if _request == null:
        return
    _cancelled = true
    _request.cancel_request()
    generation_cancelled.emit()

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if _cancelled:
        _cancelled = false
        return
    if result != HTTPRequest.RESULT_SUCCESS:
        generation_failed.emit("Network request failed (result %s)." % result)
        return

    var body_text := body.get_string_from_utf8()
    var parsed = JSON.parse_string(body_text)
    if not parsed is Dictionary:
        generation_failed.emit("The API returned an invalid JSON response.")
        return
    if response_code < 200 or response_code >= 300:
        var detail := body_text
        if parsed.has("error"):
            var api_error = parsed["error"]
            if api_error is Dictionary:
                detail = str(api_error.get("message", body_text))
            else:
                detail = str(api_error)
        generation_failed.emit("API error %s: %s" % [response_code, detail.left(800)])
        return

    var content := _extract_content(parsed)
    if content.is_empty():
        generation_failed.emit("The API response did not contain assistant text.")
        return

    var generated := _parse_generated_json(content)
    if generated.is_empty():
        generation_failed.emit("The model response could not be parsed as a character JSON object. The project was not changed.")
        return
    generation_completed.emit(generated)

func _extract_content(response: Dictionary) -> String:
    var choices = response.get("choices", [])
    if choices is Array and not choices.is_empty() and choices[0] is Dictionary:
        var first: Dictionary = choices[0]
        var message = first.get("message", {})
        if message is Dictionary:
            var content = message.get("content", "")
            if content is String:
                return content
            if content is Array:
                var parts: Array[String] = []
                for item in content:
                    if item is Dictionary and str(item.get("type", "")) == "text":
                        parts.append(str(item.get("text", "")))
                return _join_values(parts, "\n")
        if first.has("text"):
            return str(first.get("text", ""))
    return ""

func _parse_generated_json(text: String) -> Dictionary:
    var cleaned := text.strip_edges()
    if cleaned.begins_with("```"):
        var first_newline := cleaned.find("\n")
        if first_newline >= 0:
            cleaned = cleaned.substr(first_newline + 1)
        if cleaned.ends_with("```"):
            cleaned = cleaned.substr(0, cleaned.length() - 3).strip_edges()
    var parsed = JSON.parse_string(cleaned)
    if parsed is Dictionary:
        return parsed
    var start := cleaned.find("{")
    var finish := cleaned.rfind("}")
    if start >= 0 and finish > start:
        parsed = JSON.parse_string(cleaned.substr(start, finish - start + 1))
        if parsed is Dictionary:
            return parsed
    return {}

func _join_values(values: Array, separator: String) -> String:
    var result := ""
    for index in range(values.size()):
        if index > 0:
            result += separator
        result += str(values[index])
    return result

func _completion_url(base_url: String) -> String:
    var url := base_url.strip_edges().trim_suffix("/")
    if url.ends_with("/chat/completions"):
        return url
    return url + "/chat/completions"
