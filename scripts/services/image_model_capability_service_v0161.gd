class_name CCFImageModelCapabilityServiceV0161
extends RefCounted

const FORMAT_VERSION := 1

const STATE_SUPPORTED := "supported"
const STATE_UNSUPPORTED := "unsupported"
const STATE_UNKNOWN := "unknown"

const SOURCE_PROVIDER := "provider"
const SOURCE_BACKEND := "backend"
const SOURCE_MODEL_FAMILY := "model_family"
const SOURCE_WORKFLOW := "workflow"
const SOURCE_INFERRED := "inferred"
const SOURCE_USER_OVERRIDE := "user_override"

const CONFIDENCE_AUTHORITATIVE := "authoritative"
const CONFIDENCE_KNOWN := "known"
const CONFIDENCE_INFERRED := "inferred"
const CONFIDENCE_USER_DEFINED := "user_defined"

const BACKEND_OPENAI := CCFSettingsService.IMAGE_BACKEND_OPENAI
const BACKEND_AUTOMATIC1111 := CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111


static func normalise_discovery(
	profile: Dictionary,
	raw_capabilities: Dictionary,
	model_id: String = ""
) -> Dictionary:
	var backend := CCFSettingsService.image_backend(profile)
	var selected_model := model_id.strip_edges()
	if selected_model.is_empty():
		selected_model = str(profile.get("model", "")).strip_edges()
	var result := _empty_document(backend, selected_model)
	result["backend_label"] = str(
		raw_capabilities.get("backend_label", _backend_label(backend))
	).strip_edges()
	result["models"] = _model_descriptors_from_legacy(raw_capabilities.get("models", []))
	result["discovery"] = {
		"source": SOURCE_BACKEND,
		"confidence": CONFIDENCE_KNOWN,
		"note": str(raw_capabilities.get("discovery_note", "")).strip_edges(),
		"discovered_at": str(raw_capabilities.get("discovered_at", "")).strip_edges()
	}

	if backend == BACKEND_AUTOMATIC1111:
		_set_operation(result, "text_to_image", STATE_SUPPORTED, true, SOURCE_BACKEND, CONFIDENCE_KNOWN)
		# Forge/A1111 exposes img2img at backend level, but Image Studio execution
		# is intentionally deferred until the dedicated v0.16.x img2img phase.
		_set_operation(result, "image_to_image", STATE_SUPPORTED, false, SOURCE_BACKEND, CONFIDENCE_KNOWN)
		_set_operation(result, "inpainting", STATE_UNKNOWN, false, SOURCE_BACKEND, CONFIDENCE_INFERRED)
		_set_operation(result, "reference_images", STATE_UNKNOWN, false, SOURCE_BACKEND, CONFIDENCE_INFERRED)
		_set_parameter(result, "resolution", STATE_SUPPORTED, "freeform", [], SOURCE_BACKEND, CONFIDENCE_KNOWN)
		_set_parameter(result, "image_count", _state_from_bool(raw_capabilities.get("supports_batch", true)), "integer", [], SOURCE_BACKEND, CONFIDENCE_KNOWN)
		_set_parameter(result, "negative_prompt", _state_from_bool(raw_capabilities.get("supports_negative_prompt", true)), "text", [], SOURCE_BACKEND, CONFIDENCE_KNOWN)
		_set_parameter(result, "seed", _state_from_bool(raw_capabilities.get("supports_seed", true)), "integer", [], SOURCE_BACKEND, CONFIDENCE_KNOWN)
		_set_parameter(result, "sampler", _state_from_bool(raw_capabilities.get("supports_sampler", true)), "choice", raw_capabilities.get("samplers", []), SOURCE_BACKEND, CONFIDENCE_KNOWN)
		_set_parameter(result, "steps", _state_from_bool(raw_capabilities.get("supports_steps", true)), "integer", [], SOURCE_BACKEND, CONFIDENCE_KNOWN)
		_set_parameter(result, "cfg_scale", _state_from_bool(raw_capabilities.get("supports_cfg_scale", true)), "number", [], SOURCE_BACKEND, CONFIDENCE_KNOWN)
	else:
		_set_operation(result, "text_to_image", STATE_SUPPORTED, true, SOURCE_INFERRED, CONFIDENCE_INFERRED)
		_set_operation(result, "image_to_image", STATE_UNKNOWN, false, SOURCE_INFERRED, CONFIDENCE_INFERRED)
		_set_operation(result, "inpainting", STATE_UNKNOWN, false, SOURCE_INFERRED, CONFIDENCE_INFERRED)
		_set_operation(result, "reference_images", STATE_UNKNOWN, false, SOURCE_INFERRED, CONFIDENCE_INFERRED)
		# Generic OpenAI-compatible image APIs vary heavily. Keep uncertain
		# technical parameters unknown instead of silently claiming support.
		_set_parameter(result, "resolution", STATE_UNKNOWN, "freeform", [], SOURCE_INFERRED, CONFIDENCE_INFERRED)
		_set_parameter(result, "image_count", _state_from_bool(raw_capabilities.get("supports_batch", true)), "integer", [], SOURCE_INFERRED, CONFIDENCE_INFERRED)
		_set_parameter(result, "negative_prompt", STATE_UNSUPPORTED, "text", [], SOURCE_INFERRED, CONFIDENCE_INFERRED)
		_set_parameter(result, "seed", STATE_UNKNOWN, "integer", [], SOURCE_INFERRED, CONFIDENCE_INFERRED)
		_set_parameter(result, "sampler", STATE_UNKNOWN, "choice", [], SOURCE_INFERRED, CONFIDENCE_INFERRED)
		_set_parameter(result, "steps", STATE_UNKNOWN, "integer", [], SOURCE_INFERRED, CONFIDENCE_INFERRED)
		_set_parameter(result, "cfg_scale", STATE_UNKNOWN, "number", [], SOURCE_INFERRED, CONFIDENCE_INFERRED)

	result["legacy_discovery"] = raw_capabilities.duplicate(true)
	return result


