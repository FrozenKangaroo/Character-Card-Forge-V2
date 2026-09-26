extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message_text: String) -> void:
	push_error(message_text)
	print("V0205_USER_DOCUMENTATION_ERROR: %s" % message_text)
	quit(1)


func _require(condition: bool, message_text: String) -> bool:
	if condition:
		return true
	_fail(message_text)
	return false


func _run() -> void:
	var problems := CCFHelpContentServiceV0203.validate_catalog()
	var capabilities := CCFHelpContentServiceV0203.capabilities()
	var required_articles: Array[String] = [
		"installation",
		"manual_editing",
		"character_collaborator",
		"ai_review",
		"portable_storage",
		"multi_projects",
		"image_inputs",
		"export_profiles",
		"front_porch_install_sync",
		"text_routes",
		"known_limits_reporting",
	]
	for article_id in required_articles:
		if not _require(
			not CCFHelpContentServiceV0203.article_by_id(article_id).is_empty(),
			"Expanded manual is missing required topic %s." % article_id
		):
			return
	if not _require(
		problems.is_empty()
		and int(capabilities.get("article_count", 0)) >= 49
		and int(capabilities.get("category_count", 0)) == 10,
		"v0.20.5 requires a valid 10-section, 49-topic offline manual. %s"
		% str(problems)
	):
		return

	var app_scene := load("res://scenes/main.tscn") as PackedScene
	var app := app_scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var version_found := false
	for node in app.find_children("*", "Label", true, false):
		if node is Label and node.text in [
			"Godot rewrite • v0.20.5", "Godot rewrite • v0.20.6",
			"Godot rewrite • v0.20.7", "Godot rewrite • v0.20.8", "Godot rewrite • v0.20.9",
			"Godot rewrite • v0.21.0", "Godot rewrite • v0.21.1", "Godot rewrite • v0.21.2"
		]:
			version_found = true
			break
	var help_window := app.get("_help_center_v0203") as CCFHelpCenterWindowV0203
	if not _require(
		version_found and help_window != null,
		"The live application must expose v0.20.5 and retain the offline Help Center."
	):
		return
	help_window.open_help_center("character_collaborator")
	await process_frame
	var category := help_window.find_child("HelpCategoryV0203", true, false) as OptionButton
	var topics := help_window.find_child("HelpTopicListV0203", true, false) as ItemList
	var article_view := help_window.find_child("HelpArticleV0203", true, false) as RichTextLabel
	if not _require(
		help_window.visible
		and category != null
		and category.item_count == 11
		and topics != null
		and topics.item_count >= 49
		and article_view != null
		and article_view.text.contains("Character Collaborator"),
		"The expanded manual must remain readable through the live Help Center."
	):
		return

	var search := help_window.find_child("HelpSearchV0203", true, false) as LineEdit
	search.text = "single-writer"
	search.text_changed.emit(search.text)
	await process_frame
	if not _require(
		help_window.visible_article_count_v0203() >= 1
		and article_view.text.contains("shared-folder"),
		"Expanded Help search must index detailed steps and notes."
	):
		return

	app.queue_free()
	await process_frame
	print("V0205_USER_DOCUMENTATION_OK")
	quit(0)
