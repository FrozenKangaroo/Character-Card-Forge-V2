extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_scheduler_limits()
	_test_dependency_waves_and_assembly()
	await _test_live_runtime_wiring()
	print("v0.15.26 concurrent AI scheduler regression passed")
	quit(0)


func _test_scheduler_limits() -> void:
	var scheduler := CCFAIJobSchedulerV01526.new()
	scheduler.configure({
		"max_total_jobs": 2,
		"max_text_jobs": 2,
		"max_vision_jobs": 1,
		"max_image_jobs": 1,
		"max_sections_per_character": 2,
		"parallel_safe_sections": true,
		"vision_counts_toward_total": false,
		"image_counts_toward_total": true
	})
	assert(scheduler.request_slot("text_a", "text"), "First Text job should start.")
	assert(scheduler.request_slot("text_b", "text"), "Second Text job should start.")
	assert(not scheduler.request_slot("text_c", "text"), "Text work beyond the configured total/role limit must wait.")
	assert(scheduler.request_slot("vision_a", "vision"), "An independent Vision job must be allowed while the counted Text pool is full.")
	assert(not scheduler.request_slot("image_a", "image"), "Image work configured to count toward the total must wait while the total is full.")
	var snapshot := scheduler.snapshot()
	assert(int(snapshot.get("running", 0)) == 3, "Two Text jobs plus one independent Vision job should be running.")
	assert(int(snapshot.get("waiting", 0)) == 2, "Overflow Text and Image work should remain queued.")
	scheduler.release_slot("text_a")
	assert(scheduler.request_slot("text_c", "text"), "The oldest eligible waiting Text job should start when capacity is released.")

	var parent_scheduler := CCFAIJobSchedulerV01526.new()
	parent_scheduler.configure({
		"max_total_jobs": 8,
		"max_text_jobs": 8,
		"max_sections_per_character": 2,
		"parallel_safe_sections": true
	})
	assert(parent_scheduler.request_slot("section_1", "text", "character_a"), "First Safe Section should start.")
	assert(parent_scheduler.request_slot("section_2", "text", "character_a"), "Second Safe Section should start.")
	assert(not parent_scheduler.request_slot("section_3", "text", "character_a"), "A third sibling section must wait for the per-character limit even when global capacity remains.")
	assert(parent_scheduler.request_slot("other_job", "text", "character_b"), "Another character or independent parent should still use available capacity.")
	scheduler.free()
	parent_scheduler.free()


func _test_dependency_waves_and_assembly() -> void:
	var service := CCFGenerationServiceV01526.new()
	var capabilities := service.concurrent_capabilities_v01526()
	assert(bool(capabilities.get("parallel_safe_sections", false)), "v0.15.26 must advertise parallel Safe Section support.")
	assert(bool(capabilities.get("interview_barrier", false)), "Interview/Q&A must remain a barrier before section workers start.")
	assert(bool(capabilities.get("frozen_wave_context", false)), "Parallel siblings must use a frozen context snapshot.")
	assert(bool(capabilities.get("deterministic_template_order_assembly", false)), "Final assembly must use template order rather than completion order.")

	var plan := [
		{"id": "description_structure", "field_id": "description"},
		{"id": "personality_structure", "field_id": "personality"},
		{"id": "background", "field_id": "personality"},
		{"id": "scenario", "field_id": "scenario"},
		{"id": "first_message", "field_id": "first_message"},
		{"id": "example_dialogues", "field_id": "example_dialogues"}
	]
	var waves := service.dependency_waves_v01526(plan)
	assert(waves.size() == 3, "Core/Scenario, First Message, and Example Dialogues should form three dependency waves.")
	assert((waves[0] as Array) == [0, 1, 2, 3], "Independent sections should share the first post-Interview wave.")
	assert((waves[1] as Array) == [4], "First Message must wait for Scenario.")
	assert((waves[2] as Array) == [5], "Example Dialogues must wait for Scenario and First Message.")

	var personality_group := {
		"id": "personality_structure",
		"title": "Personality Structure",
		"output_field_id": "personality",
		"enabled": true,
		"components": [
			{"id": "mind", "label": "Mind", "enabled": true, "required": true}
		]
	}
	var sexual_group := {
		"id": "sexual_traits",
		"title": "Sexual Traits",
		"output_field_id": "personality",
		"enabled": true,
		"components": [
			{"id": "preferences", "label": "Preferences", "enabled": true, "required": true}
		]
	}
	var state := {
		"generation_template": {
			"sections": [
				{
					"id": "character",
					"fields": [
						{
							"id": "personality",
							"path": "character.personality",
							"generate": true,
							"type": "multiline"
						}
					]
				}
			],
			"generation_groups": [personality_group, sexual_group]
		},
		"accepted_fields": {},
		# Deliberately insert results in reverse completion order. Assembly must
		# still follow generation_groups/template order.
		"accepted_groups": {
			"sexual_traits": {
				"components": {"preferences": "Carefully developed preferences."},
				"extras": []
			},
			"personality_structure": {
				"components": {"mind": "A carefully developed personality."},
				"extras": []
			}
		}
	}
	var assembled := service._assembled_safe_fields_v01522(state)
	var personality := str(assembled.get("personality", ""))
	var personality_position := personality.find("Personality Structure:")
	var sexual_position := personality.find("Sexual Traits:")
	assert(personality_position >= 0 and sexual_position > personality_position, "Parallel results must combine in template order even when they complete in reverse order.")
	service.free()


