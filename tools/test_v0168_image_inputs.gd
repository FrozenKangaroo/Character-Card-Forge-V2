extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0168_IMAGE_INPUT_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var source_path := "user://v0168_source.png"
	var mask_path := "user://v0168_mask.png"
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.5, 0.5, 0.5, 1.0))
	if not _require(image.save_png(source_path) == OK, "Fixture source image must save."):
		return
	var mask := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	mask.fill(Color.WHITE)
	if not _require(mask.save_png(mask_path) == OK, "Fixture mask image must save."):
		return

	var bundle := CCFImageInputAssetServiceV0168.validate_bundle(
		CCFImageInputAssetServiceV0168.OP_INPAINTING,
		{"source_image_path": source_path, "mask_image_path": mask_path}
	)
	if not _require(bool(bundle.get("ok", false)), "A valid source + mask bundle must pass validation."):
		return
	var missing_mask := CCFImageInputAssetServiceV0168.validate_bundle(
		CCFImageInputAssetServiceV0168.OP_INPAINTING,
		{"source_image_path": source_path}
	)
	if not _require(not bool(missing_mask.get("ok", true)), "Inpainting must require a mask."):
		return

	var profile := {
		"id": "a1111-test",
		"name": "A1111 Test",
		"base_url": "http://127.0.0.1:7860",
		"image_backend": CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111,
		"model": "fixture.safetensors"
	}
	var base_caps := CCFImageModelCapabilityServiceV0161.normalise_discovery(profile, {})
	var ready_caps := CCFImageInputAssetServiceV0168.with_execution_readiness(base_caps, profile)
	if not _require(
		CCFImageInputAssetServiceV0168.operation_execution_ready(
			ready_caps, CCFImageInputAssetServiceV0168.OP_IMAGE_TO_IMAGE
		),
		"Forge/A1111 img2img must be execution-ready in v0.16.8."
	):
		return
	if not _require(
		CCFImageInputAssetServiceV0168.operation_execution_ready(
			ready_caps, CCFImageInputAssetServiceV0168.OP_INPAINTING
		),
		"Forge/A1111 inpainting must be execution-ready in v0.16.8."
	):
		return
	if not _require(
		not CCFImageInputAssetServiceV0168.operation_execution_ready(
			ready_caps, CCFImageInputAssetServiceV0168.OP_REFERENCE_IMAGES
		),
		"A1111 reference-image execution must remain unknown without an explicit extension/profile transport."
	):
		return

	var service := CCFImageGenerationServiceV0168.new()
	root.add_child(service)
	service.set("_pending_backend", CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111)
	service.set("_pending_profile", profile.duplicate(true))
	service.set("_pending_prompt", "fixture prompt")
	service.set("_pending_negative_prompt", "")
	service.set("_pending_image_size", "512x512")
	service.set("_pending_model", "fixture.safetensors")
	service.set("_pending_options", {
		"image_operation": CCFImageInputAssetServiceV0168.OP_INPAINTING,
		"source_image_path": source_path,
		"mask_image_path": mask_path,
		"denoise_strength": 0.55,
		"mask_blur": 6,
		"batch_size": 1,
		"steps": 20,
		"cfg_scale": 7.0,
		"seed": 123,
		"sampler": "Euler a"
	})
	var endpoint := str(service.call(
		"_generation_url",
		"http://127.0.0.1:7860",
		CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111
	))
	if not _require(endpoint.ends_with("/sdapi/v1/img2img"), "A1111 image-input operations must target img2img."):
		return
	var payload: Dictionary = service.call("_build_generation_payload")
	if not _require(payload.has("init_images"), "A1111 img2img payload must include init_images."):
		return
	if not _require(payload.has("mask"), "A1111 inpainting payload must include the mask."):
		return
	if not _require(is_equal_approx(float(payload.get("denoising_strength", 0.0)), 0.55), "Denoise strength must reach the A1111 payload."):
		return
	if not _require(int(payload.get("mask_blur", -1)) == 6, "Mask blur must reach the A1111 payload."):
		return
	service.queue_free()
	await process_frame

	var mapped_profile := {
		"image_backend": CCFSettingsService.IMAGE_BACKEND_OPENAI,
		CCFImageInputAssetServiceV0168.TRANSPORT_KEY: {
			"operations": {
				CCFImageInputAssetServiceV0168.OP_REFERENCE_IMAGES: {
					"endpoint_suffix": "/images/generations",
					"references_field": "input_images"
				}
			}
		}
	}
	var mapped_caps := CCFImageInputAssetServiceV0168.with_execution_readiness(
		CCFImageModelCapabilityServiceV0161.normalise_discovery(mapped_profile, {}),
		mapped_profile
	)
	if not _require(
		CCFImageInputAssetServiceV0168.operation_execution_ready(
			mapped_caps, CCFImageInputAssetServiceV0168.OP_REFERENCE_IMAGES
		),
		"Explicit provider transport mappings must make reference-image execution available."
	):
		return

	CCFStorageService.ensure_directories()
	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.16.8 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if not _require(app.has_method("_update_build_version_label_v0168"), "The active application shell must identify v0.16.8."):
		return
	var studio_value: Variant = app.get("_image_generation_window")
	if not _require(studio_value is CCFImageGenerationWindowV0168, "The real application must install the v0.16.8 Image Studio."):
		return
	var studio := studio_value as CCFImageGenerationWindowV0168
	if not _require(studio.image_input_surface_ready_v0168(), "The live Image Studio must expose the v0.16.8 image-input surface."):
		return
	if not _require(studio.image_operation_count_v0168() == 4, "Image Studio must expose four generation operations."):
		return
	var live_caps := studio.image_input_capabilities_v0168()
	if not _require(int(live_caps.get("operation_count", 0)) == 4, "The live v0.16.8 capability contract must expose all four operations."):
		return
	if not _require(app.has_method("_update_build_version_label_v0167"), "v0.16.8 must preserve the v0.16.7 Idea Generator shell through inheritance."):
		return

	app.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(source_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(mask_path))
	print("v0.16.8 image input regression passed")
	quit(0)
