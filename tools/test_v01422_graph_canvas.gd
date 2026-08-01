extends SceneTree


func _init() -> void:
	var canvas_source := FileAccess.get_file_as_string("res://scripts/ui/graph_canvas_v01422.gd")
	for marker in [
		"top_left", "top_middle", "top_right",
		"right_top", "right_middle", "right_bottom",
		"bottom_right", "bottom_middle", "bottom_left",
		"left_bottom", "left_middle", "left_top"
	]:
		assert(canvas_source.contains(marker), "Shared graph canvas is missing anchor %s." % marker)
	assert(canvas_source.contains("connection_requested"), "Graph canvas must emit anchor-to-anchor connection requests.")
	assert(canvas_source.contains("node_moved"), "Graph canvas must support draggable nodes.")
	assert(canvas_source.contains("from_anchor") and canvas_source.contains("to_anchor"), "Graph connections must preserve exact endpoint anchors.")

	var relationship_source := FileAccess.get_file_as_string("res://scripts/ui/relationship_graph_window_v01422.gd")
	assert(relationship_source.contains("What is the connection these two characters have?"), "Relationship connections must ask for a freeform label.")
	assert(relationship_source.contains("Create Connection"), "Relationship graph must expose connection creation.")
	assert(relationship_source.contains("graph_saved"), "Relationship graph must save edited relationships and layout.")
	assert(relationship_source.contains("{{user}}"), "Relationship graph must retain the special {{user}} node.")

	var route_source := FileAccess.get_file_as_string("res://scripts/ui/route_graph_window_v01422.gd")
	assert(route_source.contains("Route / Timeline Flowchart"), "v0.14.22 must add the separate route/timeline flowchart.")
	assert(route_source.contains("What does this connection represent?"), "Flowchart connections must ask for a freeform label.")
	assert(route_source.contains("Add Step / Event"), "Flowchart must support non-character event/choice nodes.")
	assert(route_source.contains("Linked Variant"), "Flowchart must recognise linked character variants.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01422.gd")
	assert(workspace_source.contains("Route / Timeline Flowchart…"), "Workspace Project menu must expose the flowchart.")
	assert(workspace_source.contains("format_version\": 2") or workspace_source.contains("format_version\":2") or workspace_source.contains("\"format_version\": 2"), "Relationship graph workspace metadata should advance for anchor-aware layout.")
	assert(workspace_source.contains("relationships.duplicate(true)"), "Graph-edited relationship data must be saved back to the project.")

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01422.gd")
	assert(main_source.contains("main_v01421.gd"), "v0.14.22 must preserve v0.14.21 through inheritance.")
	var scene := FileAccess.get_file_as_string("res://scenes/main.tscn")
	var shell_15 := FileAccess.get_file_as_string("res://scripts/main_v015.gd")
	assert(
		scene.contains("main_v01422.gd")
		or (scene.contains("main_v015.gd") and shell_15.contains("main_v01422.gd")),
		"The active main shell must preserve v0.14.22 through direct use or inheritance."
	)

	print("v0.14.22 shared graph canvas regression passed")
	quit(0)
