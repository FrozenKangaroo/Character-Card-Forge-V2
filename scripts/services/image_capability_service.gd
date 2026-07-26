class_name CCFImageCapabilityService
extends Node

signal capabilities_started
signal capabilities_loaded(capabilities: Dictionary)
signal capabilities_failed(message: String)
signal capabilities_cancelled

const BACKEND_OPENAI := CCFSettingsService.IMAGE_BACKEND_OPENAI
const BACKEND_AUTOMATIC1111 := CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111

var _request: HTTPRequest
var _active := false
var _cancel_requested := false
var _stage := ""
var _profile: Dictionary = {}
var _models: Array[String] = []
var _samplers: Array[String] = []


func _ready() -> void:
	_create_request()


func fetch_capabilities(profile: Dictionary) -> Dictionary:
	if _active:
		return {"ok": false, "error": "Image capability discovery is already running."}
	var base_url := str(profile.get("base_url", "")).strip_edges()
	if base_url.is_empty():
		return {"ok": false, "error": "The selected image provider profile does not have a base URL."}
	_profile = profile.duplicate(true)
	_models.clear()
	_samplers.clear()
	_cancel_requested = false
	_active = true
	var backend := CCFSettingsService.image_backend(profile)
	if backend == BACKEND_AUTOMATIC1111:
		_stage = "a1111_models"
		var start_result := _start_get(_a1111_endpoint(base_url, "sd-models"))
		if start_result != OK:
			_reset()
			return {"ok": false, "error": "Could not start Stable Diffusion model discovery (error %s)." % start_result}
	else:
		_stage = "openai_models"
		var start_result := _start_get(_openai_models_url(base_url))
		if start_result != OK:
			_reset()
			return {"ok": false, "error": "Could not start image model discovery (error %s)." % start_result}
	capabilities_started.emit()
	return {"ok": true}


func cancel() -> void:
	if not _active or _request == null:
		return
	_cancel_requested = true
	_request.cancel_request()
	_reset()
	_create_request()
	capabilities_cancelled.emit()


func is_active() -> bool:
	return _active


func _create_request() -> void:
	if _request != null:
		if _request.request_completed.is_connected(_on_request_completed):
			_request.request_completed.disconnect(_on_request_completed)
		if _request.get_parent() == self:
			remove_child(_request)
		_request.queue_free()
	_request = HTTPRequest.new()
	_request.timeout = 30.0
	add_child(_request)
	_request.request_completed.connect(_on_request_completed)


func _start_get(request_url: String) -> Error:
	return _request.request(
		request_url,
		_request_headers(_profile),
		HTTPClient.METHOD_GET
	)


