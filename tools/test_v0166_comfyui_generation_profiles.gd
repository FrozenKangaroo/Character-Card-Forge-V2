extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0166_COMFYUI_PROFILE_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var workflow := {
		"1": {"class_type": "CLIPTextEncode", "inputs": {"text": "old prompt", "clip": ["9", 1]}},
		"2": {"class_type": "CLIPTextEncode", "inputs": {"text": "old negative", "clip": ["9", 1]}},
		"3": {"class_type": "KSampler", "inputs": {"seed": 1, "steps": 20, "cfg": 7.0, "positive": ["1", 0], "negative": ["2", 0]}},
		"4": {"class_type": "EmptyLatentImage", "inputs": {"width": 512, "height": 512, "batch_size": 1}},
		"8": {"class_type": "SaveImage", "inputs": {"filename_prefix": "CCF", "images": ["7", 0]}},
		"9": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": "fixture.safetensors"}},
		"future_node": {"class_type": "FutureCustomNode", "inputs": {"preserve_me": {"x": 1}}}
	}
	var profile := CCFComfyUIGenerationProfileServiceV0166.normalise_profile({
		"id": "portrait_workflow",
		"name": "Portrait Workflow",
		"description": "Synthetic regression fixture",
		"workflow": workflow,
		"mappings": {
			"prompt": {"node_id": "1", "input": "text", "value_type": "text", "required": true},
			"negative_prompt": {"node_id": "2", "input": "text", "value_type": "text"},
			"seed": {"node_id": "3", "input": "seed", "value_type": "integer"},
			"steps": {"node_id": "3", "input": "steps", "value_type": "integer"},
			"cfg_scale": {"node_id": "3", "input": "cfg", "value_type": "number"},
			"width": {"node_id": "4", "input": "width", "value_type": "integer"},
			"height": {"node_id": "4", "input": "height", "value_type": "integer"}
		},
		"output": {"node_id": "8", "kind": "image"},
		"future_profile_field": {"keep": true}
	})
	if not _require(profile.get("format_version", 0) == 1, "Generation Profile format must be versioned."):
		return
	if not _require((profile.get("workflow", {}) as Dictionary).has("future_node"), "Unknown/custom ComfyUI workflow nodes must be preserved."):
		return

	var validation := CCFComfyUIGenerationProfileServiceV0166.validate_profile(profile)
	if not _require(bool(validation.get("ok", false)), "Synthetic ComfyUI profile must validate."):
		return
	var materialised := CCFComfyUIGenerationProfileServiceV0166.materialise_workflow(profile, {
		"prompt": "silver-haired mage",
		"negative_prompt": "blurry",
		"seed": 123456,
		"steps": 34,
		"cfg_scale": 5.5,
		"width": 1024,
		"height": 1536
	})
	if not _require(bool(materialised.get("ok", false)), "Valid ComfyUI profile must materialise offline."):
		return
	var result_workflow: Dictionary = materialised.get("workflow", {})
	if not _require(str(((result_workflow.get("1") as Dictionary).get("inputs") as Dictionary).get("text")) == "silver-haired mage", "Prompt must map to configured node input."):
		return
	if not _require(int(((result_workflow.get("3") as Dictionary).get("inputs") as Dictionary).get("seed")) == 123456, "Seed must map with integer coercion."):
		return
	if not _require(int(((result_workflow.get("4") as Dictionary).get("inputs") as Dictionary).get("width")) == 1024, "Width must map to configured latent-size input."):
		return
	if not _require((((result_workflow.get("future_node") as Dictionary).get("inputs") as Dictionary).get("preserve_me") as Dictionary).get("x") == 1, "Unmapped/custom workflow data must survive materialisation unchanged."):
		return

	var capabilities := CCFComfyUIGenerationProfileServiceV0166.capability_document(profile)
	if not _require(CCFImageModelCapabilityServiceV0161.operation_state(capabilities, "text_to_image") == CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED, "Mapped prompt must advertise workflow text-to-image support."):
		return
	if not _require(not CCFImageModelCapabilityServiceV0161.execution_ready(capabilities, "text_to_image"), "v0.16.6 must not claim live ComfyUI queue execution before transport is implemented."):
		return
	if not _require(CCFImageModelCapabilityServiceV0161.parameter_state(capabilities, "seed") == CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED, "Mapped seed must become a workflow-provenance capability."):
		return

	var bad_profile := profile.duplicate(true)
	(bad_profile.get("mappings") as Dictionary)["prompt"] = {"node_id": "missing", "input": "text", "value_type": "text"}
	var bad_validation := CCFComfyUIGenerationProfileServiceV0166.validate_profile(bad_profile)
	if not _require(not bool(bad_validation.get("ok", true)), "Mappings to missing nodes must fail validation."):
		return

	var image_profile := {
		"id": "fixture-image",
		"name": "Fixture Image",
		"image_backend": CCFSettingsService.IMAGE_BACKEND_OPENAI,
		"comfyui_enabled_v0166": true,
		CCFComfyUIGenerationProfileServiceV0166.ACTIVE_PROFILE_KEY: "portrait_workflow",
		CCFComfyUIGenerationProfileServiceV0166.PROFILE_KEY: {"portrait_workflow": profile}
	}
	var round_trip := CCFComfyUIGenerationProfileServiceV0166.profile_from_image_provider(image_profile)
	if not _require(str(round_trip.get("id")) == "portrait_workflow", "Active ComfyUI Generation Profile must round-trip through Image profile data."):
		return

	CCFStorageService.ensure_directories()
	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.16.6 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if not _require(app.has_method("_update_build_version_label_v0166"), "The active application shell must identify v0.16.6."):
		return
	var image_window_value: Variant = app.get("_image_generation_window")
	if not _require(image_window_value is CCFImageGenerationWindowV0166, "The real application must install the v0.16.6 Image Studio."):
		return
	var image_window := image_window_value as CCFImageGenerationWindowV0166
	if not _require(image_window.comfyui_generation_profile_surface_ready_v0166(), "The ComfyUI Generation Profile surface must be mounted in Advanced."):
		return
	if not _require(image_window.local_model_profile_surface_ready_v0165(), "v0.16.6 must preserve v0.16.5 local checkpoint profiles."):
		return
	if not _require(image_window.dynamic_provider_surface_ready_v0164(), "v0.16.6 must preserve v0.16.4 dynamic provider capabilities."):
		return
	if not _require(image_window.tabbed_layout_ready_v0163(), "v0.16.6 must preserve v0.16.3 tabs."):
		return
	if not _require(image_window.structured_prompt_surface_ready_v0162(), "v0.16.6 must preserve v0.16.2 structured creative controls."):
		return
	if not _require(image_window.capability_surface_ready_v0161(), "v0.16.6 must preserve v0.16.1 capability inspection."):
		return
	if not _require(app.find_child("ImageStudioComfyUIGenerationProfileControlsV0166", true, false) != null, "Mounted app tree must expose the ComfyUI Generation Profile editor."):
		return

	app.queue_free()
	await process_frame
	print("v0.16.6 ComfyUI Generation Profile regression passed")
	quit(0)
