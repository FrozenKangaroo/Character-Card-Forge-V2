extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_prepare_settings_v01531()
	var packed := load("res://scenes/main.tscn") as PackedScene
	assert(packed != null, "v0.15.31 main scene must load.")
	var app := packed.instantiate()
	assert(app != null, "v0.15.31 main scene must instantiate.")
	get_root().add_child(app)
	for _frame in range(8):
		await process_frame

	var workspace := _find_workspace_v01531(app)
	assert(workspace != null, "The live app must install CCFWorkspaceV01531View.")
	var image_window := _find_image_window_v01531(app)
	assert(image_window != null, "The live app must install CCFImageGenerationWindowV01531.")
	assert(
		workspace.get("_image_jobs_controller_v01531") == image_window,
		"Workspace AI Jobs must receive the live Image Studio controller."
	)
	workspace.show_ai_jobs_v01531(true)
	var panel := workspace.ai_jobs_panel_v01531()
	assert(panel != null and panel.visible, "AI Jobs panel must be available and showable in the live Workspace.")
	assert(_find_ai_jobs_toggle_v01531(workspace) != null, "Workspace must expose an AI Jobs toggle beside queue controls.")

	var services := workspace.concurrent_services_v01526()
	for service_name in ["primary", "collaborator", "ideas", "tools", "vision"]:
		assert(
			services.get(service_name) is CCFGenerationServiceV01531,
			"%s must use the inspectable v0.15.31 generation service." % service_name
		)

	_test_independent_queued_cancel_v01531(workspace, services)
	_test_safe_section_dependency_rows_v01531(workspace, services)
	_test_image_job_visibility_and_cancel_v01531(workspace, image_window)

	workspace.show_ai_jobs_v01531(false)
	assert(not panel.visible, "AI Jobs panel must remain collapsible.")
	app.queue_free()
	await process_frame
	print("v0.15.31 AI Jobs queue panel regression passed")
	quit(0)


func _prepare_settings_v01531() -> void:
	var settings := CCFSettingsService.default_settings()
	var generation: Dictionary = settings.get("generation", {}).duplicate(true)
	generation["ai_concurrency"] = {
		"format_version": 1,
		"max_total_jobs": 1,
		"max_text_jobs": 1,
		"max_vision_jobs": 1,
		"max_image_jobs": 1,
		"max_sections_per_character": 2,
		"parallel_safe_sections": true,
		"vision_counts_toward_total": true,
		"image_counts_toward_total": true
	}
	settings["generation"] = generation
	var save_result := CCFSettingsService.save_settings(settings)
	assert(bool(save_result.get("ok", false)), "v0.15.31 fixture settings must save.")


func _test_independent_queued_cancel_v01531(
	workspace: CCFWorkspaceV01531View, services: Dictionary
) -> void:
	var collaborator := services.get("collaborator") as CCFGenerationServiceV01531
	var ideas := services.get("ideas") as CCFGenerationServiceV01531
	var collaborator_queue: Array = collaborator.get("_queue")
	var ideas_queue: Array = ideas.get("_queue")
	collaborator_queue.append(_fixture_job_v01531("job_200321", "collaborator_reply", "Collaborator reply"))
	ideas_queue.append(_fixture_job_v01531("job_300654", "idea_generation", "Idea generation"))
	workspace.call("_refresh_ai_jobs_panel_v01531")
	var records := workspace.ai_job_records_v01531()
	assert(_record_by_job_id_v01531(records, "job_200321").get("status") == "queued")
	assert(_record_by_job_id_v01531(records, "job_300654").get("status") == "queued")
	assert(
		workspace.cancel_ai_job_v01531("collaborator", "job_200321"),
		"Per-job Cancel must remove the selected queued Collaborator job."
	)
	assert(collaborator.pending_count() == 0, "Selected Collaborator queue must be empty after cancellation.")
	assert(ideas.pending_count() == 1, "Cancelling Collaborator must not clear the unrelated Idea Generator queue.")
	ideas.clear_pending_jobs()


