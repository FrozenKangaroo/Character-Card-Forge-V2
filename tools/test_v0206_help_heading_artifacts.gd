extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message_text: String) -> void:
	push_error(message_text)
	print("V0206_HELP_HEADING_ARTIFACTS_ERROR: %s" % message_text)
	quit(1)


func _require(condition: bool, message_text: String) -> bool:
	if condition:
		return true
	_fail(message_text)
	return false


func _run() -> void:
	var article := CCFHelpContentServiceV0203.article_by_id("image_studio")
	var rendered := CCFHelpContentServiceV0203.render_article(article)
	if not _require(
		not article.is_empty()
		and rendered.contains("[font_size=26]")
		and rendered.contains("[font_size=19]Steps[/font_size]")
		and rendered.contains("[font_size=19]Good to know[/font_size]")
		and not rendered.contains("[b]")
		and not rendered.contains("[/b]"),
		"Help articles must retain size hierarchy without synthetic bold BBCode."
	):
		return

	var app_scene := load("res://scenes/main.tscn") as PackedScene
	var app := app_scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var help_window := app.get("_help_center_v0203") as CCFHelpCenterWindowV0203
	if not _require(help_window != null, "The active app must retain the Help Center."):
		return
	help_window.open_help_center("image_studio")
	await process_frame
	var article_view := help_window.find_child(
		"HelpArticleV0203", true, false
	) as RichTextLabel
	if not _require(
		article_view != null
		and article_view.bbcode_enabled
		and article_view.text == rendered
		and not article_view.text.contains("[b]"),
		"The live Help Center must display the artifact-safe article rendering."
	):
		return

	var search := help_window.find_child("HelpSearchV0203", true, false) as LineEdit
	search.text = "query with no matching help topic v0206"
	search.text_changed.emit(search.text)
	await process_frame
	if not _require(
		article_view.text.contains("No matching help topics")
		and not article_view.text.contains("[b]"),
		"The empty-search heading must also avoid synthetic bold rendering."
	):
		return

	app.queue_free()
	await process_frame
	print("V0206_HELP_HEADING_ARTIFACTS_OK")
	quit(0)