static func normalise_provider_model_record(
	profile: Dictionary,
	model_record: Dictionary
) -> Dictionary:
	var backend := CCFSettingsService.image_backend(profile)
	var model_id := str(model_record.get("id", "")).strip_edges()
	var result := _empty_document(backend, model_id)
	result["model_name"] = str(model_record.get("name", model_id)).strip_edges()
	result["description"] = str(model_record.get("description", "")).strip_edges()
	result["owner"] = str(model_record.get("owned_by", "")).strip_edges()
	result["tags"] = _normalise_string_array(model_record.get("tags", []), false)
	result["pricing"] = (
		model_record.get("pricing", {}).duplicate(true)
		if model_record.get("pricing", {}) is Dictionary
		else {}
	)
	result["discovery"] = {
		"source": SOURCE_PROVIDER,
		"confidence": CONFIDENCE_AUTHORITATIVE,
		"note": "Model capabilities supplied by the provider.",
		"discovered_at": ""
	}

	var capabilities: Dictionary = (
		model_record.get("capabilities", {})
		if model_record.get("capabilities", {}) is Dictionary
		else {}
	)
	_set_operation_from_provider_flag(result, "text_to_image", capabilities, "image_generation", true)
	_set_operation_from_provider_flag(result, "image_to_image", capabilities, "image_to_image", false)
	_set_operation_from_provider_flag(result, "inpainting", capabilities, "inpainting", false)
	var reference_state := STATE_UNKNOWN
	for key_text in ["reference_images", "image_reference", "input_images"]:
		if capabilities.has(key_text):
			reference_state = _state_from_bool(capabilities.get(key_text, false))
			break
	_set_operation(result, "reference_images", reference_state, false, SOURCE_PROVIDER, CONFIDENCE_AUTHORITATIVE)
	result["content_flags"] = {
		"nsfw": capabilities.get("nsfw", null)
	}

	var supported_parameters: Dictionary = (
		model_record.get("supported_parameters", {})
		if model_record.get("supported_parameters", {}) is Dictionary
		else {}
	)
	for raw_key in supported_parameters.keys():
		var key_text := str(raw_key)
		var raw_value: Variant = supported_parameters.get(raw_key)
		var descriptor := _descriptor_for_provider_parameter(key_text, raw_value)
		(result["parameters"] as Dictionary)[key_text] = descriptor

	# Common aliases also get stable CCF names so the UI can use polished
	# controls without losing the provider's original additive fields.
	if supported_parameters.has("resolutions"):
		_set_parameter(result, "resolution", STATE_SUPPORTED, "choice", supported_parameters.get("resolutions", []), SOURCE_PROVIDER, CONFIDENCE_AUTHORITATIVE)
	if supported_parameters.has("max_images"):
		var image_count := _descriptor_for_provider_parameter("image_count", supported_parameters.get("max_images"))
		image_count["maximum"] = int(supported_parameters.get("max_images", 1))
		(result["parameters"] as Dictionary)["image_count"] = image_count
	if supported_parameters.has("fixed_image_count"):
		var fixed_count := _descriptor_for_provider_parameter("image_count", supported_parameters.get("fixed_image_count"))
		fixed_count["fixed"] = true
		fixed_count["default"] = int(supported_parameters.get("fixed_image_count", 1))
		(result["parameters"] as Dictionary)["image_count"] = fixed_count
	if supported_parameters.has("rendering_speed"):
		_set_parameter(result, "rendering_speed", STATE_SUPPORTED, "choice", supported_parameters.get("rendering_speed", []), SOURCE_PROVIDER, CONFIDENCE_AUTHORITATIVE)

	result["provider_record"] = model_record.duplicate(true)
	return result


