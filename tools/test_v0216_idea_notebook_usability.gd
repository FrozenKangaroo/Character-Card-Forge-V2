extends SceneTree

const NOTEBOOK_SERVICE = preload(
	"res://scripts/services/idea_notebook_service_v01532.gd"
)

var _failed := false
var _test_root := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_root = "/tmp/ccf_v0216_notebook_usability_%d" % Time.get_ticks_usec()
	NOTEBOOK_SERVICE.set_storage_root_for_testing(_test_root)
	var empty_folder_id := _folder_id(NOTEBOOK_SERVICE.create_folder("Empty Folder"))
	var series_folder_id := _folder_id(NOTEBOOK_SERVICE.create_folder("Series Folder"))
	var arc_folder_id := _folder_id(
		NOTEBOOK_SERVICE.create_folder("Arc Folder", series_folder_id)
	)
	var root_notebook_id := _notebook_id(
		NOTEBOOK_SERVICE.create_notebook("Root Notebook")
	)
	var arc_notebook_id := _notebook_id(
		NOTEBOOK_SERVICE.create_notebook("Arc Notebook", arc_folder_id)
	)
	var idea_ids: Array[String] = []
	for index in range(9):
		idea_ids.append(_idea_id(NOTEBOOK_SERVICE.save_generated_idea(
			{
				"title": "Batch Idea %02d" % index,
				"concept": "Batch idea %02d preserves {{user}} agency." % index,
				"tags": ["batch"]
			},
			arc_notebook_id,
			{"type": "v0216_regression"}
		)))
	var root_idea_id := _idea_id(NOTEBOOK_SERVICE.save_generated_idea(
		{"title": "Root Idea", "concept": "Root fixture."},
		root_notebook_id,
		{"type": "v0216_regression"}
	))
	var unfiled_idea_id := _idea_id(NOTEBOOK_SERVICE.save_generated_idea(
		{"title": "Unfiled Idea", "concept": "Unfiled fixture."},
		"",
		{"type": "v0216_regression"}
	))
	if not _require(
		not empty_folder_id.is_empty()
		and not series_folder_id.is_empty()
		and not arc_folder_id.is_empty()
		and not root_notebook_id.is_empty()
		and not arc_notebook_id.is_empty()
		and idea_ids.size() == 9,
		"The v0.21.6 usability fixture must be created."
	):
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
	if not _require(
		generator is CCFIdeaGeneratorWindowCurrent,
		"The current Idea Generator must load."
	):
		app.queue_free()
		_finish()
		return
	generator.open_notebook_v01532()
	await process_frame
	await process_frame
	var tree := generator.get("_notebook_tree_v0215") as Tree
	var idea_list := generator.get("_idea_list_v01532") as ItemList
	var summary := generator.get("_idea_result_summary_v0211") as Label

	_test_tree_presentation(
		generator, tree, empty_folder_id, series_folder_id,
		arc_folder_id, root_notebook_id, arc_notebook_id
	)
	_test_dialog_states(
		generator, tree, series_folder_id, arc_folder_id,
		root_notebook_id, arc_notebook_id
	)
	_test_scope_summaries(
		generator, tree, summary, series_folder_id,
		arc_notebook_id, idea_ids.size(), unfiled_idea_id
	)
	await _test_delete_keyboard_safety(generator, tree, idea_list, arc_notebook_id)
	_test_single_and_batch_delete(
		generator, tree, idea_list, arc_notebook_id, series_folder_id, idea_ids
	)

	_require(
		bool(NOTEBOOK_SERVICE.load_idea(root_idea_id).get("ok", false))
		and bool(NOTEBOOK_SERVICE.load_idea(unfiled_idea_id).get("ok", false)),
		"Deletion in one Notebook must not affect unrelated or Unfiled ideas."
	)
	app.queue_free()
	await process_frame
	_finish()


