extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0190_RICH_AUTHORING_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _make_project() -> Dictionary:
	var project := CCFStorageService.new_project()
	var first_id := CCFStorageService.active_character_id(project)
	var first := CCFStorageService.get_character(project, first_id)
	first["metadata"]["name"] = "Mara Vale"
	first["character"]["name"] = "Mara Vale"
	first["character"]["description"] = "A precise investigator in a rain-soaked port city."
	first["character"]["personality"] = "Measured, wry, relentless, and privately compassionate."
	first["character"]["scenario"] = "{{user}} brings Mara an impossible case."
	first["character"]["first_message"] = "Start at the beginning, and leave nothing out."
	CCFStorageService.update_character(project, first)
	var second_id := CCFStorageService.add_character(project, "Ivo Kest")
	var second := CCFStorageService.get_character(project, second_id)
	second["character"]["description"] = "A theatrical smuggler with a flawless memory."
	second["character"]["personality"] = "Warm, evasive, playful, and loyal under pressure."
	second["character"]["scenario"] = "Ivo is implicated in Mara's impossible case."
	second["character"]["first_message"] = "Detective, what a deeply unsurprising surprise."
	CCFStorageService.update_character(project, second)
	project["relationships"] = [{
		"relationship_id": CCFRelationshipService.pair_key(first_id, second_id),
		"character_a_id": first_id,
		"character_b_id": second_id,
		"label": "uneasy allies",
		"status": "active",
		"summary": "They need one another but disagree on methods.",
		"a_to_b": "Mara distrusts Ivo's improvisation.",
		"b_to_a": "Ivo respects Mara's resolve.",
		"dynamic": "methodical versus improvisational",
		"notes": "",
		"tags": ["rivals", "allies"],
		"intensity": 70
	}]
	project["front_porch_worlds"] = [{
		"world_id": "world_port",
		"package": {"name": "Rain Port", "lorebook": {"entries": []}}
	}]
	return project


func _find_button(root: Node, button_text: String) -> Button:
	for node in root.find_children("*", "Button", true, false):
		if node is Button and node.text == button_text:
			return node
	return null


