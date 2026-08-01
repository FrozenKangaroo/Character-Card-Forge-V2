class_name CCFRelationshipGraphWindowV01420
extends Window

signal layout_saved(layout: Dictionary)
signal character_selected(character_id: String)

const USER_NODE_ID := "{{user}}"

var _project: Dictionary = {}
var _layout: Dictionary = {}
var _canvas: Control
var _node_buttons: Dictionary = {}
var _relationship_labels: Array[Label] = []
var _dragging_id := ""
var _drag_offset := Vector2.ZERO
var _status: Label


func _ready() -> void:
	title = "Relationship Graph"
	size = Vector2i(1280, 820)
	min_size = Vector2i(900, 600)
	unresizable = false
	exclusive = false
	transient = false
	close_requested.connect(hide)
	_build_ui()


func open_for_project(project: Dictionary) -> void:
	_project = project.duplicate(true)
	var workspace_value: Variant = _project.get("workspace", {})
	var workspace: Dictionary = workspace_value if workspace_value is Dictionary else {}
	var graph_value: Variant = workspace.get("relationship_graph", {})
	var graph: Dictionary = graph_value if graph_value is Dictionary else {}
	var nodes_value: Variant = graph.get("nodes", {})
	_layout = nodes_value.duplicate(true) if nodes_value is Dictionary else {}
	_rebuild_graph()
	popup_centered()


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 10
	root.offset_top = 10
	root.offset_right = -10
	root.offset_bottom = -10
	add_child(root)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	root.add_child(toolbar)
	var auto_layout := Button.new()
	auto_layout.text = "Auto Layout"
	auto_layout.pressed.connect(_auto_layout)
	toolbar.add_child(auto_layout)
	var save_button := Button.new()
	save_button.text = "Save Layout"
	save_button.pressed.connect(_save_layout)
	toolbar.add_child(save_button)
	var refresh_button := Button.new()
	refresh_button.text = "Refresh"
	refresh_button.pressed.connect(_rebuild_graph)
	toolbar.add_child(refresh_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(spacer)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(hide)
	toolbar.add_child(close_button)

	var help := Label.new()
	help.text = "Drag character nodes to organise the graph. Existing project relationships are shown as labelled connections; {{user}} is always available as a special roleplay node."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(help)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root.add_child(scroll)
	_canvas = Control.new()
	_canvas.custom_minimum_size = Vector2(2200, 1500)
	_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	_canvas.draw.connect(_draw_connections)
	scroll.add_child(_canvas)

	_status = Label.new()
	_status.text = "Relationship Graph ready."
	root.add_child(_status)


func _rebuild_graph() -> void:
	if _canvas == null:
		return
	for child in _canvas.get_children():
		child.queue_free()
	_node_buttons.clear()
	_relationship_labels.clear()
	var ids: Array[String] = []
	ids.append(USER_NODE_ID)
	var characters_value: Variant = _project.get("characters", [])
	if characters_value is Array:
		for raw_character in characters_value:
			if not raw_character is Dictionary:
				continue
			var character_id := str(raw_character.get("character_id", "")).strip_edges()
			if not character_id.is_empty():
				ids.append(character_id)
	for index in range(ids.size()):
		var node_id := ids[index]
		var fallback := _fallback_position(index)
		var node_position := _position_for(node_id, fallback)
		_create_node(node_id, node_position)
	_create_relationship_labels()
	_canvas.queue_redraw()


func _create_node(node_id: String, node_position: Vector2) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(190, 72)
	button.size = Vector2(190, 72)
	button.position = node_position
	button.text = _display_name(node_id)
	button.tooltip_text = "Drag to reposition. Click to select this character." if node_id != USER_NODE_ID else "Special roleplay user node."
	button.mouse_default_cursor_shape = Control.CURSOR_MOVE
	button.gui_input.connect(func(event: InputEvent) -> void: _on_node_input(node_id, button, event))
	_canvas.add_child(button)
	_node_buttons[node_id] = button


func _on_node_input(node_id: String, button: Button, event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed:
				_dragging_id = node_id
				_drag_offset = mouse_button.position
				button.accept_event()
			else:
				var was_dragging := _dragging_id == node_id
				_dragging_id = ""
				if was_dragging and mouse_button.position.distance_to(_drag_offset) < 5.0 and node_id != USER_NODE_ID:
					character_selected.emit(node_id)
	elif event is InputEventMouseMotion and _dragging_id == node_id:
		var motion := event as InputEventMouseMotion
		button.position += motion.relative
		button.position.x = maxf(0.0, button.position.x)
		button.position.y = maxf(0.0, button.position.y)
		_layout[node_id] = {"x": button.position.x, "y": button.position.y}
		_update_relationship_label_positions()
		_canvas.queue_redraw()
		button.accept_event()


func _draw_connections() -> void:
	if _canvas == null:
		return
	var relationships_value: Variant = _project.get("relationships", [])
	if not relationships_value is Array:
		return
	for raw_relationship in relationships_value:
		if not raw_relationship is Dictionary:
			continue
		var relationship: Dictionary = raw_relationship
		var from_id := _relationship_endpoint(relationship, true)
		var to_id := _relationship_endpoint(relationship, false)
		if not _node_buttons.has(from_id) or not _node_buttons.has(to_id):
			continue
		var from_button: Button = _node_buttons[from_id]
		var to_button: Button = _node_buttons[to_id]
		var from_point := from_button.position + from_button.size * 0.5
		var to_point := to_button.position + to_button.size * 0.5
		_canvas.draw_line(from_point, to_point, Color(0.66, 0.70, 0.82), 2.0, true)
		_draw_arrow_head(from_point, to_point)


func _draw_arrow_head(from_point: Vector2, to_point: Vector2) -> void:
	var direction := (to_point - from_point).normalized()
	if direction.length() < 0.01:
		return
	var side := Vector2(-direction.y, direction.x)
	var tip := to_point - direction * 98.0
	var back := tip - direction * 12.0
	_canvas.draw_colored_polygon(PackedVector2Array([tip, back + side * 6.0, back - side * 6.0]), Color(0.66, 0.70, 0.82))


func _create_relationship_labels() -> void:
	var relationships_value: Variant = _project.get("relationships", [])
	if not relationships_value is Array:
		return
	for raw_relationship in relationships_value:
		if not raw_relationship is Dictionary:
			continue
		var relationship: Dictionary = raw_relationship
		var from_id := _relationship_endpoint(relationship, true)
		var to_id := _relationship_endpoint(relationship, false)
		if not _node_buttons.has(from_id) or not _node_buttons.has(to_id):
			continue
		var label := Label.new()
		label.text = _relationship_label(relationship)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.set_meta("from_id", from_id)
		label.set_meta("to_id", to_id)
		label.set_meta("relationship", relationship.duplicate(true))
		_canvas.add_child(label)
		_relationship_labels.append(label)
	_update_relationship_label_positions()


func _update_relationship_label_positions() -> void:
	for label in _relationship_labels:
		var from_id := str(label.get_meta("from_id", ""))
		var to_id := str(label.get_meta("to_id", ""))
		if not _node_buttons.has(from_id) or not _node_buttons.has(to_id):
			continue
		var from_button: Button = _node_buttons[from_id]
		var to_button: Button = _node_buttons[to_id]
		var midpoint := (from_button.position + from_button.size * 0.5 + to_button.position + to_button.size * 0.5) * 0.5
		label.position = midpoint + Vector2(8, -12)


func _relationship_endpoint(relationship: Dictionary, first: bool) -> String:
	var keys := ["character_a_id", "source_character_id", "from_id"] if first else ["character_b_id", "target_character_id", "to_id"]
	for key in keys:
		var value := str(relationship.get(key, "")).strip_edges()
		if not value.is_empty():
			return value
	return ""


func _relationship_label(relationship: Dictionary) -> String:
	for key in ["label", "relationship", "type", "relationship_type", "summary"]:
		var value := str(relationship.get(key, "")).strip_edges()
		if not value.is_empty():
			return value
	var a_to_b := str(relationship.get("a_to_b", "")).strip_edges()
	if not a_to_b.is_empty():
		return a_to_b
	return "relationship"


func _display_name(node_id: String) -> String:
	if node_id == USER_NODE_ID:
		return "{{user}}"
	var characters_value: Variant = _project.get("characters", [])
	if characters_value is Array:
		for raw_character in characters_value:
			if not raw_character is Dictionary or str(raw_character.get("character_id", "")) != node_id:
				continue
			var character: Dictionary = raw_character
			var metadata_value: Variant = character.get("metadata", {})
			var metadata: Dictionary = metadata_value if metadata_value is Dictionary else {}
			var display_name := str(metadata.get("name", "")).strip_edges()
			if display_name.is_empty():
				var card_value: Variant = character.get("character", {})
				if card_value is Dictionary:
					display_name = str((card_value as Dictionary).get("name", "")).strip_edges()
			if not display_name.is_empty():
				return display_name
	return "Unknown Character"


func _position_for(node_id: String, fallback: Vector2) -> Vector2:
	var value: Variant = _layout.get(node_id, {})
	if value is Dictionary:
		var row: Dictionary = value
		if row.has("x") and row.has("y"):
			return Vector2(float(row.get("x", fallback.x)), float(row.get("y", fallback.y)))
	return fallback


func _fallback_position(index: int) -> Vector2:
	var column := index % 4
	var row := int(index / 4.0)
	return Vector2(90 + column * 360, 90 + row * 220)


func _auto_layout() -> void:
	var ids := _node_buttons.keys()
	ids.sort()
	if ids.has(USER_NODE_ID):
		ids.erase(USER_NODE_ID)
		ids.push_front(USER_NODE_ID)
	for index in range(ids.size()):
		var node_id := str(ids[index])
		var button: Button = _node_buttons[node_id]
		button.position = _fallback_position(index)
		_layout[node_id] = {"x": button.position.x, "y": button.position.y}
	_update_relationship_label_positions()
	_canvas.queue_redraw()
	_status.text = "Auto layout applied. Save Layout to persist it with the project."


func _save_layout() -> void:
	for raw_id in _node_buttons.keys():
		var node_id := str(raw_id)
		var button: Button = _node_buttons[node_id]
		_layout[node_id] = {"x": button.position.x, "y": button.position.y}
	layout_saved.emit(_layout.duplicate(true))
	_status.text = "Relationship graph layout saved to project workspace metadata."
