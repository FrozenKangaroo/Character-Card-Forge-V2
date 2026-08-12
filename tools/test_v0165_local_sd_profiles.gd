extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0165_LOCAL_SD_PROFILE_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var catalog := CCFImageLocalModelProfileServiceV0165.family_catalog()
	if not _require(int(catalog.get("format_version", 0)) == 1, "Local model family catalog must remain versioned."):
		return
	if not _require((catalog.get("families", []) as Array).size() >= 3, "Local model family catalog must expose generic and reusable family profiles."):
		return
	var sdxl := CCFImageLocalModelProfileServiceV0165.family_definition("sdxl")
	if not _require(not sdxl.is_empty(), "SDXL authoring family profile must load from external data."):
		return
	if not _require(str((sdxl.get("preferred_defaults", {}) as Dictionary).get("resolution", "")) == "1024x1024", "Family profiles may provide workflow defaults without becoming capability claims."):
		return

	var image_profile := {
		"id": "local-fixture",
		"name": "Local Fixture",
		"image_backend": CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111,
		"base_url": "http://127.0.0.1:7860",
		"model": "fixtureCheckpoint.safetensors"
	}
	var raw_backend := {
		"backend_label": "Stable Diffusion Forge / Automatic1111",
		"models": ["fixtureCheckpoint.safetensors"],
		"samplers": ["Euler a", "DPM++ 2M"],
		"supports_negative_prompt": true,
		"supports_seed": true,
		"supports_sampler": true,
		"supports_steps": true,
		"supports_cfg_scale": true,
		"supports_batch": true
	}
	var base_capabilities := CCFImageModelCapabilityServiceV0161.normalise_discovery(
		image_profile, raw_backend, "fixtureCheckpoint.safetensors"
	)
	var local_profile := {
		"checkpoint_id": "fixtureCheckpoint.safetensors",
		"family_id": "sdxl",
		"notes": "Synthetic local model",
		"preferred_defaults": {"sampler": "DPM++ 2M", "steps": 36},
		"capability_overrides": {
			"operations": {
				"inpainting": {"state": "supported", "execution_ready": false}
			},
			"parameters": {
				"cfg_scale": {"state": "unsupported"}
			}
		}
	}
	var applied := CCFImageLocalModelProfileServiceV0165.apply_to_capabilities(
		base_capabilities, local_profile
	)
	if not _require(str(applied.get("model_family", "")) == "sdxl", "Checkpoint profile must retain selected model family."):
		return
	if not _require(CCFImageModelCapabilityServiceV0161.operation_state(applied, "inpainting") == CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED, "Explicit checkpoint operation override must supersede inherited backend state."):
		return
	if not _require(CCFImageModelCapabilityServiceV0161.parameter_state(applied, "cfg_scale") == CCFImageModelCapabilityServiceV0161.STATE_UNSUPPORTED, "Explicit checkpoint parameter override must supersede inherited backend state."):
		return
	if not _require(bool(applied.get("has_user_overrides", false)), "Checkpoint overrides must retain user-override provenance state."):
		return
	var parameters: Dictionary = applied.get("parameters", {})
	if not _require(str((parameters.get("cfg_scale", {}) as Dictionary).get("source", "")) == CCFImageModelCapabilityServiceV0161.SOURCE_USER_OVERRIDE, "Overridden parameters must identify user_override provenance."):
		return
	var defaults := CCFImageLocalModelProfileServiceV0165.effective_defaults(local_profile)
	if not _require(str(defaults.get("resolution", "")) == "1024x1024", "Family workflow defaults must flow into effective checkpoint defaults."):
		return
	if not _require(str(defaults.get("sampler", "")) == "DPM++ 2M", "Checkpoint-specific defaults must augment family defaults."):
		return
	if not _require(int(defaults.get("steps", 0)) == 36, "Checkpoint-specific defaults must override family defaults."):
		return

	var embedded_profile := image_profile.duplicate(true)
	embedded_profile[CCFImageLocalModelProfileServiceV0165.PROFILE_KEY] = {
		"fixtureCheckpoint.safetensors": local_profile
	}
	var round_trip := CCFImageLocalModelProfileServiceV0165.checkpoint_profile(
		embedded_profile, "fixtureCheckpoint.safetensors"
	)
	if not _require(str(round_trip.get("notes", "")) == "Synthetic local model", "Checkpoint profiles must round-trip through Image profile settings data."):
		return

	CCFStorageService.ensure_directories()
	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.16.5 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if not _require(app.has_method("_update_build_version_label_v0165"), "The active application shell must identify v0.16.5."):
		return
	var image_window_value: Variant = app.get("_image_generation_window")
	if not _require(image_window_value is CCFImageGenerationWindowV0165, "The real application must install the v0.16.5 Image Studio."):
		return
	var image_window := image_window_value as CCFImageGenerationWindowV0165
	if not _require(image_window.local_model_profile_surface_ready_v0165(), "The local checkpoint profile controls must be mounted in the real Studio."):
		return
	if not _require(image_window.dynamic_provider_surface_ready_v0164(), "v0.16.5 must preserve v0.16.4 dynamic provider controls."):
		return
	if not _require(image_window.tabbed_layout_ready_v0163(), "v0.16.5 must preserve v0.16.3 tabs."):
		return
	if not _require(image_window.structured_prompt_surface_ready_v0162(), "v0.16.5 must preserve v0.16.2 creative controls."):
		return
	if not _require(image_window.capability_surface_ready_v0161(), "v0.16.5 must preserve v0.16.1 capability inspection."):
		return
	if not _require(app.find_child("ImageStudioLocalModelProfileControlsV0165", true, false) != null, "The mounted Advanced tab must contain the v0.16.5 local profile surface."):
		return

	app.queue_free()
	await process_frame
	print("v0.16.5 local Forge/A1111 checkpoint profile regression passed")
	quit(0)
