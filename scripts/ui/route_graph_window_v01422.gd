class_name CCFRouteGraphWindowV01422
extends Window

signal route_graph_saved(route_graph: Dictionary)
signal character_selected(character_id: String)

const GRAPH_CANVAS = preload("res://scripts/ui/graph_canvas_v01422.gd")

var _project: Dictionary = {}
var _route_graph: Dictionary = {}
var _graph_canvas: CCFGraphCanvasV01422
var _connection_dialog: ConfirmationDialog
var _connection_label: LineEdit
var _pending_connection: Dictionary = {}
var _step_dialog: ConfirmationDialog
var _step_title: LineEdit
var _status: Label


func _ready() -> void:
	title = "Route / Timeline Flowchart"
	size = Vector2i(1320, 860)
	min_size = Vector2i(920, 620)
	close_requested.connect(hide)
	_build_ui()
	_build_connection_dialog()
	_build_step_dialog()


func open_for_project(project: Dictionary) -> void:
	_project = project.duplicate(true)
	var route_value: Variant = _project.get("route_graph", {})
	_route_graph = route_value.duplicate(true) if route_value is Dictionary else {}
	if _route_graph.is_empty():
		_route_graph = {"format_version": 1, "nodes": [], "connections": [], "layout": {}}
	_ensure_character_nodes()
	_graph_canvas.set_graph(_route_nodes(), _route_connections(), _route_layout())
	popup_centered()


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 10
	root.offset_top = 10
	root.offset_right = -10
	root.offset_bottom = -10
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var toolbar := HBoxContainer.new()
	root.add_child(toolbar)
	var add_step := Button.new()
	add_step.text = "Add Step / Event"
	add_step.pressed.connect(func() -> void: _step_dialog.popup_centered(Vector2i(560, 180)))
	toolbar.add_child(add_step)
	var auto_layout := Button.new()
	auto_layout.text = "Auto Layout"
	auto_layout.pressed.connect(func() -> void: _graph_canvas.auto_layout())
	toolbar.add_child(auto_layout)
	var save_button := Button.new()
	save_button.text = "Save Flowchart"
	save_button.pressed.connect(_save_route_graph)
	toolbar.add_child(save_button)

	var help := Label.new()
	help.text = "Character cards, linked variants and full character versions can all appear as nodes. Drag from any anchor to another node and label the connection as a choice, event, time skip or route transition."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(help)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_graph_canvas = GRAPH_CANVAS.new()
	_graph_canvas.connection_requested.connect(_on_connection_requested)
	_graph_canvas.node_activated.connect(_on_node_activated)
	_graph_canvas.node_moved.connect(_on_node_moved)
	scroll.add_child(_graph_canvas)

	_status = Label.new()
	_status.text = "Route / Timeline Flowchart ready."
	root.add_child(_status)


func _build_connection_dialog() -> void:
	_connection_dialog = ConfirmationDialog.new()
	_connection_dialog.visible = false
	_connection_dialog.title = "Create Flowchart Connection"
	_connection_dialog.ok_button_text = "Create Connection"
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	_connection_dialog.add_child(root)
	var prompt := Label.new()
	prompt.text = "What does this connection represent?"
	root.add_child(prompt)
	_connection_label = LineEdit.new()
	_connection_label.placeholder_text = "e.g. accepts confession, affair discovered, three months later"
	root.add_child(_connection_label)
	_connection_dialog.confirmed.connect(_create_connection)
	add_child(_connection_dialog)
	_connection_dialog.hide()


func _build_step_dialog() -> void:
	_step_dialog = ConfirmationDialog.new()
	_step_dialog.visible = false
	_step_dialog.title = "Add Flowchart Step"
	_step_dialog.ok_button_text = "Add Step"
	var root := VBoxContainer.new()
	_step_dialog.add_child(root)
	_step_title = LineEdit.new()
	_step_title.placeholder_text = "e.g. Dating {{user}}, Choice, Good End, Affair Exposed"
	root.add_child(_step_title)
	_step_dialog.confirmed.connect(_create_step)
	add_child(_step_dialog)
	_step_dialog.hide()


