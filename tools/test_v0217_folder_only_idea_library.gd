extends SceneTree

const IDEA_SERVICE = preload("res://scripts/services/idea_notebook_service_v01532.gd")

var _failed := false
var _test_root := ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_root = "/tmp/ccf_v0217_folder_library_%d" % Time.get_ticks_usec()
	IDEA_SERVICE.set_storage_root_for_testing(_test_root)
	_test_collision_migration()
	_remove_tree(_test_root)
	IDEA_SERVICE.set_storage_root_for_testing(_test_root)
	var parent_a := _folder_id(IDEA_SERVICE.create_folder("Worlds"))
	var parent_b := _folder_id(IDEA_SERVICE.create_folder("Characters"))
	var same_a := _folder_id(IDEA_SERVICE.create_folder("Priority", parent_a))
	var same_b := _folder_id(IDEA_SERVICE.create_folder("Priority", parent_b))
	var nested := _folder_id(IDEA_SERVICE.create_folder("Arc One", same_a))
	var nested_idea := _idea_id(IDEA_SERVICE.save_generated_idea(
		{"title": "Nested", "concept": "Nested export fixture."}, nested
	))
	var direct_idea := _idea_id(IDEA_SERVICE.save_generated_idea(
		{"title": "Direct", "concept": "Direct fixture."}, same_a
	))
	var moved_idea := _idea_id(IDEA_SERVICE.save_generated_idea(
		{"title": "Move Me", "concept": "Batch move fixture."}, ""
	))
	_require(
		not same_a.is_empty() and not same_b.is_empty() and same_a != same_b,
		"Identically named Folders must be allowed under different parents."
	)
	var moved := IDEA_SERVICE.move_ideas_to_folder([moved_idea], nested)
	_require(
		bool(moved.get("ok", false))
		and str((IDEA_SERVICE.load_idea(moved_idea).get("data", {}) as Dictionary).get("folder_id", "")) == nested,
		"Batch Idea movement must persist the destination Folder ID."
	)
	var recursive_ids := IDEA_SERVICE.folder_ids_in_folder(same_a, true)
	var recursive_ideas := IDEA_SERVICE.list_ideas({"folder_ids": recursive_ids, "include_archived": true})
	_require(
		recursive_ideas.size() == 3 and recursive_ids.has(same_a) and recursive_ids.has(nested),
		"Recursive Folder scope must include direct and descendant Ideas."
	)
	_test_safe_folder_delete(parent_a, same_a, nested, direct_idea, nested_idea, moved_idea)
	await _test_current_ui(parent_b, same_b)
	IDEA_SERVICE.reset_storage_root_after_testing()
	_remove_tree(_test_root)
	if _failed:
		quit(1)
		return
	print("V0217_FOLDER_ONLY_IDEA_LIBRARY_OK")
	quit(0)

func _test_collision_migration() -> void:
	DirAccess.make_dir_recursive_absolute(_test_root.path_join("ideas"))
	_write_json(_test_root.path_join("library.json"), {
		"format": "character_card_forge_idea_notebook", "format_version": 2,
		"created_at": "2026-01-01T00:00:00Z", "updated_at": "2026-01-02T00:00:00Z",
		"folders": [{"id": "shared-id", "name": "Existing Folder", "parent_folder_id": "",
			"created_at": "2026-01-01T00:00:00Z", "updated_at": "2026-01-02T00:00:00Z"}],
		"notebooks": [{"id": "shared-id", "name": "Former Notebook", "parent_folder_id": "",
			"created_at": "2026-01-03T00:00:00Z", "updated_at": "2026-01-04T00:00:00Z"}]
	})
	_write_json(_test_root.path_join("ideas/collision-idea.json"), {
		"format": "character_card_forge_saved_idea", "format_version": 1,
		"id": "collision-idea", "title": "Collision", "concept": "Must stay accessible.",
		"notebook_id": "shared-id", "created_at": "2026-01-05T00:00:00Z",
		"updated_at": "2026-01-06T00:00:00Z"
	})
	var library_result := IDEA_SERVICE.load_library()
	var library: Dictionary = library_result.get("data", {})
	var alias_id := str((library.get("legacy_notebook_folder_ids", {}) as Dictionary).get("shared-id", ""))
	var idea: Dictionary = IDEA_SERVICE.load_idea("collision-idea").get("data", {})
	var disk_library := _read_json(_test_root.path_join("library.json"))
	var disk_idea := _read_json(_test_root.path_join("ideas/collision-idea.json"))
	_require(
		bool(library_result.get("ok", false)) and int(library.get("format_version", 0)) == 3
		and alias_id == "shared-id-legacy-notebook"
		and _folder_exists(library, "shared-id") and _folder_exists(library, alias_id)
		and str(idea.get("folder_id", "")) == alias_id
		and not disk_library.has("notebooks") and not disk_idea.has("notebook_id")
		and str(disk_idea.get("folder_id", "")) == alias_id,
		"ID collisions must preserve both records and migrate each legacy Idea to a deterministic Folder alias."
	)

