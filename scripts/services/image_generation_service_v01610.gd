class_name CCFImageGenerationServiceV01610
extends "res://scripts/services/image_generation_service_v0168.gd"


func _save_image(decoded_image: Image, batch_index: int, actual_seed: int) -> Dictionary:
	var record := super._save_image(decoded_image, batch_index, actual_seed)
	if record.is_empty():
		return record
	var snapshot := CCFImageResultWorkflowServiceV01610.execution_snapshot(
		_pending_profile,
		_pending_model,
		_pending_image_size,
		_pending_prompt_style,
		_pending_prompt,
		_pending_negative_prompt,
		_pending_options
	)
	snapshot["seed"] = actual_seed
	record["result_workflow_version"] = "0.16.10"
	record["composed_prompt_v01610"] = _pending_prompt
	record["execution_snapshot_v01610"] = snapshot
	record["provider_parameters"] = snapshot.get("provider_parameters", {}).duplicate(true)
	record["favourite_v01610"] = false
	var capabilities := CCFImageCapabilityCacheServiceV0161.capabilities_from_profile(_pending_profile)
	var pricing: Dictionary = capabilities.get("pricing", {}) if capabilities.get("pricing", {}) is Dictionary else {}
	record["cost_estimate_v01610"] = CCFImageResultWorkflowServiceV01610.estimate_cost(pricing, 1)
	return record