func _test_live_runtime_wiring() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	assert(packed != null, "v0.15.26 must have a loadable main scene.")
	var app := packed.instantiate()
	assert(app != null, "v0.15.26 main scene must instantiate.")
	get_root().add_child(app)
	await process_frame
	await process_frame
	await process_frame

	var workspace := _find_workspace_v01526(app)
	assert(workspace != null, "The live app shell must install CCFWorkspaceV01526View.")
	var services := workspace.concurrent_services_v01526()
	for role_name in ["primary", "collaborator", "ideas", "tools", "vision"]:
		var service_value: Variant = services.get(role_name, null)
		assert(service_value is CCFGenerationServiceV01526, "The live %s worker must use the v0.15.26 service." % role_name)
	assert(services.get("primary") != services.get("collaborator"), "Generate Character and Character Collaborator need independent service workers.")
	assert(services.get("ideas") != services.get("collaborator"), "Idea Generator and Character Collaborator need independent service workers.")
	assert(services.get("vision") != services.get("primary"), "Vision work must not be serialized inside the primary Character worker.")
	assert(workspace.call("_ensure_collaborator_generation_service_v015"), "The newest compatible service must satisfy the Collaborator gate without an exact v0.15.22 script match.")
	var status_value: Variant = workspace.get("_status")
	if status_value is Label:
		assert(not (status_value as Label).text.contains("could not activate the v0.15.22 generation service"), "The reported exact-version Collaborator error must not return.")
	var collaborator_value: Variant = workspace.get("_character_collaborator_window")
	assert(collaborator_value != null, "The live Character Collaborator window must exist.")
	assert(collaborator_value.get("_generation_service") == services.get("collaborator"), "The Collaborator must stay bound to its dedicated current service instead of being reset to an older exact version.")
	var attachment_value: Variant = workspace.get("_attachment_window")
	if attachment_value != null:
		assert(attachment_value.get("_generation_service") == services.get("vision"), "Attachment/Vision work must use the dedicated Vision worker.")

	var scheduler := workspace.ai_scheduler_v01526()
	assert(scheduler != null, "The live Workspace must own the shared AI scheduler.")
	var image_window := _find_image_window_v01526(app)
	assert(image_window != null, "The live app shell must install the scheduler-aware Image Studio.")
	assert(image_window.scheduler_v01526() == scheduler, "Image generation must share the same scheduler so its global participation setting is honoured.")
	assert(_find_settings_v01526(app) != null, "The live Settings view must expose v0.15.26 concurrency controls.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01526.gd")
	assert(workspace_source.contains("_service_has_v01526_capabilities"), "Collaborator compatibility must be capability-based rather than exact-script based.")
	assert(not workspace_source.contains("GENERATION_SERVICE_V01522"), "The current Workspace must not require the historical v0.15.22 script exactly.")
	var settings_source := FileAccess.get_file_as_string("res://scripts/ui/settings_view_v01526.gd")
	for setting_key in [
		"max_total_jobs",
		"max_text_jobs",
		"max_vision_jobs",
		"max_image_jobs",
		"max_sections_per_character",
		"vision_counts_toward_total",
		"image_counts_toward_total"
	]:
		assert(settings_source.contains(setting_key), "Concurrency Settings must persist %s." % setting_key)
	assert(_active_shell_inherits_from("res://scripts/main_v01526.gd"), "The active scene must use or inherit v0.15.26.")

	app.queue_free()
	await process_frame


func _find_workspace_v01526(root: Node) -> CCFWorkspaceV01526View:
	if root is CCFWorkspaceV01526View:
		return root as CCFWorkspaceV01526View
	for child in root.get_children():
		if child is Node:
			var found := _find_workspace_v01526(child)
			if found != null:
				return found
	return null


func _find_image_window_v01526(root: Node) -> CCFImageGenerationWindowV01526:
	if root is CCFImageGenerationWindowV01526:
		return root as CCFImageGenerationWindowV01526
	for child in root.get_children():
		if child is Node:
			var found := _find_image_window_v01526(child)
			if found != null:
				return found
	return null


func _find_settings_v01526(root: Node) -> CCFSettingsV01526View:
	if root is CCFSettingsV01526View:
		return root as CCFSettingsV01526View
	for child in root.get_children():
		if child is Node:
			var found := _find_settings_v01526(child)
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
