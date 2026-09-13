extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0200_HOTFIX1_LIBRARY_PANELS_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var defaults := CCFLibraryService.load_view_state()
	if not _require(
		int(defaults.get("format_version", 0)) == 3
		and bool(defaults.get("library_filters_expanded_v0200_hotfix1", false))
		and bool(defaults.get("library_details_expanded_v0200_hotfix1", false))
		and not bool(defaults.get("library_side_auto_hide_v0200_hotfix1", true)),
		"The upgraded Library view state must keep familiar visible defaults and opt-in auto-hide."
	):
		return

	var view := CCFLibraryV0200Hotfix1View.new()
	view.size = Vector2(1600, 900)
	root.add_child(view)
	await process_frame
	await process_frame
	var filter_panel := view.get("_filter_panel_v0200_hotfix1") as Control
	var detail_panel := view.get("_detail_panel_v0200_hotfix1") as Control
	var filter_handle := view.find_child(
		"LibraryFilterHandleV0200Hotfix1", true, false
	) as Button
	var detail_handle := view.find_child(
		"LibraryDetailHandleV0200Hotfix1", true, false
	) as Button
	var panels_menu := view.find_child(
		"LibraryPanelsMenuV0200Hotfix1", true, false
	) as MenuButton
	var library_centre := view.get("_library_centre_v0200_hotfix1") as Control
	if not _require(
		filter_panel != null
		and detail_panel != null
		and filter_handle != null
		and detail_handle != null
		and panels_menu != null
		and library_centre != null
		and filter_panel.visible
		and detail_panel.visible,
		"The live Library must expose visible, recoverable Filters and Details panel controls."
	):
		return
	var full_layout_width := library_centre.size.x

	view.call("_set_filter_panel_expanded_v0200_hotfix1", false)
	view.call("_set_detail_panel_expanded_v0200_hotfix1", false)
	await process_frame
	await process_frame
	if not _require(
		not filter_panel.visible
		and not detail_panel.visible
		and filter_handle.visible
		and detail_handle.visible
		and filter_handle.text == "▶"
		and detail_handle.text == "◀"
		and library_centre.size.x > full_layout_width + 300.0,
		"Collapsed panels must release space while leaving clear edge arrows to restore them."
	):
		return

	view.call("_on_panels_menu_v0200_hotfix1", 1)
	var project_tools_toggle := view.get("_active_project_toggle_v0191") as Button
	if not _require(
		project_tools_toggle != null and project_tools_toggle.button_pressed,
		"The unified Panels menu must also control the existing Project Tools section."
	):
		return

	view.call("_on_panels_menu_v0200_hotfix1", 3)
	view.call("_reveal_filter_for_auto_hide_v0200_hotfix1")
	if not _require(
		bool(view.get("_side_auto_hide_v0200_hotfix1"))
		and filter_panel.visible,
		"Opt-in auto-hide must allow a collapsed side panel to reveal from its edge handle."
	):
		return
	view.call("_collapse_auto_hide_side_panels_v0200_hotfix1")
	if not _require(
		not filter_panel.visible and not detail_panel.visible,
		"Auto-hide must return temporary side panels to the focused card layout."
	):
		return

	view.call("_on_panels_menu_v0200_hotfix1", 3)
	view.call("_set_filter_panel_expanded_v0200_hotfix1", true)
	view.call("_set_detail_panel_expanded_v0200_hotfix1", false)
	var saved_state := CCFLibraryService.load_view_state()
	if not _require(
		bool(saved_state.get("library_filters_expanded_v0200_hotfix1", false))
		and not bool(saved_state.get("library_details_expanded_v0200_hotfix1", true))
		and not bool(saved_state.get("library_side_auto_hide_v0200_hotfix1", true)),
		"Manual panel visibility and auto-hide preference must survive a view-state reload."
	):
		return

	var capabilities := view.library_panel_capabilities_v0200_hotfix1()
	if not _require(
		bool(capabilities.get("filters_collapsible", false))
		and bool(capabilities.get("details_collapsible", false))
		and bool(capabilities.get("project_tools_in_panel_menu", false))
		and bool(capabilities.get("side_auto_hide_opt_in", false))
		and bool(capabilities.get("persistent_layout", false)),
		"The panel capability contract must cover all requested Library layout controls."
	):
		return

	view.queue_free()
	await process_frame
	var packed := load("res://scenes/main.tscn") as PackedScene
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var live_library_value: Variant = app.get("_library")
	var version_found := false
	for node in app.find_children("*", "Label", true, false):
		if node is Label and node.text == "Godot rewrite • v0.20.0-hotfix1":
			version_found = true
			break
	if not _require(
		live_library_value is CCFLibraryV0200Hotfix1View and version_found,
		"The live application must mount the panel-aware Library and display the hotfix version."
	):
		return
	app.queue_free()
	await process_frame
	print("V0200_HOTFIX1_LIBRARY_PANELS_OK")
	quit(0)
