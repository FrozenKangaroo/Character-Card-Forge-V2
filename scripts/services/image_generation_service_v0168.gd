class_name CCFImageGenerationServiceV0168
extends "res://scripts/services/image_generation_service_v0164.gd"

const OP_TEXT_TO_IMAGE := CCFImageInputAssetServiceV0168.OP_TEXT_TO_IMAGE
const OP_IMAGE_TO_IMAGE := CCFImageInputAssetServiceV0168.OP_IMAGE_TO_IMAGE
const OP_INPAINTING := CCFImageInputAssetServiceV0168.OP_INPAINTING
const OP_REFERENCE_IMAGES := CCFImageInputAssetServiceV0168.OP_REFERENCE_IMAGES


func generate(
	project_id: String,
	character_id: String,
	profile: Dictionary,
	prompt_text: String,
	negative_prompt: String,
	image_size: String,
	prompt_style: String,
	model_override: String = "",
	options: Dictionary = {}
) -> Dictionary:
	var operation := CCFImageInputAssetServiceV0168.normalise_operation(
		str(options.get("image_operation", OP_TEXT_TO_IMAGE))
	)
	if operation != OP_TEXT_TO_IMAGE:
		var bundle_check := CCFImageInputAssetServiceV0168.validate_bundle(operation, options)
		if not bool(bundle_check.get("ok", false)):
			return bundle_check
		var backend := CCFSettingsService.image_backend(profile)
		if backend != CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111:
			var transport := CCFImageInputAssetServiceV0168.operation_transport(profile, operation)
			if transport.is_empty():
				return {
					"ok": false,
					"error": "%s is not execution-ready for this provider profile. Configure an explicit v0.16.8 image-input transport or choose a backend/profile that advertises one."
						% CCFImageInputAssetServiceV0168.operation_label(operation)
				}
	return super.generate(
		project_id,
		character_id,
		profile,
		prompt_text,
		negative_prompt,
		image_size,
		prompt_style,
		model_override,
		options
	)


func _normalise_generation_options(profile: Dictionary, overrides: Dictionary) -> Dictionary:
	var result := super._normalise_generation_options(profile, overrides)
	result["image_operation"] = CCFImageInputAssetServiceV0168.normalise_operation(
		str(overrides.get("image_operation", OP_TEXT_TO_IMAGE))
	)
	result["source_image_path"] = str(overrides.get("source_image_path", "")).strip_edges()
	result["mask_image_path"] = str(overrides.get("mask_image_path", "")).strip_edges()
	result["reference_image_paths"] = CCFImageInputAssetServiceV0168.normalise_paths(
		overrides.get("reference_image_paths", [])
	)
	result["denoise_strength"] = clampf(float(overrides.get("denoise_strength", 0.65)), 0.0, 1.0)
	result["mask_blur"] = clampi(int(overrides.get("mask_blur", 4)), 0, 64)
	return result


func _generation_url(base_url: String, backend: String) -> String:
	var operation := CCFImageInputAssetServiceV0168.normalise_operation(
		str(_pending_options.get("image_operation", OP_TEXT_TO_IMAGE))
	)
	if backend == PROVIDER_AUTOMATIC1111 and operation in [OP_IMAGE_TO_IMAGE, OP_INPAINTING]:
		return _a1111_endpoint(base_url, "img2img")
	if backend != PROVIDER_AUTOMATIC1111 and operation != OP_TEXT_TO_IMAGE:
		var transport := CCFImageInputAssetServiceV0168.operation_transport(_pending_profile, operation)
		var endpoint_suffix := str(transport.get("endpoint_suffix", "")).strip_edges()
		if not endpoint_suffix.is_empty():
			if endpoint_suffix.begins_with("http://") or endpoint_suffix.begins_with("https://"):
				return endpoint_suffix
			var clean_url := _trim_url(base_url)
			if not endpoint_suffix.begins_with("/"):
				endpoint_suffix = "/" + endpoint_suffix
			return clean_url + endpoint_suffix
	return super._generation_url(base_url, backend)


