extends SceneTree

const PERSISTENCE_SERVICE = preload(
	"res://scripts/services/project_persistence_service_v01536_hotfix3.gd"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	CCFStorageService.ensure_directories()
	var template := CCFTemplateService.load_default_template()
	assert(not template.is_empty(), "Empty-project regression requires the default template.")

	var blank := CCFStorageService.new_project()
	assert(
		not PERSISTENCE_SERVICE.project_has_meaningful_content(blank, template),
		"A pristine new project must not count UUIDs, timestamps, default names or workspace state as authored content."
	)
	var template_only := blank.duplicate(true)
	var template_character_id := CCFStorageService.active_character_id(template_only)
	CCFTemplatePreferenceService.assign_character_template(
		template_only,
		template_character_id,
		"default"
	)
	assert(
		not PERSISTENCE_SERVICE.project_has_meaningful_content(template_only, template),
		"Assigning a template alone must not make an empty project persistable."
	)

	var named_project := blank.duplicate(true)
	var named_metadata: Dictionary = named_project.get("metadata", {}).duplicate(true)
	named_metadata["name"] = "My Character Project"
	named_project["metadata"] = named_metadata
	assert(
		PERSISTENCE_SERVICE.project_has_meaningful_content(named_project, template),
		"A deliberately named project is authored project-level content."
	)

	var named_character_project := blank.duplicate(true)
	var named_character_id := CCFStorageService.active_character_id(named_character_project)
	var named_character := CCFStorageService.get_character(named_character_project, named_character_id)
	CCFStorageService.set_value_at_path(named_character, "character.name", "Elena")
	CCFStorageService.update_character(named_character_project, named_character)
	assert(
		PERSISTENCE_SERVICE.project_has_meaningful_content(named_character_project, template),
		"A real character name must count as authored content even if other fields are still blank."
	)

	var context_project := blank.duplicate(true)
	var context: Dictionary = context_project.get("shared_context", {}).duplicate(true)
	context["premise"] = "A shared premise authored before individual character fields."
	context_project["shared_context"] = context
	assert(
		PERSISTENCE_SERVICE.project_has_meaningful_content(context_project, template),
		"Shared project context must count as meaningful content."
	)

	var scene := load("res://scenes/main.tscn") as PackedScene
	assert(scene != null, "The hotfix3 real main scene must load.")
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	assert(
		app.has_method("_update_build_version_label_v01536_hotfix3"),
		"The active shell must install v0.15.36-hotfix3."
	)

	app.call("_create_new_character")
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	assert(
		workspace_value is CCFWorkspaceV01536Hotfix3View,
		"The real app must install the hotfix3 Workspace."
	)
	var workspace := workspace_value as CCFWorkspaceV01536Hotfix3View
	var live_project := workspace.current_project()
	var live_project_id := str(live_project.get("project_id", ""))
	assert(not live_project_id.is_empty(), "Unsaved projects still need a stable in-memory project ID.")
	var live_path := CCFStorageService.project_folder(live_project_id).path_join(
		CCFStorageService.PROJECT_FILE
	)
	assert(
		not FileAccess.file_exists(live_path),
		"Creating a new empty project must not write character.json before the author adds content."
	)
	assert(
		CCFStorageService.list_projects().is_empty(),
		"A pristine in-memory project must not appear in the Library."
	)

	workspace.save_project()
	await process_frame
	assert(
		not FileAccess.file_exists(live_path),
		"Pressing Save on a pristine unsaved project must still not write character.json."
	)
	var status_value: Variant = workspace.get("_status")
	assert(status_value is Label, "Workspace must expose its normal status label.")
	assert(
		(status_value as Label).text.contains("Nothing to save yet"),
		"Manual Save must explain why the empty project was not persisted."
	)
	assert(
		CCFStorageService.list_projects().is_empty(),
		"Manual Save on an empty project must not create a Library row."
	)

	var authored := CCFStorageService.new_project()
	var authored_id := CCFStorageService.active_character_id(authored)
	var authored_character := CCFStorageService.get_character(authored, authored_id)
	CCFStorageService.set_value_at_path(
		authored_character,
		"concept.prompt",
		"A real Generation Concept that should make the project persistable."
	)
	CCFStorageService.update_character(authored, authored_character)
	var save_result := PERSISTENCE_SERVICE.save_if_meaningful(authored, template)
	assert(bool(save_result.get("ok", false)), "Meaningful first save must succeed.")
	assert(bool(save_result.get("persisted", false)), "Meaningful first save must report that it persisted.")
	var authored_path := CCFStorageService.project_folder(
		str(authored.get("project_id", ""))
	).path_join(CCFStorageService.PROJECT_FILE)
	assert(FileAccess.file_exists(authored_path), "Meaningful content must create character.json normally.")

	app.queue_free()
	await process_frame
	print("v0.15.36-hotfix3 empty project save regression passed")
	quit(0)