static func apply_user_overrides(
	capability_document: Dictionary,
	overrides: Dictionary
) -> Dictionary:
	var result := capability_document.duplicate(true)
	var operation_overrides: Dictionary = (
		overrides.get("operations", {}) if overrides.get("operations", {}) is Dictionary else {}
	)
	for raw_key in operation_overrides.keys():
		var key_text := str(raw_key)
		var raw_override: Variant = operation_overrides.get(raw_key)
		if raw_override is bool:
			_set_operation(result, key_text, _state_from_bool(raw_override), bool(raw_override), SOURCE_USER_OVERRIDE, CONFIDENCE_USER_DEFINED)
		elif raw_override is Dictionary:
			_set_operation(
				result,
				key_text,
				_normalise_state(str(raw_override.get("state", STATE_UNKNOWN))),
				bool(raw_override.get("execution_ready", false)),
				SOURCE_USER_OVERRIDE,
				CONFIDENCE_USER_DEFINED
			)

	var parameter_overrides: Dictionary = (
		overrides.get("parameters", {}) if overrides.get("parameters", {}) is Dictionary else {}
	)
	for raw_key in parameter_overrides.keys():
		var key_text := str(raw_key)
		var raw_override: Variant = parameter_overrides.get(raw_key)
		if raw_override is bool:
			_set_parameter(result, key_text, _state_from_bool(raw_override), "unknown", [], SOURCE_USER_OVERRIDE, CONFIDENCE_USER_DEFINED)
		elif raw_override is Dictionary:
			var existing: Dictionary = (result.get("parameters", {}) as Dictionary).get(key_text, {})
			var descriptor := existing.duplicate(true)
			descriptor.merge(raw_override, true)
			descriptor["state"] = _normalise_state(str(descriptor.get("state", STATE_UNKNOWN)))
			descriptor["source"] = SOURCE_USER_OVERRIDE
			descriptor["confidence"] = CONFIDENCE_USER_DEFINED
			(result["parameters"] as Dictionary)[key_text] = descriptor
	result["has_user_overrides"] = not operation_overrides.is_empty() or not parameter_overrides.is_empty()
	return result


static func operation_state(capability_document: Dictionary, operation_name: String) -> String:
	var operations: Dictionary = (
		capability_document.get("operations", {})
		if capability_document.get("operations", {}) is Dictionary
		else {}
	)
	var descriptor: Dictionary = operations.get(operation_name, {})
	return _normalise_state(str(descriptor.get("state", STATE_UNKNOWN)))


static func parameter_state(capability_document: Dictionary, parameter_name: String) -> String:
	var parameters: Dictionary = (
		capability_document.get("parameters", {})
		if capability_document.get("parameters", {}) is Dictionary
		else {}
	)
	var descriptor: Dictionary = parameters.get(parameter_name, {})
	return _normalise_state(str(descriptor.get("state", STATE_UNKNOWN)))


static func execution_ready(capability_document: Dictionary, operation_name: String) -> bool:
	var operations: Dictionary = (
		capability_document.get("operations", {})
		if capability_document.get("operations", {}) is Dictionary
		else {}
	)
	var descriptor: Dictionary = operations.get(operation_name, {})
	return bool(descriptor.get("execution_ready", false))


static func summary(capability_document: Dictionary) -> String:
	var source: Dictionary = (
		capability_document.get("discovery", {})
		if capability_document.get("discovery", {}) is Dictionary
		else {}
	)
	var parts: Array[String] = []
	parts.append("Capabilities: %s" % str(source.get("source", SOURCE_INFERRED)).replace("_", " ").capitalize())
	var operation_labels := {
		"text_to_image": "Text→Image",
		"image_to_image": "Image→Image",
		"inpainting": "Inpaint",
		"reference_images": "Reference"
	}
	for operation_name in ["text_to_image", "image_to_image", "inpainting", "reference_images"]:
		var state := operation_state(capability_document, operation_name)
		var symbol := "?"
		if state == STATE_SUPPORTED:
			symbol = "✓"
		elif state == STATE_UNSUPPORTED:
			symbol = "—"
		var label := str(operation_labels.get(operation_name, operation_name))
		if state == STATE_SUPPORTED and not execution_ready(capability_document, operation_name):
			parts.append("%s %s (planned)" % [symbol, label])
		else:
			parts.append("%s %s" % [symbol, label])
	return "  ·  ".join(parts)


