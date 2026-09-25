extends SceneTree

const NOTEBOOK_SERVICE = preload(
	"res://scripts/services/idea_notebook_service_v01532.gd"
)

var _failed := false
var _created_idea_ids: Array[String] = []
var _created_notebook_ids: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The current application scene must load."):
		_finish()
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		workspace_value is CCFWorkspaceCurrent,
		"The live shell must install the current Workspace."
	):
		_finish()
		return
	var generator_value: Variant = (workspace_value as CCFWorkspaceCurrent).get(
		"_idea_generator_v01532"
	)
	if not _require(
		generator_value is CCFIdeaGeneratorWindowCurrent,
		"The live Workspace must install the current Idea Generator."
	):
		_finish()
		return
	var generator := generator_value as CCFIdeaGeneratorWindowCurrent
	var notebook_search := generator.find_child(
		"NotebookSearchV0211", true, false
	) as LineEdit
	var notebook_sort := generator.find_child(
		"NotebookSortV0211", true, false
	) as OptionButton
	var idea_sort := generator.find_child(
		"IdeaSortV0211", true, false
	) as OptionButton
	var result_summary := generator.find_child(
		"IdeaResultSummaryV0211", true, false
	) as Label
	_require(
		notebook_search != null
		and notebook_sort != null
		and idea_sort != null
		and result_summary != null,
		"Idea Notebook must expose notebook search, notebook sort, idea sort and a result summary."
	)

	var stamp := str(Time.get_ticks_usec())
	var first_name := "Notebook Alpha " + stamp
	var second_name := "Notebook Zulu " + stamp
	var generated := {
		"title": "Middle Idea " + stamp,
		"character_name": "Mika",
		"character_role": "Travelling companion",
		"source_anchor": "",
		"roleplay_hook": "Mika asks {{user}} where to travel next.",
		"concept": "Mika and {{user}} choose their next destination together.",
		"tags": ["travel", "planning"]
	}
	generator.set_last_generated_ideas_v01532([generated], {"seed": "travel"})
	generator.call("_open_save_generated_v01532")
	await process_frame
	var create_button := generator.find_child(
		"NewNotebookWhileSavingV0211", true, false
	) as Button
	_require(
		create_button != null,
		"Save Generated Ideas must offer New Notebook without leaving the save window."
	)
	generator.call("_open_new_notebook_while_saving_v0211")
	var name_input := generator.find_child(
		"SaveNewNotebookNameV0211", true, false
	) as LineEdit
	if _require(name_input != null, "The destination notebook dialog must accept a name."):
		name_input.text = first_name
		generator.call("_create_notebook_while_saving_v0211")
	var first_id := _notebook_id_named(first_name)
	if _require(not first_id.is_empty(), "Creating a destination notebook must persist it."):
		_created_notebook_ids.append(first_id)
	var destination_value: Variant = generator.get(
		"_save_generated_notebook_v01532"
	)
	var destination := destination_value as OptionButton
	_require(
		destination != null
		and _selected_metadata(destination) == first_id,
		"The newly created notebook must become the selected save destination."
	)
	generator.call("_save_selected_generated_v01532")
	var saved_middle := _idea_id_titled("Middle Idea " + stamp)
	if _require(not saved_middle.is_empty(), "Save Selected must write into the new notebook."):
		_created_idea_ids.append(saved_middle)
		var middle_loaded := NOTEBOOK_SERVICE.load_idea(saved_middle)
		_require(
			str((middle_loaded.get("data", {}) as Dictionary).get("notebook_id", ""))
			== first_id,
			"The generated idea must retain the new destination notebook ID."
		)

	var second_result := NOTEBOOK_SERVICE.create_notebook(second_name)
	if bool(second_result.get("ok", false)):
		var second_id := str(
			(second_result.get("notebook", {}) as Dictionary).get("id", "")
		)
		_created_notebook_ids.append(second_id)
		var alpha_result := NOTEBOOK_SERVICE.save_generated_idea(
			{
				"title": "Alpha Idea " + stamp,
				"concept": "An alphabetically earlier idea with {{user}} agency.",
				"tags": ["sorting"]
			},
			second_id,
			{"type": "regression"}
		)
		if bool(alpha_result.get("ok", false)):
			_created_idea_ids.append(str(
				(alpha_result.get("idea", {}) as Dictionary).get("id", "")
			))
	else:
		_require(false, str(second_result.get("error", "Could not create second notebook.")))

	var notebook_filter_value: Variant = generator.get("_notebook_filter_v01532")
	var notebook_filter := notebook_filter_value as OptionButton
	_select_metadata(notebook_filter, "__all__")
	_select_metadata(idea_sort, "title_az")
	generator.call("_refresh_ideas_v01532")
	var visible_ids: Array = generator.get("_visible_idea_ids_v01532")
	if _require(not visible_ids.is_empty(), "Sorted Idea Notebook results must remain visible."):
		var first_loaded := NOTEBOOK_SERVICE.load_idea(str(visible_ids[0]))
		_require(
			str((first_loaded.get("data", {}) as Dictionary).get("title", ""))
			== "Alpha Idea " + stamp,
			"Title A–Z must order the visible Idea Notebook results."
		)
		var idea_list_value: Variant = generator.get("_idea_list_v01532")
		var idea_list := idea_list_value as ItemList
		_require(
			idea_list != null and idea_list.get_item_text(0).contains(second_name),
			"All Ideas must show each idea's notebook so cross-notebook results stay understandable."
		)

	notebook_search.text = first_name
	generator.call("_refresh_notebook_v01532")
	_require(
		_selector_contains_text(notebook_filter, first_name)
		and not _selector_contains_text(notebook_filter, second_name),
		"Notebook search must narrow large notebook pickers by name."
	)
	_require(
		result_summary.text.begins_with("Showing ")
		and result_summary.text.contains("All Ideas"),
		"The notebook list must keep a visible result count and scope."
	)

	_cleanup()
	app.queue_free()
	await process_frame
	_finish()


func _notebook_id_named(notebook_name: String) -> String:
	for notebook in NOTEBOOK_SERVICE.list_notebooks():
		if str(notebook.get("name", "")) == notebook_name:
			return str(notebook.get("id", ""))
	return ""


func _idea_id_titled(title: String) -> String:
	for idea in NOTEBOOK_SERVICE.list_ideas({"include_archived": true}):
		if str(idea.get("title", "")) == title:
			return str(idea.get("id", ""))
	return ""


func _select_metadata(selector: OptionButton, value: String) -> void:
	if selector == null:
		return
	for index in range(selector.item_count):
		if str(selector.get_item_metadata(index)) == value:
			selector.select(index)
			return


func _selected_metadata(selector: OptionButton) -> String:
	if selector == null or selector.selected < 0:
		return ""
	return str(selector.get_item_metadata(selector.selected))


func _selector_contains_text(selector: OptionButton, text: String) -> bool:
	if selector == null:
		return false
	for index in range(selector.item_count):
		if selector.get_item_text(index).contains(text):
			return true
	return false


func _cleanup() -> void:
	for idea_id in _created_idea_ids:
		if not idea_id.is_empty():
			NOTEBOOK_SERVICE.delete_idea(idea_id)
	for notebook_id in _created_notebook_ids:
		if not notebook_id.is_empty():
			NOTEBOOK_SERVICE.delete_notebook(notebook_id)


func _finish() -> void:
	_cleanup()
	if _failed:
		quit(1)
		return
	print("V0211_IDEA_NOTEBOOK_ORGANIZATION_OK")
	quit(0)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_failed = true
	push_error(message)
	return false
