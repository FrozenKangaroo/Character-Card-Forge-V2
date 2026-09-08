extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0173_HOTFIX1_OPENROUTER_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var openrouter_base := "https://openrouter.ai/api/v1"
	if not _require(
		CCFImageProviderTransportServiceV0173Hotfix1.is_openrouter_base_url(
			openrouter_base
		)
		and CCFImageProviderTransportServiceV0173Hotfix1.is_openrouter_base_url(
			"https://www.openrouter.ai/api/v1/models"
		)
		and not CCFImageProviderTransportServiceV0173Hotfix1.is_openrouter_base_url(
			"https://openrouter.ai.example.invalid/api/v1"
		),
		"OpenRouter detection must accept its host and subdomains without matching lookalike domains."
	):
		return

	for configured_url in [
		openrouter_base,
		"https://openrouter.ai/api/v1/",
		"https://openrouter.ai/api/v1/models",
		"https://openrouter.ai/api/v1/images/models",
		"https://openrouter.ai/api/v1/images/generations"
	]:
		if not _require(
			CCFImageProviderTransportServiceV0173Hotfix1.openrouter_generation_url(
				configured_url
			) == "https://openrouter.ai/api/v1/images",
			"Every supported OpenRouter profile URL must normalize to POST /api/v1/images."
		):
			return
		if not _require(
			CCFImageProviderTransportServiceV0173Hotfix1.openrouter_models_url(
				configured_url
			) == "https://openrouter.ai/api/v1/images/models",
			"Every supported OpenRouter profile URL must normalize to its image-only model catalog."
		):
			return

	var candidates := CCFImageProviderModelCatalogServiceV0164.endpoint_candidates(
		openrouter_base
	)
	if not _require(
		candidates.size() == 3
		and candidates[0] == "https://openrouter.ai/api/v1/images/models"
		and candidates[1] == "https://openrouter.ai/api/v1/image-models"
		and candidates[2] == "https://openrouter.ai/api/v1/models",
		"OpenRouter discovery must avoid duplicated /api/v1 segments and prefer image-only models."
	):
		return

	var service := CCFImageGenerationServiceV0173Hotfix1.new()
	root.add_child(service)
	service._pending_backend = CCFImageGenerationService.PROVIDER_OPENAI_COMPATIBLE
	service._pending_options = {
		"image_operation": CCFImageInputAssetServiceV0168.OP_TEXT_TO_IMAGE
	}
	var openrouter_route := service._generation_url(
		openrouter_base,
		CCFImageGenerationService.PROVIDER_OPENAI_COMPATIBLE
	)
	var generic_route := service._generation_url(
		"https://images.example.invalid/v1",
		CCFImageGenerationService.PROVIDER_OPENAI_COMPATIBLE
	)
	if not _require(
		openrouter_route == "https://openrouter.ai/api/v1/images"
		and generic_route == "https://images.example.invalid/v1/images/generations",
		"OpenRouter must use /images while unrelated OpenAI-compatible providers retain /images/generations."
	):
		return

	var fixture_image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	fixture_image.fill(Color(0.2, 0.4, 0.8, 1.0))
	var fixture_png := fixture_image.save_png_to_buffer()
	var response_payloads := service._extract_image_payloads({
		"data": [{"b64_json": Marshalls.raw_to_base64(fixture_png)}]
	})
	if not _require(
		response_payloads.size() == 1
		and str(response_payloads[0].get("kind", "")) == "bytes",
		"OpenRouter data[].b64_json responses must use the existing decoded-image path."
	):
		return

	var safe_url := CCFImageProviderTransportServiceV0173Hotfix1.safe_request_url(
		"https://user:secret@openrouter.ai/api/v1/images?api_key=secret#fragment"
	)
	if not _require(
		safe_url == "https://openrouter.ai/api/v1/images",
		"Visible request diagnostics must remove URL credentials, queries and fragments."
	):
		return
	service.queue_free()
	await process_frame

	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The hotfix main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if not _require(
		app.has_method("_update_build_version_label_v0173_hotfix1"),
		"The active application shell must identify v0.17.3-hotfix1."
	):
		return
	var studio_value: Variant = app.get("_image_generation_window")
	if not _require(
		studio_value is CCFImageGenerationWindowV0170,
		"The hotfix must preserve the v0.17.0 Image Studio and Collaborator handoff."
	):
		return
	var studio := studio_value as CCFImageGenerationWindowV0170
	var capabilities := studio.openrouter_transport_capabilities_v0173_hotfix1()
	if not _require(
		studio.get("_image_service") is CCFImageGenerationServiceV0173Hotfix1
		and bool(capabilities.get("openrouter_native_images", false))
		and str(capabilities.get("generation_endpoint", "")) == "/api/v1/images"
		and bool(capabilities.get("openai_images_generations_preserved", false)),
		"The live Image Studio must install OpenRouter routing without removing generic OpenAI Images support."
	):
		return

	app.queue_free()
	await process_frame
	print("v0.17.3-hotfix1 OpenRouter Images regression passed")
	quit(0)
