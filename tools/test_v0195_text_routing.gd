extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message_text: String) -> void:
	push_error(message_text)
	print("V0195_TEXT_ROUTING_ERROR: %s" % message_text)
	quit(1)


func _require(condition: bool, message_text: String) -> bool:
	if condition:
		return true
	_fail(message_text)
	return false


func _run() -> void:
	if not _test_settings_and_routes():
		return
	if not _test_bounded_fallback():
		return
	if not await _test_active_ui_wiring():
		return
	print("V0195_TEXT_ROUTING_OK")
	quit(0)


func _test_settings_and_routes() -> bool:
	var settings := CCFSettingsService.default_settings()
	var default_routing: Dictionary = CCFSettingsService.profile_for_text_task(
		settings, CCFSettingsService.TEXT_TASK_PRIMARY
	).get("_ccf_text_routing_v0195", {})
	if not _require(
		int(settings.get("format_version", 0)) >= 8
		and CCFSettingsService.role_profile_id(
			settings, CCFSettingsService.ROLE_TEXT_FAST
		) == CCFSettingsService.USE_PRIMARY_PROFILE_ID
		and not bool(settings.get("generation", {}).get("text_fallback_enabled", true))
		and (default_routing.get("fallback_profile", {}) as Dictionary).is_empty(),
		"Existing installs must migrate to Use Primary routes with fallback disabled."
	):
		return false

	var profiles: Array = settings.get("api_profiles", []).duplicate(true)
	profiles.append(_profile("fast", "Fast profile", "fast-model"))
	profiles.append(_profile("deep", "Deep profile", "deep-model"))
	profiles.append(_profile("fallback", "Fallback profile", "fallback-model"))
	settings["api_profiles"] = profiles
	CCFSettingsService.set_role_profile(
		settings, CCFSettingsService.ROLE_TEXT_FAST, "fast"
	)
	CCFSettingsService.set_role_profile(
		settings, CCFSettingsService.ROLE_TEXT_DEEP, "deep"
	)
	CCFSettingsService.set_role_profile(
		settings, CCFSettingsService.ROLE_TEXT_FALLBACK, "fallback"
	)
	var generation: Dictionary = settings.get("generation", {}).duplicate(true)
	generation["text_fallback_enabled"] = true
	settings["generation"] = generation

	var primary := CCFSettingsService.profile_for_text_task(
		settings, CCFSettingsService.TEXT_TASK_PRIMARY
	)
	var fast := CCFSettingsService.profile_for_text_task(
		settings, CCFSettingsService.TEXT_TASK_FAST
	)
	var deep := CCFSettingsService.profile_for_text_task(
		settings, CCFSettingsService.TEXT_TASK_DEEP
	)
	var fast_routing: Dictionary = fast.get("_ccf_text_routing_v0195", {})
	return (
		_require(str(primary.get("id", "")) == "default", "Primary Text must remain the default route.")
		and _require(str(fast.get("id", "")) == "fast", "Single-field work must resolve the optional Fast profile.")
		and _require(str(deep.get("id", "")) == "deep", "AI Review must resolve the optional Deep profile.")
		and _require(
			str(fast_routing.get("fallback_profile", {}).get("id", "")) == "fallback",
			"An explicitly enabled distinct fallback must be attached to routed Text work."
		)
	)


