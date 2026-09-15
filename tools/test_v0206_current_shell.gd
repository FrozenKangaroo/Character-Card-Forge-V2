extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message_text: String) -> void:
	push_error(message_text)
	print("V0206_CURRENT_SHELL_ERROR: %s" % message_text)
	quit(1)


func _require(condition: bool, message_text: String) -> bool:
	if condition:
		return true
	_fail(message_text)
	return false


func _run() -> void:
	var app_scene := load("res://scenes/main.tscn") as PackedScene
	var app := app_scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame

	var app_script := app.get_script() as Script
	var version_found := false
	for node in app.find_children("*", "Label", true, false):
		if node is Label and node.text == "Godot rewrite • v0.20.6":
			version_found = true
			break
	var support_button := app.find_child(
		"SupportCenterButtonV0202", true, false
	) as Button
	var help_button := app.find_child("HelpCenterButtonV0203", true, false) as Button
	var support_window := app.get(
		"_support_center_v0202"
	) as CCFSupportCenterWindowV0202
	var help_window := app.get("_help_center_v0203") as CCFHelpCenterWindowV0203
	if not _require(
		app_script != null
		and app_script.resource_path == "res://scripts/main_current.gd"
		and version_found
		and support_button != null
		and help_button != null
		and support_window != null
		and help_window != null,
		"The semantic shell must retain current version, Support and Help navigation."
	):
		return

	app.call("_run_quick_action_v0201", "support_diagnostics")
	await process_frame
	var report_editor := support_window.find_child(
		"PrivacySafeSupportReportV0202", true, false
	) as TextEdit
	if not _require(
		support_window.visible
		and report_editor != null
		and report_editor.text.contains('"version": "0.20.6"'),
		"The consolidated shell must report the actual current build version."
	):
		return
	support_window.hide()

	app.call("_run_quick_action_v0201", "help_center")
	await process_frame
	if not _require(
		help_window.visible
		and help_window.visible_article_count_v0203() >= 49,
		"The consolidated shell must retain the complete offline manual."
	):
		return

	app.queue_free()
	await process_frame
	print("V0206_CURRENT_SHELL_OK")
	quit(0)
