class_name CCFComfyUIGenerationProfileServiceV0166
extends RefCounted

const FORMAT_VERSION := 1
const PROFILE_KEY := "comfyui_generation_profiles_v0166"
const ACTIVE_PROFILE_KEY := "comfyui_active_generation_profile_v0166"

const INPUT_PROMPT := "prompt"
const INPUT_NEGATIVE_PROMPT := "negative_prompt"
const INPUT_SEED := "seed"
const INPUT_STEPS := "steps"
const INPUT_CFG := "cfg_scale"
const INPUT_WIDTH := "width"
const INPUT_HEIGHT := "height"
const INPUT_DENOISE := "denoise"
const INPUT_REFERENCE_IMAGE := "reference_image"

const STANDARD_INPUTS := [
	INPUT_PROMPT,
	INPUT_NEGATIVE_PROMPT,
	INPUT_SEED,
	INPUT_STEPS,
	INPUT_CFG,
	INPUT_WIDTH,
	INPUT_HEIGHT,
	INPUT_DENOISE,
	INPUT_REFERENCE_IMAGE
]


static func empty_profile(profile_id: String = "comfy_default") -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"id": profile_id,
		"name": "ComfyUI Workflow",
		"description": "",
		"workflow": {},
		"mappings": {},
		"output": {"node_id": "", "kind": "image"},
		"unknown_fields": {}
	}


static func normalise_profile(raw_value: Variant, profile_id: String = "") -> Dictionary:
	var source: Dictionary = raw_value if raw_value is Dictionary else {}
	var resolved_id := profile_id.strip_edges()
	if resolved_id.is_empty():
		resolved_id = str(source.get("id", "comfy_default")).strip_edges()
	if resolved_id.is_empty():
		resolved_id = "comfy_default"
	var result := empty_profile(resolved_id)
	result.merge(source, true)
	result["format_version"] = FORMAT_VERSION
	result["id"] = resolved_id
	result["name"] = str(result.get("name", "ComfyUI Workflow")).strip_edges()
	if str(result["name"]).is_empty():
		result["name"] = "ComfyUI Workflow"
	result["description"] = str(result.get("description", ""))
	result["workflow"] = (
		source.get("workflow", {}).duplicate(true)
		if source.get("workflow", {}) is Dictionary
		else {}
	)
	var mappings: Dictionary = {}
	if source.get("mappings", {}) is Dictionary:
		for raw_key in (source.get("mappings", {}) as Dictionary).keys():
			var key_text := str(raw_key).strip_edges()
			var mapping_value: Variant = (source.get("mappings", {}) as Dictionary).get(raw_key)
			if key_text.is_empty() or not mapping_value is Dictionary:
				continue
			var node_id := str(mapping_value.get("node_id", "")).strip_edges()
			var input_name := str(mapping_value.get("input", "")).strip_edges()
			if node_id.is_empty() or input_name.is_empty():
				continue
			mappings[key_text] = {
				"node_id": node_id,
				"input": input_name,
				"value_type": str(mapping_value.get("value_type", "auto")),
				"required": bool(mapping_value.get("required", false))
			}
	result["mappings"] = mappings
	result["output"] = (
		source.get("output", {}).duplicate(true)
		if source.get("output", {}) is Dictionary
		else {"node_id": "", "kind": "image"}
	)
	return result


static func profile_from_image_provider(image_profile: Dictionary, generation_profile_id: String = "") -> Dictionary:
	var stored: Variant = image_profile.get(PROFILE_KEY, {})
	if not stored is Dictionary:
		return empty_profile(generation_profile_id if not generation_profile_id.is_empty() else "comfy_default")
	var requested_id := generation_profile_id.strip_edges()
	if requested_id.is_empty():
		requested_id = str(image_profile.get(ACTIVE_PROFILE_KEY, "")).strip_edges()
	if requested_id.is_empty() and not stored.is_empty():
		requested_id = str(stored.keys()[0])
	var raw_value: Variant = stored.get(requested_id, {})
	if raw_value is Dictionary:
		return normalise_profile(raw_value, requested_id)
	return empty_profile(requested_id if not requested_id.is_empty() else "comfy_default")