func _test_bounded_fallback() -> bool:
	var settings := CCFSettingsService.default_settings()
	var profiles: Array = settings.get("api_profiles", []).duplicate(true)
	var primary: Dictionary = profiles[0]
	primary["model"] = "primary-model"
	profiles[0] = primary
	profiles.append(_profile("fallback", "Fallback profile", "fallback-model"))
	settings["api_profiles"] = profiles
	CCFSettingsService.set_role_profile(
		settings, CCFSettingsService.ROLE_TEXT_FALLBACK, "fallback"
	)
	var generation: Dictionary = settings.get("generation", {}).duplicate(true)
	generation["text_fallback_enabled"] = true
	settings["generation"] = generation
	var routed_profile := CCFSettingsService.profile_for_text_task(
		settings, CCFSettingsService.TEXT_TASK_PRIMARY
	)

	var service := CCFGenerationServiceV0195.new()
	var queued: Dictionary = service.call(
		"_queue_chat_job",
		"routing_test",
		"Routing test",
		routed_profile,
		[{"role": "user", "content": "Return JSON"}],
		"object",
		{"project_id": "routing-test"},
		0
	)
	if not _require(bool(queued.get("ok", false)), "A routed Text job must queue normally."):
		service.free()
		return false
	var queue: Array = service.get("_queue")
	var job: Dictionary = queue[0]
	service.set("_queue", [])
	service.set("_active_job", job)
	service.call(
		"_on_request_completed",
		HTTPRequest.RESULT_SUCCESS,
		404,
		PackedStringArray(),
		'{"error":{"message":"model unavailable"}}'.to_utf8_buffer()
	)
	var fallback_job: Dictionary = service.get("_active_job")
	var fallback_metadata: Dictionary = fallback_job.get("metadata", {})
	var fallback_record: Dictionary = fallback_metadata.get("fallback", {})
	if not _require(
		str(fallback_job.get("model", "")) == "fallback-model"
		and int(fallback_job.get("max_retries", -1)) == 0
		and bool(fallback_record.get("used", false))
		and str(fallback_record.get("from", {}).get("model", "")) == "primary-model"
		and str(fallback_record.get("to", {}).get("model", "")) == "fallback-model",
		"An eligible terminal technical failure must switch once and retain both producers."
	):
		service.free()
		return false

	var chain_job := fallback_job.duplicate(true)
	var completion: Dictionary = {}
	service.job_completed.connect(
		func(
			_job_id: String,
			_job_type: String,
			_data: Variant,
			produced_metadata: Dictionary
		) -> void:
			completion["metadata"] = produced_metadata.duplicate(true)
	)
	service.call("_process_completed_content", '{"answer":"ok"}')
	var produced_metadata: Dictionary = completion.get("metadata", {})
	if not _require(
		str(produced_metadata.get("profile_id", "")) == "fallback"
		and str(produced_metadata.get("profile_name", "")) == "Fallback profile"
		and str(produced_metadata.get("model", "")) == "fallback-model"
		and bool(produced_metadata.get("text_routing", {}).get("fallback_used", false)),
		"Accepted fallback output must report the actual producing profile and model."
	):
		service.free()
		return false

	service.set("_active_job", chain_job)
	service.call("_handle_failure", "API error 503: fallback unavailable", false)
	var failure_diagnostics := service.diagnostics_for_job_v01522(
		str(queued.get("job_id", ""))
	)
	if not _require(
		(service.get("_active_job") as Dictionary).is_empty()
		and not JSON.stringify(failure_diagnostics).contains("fixture-secret")
		and JSON.stringify(failure_diagnostics).contains("text_fallback"),
		"A failed fallback must terminate without a chain and retain credential-safe diagnostics."
	):
		service.free()
		return false
	service.free()

	var content_service := CCFGenerationServiceV0195.new()
	var content_queued: Dictionary = content_service.call(
		"_queue_chat_job",
		"content_test",
		"Content test",
		routed_profile,
		[{"role": "user", "content": "Return JSON"}],
		"object",
		{},
		0
	)
	var content_queue: Array = content_service.get("_queue")
	content_service.set("_queue", [])
	content_service.set("_active_job", content_queue[0])
	content_service.call(
		"_handle_failure", "The model refused the request.", false
	)
	var refused_active: Dictionary = content_service.get("_active_job")
	var forbidden_category: String = content_service.call(
		"_technical_failure_category_v0195",
		HTTPRequest.RESULT_SUCCESS,
		403,
		'{"error":"content policy refusal"}'
	)
	var missing_model_category: String = content_service.call(
		"_technical_failure_category_v0195",
		HTTPRequest.RESULT_SUCCESS,
		400,
		'{"error":"requested model is not available"}'
	)
	var invalid_content_category: String = content_service.call(
		"_technical_failure_category_v0195",
		HTTPRequest.RESULT_SUCCESS,
		400,
		'{"error":"content policy refusal"}'
	)
	content_service.free()
	return (
		_require(bool(content_queued.get("ok", false)), "The content-failure fixture must queue.")
		and _require(
			refused_active.is_empty()
			and forbidden_category.is_empty()
			and missing_model_category == "endpoint_or_model"
			and invalid_content_category.is_empty(),
			"Refusals, authentication/content failures and other non-technical failures must never fall back."
		)
	)


func _test_active_ui_wiring() -> bool:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var app := packed.instantiate()
	get_root().add_child(app)
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	var settings_value: Variant = app.get("_settings_view")
	if not _require(
		workspace_value is CCFWorkspaceV0195View
		and settings_value is CCFSettingsV0195View,
		"The active scene must install the v0.19.5 workspace and Settings views."
	):
		return false
	var workspace := workspace_value as CCFWorkspaceV0195View
	var capabilities := workspace.text_routing_capabilities_v0195()
	if not _require(
		bool(capabilities.get("single_field_suggestions_use_fast", false))
		and bool(capabilities.get("front_porch_single_fields_use_fast", false))
		and bool(capabilities.get("ai_review_uses_deep", false))
		and bool(capabilities.get("full_generation_uses_primary", false))
		and not bool(capabilities.get("content_failure_fallback", true))
		and not bool(capabilities.get("fallback_chains", true)),
		"The active workspace must expose the bounded v0.19.5 routing contract."
	):
		return false
	var version_found := false
	for node in app.find_children("*", "Label", true, false):
		if node is Label and node.text in [
			"Godot rewrite • v0.19.5", "Godot rewrite • v0.20.0"
		]:
			version_found = true
			break
	if not _require(version_found, "The application shell must display v0.19.5 or a later compatible version."):
		return false
	var settings_view := settings_value as CCFSettingsV0195View
	if not _require(
		settings_view.get("_fast_text_role_selector_v0195") is OptionButton
		and settings_view.get("_deep_text_role_selector_v0195") is OptionButton
		and settings_view.get("_fallback_text_role_selector_v0195") is OptionButton
		and settings_view.get("_text_fallback_enabled_v0195") is CheckBox,
		"Settings must visibly expose every optional Text route and the fallback opt-in."
	):
		return false
	app.queue_free()
	await process_frame
	return true


func _profile(profile_id: String, display_name: String, model_id: String) -> Dictionary:
	return {
		"id": profile_id,
		"profile_kind": CCFSettingsService.PROFILE_KIND_AI,
		"name": display_name,
		"base_url": "https://example.invalid/v1",
		"api_key": "fixture-secret",
		"model": model_id,
		"temperature": 0.4,
		"max_output_tokens": 4096,
		"vision_detail": "auto"
	}
