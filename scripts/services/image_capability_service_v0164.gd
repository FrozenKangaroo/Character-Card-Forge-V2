class_name CCFImageCapabilityServiceV0164
extends "res://scripts/services/image_capability_service.gd"

var _provider_endpoints_v0164: Array[String] = []
var _provider_endpoint_index_v0164 := 0


func fetch_capabilities(profile: Dictionary) -> Dictionary:
	if CCFSettingsService.image_backend(profile) == BACKEND_AUTOMATIC1111:
		return super.fetch_capabilities(profile)
	if _active:
		return {"ok": false, "error": "Image capability discovery is already running."}
	var base_url := str(profile.get("base_url", "")).strip_edges()
	_provider_endpoints_v0164 = CCFImageProviderModelCatalogServiceV0164.endpoint_candidates(base_url)
	if _provider_endpoints_v0164.is_empty():
		return {"ok": false, "error": "The selected image provider profile does not have a usable base URL."}
	_profile = profile.duplicate(true)
	_models.clear()
	_samplers.clear()
	_cancel_requested = false
	_active = true
	_stage = "v0164_provider_models"
	_provider_endpoint_index_v0164 = 0
	var start_result := _start_provider_endpoint_v0164()
	if start_result != OK:
		_reset_v0164()
		return {"ok": false, "error": "Could not start rich image model discovery (error %s)." % start_result}
	capabilities_started.emit()
	return {"ok": true}


func _on_request_completed(
	request_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if _stage != "v0164_provider_models":
		super._on_request_completed(request_result, response_code, _headers, body)
		return
	if not _active or _cancel_requested:
		return
	if request_result != HTTPRequest.RESULT_SUCCESS:
		if _try_next_provider_endpoint_v0164():
			return
		_fail_v0164("Image model discovery failed (result %s)." % request_result)
		return
	if response_code < 200 or response_code >= 300:
		if _try_next_provider_endpoint_v0164():
			return
		_fail_v0164("Image model discovery provider error %s: %s" % [response_code, _error_detail(body.get_string_from_utf8())])
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	var endpoint := _provider_endpoints_v0164[_provider_endpoint_index_v0164]
	var catalog_result := CCFImageProviderModelCatalogServiceV0164.parse_provider_response(parsed, endpoint)
	if not bool(catalog_result.get("ok", false)):
		if _try_next_provider_endpoint_v0164():
			return
		_fail_v0164(str(catalog_result.get("error", "Image model catalog could not be parsed.")))
		return
	var catalog := CCFImageProviderModelCatalogServiceV0164.with_fetch_metadata(catalog_result, endpoint)
	var capabilities := {
		"backend": BACKEND_OPENAI,
		"backend_label": "OpenAI-compatible Images API",
		"models": catalog.get("model_ids", []),
		"samplers": [],
		"model_records": catalog.get("records", []),
		"rich_model_catalog": catalog,
		"supports_negative_prompt": false,
		"supports_seed": false,
		"supports_sampler": false,
		"supports_steps": false,
		"supports_cfg_scale": false,
		"supports_batch": true,
		"discovery_note": (
			"Provider supplied rich image-model metadata."
			if bool(catalog.get("rich_metadata", false))
			else "Provider returned a model list without rich image capability metadata; unknown-safe defaults remain in effect."
		)
	}
	_reset_v0164()
	capabilities_loaded.emit(capabilities)


func _start_provider_endpoint_v0164() -> Error:
	if _provider_endpoint_index_v0164 < 0 or _provider_endpoint_index_v0164 >= _provider_endpoints_v0164.size():
		return ERR_INVALID_PARAMETER
	return _start_get(_provider_endpoints_v0164[_provider_endpoint_index_v0164])


func _try_next_provider_endpoint_v0164() -> bool:
	_provider_endpoint_index_v0164 += 1
	if _provider_endpoint_index_v0164 >= _provider_endpoints_v0164.size():
		return false
	var start_result := _start_provider_endpoint_v0164()
	if start_result == OK:
		return true
	return _try_next_provider_endpoint_v0164()


func _fail_v0164(message_text: String) -> void:
	_reset_v0164()
	capabilities_failed.emit(message_text)


func _reset_v0164() -> void:
	_active = false
	_cancel_requested = false
	_stage = ""
	_profile.clear()
	_models.clear()
	_samplers.clear()
	_provider_endpoints_v0164.clear()
	_provider_endpoint_index_v0164 = 0
