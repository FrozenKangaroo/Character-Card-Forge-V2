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

	expression_window.hide()
	image_window.hide()
	app.queue_free()
	await process_frame
	print("V0204_EXPRESSION_WINDOW_OK")
	quit(0)
