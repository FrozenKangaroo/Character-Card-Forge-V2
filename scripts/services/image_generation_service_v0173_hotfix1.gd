class_name CCFImageGenerationServiceV0173Hotfix1
extends "res://scripts/services/image_generation_service_v01610.gd"

var _last_request_route_v0173_hotfix1 := ""
var _last_transport_v0173_hotfix1 := ""


func openrouter_transport_capabilities_v0173_hotfix1() -> Dictionary:
	return {
		"version": "0.17.3-hotfix1",
		"openrouter_native_images": true,
		"generation_endpoint": "/api/v1/images",
		"image_models_endpoint": "/api/v1/images/models",
		"openai_images_generations_preserved": true,
		"response_b64_json_supported": true,
		"failure_route_visible": true
	}


func last_request_diagnostics_v0173_hotfix1() -> Dictionary:
	return {
		"transport": _last_transport_v0173_hotfix1,
		"request_route": _last_request_route_v0173_hotfix1,
		"model": _pending_model
	}


func _generation_url(base_url: String, backend: String) -> String:
	var operation := CCFImageInputAssetServiceV0168.normalise_operation(
		str(_pending_options.get("image_operation", OP_TEXT_TO_IMAGE))
	)
	var route := ""
	if (
		backend == PROVIDER_OPENAI_COMPATIBLE
		and operation == OP_TEXT_TO_IMAGE
		and CCFImageProviderTransportServiceV0173Hotfix1.is_openrouter_base_url(
			base_url
		)
	):
		route = CCFImageProviderTransportServiceV0173Hotfix1.openrouter_generation_url(
			base_url
		)
	else:
		route = super._generation_url(base_url, backend)
	_last_transport_v0173_hotfix1 = (
		CCFImageProviderTransportServiceV0173Hotfix1.transport_for_base_url(base_url)
		if backend == PROVIDER_OPENAI_COMPATIBLE
		else backend
	)
	_last_request_route_v0173_hotfix1 = (
		CCFImageProviderTransportServiceV0173Hotfix1.safe_request_url(route)
	)
	return route


func _fail(message_text: String) -> void:
	var detail := message_text
	if not _last_request_route_v0173_hotfix1.is_empty():
		detail += " Request route: %s. Transport: %s." % [
			_last_request_route_v0173_hotfix1,
			_last_transport_v0173_hotfix1
		]
	super._fail(detail)
