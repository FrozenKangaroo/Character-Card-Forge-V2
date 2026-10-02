extends SceneTree

const TEST_USER_DATA_ISOLATION = preload("res://tools/test_user_data_isolation.gd")
var _test_user_data_isolation := TEST_USER_DATA_ISOLATION.activate("v0216-idea-notebook-usability")

const IDEA_SERVICE = preload("res://scripts/services/idea_notebook_service_v01532.gd")

var _failed := false
var _test_root := ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_root = "/tmp/ccf_v0216_folder_usability_%d" % Time.get_ticks_usec()
	IDEA_SERVICE.set_storage_root_for_testing(_test_root)
	var parent_id := _folder_id(IDEA_SERVICE.create_folder("Series Folder"))
	var folder_id := _folder_id(IDEA_SERVICE.create_folder("Arc Folder", parent_id))
	var idea_ids: Array[String] = []
	for index in range(9):
		idea_ids.append(_idea_id(IDEA_SERVICE.save_generated_idea(
			{"title": "Batch Idea %02d" % index, "concept": "Batch fixture %02d." % index}, folder_id
		)))
	if not _require(not folder_id.is_empty() and idea_ids.size() == 9,
		"The Folder usability fixture must be created."):
		_finish()
		return
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
	var generator: Variant = workspace.get("_idea_generator_v01532") if workspace != null else null
	if not _require(generator is CCFIdeaGeneratorWindowCurrent, "The current Idea Library must load."):
		app.queue_free()
		_finish()
		return
	generator.open_notebook_v01532()
	await process_frame
	await process_frame
	var tree := generator.get("_notebook_tree_v0215") as Tree
	var list := generator.get("_idea_list_v01532") as ItemList
	_select_tree_item(generator, _find_tree_item(tree, "folder", folder_id))
	_require(list.item_count == 9, "Selecting a Folder must show its nine direct Ideas.")
	var summary := generator.get("_idea_result_summary_v0211") as Label
	_require(summary.text.contains("Folder: Series Folder / Arc Folder") and summary.text.contains("9 ideas"),
		"Folder feedback must use the full path and direct/recursive Idea count.")
	list.deselect_all()
	for index in [1, 2, 3]:
		list.select(index, false)
		generator.call("_on_idea_multi_selected_v0214", index, true)
	var batch_ids := generator.call("_live_notebook_selected_ids_v0214") as Array
	var refreshes_before := int(generator.get("_idea_delete_batch_refresh_count_v0216"))
	generator.call("_request_delete_idea_v01532")
	_require((generator.get("_pending_delete_idea_ids_v0216") as Array).size() == 3,
		"Batch deletion must use the live multi-selection.")
	generator.call("_delete_selected_idea_v01532")
	_require(int(generator.get("_idea_delete_batch_refresh_count_v0216")) == refreshes_before + 1,
		"One deletion batch must perform exactly one expensive Idea Library refresh.")
	for idea_id in batch_ids:
		_require(not bool(IDEA_SERVICE.load_idea(str(idea_id)).get("ok", false)),
			"Every confirmed Idea in the batch must be deleted.")
	_require(IDEA_SERVICE.list_ideas({"folder_id": folder_id, "include_archived": true}).size() == 6,
		"Untargeted Ideas must survive batch deletion.")
	var delete_event := InputEventKey.new()
	delete_event.pressed = true
	delete_event.keycode = KEY_DELETE
	(generator.get("_concept_v01532") as TextEdit).grab_focus()
	await process_frame
	generator.call("_on_idea_list_gui_input_v0216", delete_event)
	_require((generator.get("_pending_delete_idea_ids_v0216") as Array).is_empty(),
		"Delete while editing text must not request Idea deletion.")
	app.queue_free()
	await process_frame
	_finish()

func _select_tree_item(generator: Variant, item: TreeItem) -> void:
	if item == null:
		_require(false, "The requested Folder item must exist.")
		return
	item.select(0)
	generator.call("_on_notebook_tree_selected_v0215")

func _find_tree_item(tree: Tree, kind: String, item_id: String) -> TreeItem:
	if tree == null or tree.get_root() == null:
		return null
	var pending: Array[TreeItem] = []
	var child := tree.get_root().get_first_child()
	while child != null:
		pending.append(child)
		child = child.get_next()
	while not pending.is_empty():
		var item: TreeItem = pending.pop_back()
		var metadata_value: Variant = item.get_metadata(0)
		if metadata_value is Dictionary:
			var metadata: Dictionary = metadata_value
			if str(metadata.get("kind", "")) == kind and str(metadata.get("id", "")) == item_id:
				return item
		var nested := item.get_first_child()
		while nested != null:
			pending.append(nested)
			nested = nested.get_next()
	return null

func _folder_id(result: Dictionary) -> String:
	return str((result.get("folder", {}) as Dictionary).get("id", ""))

func _idea_id(result: Dictionary) -> String:
	return str((result.get("idea", {}) as Dictionary).get("id", ""))

func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_failed = true
	push_error(message)
	return false

func _finish() -> void:
	IDEA_SERVICE.reset_storage_root_after_testing()
	_remove_tree(_test_root)
	if _failed:
		quit(1)
		return
	print("V0216_IDEA_FOLDER_USABILITY_OK")
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
