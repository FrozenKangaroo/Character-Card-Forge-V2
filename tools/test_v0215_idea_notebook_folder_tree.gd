extends SceneTree

const NOTEBOOK_SERVICE = preload(
	"res://scripts/services/idea_notebook_service_v01532.gd"
)

var _failed := false
var _idea_ids: Array[String] = []
var _notebook_ids: Array[String] = []
var _folder_ids: Array[String] = []
var _test_root := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_root = "/tmp/ccf_v0215_notebook_tree_%d" % Time.get_ticks_usec()
	NOTEBOOK_SERVICE.set_storage_root_for_testing(_test_root)
	_test_v1_migration_and_malformed_recovery()
	var stamp := str(Time.get_ticks_usec())
	var high_result := NOTEBOOK_SERVICE.create_folder("High Priority " + stamp)
	if not _require(bool(high_result.get("ok", false)), "A root folder must be creatable."):
		_finish()
		return
	var high: Dictionary = high_result.get("folder", {})
	var high_id := str(high.get("id", ""))
	_folder_ids.append(high_id)
	var pregnancy_result := NOTEBOOK_SERVICE.create_folder("Pregnancy " + stamp, high_id)
	if not _require(bool(pregnancy_result.get("ok", false)), "A nested folder must be creatable."):
		_finish()
		return
	var pregnancy: Dictionary = pregnancy_result.get("folder", {})
	var pregnancy_id := str(pregnancy.get("id", ""))
	_folder_ids.append(pregnancy_id)

	var notebook_a := _create_notebook("She Got Pregnant " + stamp, pregnancy_id)
	var notebook_b := _create_notebook("Give Us a Baby " + stamp, pregnancy_id)
	var notebook_c := _create_notebook("Romance Club " + stamp, high_id)
	if notebook_a.is_empty() or notebook_b.is_empty() or notebook_c.is_empty():
		_finish()
		return
	var idea_a := _save_idea("Pregnancy Idea A " + stamp, notebook_a, "pregnancy")
	var idea_b := _save_idea("Pregnancy Idea B " + stamp, notebook_b, "pregnancy")
	var idea_c := _save_idea("Romance Idea C " + stamp, notebook_c, "romance")
	if idea_a.is_empty() or idea_b.is_empty() or idea_c.is_empty():
		_finish()
		return

	_require(
		NOTEBOOK_SERVICE.folder_path(pregnancy_id).contains("High Priority")
		and NOTEBOOK_SERVICE.notebook_path(notebook_a).contains("Pregnancy")
		and NOTEBOOK_SERVICE.notebook_path(notebook_a).contains("She Got Pregnant"),
		"Folder and notebook paths must use stable parent IDs."
	)
	var high_notebooks := NOTEBOOK_SERVICE.notebook_ids_in_folder(high_id, true)
	var pregnancy_notebooks := NOTEBOOK_SERVICE.notebook_ids_in_folder(pregnancy_id, true)
	_require(
		high_notebooks.has(notebook_a)
		and high_notebooks.has(notebook_b)
		and high_notebooks.has(notebook_c),
		"A parent folder must resolve all descendant notebooks."
	)
	_require(
		pregnancy_notebooks.has(notebook_a)
		and pregnancy_notebooks.has(notebook_b)
		and not pregnancy_notebooks.has(notebook_c),
		"A nested folder must resolve only its own descendant notebooks."
	)
	var folder_counts := NOTEBOOK_SERVICE.folder_counts(true)
	_require(
		int(folder_counts.get(high_id, 0)) == 3
		and int(folder_counts.get(pregnancy_id, 0)) == 2,
		"Folder counts must recursively sum direct notebook counts."
	)

	var self_move := NOTEBOOK_SERVICE.move_folder(high_id, high_id)
	var cycle_move := NOTEBOOK_SERVICE.move_folder(high_id, pregnancy_id)
	_require(
		not bool(self_move.get("ok", false))
		and not bool(cycle_move.get("ok", false))
		and str(_folder_by_id(high_id).get("parent_folder_id", "")).is_empty(),
		"Self/descendant moves must be rejected without changing hierarchy."
	)

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
	if not _require(workspace_value is CCFWorkspaceCurrent, "The current Workspace must load."):
		app.queue_free()
		_finish()
		return
	var generator_value: Variant = (workspace_value as CCFWorkspaceCurrent).get("_idea_generator_v01532")
	if not _require(generator_value is CCFIdeaGeneratorWindowCurrent, "The current Idea Generator must load."):
		app.queue_free()
		_finish()
		return
	var generator := generator_value as CCFIdeaGeneratorWindowCurrent
	generator.set("_idea_pack_service_v0210", CCFIdeaPackServiceV0210.new(_test_root))
	generator.open_notebook_v01532()
	await process_frame
	await process_frame
	var tree := generator.find_child("IdeaNotebookFolderTreeV0215", true, false) as Tree
	var tree_panel := generator.find_child("IdeaNotebookTreePanelV0215", true, false)
	var inner_split := generator.find_child("IdeaNotebookIdeasAndDetailsV0215", true, false)
	_require(
		tree != null and tree_panel is VBoxContainer and inner_split is HSplitContainer,
		"Idea Notebook must use a resizable tree / Saved Ideas / Idea Details layout."
	)
	_require(
		_find_tree_item(tree, "special", "__all__") != null
		and _find_tree_item(tree, "special", "__unfiled__") != null
		and _find_tree_item(tree, "folder", pregnancy_id) != null
		and _find_tree_item(tree, "notebook", notebook_a) != null,
		"The tree must render built-in views, nested folders and notebook leaves."
	)
	var high_item := _find_tree_item(tree, "folder", high_id)
	var pregnancy_item := _find_tree_item(tree, "folder", pregnancy_id)
	_require(
		high_item != null and high_item.get_text(0).contains("(3)")
		and pregnancy_item != null and pregnancy_item.get_text(0).contains("(2)"),
		"Folder tree labels must show recursive idea counts."
	)
	if pregnancy_item != null:
		pregnancy_item.select(0)
		generator.call("_on_notebook_tree_selected_v0215")
		var visible_ids: Array = generator.get("_visible_idea_ids_v01532")
		_require(
			visible_ids.has(idea_a) and visible_ids.has(idea_b) and not visible_ids.has(idea_c),
			"Selecting a folder must show ideas from descendant notebooks only."
		)
		var idea_list := generator.get("_idea_list_v01532") as ItemList
		if idea_list != null and idea_list.item_count >= 2:
			idea_list.select(0, false)
			idea_list.select(1, false)
			_require(
				(generator.call("_live_notebook_selected_ids_v0214") as Array).size() == 2,
				"Folder navigation must preserve Saved Ideas multi-selection."
			)

	var search := generator.find_child("NotebookSearchV0211", true, false) as LineEdit
	if search != null:
		search.text = "She Got Pregnant " + stamp
		generator.call("_refresh_notebook_v01532")
		var matched := _find_tree_item(tree, "notebook", notebook_a)
		var matched_parent := _find_tree_item(tree, "folder", pregnancy_id)
		_require(
			matched != null and matched_parent != null and not matched_parent.collapsed,
			"Tree search must reveal a matching nested notebook with its expanded ancestors."
		)
		search.text = ""
		generator.call("_refresh_notebook_v01532")

	generator.call("_build_export_window_v0210")
	var export_scope := generator.get("_export_scope_v0210") as OptionButton
	_require(
		_selector_contains(export_scope, "Notebook: High Priority " + stamp + " / Pregnancy " + stamp + " / She Got Pregnant " + stamp)
		and _selector_contains(export_scope, "Folder: High Priority " + stamp + " / Pregnancy " + stamp),
		"Export scopes must show notebook paths and recursive folder scopes without changing stable IDs."
	)

	var move_result: Variant = generator.call(
		"_on_notebook_tree_drop_v0215", "notebook", notebook_a, high_id
	)
	var moved_notebook := _notebook_by_id(notebook_a)
	var moved_idea := NOTEBOOK_SERVICE.load_idea(idea_a)
	_require(
		move_result == null
		and str(moved_notebook.get("parent_folder_id", "")) == high_id
		and str((moved_idea.get("data", {}) as Dictionary).get("notebook_id", "")) == notebook_a,
		"Moving a notebook must update only its parent and leave every idea reference untouched."
	)

	var delete_folder := NOTEBOOK_SERVICE.delete_folder(pregnancy_id)
	_folder_ids.erase(pregnancy_id)
	_require(
		bool(delete_folder.get("ok", false))
		and str(_notebook_by_id(notebook_b).get("parent_folder_id", "")) == high_id
		and bool(NOTEBOOK_SERVICE.load_idea(idea_b).get("ok", false)),
		"Deleting a folder must reparent direct contents and never delete ideas."
	)

	app.queue_free()
	await process_frame
	_finish()