static func _empty_document(backend: String, model_id: String) -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"backend": backend,
		"backend_label": _backend_label(backend),
		"model_id": model_id,
		"model_name": model_id,
		"description": "",
		"owner": "",
		"tags": [],
		"models": [],
		"operations": {},
		"parameters": {},
		"pricing": {},
		"content_flags": {},
		"discovery": {
			"source": SOURCE_INFERRED,
			"confidence": CONFIDENCE_INFERRED,
			"note": "",
			"discovered_at": ""
		},
		"has_user_overrides": false
	}


static func _set_operation(
	document: Dictionary,
	name: String,
	state: String,
	execution_is_ready: bool,
	source: String,
	confidence: String
) -> void:
	(document["operations"] as Dictionary)[name] = {
		"state": _normalise_state(state),
		"execution_ready": execution_is_ready,
		"source": source,
		"confidence": confidence
	}


static func _set_operation_from_provider_flag(
	document: Dictionary,
	operation_name: String,
	capabilities: Dictionary,
	provider_key: String,
	execution_is_ready: bool
) -> void:
	var state := STATE_UNKNOWN
	if capabilities.has(provider_key):
		state = _state_from_bool(capabilities.get(provider_key, false))
	_set_operation(document, operation_name, state, execution_is_ready and state == STATE_SUPPORTED, SOURCE_PROVIDER, CONFIDENCE_AUTHORITATIVE)


static func _set_parameter(
	document: Dictionary,
	name: String,
	state: String,
	value_type: String,
	values: Variant,
	source: String,
	confidence: String
) -> void:
	(document["parameters"] as Dictionary)[name] = {
		"state": _normalise_state(state),
		"value_type": value_type,
		"values": _normalise_variant_array(values),
		"source": source,
		"confidence": confidence
	}


static func _descriptor_for_provider_parameter(key_text: String, raw_value: Variant) -> Dictionary:
	var value_type := "unknown"
	var values: Array = []
	var default_value: Variant = null
	if raw_value is Array:
		value_type = "choice"
		values = _normalise_variant_array(raw_value)
	elif raw_value is bool:
		value_type = "boolean"
		default_value = raw_value
	elif raw_value is int:
		value_type = "integer"
		default_value = raw_value
	elif raw_value is float:
		value_type = "number"
		default_value = raw_value
	elif raw_value is String:
		value_type = "text"
		default_value = raw_value
	return {
		"state": STATE_SUPPORTED,
		"value_type": value_type,
		"values": values,
		"default": default_value,
		"provider_key": key_text,
		"source": SOURCE_PROVIDER,
		"confidence": CONFIDENCE_AUTHORITATIVE
	}


static func _model_descriptors_from_legacy(raw_models: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not raw_models is Array:
		return result
	for raw_model in raw_models:
		var model_id := str(raw_model).strip_edges()
		if model_id.is_empty():
			continue
		result.append({"id": model_id, "name": model_id})
	return result


static func _normalise_state(state: String) -> String:
	var clean_state := state.strip_edges().to_lower()
	if clean_state in [STATE_SUPPORTED, STATE_UNSUPPORTED, STATE_UNKNOWN]:
		return clean_state
	return STATE_UNKNOWN


static func _state_from_bool(raw_value: Variant) -> String:
	return STATE_SUPPORTED if bool(raw_value) else STATE_UNSUPPORTED


static func _normalise_string_array(raw_value: Variant, sort_values: bool = true) -> Array[String]:
	var result: Array[String] = []
	if not raw_value is Array:
		return result
	for raw_entry in raw_value:
		var entry := str(raw_entry).strip_edges()
		if not entry.is_empty() and entry not in result:
			result.append(entry)
	if sort_values:
		result.sort()
	return result


static func _normalise_variant_array(raw_value: Variant) -> Array:
	var result: Array = []
	if not raw_value is Array:
		return result
	for entry in raw_value:
		if entry not in result:
			result.append(entry)
	return result


static func _backend_label(backend: String) -> String:
	if backend == BACKEND_AUTOMATIC1111:
		return "Stable Diffusion Forge / Automatic1111"
	return "OpenAI-compatible Images API"
