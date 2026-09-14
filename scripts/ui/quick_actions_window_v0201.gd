class_name CCFQuickActionsWindowV0201
extends Window

signal action_requested(action_id: String)

var _search: LineEdit
var _rows: Array[Dictionary] = []


func _ready() -> void:
	title = "Quick Actions"
	size = Vector2i(720, 700)
	min_size = Vector2i(560, 480)
	force_native = true
	transient = false
	exclusive = false
	close_requested.connect(hide)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	var heading := Label.new()
	heading.text = "Quick Actions"
	heading.add_theme_font_size_override("font_size", 24)
	root.add_child(heading)
	_search = LineEdit.new()
	_search.placeholder_text = "Type an action, tool or workflow…"
	_search.clear_button_enabled = true
	_search.text_changed.connect(_filter_actions)
	_search.text_submitted.connect(_run_first_visible)
	root.add_child(_search)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for action in CCFWorkflowDiscoveryServiceV0201.quick_actions():
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 44
		button.text = "%s  ·  %s" % [
			str(action.get("group", "Action")),
			str(action.get("label", "Action")),
		]
		var shortcut := str(action.get("shortcut", "")).strip_edges()
		if not shortcut.is_empty():
			button.text += "    %s" % shortcut
		button.pressed.connect(_run_action.bind(str(action.get("id", ""))))
		list.add_child(button)
		_rows.append({"action": action.duplicate(true), "button": button})


func open_palette() -> void:
	_search.text = ""
	_filter_actions("")
	popup_centered()
	_search.grab_focus()


func _filter_actions(query: String) -> void:
	var needle := query.strip_edges().to_lower()
	for row in _rows:
		var action: Dictionary = row.get("action", {})
		var button := row.get("button") as Button
		if button == null:
			continue
		var haystack := "%s %s %s" % [
			str(action.get("group", "")),
			str(action.get("label", "")),
			str(action.get("shortcut", "")),
		]
		button.visible = needle.is_empty() or haystack.to_lower().contains(needle)


func _run_first_visible(_query: String) -> void:
	for row in _rows:
		var button := row.get("button") as Button
		if button != null and button.visible:
			_run_action(str((row.get("action", {}) as Dictionary).get("id", "")))
			return


func _run_action(action_id: String) -> void:
	if action_id.is_empty():
		return
	hide()
	action_requested.emit(action_id)
