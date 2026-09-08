extends SceneTree

const OUTPUT_PATH := "user://v0175_hotfix2_export_safety.json"


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0175_HOTFIX2_EXPORT_SAFETY_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	if FileAccess.file_exists(OUTPUT_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(OUTPUT_PATH))
	var blank_project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(blank_project)
	var blank_document := CCFStorageService.character_workspace_document(
		blank_project, character_id
	)
	CCFStorageService.set_value_at_path(
		blank_document,
		"metadata.name",
		"Concept Only"
	)
	CCFStorageService.set_value_at_path(
		blank_document,
		"character.name",
		"Concept Only"
	)
	CCFStorageService.set_value_at_path(
		blank_document,
		"concept.prompt",
		"A detailed generation concept that has not been materialised yet."
	)
	CCFStorageService.update_character(blank_project, blank_document)

	var blocked_report := CCFCardFormatService.export_safety_report(
		blank_project, character_id
	)
	if not _require(
		not bool(blocked_report.get("can_export", true))
		and bool(blocked_report.get("all_core_fields_empty", false))
		and not bool(blocked_report.get("has_image", true))
		and "; ".join(blocked_report.get("errors", [])).contains("Generate Character"),
		"A concept-only character must be recognised as an incomplete generation draft."
	):
		return
	var blocked_export := CCFCardFormatService.export_json(
		blank_project, character_id, OUTPUT_PATH
	)
	if not _require(
		not bool(blocked_export.get("ok", true))
		and not FileAccess.file_exists(OUTPUT_PATH),
		"Service-level JSON export must fail before writing an all-empty core card."
	):
		return

	var text_only_project := blank_project.duplicate(true)
	var text_document := CCFStorageService.character_workspace_document(
		text_only_project, character_id
	)
	CCFStorageService.set_value_at_path(
		text_document,
		"character.description",
		"A completed description is sufficient to distinguish this from a concept-only draft."
	)
	CCFStorageService.update_character(text_only_project, text_document)
	var text_only_report := CCFCardFormatService.export_safety_report(
		text_only_project, character_id
	)
	if not _require(
		bool(text_only_report.get("can_export", false))
		and not bool(text_only_report.get("has_image", true))
		and text_only_report.get("warnings", []).size() == 1,
		"A character with any core authored field must be exportable with a missing-image warning."
	):
		return
	var text_export := CCFCardFormatService.export_json(
		text_only_project, character_id, OUTPUT_PATH
	)
	if not _require(
		bool(text_export.get("ok", false)) and FileAccess.file_exists(OUTPUT_PATH),
		"The missing-image warning must remain non-blocking after explicit confirmation at the UI boundary."
	):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OUTPUT_PATH))

	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.35, 0.55, 0.82, 1.0))
	var image_relative := "characters/%s/generated_images/export-safety.png" % character_id
	var image_absolute := CCFStorageService.project_folder(
		str(text_only_project.get("project_id", ""))
	).path_join(image_relative)
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(image_absolute.get_base_dir())
	)
	if not _require(
		image.save_png(ProjectSettings.globalize_path(image_absolute)) == OK,
		"The export-safety image fixture must save."
	):
		return
	var image_document := CCFStorageService.character_workspace_document(
		text_only_project, character_id
	)
	CCFStorageService.set_value_at_path(
		image_document,
		"assets.generated_images",
		[{"image_id": "export-safety", "path": image_relative}]
	)
	CCFStorageService.update_character(text_only_project, image_document)
	var image_report := CCFCardFormatService.export_safety_report(
		text_only_project, character_id
	)
	if not _require(
		bool(image_report.get("can_export", false))
		and bool(image_report.get("has_image", false))
		and image_report.get("warnings", []).is_empty(),
		"A usable generated image must satisfy the artwork warning check."
	):
		return

	var blank_with_image := text_only_project.duplicate(true)
	var blank_with_image_document := CCFStorageService.character_workspace_document(
		blank_with_image, character_id
	)
	CCFStorageService.set_value_at_path(
		blank_with_image_document, "character.description", ""
	)
	CCFStorageService.update_character(
		blank_with_image, blank_with_image_document
	)
	var blocked_png := CCFCardFormatService.build_png_card_bytes(
		image_absolute, blank_with_image, character_id
	)
	if not _require(
		not bool(blocked_png.get("ok", true)),
		"Supplying artwork must not bypass the all-empty core-content block."
	):
		return

	var second := CCFStorageService.new_character_record("Second Concept Only")
	var second_id := str(second.get("character_id", ""))
	var characters: Array = text_only_project.get("characters", []).duplicate(true)
	characters.append(second)
	text_only_project["characters"] = characters
	var workflow := {
		"workflow_id": "export_safety_group",
		"mode": "group_card",
		"title": "Safety Group",
		"selected_character_ids": [character_id, second_id],
		"members": [
			{"character_id": character_id, "role_in_output": ""},
			{"character_id": second_id, "role_in_output": ""}
		]
	}
	var blocked_group := CCFFrontPorchGroupCardServiceV0174.build_group_payload(
		text_only_project, workflow
	)
	if not _require(
		not bool(blocked_group.get("ok", true))
		and str(blocked_group.get("error", "")).contains("Second Concept Only"),
		"A group-card export must identify and block an incomplete member."
	):
		return
	var second_document := CCFStorageService.character_workspace_document(
		text_only_project, second_id
	)
	CCFStorageService.set_value_at_path(
		second_document, "character.description", "A completed second member."
	)
	CCFStorageService.update_character(text_only_project, second_document)
	var warned_group := CCFFrontPorchGroupCardServiceV0174.build_group_payload(
		text_only_project, workflow
	)
	if not _require(
		bool(warned_group.get("ok", false))
		and "; ".join(warned_group.get("report", {}).get("warnings", [])).contains(
			"Second Concept Only has no attached, assigned or generated image"
		),
		"A complete group member without artwork must receive a visible placeholder warning."
	):
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The active application scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		workspace_value is CCFWorkspaceV0175View,
		"The live shell must retain the v0.17.5 workspace."
	):
		return
	var workspace := workspace_value as CCFWorkspaceV0175View
	workspace.load_project(
		blank_project, CCFTemplateService.load_template("default"), {}
	)
	await process_frame
	workspace.call("_open_import_export_studio")
	await process_frame
	var window_value: Variant = workspace.get("_import_export_window")
	if not _require(
		window_value is CCFImportExportWindowV0175,
		"The active Import / Export Studio must expose the safety gate."
	):
		return
	var window := window_value as CCFImportExportWindowV0175
	window.call("_request_json_export")
	if not _require(
		bool(window.get("_export_safety_block_v0175").visible)
		and not bool(window.get("_json_save_dialog").visible)
		and str(window.get("_status").text).contains("blocked"),
		"The UI must stop a concept-only JSON export before opening a destination dialog."
	):
		return
	window.get("_export_safety_block_v0175").hide()
	var ui_text_only_project := blank_project.duplicate(true)
	var ui_text_only_document := CCFStorageService.character_workspace_document(
		ui_text_only_project, character_id
	)
	CCFStorageService.set_value_at_path(
		ui_text_only_document,
		"character.description",
		"A completed text-only character awaiting optional artwork."
	)
	CCFStorageService.update_character(
		ui_text_only_project, ui_text_only_document
	)
	workspace.load_project(
		ui_text_only_project,
		CCFTemplateService.load_template("default"),
		{}
	)
	await process_frame
	window.update_project_context(ui_text_only_project, {}, character_id)
	window.call("_request_json_export")
	var ui_warning_visible := bool(window.get("_export_safety_warning_v0175").visible)
	var ui_pending_action := str(window.get("_pending_export_action_v0175"))
	var ui_json_visible := bool(window.get("_json_save_dialog").visible)
	if not _require(
		ui_warning_visible
		and ui_pending_action == "json"
		and not ui_json_visible,
		"A text-only export must pause for explicit missing-image confirmation "
		+ "(warning=%s, pending=%s, json=%s, status=%s, safety=%s)." % [
			ui_warning_visible,
			ui_pending_action,
			ui_json_visible,
			str(window.get("_status").text),
			CCFCardFormatService.export_safety_report(ui_text_only_project, character_id)
		]
	):
		return
	window.call("_confirm_export_safety_v0175")
	await process_frame
	if not _require(
		bool(window.get("_json_save_dialog").visible)
		and str(window.get("_pending_export_action_v0175")).is_empty(),
		"Confirming the artwork warning must continue the exact pending export once."
	):
		return
	window.get("_json_save_dialog").hide()
	app.queue_free()
	await process_frame
	if FileAccess.file_exists(image_absolute):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(image_absolute))
	print("v0.17.5-hotfix2 export safety regression passed")
	quit(0)