static func store_profile(
	settings: Dictionary,
	image_profile_id: String,
	generation_profile_value: Dictionary
) -> Dictionary:
	var clean_image_profile_id := image_profile_id.strip_edges()
	if clean_image_profile_id.is_empty():
		return {"ok": false, "error": "No Image provider profile was selected."}
	var normalised := normalise_profile(generation_profile_value)
	var generation_profile_id := str(normalised.get("id", "")).strip_edges()
	if generation_profile_id.is_empty():
		return {"ok": false, "error": "The ComfyUI Generation Profile needs an ID."}
	var updated_settings := settings.duplicate(true)
	var image_profile := CCFSettingsService.image_profile_by_id(updated_settings, clean_image_profile_id).duplicate(true)
	if image_profile.is_empty():
		return {"ok": false, "error": "The selected Image provider profile no longer exists."}
	var stored_profiles: Dictionary = (
		image_profile.get(PROFILE_KEY, {}).duplicate(true)
		if image_profile.get(PROFILE_KEY, {}) is Dictionary
		else {}
	)
	stored_profiles[generation_profile_id] = normalised
	image_profile[PROFILE_KEY] = stored_profiles
	image_profile[ACTIVE_PROFILE_KEY] = generation_profile_id
	image_profile["comfyui_enabled_v0166"] = true
	CCFSettingsService.replace_image_profile_by_id(updated_settings, clean_image_profile_id, image_profile)
	var save_result := CCFSettingsService.save_settings(updated_settings)
	if not bool(save_result.get("ok", false)):
		return save_result
	return {
		"ok": true,
		"settings": CCFSettingsService.load_settings(),
		"generation_profile": normalised
	}


static func validate_profile(profile_value: Dictionary) -> Dictionary:
	var profile := normalise_profile(profile_value)
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var workflow: Dictionary = profile.get("workflow", {})
	if workflow.is_empty():
		errors.append("Workflow JSON is empty.")
	var mappings: Dictionary = profile.get("mappings", {})
	if not mappings.has(INPUT_PROMPT):
		errors.append("Prompt mapping is required.")
	for raw_key in mappings.keys():
		var key_text := str(raw_key)
		var mapping: Dictionary = mappings.get(raw_key, {})
		var node_id := str(mapping.get("node_id", ""))
		if not workflow.has(node_id):
			errors.append("Mapping '%s' targets missing workflow node '%s'." % [key_text, node_id])
			continue
		var node: Variant = workflow.get(node_id)
		if not node is Dictionary:
			errors.append("Workflow node '%s' is not an object." % node_id)
			continue
		var inputs: Variant = node.get("inputs", {})
		if not inputs is Dictionary:
			errors.append("Workflow node '%s' has no inputs object." % node_id)
			continue
		var input_name := str(mapping.get("input", ""))
		if not inputs.has(input_name):
			warnings.append("Mapping '%s' targets input '%s' which is not present in the saved workflow snapshot." % [key_text, input_name])
	var output: Dictionary = profile.get("output", {})
	var output_node := str(output.get("node_id", "")).strip_edges()
	if output_node.is_empty():
		warnings.append("No output node is mapped yet.")
	elif not workflow.has(output_node):
		errors.append("Output node '%s' is not present in the workflow." % output_node)
	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings}


