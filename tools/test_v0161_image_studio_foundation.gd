extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0161_IMAGE_STUDIO_FOUNDATION_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var a1111_profile := {
		"backend": CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111,
		"base_url": "http://127.0.0.1:7860",
		"model": "animeXL.safetensors"
	}
	var legacy_a1111 := {
		"backend": CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111,
		"backend_label": "Stable Diffusion Forge / Automatic1111",
		"models": ["animeXL.safetensors"],
		"samplers": ["Euler a", "DPM++ 2M"],
		"supports_negative_prompt": true,
		"supports_seed": true,
		"supports_sampler": true,
		"supports_steps": true,
		"supports_cfg_scale": true,
		"supports_batch": true,
		"discovery_note": "Local WebUI discovery fixture."
	}
	var a1111 := CCFImageModelCapabilityServiceV0161.normalise_discovery(
		a1111_profile,
		legacy_a1111
	)
	if not _require(int(a1111.get("format_version", 0)) == 1, "Normalized Image capabilities must be versioned."):
		return
	if not _require(
		CCFImageModelCapabilityServiceV0161.operation_state(a1111, "text_to_image") == CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED,
		"Forge/A1111 text-to-image must be represented as supported."
	):
		return
	if not _require(
		CCFImageModelCapabilityServiceV0161.operation_state(a1111, "image_to_image") == CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED,
		"Forge/A1111 backend img2img capability must be representable before Studio execution is exposed."
	):
		return
	if not _require(
		not CCFImageModelCapabilityServiceV0161.execution_ready(a1111, "image_to_image"),
		"v0.16.1 must keep backend capability separate from current Studio execution readiness."
	):
		return
	if not _require(
		CCFImageModelCapabilityServiceV0161.parameter_state(a1111, "sampler") == CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED,
		"Forge/A1111 sampler capability must survive normalization."
	):
		return
	var sampler_descriptor: Dictionary = (a1111.get("parameters", {}) as Dictionary).get("sampler", {})
	if not _require((sampler_descriptor.get("values", []) as Array).has("DPM++ 2M"), "Discovered sampler values must remain available to capability-aware UI."):
		return

	# Existing v0.15.28 Image profiles may only have the legacy
	# `discovered_capabilities` cache. v0.16.1 must upgrade that shape in memory
	# without requiring the user to run provider discovery again.
	var legacy_profile := a1111_profile.duplicate(true)
	legacy_profile[CCFImageCapabilityCacheServiceV01528.CACHE_KEY] = legacy_a1111.duplicate(true)
	var migrated := CCFImageCapabilityCacheServiceV0161.capabilities_from_profile(legacy_profile)
	if not _require(
		CCFImageModelCapabilityServiceV0161.operation_state(migrated, "text_to_image") == CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED,
		"A legacy v0.15.28 capability cache must normalize into supported Forge/A1111 text-to-image without rediscovery."
	):
		return
	var migrated_sampler: Dictionary = (migrated.get("parameters", {}) as Dictionary).get("sampler", {})
	if not _require(
		(migrated_sampler.get("values", []) as Array).has("DPM++ 2M"),
		"Legacy cached sampler choices must survive in-memory normalization."
	):
		return

	var generic_profile := {
		"backend": CCFSettingsService.IMAGE_BACKEND_OPENAI,
		"base_url": "https://example.invalid/v1",
		"model": "unknown-image-model"
	}
	var generic := CCFImageModelCapabilityServiceV0161.normalise_discovery(
		generic_profile,
		{"models": ["unknown-image-model"], "supports_batch": true}
	)
	if not _require(
		CCFImageModelCapabilityServiceV0161.operation_state(generic, "image_to_image") == CCFImageModelCapabilityServiceV0161.STATE_UNKNOWN,
		"Missing OpenAI-compatible discovery metadata must remain unknown instead of being treated as unsupported."
	):
		return
	if not _require(
		CCFImageModelCapabilityServiceV0161.parameter_state(generic, "resolution") == CCFImageModelCapabilityServiceV0161.STATE_UNKNOWN,
		"Generic API resolution support must remain unknown when the provider does not describe it."
	):
		return

	# This fixture follows the richer provider model shape discussed for NanoGPT.
	# v0.16.1 does not yet own provider-specific fetching; it establishes a
	# normalized additive parser that the later discovery adapter can feed.
	var provider_record := {
		"id": "pruna-ai/p-image/text-to-image",
		"name": "P-Image",
		"description": "Fast text-to-image generation fixture.",
		"owned_by": "prunaai",
		"pricing": {
			"per_image": {"1024*1024": 0.005},
			"currency": "USD"
		},
		"capabilities": {
			"image_generation": true,
			"image_to_image": false,
			"inpainting": false,
			"nsfw": false
		},
		"supported_parameters": {
			"resolutions": ["1024x1024", "1376x768", "1184x896"],
			"max_images": 4,
			"rendering_speed": ["fast", "quality"],
			"creativity": ["low", "medium", "high"]
		},
		"tags": ["text-to-image", "prunaai"],
		"category": "image"
	}
	var provider_caps := CCFImageModelCapabilityServiceV0161.normalise_provider_model_record(
		generic_profile,
		provider_record
	)
	var discovery: Dictionary = provider_caps.get("discovery", {})
	if not _require(str(discovery.get("source", "")) == CCFImageModelCapabilityServiceV0161.SOURCE_PROVIDER, "Provider-supplied model capabilities must retain provider provenance."):
		return
	if not _require(str(discovery.get("confidence", "")) == CCFImageModelCapabilityServiceV0161.CONFIDENCE_AUTHORITATIVE, "Provider-supplied capability metadata must be marked authoritative."):
		return
	if not _require(
		CCFImageModelCapabilityServiceV0161.operation_state(provider_caps, "image_to_image") == CCFImageModelCapabilityServiceV0161.STATE_UNSUPPORTED,
		"An explicit provider false flag must remain distinct from unknown."
	):
		return
	var parameters: Dictionary = provider_caps.get("parameters", {})
	var resolution_descriptor: Dictionary = parameters.get("resolution", {})
	if not _require((resolution_descriptor.get("values", []) as Array).has("1376x768"), "Provider-specific resolution strings must be preserved verbatim."):
		return
	var image_count_descriptor: Dictionary = parameters.get("image_count", {})
	if not _require(int(image_count_descriptor.get("maximum", 0)) == 4, "Provider max_images must normalize into an image-count maximum."):
		return
	if not _require(parameters.has("creativity"), "Unknown additive provider parameters must be preserved instead of discarded."):
		return
	var creativity: Dictionary = parameters.get("creativity", {})
	if not _require((creativity.get("values", []) as Array).has("high"), "Unknown enumerated provider parameters must keep their choices."):
		return
	if not _require((provider_caps.get("pricing", {}) as Dictionary).get("currency", "") == "USD", "Provider pricing metadata must survive normalization for later cost-estimate UI."):
		return

	var overridden := CCFImageModelCapabilityServiceV0161.apply_user_overrides(
		generic,
		{
			"operations": {"image_to_image": true},
			"parameters": {"seed": true}
		}
	)
	if not _require(
		CCFImageModelCapabilityServiceV0161.operation_state(overridden, "image_to_image") == CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED,
		"Explicit local user overrides must be able to resolve unknown capabilities."
	):
		return
	var overridden_operation: Dictionary = (overridden.get("operations", {}) as Dictionary).get("image_to_image", {})
	if not _require(str(overridden_operation.get("source", "")) == CCFImageModelCapabilityServiceV0161.SOURCE_USER_OVERRIDE, "User capability overrides must retain their provenance."):
		return

	CCFStorageService.ensure_directories()
	var scene := load("res://scenes/main.tscn") as PackedScene
	if not _require(scene != null, "The v0.16.1 main scene must load."):
		return
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if not _require(app.has_method("_update_build_version_label_v0161"), "The active application shell must identify v0.16.1."):
		return
	var image_window_value: Variant = app.get("_image_generation_window")
	if not _require(image_window_value is CCFImageGenerationWindowV0161, "The real application must install the v0.16.1 Image Studio."):
		return
	var image_window := image_window_value as CCFImageGenerationWindowV0161
	var advertised := image_window.image_studio_foundation_capabilities_v0161()
	if not _require(bool(advertised.get("tri_state_capabilities", false)), "The live Image Studio must advertise tri-state capability semantics."):
		return
	if not _require(bool(advertised.get("capability_provenance", false)), "The live Image Studio must advertise capability provenance."):
		return
	if not _require(image_window.find_child("ImageStudioCapabilitySummaryV0161", true, false) != null, "The live Image Studio must expose a visible capability summary."):
		return
	if not _require(image_window.find_child("ImageStudioCapabilityDetailsButtonV0161", true, false) != null, "The live Image Studio must expose capability details without making an AI/provider request."):
		return

	app.queue_free()
	await process_frame
	print("v0.16.1 Image Studio 2 foundation regression passed")
	quit(0)
