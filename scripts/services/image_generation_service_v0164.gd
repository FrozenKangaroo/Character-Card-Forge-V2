class_name CCFImageGenerationServiceV0164
extends "res://scripts/services/image_generation_service_v01526.gd"


func _normalise_generation_options(profile: Dictionary, overrides: Dictionary) -> Dictionary:
	var result := super._normalise_generation_options(profile, overrides)
	var provider_parameters: Variant = overrides.get("provider_parameters", {})
	result["provider_parameters"] = (
		provider_parameters.duplicate(true) if provider_parameters is Dictionary else {}
	)
	return result


func _build_generation_payload() -> Dictionary:
	var payload := super._build_generation_payload()
	if _pending_backend != PROVIDER_OPENAI_COMPATIBLE:
		return payload
	var provider_parameters: Variant = _pending_options.get("provider_parameters", {})
	if not provider_parameters is Dictionary:
		return payload
	for raw_key in provider_parameters.keys():
		var key_text := str(raw_key).strip_edges()
		if key_text.is_empty() or key_text in ["model", "prompt", "n", "size"]:
			continue
		var value: Variant = provider_parameters.get(raw_key)
		if value == null:
			continue
		if value is String and str(value).strip_edges().is_empty():
			continue
		payload[key_text] = value
	return payload
