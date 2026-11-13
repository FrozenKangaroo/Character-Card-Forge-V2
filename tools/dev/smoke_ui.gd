extends SceneTree

# Development-only smoke harness: drives every top-level view and several tool
# windows, then reports any engine error/warning text the run produced.
#
# Usage:
#   godot --accessibility disabled --path . --script res://tools/dev/smoke_ui.gd

var _main: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	_main = packed.instantiate()
	root.add_child(_main)
	await _settle(12)
	_main.call("_show_view", "home")
	await _settle(6)

	for view in ["dashboard", "library", "series", "templates", "settings", "dashboard"]:
		_main.call("_show_view", view)
		await _settle(6)

	var project_id := _find_project_id("Aya")
	if not project_id.is_empty():
		_main.call("_open_project", project_id)
		await _settle(12)
		await _walk_workspace()
		await _open_tool_windows()

	if _main.has_method("_open_support_center_v0202"):
		_main.call("_open_support_center_v0202")
		await _settle(10)
	if _main.has_method("_open_help_center_v0203"):
		_main.call("_open_help_center_v0203", "")
		await _settle(10)
	await _settle(20)
	print("SMOKE_DONE")
	quit(0)


func _walk_workspace() -> void:
	var workspace: Node = _main.get("_workspace")
	if workspace == null:
		return
	var tabs: TabContainer = workspace.get("_tabs")
	if tabs != null:
		for index in range(tabs.get_tab_count()):
			tabs.current_tab = index
			await _settle(5)
	var group_tabs: TabContainer = workspace.get("_front_porch_group_tabs_v0172")
	if group_tabs != null:
		for index in range(group_tabs.get_tab_count()):
			group_tabs.current_tab = index
			await _settle(5)


func _open_tool_windows() -> void:
	var workspace: Node = _main.get("_workspace")
	if workspace == null:
		return
	for method in [
		"_open_card_inspector_v0182",
		"_open_rich_authoring_v0190",
		"_open_import_export_studio",
		"_open_attachment_manager",
		"_open_project_context",
		"_open_relationship_matrix",
		"_open_card_workflow_studio",
		"_open_idea_generator",
		"_open_revision_history_v0181",
	]:
		if workspace.has_method(method):
			workspace.call(method)
			await _settle(6)


func _find_project_id(project_name: String) -> String:
	var index_result: Dictionary = CCFLibraryService.refresh_index(false)
	for row in index_result.get("rows", []):
		if str(row.get("name", "")).to_lower() == project_name.to_lower():
			return str(row.get("project_id", ""))
	return ""


func _settle(frames: int) -> void:
	for _index in range(frames):
		await process_frame