func _run() -> void:
	var capabilities := CCFRichAuthoringServiceV0190.capabilities()
	if not _require(
		bool(capabilities.get("scenario_presets", false))
		and bool(capabilities.get("greeting_manager", false))
		and bool(capabilities.get("persistent_roster_and_active_cast", false))
		and bool(capabilities.get("recoverable_parent_job", false))
		and bool(capabilities.get("partial_retry", false))
		and bool(capabilities.get("dependency_inspection", false))
		and bool(capabilities.get("explicit_export_mappings", false))
		and not bool(capabilities.get("automatic_network_calls", true))
		and not bool(capabilities.get("raw_database_writes", true)),
		"v0.19.0 must advertise the complete rich-authoring and safety boundary."
	):
		return

	var project := _make_project()
	var summaries := CCFStorageService.project_character_summaries(project)
	var first_id := str(summaries[0].get("character_id", ""))
	var second_id := str(summaries[1].get("character_id", ""))
	var first_before := CCFStorageService.get_character(project, first_id)
	var first := first_before.duplicate(true)
	var scenario := CCFRichAuthoringServiceV0190.upsert_scenario(first, {
		"name": "Midnight Ferry",
		"scenario": "Mara and {{user}} board the last ferry while Ivo follows unseen.",
		"opening_message": "The ferry leaves in three minutes. Decide what you're carrying.",
		"active_character_ids": [first_id, second_id],
		"world_ids": ["world_port"],
		"tags": ["mystery", "night"],
		"favourite": true
	})
	CCFStorageService.update_character(project, first)
	var materialised := CCFRichAuthoringServiceV0190.materialise_scenario(
		project, first_id, str(scenario.get("scenario_id", ""))
	)
	if not _require(
		bool(materialised.get("ok", false))
		and str(materialised.get("card", {}).get("data", {}).get("scenario", "")).contains("last ferry")
		and CCFStorageService.get_character(project, first_id).get("character", {}).get("scenario", "")
		== first_before.get("character", {}).get("scenario", ""),
		"Scenario presets must materialise one reviewed setup without changing the source card."
	):
		return

	first = CCFStorageService.get_character(project, first_id)
	var greetings := CCFRichAuthoringServiceV0190.set_greeting_records(first, [
		{"text": "The ferry leaves in three minutes.", "category": "Mystery", "tags": ["urgent"], "weight": 8, "favourite": true, "front_porch_seed": "rainy dock"},
		{"text": "You look like someone carrying a secret.", "category": "Mystery", "tags": ["quiet"], "weight": 1}
	])
	CCFStorageService.update_character(project, first)
	var chosen := CCFRichAuthoringServiceV0190.choose_greeting(first, "Mystery", "deterministic-key")
	if not _require(
		greetings.size() == 2
		and first.get("character", {}).get("alternate_greetings", []).size() == 2
		and not chosen.is_empty()
		and str(chosen.get("category", "")) == "Mystery",
		"Greeting metadata must retain categories, weights and Front Porch seeds while synchronising compatible alternate greetings."
	):
		return
	var legacy_greeting_record := CCFStorageService.new_character_record("Legacy Greeter")
	legacy_greeting_record["character"]["alternate_greetings"] = [
		"Welcome back to the rain port.",
		"The ferry has already left."
	]
	var legacy_greetings_first := CCFRichAuthoringServiceV0190.greeting_records(
		legacy_greeting_record
	)
	var legacy_greetings_second := CCFRichAuthoringServiceV0190.greeting_records(
		legacy_greeting_record
	)
	if not _require(
		legacy_greetings_first.size() == 2
		and str(legacy_greetings_first[0].get("greeting_id", ""))
		== str(legacy_greetings_second[0].get("greeting_id", ""))
		and not str(legacy_greetings_first[0].get("greeting_id", "")).is_empty(),
		"Legacy alternate greetings must receive stable IDs so repeated selector reads keep working."
	):
		return

	var group_project := CCFRichAuthoringServiceV0190.new_multi_character_project(
		"Harbour Ensemble", ["Mara", "Ivo", "The Ferryman"]
	)
	var initial_workflow: Dictionary = group_project.get("card_workflows", [])[0]
	var group_ids: Array[String] = []
	for summary in CCFStorageService.project_character_summaries(group_project):
		group_ids.append(str(summary.get("character_id", "")))
	initial_workflow = CCFRichAuthoringServiceV0190.apply_roster(
		initial_workflow, group_ids, [group_ids[0], group_ids[1]]
	)
	initial_workflow["title"] = "Harbour Ensemble"
	initial_workflow["shared_scenario"] = "A conspiracy unfolds aboard the midnight ferry."
	initial_workflow["opening_message"] = "The bell sounds once across black water."
	initial_workflow["front_porch_group"] = {"world_ids": ["world_port"], "system_prompt": "Preserve distinct voices."}
	var source_guard := JSON.stringify(group_project)
	var combined := CCFRichAuthoringServiceV0190.materialise_multi_character_card(
		group_project, initial_workflow
	)
	if not _require(
		group_ids.size() == 3
		and bool(combined.get("ok", false))
		and (combined.get("source_character_ids", []) as Array).size() == 2
		and JSON.stringify(group_project) == source_guard
		and str(combined.get("card", {}).get("data", {}).get("system_prompt", "")).contains("distinct"),
		"Ensemble materialisation must distinguish roster from active cast and never mutate independent sources."
	):
		return

	var source_for_copy := CCFStorageService.get_character(project, first_id)
	var source_copy_workspace: Dictionary = source_for_copy.get("workspace", {}).duplicate(true)
	source_copy_workspace[CCFFrontPorchSyncServiceV0185.BINDING_KEY] = {
		"remote_id": "front-porch-mara"
	}
	source_for_copy["workspace"] = source_copy_workspace
	CCFStorageService.update_character(project, source_for_copy)
	var copied := CCFRichAuthoringServiceV0190.add_existing_library_character(
		group_project, project, first_id
	)
	var copied_project: Dictionary = copied.get("project", {})
	var copied_id := str(copied.get("character_id", ""))
	var copied_record := CCFStorageService.get_character(copied_project, copied_id)
	if not _require(
		bool(copied.get("ok", false))
		and copied_id != first_id
		and str(copied_record.get("revision_lineage", {}).get("source_character_id", "")) == first_id
		and str(copied_record.get("assets", {}).get("portrait", "")).is_empty()
		and not copied_record.get("workspace", {}).has(
			CCFFrontPorchSyncServiceV0185.BINDING_KEY
		)
		and CCFRevisionServiceV0181.list_revisions(copied_record).size() == 1,
		"Adding a library character must create an independent, revisioned copy without managed-file links or the source Front Porch identity."
	):
		return

	var split := CCFRichAuthoringServiceV0190.create_split_batch(project, "Two rivals investigate a flooded archive.", [
		{"name": "Archivist", "role": "methodical keeper"},
		{"name": "Diver", "role": "reckless salvage expert"}
	])
	var split_project: Dictionary = split.get("project", {})
	var batch: Dictionary = split.get("batch", {})
	var batch_id := str(batch.get("batch_id", ""))
	var split_request := CCFRichAuthoringServiceV0190.build_split_request(split_project, batch_id)
	var member_rows: Array = batch.get("members", [])
	var successful_id := str(member_rows[0].get("character_id", ""))
	var failed_id := str(member_rows[1].get("character_id", ""))
	var applied := CCFRichAuthoringServiceV0190.apply_split_result(split_project, batch_id, {
		"members": [
			{
				"character_id": successful_id,
				"description": "Keeper of a flooded archive.",
				"personality": "Patient and exacting.",
				"scenario": "{{user}} arrives during a salvage attempt.",
				"first_message": "The water is rising again.",
				"example_dialogue": "{{char}}: Mark every recovered page.",
				"creator_notes": "Independent member.",
				"system_prompt": "Preserve this member's voice.",
				"post_history_instructions": "Track recovered pages."
			},
			{"character_id": failed_id, "description": "Incomplete"}
		]
	}, {"model": "fixture-model"})
	var applied_project: Dictionary = applied.get("project", {})
	var retry_request := CCFRichAuthoringServiceV0190.build_split_request(
		applied_project, batch_id, [failed_id]
	)
	if not _require(
		bool(split.get("ok", false))
		and bool(split_request.get("ok", false))
		and bool(applied.get("ok", false))
		and bool(applied.get("partial", false))
		and (applied.get("completed_character_ids", []) as Array) == [successful_id]
		and applied.get("failures", {}).has(failed_id)
		and (retry_request.get("requested_character_ids", []) as Array) == [failed_id]
		and CCFRevisionServiceV0181.list_revisions(
			CCFStorageService.get_character(applied_project, successful_id)
		).size() == 1,
		"Split generation must retain a recoverable parent batch, accept partial results and retry only failed members."
	):
		return
	var current_retry_project := applied_project.duplicate(true)
	current_retry_project["metadata"]["concurrent_edit"] = "must survive queued generation"
	var retried := CCFRichAuthoringServiceV0190.apply_split_result(
		current_retry_project,
		batch_id,
		{
			"members": [{
				"character_id": failed_id,
				"description": "A reckless salvage diver.",
				"personality": "Bold, impatient, and unexpectedly scholarly.",
				"scenario": "{{user}} joins a dangerous archive dive.",
				"first_message": "Keep the rope tight and the lantern dry.",
				"example_dialogue": "{{char}}: The lower stacks are still breathing.",
				"creator_notes": "Independent member.",
				"system_prompt": "Preserve this member's voice.",
				"post_history_instructions": "Track air and recovered pages."
			}]
		},
		{"model": "fixture-model", "requested_character_ids": [failed_id]}
	)
	var retried_project: Dictionary = retried.get("project", {})
	var retried_batch := CCFRichAuthoringServiceV0190.split_batch(
		retried_project, batch_id
	)
	var retry_attempts: Dictionary = {}
	for raw_retry_member in retried_batch.get("members", []):
		if raw_retry_member is Dictionary:
			retry_attempts[str(raw_retry_member.get("character_id", ""))] = int(
				raw_retry_member.get("attempts", 0)
			)
	if not _require(
		bool(retried.get("ok", false))
		and not bool(retried.get("partial", true))
		and str(retried_batch.get("status", "")) == "completed"
		and int(retry_attempts.get(successful_id, 0)) == 1
		and int(retry_attempts.get(failed_id, 0)) == 2
		and str(retried_project.get("metadata", {}).get("concurrent_edit", ""))
		== "must survive queued generation",
		"A member retry must use cumulative completion, increment only the retried member and preserve newer project edits."
	):
		return

	var invalid_split := CCFRichAuthoringServiceV0190.create_split_batch(
		project,
		"Two incomplete fixtures.",
		[
			{"name": "Invalid One", "role": "fixture"},
			{"name": "Invalid Two", "role": "fixture"}
		]
	)
	var invalid_project: Dictionary = invalid_split.get("project", {})
	var invalid_batch: Dictionary = invalid_split.get("batch", {})
	var invalid_ids: Array[String] = []
	var invalid_outputs: Array = []
	for raw_invalid_member in invalid_batch.get("members", []):
		if raw_invalid_member is Dictionary:
			var invalid_id := str(raw_invalid_member.get("character_id", ""))
			invalid_ids.append(invalid_id)
			invalid_outputs.append({"character_id": invalid_id, "description": "Incomplete"})
	var invalid_applied := CCFRichAuthoringServiceV0190.apply_split_result(
		invalid_project,
		str(invalid_batch.get("batch_id", "")),
		{"members": invalid_outputs},
		{"requested_character_ids": invalid_ids}
	)
	var retained_invalid_batch := CCFRichAuthoringServiceV0190.split_batch(
		invalid_applied.get("project", {}), str(invalid_batch.get("batch_id", ""))
	)
	var retained_failure_count := 0
	for raw_failed_member in retained_invalid_batch.get("members", []):
		if (
			raw_failed_member is Dictionary
			and str(raw_failed_member.get("status", "")) == "failed"
			and int(raw_failed_member.get("attempts", 0)) == 1
			and not str(raw_failed_member.get("error", "")).is_empty()
		):
			retained_failure_count += 1
	if not _require(
		bool(invalid_applied.get("ok", false))
		and (invalid_applied.get("completed_character_ids", []) as Array).is_empty()
		and retained_failure_count == 2,
		"An all-invalid provider response must retain member failures and attempts for review and retry."
	):
		return

	first = CCFStorageService.get_character(project, first_id)
	CCFRichAuthoringServiceV0190.set_private_custom_metadata(
		first,
		{"rating_note": "author-only", "public_hook": {"kind": "mystery"}},
		[{"source_key": "public_hook", "target_key": "example.org/story_hook"}]
	)
	CCFStorageService.update_character(project, first)
	var mapping_preview := CCFRichAuthoringServiceV0190.mapped_export_preview(first)
	var exported := CCFCardFormatService.export_character_v2(project, first_id)
	var exported_text := JSON.stringify(exported)
	var dependency_rows := CCFRichAuthoringServiceV0190.dependency_report(project)
	if not _require(
		mapping_preview.get("mapped_extensions", {}).has("example.org/story_hook")
		and mapping_preview.get("private_unmapped_keys", []).has("rating_note")
		and exported.get("data", {}).get("extensions", {}).has("example.org/story_hook")
		and not exported_text.contains("author-only")
		and not exported_text.contains(CCFRichAuthoringServiceV0190.CHARACTER_KEY)
		and not dependency_rows.is_empty()
		and not CCFRichAuthoringServiceV0190.deletion_warnings(
			project, "world", "world_port"
		).is_empty(),
		"Private custom fields must remain private unless explicitly mapped, and dependency inspection must warn about referenced worlds."
	):
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	var app := packed.instantiate()
	get_root().add_child(app)
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	var version_found := false
	for node in app.find_children("*", "Label", true, false):
		if node is Label and node.text in [
			"Godot rewrite • v0.19.0", "Godot rewrite • v0.19.1",
			"Godot rewrite • v0.19.2", "Godot rewrite • v0.19.3",
			"Godot rewrite • v0.19.3-hotfix1", "Godot rewrite • v0.19.4",
			"Godot rewrite • v0.19.5", "Godot rewrite • v0.20.0"
		]:
			version_found = true
			break
	if not _require(
		workspace_value is CCFWorkspaceV0190View
		and workspace_value.get("_generation_service") is CCFGenerationServiceV0190
		and workspace_value.get("_card_workflow_window") is CCFCardWorkflowWindowV0190
		and _find_button(workspace_value, "Rich Authoring") != null
		and _find_button(workspace_value, "Card Workflows") != null
		and version_found,
		"The live v0.19.0 app must install Rich Authoring, upgraded Card Workflows and the current generation service."
	):
		return
	app.queue_free()
	await process_frame
	print("V0190_RICH_AUTHORING_OK")
	quit(0)
