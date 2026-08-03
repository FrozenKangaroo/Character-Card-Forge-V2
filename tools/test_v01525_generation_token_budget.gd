extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var service := CCFGenerationServiceV01525.new()
	var capabilities := service.generation_token_budget_capabilities_v01525()
	assert(bool(capabilities.get("character_text_budget_invariant", false)), "v0.15.25 must enforce one Text output budget across Character generation stages.")
	assert(bool(capabilities.get("provider_termination_diagnostics", false)), "v0.15.25 must expose provider termination diagnostics.")

	var questions: Array = []
	for index in range(39):
		questions.append({
			"id": "question_%02d" % index,
			"label": "Question %02d" % index,
			"question": "Develop a useful planning answer for interview question %02d." % index,
			"required": index < 8
		})

	var configured_payload := {
		"model": "test-model",
		"temperature": 0.8,
		"max_tokens": 32768,
		"messages": [
			{"role": "system", "content": "Original system prompt"},
			{"role": "user", "content": "Original character generation prompt"}
		]
	}
	var interview := service._build_interview_payload(
		configured_payload,
		"A deliberately detailed character concept.",
		questions,
		{},
		false
	)
	assert(int(interview.get("max_tokens", 0)) == 32768, "Private Interview/Q&A must use the active Text Maximum Output Tokens allowance, not the historical 2,600-token cap.")
	assert(float(interview.get("temperature", 1.0)) <= 0.65, "The interview may retain its lower temperature without changing the user's token allowance.")

	var modest_payload := configured_payload.duplicate(true)
	modest_payload["max_tokens"] = 1800
	var modest_interview := service._build_interview_payload(
		modest_payload,
		"Short concept.",
		questions.slice(0, 3),
		{},
		false
	)
	assert(int(modest_interview.get("max_tokens", 0)) == 1800, "v0.15.25 must respect a deliberately smaller user-configured Text output limit exactly rather than imposing its own minimum or larger value.")

	# Simulate any later inherited generation/repair stage attempting to apply its
	# own hidden ceiling. The final request guard must restore the authoritative
	# Text profile budget before HTTPRequest sees the payload.
	service._active_job = {
		"id": "job_token_invariant",
		"type": "character",
		"payload": {
			"model": "test-model",
			"temperature": 0.0,
			"max_tokens": 2600,
			"messages": [{"role": "user", "content": "Repair this section."}]
		},
		"authoritative_text_max_output_tokens_v01525": 32768,
		"metadata": {},
		"profile_name": "Regression profile",
		"model": "test-model"
	}
	service._enforce_character_output_budget_v01525()
	var enforced_payload: Dictionary = service._active_job.get("payload", {})
	assert(int(enforced_payload.get("max_tokens", 0)) == 32768, "Every Character sub-request must restore the configured Text output allowance before sending.")

	var termination := service.provider_termination_from_response_v01525({
		"choices": [
			{
				"index": 0,
				"message": {"role": "assistant", "content": "{\"partial\": \"value"},
				"finish_reason": "length"
			}
		],
		"usage": {
			"prompt_tokens": 4921,
			"completion_tokens": 2600,
			"total_tokens": 7521
		}
	})
	assert(str(termination.get("finish_reason", "")) == "length", "Diagnostics must extract finish_reason from OpenAI-compatible choices.")
	assert(bool(termination.get("limit_reached", false)), "finish_reason=length must be identified as an output-limit termination.")
	assert(int(termination.get("completion_tokens", 0)) == 2600, "Diagnostics must preserve provider completion-token usage.")
	service._active_job.clear()
	service.free()

	var packed := load("res://scenes/main.tscn") as PackedScene
	assert(packed != null, "v0.15.25 must have a loadable main scene.")
	var app := packed.instantiate()
	assert(app != null, "v0.15.25 main scene must instantiate.")
	get_root().add_child(app)
	await process_frame

	var workspace := _find_workspace_v01525(app)
	assert(workspace != null, "The live app shell must install CCFWorkspaceV01525View.")
	assert(workspace.call("_ensure_token_budget_generation_service_v01525"), "The live Workspace must activate the v0.15.25 token-safe generation service.")
	var live_service_value: Variant = workspace.get("_generation_service")
	assert(live_service_value is CCFGenerationServiceV01525, "The real live Workspace must use CCFGenerationServiceV01525 rather than the older v0.15.22 leaf.")
	var live_service := live_service_value as CCFGenerationServiceV01525
	assert(live_service.has_method("queue_character_generation_with_strategy"), "v0.15.25 must retain Safe Section Build and Fast Full Card.")
	assert(live_service.has_signal("diagnostics_available"), "v0.15.25 must retain Generation Diagnostics.")

	var diagnostics_source := FileAccess.get_file_as_string("res://scripts/ui/generation_diagnostics_window_v01525.gd")
	assert(diagnostics_source.contains("OUTPUT LIMIT REACHED"), "Diagnostics Overview must make provider output-limit termination immediately visible.")
	assert(diagnostics_source.contains("This request max_tokens"), "Diagnostics Overview must show the actual max_tokens sent for the failed request.")
	assert(diagnostics_source.contains("Provider output tokens"), "Diagnostics Overview must show provider-reported completion/output token use.")

	var service_source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v01525.gd")
	assert(service_source.contains("_enforce_character_output_budget_v01525"), "v0.15.25 must keep a final request-time token-budget invariant rather than relying only on one interview override.")
	assert(service_source.contains("active_text_provider_profile"), "The authoritative Character token budget must be captured from the active Text provider payload.")

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01525.gd")
	assert(main_source.contains('BUILD_DISPLAY_VERSION_V01525 := "0.15.25"'), "The v0.15.25 shell must expose its build version.")
	assert(_active_shell_inherits_from("res://scripts/main_v01525.gd"), "The active scene must use or inherit v0.15.25.")

	app.queue_free()
	await process_frame
	print("v0.15.25 generation token budget regression passed")
	quit(0)


func _find_workspace_v01525(root: Node) -> CCFWorkspaceV01525View:
	if root is CCFWorkspaceV01525View:
		return root as CCFWorkspaceV01525View
	for child in root.get_children():
		if child is Node:
			var found := _find_workspace_v01525(child)
			if found != null:
				return found
	return null


func _active_shell_inherits_from(target_path: String) -> bool:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		return false
	var root := packed.instantiate()
	if root == null:
		return false
	var current := root.get_script() as Script
	while current != null:
		if current.resource_path == target_path:
			root.free()
			return true
		current = current.get_base_script()
	root.free()
	return false