static func materialise_workflow(profile_value: Dictionary, values: Dictionary) -> Dictionary:
	var profile := normalise_profile(profile_value)
	var validation := validate_profile(profile)
	if not bool(validation.get("ok", false)):
		return {"ok": false, "error": "ComfyUI Generation Profile is invalid.", "validation": validation}
	var workflow: Dictionary = (profile.get("workflow", {}) as Dictionary).duplicate(true)
	var mappings: Dictionary = profile.get("mappings", {})
	for raw_key in mappings.keys():
		var key_text := str(raw_key)
		if not values.has(key_text):
			continue
		var mapping: Dictionary = mappings.get(raw_key, {})
		var node_id := str(mapping.get("node_id", ""))
		var input_name := str(mapping.get("input", ""))
		var node: Dictionary = (workflow.get(node_id, {}) as Dictionary).duplicate(true)
		var inputs: Dictionary = (node.get("inputs", {}) as Dictionary).duplicate(true)
		inputs[input_name] = _coerce_value(values.get(key_text), str(mapping.get("value_type", "auto")))
		node["inputs"] = inputs
		workflow[node_id] = node
	return {
		"ok": true,
		"workflow": workflow,
		"output": (profile.get("output", {}) as Dictionary).duplicate(true),
		"profile_id": str(profile.get("id", "")),
		"validation": validation
	}


static func capability_document(profile_value: Dictionary) -> Dictionary:
	var profile := normalise_profile(profile_value)
	var mappings: Dictionary = profile.get("mappings", {})
	var result := {
		"format_version": CCFImageModelCapabilityServiceV0161.FORMAT_VERSION,
		"backend": "comfyui",
		"backend_label": "ComfyUI Workflow",
		"model_id": str(profile.get("id", "")),
		"model_name": str(profile.get("name", "ComfyUI Workflow")),
		"description": str(profile.get("description", "")),
		"operations": {},
		"parameters": {},
		"pricing": {},
		"content_flags": {},
		"discovery": {
			"source": CCFImageModelCapabilityServiceV0161.SOURCE_WORKFLOW,
			"confidence": CCFImageModelCapabilityServiceV0161.CONFIDENCE_KNOWN,
			"note": "Capabilities are derived from explicit ComfyUI Generation Profile mappings.",
			"discovered_at": ""
		},
		"has_user_overrides": false
	}
	var operation_state := CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED if mappings.has(INPUT_PROMPT) else CCFImageModelCapabilityServiceV0161.STATE_UNKNOWN
	(result["operations"] as Dictionary)["text_to_image"] = {
		"state": operation_state,
		"execution_ready": false,
		"source": CCFImageModelCapabilityServiceV0161.SOURCE_WORKFLOW,
		"confidence": CCFImageModelCapabilityServiceV0161.CONFIDENCE_KNOWN
	}
	for operation_name in ["image_to_image", "inpainting", "reference_images"]:
		(result["operations"] as Dictionary)[operation_name] = {
			"state": CCFImageModelCapabilityServiceV0161.STATE_UNKNOWN,
			"execution_ready": false,
			"source": CCFImageModelCapabilityServiceV0161.SOURCE_WORKFLOW,
			"confidence": CCFImageModelCapabilityServiceV0161.CONFIDENCE_INFERRED
		}
	var parameter_map := {
		INPUT_NEGATIVE_PROMPT: "text",
		INPUT_SEED: "integer",
		INPUT_STEPS: "integer",
		INPUT_CFG: "number",
		INPUT_WIDTH: "integer",
		INPUT_HEIGHT: "integer",
		INPUT_DENOISE: "number",
		INPUT_REFERENCE_IMAGE: "image"
	}
	for parameter_name in parameter_map.keys():
		(result["parameters"] as Dictionary)[parameter_name] = {
			"state": CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED if mappings.has(parameter_name) else CCFImageModelCapabilityServiceV0161.STATE_UNKNOWN,
			"value_type": str(parameter_map[parameter_name]),
			"values": [],
			"source": CCFImageModelCapabilityServiceV0161.SOURCE_WORKFLOW,
			"confidence": CCFImageModelCapabilityServiceV0161.CONFIDENCE_KNOWN
		}
	return result


static func _coerce_value(value: Variant, value_type: String) -> Variant:
	match value_type:
		"integer": return int(value)
		"number": return float(value)
		"boolean": return bool(value)
		"text": return str(value)
		_: return value