func _test_safe_folder_delete(
	parent_id: String, folder_id: String, child_id: String,
	direct_idea: String, child_idea: String, moved_idea: String
) -> void:
	var result := IDEA_SERVICE.delete_folder(folder_id)
	var direct: Dictionary = IDEA_SERVICE.load_idea(direct_idea).get("data", {})
	var child: Dictionary = _folder_by_id(child_id)
	_require(
		bool(result.get("ok", false))
		and str(direct.get("folder_id", "")) == parent_id
		and str(child.get("parent_folder_id", "")) == parent_id
		and str((IDEA_SERVICE.load_idea(child_idea).get("data", {}) as Dictionary).get("folder_id", "")) == child_id
		and str((IDEA_SERVICE.load_idea(moved_idea).get("data", {}) as Dictionary).get("folder_id", "")) == child_id,
		"Deleting a Folder must move direct Ideas and child Folders to its parent without deleting descendant Ideas."
	)
	var root_folder := _folder_id(IDEA_SERVICE.create_folder("Root Delete"))
	var root_idea := _idea_id(IDEA_SERVICE.save_generated_idea(
		{"title": "Root delete", "concept": "Must become Unfiled."}, root_folder
	))
	IDEA_SERVICE.delete_folder(root_folder)
	_require(
		str((IDEA_SERVICE.load_idea(root_idea).get("data", {}) as Dictionary).get("folder_id", "")) == "",
		"Deleting a root Folder must move its direct Ideas to Unfiled."
	)

func _test_current_ui(parent_id: String, folder_id: String) -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The current application scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	await process_frame
	var workspace: Variant = app.get("_workspace")
	var generator: Variant = workspace.get("_idea_generator_v01532") if workspace != null else null
	if not _require(generator is CCFIdeaGeneratorWindowCurrent, "The current Idea Library window must load."):
		app.queue_free()
		return
	generator.open_notebook_v01532()
	await process_frame
	await process_frame
	var selector := OptionButton.new()
	generator.call("_fill_destination_notebooks_v01532", selector, folder_id)
	var texts: Array[String] = []
	for index in range(selector.item_count):
		texts.append(selector.get_item_text(index))
	_require(
		texts.has("Unfiled") and texts.has("Characters / Priority")
		and str(selector.get_item_metadata(selector.selected)) == folder_id,
		"Save/import destination selectors must show Unfiled and full Folder paths."
	)
	var tree := generator.get("_notebook_tree_v0215") as Tree
	var folder_item := _find_tree_item(tree, "folder", folder_id)
	var all_item := _find_tree_item(tree, "special", "__all__")
	var unfiled_item := _find_tree_item(tree, "special", "__unfiled__")
	var drag_payload := {"kind": "ideas", "ids": ["idea-a", "idea-b"]}
	_require(
		_tree_accepts_drop(tree, folder_item, drag_payload)
		and _tree_accepts_drop(tree, unfiled_item, drag_payload)
		and not _tree_accepts_drop(tree, all_item, drag_payload),
		"Idea drag targets must accept Folders and Unfiled while rejecting All Ideas."
	)
	var idea_list := generator.get("_idea_list_v01532") as ItemList
	if _require(idea_list != null and idea_list.item_count >= 2,
		"The drag fixture needs at least two visible Ideas."):
		idea_list.deselect_all()
		idea_list.select(0, false)
		idea_list.select(1, false)
		var dragged_ids: Variant = idea_list.call("drag_idea_ids_for_index_v0217", 0)
		_require(
			dragged_ids is Array and (dragged_ids as Array).size() == 2,
			"Dragging one selected row must carry the complete live multi-selection by stable Idea ID."
		)
	var source := FileAccess.get_file_as_string("res://scripts/ui/idea_generator_window_current.gd")
	var tree_source := FileAccess.get_file_as_string("res://scripts/ui/idea_notebook_tree_v0215.gd")
	var list_source := FileAccess.get_file_as_string("res://scripts/ui/idea_library_list_v0217.gd")
	_require(
		source.contains("folder_ids_in_folder_from_snapshot")
		and source.contains("move_ideas_to_folder")
		and tree_source.contains("signal idea_drop")
		and tree_source.contains("__unfiled__")
		and list_source.contains("get_selected_items"),
		"Current export and drag/drop wiring must support recursive Folders and stable multi-Idea movement."
	)
	var folder_scope_ids := IDEA_SERVICE.folder_ids_in_folder(parent_id, true)
	_require(folder_scope_ids.has(parent_id) and folder_scope_ids.has(folder_id),
		"A recursive export Folder scope must include its selected parent and descendants.")
	selector.queue_free()
	app.queue_free()
	await process_frame

func _tree_accepts_drop(tree: Tree, item: TreeItem, payload: Dictionary) -> bool:
	if tree == null or item == null:
		return false
	var metadata_value: Variant = item.get_metadata(0)
	if not metadata_value is Dictionary:
		return false
	return bool(tree.call(
		"can_accept_drop_metadata_v0217", payload, metadata_value as Dictionary, true
	))

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

func _folder_by_id(folder_id: String) -> Dictionary:
	for folder in IDEA_SERVICE.list_folders():
		if str(folder.get("id", "")) == folder_id:
			return folder
	return {}

func _folder_exists(library: Dictionary, folder_id: String) -> bool:
	for value in library.get("folders", []):
		if value is Dictionary and str((value as Dictionary).get("id", "")) == folder_id:
			return true
	return false

func _folder_id(result: Dictionary) -> String:
	return str((result.get("folder", {}) as Dictionary).get("id", ""))

func _idea_id(result: Dictionary) -> String:
	return str((result.get("idea", {}) as Dictionary).get("id", ""))

func _write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	_require(file != null, "Fixture JSON must be writable.")
	if file != null:
		file.store_string(JSON.stringify(value, "\t") + "\n")

func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}

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
