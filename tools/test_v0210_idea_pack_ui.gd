extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The current main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	if not _require(workspace_value is CCFWorkspaceCurrent, "The live shell must install the current Workspace."):
		return
	var workspace := workspace_value as CCFWorkspaceCurrent
	var generator_value: Variant = workspace.get("_idea_generator_v01532")
	if not _require(generator_value is CCFIdeaGeneratorWindowCurrent, "The live Workspace must install the Idea Pack-aware Idea Generator."):
		return
	var generator := generator_value as CCFIdeaGeneratorWindowCurrent
	var import_button := generator.find_child("ImportIdeaPackV0210", true, false) as Button
	var export_button := generator.find_child("ExportIdeaPackV0210", true, false) as Button
	if not _require(import_button != null and export_button != null, "Idea Notebook must expose Import and Export Idea Pack actions."):
		return
	var toolbar := generator.find_child("IdeaPackActionsV0210", true, false)
	var action_row := generator.find_child("IdeaPackActionButtonsV0210", true, false)
	var explanation := generator.find_child("IdeaPackExplanationV0210", true, false)
	if not _require(
		toolbar is VBoxContainer
		and action_row is HFlowContainer
		and explanation is Label
		and import_button.get_parent() == action_row
		and export_button.get_parent() == action_row
		and explanation.get_parent() == toolbar,
		"Idea Pack actions and wrapping help text must use separate rows so the notebook cannot collapse horizontally."
	):
		return
	generator.open_notebook_v01532()
	await process_frame
	await process_frame
	var notebook_value: Variant = generator.get("_notebook_tab_v01532")
	var notebook_splits: Array[Node] = []
	if notebook_value is VBoxContainer:
		notebook_splits = (notebook_value as VBoxContainer).find_children("*", "HSplitContainer", true, false)
	var notebook_split := notebook_splits[0] as HSplitContainer if not notebook_splits.is_empty() else null
	var layout_measurements := "toolbar=%s action_row=%s explanation=%s split=%s" % [
		str((toolbar as VBoxContainer).size),
		str((action_row as HFlowContainer).size),
		str((explanation as Label).size),
		str(notebook_split.size) if notebook_split != null else "missing"
	]
	if not _require(
		(toolbar as VBoxContainer).size.y < 140.0
		and (action_row as HFlowContainer).size.y < 80.0
		and (explanation as Label).size.x > 400.0
		and notebook_split != null
		and notebook_split.size.x > 650.0
		and notebook_split.size.y > 140.0,
		"The visible Idea Notebook must retain a compact action toolbar and usable full-width editor split (%s)." % layout_measurements
	):
		return
	generator.hide()
	var structured_details := generator.find_child("StructuredIdeaDetailsV0210", true, false)
	if not _require(structured_details != null, "Idea Notebook must expose structured semantic details for imported entries."):
		return
	var import_dialog_value: Variant = generator.get("_import_dialog_v0210")
	var preview_value: Variant = generator.get("_import_preview_v0210")
	var export_window_value: Variant = generator.get("_export_window_v0210")
	if not _require(
		import_dialog_value is FileDialog
		and preview_value is Window
		and export_window_value is Window,
		"Idea Pack file selection, staged preview and export windows must be constructed."
	):
		return
	if not _require(
		not (import_dialog_value as FileDialog).visible
		and not (preview_value as Window).visible
		and not (export_window_value as Window).visible,
		"Idea Pack windows must stay hidden until explicitly requested."
	):
		return
	var filters := (import_dialog_value as FileDialog).filters
	if not _require(
		filters.size() >= 2
		and str(filters[0]).contains("*.ccfideas.json")
		and str(filters[1]).contains("*.json"),
		"The primary file workflow must accept Idea Pack and generic JSON files."
	):
		return
	if not _test_export_scope_selection(generator, export_button):
		return
	if not _test_export_context_freshness(generator):
		return
	if not _test_independent_file_dialogs(generator):
		return
	app.queue_free()
	await process_frame
	print("V0210_IDEA_PACK_UI_OK")
	quit(0)