func _test_tree_presentation(
	generator: Variant, tree: Tree, empty_folder_id: String,
	series_folder_id: String, arc_folder_id: String,
	root_notebook_id: String, arc_notebook_id: String
) -> void:
	var empty_folder := _find_tree_item(tree, "folder", empty_folder_id)
	var populated_folder := _find_tree_item(tree, "folder", series_folder_id)
	var nested_folder := _find_tree_item(tree, "folder", arc_folder_id)
	var root_notebook := _find_tree_item(tree, "notebook", root_notebook_id)
	var nested_notebook := _find_tree_item(tree, "notebook", arc_notebook_id)
	var all_ideas := _find_tree_item(tree, "special", "__all__")
	var unfiled := _find_tree_item(tree, "special", "__unfiled__")
	_require(
		_presentation_kind(empty_folder) == "folder"
		and _presentation_kind(populated_folder) == "folder"
		and _presentation_kind(nested_folder) == "folder"
		and _presentation_kind(root_notebook) == "notebook"
		and _presentation_kind(nested_notebook) == "notebook"
		and _presentation_kind(all_ideas) == "special"
		and _presentation_kind(unfiled) == "special",
		"Folders, Notebooks and built-in views must expose distinct semantic presentation metadata regardless of nesting."
	)
	_require(
		empty_folder != null
		and empty_folder.get_first_child() == null
		and empty_folder.get_icon(0) != null
		and populated_folder != null
		and populated_folder.get_icon(0) == empty_folder.get_icon(0)
		and root_notebook != null
		and root_notebook.get_icon(0) != empty_folder.get_icon(0)
		and all_ideas != null
		and all_ideas.get_icon(0) != root_notebook.get_icon(0),
		"An empty Folder must carry the same Folder icon as populated Folders, while Notebooks and built-in views use different shapes."
	)
	var folder_descriptor: Dictionary = generator.call(
		"_tree_presentation_descriptor_v0216", "folder", empty_folder_id
	)
	_require(
		str(folder_descriptor.get("label", "")) == "Folder"
		and str(folder_descriptor.get("tooltip", "")).contains("descendant notebooks"),
		"Folder identity must remain understandable without relying on color or children."
	)


func _test_dialog_states(
	generator: Variant, tree: Tree, series_folder_id: String,
	arc_folder_id: String, root_notebook_id: String, arc_notebook_id: String
) -> void:
	_assert_dialog(
		generator, tree, "special", "__all__", "new_folder",
		"Create Folder", "Root", "Folder name", "Create Folder"
	)
	_assert_dialog(
		generator, tree, "folder", arc_folder_id, "new_folder",
		"Create Folder", "Series Folder / Arc Folder", "Folder name", "Create Folder"
	)
	_assert_dialog(
		generator, tree, "special", "__all__", "new_notebook",
		"Create Notebook", "Root", "Notebook name", "Create Notebook"
	)
	_assert_dialog(
		generator, tree, "folder", arc_folder_id, "new_notebook",
		"Create Notebook", "Series Folder / Arc Folder", "Notebook name", "Create Notebook"
	)
	_assert_dialog(
		generator, tree, "folder", series_folder_id, "rename",
		"Rename Folder", "Rename this folder", "Folder name", "Rename Folder"
	)
	_assert_dialog(
		generator, tree, "notebook", root_notebook_id, "rename",
		"Rename Notebook", "Rename this notebook", "Notebook name", "Rename Notebook"
	)
	var folder_item := _find_tree_item(tree, "folder", series_folder_id)
	_select_tree_item(generator, folder_item)
	generator.call("_open_tree_name_dialog_v0215", "new_folder")
	var name_input := generator.get("_name_input_v01532") as LineEdit
	_require(
		name_input != null and name_input.placeholder_text != "Notebook name",
		"A Folder operation must never retain the legacy Notebook placeholder."
	)
	(generator.get("_name_dialog_v01532") as ConfirmationDialog).hide()
	var nested_notebook := _find_tree_item(tree, "notebook", arc_notebook_id)
	_require(
		nested_notebook != null,
		"Dialog tests must not alter nested Notebook identity."
	)