func _test_safe_section_dependency_rows_v01531(
	workspace: CCFWorkspaceV01531View, services: Dictionary
) -> void:
	var primary := services.get("primary") as CCFGenerationServiceV01531
	primary.set(
		"_active_job",
		{
			"id": "job_100777",
			"type": "character",
			"label": "Safe Section Build",
			"profile_name": "Fixture Text",
			"model": "fixture-model",
			"generation_strategy": "safe_section",
			"parallel_safe_waiting_v01526": true,
			"safe_build_state": {
				"plan": [
					{
						"kind": "standalone_field",
						"id": "scenario",
						"field_id": "scenario",
						"title": "Scenario"
					},
					{
						"kind": "standalone_field",
						"id": "first_message",
						"field_id": "first_message",
						"title": "First Message"
					}
				]
			}
		}
	)
	primary.set(
		"_parallel_coordinator_v01526",
		{
			"started": true,
			"completed_indices": {},
			"running": {},
			"wave_indices": [0],
			"wave_cursor": 0,
			"wave_number": 0,
			"waves": [[0], [1]],
			"failed": false
		}
	)
	workspace.call("_refresh_ai_jobs_panel_v01531")
	var records := primary.job_records_v01531()
	var scenario := _record_by_label_v01531(records, "Scenario")
	var first_message := _record_by_label_v01531(records, "First Message")
	assert(scenario.get("status") == "queued", "Scenario must be visible in the eligible Safe Section wave.")
	assert(first_message.get("status") == "waiting_dependency", "First Message must visibly wait for Scenario.")
	assert(str(first_message.get("detail", "")).contains("Scenario"), "Dependency wait must name Scenario rather than showing an unexplained queue stall.")
	assert(
		str(first_message.get("cancel_job_id", "")) == "job_100777",
		"Cancelling a Safe child row must target the parent Character build."
	)

	primary.set(
		"_parallel_coordinator_v01526",
		{
			"started": true,
			"completed_indices": {0: true},
			"running": {},
			"wave_indices": [1],
			"wave_cursor": 0,
			"wave_number": 1,
			"waves": [[0], [1]],
			"failed": false
		}
	)
	records = primary.job_records_v01531()
	scenario = _record_by_label_v01531(records, "Scenario")
	first_message = _record_by_label_v01531(records, "First Message")
	assert(scenario.get("status") == "completed", "Completed Safe Sections must remain visible while the parent build is active.")
	assert(first_message.get("status") == "queued", "First Message must become eligible after Scenario completes.")
	primary.set("_active_job", {})
	primary.set("_parallel_coordinator_v01526", {})
	workspace.call("_refresh_ai_jobs_panel_v01531")


func _test_image_job_visibility_and_cancel_v01531(
	workspace: CCFWorkspaceV01531View,
	image_window: CCFImageGenerationWindowV01531
) -> void:
	var image_service := image_window.get("_image_service") as CCFImageGenerationServiceV01526
	assert(image_service != null, "Image Studio must retain the scheduler-aware Image service.")
	image_service.set(
		"_pending_generate_v01526",
		{
			"project_id": "fixture-project",
			"character_id": "fixture-character",
			"profile": {
				"name": "Local Forge",
				"model": "portrait.safetensors"
			},
			"prompt_text": "portrait",
			"negative_prompt": "",
			"image_size": "1024x1024",
			"prompt_style": "stable_diffusion",
			"model_override": "portrait.safetensors",
			"options": {}
		}
	)
	workspace.call("_refresh_ai_jobs_panel_v01531")
	var records := workspace.ai_job_records_v01531()
	var image_record := _record_by_job_id_v01531(records, "image_generation")
	assert(not image_record.is_empty(), "Queued Image Studio generation must appear in the shared AI Jobs panel.")
	assert(image_record.get("status") == "waiting_capacity", "Pending Image generation must be labelled as waiting for capacity.")
	assert(str(image_record.get("profile_name", "")) == "Local Forge")
	assert(
		workspace.cancel_ai_job_v01531(
			str(image_record.get("worker_id", "image_generation")),
			"image_generation"
		),
		"Image Studio job must be cancellable from the shared AI Jobs panel."
	)
	var pending_value: Variant = image_service.get("_pending_generate_v01526")
	assert(pending_value is Dictionary and pending_value.is_empty(), "Cancelling the Image job must clear its pending generation state.")


func _fixture_job_v01531(job_id: String, job_type: String, label: String) -> Dictionary:
	return {
		"id": job_id,
		"type": job_type,
		"label": label,
		"profile_name": "Fixture Text",
		"model": "fixture-model",
		"metadata": {},
		"payload": {},
		"max_retries": 0,
		"attempt": 0
	}


func _record_by_job_id_v01531(records: Array, job_id: String) -> Dictionary:
	for raw_record in records:
		if raw_record is Dictionary and str(raw_record.get("job_id", "")) == job_id:
			return raw_record
	return {}


func _record_by_label_v01531(records: Array, label: String) -> Dictionary:
	for raw_record in records:
		if raw_record is Dictionary and str(raw_record.get("label", "")) == label:
			return raw_record
	return {}


func _find_workspace_v01531(root: Node) -> CCFWorkspaceV01531View:
	if root is CCFWorkspaceV01531View:
		return root as CCFWorkspaceV01531View
	for child in root.get_children():
		if child is Node:
			var found := _find_workspace_v01531(child)
			if found != null:
				return found
	return null


func _find_image_window_v01531(root: Node) -> CCFImageGenerationWindowV01531:
	if root is CCFImageGenerationWindowV01531:
		return root as CCFImageGenerationWindowV01531
	for child in root.get_children():
		if child is Node:
			var found := _find_image_window_v01531(child)
			if found != null:
				return found
	return null


func _find_ai_jobs_toggle_v01531(root: Node) -> Button:
	if root is Button and (root as Button).text.begins_with("AI Jobs ("):
		return root as Button
	for child in root.get_children():
		if child is Node:
			var found := _find_ai_jobs_toggle_v01531(child)
			if found != null:
				return found
	return null
