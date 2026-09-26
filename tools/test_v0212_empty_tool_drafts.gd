extends SceneTree


var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	CCFStorageService.ensure_directories()
	var app_scene := load("res://scenes/main.tscn") as PackedScene
	if not _require(app_scene != null, "The current main scene must load."):
		quit(1)
		return
	var app := app_scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame

	var capabilities: Dictionary = app.call(
		"empty_draft_persistence_capabilities_v0212"
	)
	_require(
		bool(capabilities.get("single_empty_character_stays_in_memory", false))
		and bool(capabilities.get("workspace_tools_do_not_persist_drafts", false))
		and bool(capabilities.get("meaningful_save_still_supported", false)),
		"The current shell must disclose the empty tool-draft persistence contract."
	)

	for method_id in ["idea_generator", "collaborator"]:
		app.call("_on_new_project_method_v0201", method_id, "default")
		await process_frame
		await process_frame
		var workspace_value: Variant = app.get("_workspace")
		if not _require(
			workspace_value is CCFWorkspaceCurrent,
			"The current Workspace must host new tool drafts."
		):
			break
		var workspace := workspace_value as CCFWorkspaceCurrent
		var project := workspace.current_project()
		var characters_value: Variant = project.get("characters", [])
		var project_id := str(project.get("project_id", ""))
		var project_path := CCFStorageService.project_folder(project_id).path_join(
			CCFStorageService.PROJECT_FILE
		)
		_require(
			not project_id.is_empty()
			and characters_value is Array
			and (characters_value as Array).size() == 1,
			"A tool draft must remain a stable one-character project in memory."
		)
		_require(
			not FileAccess.file_exists(project_path)
			and CCFStorageService.list_projects().is_empty(),
			"Opening %s must not write an empty project or add a Library row."
			% method_id
		)

	if not _failed:
		var workspace := app.get("_workspace") as CCFWorkspaceCurrent
		var authored := workspace.current_project()
		var active_id := CCFStorageService.active_character_id(authored)
		var character := CCFStorageService.get_character(authored, active_id)
		CCFStorageService.set_value_at_path(
			character,
			"concept.prompt",
			"A deliberately authored concept that should make this draft persist."
		)
		CCFStorageService.update_character(authored, character)
		workspace.load_project(
			authored,
			CCFTemplateService.load_template("default"),
			CCFSettingsService.default_settings()
		)
		workspace.save_project()
		await process_frame
		var saved_path := CCFStorageService.project_folder(
			str(authored.get("project_id", ""))
		).path_join(CCFStorageService.PROJECT_FILE)
		_require(
			FileAccess.file_exists(saved_path)
			and CCFStorageService.list_projects().size() == 1,
			"Adding meaningful character content and saving must still persist normally."
		)

	app.queue_free()
	await process_frame
	if _failed:
		quit(1)
		return
	print("V0212_EMPTY_TOOL_DRAFTS_OK")
	quit(0)


func _require(condition: bool, message_text: String) -> bool:
	if condition:
		return true
	_failed = true
	push_error(message_text)
	return false
