extends SceneTree

const REFINEMENT_SERVICE = preload(
	"res://scripts/services/collaborator_refinement_service_v01536.gd"
)
const CHARACTER_INTENT_SERVICE = preload(
	"res://scripts/services/collaborator_character_intent_service_v01534.gd"
)
const DESTINATION_WINDOW = preload(
	"res://scripts/ui/collaborator_completion_destination_window_v01536.gd"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var template := CCFTemplateService.load_default_template()
	assert(not template.is_empty(), "v0.15.36 regression requires the default template.")

	var source := CCFStorageService.new_character_record("Source Character")
	var source_id := str(source.get("character_id", ""))
	CCFStorageService.set_value_at_path(source, "character.name", "Source Character")
	CCFStorageService.set_value_at_path(source, "metadata.name", "Source Character")
	CCFStorageService.set_value_at_path(source, "concept.prompt", "Original concept")
	CCFStorageService.set_value_at_path(source, "character.description", "Original description")
	CCFStorageService.set_value_at_path(source, "character.personality", "Original personality")
	CCFStorageService.set_value_at_path(source, "character.scenario", "Original scenario")
	CCFStorageService.set_value_at_path(
		source,
		"character.alternate_greetings",
		["Original greeting"]
	)

	var refine_source := CHARACTER_INTENT_SERVICE.build_source(
		source,
		"project-v01536",
		"Regression Project",
		"Source Character",
		{"intent_id": "refine", "instruction": "Deepen the character without changing her premise."}
	)
	assert(REFINEMENT_SERVICE.can_compare_source(refine_source), "Existing-character sources must be comparable.")
	assert(REFINEMENT_SERVICE.source_character_id(refine_source) == source_id, "Compare & Apply must retain the source character ID.")
	assert(REFINEMENT_SERVICE.allows_update_original(refine_source), "Refine direction must allow reviewed Update Original.")

	var field_ids := _field_ids_by_path(template)
	assert(field_ids.has("character.description"), "Default template must expose Description for v0.15.36 regression.")
	assert(field_ids.has("character.personality"), "Default template must expose Personality for v0.15.36 regression.")
	assert(field_ids.has("character.scenario"), "Default template must expose Scenario for v0.15.36 regression.")
	var payload := {
		"handoff_mode": "detailed_workspace_draft",
		"suggested_name": "Source Character",
		"concept_prompt": "Refined concept",
		"fields": {
			str(field_ids["character.description"]): "Refined description",
			str(field_ids["character.personality"]): "Refined personality",
			str(field_ids["character.scenario"]): "Original scenario"
		},
		"alternate_greetings": ["Original greeting", "New greeting"],
		"lorebook": {"entries": []}
	}
	var proposal_result := REFINEMENT_SERVICE.build_proposal(
		payload,
		"Refinement Regression",
		template,
		refine_source
	)
	assert(bool(proposal_result.get("ok", false)), "v0.15.36 must materialise a comparable Collaborator proposal.")
	var proposal: Dictionary = proposal_result.get("character", {})
	var rows := REFINEMENT_SERVICE.comparison_rows(
		payload,
		source,
		proposal,
		template
	)
	var row_paths := _row_paths(rows)
	assert(row_paths.has("concept.prompt"), "Changed Generation Concept must appear in comparison.")
	assert(row_paths.has("character.description"), "Changed Description must appear in comparison.")
	assert(row_paths.has("character.personality"), "Changed Personality must appear in comparison.")
	assert(row_paths.has("character.alternate_greetings"), "Changed Alternative Greetings must appear in comparison.")
	assert(not row_paths.has("character.scenario"), "Unchanged explicit fields should not clutter the comparison.")

	var selective := REFINEMENT_SERVICE.apply_selected_changes(
		source,
		source,
		proposal,
		["character.description"],
		REFINEMENT_SERVICE.APPLY_UPDATE_ORIGINAL,
		refine_source,
		"Refinement Regression"
	)
	assert(bool(selective.get("ok", false)), "Selective Update Original must succeed for a clean refine source.")
	var selective_character: Dictionary = selective.get("character", {})
	assert(str(selective_character.get("character_id", "")) == source_id, "Update Original must preserve the source character ID.")
	assert(
		str(CCFStorageService.get_value_at_path(selective_character, "character.description", "")) == "Refined description",
		"Selected Description must be applied."
	)
	assert(
		str(CCFStorageService.get_value_at_path(selective_character, "character.personality", "")) == "Original personality",
		"Unselected Personality must remain unchanged."
	)

	var edited_after_capture := source.duplicate(true)
	CCFStorageService.set_value_at_path(
		edited_after_capture,
		"character.description",
		"Manual edit made after Collaborator opened"
	)
	var conflict := REFINEMENT_SERVICE.apply_selected_changes(
		edited_after_capture,
		source,
		proposal,
		["character.description"],
		REFINEMENT_SERVICE.APPLY_UPDATE_ORIGINAL,
		refine_source,
		"Refinement Regression"
	)
	assert(not bool(conflict.get("ok", true)), "Update Original must block a selected field that changed after source capture.")
	assert((conflict.get("conflicts", []) as Array).has("character.description"), "Conflict result must identify the changed source path.")

	var copy_result := REFINEMENT_SERVICE.apply_selected_changes(
		edited_after_capture,
		source,
		proposal,
		["character.description", "character.personality"],
		REFINEMENT_SERVICE.APPLY_CREATE_COPY,
		refine_source,
		"Refinement Regression"
	)
	assert(bool(copy_result.get("ok", false)), "Create Improved Copy must preserve newer source edits while applying selected proposal changes.")
	var copy_character: Dictionary = copy_result.get("character", {})
	assert(str(copy_character.get("character_id", "")) != source_id, "Improved copy must receive a new stable character ID.")
	assert(
		str(CCFStorageService.get_value_at_path(copy_character, "character.description", "")) == "Refined description",
		"Improved copy must receive selected proposal values."
	)
	assert(
		str(CCFStorageService.get_value_at_path(copy_character, "character.scenario", "")) == "Original scenario",
		"Improved copy must preserve unselected source data."
	)

	var future_source := CHARACTER_INTENT_SERVICE.build_source(
		source,
		"project-v01536",
		"Regression Project",
		"Source Character",
		{"intent_id": "future_version", "instruction": "Five years later."}
	)
	assert(not REFINEMENT_SERVICE.allows_update_original(future_source), "Future-version branches must not enable Update Original.")
	var blocked_branch := REFINEMENT_SERVICE.apply_selected_changes(
		source,
		source,
		proposal,
		["character.description"],
		REFINEMENT_SERVICE.APPLY_UPDATE_ORIGINAL,
		future_source,
		"Future Version Regression"
	)
	assert(not bool(blocked_branch.get("ok", true)), "Branch directions must reject destructive Update Original.")

	var project_for_presence := CCFStorageService.new_project()
	project_for_presence["project_id"] = "project-v01536"
	project_for_presence["characters"] = [source.duplicate(true)]
	assert(REFINEMENT_SERVICE.source_exists_in_project(refine_source, project_for_presence), "Source-target lookup must verify the captured character is still in the original project.")

	var chooser := DESTINATION_WINDOW.new() as CCFCollaboratorCompletionDestinationWindowV01536
	root.add_child(chooser)
	await process_frame
	chooser.open_for_completion_v01536(
		source,
		template,
		"Regression Project",
		"Source Character",
		refine_source,
		true
	)
	await process_frame
	assert(chooser.compare_apply_available_v01536(), "Existing-character completion routing must expose Compare & Apply.")
	chooser.hide()

	assert(
		str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "")) == "forward_plus",
		"v0.15.36 must make Forward+ the default desktop renderer."
	)
	assert(
		bool(ProjectSettings.get_setting("rendering/rendering_device/fallback_to_opengl3", false)),
		"Forward+ should retain Godot's Compatibility fallback for genuinely unsupported older hardware."
	)

	var scene := load("res://scenes/main.tscn") as PackedScene
	assert(scene != null, "The real main scene must load for v0.15.36 regression coverage.")
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	assert(workspace_value is CCFWorkspaceV01536View, "The real main scene must install the v0.15.36 Workspace or a compatible descendant.")
	var workspace := workspace_value as CCFWorkspaceV01536View
	var capabilities := workspace.collaborator_refinement_capabilities_v01536()
	assert(bool(capabilities.get("existing_character_compare", false)), "v0.15.36 must advertise source/proposal comparison.")
	assert(bool(capabilities.get("selective_field_apply", false)), "v0.15.36 must advertise selective application.")
	assert(bool(capabilities.get("create_improved_copy", false)), "v0.15.36 must advertise improved-copy creation.")
	var live_destination: Variant = workspace.get("_completion_destination_window_v01535")
	assert(live_destination is CCFCollaboratorCompletionDestinationWindowV01536, "Live Workspace must install the v0.15.36 completion chooser.")
	var live_compare: Variant = workspace.get("_refinement_compare_window_v01536")
	assert(live_compare is CCFCollaboratorRefinementCompareWindowV01536, "Live Workspace must install the v0.15.36 Compare & Apply window.")

	var app_settings_value: Variant = app.get("_settings")
	var app_settings: Dictionary = app_settings_value if app_settings_value is Dictionary else {}
	var live_project := CCFStorageService.new_project()
	live_project["project_id"] = "project-v01536"
	live_project["characters"] = [source.duplicate(true)]
	var live_workspace_meta: Dictionary = live_project.get("workspace", {}).duplicate(true)
	live_workspace_meta["active_character_id"] = source_id
	live_project["workspace"] = live_workspace_meta
	workspace.load_project(live_project, template, app_settings)
	await process_frame
	workspace.set("_pending_completion_payload_v01535", payload.duplicate(true))
	workspace.set("_pending_completion_source_v01535", refine_source.duplicate(true))
	workspace.set("_pending_completion_title_v01535", "Live Refinement Regression")
	workspace.set("_pending_completion_project_id_v01535", "project-v01536")
	var live_apply := workspace.apply_collaborator_refinement_v01536(
		REFINEMENT_SERVICE.APPLY_UPDATE_ORIGINAL,
		["character.description"]
	)
	assert(bool(live_apply.get("ok", false)), "Live Workspace Update Original must succeed after explicit selection.")
	var live_after: Dictionary = workspace.get("_project_container")
	assert((live_after.get("characters", []) as Array).size() == 1, "Update Original must not create a duplicate character.")
	var live_source_after := CCFStorageService.get_character(live_after, source_id)
	assert(
		str(CCFStorageService.get_value_at_path(live_source_after, "character.description", "")) == "Refined description",
		"Live Workspace must apply the selected refinement to the source character."
	)
	assert(
		str(CCFStorageService.get_value_at_path(live_source_after, "character.personality", "")) == "Original personality",
		"Live Workspace must preserve unselected source fields."
	)

	var main_script := app.get_script() as Script
	assert(main_script != null, "The active app shell must have a script.")
	assert(
		app.has_method("_update_build_version_label_v01536"),
		"The active app shell must retain the v0.15.36 shell capability through inheritance."
	)

	app.queue_free()
	chooser.queue_free()
	await process_frame
	print("v0.15.36 Collaborator Compare & Apply regression passed")
	quit(0)


func _field_ids_by_path(template: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for raw_field in CCFTemplateService.generation_fields(template):
		if not raw_field is Dictionary:
			continue
		var field: Dictionary = raw_field
		var path := str(field.get("path", "")).strip_edges()
		var field_id := str(field.get("id", "")).strip_edges()
		if not path.is_empty() and not field_id.is_empty():
			result[path] = field_id
	return result


func _row_paths(rows: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for row in rows:
		result.append(str(row.get("path", "")))
	return result