func _build_generation_payload() -> Dictionary:
	var payload := super._build_generation_payload()
	var operation := CCFImageInputAssetServiceV0168.normalise_operation(
		str(_pending_options.get("image_operation", OP_TEXT_TO_IMAGE))
	)
	if operation == OP_TEXT_TO_IMAGE:
		return payload
	if _pending_backend == PROVIDER_AUTOMATIC1111:
		var source := CCFImageInputAssetServiceV0168.encoded_image(
			str(_pending_options.get("source_image_path", ""))
		)
		if bool(source.get("ok", false)):
			payload["init_images"] = [str(source.get("base64", ""))]
		payload["denoising_strength"] = float(_pending_options.get("denoise_strength", 0.65))
		if operation == OP_INPAINTING:
			var mask := CCFImageInputAssetServiceV0168.encoded_image(
				str(_pending_options.get("mask_image_path", ""))
			)
			if bool(mask.get("ok", false)):
				payload["mask"] = str(mask.get("base64", ""))
			payload["mask_blur"] = int(_pending_options.get("mask_blur", 4))
			payload["inpainting_fill"] = 1
			payload["inpaint_full_res"] = true
		return payload
	return _apply_generic_image_transport_v0168(payload, operation)


func _apply_generic_image_transport_v0168(payload: Dictionary, operation: String) -> Dictionary:
	var result := payload.duplicate(true)
	var transport := CCFImageInputAssetServiceV0168.operation_transport(_pending_profile, operation)
	if transport.is_empty():
		return result
	var source_field := str(transport.get("source_field", "image")).strip_edges()
	var mask_field := str(transport.get("mask_field", "mask")).strip_edges()
	var references_field := str(transport.get("references_field", "reference_images")).strip_edges()
	var denoise_field := str(transport.get("denoise_field", "denoise")).strip_edges()
	if operation in [OP_IMAGE_TO_IMAGE, OP_INPAINTING]:
		var source := CCFImageInputAssetServiceV0168.encoded_image(
			str(_pending_options.get("source_image_path", ""))
		)
		if bool(source.get("ok", false)) and not source_field.is_empty():
			result[source_field] = str(source.get("base64", ""))
		if not denoise_field.is_empty():
			result[denoise_field] = float(_pending_options.get("denoise_strength", 0.65))
	if operation == OP_INPAINTING:
		var mask := CCFImageInputAssetServiceV0168.encoded_image(
			str(_pending_options.get("mask_image_path", ""))
		)
		if bool(mask.get("ok", false)) and not mask_field.is_empty():
			result[mask_field] = str(mask.get("base64", ""))
	if operation == OP_REFERENCE_IMAGES and not references_field.is_empty():
		var encoded_references: Array[String] = []
		for path_text in CCFImageInputAssetServiceV0168.normalise_paths(
			_pending_options.get("reference_image_paths", [])
		):
			var encoded := CCFImageInputAssetServiceV0168.encoded_image(path_text)
			if bool(encoded.get("ok", false)):
				encoded_references.append(str(encoded.get("base64", "")))
		result[references_field] = encoded_references
	return result


func _save_image(decoded_image: Image, batch_index: int, actual_seed: int) -> Dictionary:
	var record := super._save_image(decoded_image, batch_index, actual_seed)
	if record.is_empty():
		return record
	record["image_operation"] = CCFImageInputAssetServiceV0168.normalise_operation(
		str(_pending_options.get("image_operation", OP_TEXT_TO_IMAGE))
	)
	record["denoise_strength"] = float(_pending_options.get("denoise_strength", 0.65))
	record["mask_supplied"] = not str(_pending_options.get("mask_image_path", "")).strip_edges().is_empty()
	record["reference_image_count"] = CCFImageInputAssetServiceV0168.normalise_paths(
		_pending_options.get("reference_image_paths", [])
	).size()
	return record
