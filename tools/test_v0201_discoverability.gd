extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message_text: String) -> void:
	push_error(message_text)
	print("V0201_DISCOVERABILITY_ERROR: %s" % message_text)
	quit(1)


func _require(condition: bool, message_text: String) -> bool:
	if condition:
		return true
	_fail(message_text)
	return false


func _run() -> void:
	var capabilities := CCFWorkflowDiscoveryServiceV0201.capabilities()
	if not _require(
		bool(capabilities.get("new_project_chooser", false))
		and int(capabilities.get("creation_methods", 0)) >= 7
		and bool(capabilities.get("quick_actions", false))
		and bool(capabilities.get("keyboard_shortcuts", false))
		and int(capabilities.get("workspace_layout_presets", 0)) == 5
		and bool(capabilities.get("getting_started_reopenable", false))
		and bool(capabilities.get("existing_workflows_reused", false)),
		"The data-driven discovery contract must expose every v0.20.1 workflow."
	):
		return

	var methods := CCFWorkflowDiscoveryServiceV0201.new_project_methods()
	var method_ids: Array[String] = []
	for method in methods:
		method_ids.append(str(method.get("id", "")))
	if not _require(
		"manual" in method_ids
		and "manual_guided" in method_ids
		and "idea_generator" in method_ids
		and "collaborator" in method_ids
		and "idea_notebook" in method_ids
		and "import" in method_ids
		and "template" in method_ids,
		"New Project must explain and route every accepted creation method."
	):
		return

	var app_scene := load("res://scenes/main.tscn") as PackedScene
	var app := app_scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame

	var workspace_value: Variant = app.get("_workspace")
	var workspace := workspace_value as CCFWorkspaceV0201View
	var chooser := app.get("_new_project_chooser_v0201") as CCFNewProjectChooserV0201
	var palette := app.get("_quick_actions_v0201") as CCFQuickActionsWindowV0201
	var guide := app.get("_getting_started_v0201") as CCFGettingStartedWindowV0201
	var library_value: Variant = app.get("_library")
	var version_found := false
	for node in app.find_children("*", "Label", true, false):
		if node is Label and node.text in [
			"Godot rewrite • v0.20.1", "Godot rewrite • v0.20.2",
			"Godot rewrite • v0.20.3", "Godot rewrite • v0.20.4",
			"Godot rewrite • v0.20.5", "Godot rewrite • v0.20.6",
			"Godot rewrite • v0.20.7", "Godot rewrite • v0.20.8", "Godot rewrite • v0.20.9",
			"Godot rewrite • v0.21.0", "Godot rewrite • v0.21.1", "Godot rewrite • v0.21.2", "Godot rewrite • v0.21.3"
		]:
			version_found = true
			break
	if not _require(
		workspace != null
		and library_value is CCFLibraryV0200Hotfix1View
		and chooser != null
		and palette != null
		and guide != null
		and version_found,
		"The live app must mount v0.20.1 discovery surfaces over the current Library and Workspace."
	):
		return

	var quick_button := app.find_child("QuickActionsButtonV0201", true, false) as Button
	var guide_button := app.find_child("GettingStartedButtonV0201", true, false) as Button
	if not _require(
		quick_button != null
		and quick_button.tooltip_text.contains("Ctrl+K")
		and guide_button != null
		and guide_button.tooltip_text.contains("F1"),
		"Quick Actions and Getting Started must be permanently discoverable in navigation."
	):
		return

	app.call("_open_new_project_chooser_v0201")
	await process_frame
	var method_list := chooser.get("_method_list") as ItemList
	var confirm_button := chooser.get("_confirm_button") as Button
	var method_description := chooser.get("_method_description") as Label
	if not _require(
		chooser.visible
		and chooser.get("_template_selector") is OptionButton
		and method_list != null
		and method_list.item_count == methods.size()
		and method_list.get_selected_items().size() == 1
		and confirm_button != null
		and confirm_button.text == "Create Project"
		and not confirm_button.disabled
		and method_description != null
		and not method_description.text.is_empty(),
		"New Project must visibly select a method and require an explicit Create Project confirmation."
	):
		return
	confirm_button.pressed.emit()
	await process_frame
	await process_frame
	if not _require(
		not chooser.visible
		and not workspace.current_project().is_empty(),
		"Create Project must confirm the selected method and open its editable Workspace project."
	):
		return

	app.call("_open_quick_actions_v0201")
	await process_frame
	var action_rows: Array = palette.get("_rows")
	if not _require(
		palette.visible
		and action_rows.size() >= 18
		and str(action_rows[0].get("button").text).contains("Ctrl+N"),
		"Quick Actions must expose searchable grouped actions with visible shortcut labels."
	):
		return
	palette.call("_filter_actions", "lorebook")
	var visible_count := 0
	for row in action_rows:
		var action_button := row.get("button") as Button
		if action_button != null and action_button.visible:
			visible_count += 1
	if not _require(
		visible_count >= 2 and visible_count < action_rows.size(),
		"Quick Actions filtering must narrow the command list without changing the catalog."
	):
		return
	palette.hide()

	var workspace_capabilities := workspace.workflow_capabilities_v0201()
	var layout_menu := workspace.get("_layout_menu_v0201") as MenuButton
	if not _require(
		int(workspace_capabilities.get("layout_presets", 0)) == 5
		and bool(workspace_capabilities.get("field_navigation", false))
		and bool(workspace_capabilities.get("detachable_windows_preserved", false))
		and layout_menu != null
		and layout_menu.get_popup().item_count == 5
		and workspace.run_shortcut_action_v0201("next_field"),
		"Workspace layouts and keyboard-first field navigation must remain live and discoverable."
	):
		return
	workspace.apply_workspace_layout_v0201("editing")
	if not _require(
		str(workspace.get("_active_layout_v0201")) == "editing"
		and layout_menu.text == "Layout: Editing",
		"The Editing preset must apply without replacing or closing existing workspace tools."
	):
		return

	app.call("_run_quick_action_v0201", "library_search")
	await process_frame
	var library_search := library_value.get("_search") as LineEdit
	if not _require(
		str(app.get("_current_view")) == "library"
		and library_search != null
		and library_search.has_focus()
		and library_search.placeholder_text.contains("Ctrl+F"),
		"The global search shortcut must reveal Character Library and focus its existing full-text search."
	):
		return

	app.queue_free()
	await process_frame
	print("V0201_DISCOVERABILITY_OK")
	quit(0)
