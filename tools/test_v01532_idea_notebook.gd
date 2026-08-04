extends SceneTree

const NOTEBOOK_SERVICE = preload("res://scripts/services/idea_notebook_service_v01532.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var baseline_count := NOTEBOOK_SERVICE.list_ideas({"include_archived": true}).size()
	var stamp := str(Time.get_ticks_usec())
	var notebook_name := "Regression Notebook " + stamp
	var created := NOTEBOOK_SERVICE.create_notebook(notebook_name)
	assert(bool(created.get("ok", false)), "v0.15.32 must create named Idea Notebooks.")
	var notebook: Dictionary = created.get("notebook", {})
	var notebook_id := str(notebook.get("id", ""))
	assert(not notebook_id.is_empty(), "Created notebook needs a stable ID.")

	var source_idea := {
		"title": "Assigned the Wrong Dorm Room",
		"character_name": "Mina",
		"character_role": "{{user}}'s unexpectedly assigned dorm mate",
		"source_anchor": "assigned the same dorm room",
		"roleplay_hook": "Mina and {{user}} must decide how to survive the university housing mistake.",
		"concept": "Mina is {{user}}'s unexpectedly assigned dorm mate after a university housing error forces them to share a room.",
		"tags": ["University", "roommates", "romance"]
	}
	var saved := NOTEBOOK_SERVICE.save_generated_idea(
		source_idea,
		notebook_id,
		{
			"type": "idea_generator",
			"seed_prompt": "new dorm mate",
			"idea_contract_version": "user_centric_roleplay_v3"
		}
	)
	assert(bool(saved.get("ok", false)), "A generated idea must be selectively saveable.")
	var saved_idea: Dictionary = saved.get("idea", {})
	var idea_id := str(saved_idea.get("id", ""))
	assert(not idea_id.is_empty(), "Saved ideas need stable IDs.")
	assert(NOTEBOOK_SERVICE.list_ideas({"include_archived": true}).size() == baseline_count + 1, "Saving one selected idea must create exactly one stored idea.")

	var loaded := NOTEBOOK_SERVICE.load_idea(idea_id)
	assert(bool(loaded.get("ok", false)), "Saved ideas must reload from external JSON.")
	var idea: Dictionary = loaded.get("data", {})
	assert(str(idea.get("character_name", "")) == "Mina", "Saved ideas must preserve generated character identity.")
	assert(str(idea.get("character_role", "")).contains("{{user}}"), "Saved ideas must preserve generated character role.")
	assert(str(idea.get("source_anchor", "")) == "assigned the same dorm room", "Saved ideas must preserve source anchors.")
	assert(str(idea.get("roleplay_hook", "")).contains("housing mistake"), "Saved ideas must preserve roleplay hooks.")
	assert((idea.get("tags", []) as Array).size() == 3, "Saved ideas must preserve generated tags.")
	assert(str((idea.get("source", {}) as Dictionary).get("seed_prompt", "")) == "new dorm mate", "Saved ideas must preserve source provenance available in v0.15.32.")

	var search_rows := NOTEBOOK_SERVICE.list_ideas({"search": "housing mistake", "include_archived": true})
	assert(_contains_idea(search_rows, idea_id), "Idea Notebook search must include roleplay-hook text.")
	var tag_rows := NOTEBOOK_SERVICE.list_ideas({"tag": "ROMANCE", "include_archived": true})
	assert(_contains_idea(tag_rows, idea_id), "Idea Notebook tag filtering must be case-insensitive.")
	var notebook_rows := NOTEBOOK_SERVICE.list_ideas({"notebook_id": notebook_id, "include_archived": true})
	assert(_contains_idea(notebook_rows, idea_id), "Named notebook filtering must return its ideas.")

	var edited := NOTEBOOK_SERVICE.update_idea(
		idea_id,
		{
			"title": "Dorm Room Mix-Up",
			"notes": "Keep this one for later.",
			"tags": "university, comedy, roommates",
			"notebook_id": notebook_id
		}
	)
	assert(bool(edited.get("ok", false)), "Saved idea title/notes/tags/notebook must remain editable.")
	var edited_idea: Dictionary = edited.get("idea", {})
	assert(str(edited_idea.get("notes", "")) == "Keep this one for later.", "Private idea notes must persist.")
	assert((edited_idea.get("tags", []) as Array).has("comedy"), "Edited comma-separated tags must normalise and persist.")

	var archived := NOTEBOOK_SERVICE.update_idea(idea_id, {"archived": true})
	assert(bool(archived.get("ok", false)), "Saved ideas must support archive state.")
	assert(not _contains_idea(NOTEBOOK_SERVICE.list_ideas(), idea_id), "Archived ideas must be hidden by default.")
	assert(_contains_idea(NOTEBOOK_SERVICE.list_ideas({"include_archived": true}), idea_id), "Archived ideas must be available when requested.")
	NOTEBOOK_SERVICE.update_idea(idea_id, {"archived": false})

	var scene := load("res://scenes/main.tscn") as PackedScene
	assert(scene != null, "The real main scene must load for v0.15.32 regression coverage.")
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	assert(workspace_value is CCFWorkspaceV01532View, "The real main scene must install the v0.15.32 Workspace.")
	var workspace := workspace_value as CCFWorkspaceV01532View
	var generator_value: Variant = workspace.get("_idea_generator_v01532")
	assert(generator_value is CCFIdeaGeneratorWindowV01532, "The live Workspace must install the v0.15.32 unified Idea Generator.")
	var generator := generator_value as CCFIdeaGeneratorWindowV01532
	assert(generator.get_node_or_null("MarginContainer/VBoxContainer/TabContainer/Idea Notebook") != null or _has_named_tab(generator, "Idea Notebook"), "The live Idea Generator must contain an Idea Notebook tab.")
	var before_capture := NOTEBOOK_SERVICE.list_ideas({"include_archived": true}).size()
	workspace.call(
		"_on_idea_job_completed_v01532",
		"regression-ideas",
		"ideas",
		[source_idea.duplicate(true)],
		{"seed": "new dorm mate", "idea_contract_version": "user_centric_roleplay_v3"}
	)
	var captured: Array = generator.get("_last_generated_ideas_v01532")
	assert(captured.size() == 1, "The live Idea worker result must feed the Notebook save workflow.")
	var save_button_value: Variant = generator.get("_save_generated_button_v01532")
	assert(save_button_value is Button and not (save_button_value as Button).disabled, "A completed AI Ideas batch must enable selective saving.")
	assert(NOTEBOOK_SERVICE.list_ideas({"include_archived": true}).size() == before_capture, "Capturing generated ideas must never auto-save them.")

	var deleted_notebook := NOTEBOOK_SERVICE.delete_notebook(notebook_id)
	assert(bool(deleted_notebook.get("ok", false)), "Named notebooks must be deletable.")
	var unfiled := NOTEBOOK_SERVICE.load_idea(idea_id)
	assert(bool(unfiled.get("ok", false)), "Deleting a notebook must retain its ideas.")
	assert(str((unfiled.get("data", {}) as Dictionary).get("notebook_id", "")).is_empty(), "Deleting a notebook must move its ideas to Unfiled.")
	assert(_contains_idea(NOTEBOOK_SERVICE.list_ideas({"notebook_id": "__unfiled__", "include_archived": true}), idea_id), "Built-in Unfiled must expose ideas whose notebook was deleted.")

	var deleted_idea := NOTEBOOK_SERVICE.delete_idea(idea_id)
	assert(bool(deleted_idea.get("ok", false)), "Saved ideas must be deletable.")
	assert(NOTEBOOK_SERVICE.list_ideas({"include_archived": true}).size() == baseline_count, "Regression cleanup must restore the pre-test Idea Notebook count.")

	app.queue_free()
	await process_frame
	print("v0.15.32 Idea Notebook regression passed")
	quit(0)


func _contains_idea(rows: Array, idea_id: String) -> bool:
	for value in rows:
		if value is Dictionary and str((value as Dictionary).get("id", "")) == idea_id:
			return true
	return false


func _has_named_tab(generator: CCFIdeaGeneratorWindowV01532, title: String) -> bool:
	var tabs_value: Variant = generator.get("_tabs")
	if not tabs_value is TabContainer:
		return false
	var tabs := tabs_value as TabContainer
	for index in range(tabs.get_tab_count()):
		if tabs.get_tab_title(index) == title:
			return true
	return false