func _assert_dialog(
	generator: Variant, tree: Tree, kind: String, item_id: String, action: String,
	expected_title: String, expected_description: String,
	expected_placeholder: String, expected_confirm: String
) -> void:
	_select_tree_item(generator, _find_tree_item(tree, kind, item_id))
	generator.call("_open_tree_name_dialog_v0215", action)
	var dialog := generator.get("_name_dialog_v01532") as ConfirmationDialog
	var input := generator.get("_name_input_v01532") as LineEdit
	_require(
		dialog != null
		and input != null
		and dialog.title == expected_title
		and dialog.dialog_text.contains(expected_description)
		and input.placeholder_text == expected_placeholder
		and dialog.ok_button_text == expected_confirm,
		"%s must use action-specific title, description, placeholder and confirmation wording."
		% expected_title
	)
	dialog.hide()


func _test_scope_summaries(
	generator: Variant, tree: Tree, summary: Label,
	series_folder_id: String, notebook_id: String,
	idea_count: int, _unfiled_idea_id: String
) -> void:
	_select_tree_item(generator, _find_tree_item(tree, "folder", series_folder_id))
	_require(
		summary.text.contains("Folder: Series Folder")
		and summary.text.contains("%d ideas across 1 notebook" % idea_count),
		"Folder scope feedback must name the Folder and report recursive ideas/notebooks."
	)
	_select_tree_item(generator, _find_tree_item(tree, "notebook", notebook_id))
	_require(
		summary.text.contains("Notebook: Series Folder / Arc Folder / Arc Notebook")
		and summary.text.contains("%d ideas" % idea_count),
		"Notebook scope feedback must use its full path without calling it a Folder."
	)
	_select_tree_item(generator, _find_tree_item(tree, "special", "__all__"))
	_require(
		summary.text.begins_with("All Ideas\n"),
		"All Ideas must retain distinct built-in scope wording."
	)
	_select_tree_item(generator, _find_tree_item(tree, "special", "__unfiled__"))
	_require(
		summary.text.begins_with("Unfiled\n") and summary.text.contains("1 idea"),
		"Unfiled must retain distinct built-in scope wording and count."
	)


func _test_delete_keyboard_safety(
	generator: Variant, tree: Tree, idea_list: ItemList, notebook_id: String
) -> void:
	_select_tree_item(generator, _find_tree_item(tree, "notebook", notebook_id))
	idea_list.deselect_all()
	idea_list.select(0, false)
	generator.call("_on_idea_multi_selected_v0214", 0, true)
	idea_list.grab_focus()
	await process_frame
	var delete_event := InputEventKey.new()
	delete_event.pressed = true
	delete_event.keycode = KEY_DELETE
	generator.call("_on_idea_list_gui_input_v0216", delete_event)
	_require(
		(generator.get("_pending_delete_idea_ids_v0216") as Array).size() == 1,
		"Delete with Saved Ideas focused must open the shared one-item deletion request."
	)
	_cancel_delete(generator)
	idea_list.select(1, false)
	generator.call("_on_idea_multi_selected_v0214", 1, true)
	idea_list.grab_focus()
	await process_frame
	generator.call("_on_idea_list_gui_input_v0216", delete_event)
	_require(
		(generator.get("_pending_delete_idea_ids_v0216") as Array).size() == 2,
		"Delete with multiple Saved Ideas focused must open the same batch deletion request."
	)
	_cancel_delete(generator)
	var protected_controls: Array[Control] = [
		generator.get("_title_v01532") as LineEdit,
		generator.get("_concept_v01532") as TextEdit,
		generator.get("_notes_v01532") as TextEdit,
		generator.get("_tags_v01532") as LineEdit,
		generator.get("_search_v01532") as LineEdit,
		generator.get("_name_input_v01532") as LineEdit
	]
	for control in protected_controls:
		if control == null:
			continue
		control.grab_focus()
		await process_frame
		generator.call("_on_idea_list_gui_input_v0216", delete_event)
		_require(
			(generator.get("_pending_delete_idea_ids_v0216") as Array).is_empty(),
			"Delete while editing %s must not request Idea deletion." % control.get_class()
		)


