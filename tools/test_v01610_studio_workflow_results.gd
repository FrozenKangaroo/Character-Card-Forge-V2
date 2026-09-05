extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V01610_STUDIO_RESULTS_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var profile := {
		"id": "regression_image",
		"name": "Regression Image Provider",
		"image_backend": CCFSettingsService.IMAGE_BACKEND_OPENAI,
		"base_url": "https://example.invalid/v1",
		"model": "image-regression",
		"api_key": "must-not-enter-result-history"
	}
	var options := {
		"sampler": "Euler a",
		"steps": 31,
		"cfg_scale": 6.5,
		"seed": 12345,
		"batch_size": 3,
		"provider_parameters": {"quality": "high", "guidance": 2.25},
		"image_operation": "inpainting",
		"source_image_path": "user://source.png",
		"source_image_id": "source_1",
		"mask_image_path": "user://mask.png",
		"reference_image_paths": ["user://reference_a.png", "user://reference_b.png"],
		"denoise_strength": 0.55,
		"mask_blur": 7
	}
	var snapshot := CCFImageResultWorkflowServiceV01610.execution_snapshot(
		profile, "image-regression", "1024x1536", "portrait", "exact composed prompt", "negative", options
	)
	if not _require(str(snapshot.get("composed_prompt", "")) == "exact composed prompt", "Result history must preserve the exact composed prompt."):
		return
	if not _require(int(snapshot.get("seed", -1)) == 12345 and int(snapshot.get("steps", 0)) == 31, "Result history must preserve reusable seed and step settings."):
		return
	if not _require((snapshot.get("provider_parameters", {}) as Dictionary).get("quality") == "high", "Unknown provider parameters must survive in the execution snapshot."):
		return
	if not _require(not snapshot.has("api_key"), "Result history must never copy provider credentials."):
		return

	var estimate := CCFImageResultWorkflowServiceV01610.estimate_cost({"cost_per_image": 0.04, "currency": "usd"}, 3)
	if not _require(bool(estimate.get("available", false)) and is_equal_approx(float(estimate.get("amount", 0.0)), 0.12), "Explicit per-image provider pricing must produce an optional batch estimate."):
		return
	if not _require(not bool(CCFImageResultWorkflowServiceV01610.estimate_cost({}, 3).get("available", true)), "Missing pricing metadata must remain supported without an invented estimate."):
		return

	var first := {"image_id": "a", "path": "a.png", "created_at": "2026-01-01T00:00:00", "execution_snapshot_v01610": snapshot}
	var second := {"image_id": "b", "path": "b.png", "created_at": "2026-01-02T00:00:00", "execution_snapshot_v01610": snapshot.duplicate(true)}
	second["execution_snapshot_v01610"]["seed"] = 54321
	if not _require(CCFImageResultWorkflowServiceV01610.comparison_text(first, second).contains("54321"), "Two-result comparison must expose differing provenance/settings."):
		return
	if not _require(CCFImageResultWorkflowServiceV01610.is_favourite(CCFImageResultWorkflowServiceV01610.with_favourite(first, true)), "Favourites must be additive result metadata."):
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.16.10 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if not _require(app.has_method("_update_build_version_label_v01610"), "The active application shell must identify v0.16.10."):
		return
	var studio_value: Variant = app.get("_image_generation_window")
	if not _require(studio_value is CCFImageGenerationWindowV01610, "The real application must install the v0.16.10 Image Studio."):
		return
	var studio := studio_value as CCFImageGenerationWindowV01610
	if not _require(studio.result_workflow_surface_ready_v01610(), "The live Studio must expose the v0.16.10 result workflow surface."):
		return
	if not _require(studio.get("_image_service") is CCFImageGenerationServiceV01610, "The live Studio must preserve complete v0.16.10 result snapshots."):
		return
	var capabilities := studio.result_workflow_capabilities_v01610()
	for key in ["execution_settings_snapshot", "reuse_settings_without_generation", "favourites", "two_result_comparison", "missing_asset_recovery"]:
		if not _require(bool(capabilities.get(key, false)), "Result workflow capability missing: %s" % key):
			return
	if not _require(not bool(capabilities.get("pricing_required", true)), "Local providers must not require pricing metadata."):
		return
	if not _require(app.has_method("_update_build_version_label_v0169"), "v0.16.10 must preserve the v0.16.9 shell through inheritance."):
		return
	app.queue_free()
	await process_frame
	print("v0.16.10 Studio workflow and results regression passed")
	quit(0)
