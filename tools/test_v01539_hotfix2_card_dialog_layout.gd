extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V01539_HOTFIX2_REGRESSION_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _control_rect_inside_window(control: Control, window: Window) -> Rect2:
	var local_position := control.position
	var parent := control.get_parent()
	while parent != null and parent != window:
		if parent is Control:
			local_position += (parent as Control).position
		parent = parent.get_parent()
	return Rect2(local_position, control.size)


func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	if not _require(scene != null, "The real main scene must load."):
		return
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame

	var workspace_value: Variant = app.get("_workspace")
	if not _require(workspace_value is CCFWorkspaceV01539View, "The live app must retain the v0.15.39 Workspace."):
		return
	var workspace := workspace_value as CCFWorkspaceV01539View
	var collaborator_value: Variant = workspace.get("_character_collaborator_window")
	if not _require(collaborator_value is CCFCharacterCollaboratorWindowV01539, "The live Workspace must install the v0.15.39 Collaborator."):
		return
	var collaborator := collaborator_value as CCFCharacterCollaboratorWindowV01539

	var dialog_value: Variant = collaborator.get("_card_ingestion_dialog_v01539")
	var add_value: Variant = collaborator.get("_card_ingestion_add_button_v01539")
	var cancel_value: Variant = collaborator.get("_card_ingestion_cancel_button_v01539")
	var mode_value: Variant = collaborator.get("_card_ingestion_mode_v01539")
	var hint_value: Variant = collaborator.get("_card_ingestion_hint_v01539")
	if not _require(dialog_value is ConfirmationDialog, "Character Card ingestion must still use a ConfirmationDialog shell."):
		return
	if not _require(add_value is Button and cancel_value is Button, "The dialog must expose explicit Add and Cancel buttons inside its custom content."):
		return
	if not _require(mode_value is OptionButton and (mode_value as OptionButton).item_count == 3, "The three ingestion choices must remain available."):
		return
	if not _require(hint_value is Label and (hint_value as Label).custom_minimum_size.x >= 680.0, "Wrapped dialog text must have a stable width before minimum-height calculation."):
		return
	var dialog := dialog_value as ConfirmationDialog
	var add_button := add_value as Button
	var cancel_button := cancel_value as Button
	if not _require(add_button.text == "Add" and cancel_button.text == "Cancel", "The visible action buttons must be labelled Add and Cancel."):
		return
	if not _require(add_button.visible and cancel_button.visible, "The custom action buttons must be visible controls."):
		return
	if not _require(not dialog.get_ok_button().visible and not dialog.get_cancel_button().visible, "Hidden native action buttons must not duplicate the custom action row."):
		return

	# Exercise the same long-label path as the desktop regression. Native child
	# windows do not reliably report visible=true under --headless, so this test
	# validates the layout geometry rather than OS/window-manager visibility state.
	collaborator.set("_pending_card_ingestions_v01539", [{
		"path": "/tmp/A very long Character Card filename used to reproduce the missing button layout regression.png",
		"source": {
			"label": "A very long Character Card filename used to reproduce the missing button layout regression",
			"source_context_id": "layout-regression-source"
		}
	}])
	collaborator.call("_show_next_card_ingestion_v01539")
	await process_frame
	await process_frame

	if not _require(dialog.size.x >= 700 and dialog.size.y <= 520, "The mode dialog must keep a wide, bounded geometry instead of expanding to desktop height."):
		return
	var add_rect := _control_rect_inside_window(add_button, dialog)
	var cancel_rect := _control_rect_inside_window(cancel_button, dialog)
	if not _require(add_rect.size.y > 0.0 and cancel_rect.size.y > 0.0, "Visible action buttons must receive real layout rectangles."):
		return
	if not _require(add_rect.end.y <= float(dialog.size.y) + 1.0 and cancel_rect.end.y <= float(dialog.size.y) + 1.0, "Add and Cancel must remain inside the dialog's bounded content geometry."):
		return

	dialog.hide()
	app.queue_free()
	await process_frame
	print("v0.15.39-hotfix2 Character Card dialog layout regression passed")
	quit(0)
