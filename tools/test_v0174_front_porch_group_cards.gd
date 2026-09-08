extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0174_FRONT_PORCH_GROUP_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var project := CCFStorageService.new_project()
	var characters: Array = project.get("characters", [])
	var first: Dictionary = characters[0]
	var first_id := str(first.get("character_id", ""))
	first["character"]["name"] = "Aster"
	first["metadata"]["name"] = "Aster"
	first["character"]["description"] = "A careful archivist."
	characters[0] = first
	var second := CCFStorageService.new_character_record("Bram")
	var second_id := str(second.get("character_id", ""))
	second["character"]["description"] = "A cheerful expedition guide."
	characters.append(second)
	project["characters"] = characters
	var options := CCFFrontPorchGroupCardServiceV0174.default_group_options(
		project, {"selected_character_ids": [first_id, second_id]}
	)
	options["turn_order"] = "random"
	options["director_mode"] = true
	options["system_prompt"] = "Keep both characters active while preserving {{user}} agency."
	options["character_system_prompts"] = {
		first_id: "Aster tracks discoveries.", second_id: "Bram keeps the expedition moving."
	}
	options["member_objectives"] = {
		first_id: [{"title": "Catalogue the ruin", "description": "Record its history.", "status": "active", "priority": 4}],
		second_id: [{"title": "Protect the party", "description": "Guide everyone home.", "status": "active", "priority": 5}]
	}
	options["extensions"] = {"future_group_feature": {"enabled": true}}
	options["preserved_fields"] = {"future_top_level": "keep-me"}
	var workflow := {
		"workflow_id": "workflow_group_regression",
		"mode": "group_card",
		"title": "Archive Expedition",
		"selected_character_ids": [first_id, second_id],
		"shared_scenario": "The group enters a sealed archive.",
		"opening_message": "The doors open with a sigh.",
		"front_porch_group": options
	}
	var built := CCFFrontPorchGroupCardServiceV0174.build_group_payload(project, workflow)
	if not _require(bool(built.get("ok", false)), "A valid group workflow must build a payload."):
		return
	var payload: Dictionary = built.get("payload", {})
	var report: Dictionary = built.get("report", {})
	var raw_members: Array = payload.get("raw_member_data", [])
	if not _require(
		bool(report.get("ok", false))
		and str(payload.get("spec", "")) == "front_porch_group_card"
		and str(payload.get("spec_version", "")) == "1.0"
		and str(payload.get("turn_order", "")) == "random"
		and bool(payload.get("director_mode", false))
		and str(payload.get("future_top_level", "")) == "keep-me"
		and raw_members.size() == 2
		and payload.get("members", []).size() == 2,
		"The payload must match Front Porch 1.0 and preserve future top-level data."
	):
		return
	for raw_value in raw_members:
		var raw_member: Dictionary = raw_value
		var avatar := Marshalls.base64_to_raw(str(raw_member.get("avatar_base64", "")))
		if not _require(
			avatar.size() > 8
			and avatar.slice(0, 8) == CCFFrontPorchGroupCardServiceV0174.PNG_SIGNATURE
			and not str(raw_member.get("_original_stable_id", "")).is_empty(),
			"Every exported group member must carry a full PNG avatar and stable ID."
		):
			return

	var output_path := "user://v0174_group_roundtrip.png"
	var written := CCFFrontPorchGroupCardServiceV0174.write_group_card(
		output_path, project, workflow
	)
	if not _require(bool(written.get("ok", false)), "The portable group PNG must be written."):
		return
	var loaded := CCFFrontPorchGroupCardServiceV0174.load_group_card(output_path)
	if not _require(
		bool(loaded.get("ok", false))
		and str(loaded.get("payload", {}).get("name", "")) == "Archive Expedition",
		"The fpa_group PNG must load back losslessly."
	):
		return

	var imported := CCFFrontPorchGroupCardServiceV0174.import_group_to_project(
		loaded.get("payload", {}), output_path
	)
	if not _require(bool(imported.get("ok", false)), "The group PNG payload must import as a project."):
		return
	var imported_project: Dictionary = imported.get("project", {})
	var id_map: Dictionary = imported.get("id_map", {})
	var imported_workflows: Array = imported_project.get("card_workflows", [])
	var imported_workflow: Dictionary = imported_workflows[0]
	var imported_options: Dictionary = imported_workflow.get("front_porch_group", {})
	var imported_prompts: Dictionary = imported_options.get("character_system_prompts", {})
	var imported_objectives: Dictionary = imported_options.get("member_objectives", {})
	var mapped_first := str(id_map.get(first_id, ""))
	var mapped_second := str(id_map.get(second_id, ""))
	if not _require(
		imported_project.get("characters", []).size() == 2
		and str(imported_workflow.get("mode", "")) == "group_card"
		and mapped_first != first_id and mapped_second != second_id
		and imported_prompts.has(mapped_first) and imported_prompts.has(mapped_second)
		and imported_objectives.has(mapped_first) and imported_objectives.has(mapped_second)
		and not imported_prompts.has(first_id)
		and str(imported_options.get("preserved_fields", {}).get("future_top_level", "")) == "keep-me"
		and bool(imported_options.get("extensions", {}).get("future_group_feature", {}).get("enabled", false)),
		"Import must remap stable-ID keyed fields while preserving unknown group data."
	):
		return
	for imported_character in imported_project.get("characters", []):
		var portrait := str(imported_character.get("assets", {}).get("portrait", ""))
		var resolved := CCFStorageService.project_folder(
			str(imported_project.get("project_id", ""))
		).path_join(portrait)
		if not _require(
			not portrait.is_empty() and FileAccess.file_exists(resolved),
			"Imported group member artwork must be saved and assigned as the portrait."
		):
			return

	var duplicate_payload := payload.duplicate(true)
	var duplicate_members: Array = duplicate_payload.get("raw_member_data", [])
	duplicate_members[1]["_original_stable_id"] = duplicate_members[0]["_original_stable_id"]
	duplicate_payload["raw_member_data"] = duplicate_members
	if not _require(
		not bool(CCFFrontPorchGroupCardServiceV0174.validate_group_payload(duplicate_payload).get("ok", true)),
		"Duplicate Front Porch stable member IDs must be rejected."
	):
		return
	var duplicate_id_map := {first_id: "duplicate-first", second_id: "duplicate-second"}
	var remapped_workflow := CCFStorageService._remap_front_porch_group_workflow_v0174(
		workflow, duplicate_id_map
	)
	var remapped_options: Dictionary = remapped_workflow.get("front_porch_group", {})
	var remapped_baseline = JSON.parse_string(str(remapped_options.get("baseline_realism_state", "")))
	if not _require(
		remapped_options.get("character_system_prompts", {}).has("duplicate-first")
		and remapped_options.get("member_objectives", {}).has("duplicate-second")
		and remapped_baseline is Dictionary
		and remapped_baseline.has("duplicate-first")
		and not remapped_baseline.has(first_id),
		"Project duplication must remap Front Porch member-keyed workflow settings."
	):
		return

	var generator := CCFGenerationServiceV0174.new()
	var queued := generator.queue_front_porch_group_generation_v0174(
		project, [first_id, second_id], "Keep the tone adventurous.",
		{"name": "Offline", "base_url": "http://127.0.0.1:1/v1", "model": "offline", "max_output_tokens": 2048}, 0
	)
	var queue: Array = generator.get("_queue")
	var queued_job: Dictionary = queue[0]
	var prompt_text := JSON.stringify(queued_job.get("payload", {}).get("messages", []))
	if not _require(
		bool(queued.get("ok", false))
		and str(queued_job.get("type", "")) == "front_porch_group_generation_v0174"
		and prompt_text.contains(first_id) and prompt_text.contains(second_id)
		and prompt_text.contains("agency"),
		"Group AI drafting must use exact member IDs and preserve user agency."
	):
		return
	generator.free()

	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.17.4 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		app.has_method("_update_build_version_label_v0174")
		and app.has_method("_update_build_version_label_v0173_hotfix1")
		and workspace_value is CCFWorkspaceV0174View,
		"The live shell must install v0.17.4 on top of the OpenRouter hotfix."
	):
		return
	var capabilities := (workspace_value as CCFWorkspaceV0174View).front_porch_group_capabilities_v0174()
	if not _require(
		bool(capabilities.get("portable_import", false))
		and bool(capabilities.get("portable_export", false))
		and not bool(capabilities.get("direct_database_writes", true))
		and not bool(capabilities.get("direct_group_install", true)),
		"The live UI must expose portable group import/export without database writes."
	):
		return
	app.queue_free()
	await process_frame
	print("v0.17.4 Front Porch group-card regression passed")
	quit(0)
