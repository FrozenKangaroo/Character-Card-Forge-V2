extends SceneTree

const CUSTOM_TEMPLATE_ID := "regression_custom_default_template"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	CCFStorageService.ensure_directories()
	var template := CCFTemplateService.create_template("Regression Custom Default")
	template["template_id"] = CUSTOM_TEMPLATE_ID
	var save_template_result := CCFTemplateService.save_template(template)
	assert(
		bool(save_template_result.get("ok", false)),
		"Regression custom template must save before exercising the default preference."
	)

	var settings := CCFSettingsService.default_settings()
	var resolved_default := CCFTemplatePreferenceService.set_default_template_id(
		settings,
		CUSTOM_TEMPLATE_ID
	)
	assert(
		resolved_default == CUSTOM_TEMPLATE_ID,
		"The configured custom template must resolve as the application default."
	)
	var save_settings_result := CCFSettingsService.save_settings(settings)
	assert(
		bool(save_settings_result.get("ok", false)),
		"Regression settings must save before the real app shell loads."
	)

	var scene := load("res://scenes/main.tscn") as PackedScene
	assert(scene != null, "The hotfix real main scene must load.")
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame

	assert(
		app.has_method("_update_build_version_label_v01536_hotfix1"),
		"The active shell must install v0.15.36-hotfix1."
	)
	app.call("_create_new_character")
	await process_frame
	await process_frame

	var workspace_value: Variant = app.get("_workspace")
	assert(
		workspace_value is CCFWorkspaceV01536Hotfix1View,
		"The real app must install the hotfix Workspace."
	)
	var workspace := workspace_value as CCFWorkspaceV01536Hotfix1View
	var project := workspace.current_project()
	var first_character_id := CCFStorageService.active_character_id(project)
	assert(
		CCFStorageService.active_character_template_id(project) == CUSTOM_TEMPLATE_ID,
		"New projects must assign the configured custom default template to their first character."
	)
	var live_template_value: Variant = workspace.get("_template")
	assert(live_template_value is Dictionary, "Workspace must expose its active template dictionary.")
	var live_template: Dictionary = live_template_value
	assert(
		str(live_template.get("template_id", "")) == CUSTOM_TEMPLATE_ID,
		"New project Workspace must visibly load the configured custom default template."
	)
	assert(not first_character_id.is_empty(), "New project must contain an active character.")

	workspace.call("_add_character")
	await process_frame
	var project_after_add := workspace.current_project()
	var second_character_id := CCFStorageService.active_character_id(project_after_add)
	assert(
		second_character_id != first_character_id,
		"Add Character must switch to the newly created character."
	)
	assert(
		CCFStorageService.active_character_template_id(project_after_add) == CUSTOM_TEMPLATE_ID,
		"Characters added inside an existing project must inherit the configured application default template."
	)
	var added_live_template: Dictionary = workspace.get("_template")
	assert(
		str(added_live_template.get("template_id", "")) == CUSTOM_TEMPLATE_ID,
		"Workspace must keep the custom default active after Add Character."
	)

	var current_workspace_value: Variant = workspace.get("_project")
	assert(current_workspace_value is Dictionary, "Workspace document must remain a dictionary.")
	var workspace_document: Dictionary = (current_workspace_value as Dictionary).duplicate(true)
	var generation: Dictionary = workspace_document.get("generation", {}).duplicate(true)
	generation["template_id"] = "missing_regression_template"
	workspace_document["generation"] = generation
	workspace.set("_project", workspace_document)
	workspace.call("refresh_templates")
	var repaired_workspace_value: Variant = workspace.get("_project")
	assert(repaired_workspace_value is Dictionary, "Repaired Workspace document must remain a dictionary.")
	var repaired_workspace: Dictionary = repaired_workspace_value
	var repaired_generation: Dictionary = repaired_workspace.get("generation", {})
	assert(
		str(repaired_generation.get("template_id", "")) == CUSTOM_TEMPLATE_ID,
		"If an assigned template disappears, Workspace must fall back to the configured default before the built-in template."
	)
	var repaired_template: Dictionary = workspace.get("_template")
	assert(
		str(repaired_template.get("template_id", "")) == CUSTOM_TEMPLATE_ID,
		"Template refresh fallback must visibly restore the configured custom default."
	)

	app.queue_free()
	await process_frame
	print("v0.15.36-hotfix1 default template regression passed")
	quit(0)
