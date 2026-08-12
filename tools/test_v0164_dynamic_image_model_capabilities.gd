extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0164_DYNAMIC_CAPABILITY_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var endpoints := CCFImageProviderModelCatalogServiceV0164.endpoint_candidates(
		"https://example.invalid/api/v1/images/generations"
	)
	if not _require(endpoints.size() == 3, "v0.16.4 discovery must expose rich, legacy-rich, and generic endpoint candidates."):
		return
	if not _require(endpoints[0].ends_with("/api/v1/images/models"), "The normalized rich image-model endpoint must be preferred."):
		return
	if not _require(endpoints[1].ends_with("/api/v1/image-models"), "The legacy image-model endpoint must remain a fallback."):
		return
	if not _require(endpoints[2].ends_with("/models"), "Generic OpenAI-compatible /models must remain the final fallback."):
		return

	var raw_response := {
		"data": [
			{
				"id": "example-image-pro",
				"name": "Example Image Pro",
				"description": "Synthetic regression fixture",
				"owned_by": "fixture-provider",
				"pricing": {"image": 0.025, "currency": "USD"},
				"capabilities": {
					"image_generation": true,
					"image_to_image": true,
					"inpainting": false,
					"reference_images": true
				},
				"supported_parameters": {
					"resolutions": ["1024x1024", "1536x1024"],
					"max_images": 4,
					"rendering_speed": ["standard", "fast"],
					"quality": ["standard", "high"],
					"creativity": ["low", "medium", "high"]
				},
				"future_provider_field": {"preserve_me": true}
			}
		]
	}
	var parsed := CCFImageProviderModelCatalogServiceV0164.parse_provider_response(
		raw_response, endpoints[0]
	)
	if not _require(bool(parsed.get("ok", false)), "Rich provider model fixture must parse."):
		return
	if not _require(bool(parsed.get("rich_metadata", false)), "Rich provider metadata must be detected."):
		return
	var records: Array = parsed.get("records", [])
	if not _require(records.size() == 1, "The rich fixture must retain one model record."):
		return
	var record: Dictionary = records[0]
	if not _require((record.get("future_provider_field", {}) as Dictionary).get("preserve_me", false), "Unknown future provider record fields must be preserved."):
		return

	var profile := {
		"id": "fixture-image",
		"name": "Fixture Image",
		"image_backend": CCFSettingsService.IMAGE_BACKEND_OPENAI,
		"base_url": "https://example.invalid/api/v1/images/generations",
		"model": "example-image-pro"
	}
	var catalog := CCFImageProviderModelCatalogServiceV0164.with_fetch_metadata(parsed, endpoints[0])
	var normalized := CCFImageProviderModelCatalogServiceV0164.normalized_capabilities_for_model(
		profile, catalog, "example-image-pro"
	)
	if not _require(CCFImageModelCapabilityServiceV0161.operation_state(normalized, "text_to_image") == CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED, "Provider text-to-image support must become authoritative normalized capability data."):
		return
	if not _require(CCFImageModelCapabilityServiceV0161.operation_state(normalized, "image_to_image") == CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED, "Provider image-to-image support must be retained even before Studio execution is exposed."):
		return
	var parameters: Dictionary = normalized.get("parameters", {})
	if not _require((parameters.get("resolution", {}) as Dictionary).get("values", []).size() == 2, "Provider resolution strings must be preserved verbatim."):
		return
	if not _require(int((parameters.get("image_count", {}) as Dictionary).get("maximum", 0)) == 4, "Provider max-images metadata must constrain image count."):
		return
	if not _require(parameters.has("creativity"), "Unknown/additive supported parameters must survive normalization."):
		return
	if not _require((normalized.get("pricing", {}) as Dictionary).get("image", 0.0) == 0.025, "Provider pricing metadata must be retained."):
		return

	var vanished := CCFImageProviderModelCatalogServiceV0164.normalized_capabilities_for_model(
		profile, catalog, "model-removed-by-provider"
	)
	if not _require(bool(vanished.get("model_missing_from_latest_catalog", false)), "A manually selected/cached model that vanished from discovery must remain identifiable instead of being silently replaced."):
		return

	var cached_profile := CCFImageProviderModelCatalogServiceV0164.cache_catalog_in_profile(profile, catalog)
	var cached_catalog := CCFImageProviderModelCatalogServiceV0164.catalog_from_profile(cached_profile)
	if not _require((cached_catalog.get("records", []) as Array).size() == 1, "Rich model catalog must round-trip through profile cache data."):
		return
	if not _require(CCFImageProviderModelCatalogServiceV0164.catalog_age_seconds(cached_catalog) >= 0, "Cached model catalog must retain refresh age metadata."):
		return

	var generation_service := CCFImageGenerationServiceV0164.new()
	root.add_child(generation_service)
	generation_service._pending_backend = CCFImageGenerationService.PROVIDER_OPENAI_COMPATIBLE
	generation_service._pending_model = "example-image-pro"
	generation_service._pending_prompt = "test prompt"
	generation_service._pending_negative_prompt = ""
	generation_service._pending_image_size = "1024x1024"
	generation_service._pending_options = {
		"batch_size": 1,
		"provider_parameters": {
			"quality": "high",
			"rendering_speed": "fast",
			"creativity": "medium",
			"model": "must-not-overwrite"
		}
	}
	var payload := generation_service._build_generation_payload()
	if not _require(payload.get("quality", "") == "high", "Dynamic provider quality must reach generation payloads."):
		return
	if not _require(payload.get("rendering_speed", "") == "fast", "Dynamic provider speed must reach generation payloads."):
		return
	if not _require(payload.get("creativity", "") == "medium", "Future additive provider parameters must reach generation payloads."):
		return
	if not _require(payload.get("model", "") == "example-image-pro", "Dynamic provider parameters must never overwrite core model selection."):
		return
	generation_service.queue_free()
	await process_frame

	CCFStorageService.ensure_directories()
	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.16.4 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if not _require(app.has_method("_update_build_version_label_v0164"), "The active application shell must identify v0.16.4."):
		return
	var image_window_value: Variant = app.get("_image_generation_window")
	if not _require(image_window_value is CCFImageGenerationWindowV0164, "The real application must install the v0.16.4 Image Studio."):
		return
	var image_window := image_window_value as CCFImageGenerationWindowV0164
	if not _require(image_window.dynamic_provider_surface_ready_v0164(), "The dynamic provider controls must be mounted in the real Studio."):
		return
	if not _require(image_window.tabbed_layout_ready_v0163(), "v0.16.4 must preserve the v0.16.3 tabbed workflow."):
		return
	if not _require(image_window.structured_prompt_surface_ready_v0162(), "v0.16.4 must preserve the v0.16.2 creative composer."):
		return
	if not _require(image_window.capability_surface_ready_v0161(), "v0.16.4 must preserve the v0.16.1 capability inspector."):
		return
	if not _require(app.find_child("ImageStudioDynamicProviderControlsV0164", true, false) != null, "The mounted Advanced tab must expose dynamic provider controls."):
		return
	if not _require(image_window.get("_capability_service") is CCFImageCapabilityServiceV0164, "The live Studio must use v0.16.4 rich model discovery."):
		return
	if not _require(image_window.get("_image_service") is CCFImageGenerationServiceV0164, "The live Studio must use v0.16.4 provider-parameter-aware image generation."):
		return

	app.queue_free()
	await process_frame
	print("v0.16.4 dynamic provider image model capability regression passed")
	quit(0)
