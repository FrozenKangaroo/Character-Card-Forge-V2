class_name CCFWorkspaceV01422View
extends "res://scripts/ui/workspace_v01421.gd"

const RELATIONSHIP_GRAPH_WINDOW_V01422 = preload("res://scripts/ui/relationship_graph_window_v01422.gd")
const ROUTE_GRAPH_WINDOW_V01422 = preload("res://scripts/ui/route_graph_window_v01422.gd")
const PROJECT_ROUTE_GRAPH_MENU_ID := 14220

var _route_graph_window: CCFRouteGraphWindowV01422


func _ready() -> void:
	super._ready()
	_build_route_graph_window_v01422()
	_add_route_graph_menu_v01422()


func _build_relationship_graph_window_v01420() -> void:
	_relationship_graph_window = RELATIONSHIP_GRAPH_WINDOW_V01422.new()
	_relationship_graph_window.visible = false
	_relationship_graph_window.force_native = true
	_relationship_graph_window.transient = false
	_relationship_graph_window.exclusive = false
	(_relationship_graph_window as CCFRelationshipGraphWindowV01422).graph_saved.connect(_on_relationship_graph_saved_v01422)
	_relationship_graph_window.character_selected.connect(_on_relationship_graph_character_selected)
	add_child(_relationship_graph_window)
	_relationship_graph_window.hide()


func _build_route_graph_window_v01422() -> void:
	_route_graph_window = ROUTE_GRAPH_WINDOW_V01422.new()
	_route_graph_window.visible = false
	_route_graph_window.force_native = true
	_route_graph_window.transient = false
	_route_graph_window.exclusive = false
	_route_graph_window.route_graph_saved.connect(_on_route_graph_saved_v01422)
	_route_graph_window.character_selected.connect(_on_relationship_graph_character_selected)
	add_child(_route_graph_window)
	_route_graph_window.hide()


func _add_route_graph_menu_v01422() -> void:
	for node in find_children("*", "MenuButton", true, false):
		if not node is MenuButton:
			continue
		var menu := node as MenuButton
		if menu.text != "Project":
			continue
		var popup_menu := menu.get_popup()
		popup_menu.add_item("Route / Timeline Flowchart…", PROJECT_ROUTE_GRAPH_MENU_ID)
		popup_menu.id_pressed.connect(_on_project_route_graph_menu_v01422)
		return


func _on_project_route_graph_menu_v01422(id: int) -> void:
	if id != PROJECT_ROUTE_GRAPH_MENU_ID:
		return
	_open_route_graph_v01422()


func _open_route_graph_v01422() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	_capture_project_name()
	_route_graph_window.open_for_project(_project_container)
	_status.text = "Route / Timeline Flowchart opened. Drag cards and connect any anchor points to build routes."


func _on_relationship_graph_saved_v01422(layout: Dictionary, relationships: Array) -> void:
	var workspace: Dictionary = _project_container.get("workspace", {}).duplicate(true)
	workspace["relationship_graph"] = {
		"format_version": 2,
		"nodes": layout.duplicate(true)
	}
	_project_container["workspace"] = workspace
	_project_container["relationships"] = relationships.duplicate(true)
	_dirty = true
	_update_project_level_window_contexts()
	_status.text = "Relationship Graph saved, including connection labels and anchor choices."


func _on_route_graph_saved_v01422(route_graph: Dictionary) -> void:
	_project_container["route_graph"] = route_graph.duplicate(true)
	_dirty = true
	_status.text = "Route / Timeline Flowchart saved to the project."


func _close_tool_windows_for_project_change() -> void:
	if _route_graph_window != null and _route_graph_window.visible:
		_route_graph_window.hide()
	super._close_tool_windows_for_project_change()
