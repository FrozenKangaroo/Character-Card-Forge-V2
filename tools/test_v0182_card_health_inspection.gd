extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0182_CARD_INSPECTION_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _has_finding(report: Dictionary, code: String) -> bool:
	for finding in report.get("findings", []):
		if str(finding.get("code", "")) == code:
			return true
	return false


func _run() -> void:
	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var character_record := CCFStorageService.get_character(project, character_id)
	var long_text := "A deliberately repeated and oversized authored section. ".repeat(190)
	var card: Dictionary = character_record.get("character", {}).duplicate(true)
	card["name"] = "Inspector Test"
	card["description"] = long_text
	card["personality"] = long_text
	card["scenario"] = "A quiet observatory at midnight."
	card["first_message"] = "The telescope turns toward {{user}}."
	card["example_dialogue"] = "<START>\n{{char}}: Look at the stars."
	card["system_prompt"] = "Keep characterization consistent."
	card["alternate_greetings"] = ["Welcome to the observatory.", "Welcome to the observatory."]
	card["character_book"] = {
		"entries": [{
			"name": "Observatory",
			"keys": ["stars", "telescope"],
			"content": "The observatory stands above the cloud line."
		}]
	}
	card["card_extensions"] = {"vendor/future": {"mode": "preserve"}}
	character_record["character"] = card
	var metadata: Dictionary = character_record.get("metadata", {}).duplicate(true)
	metadata["name"] = "Inspector Test"
	metadata["tags"] = ["science", "night"]
	character_record["metadata"] = metadata
	character_record["future_private_field"] = {"keep": true}
	character_record["revision_lineage"] = {"source_character_id": "private-source"}
	var assets: Dictionary = character_record.get("assets", {}).duplicate(true)
	assets["portrait"] = "characters/%s/assets/missing.png" % character_id
	character_record["assets"] = assets
	_replace_character(project, character_record)
	project["card_workflows"] = [{
		"workflow_id": "broken-group",
		"selected_character_ids": [character_id, "missing-member"]
	}]
	var preserved_save := CCFStorageService.save_project(project)
	var preserved_load := CCFStorageService.load_project(str(project.get("project_id", "")))
	if not _require(
		bool(preserved_save.get("ok", false))
		and bool(preserved_load.get("ok", false))
		and preserved_load.get("data", {}).get("card_workflows", []).size() == 1,
		"Externally introduced missing group references must survive loading so the inspector can repair them."
	):
		return
	project = preserved_load.get("data", {})

	var health := CCFCardInspectionServiceV0182.health_report(project, character_id)
	if not _require(
		bool(health.get("ok", false))
		and not bool(health.get("blocking", true))
		and _has_finding(health, "duplicate_text")
		and _has_finding(health, "duplicate_greeting")
		and _has_finding(health, "oversized_section")
		and _has_finding(health, "missing_asset")
		and _has_finding(health, "missing_group_member")
		and _has_finding(health, "namespaced_custom_metadata"),
		"Health inspection must detect duplicated, oversized, missing-reference and custom metadata issues without blocking unusual cards."
	):
		return

	var tokens := CCFCardInspectionServiceV0182.token_report(project, character_id)
	var token_paths: Array[String] = []
	for section in tokens.get("sections", []):
		token_paths.append(str(section.get("path", "")))
	if not _require(
		int(tokens.get("total_tokens", 0)) > 4000
		and token_paths.has("character.alternate_greetings")
		and token_paths.has("character.character_book")
		and token_paths.has("character.example_dialogue")
		and token_paths.has("character.scenario")
		and token_paths.has("character.system_prompt"),
		"Token inspection must report the whole card and every planned contributing section."
	):
		return
	var compiled := CCFCardInspectionServiceV0182.compiled_prompt_preview(
		project, character_id
	)
	if not _require(
		bool(compiled.get("ok", false))
		and bool(compiled.get("approximate", false))
		and str(compiled.get("text", "")).begins_with("[CCF APPROXIMATION")
		and str(compiled.get("text", "")).contains("RUNTIME ACTIVATION UNKNOWN")
		and compiled.get("runtime_dependencies", []).size() >= 4,
		"Compiled prompt preview must prominently distinguish CCF approximation from runtime-dependent behavior."
	):
		return

	var technical := CCFCardInspectionServiceV0182.technical_metadata(
		project, character_id
	)
	if not _require(
		str(technical.get("card_spec", "")) == CCFCardFormatService.FORMAT_V2
		and str(technical.get("card_spec_version", "")) == CCFCardFormatService.SPEC_VERSION_V2
		and technical.get("extension_keys", []).has("vendor/future")
		and technical.get("private_internal_keys", []).has("revision_lineage"),
		"Technical metadata must expose format, extension and private-boundary information separately from Raw JSON."
	):
		return

	var raw_text := CCFCardInspectionServiceV0182.raw_character_json(
		project, character_id
	)
	if not _require(
		not raw_text.contains("revision_lineage")
		and not raw_text.contains("revision_history"),
		"Expert Raw JSON must hide CCF-managed private revision data."
	):
		return
	var parsed_raw: Dictionary = JSON.parse_string(raw_text)
	parsed_raw["character"]["description"] = "Validated expert edit"
	var applied_raw := CCFCardInspectionServiceV0182.apply_raw_character_json(
		project, character_id, JSON.stringify(parsed_raw, "  ")
	)
	project = applied_raw.get("project", {})
	character_record = CCFStorageService.get_character(project, character_id)
	if not _require(
		bool(applied_raw.get("ok", false))
		and str(character_record.get("character", {}).get("description", ""))
		== "Validated expert edit"
		and str(character_record.get("revision_lineage", {}).get("source_character_id", ""))
		== "private-source"
		and CCFRevisionServiceV0181.list_revisions(character_record).size() == 2,
		"Raw JSON apply must preserve private lineage and add before/after revision checkpoints."
	):
		return
	parsed_raw["character_id"] = "changed-id"
	var invalid_raw := CCFCardInspectionServiceV0182.validate_raw_character_json(
		JSON.stringify(parsed_raw), character_id
	)
	if not _require(
		not bool(invalid_raw.get("ok", true))
		and "; ".join(invalid_raw.get("errors", [])).contains("cannot be changed"),
		"Raw JSON validation must reject identity changes before apply."
	):
		return

	var replacement_path := "user://replacement.png"
	var replacement := FileAccess.open(replacement_path, FileAccess.WRITE)
	replacement.store_buffer(PackedByteArray([137, 80, 78, 71]))
	replacement.close()
	var missing_report := CCFCardInspectionServiceV0182.missing_asset_report(
		project, character_id
	)
	var relinked := CCFCardInspectionServiceV0182.relink_asset(
		project,
		character_id,
		missing_report.get("missing", [])[0],
		replacement_path
	)
	project = relinked.get("project", {})
	character_record = CCFStorageService.get_character(project, character_id)
	var relinked_path := str(character_record.get("assets", {}).get("portrait", ""))
	if not _require(
		bool(relinked.get("ok", false))
		and relinked_path.begins_with("characters/%s/assets/relinked_" % character_id)
		and FileAccess.file_exists(
			CCFStorageService.project_folder(str(project.get("project_id", ""))).path_join(relinked_path)
		),
		"Missing Asset repair must copy replacements into managed portable project storage."
	):
		return
	var group_missing: Dictionary = {}
	for missing_item_value in missing_report.get("missing", []):
		if str(missing_item_value.get("kind", "")) == "group_member":
			group_missing = missing_item_value
			break
	var group_repaired := CCFCardInspectionServiceV0182.repair_group_member(
		project, group_missing, character_id
	)
	project = group_repaired.get("project", {})
	if not _require(
		bool(group_repaired.get("ok", false))
		and str(project.get("card_workflows", [])[0].get("selected_character_ids", [])[0])
		== character_id
		and project.get("card_workflows", [])[0].get("selected_character_ids", []).size()
		== 1,
		"Missing group members must be repairable with an explicitly selected existing character."
	):
		return

	var checklist_before := CCFCardInspectionServiceV0182.checklist_report(
		project, character_id
	)
	var checklist_settings: Dictionary = checklist_before.get("settings", {})
	checklist_settings["manual_review_complete"] = true
	checklist_settings["test_complete"] = true
	var enabled: Dictionary = checklist_settings.get("enabled", {})
	enabled["lore"] = true
	enabled["test_status"] = true
	checklist_settings["enabled"] = enabled
	var checklist_saved := CCFCardInspectionServiceV0182.save_checklist_settings(
		project, character_id, checklist_settings
	)
	project = checklist_saved.get("project", {})
	var checklist_after := CCFCardInspectionServiceV0182.checklist_report(
		project, character_id
	)
	if not _require(
		bool(checklist_saved.get("ok", false))
		and bool(checklist_after.get("settings", {}).get("manual_review_complete", false))
		and bool(checklist_after.get("settings", {}).get("test_complete", false)),
		"The per-character quality checklist must retain custom enabled checks, review and optional test status."
	):
		return
	var exported := CCFCardFormatService.export_character_v2(project, character_id)
	var exported_custom: Dictionary = exported.get("data", {}).get("extensions", {}).get(
		CCFCardFormatService.CCF_EXTENSION_KEY, {}
	).get("custom", {}).get("top_level", {})
	if not _require(
		not exported_custom.has("revision_history")
		and not exported_custom.has("revision_lineage")
		and not exported_custom.has(CCFCardInspectionServiceV0182.INSPECTION_KEY),
		"Revision provenance and private checklist state must not enter ordinary Character Card export."
	):
		return

	var legacy_card := {
		"name": "Legacy Inspector",
		"description": "Imported description",
		"personality": "Imported personality",
		"scenario": "Imported scenario",
		"first_mes": "Imported greeting",
		"mes_example": "Imported example"
	}
	var import_path := "user://v0182-legacy-card.json"
	var import_file := FileAccess.open(import_path, FileAccess.WRITE)
	import_file.store_string(JSON.stringify(legacy_card, "  "))
	import_file.close()
	var inspection := CCFCardInspectionServiceV0182.import_inspection(import_path)
	if not _require(
		bool(inspection.get("ok", false))
		and str(inspection.get("detected_format", "")) == CCFCardFormatService.FORMAT_V1
		and int(inspection.get("token_report", {}).get("total_tokens", 0)) > 0
		and inspection.get("loss_mapping", []).size() >= 3
		and str(inspection.get("migration", {}).get("target", "")).contains("Character Card V2"),
		"Import preview must include format/version, size, validation and migration/loss mapping."
	):
		return
	var copy_result := CCFCardInspectionServiceV0182.apply_import_to_current_project(
		project, character_id, inspection, "copy"
	)
	if not _require(
		bool(copy_result.get("ok", false))
		and copy_result.get("project", {}).get("characters", []).size()
		== project.get("characters", []).size() + 1,
		"Reviewed imports must support a non-destructive copy in the current project."
	):
		return
	var merge_result := CCFCardInspectionServiceV0182.apply_import_to_current_project(
		project, character_id, inspection, "merge"
	)
	var merged_character := CCFStorageService.get_character(
		merge_result.get("project", {}), character_id
	)
	if not _require(
		bool(merge_result.get("ok", false))
		and str(merged_character.get("character", {}).get("description", ""))
		== "Imported description"
		and CCFRevisionServiceV0181.list_revisions(merged_character).size() >= 2,
		"Reviewed merge must apply imported non-empty fields behind revision recovery."
	):
		return
	var replace_result := CCFCardInspectionServiceV0182.apply_import_to_current_project(
		project, character_id, inspection, "replace"
	)
	var replaced_character := CCFStorageService.get_character(
		replace_result.get("project", {}), character_id
	)
	if not _require(
		bool(replace_result.get("ok", false))
		and str(replaced_character.get("character", {}).get("name", ""))
		== "Legacy Inspector"
		and str(replaced_character.get("character_id", "")) == character_id
		and CCFRevisionServiceV0181.list_revisions(replaced_character).size() >= 2,
		"Reviewed replacement must preserve the target identity and recovery history."
	):
		return

	var imported_project: Dictionary = inspection.get("imported_project", {})
	CCFStorageService.save_project(imported_project)
	var duplicate_inspection := CCFCardInspectionServiceV0182.import_inspection(
		import_path
	)
	if not _require(
		duplicate_inspection.get("duplicate_evidence", []).size() >= 1
		and bool(duplicate_inspection.get("duplicate_evidence", [])[0].get("exact_content", false)),
		"Import preview must surface exact duplicate evidence from the saved library."
	):
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.18.2 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		workspace_value is CCFWorkspaceV0182View,
		"The live app must install the v0.18.2 Workspace."
	):
		return
	var workspace := workspace_value as CCFWorkspaceV0182View
	var inspector_value: Variant = workspace.get("_card_inspector_v0182")
	var inspector_button_value: Variant = workspace.get("_card_inspector_button_v0182")
	var import_window_value: Variant = workspace.get("_import_export_window")
	if not _require(
		inspector_value is CCFCardInspectorWindowV0182
		and inspector_button_value is Button
		and (inspector_button_value as Button).text == "Card Inspector"
		and import_window_value is CCFImportExportWindowV0182,
		"The live Workspace must expose Card Inspector and the richer reviewed import window."
	):
		return
	var inspector := inspector_value as CCFCardInspectorWindowV0182
	var tabs_found := false
	for node in inspector.find_children("*", "TabContainer", true, false):
		if node is TabContainer and node.get_tab_count() == 6:
			tabs_found = true
			break
	var version_found := false
	for node in app.find_children("*", "Label", true, false):
		if node is Label and node.text == "Godot rewrite • v0.18.2":
			version_found = true
			break
	if not _require(
		tabs_found and version_found,
		"The live inspector must provide six separated areas and the build label must identify v0.18.2."
	):
		return
	app.queue_free()
	await process_frame
	print("v0.18.2 Card Health and Interchange Inspection regression passed")
	quit(0)


func _replace_character(project: Dictionary, character_record: Dictionary) -> void:
	var character_id := str(character_record.get("character_id", ""))
	var index := CCFStorageService.character_index(project, character_id)
	var characters: Array = project.get("characters", []).duplicate(true)
	characters[index] = character_record.duplicate(true)
	project["characters"] = characters