func _test_export_scope_selection(
	generator: CCFIdeaGeneratorWindowCurrent,
	notebook_export_button: Button
) -> bool:
	generator.call("_build_export_window_v0210")
	var scope := generator.get("_export_scope_v0210") as OptionButton
	if not _require(scope != null, "Idea Pack export must expose Selection scope."):
		return false
	_require(
		notebook_export_button.text == "Choose Ideas & Export…",
		"The Notebook action should describe opening a checked-idea export workflow."
	)
	var final_action_found := false
	var export_window := generator.get("_export_window_v0210") as Window
	for node in export_window.find_children("*", "Button", true, false):
		if node is Button and (node as Button).text == "Export Checked Ideas…":
			final_action_found = true
	_require(
		final_action_found,
		"The final export action should clearly export the checked rows."
	)

	var ideas: Array[Dictionary] = [
		_export_test_idea("local-a1", "entry-a1", "Series A — One", "Bible A", ["Series A"]),
		_export_test_idea("local-a2", "entry-a2", "Series A — Two", "Bible A", ["Series A"]),
		_export_test_idea("local-b1", "entry-b1", "Series B — One", "Bible B", ["Series B"]),
		_export_test_idea("local-b2", "entry-b2", "Series B — Two", "Bible A", ["Series B"])
	]
	var rows: Array[Dictionary] = []
	for idea in ideas:
		var check := CheckBox.new()
		check.button_pressed = false
		rows.append({"check": check, "idea": idea})
	generator.set("_export_rows_v0210", rows)
	scope.clear()
	generator.call("_add_export_scope_v0210", "All ideas", {"kind": "all", "value": ""})
	generator.call("_add_export_scope_v0210", "Selected idea", {"kind": "selected", "value": "local-b1"})
	generator.call("_add_export_scope_v0210", "Bible: Bible A", {"kind": "bible", "value": "Bible A"})
	generator.call("_add_export_scope_v0210", "Series: Series A", {"kind": "series", "value": "Series A"})
	generator.call("_add_export_scope_v0210", "Series: Series B", {"kind": "series", "value": "Series B"})

	_apply_scope(generator, scope, 0)
	if not _require(
		_checked(rows) == [true, true, true, true]
		and _visible(rows) == [true, true, true, true],
		"All ideas scope must initialise and show every row."
	):
		return false
	generator.call("_set_export_selection_v0210", false)
	if not _require(
		_checked(rows) == [false, false, false, false],
		"All ideas + Select None must deselect every row."
	):
		return false
	generator.call("_set_export_selection_v0210", true)
	if not _require(
		_checked(rows) == [true, true, true, true],
		"All ideas + Select All must select every row."
	):
		return false

	_apply_scope(generator, scope, 3)
	(rows[2].get("check") as CheckBox).button_pressed = true
	(rows[3].get("check") as CheckBox).button_pressed = false
	generator.call("_set_export_selection_v0210", true)
	if not _require(
		_checked(rows) == [true, true, true, false]
		and _visible(rows) == [true, true, false, false],
		"Series A + Select All must select only matching rows and preserve Series B states."
	):
		return false
	generator.call("_set_export_selection_v0210", false)
	if not _require(
		_checked(rows) == [false, false, true, false],
		"Series A + Select None must deselect only Series A and preserve Series B states."
	):
		return false
	(rows[0].get("check") as CheckBox).button_pressed = true
	(rows[0].get("check") as CheckBox).button_pressed = false
	if not _require(
		not (rows[0].get("check") as CheckBox).button_pressed,
		"Manual checkbox changes must remain possible after a scope is applied."
	):
		return false

	_apply_scope(generator, scope, 2)
	(rows[2].get("check") as CheckBox).button_pressed = true
	generator.call("_set_export_selection_v0210", false)
	if not _require(
		_checked(rows) == [false, false, true, false]
		and _visible(rows) == [true, true, false, true],
		"Bible A + Select None must affect only Bible A while preserving Bible B."
	):
		return false
	generator.call("_set_export_selection_v0210", true)
	if not _require(
		_checked(rows) == [true, true, true, true],
		"Bible A + Select All must select all Bible A rows without changing Bible B."
	):
		return false

	_apply_scope(generator, scope, 1)
	(rows[0].get("check") as CheckBox).button_pressed = true
	generator.call("_set_export_selection_v0210", false)
	if not _require(
		_checked(rows) == [true, false, false, false]
		and _visible(rows) == [false, false, true, false],
		"Selected idea + Select None must affect only the scoped idea."
	):
		return false
	generator.call("_set_export_selection_v0210", true)
	if not _require(
		_checked(rows) == [true, false, true, false],
		"Selected idea + Select All must select only the scoped idea and preserve other rows."
	):
		return false
	_apply_scope(generator, scope, 3)
	if not _require(
		_checked(rows) == [true, true, false, false],
		"Changing scope must initialise selection for the newly matching ideas."
	):
		return false

	(rows[0].get("check") as CheckBox).button_pressed = true
	(rows[1].get("check") as CheckBox).button_pressed = false
	(rows[2].get("check") as CheckBox).button_pressed = true
	(rows[3].get("check") as CheckBox).button_pressed = false
	generator.call("_choose_export_path_v0210")
	var pending: Array = generator.get("_pending_export_ideas_v0210")
	if not _require(
		pending.size() == 2
		and str((pending[0] as Dictionary).get("id", "")) == "local-a1"
		and str((pending[1] as Dictionary).get("id", "")) == "local-b1",
		"Export must include exactly the checked rows and no unchecked rows."
	):
		return false
	var pack_service := generator.get("_idea_pack_service_v0210") as CCFIdeaPackServiceV0210
	var pack := pack_service.build_export_pack(pending, {
		"id": "scope-regression-pack",
		"title": "Scope Regression Pack",
		"description": "Selection-only regression metadata",
		"source_version": "unchanged"
	})
	var reparsed := pack_service.parse_text(JSON.stringify(pack))
	return _require(
		str(pack.get("format", "")) == CCFIdeaPackServiceV0210.FORMAT_ID
		and int(pack.get("schema_version", 0)) == CCFIdeaPackServiceV0210.SCHEMA_VERSION
		and str((pack.get("pack", {}) as Dictionary).get("description", "")) == "Selection-only regression metadata"
		and (pack.get("entries", []) as Array).size() == 2
		and bool(reparsed.get("import_allowed", false)),
		"Idea Pack format, metadata and import compatibility must remain unchanged."
	)