func _ensure_character_nodes() -> void:
	var nodes: Array = _route_graph.get("nodes", []).duplicate(true) if _route_graph.get("nodes", []) is Array else []
	var existing := {}
	for raw_node in nodes:
		if raw_node is Dictionary:
			existing[str(raw_node.get("id", ""))] = true
	var characters: Variant = _project.get("characters", [])
	if characters is Array:
		for raw_character in characters:
			if not raw_character is Dictionary:
				continue
			var character: Dictionary = raw_character
			var character_id := str(character.get("character_id", ""))
			if character_id.is_empty():
				continue
			var node_id := "character:%s" % character_id
			if existing.has(node_id):
				continue
			nodes.append({
				"id": node_id,
				"type": "character",
				"character_id": character_id,
				"title": CCFStorageService.character_display_name(character),
				"subtitle": "Linked Variant" if str(character.get("record_type", "")) == "variant" else "Character"
			})
	_route_graph["nodes"] = nodes


func _route_nodes() -> Array:
	return (_route_graph.get("nodes", []) as Array).duplicate(true) if _route_graph.get("nodes", []) is Array else []


func _route_connections() -> Array:
	return (_route_graph.get("connections", []) as Array).duplicate(true) if _route_graph.get("connections", []) is Array else []


func _route_layout() -> Dictionary:
	return (_route_graph.get("layout", {}) as Dictionary).duplicate(true) if _route_graph.get("layout", {}) is Dictionary else {}


func _on_connection_requested(from_node: String, from_anchor: String, to_node: String, to_anchor: String) -> void:
	_pending_connection = {"from_node": from_node, "from_anchor": from_anchor, "to_node": to_node, "to_anchor": to_anchor}
	_connection_label.text = ""
	_connection_dialog.popup_centered(Vector2i(620, 200))


func _create_connection() -> void:
	if _pending_connection.is_empty():
		return
	var label := _connection_label.text.strip_edges()
	if label.is_empty():
		label = "continues"
	var connections: Array = _route_connections()
	connections.append({
		"id": "route_connection_%d" % (connections.size() + 1),
		"from_node": str(_pending_connection.get("from_node", "")),
		"from_anchor": str(_pending_connection.get("from_anchor", "right_middle")),
		"to_node": str(_pending_connection.get("to_node", "")),
		"to_anchor": str(_pending_connection.get("to_anchor", "left_middle")),
		"label": label,
		"direction": "forward"
	})
	_route_graph["connections"] = connections
	_graph_canvas.set_connections(connections)
	_pending_connection = {}
	_status.text = "Created flowchart connection: %s" % label


func _create_step() -> void:
	var title_text := _step_title.text.strip_edges()
	if title_text.is_empty():
		title_text = "New Step"
	var nodes: Array = _route_nodes()
	var node_id := "step_%d" % (nodes.size() + 1)
	nodes.append({"id": node_id, "type": "step", "title": title_text, "subtitle": "Flowchart step"})
	_route_graph["nodes"] = nodes
	_graph_canvas.add_graph_node(node_id, title_text, "Flowchart step", Vector2(160 + nodes.size() * 18, 140 + nodes.size() * 14))
	_step_title.text = ""
	_status.text = "Added flowchart step: %s" % title_text


func _on_node_moved(_node_id: String, _node_position: Vector2) -> void:
	_route_graph["layout"] = _graph_canvas.graph_layout()


func _on_node_activated(node_id: String) -> void:
	if not node_id.begins_with("character:"):
		return
	character_selected.emit(node_id.trim_prefix("character:"))


func _save_route_graph() -> void:
	_route_graph["format_version"] = 1
	_route_graph["layout"] = _graph_canvas.graph_layout()
	route_graph_saved.emit(_route_graph.duplicate(true))
	_status.text = "Route / Timeline Flowchart saved to the project."
