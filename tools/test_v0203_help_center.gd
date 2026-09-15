extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message_text: String) -> void:
	push_error(message_text)
	print("V0203_HELP_CENTER_ERROR: %s" % message_text)
	quit(1)


func _require(condition: bool, message_text: String) -> bool:
	if condition:
		return true
	_fail(message_text)
	return false


func _button_with_text(parent: Node, button_text: String) -> Button:
	for node in parent.find_children("*", "Button", true, false):
		if node is Button and node.text == button_text:
			return node as Button
	return null


func _run() -> void:
	var problems := CCFHelpContentServiceV0203.validate_catalog()
	var capabilities := CCFHelpContentServiceV0203.capabilities()
	if not _require(
		problems.is_empty()
		and int(capabilities.get("format_version", 0)) == 1
		and bool(capabilities.get("offline", false))
		and not bool(capabilities.get("provider_calls", true))
		and not bool(capabilities.get("automatic_network", true))
		and bool(capabilities.get("searchable", false))
		and bool(capabilities.get("task_oriented", false))
		and int(capabilities.get("article_count", 0)) >= 12
		and int(capabilities.get("category_count", 0)) >= 6
		and bool(capabilities.get("routes_to_existing_tools", false)),
		"The versioned help catalog must be valid, task-oriented and offline. %s"
		% str(problems)
	):
		return

	var troubleshooting := CCFHelpContentServiceV0203.search("404")
	var image_topics := CCFHelpContentServiceV0203.search("image", "images")
	var first_character := CCFHelpContentServiceV0203.article_by_id("first_character")
	var rendered := CCFHelpContentServiceV0203.render_article(first_character)
	if not _require(
		troubleshooting.size() == 1
		and str(troubleshooting[0].get("id", "")) == "troubleshooting"
		and not image_topics.is_empty()
		and str(image_topics[0].get("category", "")) == "images"
		and rendered.contains("Create your first character")
		and rendered.contains("[b]1.[/b]"),
		"Search, category filtering and task rendering must remain deterministic."
	):
		return

	var quick_action_ids: Array[String] = []
	for action in CCFWorkflowDiscoveryServiceV0201.quick_actions():
		quick_action_ids.append(str(action.get("id", "")))
	for article in CCFHelpContentServiceV0203.articles():
		for action_value in article.get("actions", []):
			if not _require(
				action_value is Dictionary
				and str((action_value as Dictionary).get("id", "")) in quick_action_ids,
				"Every Help Center action must route through an existing Quick Action."
			):
				return

	var app_scene := load("res://scenes/main.tscn") as PackedScene
	var app := app_scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var help_button := app.find_child("HelpCenterButtonV0203", true, false) as Button
	var help_window := app.get("_help_center_v0203") as CCFHelpCenterWindowV0203
	var version_found := false
	for node in app.find_children("*", "Label", true, false):
		if node is Label and node.text in [
			"Godot rewrite • v0.20.3",
			"Godot rewrite • v0.20.4",
			"Godot rewrite • v0.20.5",
			"Godot rewrite • v0.20.6"
		]:
			version_found = true
			break
	if not _require(
		help_button != null
		and help_button.tooltip_text.contains("offline")
		and help_window != null
		and version_found
		and help_window.find_children("*", "HTTPRequest", true, false).is_empty(),
		"The live v0.20.3 app must expose an offline Help Center in permanent navigation."
	):
		return

	app.call("_run_quick_action_v0201", "help_center")
	await process_frame
	var search := help_window.find_child("HelpSearchV0203", true, false) as LineEdit
	var category := help_window.find_child("HelpCategoryV0203", true, false) as OptionButton
	var topics := help_window.find_child("HelpTopicListV0203", true, false) as ItemList
	var article_view := help_window.find_child("HelpArticleV0203", true, false) as RichTextLabel
	if not _require(
		help_window.visible
		and search != null
		and category != null
		and category.item_count == int(capabilities.get("category_count", 0)) + 1
		and topics != null
		and topics.item_count >= 12
		and article_view != null
		and article_view.text.contains("First launch"),
		"The Help Center must open with searchable topics, categories and a readable article."
	):
		return

	search.text = "404"
	search.text_changed.emit(search.text)
	await process_frame
	if not _require(
		help_window.visible_article_count_v0203() == 1
		and help_window.selected_article_id_v0203() == "troubleshooting"
		and article_view.text.contains("Troubleshoot a problem"),
		"Live Help Center search must reveal the matching troubleshooting topic."
	):
		return

	help_window.open_help_center("provider_setup")
	await process_frame
	var provider_button := _button_with_text(help_window, "Open Provider Settings")
	if not _require(
		provider_button != null
		and help_window.selected_article_id_v0203() == "provider_setup",
		"Help topics must expose direct routes into existing app tools."
	):
		return
	provider_button.pressed.emit()
	await process_frame
	if not _require(
		not help_window.visible and str(app.get("_current_view")) == "settings",
		"Help actions must close Help Center and route through the canonical app workflow."
	):
		return

	app.queue_free()
	await process_frame
	print("V0203_HELP_CENTER_OK")
	quit(0)
