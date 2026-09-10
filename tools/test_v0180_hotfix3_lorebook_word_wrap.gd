extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0180_HOTFIX3_LOREBOOK_WRAP_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The v0.18.0-hotfix3 main scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame

	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		workspace_value is CCFWorkspaceView,
		"The live app must install a Workspace."
	):
		return
	var workspace := workspace_value as CCFWorkspaceView
	var lorebook_value: Variant = workspace.get("_lorebook_window")
	if not _require(
		lorebook_value is CCFLorebookWindowV01415,
		"The live Workspace must retain the generation-aware Lorebook Manager."
	):
		return
	var lorebook := lorebook_value as CCFLorebookWindowV01415
	var content_value: Variant = lorebook.get("_content_edit")
	var trigger_value: Variant = lorebook.get("_activation_input")
	if not _require(
		content_value is TextEdit
		and trigger_value is TextEdit,
		"Lore content and Trigger Preview must remain multiline text editors."
	):
		return
	var content := content_value as TextEdit
	var trigger := trigger_value as TextEdit
	if not _require(
		content.wrap_mode == TextEdit.LINE_WRAPPING_BOUNDARY
		and trigger.wrap_mode == TextEdit.LINE_WRAPPING_BOUNDARY,
		"Both Lorebook multiline editors must wrap long text at their visible boundary."
	):
		return

	var long_line := (
		"This is one intentionally long lore line that should wrap visually "
		+ "without requiring the author to insert manual line breaks."
	)
	content.text = long_line
	trigger.text = long_line
	if not _require(
		content.text == long_line
		and trigger.text == long_line
		and not content.text.contains("\n")
		and not trigger.text.contains("\n"),
		"Visual wrapping must preserve the author's text without adding stored newlines."
	):
		return

	var version_label_found := false
	for node in app.find_children("*", "Label", true, false):
		if node is Label and node.text == "Godot rewrite • v0.18.0-hotfix3":
			version_label_found = true
			break
	if not _require(
		version_label_found,
		"The development build label must identify v0.18.0-hotfix3."
	):
		return

	app.queue_free()
	await process_frame
	print("v0.18.0-hotfix3 Lorebook word-wrap regression passed")
	quit(0)
