class_name CCFModelService
extends Node

signal models_loaded(models: Array)
signal models_failed(message: String)

var _request: HTTPRequest
var _busy := false

func _ready() -> void:
    _request = HTTPRequest.new()
    _request.timeout = 60.0
    add_child(_request)
    _request.request_completed.connect(_on_request_completed)

func fetch_models(profile: Dictionary) -> Dictionary:
    if _busy:
        return {"ok": false, "error": "A model-list request is already running."}
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
        return {"ok": false, "error": "Could not start model-list request (error %s)." % request_error}
    return {"ok": true}

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    _busy = false
    if result != HTTPRequest.RESULT_SUCCESS:
        models_failed.emit("Model request failed (result %s)." % result)
        return

    var body_text := body.get_string_from_utf8()
    var parsed = JSON.parse_string(body_text)
    if response_code < 200 or response_code >= 300:
        var detail := body_text
        if parsed is Dictionary and parsed.has("error"):
            var api_error = parsed.get("error")
            if api_error is Dictionary:
                detail = str(api_error.get("message", body_text))
            else:
                detail = str(api_error)
        models_failed.emit("API error %s while fetching models: %s" % [response_code, detail.left(800)])
        return
    if not parsed is Dictionary:
        models_failed.emit("The model endpoint returned invalid JSON.")
        return

    var model_ids: Array[String] = []
    var data = parsed.get("data", [])
    if data is Array:
        for entry in data:
            if entry is Dictionary:
                var model_id := str(entry.get("id", "")).strip_edges()
                if not model_id.is_empty() and not model_ids.has(model_id):
                    model_ids.append(model_id)
            elif not str(entry).strip_edges().is_empty():
                var model_id := str(entry).strip_edges()
                if not model_ids.has(model_id):
                    model_ids.append(model_id)
    model_ids.sort()
    if model_ids.is_empty():
        models_failed.emit("The model endpoint returned no model IDs.")
        return
    models_loaded.emit(model_ids)

func _models_url(base_url: String) -> String:
    var url := base_url.strip_edges().trim_suffix("/")
    if url.ends_with("/chat/completions"):
        url = url.trim_suffix("/chat/completions")
    if url.ends_with("/models"):
        return url
    return url + "/models"