func _test_v1_migration_and_malformed_recovery() -> void:
	var v1_fixture := {
		"format": NOTEBOOK_SERVICE.LIBRARY_FORMAT,
		"format_version": 1,
		"notebooks": [{"id": "sgp", "name": "She Got Pregnant"}]
	}
	DirAccess.make_dir_recursive_absolute(_test_root)
	var fixture_file := FileAccess.open(_test_root.path_join("library.json"), FileAccess.WRITE)
	if fixture_file != null:
		fixture_file.store_string(JSON.stringify(v1_fixture, "  "))
		fixture_file.close()
	var loaded := NOTEBOOK_SERVICE.load_library()
	var migrated: Dictionary = loaded.get("data", {})
	var migrated_notebooks: Array = migrated.get("notebooks", [])
	_require(
		bool(loaded.get("ok", false))
		and int(migrated.get("format_version", 0)) == NOTEBOOK_SERVICE.LIBRARY_FORMAT_VERSION
		and (migrated.get("folders", []) as Array).is_empty()
		and migrated_notebooks.size() == 1
		and str((migrated_notebooks[0] as Dictionary).get("id", "")) == "sgp"
		and str((migrated_notebooks[0] as Dictionary).get("parent_folder_id", "")).is_empty(),
		"Format-v1 libraries must migrate to root-level notebooks without changing IDs."
	)
	var repaired: Dictionary = NOTEBOOK_SERVICE._normalise_library({
		"notebooks": [{"id": "n", "name": "Notebook", "parent_folder_id": "missing"}],
		"folders": [
			{"id": "a", "name": "A", "parent_folder_id": "b"},
			{"id": "b", "name": "B", "parent_folder_id": "a"},
			{"id": "self", "name": "Self", "parent_folder_id": "self"}
		]
	})
	_require(
		str(((repaired.get("notebooks", []) as Array)[0] as Dictionary).get("parent_folder_id", "")).is_empty()
		and not _library_has_cycle(repaired),
		"Missing, self and cyclic parents must recover safely to root."
	)