func _test_single_and_batch_delete(
	generator: Variant, tree: Tree, idea_list: ItemList,
	notebook_id: String, folder_id: String, original_ids: Array[String]
) -> void:
	_select_tree_item(generator, _find_tree_item(tree, "notebook", notebook_id))
	var visible_ids: Array = generator.get("_visible_idea_ids_v01532")
	idea_list.deselect_all()
	idea_list.select(0, false)
	generator.call("_on_idea_multi_selected_v0214", 0, true)
	var delete_button := generator.get("_delete_idea_button_v01532") as Button
	generator.call("_request_delete_idea_v01532")
	var delete_dialog := generator.get("_delete_idea_dialog_v01532") as ConfirmationDialog
	_require(
		delete_button != null and delete_button.text == "Delete Idea…"
		and delete_dialog.title == "Delete Saved Idea"
		and delete_dialog.ok_button_text == "Delete Idea"
		and delete_dialog.dialog_text.contains("permanently delete 1 saved idea"),
		"One selected Idea must use one-item confirmation wording."
	)
	var cancel_id := str(visible_ids[0])
	_cancel_delete(generator)
	_require(
		bool(NOTEBOOK_SERVICE.load_idea(cancel_id).get("ok", false)),
		"Cancelling deletion must delete nothing."
	)

	idea_list.deselect_all()
	for index in [1, 2, 3]:
		idea_list.select(index, false)
		generator.call("_on_idea_multi_selected_v0214", index, true)
	var batch_ids := generator.call("_live_notebook_selected_ids_v0214") as Array
	generator.set("_selected_idea_id_v01532", cancel_id)
	generator.call("_request_delete_idea_v01532")
	_require(
		batch_ids.size() == 3
		and delete_button.text == "Delete 3 Ideas…"
		and (generator.get("_pending_delete_idea_ids_v0216") as Array) == batch_ids
		and not cancel_id in batch_ids
		and delete_dialog.title == "Delete Saved Ideas"
		and delete_dialog.ok_button_text == "Delete 3 Ideas"
		and delete_dialog.dialog_text.contains("permanently delete 3 saved ideas"),
		"Batch deletion must use the live ItemList selection, not a different focused Idea."
	)
	var refreshes_before := int(generator.get("_idea_delete_batch_refresh_count_v0216"))
	generator.call("_delete_selected_idea_v01532")
	_require(
		int(generator.get("_idea_delete_batch_refresh_count_v0216")) == refreshes_before + 1,
		"One deletion batch must perform one expensive Notebook refresh."
	)
	for idea_id in batch_ids:
		_require(
			not bool(NOTEBOOK_SERVICE.load_idea(str(idea_id)).get("ok", false)),
			"Every checked Idea in the confirmed batch must be deleted."
		)
	_require(
		bool(NOTEBOOK_SERVICE.load_idea(cancel_id).get("ok", false))
		and str(generator.get("_notebook_tree_selection_id_v0215")) == notebook_id
		and not str(generator.get("_selected_idea_id_v01532")).is_empty()
		and (generator.call("_live_notebook_selected_ids_v0214") as Array).all(
			func(value: Variant) -> bool: return not str(value) in batch_ids
		),
		"Survivors, navigation scope, editor focus and live export selection must remain valid after batch deletion."
	)
	var notebook_item := _find_tree_item(tree, "notebook", notebook_id)
	var folder_item := _find_tree_item(tree, "folder", folder_id)
	_require(
		notebook_item != null and notebook_item.get_text(0).contains("(6)")
		and folder_item != null and folder_item.get_text(0).contains("(6)"),
		"Notebook and recursive Folder counts must update after one batch refresh."
	)

	visible_ids = generator.get("_visible_idea_ids_v01532")
	idea_list.deselect_all()
	idea_list.select(0, false)
	idea_list.select(1, false)
	var valid_id := str(visible_ids[0])
	var preserved_id := str(visible_ids[1])
	visible_ids[1] = "missing-v0216-fixture"
	generator.set("_visible_idea_ids_v01532", visible_ids)
	generator.call("_on_idea_multi_selected_v0214", 0, true)
	generator.call("_on_idea_multi_selected_v0214", 1, true)
	generator.call("_request_delete_idea_v01532")
	refreshes_before = int(generator.get("_idea_delete_batch_refresh_count_v0216"))
	generator.call("_delete_selected_idea_v01532")
	var status := generator.get("_status_v01532") as Label
	_require(
		int(generator.get("_idea_delete_batch_refresh_count_v0216")) == refreshes_before + 1
		and not bool(NOTEBOOK_SERVICE.load_idea(valid_id).get("ok", false))
		and bool(NOTEBOOK_SERVICE.load_idea(preserved_id).get("ok", false))
		and status.text.contains("Deleted 1 saved idea")
		and status.text.contains("1 could not be deleted"),
		"Partial failure must continue the batch, preserve untargeted survivors, report both counts and refresh once."
	)
	visible_ids = generator.get("_visible_idea_ids_v01532")
	var single_id := str(visible_ids[0]) if not visible_ids.is_empty() else ""
	var single_index := visible_ids.find(single_id)
	_require(single_index >= 0, "A surviving single-delete fixture must remain visible.")
	if single_index >= 0:
		idea_list.deselect_all()
		idea_list.select(single_index, false)
		generator.call("_on_idea_multi_selected_v0214", single_index, true)
		generator.call("_request_delete_idea_v01532")
		refreshes_before = int(generator.get("_idea_delete_batch_refresh_count_v0216"))
		generator.call("_delete_selected_idea_v01532")
		_require(
			int(generator.get("_idea_delete_batch_refresh_count_v0216")) == refreshes_before + 1
			and not bool(NOTEBOOK_SERVICE.load_idea(single_id).get("ok", false)),
			"Confirming one selected Idea must use the same one-refresh deletion path."
		)
	_require(
		original_ids.size() == 9,
		"The multi-delete fixture must retain its expected original population."
	)


