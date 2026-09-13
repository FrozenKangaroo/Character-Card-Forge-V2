extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0181_REVISION_SAFETY_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var character_record := CCFStorageService.get_character(project, character_id)
	var card: Dictionary = character_record.get("character", {}).duplicate(true)
	card["description"] = "Original description"
	card["alternate_greetings"] = ["Hello", "Welcome"]
	card["character_book"] = {
		"entries": [{"keys": ["harbour"], "content": "Original lore"}]
	}
	card["card_extensions"] = {"vendor/example": {"future": true}}
	character_record["character"] = card
	var assets: Dictionary = character_record.get("assets", {}).duplicate(true)
	assets["portrait"] = "characters/%s/assets/portrait.png" % character_id
	character_record["assets"] = assets
	_replace_character(project, character_record)

	var first := CCFRevisionServiceV0181.create_checkpoint(
		character_record, "Original", "Before edits", "manual"
	)
	if not _require(
		bool(first.get("created", false)),
		"The first meaningful checkpoint must be created."
	):
		return
	var first_id := str(first.get("revision", {}).get("revision_id", ""))
	var changed_card: Dictionary = character_record.get("character", {}).duplicate(true)
	changed_card["description"] = "Current description"
	changed_card["alternate_greetings"] = ["Hello", "Welcome back", "Good evening"]
	changed_card["character_book"] = {
		"entries": [{"keys": ["harbour"], "content": "Revised lore"}]
	}
	changed_card["card_extensions"] = {"vendor/example": {"future": false, "new": 3}}
	character_record["character"] = changed_card
	var original_revision := CCFRevisionServiceV0181.get_revision(
		character_record, first_id
	)
	if not _require(
		str(original_revision.get("snapshot", {}).get("character", {}).get("description", ""))
		== "Original description",
		"Revision snapshots must remain immutable after the live character changes."
	):
		return
	var duplicate_result := CCFRevisionServiceV0181.create_checkpoint(
		character_record, "Current", "", "save"
	)
	var duplicate_again := CCFRevisionServiceV0181.create_checkpoint(
		character_record, "Current again", "", "save"
	)
	if not _require(
		bool(duplicate_result.get("created", false))
		and bool(duplicate_again.get("duplicate", false)),
		"Identical automatic checkpoints must be deduplicated."
	):
		return
	var current_snapshot := CCFRevisionServiceV0181.snapshot_character(character_record)
	var original_snapshot: Dictionary = original_revision.get("snapshot", {})
	var differences := CCFRevisionServiceV0181.compare_snapshots(
		original_snapshot, current_snapshot
	)
	var changed_paths: Array[String] = []
	for difference in differences:
		changed_paths.append(str(difference.get("path", "")))
	if not _require(
		changed_paths.has("character.description")
		and changed_paths.has("character.alternate_greetings")
		and changed_paths.has("character.character_book.entries")
		and changed_paths.has("character.card_extensions.vendor/example.future")
		and changed_paths.has("character.card_extensions.vendor/example.new"),
		"The field-aware diff must cover core text, greetings, lorebooks and vendor extensions."
	):
		return
	if not _require(
		str(original_snapshot.get("assets", {}).get("portrait", ""))
		== "characters/%s/assets/portrait.png" % character_id,
		"Checkpoints must retain content-addressed asset references instead of embedding copies."
	):
		return

	_replace_character(project, character_record)
	var selective := CCFRevisionServiceV0181.apply_selected_paths(
		project, character_id, first_id, ["character.description"]
	)
	var selectively_merged := CCFStorageService.get_character(project, character_id)
	if not _require(
		bool(selective.get("ok", false))
		and str(selectively_merged.get("character", {}).get("description", ""))
		== "Original description"
		and selectively_merged.get("character", {}).get("alternate_greetings", []).size()
		== 3,
		"Selective merge must apply only checked paths and preserve unchecked fields."
	):
		return
	var pre_restore_count := CCFRevisionServiceV0181.list_revisions(
		selectively_merged
	).size()
	var restored := CCFRevisionServiceV0181.restore_revision(
		project, character_id, first_id
	)
	var restored_character := CCFStorageService.get_character(project, character_id)
	var restored_revisions := CCFRevisionServiceV0181.list_revisions(
		restored_character
	)
	if not _require(
		bool(restored.get("ok", false))
		and str(restored_character.get("character", {}).get("description", ""))
		== "Original description"
		and restored_revisions.size() == pre_restore_count + 2
		and str(restored_revisions[-2].get("reason", "")) == "pre_restore"
		and str(restored_revisions[-1].get("reason", "")) == "restore",
		"Restore must preserve the current state and append a new restored revision."
	):
		return

	var forked := CCFRevisionServiceV0181.fork_revision(
		project, character_id, first_id, "Original Fork"
	)
	var forked_id := str(forked.get("character_id", ""))
	var forked_character := CCFStorageService.get_character(project, forked_id)
	if not _require(
		bool(forked.get("ok", false))
		and not forked_id.is_empty()
		and forked_id != character_id
		and str(forked_character.get("character", {}).get("name", ""))
		== "Original Fork"
		and str(forked_character.get("revision_lineage", {}).get("source_revision_id", ""))
		== first_id,
		"Forking must create a new character with private source lineage."
	):
		return
	var related_card: Dictionary = forked_character.get("character", {}).duplicate(true)
	related_card["description"] = "Description copied from a related card"
	forked_character["character"] = related_card
	_replace_character(project, forked_character)
	var related_merge := CCFRevisionServiceV0181.apply_selected_snapshot(
		project,
		character_id,
		CCFRevisionServiceV0181.snapshot_character(forked_character),
		["character.description"],
		"Original Fork • Current",
		{"source_character_id": forked_id}
	)
	restored_character = CCFStorageService.get_character(project, character_id)
	if not _require(
		bool(related_merge.get("ok", false))
		and str(restored_character.get("character", {}).get("description", ""))
		== "Description copied from a related card",
		"Selective merge must also accept an explicitly selected related-card snapshot."
	):
		return

	CCFRevisionServiceV0181.configure_history(restored_character, 5, false)
	for index in range(8):
		var loop_card: Dictionary = restored_character.get("character", {}).duplicate(true)
		loop_card["description"] = "Retention edit %d" % index
		restored_character["character"] = loop_card
		CCFRevisionServiceV0181.create_checkpoint(
			restored_character, "Retention %d" % index, "", "test", {}, true
		)
	_replace_character(project, restored_character)
	var packaged := CCFRevisionServiceV0181.project_for_package(project)
	var packaged_character := CCFStorageService.get_character(packaged, character_id)
	if not _require(
		CCFRevisionServiceV0181.list_revisions(restored_character).size() == 5
		and not packaged_character.has("revision_history")
		and project.get("characters", [])[0].has("revision_history"),
		"Retention must prune old entries and package exclusion must not mutate the live project."
	):
		return
	var package_path := "user://v0181-history-policy.ccfproject"
	var package_result := CCFProjectPackageService.export_project(
		project, package_path
	)
	var package_reader := ZIPReader.new()
	if not _require(
		bool(package_result.get("ok", false))
		and package_reader.open(package_path) == OK,
		"Portable project export must support revision inclusion controls."
	):
		return
	var packaged_json: Variant = JSON.parse_string(
		package_reader.read_file("project/character.json").get_string_from_utf8()
	)
	package_reader.close()
	if not _require(
		packaged_json is Dictionary
		and not CCFStorageService.get_character(
			packaged_json as Dictionary, character_id
		).has("revision_history")
		and int(package_result.get("manifest", {}).get(
			"revision_history_character_count", -1
		)) == 1,
		"The actual package payload and manifest must report only included histories."
	):
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.18.1 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		workspace_value is CCFWorkspaceV0181View,
		"The live app must install the v0.18.1 Workspace."
	):
		return
	var workspace := workspace_value as CCFWorkspaceV0181View
	var revision_window_value: Variant = workspace.get("_revision_window_v0181")
	var revision_button_value: Variant = workspace.get("_revision_button_v0181")
	if not _require(
		revision_window_value is CCFRevisionHistoryWindowV0181
		and revision_button_value is Button
		and (revision_button_value as Button).text == "Revision History",
		"The Workspace must expose the revision history window and navigation action."
	):
		return
	var version_found := false
	for node in app.find_children("*", "Label", true, false):
		if node is Label and (
			node.text.begins_with("Godot rewrite • v0.18")
			or node.text.begins_with("Godot rewrite • v0.19")
			or node.text.begins_with("Godot rewrite • v0.20")
		):
			version_found = true
			break
	if not _require(
		version_found,
		"The build label must identify a supported v0.18/v0.19/v0.20 line."
	):
		return
	app.queue_free()
	await process_frame
	print("v0.18.1 revision safety regression passed")
	quit(0)


func _replace_character(project: Dictionary, character_record: Dictionary) -> void:
	var character_id := str(character_record.get("character_id", ""))
	var index := CCFStorageService.character_index(project, character_id)
	var characters: Array = project.get("characters", []).duplicate(true)
	characters[index] = character_record.duplicate(true)
	project["characters"] = characters
