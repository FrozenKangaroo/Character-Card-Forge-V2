extends SceneTree

const TEST_USER_DATA_ISOLATION = preload("res://tools/test_user_data_isolation.gd")
var _test_user_data_isolation := TEST_USER_DATA_ISOLATION.activate("v0215-idea-window")

const NOTEBOOK_SERVICE = preload(
	"res://scripts/services/idea_notebook_service_v01532.gd"
)

var _failed := false
var _test_root := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_root = "/tmp/ccf_v0215_hotfix1_%d" % Time.get_ticks_usec()
	NOTEBOOK_SERVICE.set_storage_root_for_testing(_test_root)
	var folder_result := NOTEBOOK_SERVICE.create_folder("Performance")
	var folder: Dictionary = folder_result.get("folder", {})
	var folder_id := str(folder.get("id", ""))
	var notebook_result := NOTEBOOK_SERVICE.create_notebook("Selection Test", folder_id)
	var notebook: Dictionary = notebook_result.get("notebook", {})
	var notebook_id := str(notebook.get("id", ""))
	var idea_ids: Array[String] = []
	for index in range(20):
		var saved := NOTEBOOK_SERVICE.save_generated_idea(
			{
				"title": "Selection Idea %02d" % index,
				"concept": "Idea %02d keeps {{user}} agency." % index,
				"structured_idea": {"kind": "scenario", "sections": {"premise": "Test"}}
			},
			notebook_id,
			{"type": "v0215_hotfix1_regression"}
		)
		idea_ids.append(str((saved.get("idea", {}) as Dictionary).get("id", "")))

	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The current application scene must load."):
		_finish()
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	await process_frame
	var workspace: Variant = app.get("_workspace")
	if not _require(workspace != null, "The current Workspace must load."):
		app.queue_free()
		_finish()
		return
	var generator: Variant = workspace.get("_idea_generator_v01532")
	if not _require(generator != null, "The unified Idea Generator must load."):
		app.queue_free()
		_finish()
		return

	var tab_names: Array[String] = []
	var tabs := generator.get("_tabs") as TabContainer
	for index in range(tabs.get_tab_count()):
		tab_names.append(tabs.get_tab_title(index))
	_require(
		tab_names.has("AI Ideas")
		and tab_names.has("Structured Builder")
		and tab_names.has("Idea Library")
		and tab_names.has("Idea Sources"),
		"The reused unified Window must retain all four expected tabs."
	)

	var legacy := workspace.get("_idea_window") as Window
	var unrelated := Window.new()
	unrelated.name = "IdeaNotebookExportWindow"
	unrelated.title = "Idea Export"
	workspace.add_child(unrelated)
	_require(
		workspace.call("_find_legacy_ai_idea_window") == legacy,
		"Legacy attachment must use the exact original controller, not a name/title heuristic."
	)
	workspace.call("_prepare_unified_idea_generator")
	var embedded_once: Variant = generator.get("_embedded_ai_window")
	workspace.call("_prepare_unified_idea_generator")
	_require(
		embedded_once == legacy
		and generator.get("_embedded_ai_window") == legacy
		and bool(workspace.get("_legacy_ai_ideas_attached")),
		"The legacy AI controller must attach exactly once and remain stable."
	)

	var open_count := int(generator.get("_open_studio_request_count_v0215_hotfix"))
	workspace.open_idea_notebook_v01532()
	await process_frame
	_require(
		int(generator.get("_open_studio_request_count_v0215_hotfix")) == open_count + 1
		and tabs.get_tab_title(tabs.current_tab) == "Idea Library"
		and generator.visible
		and not legacy.visible,
		"Direct Idea Notebook routing must select its tab first and show one unified Window once."
	)
	for cycle in range(3):
		generator.hide()
		workspace.call("_open_idea_generator")
		await process_frame
		_require(
			tabs.get_tab_title(tabs.current_tab) == "AI Ideas" and generator.visible,
			"Reopening Idea Generator must reuse the unified Window with AI Ideas selected."
		)
		generator.hide()
		workspace.open_idea_notebook_v01532()
		await process_frame
		_require(
			tabs.get_tab_title(tabs.current_tab) == "Idea Library" and generator.visible,
			"Alternating close/reopen cycles must reliably restore Idea Notebook."
		)
	_require(
		int(generator.get("_open_studio_request_count_v0215_hotfix")) == open_count + 7,
		"Each logical open request must result in exactly one native Window show/focus request."
	)

	generator.set("_notebook_tree_selection_kind_v0215", "folder")
	generator.set("_notebook_tree_selection_id_v0215", notebook_id)
	generator.call("_refresh_ideas_v01532")
	var idea_list := generator.get("_idea_list_v01532") as ItemList
	var visible_ids: Array = generator.get("_visible_idea_ids_v01532")
	_require(idea_list != null and visible_ids.size() == 20, "The selection fixture must be visible.")
	if idea_list != null and visible_ids.size() == 20:
		idea_list.deselect_all()
		idea_list.select(0, false)
		generator.call("_on_idea_selected_v01532", 0)
		var focused_before := str(generator.get("_selected_idea_id_v01532"))
		var tree_refreshes_before := int(generator.get("_notebook_tree_refresh_count_v0215_hotfix"))
		NOTEBOOK_SERVICE.reset_io_counters_for_testing()
		generator.set("_focused_idea_load_count_v0215_hotfix", 0)
		for index in range(1, 15):
			idea_list.select(index, false)
			generator.call("_on_idea_multi_selected_v0214", index, true)
		var range_counters := NOTEBOOK_SERVICE.io_counters_for_testing()
		_require(
			int(generator.get("_focused_idea_load_count_v0215_hotfix")) == 0
			and int(range_counters.get("idea_reads", -1)) == 0
			and str(generator.get("_selected_idea_id_v01532")) == str(visible_ids[14])
			and str(generator.get("_selected_idea_id_v01532")) != focused_before
			and int(generator.get("_notebook_tree_refresh_count_v0215_hotfix")) == tree_refreshes_before,
			"A Shift-range-equivalent multi-selection may move lightweight focus, but must not load N ideas or rebuild the tree."
		)
		_require(
			(generator.call("_live_notebook_selected_ids_v0214") as Array).size() == 15,
			"The live batch/export selection must still contain every selected idea."
		)
		NOTEBOOK_SERVICE.reset_io_counters_for_testing()
		generator.call("_on_idea_selected_v01532", 14)
		var focus_counters := NOTEBOOK_SERVICE.io_counters_for_testing()
		_require(
			int(generator.get("_focused_idea_load_count_v0215_hotfix")) == 1
			and int(focus_counters.get("idea_reads", -1)) == 1
			and int(focus_counters.get("library_loads", -1)) == 1,
			"One focus change must read one idea and build one hierarchy snapshot."
		)

	var snapshot := NOTEBOOK_SERVICE.hierarchy_snapshot()
	_require(
		NOTEBOOK_SERVICE.notebook_path_from_snapshot(notebook_id, snapshot)
		== "Performance / Selection Test",
		"The in-memory hierarchy snapshot must preserve full destination paths."
	)
	NOTEBOOK_SERVICE.rename_folder(folder_id, "Renamed")
	var renamed := NOTEBOOK_SERVICE.hierarchy_snapshot()
	_require(
		NOTEBOOK_SERVICE.notebook_path_from_snapshot(notebook_id, renamed)
		== "Renamed / Selection Test",
		"A fresh snapshot must reflect hierarchy edits without stale persistent caching."
	)

	unrelated.queue_free()
	app.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	NOTEBOOK_SERVICE.reset_storage_root_after_testing()
	_remove_tree(_test_root)
	if _failed:
		quit(1)
		return
	print("V0215_HOTFIX1_IDEA_WINDOW_SELECTION_OK")
	quit(0)


func _remove_tree(path: String) -> void:
	if path.is_empty() or not DirAccess.dir_exists_absolute(path):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var child_path := path.path_join(entry)
			if directory.current_is_dir():
				_remove_tree(child_path)
			else:
				DirAccess.remove_absolute(child_path)
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(path)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_failed = true
	push_error(message)
	return false