func _test_export_context_freshness(
	generator: CCFIdeaGeneratorWindowCurrent
) -> bool:
	var test_root := "user://ccf_v0210_export_context_%d" % Time.get_ticks_usec()
	var service := CCFIdeaPackServiceV0210.new(test_root)
	var entries: Array[Dictionary] = [
		_export_test_entry("series-a", "series", "Series A", "Bible A", ["Series A"]),
		_export_test_entry("series-b", "series", "Series B", "Bible B", ["Series B"]),
		_export_test_entry("idea-a", "seed", "Idea A", "Bible A", ["Series A"]),
		_export_test_entry("idea-b", "seed", "Idea B", "Bible B", ["Series B"]),
		_export_test_entry("bible-context", "series", "Bible Context", "Bible C", [])
	]
	var preview := service.parse_text(JSON.stringify({
		"format": CCFIdeaPackServiceV0210.FORMAT_ID,
		"schema_version": CCFIdeaPackServiceV0210.SCHEMA_VERSION,
		"pack": {"id": "fresh-context", "title": "Fresh Export Context"},
		"entries": entries
	}))
	var selections: Array[Dictionary] = []
	for index in range(entries.size()):
		selections.append({"index": index, "selected": true, "action": "import"})
	var imported := service.import_preview(preview, selections)
	if not _require(
		bool(imported.get("ok", false)) and int(imported.get("imported", 0)) == entries.size(),
		"Fresh export-context fixtures must import through the unchanged Idea Pack path."
	):
		_remove_tree(test_root)
		return false

	var local_ids := {}
	for idea in service.list_local_ideas(true):
		local_ids[service.original_import_id(idea)] = str(idea.get("id", ""))
	generator.set("_idea_pack_service_v0210", service)
	var notebook_list := generator.get("_idea_list_v01532") as ItemList
	var visible_ids: Array[String] = [
		str(local_ids.get("series-a", "")),
		str(local_ids.get("series-b", "")),
		str(local_ids.get("idea-a", "")),
		str(local_ids.get("idea-b", "")),
		str(local_ids.get("bible-context", ""))
	]
	notebook_list.clear()
	for label in ["Series A", "Series B", "Idea A", "Idea B", "Bible Context"]:
		notebook_list.add_item(label)
	generator.set("_visible_idea_ids_v01532", visible_ids)

	_select_notebook_test_row(notebook_list, 0)
	generator.set("_selected_idea_id_v01532", "stale-series-id")
	generator.call("_open_export_window_v0210")
	var series_a_scope := generator.get("_export_scope_v0210") as OptionButton
	if not _require(
		_scope_metadata(series_a_scope) == {"kind": "series", "value": "Series A"},
		"Opening export from the current Series A Notebook item must select Series A."
	):
		_remove_tree(test_root)
		return false
	(generator.get("_export_window_v0210") as Window).hide()

	_select_notebook_test_row(notebook_list, 1)
	generator.call("_open_export_window_v0210")
	var series_b_scope := generator.get("_export_scope_v0210") as OptionButton
	if not _require(
		_scope_metadata(series_b_scope) == {"kind": "series", "value": "Series B"}
		and not series_a_scope.is_inside_tree(),
		"Reopening after selecting Series B must rebuild fresh context without retaining Series A controls."
	):
		_remove_tree(test_root)
		return false
	(generator.get("_export_window_v0210") as Window).hide()

	_select_notebook_test_row(notebook_list, 2)
	generator.call("_open_export_window_v0210")
	var idea_a_scope := generator.get("_export_scope_v0210") as OptionButton
	if not _require(
		_scope_metadata(idea_a_scope)
		== {"kind": "selected", "value": str(local_ids.get("idea-a", ""))},
		"Selected idea context must reference the current Idea A local ID."
	):
		_remove_tree(test_root)
		return false
	(generator.get("_export_window_v0210") as Window).hide()

	_select_notebook_test_row(notebook_list, 3)
	generator.call("_open_export_window_v0210")
	var idea_b_scope := generator.get("_export_scope_v0210") as OptionButton
	if not _require(
		_scope_metadata(idea_b_scope)
		== {"kind": "selected", "value": str(local_ids.get("idea-b", ""))}
		and _scope_metadata(idea_b_scope) != _scope_metadata(idea_a_scope),
		"Reopening after selecting Idea B must not retain Idea A as the selected-idea scope."
	):
		_remove_tree(test_root)
		return false
	(generator.get("_export_window_v0210") as Window).hide()

	_select_notebook_test_row(notebook_list, 4)
	generator.call("_open_export_window_v0210")
	var bible_scope := generator.get("_export_scope_v0210") as OptionButton
	var result := _require(
		_scope_metadata(bible_scope) == {"kind": "bible", "value": "Bible C"},
		"A current Bible-classified Series item with no Series value must initialise its Bible scope."
	)
	(generator.get("_export_window_v0210") as Window).hide()
	_remove_tree(test_root)
	return result


