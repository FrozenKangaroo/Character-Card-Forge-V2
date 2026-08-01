class_name CCFGraphCanvasV01422
extends Control

signal node_moved(node_id: String, position: Vector2)
signal node_activated(node_id: String)
signal connection_requested(from_node_id: String, from_anchor: String, to_node_id: String, to_anchor: String)

const NODE_SIZE := Vector2(220, 118)
const ANCHOR_SIZE := Vector2(14, 14)
const ANCHORS := [
	"top_left", "top_middle", "top_right",
	"right_top", "right_middle", "right_bottom",
	"bottom_right", "bottom_middle", "bottom_left",
	"left_bottom", "left_middle", "left_top"
]

var _nodes: Dictionary = {}
var _headers: Dictionary = {}
var _anchor_buttons: Dictionary = {}
var _connections: Array = []
var _dragging_node_id := ""
var _drag_origin := Vector2.ZERO
var _drag_moved := false
var _connecting_node_id := ""
var _connecting_anchor := ""
var _connection_mouse := Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2(2400, 1600)
	mouse_filter = Control.MOUSE_FILTER_PASS


func clear_graph() -> void:
	for child in get_children():
		child.queue_free()
	_nodes.clear()
	_headers.clear()
	_anchor_buttons.clear()
	_connections.clear()
	_connecting_node_id = ""
	_connecting_anchor = ""
	queue_redraw()


func set_graph(nodes: Array, connections: Array, layout: Dictionary = {}) -> void:
	clear_graph()
	for index in range(nodes.size()):
		if not nodes[index] is Dictionary:
			continue
		var row: Dictionary = nodes[index]
		var node_id := str(row.get("id", "")).strip_edges()
		if node_id.is_empty():
			continue
		var fallback := Vector2(90 + (index % 4) * 360, 90 + int(float(index) / 4.0) * 220)
		var node_position := fallback
		var stored: Variant = layout.get(node_id, {})
		if stored is Dictionary and stored.has("x") and stored.has("y"):
			node_position = Vector2(float(stored.get("x", fallback.x)), float(stored.get("y", fallback.y)))
		_create_node(node_id, str(row.get("title", node_id)), str(row.get("subtitle", "")), node_position)
	_connections = connections.duplicate(true)
	queue_redraw()


func set_connections(connections: Array) -> void:
	_connections = connections.duplicate(true)
	queue_redraw()


func graph_layout() -> Dictionary:
	var result := {}
	for raw_id in _nodes.keys():
		var node_id := str(raw_id)
		var node: Control = _nodes[node_id]
		result[node_id] = {"x": node.position.x, "y": node.position.y}
	return result


func auto_layout() -> void:
	var ids: Array = _nodes.keys()
	ids.sort()
	for index in range(ids.size()):
		var node_id := str(ids[index])
		var node: Control = _nodes[node_id]
		node.position = Vector2(90 + (index % 4) * 360, 90 + int(float(index) / 4.0) * 220)
		node_moved.emit(node_id, node.position)
	queue_redraw()


func add_graph_node(node_id: String, title: String, subtitle: String = "", node_position: Vector2 = Vector2(120, 120)) -> void:
	if node_id.is_empty() or _nodes.has(node_id):
		return
	_create_node(node_id, title, subtitle, node_position)
	queue_redraw()


func _create_node(node_id: String, title: String, subtitle: String, node_position: Vector2) -> void:
	var card := Control.new()
	card.name = "GraphNode_%s" % node_id.validate_node_name()
	card.custom_minimum_size = NODE_SIZE
	card.size = NODE_SIZE
	card.position = node_position
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(card)
	_nodes[node_id] = card

	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(panel)

	var header := Button.new()
	header.position = Vector2(8, 8)
	header.size = Vector2(NODE_SIZE.x - 16, 38)
	header.text = title
	header.tooltip_text = "Drag to move this card. Click to select it."
	header.mouse_default_cursor_shape = Control.CURSOR_MOVE
	header.gui_input.connect(func(event: InputEvent) -> void: _on_header_input(node_id, card, event))
	card.add_child(header)
	_headers[node_id] = header

	var subtitle_label := Label.new()
	subtitle_label.position = Vector2(12, 54)
	subtitle_label.size = Vector2(NODE_SIZE.x - 24, 50)
	subtitle_label.text = subtitle
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(subtitle_label)

	for anchor_name in ANCHORS:
		var anchor := Button.new()
		anchor.name = "Anchor_%s" % anchor_name
		anchor.flat = false
		anchor.text = ""
		anchor.size = ANCHOR_SIZE
		anchor.position = _anchor_local_position(anchor_name) - ANCHOR_SIZE * 0.5
		anchor.tooltip_text = anchor_name.replace("_", " ").capitalize()
		anchor.mouse_default_cursor_shape = Control.CURSOR_CROSS
		anchor.gui_input.connect(func(event: InputEvent) -> void: _on_anchor_input(node_id, anchor_name, event))
		card.add_child(anchor)
		_anchor_buttons[_anchor_key(node_id, anchor_name)] = anchor


