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
	app.queue_free()
	await process_frame
	print("V0210_IDEA_PACK_UI_OK")
	quit(0)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	print("V0210_IDEA_PACK_UI_ERROR: %s" % message)
	quit(1)
	return false
