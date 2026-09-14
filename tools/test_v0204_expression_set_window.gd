extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message_text: String) -> void:
	push_error(message_text)
	print("V0204_EXPRESSION_WINDOW_ERROR: %s" % message_text)
	quit(1)


func _require(condition: bool, message_text: String) -> bool:
	if condition:
		return true
	_fail(message_text)
	return false


func _label_with_text(parent: Node, label_text: String) -> Label:
	for node in parent.find_children("*", "Label", true, false):
		if node is Label and (node as Label).text == label_text:
			return node as Label
	return null


func _button_with_text(parent: Node, button_text: String) -> Button:
	for node in parent.find_children("*", "Button", true, false):
		if node is Button and (node as Button).text == button_text:
			return node as Button
	return null


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame

	var image_window_value: Variant = app.get("_image_generation_window")
	if not _require(
		image_window_value is CCFImageGenerationWindowV0193,
		"The current application must mount the expression-capable Image Studio."
	):
		return
	var image_window := image_window_value as CCFImageGenerationWindowV0193
	var project := CCFStorageService.new_project()
	var characters: Array = project.get("characters", [])
	var character_id := str((characters[0] as Dictionary).get("character_id", ""))
	image_window.sync_saved_project_v01528(project, character_id)
	image_window.ensure_expression_set_surface_v0193()
	image_window.open_studio()
	await process_frame

	var open_button_value: Variant = image_window.get("_expression_set_button_v0193")
	if not _require(
		open_button_value is Button and not (open_button_value as Button).disabled,
		"Generate Expression Set must be enabled for a live project and character."
	):
		return
	(open_button_value as Button).pressed.emit()
	await process_frame
	await process_frame

	var expression_window_value: Variant = image_window.get("_expression_window_v0193")
	if not _require(
		expression_window_value is CCFExpressionSetWindowV0193,
		"The Generate Expression Set action must open its managed window."
	):
		return
	var expression_window := expression_window_value as CCFExpressionSetWindowV0193
	var content := expression_window.find_child(
		"ExpressionSetContentV0204", false, false
	) as Control
	var heading := _label_with_text(
		expression_window, "Generate a reviewable expression set"
	)
	if not _require(
		expression_window.visible
		and expression_window.get_parent() == image_window.get_parent()
		and not expression_window.get_parent() is Window
		and content != null
		and content.is_visible_in_tree()
		and content.size.x > 0.0
		and content.size.y > 0.0
		and heading != null
		and heading.is_visible_in_tree()
		and heading.size.x > 0.0
		and heading.size.y > 0.0,
		"Expression Set must open as an application-level native window with visible, laid-out content."
	):
		return

	var labels := expression_window.find_child(
		"ExpressionSetLabelsV0193", true, false
	) as ItemList
	var generate_button := _button_with_text(
		expression_window, "Generate Selected Expressions…"
	)
	if not _require(
		labels != null and generate_button != null and labels.item_count == 30,
		"The live Expression Set editor must expose all selectable labels and its generation action."
	):
		return
	for label_index in range(labels.item_count):
		labels.select(label_index, false)
	generate_button.pressed.emit()
	await process_frame
	await process_frame
	var create_confirm_value: Variant = expression_window.get("_create_confirm")
	if not _require(
		create_confirm_value is ConfirmationDialog,
		"Selecting expressions must open the managed-batch confirmation dialog."
	):
		return
	var create_confirm := create_confirm_value as ConfirmationDialog
	var confirm_button := create_confirm.get_ok_button()
	var cancel_button := create_confirm.get_cancel_button()
	if not _require(
		create_confirm.visible
		and create_confirm.dialog_text.contains("Generate 30 separate provider requests")
		and confirm_button != null
		and confirm_button.is_visible_in_tree()
		and confirm_button.size.x > 0.0
		and confirm_button.size.y > 0.0
		and confirm_button.position.y + confirm_button.size.y <= create_confirm.size.y
		and cancel_button != null
		and cancel_button.is_visible_in_tree()
		and cancel_button.size.x > 0.0
		and cancel_button.size.y > 0.0
		and cancel_button.position.y + cancel_button.size.y <= create_confirm.size.y,
		"The 30-expression confirmation must keep visible Confirm and Cancel buttons inside the dialog."
	):
		return
	create_confirm.hide()

	expression_window.hide()
	image_window.hide()
	app.queue_free()
	await process_frame
	print("V0204_EXPRESSION_WINDOW_OK")
	quit(0)
