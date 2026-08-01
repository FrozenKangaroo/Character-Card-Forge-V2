class_name CCFRelationshipGraphWindowV01422
extends "res://scripts/ui/relationship_graph_window_v01420.gd"

signal graph_saved(layout: Dictionary, relationships: Array)

const GRAPH_CANVAS = preload("res://scripts/ui/graph_canvas_v01422.gd")
const USER_NODE_ID := "{{user}}"

var _graph_canvas: CCFGraphCanvasV01422
var _relationships_v01422: Array = []
var _connection_dialog: ConfirmationDialog
var _connection_label: LineEdit
var _connection_direction: OptionButton
var _pending_connection: Dictionary = {}
var _status_v01422: Label


func _ready() -> void:
	title = "Relationship Graph"
	size = Vector2i(1320, 860)
	min_size = Vector2i(920, 620)
	close_requested.connect(hide)
	_build_graph_ui_v01422()
	_build_connection_dialog_v01422()


func open_for_project(project: Dictionary) -> void:
	_project = project.duplicate(true)
	_relationships_v01422 = (_project.get("relationships", []) as Array).duplicate(true) if _project.get("relationships", []) is Array else []
	var workspace: Dictionary = _project.get("workspace", {}) if _project.get("workspace", {}) is Dictionary else {}
	var graph: Dictionary = workspace.get("relationship_graph", {}) if workspace.get("relationship_graph", {}) is Dictionary else {}
	var layout: Dictionary = graph.get("nodes", {}) if graph.get("nodes", {}) is Dictionary else {}
	_graph_canvas.set_graph(_relationship_nodes(), _relationship_connections(), layout)
	popup_centered()


func _build_graph_ui_v01422() -> void:
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
	var auto_layout := Button.new()
	auto_layout.text = "Auto Layout"
	auto_layout.pressed.connect(func() -> void: _graph_canvas.auto_layout())
	toolbar.add_child(auto_layout)
	var save_button := Button.new()
	save_button.text = "Save Graph"
	save_button.pressed.connect(_save_graph_v01422)
	toolbar.add_child(save_button)
	var help := Label.new()
	help.text = "Drag cards by their headers. Drag from any anchor point to an anchor on another card to create a labelled relationship."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(help)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_graph_canvas = GRAPH_CANVAS.new()
	_graph_canvas.connection_requested.connect(_on_relationship_connection_requested)
	_graph_canvas.node_activated.connect(_on_relationship_node_activated)
	scroll.add_child(_graph_canvas)

	_status_v01422 = Label.new()
	_status_v01422.text = "Relationship Graph ready."
	root.add_child(_status_v01422)


func _build_connection_dialog_v01422() -> void:
	_connection_dialog = ConfirmationDialog.new()
	_connection_dialog.visible = false
	_connection_dialog.title = "Create Relationship Connection"
	_connection_dialog.ok_button_text = "Create Connection"
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	_connection_dialog.add_child(root)
	var prompt := Label.new()
	prompt.text = "What is the connection these two characters have?"
	root.add_child(prompt)
	_connection_label = LineEdit.new()
	_connection_label.placeholder_text = "e.g. childhood friends, older sister, secretly loves"
	root.add_child(_connection_label)
	_connection_direction = OptionButton.new()
	_connection_direction.add_item("From first card → second card")
	_connection_direction.set_item_metadata(0, "forward")
	_connection_direction.add_item("Second card → first card")
	_connection_direction.set_item_metadata(1, "reverse")
	_connection_direction.add_item("Mutual")
	_connection_direction.set_item_metadata(2, "mutual")
	_connection_direction.add_item("Undirected")
	_connection_direction.set_item_metadata(3, "none")
	root.add_child(_connection_direction)
	_connection_dialog.confirmed.connect(_create_relationship_connection)
	add_child(_connection_dialog)
	_connection_dialog.hide()


func _relationship_nodes() -> Array:
	var nodes: Array = [{"id": USER_NODE_ID, "title": "{{user}}", "subtitle": "Roleplay user"}]
	var characters: Variant = _project.get("characters", [])
	if characters is Array:
		for raw_character in characters:
			if not raw_character is Dictionary:
				continue
			var character: Dictionary = raw_character
			var character_id := str(character.get("character_id", ""))
			if character_id.is_empty():
				continue
			var subtitle := "Linked Variant" if str(character.get("record_type", "")) == "variant" else "Character"
			nodes.append({"id": character_id, "title": CCFStorageService.character_display_name(character), "subtitle": subtitle})
	return nodes


func _relationship_connections() -> Array:
	var result: Array = []
	for raw_relationship in _relationships_v01422:
		if not raw_relationship is Dictionary:
			continue
		var relationship: Dictionary = raw_relationship
		var from_id := _relationship_endpoint(relationship, true)
		var to_id := _relationship_endpoint(relationship, false)
		if from_id.is_empty() or to_id.is_empty():
			continue
		var graph: Dictionary = relationship.get("graph", {}) if relationship.get("graph", {}) is Dictionary else {}
		result.append({
			"from_node": from_id,
			"to_node": to_id,
			"from_anchor": str(graph.get("from_anchor", "right_middle")),
			"to_anchor": str(graph.get("to_anchor", "left_middle")),
			"label": _relationship_label(relationship),
			"direction": _normalise_relationship_direction(relationship)
		})
	return result


func _normalise_relationship_direction(relationship: Dictionary) -> String:
	var value := str(relationship.get("direction", "")).strip_edges()
	if value in ["forward", "reverse", "mutual", "none"]:
		return value
	return "forward"


func _on_relationship_connection_requested(from_node: String, from_anchor: String, to_node: String, to_anchor: String) -> void:
	_pending_connection = {"from_node": from_node, "from_anchor": from_anchor, "to_node": to_node, "to_anchor": to_anchor}
	_connection_label.text = ""
	_connection_direction.select(2)
	_connection_dialog.popup_centered(Vector2i(620, 250))


func _create_relationship_connection() -> void:
	if _pending_connection.is_empty():
		return
	var label := _connection_label.text.strip_edges()
	if label.is_empty():
		label = "relationship"
	var relation_id := _next_relationship_id()
	var direction := str(_connection_direction.get_item_metadata(_connection_direction.selected))
	var relationship := {
		"relationship_id": relation_id,
		"character_a_id": str(_pending_connection.get("from_node", "")),
		"character_b_id": str(_pending_connection.get("to_node", "")),
		"label": label,
		"relationship_type": "custom",
		"direction": direction,
		"graph": {
			"from_anchor": str(_pending_connection.get("from_anchor", "right_middle")),
			"to_anchor": str(_pending_connection.get("to_anchor", "left_middle"))
		}
	}
	_relationships_v01422.append(relationship)
	_graph_canvas.set_connections(_relationship_connections())
	_status_v01422.text = "Created relationship: %s" % label
	_pending_connection = {}


func _next_relationship_id() -> String:
	var index := _relationships_v01422.size() + 1
	while true:
		var candidate := "graph_relationship_%d" % index
		var exists := false
		for raw_relationship in _relationships_v01422:
			if raw_relationship is Dictionary and str(raw_relationship.get("relationship_id", "")) == candidate:
				exists = true
				break
		if not exists:
			return candidate
		index += 1
	return "graph_relationship"


func _on_relationship_node_activated(node_id: String) -> void:
	if node_id != USER_NODE_ID:
		character_selected.emit(node_id)


func _save_graph_v01422() -> void:
	graph_saved.emit(_graph_canvas.graph_layout(), _relationships_v01422.duplicate(true))
	_status_v01422.text = "Relationship graph and connection labels saved."