func _create_notebook(name: String, parent_id: String) -> String:
	var result := NOTEBOOK_SERVICE.create_notebook(name, parent_id)
	_require(bool(result.get("ok", false)), "Notebook creation inside a folder must succeed.")
	var notebook: Dictionary = result.get("notebook", {})
	var notebook_id := str(notebook.get("id", ""))
	if not notebook_id.is_empty():
		_notebook_ids.append(notebook_id)
	return notebook_id


func _save_idea(title: String, notebook_id: String, tag: String) -> String:
	var result := NOTEBOOK_SERVICE.save_generated_idea(
		{"title": title, "concept": title + " keeps {{user}} agency.", "tags": [tag]},
		notebook_id,
		{"type": "v0215_regression"}
	)
	_require(bool(result.get("ok", false)), "Folder-tree fixture ideas must save.")
	var idea: Dictionary = result.get("idea", {})
	var idea_id := str(idea.get("id", ""))
	if not idea_id.is_empty():
		_idea_ids.append(idea_id)
	return idea_id


func _folder_by_id(folder_id: String) -> Dictionary:
	for folder in NOTEBOOK_SERVICE.list_folders():
		if str(folder.get("id", "")) == folder_id:
			return folder
	return {}


func _notebook_by_id(notebook_id: String) -> Dictionary:
	for notebook in NOTEBOOK_SERVICE.list_notebooks():
		if str(notebook.get("id", "")) == notebook_id:
			return notebook
	return {}


func _find_tree_item(tree: Tree, kind: String, item_id: String) -> TreeItem:
	if tree == null or tree.get_root() == null:
		return null
	var pending: Array[TreeItem] = []
	var child: TreeItem = tree.get_root().get_first_child()
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
		var nested: TreeItem = item.get_first_child()
		while nested != null:
			pending.append(nested)
			nested = nested.get_next()
	return null


func _selector_contains(selector: OptionButton, text: String) -> bool:
	if selector == null:
		return false
	for index in range(selector.item_count):
		if selector.get_item_text(index).contains(text):
			return true
	return false


func _library_has_cycle(library: Dictionary) -> bool:
	var parent_by_id := {}
	for folder_value in library.get("folders", []):
		var folder: Dictionary = folder_value
		parent_by_id[str(folder.get("id", ""))] = str(folder.get("parent_folder_id", ""))
	for folder_id_value in parent_by_id.keys():
		var cursor := str(folder_id_value)
		var visited := {}
		while not cursor.is_empty() and parent_by_id.has(cursor):
			if visited.has(cursor):
				return true
			visited[cursor] = true
			cursor = str(parent_by_id.get(cursor, ""))
	return false


func _cleanup() -> void:
	for idea_id in _idea_ids:
		NOTEBOOK_SERVICE.delete_idea(idea_id)
	for notebook_id in _notebook_ids:
		NOTEBOOK_SERVICE.delete_notebook(notebook_id)
	for index in range(_folder_ids.size() - 1, -1, -1):
		NOTEBOOK_SERVICE.delete_folder(_folder_ids[index])
	NOTEBOOK_SERVICE.reset_storage_root_after_testing()
	_remove_tree(_test_root)


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


func _finish() -> void:
	_cleanup()
	if _failed:
		quit(1)
		return
	print("V0215_IDEA_NOTEBOOK_FOLDER_TREE_OK")
	quit(0)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_failed = true
	push_error(message)
	return false
