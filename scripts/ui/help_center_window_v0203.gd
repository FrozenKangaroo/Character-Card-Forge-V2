class_name CCFHelpCenterWindowV0203
extends Window

signal action_requested(action_id: String)

var _catalog: Dictionary = {}
var _search: LineEdit
var _category: OptionButton
var _topic_list: ItemList
var _content: RichTextLabel
var _actions: HFlowContainer
var _related: HFlowContainer
var _status: Label
var _visible_articles: Array[Dictionary] = []
var _selected_article_id := ""


func _ready() -> void:
	title = "Character Card Forge Help"
	size = Vector2i(1080, 760)
	min_size = Vector2i(760, 540)
	force_native = true
	transient = false
	exclusive = false
	close_requested.connect(hide)
	_catalog = CCFHelpContentServiceV0203.load_catalog()
	_build_ui()
	_populate_categories()
	_filter_topics()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var heading := Label.new()
	heading.text = "Help Center"
	heading.add_theme_font_size_override("font_size", 24)
	root.add_child(heading)
	var introduction := Label.new()
	introduction.text = (
		"Search task-focused guides stored with the app. Help browsing is offline and "
		+ "never calls an AI provider or sends project data."
	)
	introduction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(introduction)

	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 8)
	root.add_child(filters)
	_search = LineEdit.new()
	_search.name = "HelpSearchV0203"
	_search.placeholder_text = "Search tasks, tools or problems…"
	_search.clear_button_enabled = true
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(_filter_topics.unbind(1))
	filters.add_child(_search)
	_category = OptionButton.new()
	_category.name = "HelpCategoryV0203"
	_category.custom_minimum_size.x = 230
	_category.item_selected.connect(_filter_topics.unbind(1))
	filters.add_child(_category)

	var split := HSplitContainer.new()
	split.split_offset = 310
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(split)
	_topic_list = ItemList.new()
	_topic_list.name = "HelpTopicListV0203"
	_topic_list.custom_minimum_size.x = 270
	_topic_list.select_mode = ItemList.SELECT_SINGLE
	_topic_list.item_selected.connect(_on_topic_selected)
	split.add_child(_topic_list)

	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 8)
	split.add_child(detail)
	_content = RichTextLabel.new()
	_content.name = "HelpArticleV0203"
	_content.bbcode_enabled = true
	_content.fit_content = false
	_content.scroll_active = true
	_content.selection_enabled = true
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(_content)
	_actions = HFlowContainer.new()
	_actions.add_theme_constant_override("separation", 8)
	detail.add_child(_actions)
	_related = HFlowContainer.new()
	_related.add_theme_constant_override("separation", 8)
	detail.add_child(_related)

	var footer := HBoxContainer.new()
	root.add_child(footer)
	_status = Label.new()
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_status)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(hide)
	footer.add_child(close)


func open_help_center(article_id := "") -> void:
	_search.text = ""
	_category.select(0)
	_filter_topics()
	if not article_id.is_empty():
		_select_article(article_id)
	popup_centered()
	_search.grab_focus()


func selected_article_id_v0203() -> String:
	return _selected_article_id


func visible_article_count_v0203() -> int:
	return _visible_articles.size()


func _populate_categories() -> void:
	_category.clear()
	_category.add_item("All topics")
	_category.set_item_metadata(0, "")
	for category_value in CCFHelpContentServiceV0203.categories(_catalog):
		var category: Dictionary = category_value
		_category.add_item(str(category.get("label", "Topic")))
		_category.set_item_metadata(
			_category.item_count - 1, str(category.get("id", ""))
		)


func _filter_topics() -> void:
	var previous_id := _selected_article_id
	var category_id := ""
	if _category.selected >= 0:
		category_id = str(_category.get_item_metadata(_category.selected))
	_visible_articles = CCFHelpContentServiceV0203.search(
		_search.text, category_id, _catalog
	)
	_topic_list.clear()
	for article_value in _visible_articles:
		var article: Dictionary = article_value
		_topic_list.add_item(str(article.get("title", "Help topic")))
		_topic_list.set_item_tooltip(
			_topic_list.item_count - 1, str(article.get("summary", ""))
		)
		_topic_list.set_item_metadata(
			_topic_list.item_count - 1, str(article.get("id", ""))
		)
	if _visible_articles.is_empty():
		_selected_article_id = ""
		_content.text = (
			"[font_size=22][b]No matching help topics[/b][/font_size]\n\n"
			+ "Try a shorter search or choose All topics."
		)
		_clear_container(_actions)
		_clear_container(_related)
		_status.text = "No matching topics."
		return
	if not previous_id.is_empty() and _select_article(previous_id):
		return
	_topic_list.select(0)
	_show_article(_visible_articles[0])


func _on_topic_selected(index: int) -> void:
	if index < 0 or index >= _visible_articles.size():
		return
	_show_article(_visible_articles[index])


func _show_article(article: Dictionary) -> void:
	_selected_article_id = str(article.get("id", ""))
	_content.text = CCFHelpContentServiceV0203.render_article(article)
	_content.scroll_to_line(0)
	_build_action_buttons(article)
	_build_related_buttons(article)
	_status.text = "%d topic%s shown." % [
		_visible_articles.size(), "" if _visible_articles.size() == 1 else "s"
	]


func _build_action_buttons(article: Dictionary) -> void:
	_clear_container(_actions)
	var values: Variant = article.get("actions", [])
	if not values is Array or (values as Array).is_empty():
		return
	var label := Label.new()
	label.text = "Open in app:"
	_actions.add_child(label)
	for action_value in values:
		if not action_value is Dictionary:
			continue
		var action: Dictionary = action_value
		var action_id := str(action.get("id", ""))
		if action_id.is_empty():
			continue
		var button := Button.new()
		button.text = str(action.get("label", "Open"))
		button.pressed.connect(_request_action.bind(action_id))
		_actions.add_child(button)


func _build_related_buttons(article: Dictionary) -> void:
	_clear_container(_related)
	var values: Variant = article.get("related", [])
	if not values is Array or (values as Array).is_empty():
		return
	var label := Label.new()
	label.text = "Related:"
	_related.add_child(label)
	for related_value in values:
		var related_id := str(related_value)
		var related_article := CCFHelpContentServiceV0203.article_by_id(
			related_id, _catalog
		)
		if related_article.is_empty():
			continue
		var button := Button.new()
		button.text = str(related_article.get("title", "Help topic"))
		button.pressed.connect(_open_related.bind(related_id))
		_related.add_child(button)


func _select_article(article_id: String) -> bool:
	for index in range(_visible_articles.size()):
		if str(_visible_articles[index].get("id", "")) == article_id:
			_topic_list.select(index)
			_topic_list.ensure_current_is_visible()
			_show_article(_visible_articles[index])
			return true
	return false


func _open_related(article_id: String) -> void:
	_search.text = ""
	_category.select(0)
	_filter_topics()
	_select_article(article_id)


func _request_action(action_id: String) -> void:
	hide()
	action_requested.emit(action_id)


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