func _test_independent_file_dialogs(
	generator: CCFIdeaGeneratorWindowCurrent
) -> bool:
	var dialogs := {
		"Import Idea Pack": generator.get("_import_dialog_v0210"),
		"Export Idea Pack": generator.get("_export_dialog_v0210"),
		"Load Idea Source": generator.get("_source_load_dialog_v0213"),
		"Export Idea Source": generator.get("_source_export_dialog_v0213")
	}
	for label in dialogs:
		var dialog_value: Variant = dialogs[label]
		if not _require(
			dialog_value is FileDialog,
			"%s must remain a FileDialog." % label
		):
			return false
		var dialog := dialog_value as FileDialog
		if not _require(
			dialog.use_native_dialog
			and dialog.force_native
			and not dialog.exclusive
			and not dialog.always_on_top
			and not dialog.unresizable,
			"%s must use the shared independent native, movable and resizable configuration (native_dialog=%s, force_native=%s, exclusive=%s, always_on_top=%s, unresizable=%s)."
			% [
				label,
				str(dialog.use_native_dialog),
				str(dialog.force_native),
				str(dialog.exclusive),
				str(dialog.always_on_top),
				str(dialog.unresizable)
			]
		):
			return false
	return _require(
		generator.has_method("_configure_independent_file_dialog_v0213"),
		"Idea Generator file dialogs must share one reusable configuration helper."
	)


func _export_test_entry(
	entry_id: String,
	kind: String,
	title: String,
	bible: String,
	series: Array[String]
) -> Dictionary:
	return {
		"id": entry_id,
		"kind": kind,
		"title": title,
		"classification": {
			"bible": bible,
			"primary_series": series,
			"secondary_series": []
		},
		"core_premise": "Fresh export context fixture."
	}


func _select_notebook_test_row(list: ItemList, index: int) -> void:
	list.deselect_all()
	list.select(index)


func _scope_metadata(scope: OptionButton) -> Dictionary:
	if scope == null or scope.selected < 0:
		return {}
	var metadata_value: Variant = scope.get_item_metadata(scope.selected)
	return (metadata_value as Dictionary).duplicate(true) if metadata_value is Dictionary else {}


func _export_test_idea(
	local_id: String,
	entry_id: String,
	title: String,
	bible: String,
	series: Array[String]
) -> Dictionary:
	return {
		"id": local_id,
		"structured_idea": {
			"entry": {
				"id": entry_id,
				"kind": "seed",
				"title": title,
				"classification": {
					"bible": bible,
					"primary_series": series,
					"secondary_series": []
				},
				"core_premise": "Scope selection test premise."
			}
		}
	}


func _apply_scope(
	generator: CCFIdeaGeneratorWindowCurrent,
	scope: OptionButton,
	index: int
) -> void:
	scope.select(index)
	generator.call("_apply_export_scope_v0210", index)


func _checked(rows: Array[Dictionary]) -> Array[bool]:
	var result: Array[bool] = []
	for row in rows:
		result.append((row.get("check") as CheckBox).button_pressed)
	return result


func _visible(rows: Array[Dictionary]) -> Array[bool]:
	var result: Array[bool] = []
	for row in rows:
		result.append((row.get("check") as CheckBox).visible)
	return result


func _remove_tree(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	var directory := DirAccess.open(absolute)
	if directory == null:
		return
	directory.list_dir_begin()
	var item_name := directory.get_next()
	while not item_name.is_empty():
		if item_name != "." and item_name != "..":
			var child := absolute.path_join(item_name)
			if directory.current_is_dir():
				_remove_tree(child)
			else:
				DirAccess.remove_absolute(child)
		item_name = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(absolute)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	print("V0210_IDEA_PACK_UI_ERROR: %s" % message)
	quit(1)
	return false
