class_name CCFImageResultWorkflowServiceV01610
extends RefCounted

const SNAPSHOT_FORMAT_VERSION := 1


static func execution_snapshot(
	profile: Dictionary,
	model: String,
	size: String,
	prompt_style: String,
	prompt: String,
	negative_prompt: String,
	options: Dictionary
) -> Dictionary:
	return {
		"format_version": SNAPSHOT_FORMAT_VERSION,
		"profile_id": str(profile.get("id", "default")),
		"profile_name": str(profile.get("name", "Image provider")),
		"backend": CCFImageGenerationService.backend_for_profile(profile),
		"model": model,
		"size": size,
		"prompt_style": prompt_style,
		"composed_prompt": prompt,
		"negative_prompt": negative_prompt,
		"sampler": str(options.get("sampler", "")),
		"steps": int(options.get("steps", 28)),
		"cfg_scale": float(options.get("cfg_scale", 7.0)),
		"seed": int(options.get("seed", -1)),
		"batch_size": int(options.get("batch_size", 1)),
		"provider_parameters": _dictionary_copy(options.get("provider_parameters", {})),
		"image_operation": str(options.get("image_operation", "text_to_image")),
		"source_image_path": str(options.get("source_image_path", "")),
		"source_image_id": str(options.get("source_image_id", "")),
		"mask_image_path": str(options.get("mask_image_path", "")),
		"reference_image_paths": _string_array(options.get("reference_image_paths", [])),
		"denoise_strength": float(options.get("denoise_strength", 0.65)),
		"mask_blur": int(options.get("mask_blur", 4))
	}


static func snapshot_from_record(record: Dictionary) -> Dictionary:
	var stored: Variant = record.get("execution_snapshot_v01610", {})
	if stored is Dictionary and not stored.is_empty():
		return stored.duplicate(true)
	return {
		"format_version": 0,
		"profile_id": str(record.get("profile_id", "")),
		"profile_name": str(record.get("profile_name", "")),
		"backend": str(record.get("backend", record.get("provider", ""))),
		"model": str(record.get("model", "")),
		"size": str(record.get("size", "")),
		"prompt_style": str(record.get("prompt_style", "auto")),
		"composed_prompt": str(record.get("prompt", "")),
		"negative_prompt": str(record.get("negative_prompt", "")),
		"sampler": str(record.get("sampler", "")),
		"steps": int(record.get("steps", 28)),
		"cfg_scale": float(record.get("cfg_scale", 7.0)),
		"seed": int(record.get("seed", -1)),
		"batch_size": int(record.get("batch_size", 1)),
		"provider_parameters": _dictionary_copy(record.get("provider_parameters", {})),
		"image_operation": str(record.get("image_operation", "text_to_image")),
		"source_image_path": "",
		"source_image_id": str(record.get("source_image_id", "")),
		"mask_image_path": "",
		"reference_image_paths": [],
		"denoise_strength": float(record.get("denoise_strength", 0.65)),
		"mask_blur": int(record.get("mask_blur", 4))
	}


static func with_favourite(record: Dictionary, favourite: bool) -> Dictionary:
	var result := record.duplicate(true)
	result["favourite_v01610"] = favourite
	return result


static func is_favourite(record: Dictionary) -> bool:
	return bool(record.get("favourite_v01610", false))


static func estimate_cost(pricing: Dictionary, image_count: int) -> Dictionary:
	if pricing.is_empty():
		return {"available": false}
	var amount_value: Variant = null
	var basis := ""
	for key in ["cost_per_image", "price_per_image", "per_image"]:
		if pricing.has(key) and (pricing[key] is float or pricing[key] is int):
			amount_value = pricing[key]
			basis = key
			break
	if amount_value == null:
		return {"available": false}
	var count := maxi(1, image_count)
	return {
		"available": true,
		"amount": float(amount_value) * count,
		"currency": str(pricing.get("currency", "USD")).to_upper(),
		"image_count": count,
		"basis": basis
	}


static func cost_label(estimate: Dictionary) -> String:
	if not bool(estimate.get("available", false)):
		return "Cost estimate unavailable — local and providers without explicit per-image pricing remain fully supported."
	return "Estimated provider cost: %s %.4f for %d image(s)" % [
		str(estimate.get("currency", "USD")),
		float(estimate.get("amount", 0.0)),
		int(estimate.get("image_count", 1))
	]


static func comparison_text(left: Dictionary, right: Dictionary) -> String:
	if left.is_empty() or right.is_empty():
		return "Choose a gallery result for both comparison slots."
	var left_snapshot := snapshot_from_record(left)
	var right_snapshot := snapshot_from_record(right)
	var lines: Array[String] = ["RESULT A", _summary(left, left_snapshot), "", "RESULT B", _summary(right, right_snapshot)]
	return "\n".join(lines)


static func same_record(left: Dictionary, right: Dictionary) -> bool:
	var left_id := str(left.get("image_id", ""))
	var right_id := str(right.get("image_id", ""))
	if not left_id.is_empty() and not right_id.is_empty():
		return left_id == right_id
	return str(left.get("path", "")) == str(right.get("path", ""))


static func _summary(record: Dictionary, snapshot: Dictionary) -> String:
	return "%s\n%s · %s · %s\nSeed %s · %s steps · CFG %s\nPrompt: %s" % [
		str(record.get("created_at", record.get("path", "Result"))).replace("T", " "),
		str(snapshot.get("profile_name", snapshot.get("backend", "Provider"))),
		str(snapshot.get("model", "Model not recorded")),
		str(snapshot.get("size", "Size not recorded")),
		str(snapshot.get("seed", -1)),
		str(snapshot.get("steps", "?")),
		str(snapshot.get("cfg_scale", "?")),
		str(snapshot.get("composed_prompt", "")).left(700)
	]


static func _dictionary_copy(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}


static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			var text := str(item).strip_edges()
			if not text.is_empty():
				result.append(text)
	return result