func _on_header_input(node_id: String, card: Control, event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_button.pressed:
			_dragging_node_id = node_id
			_drag_origin = mouse_button.position
			_drag_moved = false
		else:
			if _dragging_node_id == node_id and not _drag_moved:
				node_activated.emit(node_id)
			_dragging_node_id = ""
	elif event is InputEventMouseMotion and _dragging_node_id == node_id:
		var motion := event as InputEventMouseMotion
		card.position += motion.relative
		card.position.x = maxf(10.0, card.position.x)
		card.position.y = maxf(10.0, card.position.y)
		if motion.position.distance_to(_drag_origin) > 3.0:
			_drag_moved = true
		node_moved.emit(node_id, card.position)
		queue_redraw()


func _on_anchor_input(node_id: String, anchor_name: String, event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_button.pressed:
			_connecting_node_id = node_id
			_connecting_anchor = anchor_name
			_connection_mouse = _mouse_on_canvas()
			queue_redraw()
		else:
			if _connecting_node_id.is_empty():
				return
			var hit := _anchor_at_point(_mouse_on_canvas())
			if not hit.is_empty():
				var target_node := str(hit.get("node_id", ""))
				var target_anchor := str(hit.get("anchor", ""))
				if target_node != _connecting_node_id:
					connection_requested.emit(_connecting_node_id, _connecting_anchor, target_node, target_anchor)
			_connecting_node_id = ""
			_connecting_anchor = ""
			queue_redraw()
	elif event is InputEventMouseMotion and not _connecting_node_id.is_empty():
		_connection_mouse = _mouse_on_canvas()
		queue_redraw()


func _mouse_on_canvas() -> Vector2:
	return get_viewport().get_mouse_position() - global_position


func _anchor_at_point(canvas_point: Vector2) -> Dictionary:
	for raw_key in _anchor_buttons.keys():
		var key := str(raw_key)
		var parts := key.split("::", false, 1)
		if parts.size() != 2:
			continue
		var point := _anchor_canvas_position(parts[0], parts[1])
		if point.distance_to(canvas_point) <= 18.0:
			return {"node_id": parts[0], "anchor": parts[1]}
	return {}


func _draw() -> void:
	for raw_connection in _connections:
		if not raw_connection is Dictionary:
			continue
		_draw_connection(raw_connection)
	if not _connecting_node_id.is_empty():
		var start := _anchor_canvas_position(_connecting_node_id, _connecting_anchor)
		draw_line(start, _connection_mouse, Color(0.85, 0.85, 0.95), 2.0, true)


func _draw_connection(connection: Dictionary) -> void:
	var from_node := str(connection.get("from_node", ""))
	var to_node := str(connection.get("to_node", ""))
	if not _nodes.has(from_node) or not _nodes.has(to_node):
		return
	var from_anchor := str(connection.get("from_anchor", "right_middle"))
	var to_anchor := str(connection.get("to_anchor", "left_middle"))
	var start := _anchor_canvas_position(from_node, from_anchor)
	var finish := _anchor_canvas_position(to_node, to_anchor)
	var middle_x := (start.x + finish.x) * 0.5
	var p2 := Vector2(middle_x, start.y)
	var p3 := Vector2(middle_x, finish.y)
	var line_color := Color(0.66, 0.70, 0.82)
	draw_line(start, p2, line_color, 2.0, true)
	draw_line(p2, p3, line_color, 2.0, true)
	draw_line(p3, finish, line_color, 2.0, true)
	var direction := str(connection.get("direction", "forward"))
	if direction == "forward" or direction == "mutual":
		_draw_arrow(p3, finish, line_color)
	if direction == "reverse" or direction == "mutual":
		_draw_arrow(p2, start, line_color)
	var label := str(connection.get("label", "")).strip_edges()
	if not label.is_empty():
		var font := ThemeDB.fallback_font
		var label_position := Vector2(middle_x + 8, (start.y + finish.y) * 0.5 - 6)
		draw_string(font, label_position, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.93, 0.93, 0.96))


func _draw_arrow(from_point: Vector2, to_point: Vector2, line_color: Color) -> void:
	var direction := (to_point - from_point).normalized()
	if direction.length() < 0.01:
		return
	var side := Vector2(-direction.y, direction.x)
	var tip := to_point
	var back := tip - direction * 12.0
	draw_colored_polygon(PackedVector2Array([tip, back + side * 6.0, back - side * 6.0]), line_color)


func _anchor_canvas_position(node_id: String, anchor_name: String) -> Vector2:
	if not _nodes.has(node_id):
		return Vector2.ZERO
	var node: Control = _nodes[node_id]
	return node.position + _anchor_local_position(anchor_name)


func _anchor_local_position(anchor_name: String) -> Vector2:
	match anchor_name:
		"top_left": return Vector2(54, 0)
		"top_middle": return Vector2(NODE_SIZE.x * 0.5, 0)
		"top_right": return Vector2(NODE_SIZE.x - 54, 0)
		"right_top": return Vector2(NODE_SIZE.x, 28)
		"right_middle": return Vector2(NODE_SIZE.x, NODE_SIZE.y * 0.5)
		"right_bottom": return Vector2(NODE_SIZE.x, NODE_SIZE.y - 28)
		"bottom_right": return Vector2(NODE_SIZE.x - 54, NODE_SIZE.y)
		"bottom_middle": return Vector2(NODE_SIZE.x * 0.5, NODE_SIZE.y)
		"bottom_left": return Vector2(54, NODE_SIZE.y)
		"left_bottom": return Vector2(0, NODE_SIZE.y - 28)
		"left_middle": return Vector2(0, NODE_SIZE.y * 0.5)
		"left_top": return Vector2(0, 28)
	return Vector2(NODE_SIZE.x, NODE_SIZE.y * 0.5)


func _anchor_key(node_id: String, anchor_name: String) -> String:
	return "%s::%s" % [node_id, anchor_name]
