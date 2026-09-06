extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0170_IMAGE_COLLABORATOR_HANDOFF_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var project := {
		"project_id": "project_v0170",
		"metadata": {"name": "Handoff Regression Project"}
	}
	var character := {
		"character_id": "character_v0170",
		"metadata": {"name": "Avery"},
		"character": {
			"name": "Avery",
			"description": "Existing canonical description"
		}
	}
	var snapshot := CCFImageResultWorkflowServiceV01610.execution_snapshot(
		{
			"id": "image_profile",
			"name": "Studio Provider",
			"image_backend": CCFSettingsService.IMAGE_BACKEND_OPENAI
		},
		"image-model-v17",
		"1024x1536",
		"portrait",
		"exact composed portrait prompt",
		"low quality",
		{
			"seed": 1700,
			"steps": 32,
			"cfg_scale": 6.25,
			"provider_parameters": {
				"quality": "high",
				"api_key": "must-not-survive",
				"nested": {
					"access_token": "must-not-survive-either",
					"refresh_token": "must-not-survive-too",
					"style": "vivid"
				}
			}
		}
	)
	var record := {
		"image_id": "image_v0170",
		"path": "characters/character_v0170/generated_images/result.png",
		"width": 1024,
		"height": 1536,
		"created_at": "2026-09-06T00:00:00Z",
		"result_workflow_version": "0.16.10",
		"execution_snapshot_v01610": snapshot
	}
	var project_before := project.duplicate(true)
	var character_before := character.duplicate(true)
	var record_before := record.duplicate(true)
	var source := CCFImageCollaboratorHandoffServiceV0170.from_result(
		project, character, record, "user://projects/project_v0170/result.png"
	)
	if not _require(not source.is_empty(), "A valid gallery result must create a structured Collaborator source."):
		return
	if not _require(
		str(source.get("source_type", ""))
		== CCFCollaboratorSourceContextServiceV01537.TYPE_IMAGE_STUDIO_RESULT,
		"The handoff must use the dedicated Image Studio result source type."
	):
		return
	if not _require(
		str(source.get("label", "")).begins_with("Avery")
		and str((source.get("provenance", {}) as Dictionary).get("project_name", ""))
		== "Handoff Regression Project",
		"The handoff must resolve names from the real nested project/character schema."
	):
		return
	if not _require(
		str(source.get("source_role", ""))
		== CCFCollaboratorSourceContextServiceV01537.ROLE_REFERENCE,
		"Image Studio results must enter Collaborator as Reference Context."
	):
		return
	if not _require(
		not CCFCollaboratorSourceContextServiceV01537.can_be_target(source),
		"An image must never become a Compare & Apply target."
	):
		return

	var source_snapshot: Dictionary = source.get("snapshot", {})
	var generation: Dictionary = source_snapshot.get("generation", {})
	if not _require(
		str(generation.get("composed_prompt", "")) == "exact composed portrait prompt"
		and str(generation.get("model", "")) == "image-model-v17"
		and int(generation.get("seed", -1)) == 1700,
		"The structured source must preserve exact prompt/model/seed provenance."
	):
		return
	var parameters: Dictionary = generation.get("provider_parameters", {})
	if not _require(
		str(parameters.get("quality", "")) == "high"
		and not parameters.has("api_key")
		and not (parameters.get("nested", {}) as Dictionary).has("access_token")
		and not (parameters.get("nested", {}) as Dictionary).has("refresh_token"),
		"Useful provider parameters must survive while credentials are redacted."
	):
		return
	if not _require(
		project == project_before and character == character_before and record == record_before,
		"Preparing a handoff must not mutate project, character or gallery data."
	):
		return
	var context_block := CCFCollaboratorSourceContextServiceV01537.model_context_block([source])
	if not _require(
		context_block.contains("generation prompts/settings describe creative intent")
		and context_block.contains("separately linked Vision reference"),
		"Model context must distinguish creative provenance from separate Vision evidence."
	):
		return
	if not _require(
		CCFCollaboratorCardVisionServiceV01539.is_visual_card_source(source),
		"A structured Image Studio source must remain eligible for optional linked Vision analysis."
	):
		return
	var linked_vision := CCFCollaboratorCardVisionServiceV01539.annotate_vision_context(
		{"type": "vision_reference", "content": "Separate visual description"},
		str(source.get("source_context_id", "")),
		str(source.get("source_type", ""))
	)
	if not _require(
		str(linked_vision.get("context_provenance", ""))
		== "vision_description_linked_to_image_studio_result",
		"Image Vision evidence must carry Image Studio-specific linkage without changing legacy Character Card provenance."
	):
		return

	var capabilities := CCFImageCollaboratorHandoffServiceV0170.capabilities()
	for key in [
		"structured_image_source",
		"raw_image_provenance",
		"exact_generation_snapshot",
		"existing_character_target_mode",
		"new_collaborator_mode",
		"optional_linked_vision",
		"vision_evidence_separate"
	]:
		if not _require(bool(capabilities.get(key, false)), "Handoff capability missing: %s" % key):
			return
	if not _require(
		not bool(capabilities.get("canonical_writes_automatic", true)),
		"Image handoff must declare that canonical writes are never automatic."
	):
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.17.0 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if not _require(
		app.has_method("_update_build_version_label_v0170"),
		"The active application shell must identify v0.17.0."
	):
		return
	var studio_value: Variant = app.get("_image_generation_window")
	if not _require(
		studio_value is CCFImageGenerationWindowV0170,
		"The application must install the v0.17.0 Image Studio."
	):
		return
	var studio := studio_value as CCFImageGenerationWindowV0170
	if not _require(
		studio.collaborator_handoff_surface_ready_v0170(),
		"The live Image Studio must expose the Collaborator handoff surface."
	):
		return
	if not _require(
		studio.collaborator_handoff_requested.is_connected(
			app._on_image_collaborator_handoff_requested_v0170
		),
		"The Image Studio handoff must be wired to the active Workspace."
	):
		return
	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		workspace_value is CCFWorkspaceV0170View,
		"The application must install the v0.17.0 Workspace handoff bridge."
	):
		return
	var workspace := workspace_value as CCFWorkspaceV0170View
	var live_project := CCFStorageService.new_project()
	live_project["project_id"] = "project_v0170"
	(live_project["metadata"] as Dictionary)["name"] = "Handoff Regression Project"
	var live_characters: Array = live_project.get("characters", [])
	var live_character: Dictionary = (live_characters[0] as Dictionary).duplicate(true)
	live_character["character_id"] = "character_v0170"
	(live_character["metadata"] as Dictionary)["name"] = "Avery"
	(live_character["character"] as Dictionary)["name"] = "Avery"
	(live_character["character"] as Dictionary)["description"] = "Existing canonical description"
	live_characters[0] = live_character
	live_project["characters"] = live_characters
	(live_project["workspace"] as Dictionary)["active_character_id"] = "character_v0170"
	workspace.load_project(
		live_project,
		CCFTemplateService.load_default_template(),
		CCFSettingsService.default_settings()
	)
	var existing_result := workspace.open_collaborator_with_image_result_v0170(
		source,
		{
			"mode": CCFImageCollaboratorHandoffServiceV0170.MODE_EXISTING_TARGET,
			"analyse_with_vision": false
		}
	)
	if not _require(
		bool(existing_result.get("ok", false))
		and not bool(existing_result.get("canonical_character_changed", true)),
		"Existing-target handoff must open successfully without a canonical character write."
	):
		return
	var collaborator_value: Variant = workspace.get("_character_collaborator_window")
	if not _require(
		collaborator_value is CCFCharacterCollaboratorWindowV0170,
		"The v0.17.0 Workspace must install a Collaborator that accepts the structured image source directly."
	):
		return
	var existing_sources_value: Variant = collaborator_value.call(
		"active_source_contexts_v01537"
	)
	var existing_sources: Array = (
		existing_sources_value as Array if existing_sources_value is Array else []
	)
	var target_count := 0
	var image_count := 0
	for live_source_value in existing_sources:
		if not live_source_value is Dictionary:
			continue
		var live_source: Dictionary = live_source_value
		if str(live_source.get("source_role", "")) == "target":
			target_count += 1
		if str(live_source.get("source_type", "")) == "image_studio_result":
			image_count += 1
	if not _require(
		target_count == 1 and image_count == 1 and existing_sources.size() == 2,
		"Existing-target mode must create one character target plus one image reference."
	):
		return

	var new_result := workspace.open_collaborator_with_image_result_v0170(
		source,
		{
			"mode": CCFImageCollaboratorHandoffServiceV0170.MODE_NEW_COLLABORATOR,
			"analyse_with_vision": false
		}
	)
	if not _require(
		bool(new_result.get("ok", false)),
		"Image-led mode must open a new Collaborator conversation: %s"
		% str(new_result.get("error", "unknown error"))
	):
		return
	var image_led_sources_value: Variant = collaborator_value.call(
		"active_source_contexts_v01537"
	)
	var image_led_sources: Array = (
		image_led_sources_value as Array if image_led_sources_value is Array else []
	)
	if not _require(
		image_led_sources.size() == 1
		and str((image_led_sources[0] as Dictionary).get("source_type", ""))
		== "image_studio_result"
		and str((image_led_sources[0] as Dictionary).get("source_role", ""))
		== "reference",
		"Image-led mode must start with only the image as read-only Reference Context."
	):
		return
	if not _require(
		app.has_method("_update_build_version_label_v01610"),
		"v0.17.0 must preserve the v0.16.10 shell through inheritance."
	):
		return
	app.queue_free()
	await process_frame
	print("v0.17.0 structured Image Studio to Collaborator handoff regression passed")
	quit(0)