func _cancel_delete(generator: Variant) -> void:
	generator.call("_cancel_delete_ideas_v0216")
	var dialog := generator.get("_delete_idea_dialog_v01532") as ConfirmationDialog
	if dialog != null:
		dialog.hide()


func _select_tree_item(generator: Variant, item: TreeItem) -> void:
	if item == null:
		_require(false, "The requested hierarchy item must exist.")
		return
	item.select(0)
	generator.call("_on_notebook_tree_selected_v0215")


func _presentation_kind(item: TreeItem) -> String:
	if item == null:
		return ""
	var metadata_value: Variant = item.get_metadata(0)
	if not metadata_value is Dictionary:
		return ""
	return str((metadata_value as Dictionary).get("presentation_kind", ""))


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
		var nested := item.get_first_child()
		while nested != null:
			pending.append(nested)
			nested = nested.get_next()
	return null


func _folder_id(result: Dictionary) -> String:
	return str((result.get("folder", {}) as Dictionary).get("id", ""))


func _notebook_id(result: Dictionary) -> String:
	return str((result.get("notebook", {}) as Dictionary).get("id", ""))


func _idea_id(result: Dictionary) -> String:
	return str((result.get("idea", {}) as Dictionary).get("id", ""))


func _finish() -> void:
	NOTEBOOK_SERVICE.reset_storage_root_after_testing()
	_remove_tree(_test_root)
	if _failed:
		quit(1)
		return
	print("V0216_IDEA_NOTEBOOK_USABILITY_OK")
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
