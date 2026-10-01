extends SceneTree

const TEST_USER_DATA_ISOLATION = preload("res://tools/test_user_data_isolation.gd")
var _test_user_data_isolation := TEST_USER_DATA_ISOLATION.activate("v0215-idea-folder-tree")

const IDEA_SERVICE = preload("res://scripts/services/idea_notebook_service_v01532.gd")

var _failed := false
var _test_root := ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_root = "/tmp/ccf_v0215_folder_tree_%d" % Time.get_ticks_usec()
	IDEA_SERVICE.set_storage_root_for_testing(_test_root)
	_test_legacy_library_migration()
	var root_folder := _folder_id(IDEA_SERVICE.create_folder("High Priority"))
	var nested_folder := _folder_id(IDEA_SERVICE.create_folder("Pregnancy", root_folder))
	var leaf_folder := _folder_id(IDEA_SERVICE.create_folder("She Got Pregnant", nested_folder))
	var sibling_folder := _folder_id(IDEA_SERVICE.create_folder("Romance Club", root_folder))
	var leaf_idea := _idea_id(IDEA_SERVICE.save_generated_idea(
		{"title": "Pregnancy Idea", "concept": "A nested folder idea."}, leaf_folder
	))
	var sibling_idea := _idea_id(IDEA_SERVICE.save_generated_idea(
		{"title": "Romance Idea", "concept": "A sibling folder idea."}, sibling_folder
	))
	_require(
		not root_folder.is_empty() and not nested_folder.is_empty()
		and not leaf_folder.is_empty() and not sibling_folder.is_empty()
		and not leaf_idea.is_empty() and not sibling_idea.is_empty(),
		"The folder-only hierarchy fixture must be created."
	)
	_require(
		IDEA_SERVICE.folder_path(leaf_folder) == "High Priority / Pregnancy / She Got Pregnant",
		"Folder paths must use stable parent IDs."
	)
	var descendants := IDEA_SERVICE.folder_ids_in_folder(root_folder, true)
	_require(
		descendants.has(root_folder) and descendants.has(nested_folder)
		and descendants.has(leaf_folder) and descendants.has(sibling_folder),
		"Recursive Folder scope must include the selected Folder and every child Folder."
	)
	var counts := IDEA_SERVICE.folder_counts(true)
	_require(
		int(counts.get(root_folder, 0)) == 2
		and int(counts.get(nested_folder, 0)) == 1
		and int(counts.get(leaf_folder, 0)) == 1,
		"Recursive Folder counts must include direct Ideas from descendant Folders."
	)
	_require(
		not bool(IDEA_SERVICE.move_folder(root_folder, root_folder).get("ok", false))
		and not bool(IDEA_SERVICE.move_folder(root_folder, leaf_folder).get("ok", false)),
		"Folder self/descendant moves must be rejected."
	)
	var packed := load("res://scenes/main.tscn") as PackedScene
	if _require(packed != null, "The current application scene must load."):
		var app := packed.instantiate()
		root.add_child(app)
		await process_frame
		await process_frame
		await process_frame
		var workspace: Variant = app.get("_workspace")
		var generator: Variant = workspace.get("_idea_generator_v01532") if workspace != null else null
		if _require(generator is CCFIdeaGeneratorWindowCurrent, "The current Idea Library must load."):
			generator.open_notebook_v01532()
			await process_frame
			await process_frame
			var tree := generator.get("_notebook_tree_v0215") as Tree
			_require(
				_find_tree_item(tree, "folder", leaf_folder) != null
				and _find_tree_item(tree, "special", "__all__") != null
				and _find_tree_item(tree, "special", "__unfiled__") != null
				and _find_tree_item(tree, "notebook", leaf_folder) == null,
				"The current hierarchy must render only built-in views and Folder nodes."
			)
			var tab := generator.get("_notebook_tab_v01532") as Control
			_require(tab != null and tab.name == "Idea Library", "The current tab must be named Idea Library.")
			var search := generator.get("_notebook_search_v0211") as LineEdit
			search.text = "She Got Pregnant"
			await process_frame
			_require(_find_tree_item(tree, "folder", leaf_folder) != null,
				"Folder search must retain a matching nested Folder and its ancestor path.")
		app.queue_free()
		await process_frame
	IDEA_SERVICE.reset_storage_root_after_testing()
	_remove_tree(_test_root)
	if _failed:
		quit(1)
		return
	print("V0215_IDEA_FOLDER_TREE_OK")
	quit(0)

func _test_legacy_library_migration() -> void:
	DirAccess.make_dir_recursive_absolute(_test_root.path_join("ideas"))
	_write_json(_test_root.path_join("library.json"), {
		"format": "character_card_forge_idea_notebook", "format_version": 1,
		"created_at": "2026-01-01T00:00:00Z", "updated_at": "2026-01-02T00:00:00Z",
		"folders": [{"id": "legacy-parent", "name": "Legacy Parent", "parent_folder_id": "",
			"created_at": "2026-01-01T00:00:00Z", "updated_at": "2026-01-02T00:00:00Z"}],
		"notebooks": [{"id": "legacy-leaf", "name": "Legacy Notebook", "parent_folder_id": "legacy-parent",
			"created_at": "2026-01-01T01:00:00Z", "updated_at": "2026-01-02T01:00:00Z"}]
	})
	_write_json(_test_root.path_join("ideas/legacy-idea.json"), {
		"format": "character_card_forge_saved_idea", "format_version": 1,
		"id": "legacy-idea", "title": "Legacy", "concept": "Preserved",
		"notebook_id": "legacy-leaf", "created_at": "2026-01-01T02:00:00Z",
		"updated_at": "2026-01-02T02:00:00Z"
	})
	var loaded := IDEA_SERVICE.load_library()
	var data: Dictionary = loaded.get("data", {})
	var migrated_idea: Dictionary = IDEA_SERVICE.load_idea("legacy-idea").get("data", {})
	_require(
		bool(loaded.get("ok", false)) and int(data.get("format_version", 0)) == 3
		and not data.has("notebooks") and _folder_exists(data, "legacy-leaf")
		and str(migrated_idea.get("folder_id", "")) == "legacy-leaf"
		and not migrated_idea.has("notebook_id")
		and str(migrated_idea.get("created_at", "")) == "2026-01-01T02:00:00Z",
		"Legacy Notebooks must migrate to Folders without losing IDs, Idea membership or timestamps."
	)
	_remove_tree(_test_root)
	IDEA_SERVICE.set_storage_root_for_testing(_test_root)

func _folder_exists(library: Dictionary, folder_id: String) -> bool:
	for value in library.get("folders", []):
		if value is Dictionary and str((value as Dictionary).get("id", "")) == folder_id:
			return true
	return false

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

func _write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	_require(file != null, "Fixture JSON must be writable.")
	if file != null:
		file.store_string(JSON.stringify(value, "\t") + "\n")

func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_failed = true
	push_error(message)
	return false

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