func _on_request_completed(
	request_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if not _active or _cancel_requested:
		return
	if request_result != HTTPRequest.RESULT_SUCCESS:
		_fail("Image capability request failed (result %s)." % request_result)
		return
	if response_code < 200 or response_code >= 300:
		_fail("Image capability provider error %s: %s" % [response_code, _error_detail(body.get_string_from_utf8())])
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	match _stage:
		"openai_models":
			if not parsed is Dictionary:
				_fail("The OpenAI-compatible /models response was not a JSON object.")
				return
			_models = _extract_openai_models(parsed)
			_finish_openai()
		"a1111_models":
			if not parsed is Array:
				_fail("The Stable Diffusion /sd-models response was not a JSON array.")
				return
			_models = _extract_a1111_models(parsed)
			_stage = "a1111_samplers"
			var sampler_error := _start_get(
				_a1111_endpoint(str(_profile.get("base_url", "")), "samplers")
			)
			if sampler_error != OK:
				_fail("Models were discovered, but sampler discovery could not start (error %s)." % sampler_error)
		"a1111_samplers":
			if parsed is Array:
				_samplers = _extract_a1111_samplers(parsed)
			_finish_a1111()
		_:
			_fail("Image capability discovery reached an unknown request stage.")


func _finish_openai() -> void:
	var capabilities := {
		"backend": BACKEND_OPENAI,
		"backend_label": "OpenAI-compatible Images API",
		"models": _models.duplicate(),
		"samplers": [],
		"supports_negative_prompt": false,
		"supports_seed": false,
		"supports_sampler": false,
		"supports_steps": false,
		"supports_cfg_scale": false,
		"supports_batch": true,
		"discovery_note": "The provider exposed /models. OpenAI-compatible model listings do not reliably identify which entries support image generation."
	}
	_reset()
	capabilities_loaded.emit(capabilities)


func _finish_a1111() -> void:
	var capabilities := {
		"backend": BACKEND_AUTOMATIC1111,
		"backend_label": "Stable Diffusion Forge / Automatic1111",
		"models": _models.duplicate(),
		"samplers": _samplers.duplicate(),
		"supports_negative_prompt": true,
		"supports_seed": true,
		"supports_sampler": true,
		"supports_steps": true,
		"supports_cfg_scale": true,
		"supports_batch": true,
		"discovery_note": "Models and samplers were read from the Stable Diffusion WebUI API."
	}
	_reset()
	capabilities_loaded.emit(capabilities)


func _extract_openai_models(response: Dictionary) -> Array[String]:
	var found: Array[String] = []
	var data_value = response.get("data", [])
	if not data_value is Array:
		return found
	for raw_model in data_value:
		if not raw_model is Dictionary:
			continue
		var model_id := str(raw_model.get("id", "")).strip_edges()
		if not model_id.is_empty() and model_id not in found:
			found.append(model_id)
	found.sort()
	return found


func _extract_a1111_models(response: Array) -> Array[String]:
	var found: Array[String] = []
	for raw_model in response:
		if not raw_model is Dictionary:
			continue
		var model_title := str(raw_model.get("title", "")).strip_edges()
		if model_title.is_empty():
			model_title = str(raw_model.get("model_name", "")).strip_edges()
		if not model_title.is_empty() and model_title not in found:
			found.append(model_title)
	found.sort()
	return found


func _extract_a1111_samplers(response: Array) -> Array[String]:
	var found: Array[String] = []
	for raw_sampler in response:
		if not raw_sampler is Dictionary:
			continue
		var sampler_name := str(raw_sampler.get("name", "")).strip_edges()
		if not sampler_name.is_empty() and sampler_name not in found:
			found.append(sampler_name)
	found.sort()
	return found


func _request_headers(profile: Dictionary) -> PackedStringArray:
	var headers := PackedStringArray(["Accept: application/json"])
	var api_key := str(profile.get("api_key", "")).strip_edges()
	if not api_key.is_empty():
		headers.append("Authorization: Bearer %s" % api_key)
	return headers


func _openai_models_url(base_url: String) -> String:
	var clean_url := _trim_url(base_url)
	if clean_url.ends_with("/images/generations"):
		clean_url = clean_url.trim_suffix("/images/generations")
	if clean_url.ends_with("/models"):
		return clean_url
	return clean_url + "/models"


func _a1111_endpoint(base_url: String, endpoint_name: String) -> String:
	var clean_url := _trim_url(base_url)
	if clean_url.ends_with("/sdapi/v1"):
		return clean_url + "/" + endpoint_name
	if clean_url.contains("/sdapi/v1/"):
		var api_index := clean_url.find("/sdapi/v1/")
		clean_url = clean_url.left(api_index + "/sdapi/v1".length())
		return clean_url + "/" + endpoint_name
	return clean_url + "/sdapi/v1/" + endpoint_name


func _trim_url(base_url: String) -> String:
	var clean_url := base_url.strip_edges()
	while clean_url.ends_with("/"):
		clean_url = clean_url.left(clean_url.length() - 1)
	return clean_url


func _error_detail(response_text: String) -> String:
	var parsed = JSON.parse_string(response_text)
	if parsed is Dictionary:
		var error_value = parsed.get("error", {})
		if error_value is Dictionary:
			var message_text := str(error_value.get("message", "")).strip_edges()
			if not message_text.is_empty():
				return message_text.left(1200)
		var detail := str(parsed.get("detail", "")).strip_edges()
		if not detail.is_empty():
			return detail.left(1200)
	return response_text.strip_edges().left(1200)


func _fail(message_text: String) -> void:
	_reset()
	capabilities_failed.emit(message_text)


func _reset() -> void:
	_active = false
	_cancel_requested = false
	_stage = ""
	_profile.clear()
	_models.clear()
	_samplers.clear()
