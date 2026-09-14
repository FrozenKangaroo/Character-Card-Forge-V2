extends "res://scripts/main_v0200_hotfix1.gd"

const WORKSPACE_V0201 = preload("res://scripts/ui/workspace_v0201.gd")
const NEW_PROJECT_CHOOSER_V0201 = preload(
	"res://scripts/ui/new_project_chooser_v0201.gd"
)
const QUICK_ACTIONS_V0201 = preload(
	"res://scripts/ui/quick_actions_window_v0201.gd"
)
const GETTING_STARTED_V0201 = preload(
	"res://scripts/ui/getting_started_window_v0201.gd"
)
const BUILD_DISPLAY_VERSION_V0201 := "0.20.1"

var _new_project_chooser_v0201: CCFNewProjectChooserV0201
var _quick_actions_v0201: CCFQuickActionsWindowV0201
var _getting_started_v0201: CCFGettingStartedWindowV0201


func _ready() -> void:
	super._ready()
	_build_discovery_surfaces_v0201()
	_install_discovery_navigation_v0201()
	_decorate_discoverability_v0201()
	_update_build_version_label_v0201()
	if not OS.has_environment("CCF_REGRESSION_RUN") and not _getting_started_seen_v0201():
		call_deferred("_open_getting_started_v0201")


func _shortcut_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var command_pressed := key_event.ctrl_pressed or key_event.meta_pressed
	var action_id := ""
	if key_event.keycode == KEY_F1:
		action_id = "getting_started"
	elif command_pressed and key_event.keycode == KEY_K:
		action_id = "quick_actions"
	elif command_pressed and key_event.keycode == KEY_N and not key_event.shift_pressed:
		action_id = "new_project"
	elif command_pressed and key_event.keycode == KEY_F and not key_event.shift_pressed:
		action_id = "library_search"
	elif command_pressed and key_event.keycode == KEY_S and not key_event.shift_pressed:
		action_id = "save"
	elif command_pressed and key_event.shift_pressed and key_event.keycode == KEY_R:
		action_id = "ai_review"
	elif command_pressed and key_event.shift_pressed and key_event.keycode == KEY_D:
		action_id = "compare"
	elif command_pressed and key_event.shift_pressed and key_event.keycode == KEY_E:
		action_id = "export_install"
	elif command_pressed and key_event.shift_pressed and key_event.keycode == KEY_L:
		action_id = "lorebook"
	elif key_event.alt_pressed and key_event.keycode == KEY_DOWN:
		action_id = "next_field"
	elif key_event.alt_pressed and key_event.keycode == KEY_UP:
		action_id = "previous_field"
	if action_id.is_empty():
		return
	_run_quick_action_v0201(action_id)
	get_viewport().set_input_as_handled()


func _install_workspace_v01526() -> void:
	if _content == null:
		return
	var previous_workspace: CCFWorkspaceView = _workspace
	if previous_workspace != null and previous_workspace.get_script() == WORKSPACE_V0201:
		previous_workspace.update_settings(_settings)
		return
	var should_be_visible := _current_view == "workspace"
	if previous_workspace != null:
		if previous_workspace.project_saved.is_connected(_on_project_saved):
			previous_workspace.project_saved.disconnect(_on_project_saved)
		if previous_workspace.library_requested.is_connected(_show_library_from_workspace):
			previous_workspace.library_requested.disconnect(_show_library_from_workspace)
		if previous_workspace.settings_requested.is_connected(_show_settings_from_workspace):
			previous_workspace.settings_requested.disconnect(_show_settings_from_workspace)
		if previous_workspace.template_manager_requested.is_connected(_show_templates_from_workspace):
			previous_workspace.template_manager_requested.disconnect(_show_templates_from_workspace)
		if previous_workspace.series_manager_requested.is_connected(_show_series_from_workspace):
			previous_workspace.series_manager_requested.disconnect(_show_series_from_workspace)
		if previous_workspace.project_imported.is_connected(_on_project_imported):
			previous_workspace.project_imported.disconnect(_on_project_imported)
		if previous_workspace.get_parent() == _content:
			_content.remove_child(previous_workspace)
		previous_workspace.queue_free()
	var upgraded: CCFWorkspaceView = WORKSPACE_V0201.new()
	upgraded.visible = should_be_visible
	upgraded.project_saved.connect(_on_project_saved)
	upgraded.library_requested.connect(_show_library_from_workspace)
	upgraded.settings_requested.connect(_show_settings_from_workspace)
	upgraded.template_manager_requested.connect(_show_templates_from_workspace)
	upgraded.series_manager_requested.connect(_show_series_from_workspace)
	upgraded.project_imported.connect(_on_project_imported)
	_workspace = upgraded
	_content.add_child(upgraded)
	upgraded.update_settings(_settings)
	_wire_ai_jobs_controller_v01531()


func _create_new_character() -> void:
	if OS.has_environment("CCF_REGRESSION_RUN"):
		super._create_new_character()
		return
	_open_new_project_chooser_v0201()


func _open_new_project_chooser_v0201() -> void:
	if _new_project_chooser_v0201 == null:
		super._create_new_character()
		return
	var template_id := CCFTemplatePreferenceService.default_template_id(_settings)
	_new_project_chooser_v0201.open_chooser(template_id)


func workflow_discovery_capabilities_v0201() -> Dictionary:
	return CCFWorkflowDiscoveryServiceV0201.capabilities()


func _build_discovery_surfaces_v0201() -> void:
	_new_project_chooser_v0201 = NEW_PROJECT_CHOOSER_V0201.new()
	_new_project_chooser_v0201.visible = false
	_new_project_chooser_v0201.method_selected.connect(
		_on_new_project_method_v0201
	)
	add_child(_new_project_chooser_v0201)
	_new_project_chooser_v0201.hide()

	_quick_actions_v0201 = QUICK_ACTIONS_V0201.new()
	_quick_actions_v0201.visible = false
	_quick_actions_v0201.action_requested.connect(_run_quick_action_v0201)
	add_child(_quick_actions_v0201)
	_quick_actions_v0201.hide()

	_getting_started_v0201 = GETTING_STARTED_V0201.new()
	_getting_started_v0201.visible = false
	_getting_started_v0201.action_requested.connect(_run_quick_action_v0201)
	_getting_started_v0201.dismissed.connect(_mark_getting_started_seen_v0201)
	add_child(_getting_started_v0201)
	_getting_started_v0201.hide()


func _install_discovery_navigation_v0201() -> void:
	var settings_button := _nav_buttons.get("settings") as Button
	if settings_button == null or settings_button.get_parent() == null:
		return
	var side := settings_button.get_parent() as VBoxContainer
	if side == null:
		return
	var quick := Button.new()
	quick.name = "QuickActionsButtonV0201"
	quick.text = "Quick Actions"
	quick.alignment = HORIZONTAL_ALIGNMENT_LEFT
	quick.custom_minimum_size.y = 44
	quick.tooltip_text = "Search commands, tools and layouts (Ctrl+K)."
	quick.pressed.connect(_open_quick_actions_v0201)
	side.add_child(quick)
	side.move_child(quick, settings_button.get_index() + 1)
	var guide := Button.new()
	guide.name = "GettingStartedButtonV0201"
	guide.text = "Getting Started"
	guide.alignment = HORIZONTAL_ALIGNMENT_LEFT
	guide.custom_minimum_size.y = 44
	guide.tooltip_text = "Reopen the Getting Started guide (F1)."
	guide.pressed.connect(_open_getting_started_v0201)
	side.add_child(guide)
	side.move_child(guide, quick.get_index() + 1)


func _decorate_discoverability_v0201() -> void:
	if _library != null:
		var search_value: Variant = _library.get("_search")
		var search := search_value as LineEdit
		if search != null:
			search.placeholder_text = "Search projects, characters, card text and metadata…  Ctrl+F"
	for node in find_children("*", "Button", true, false):
		if not node is Button:
			continue
		var button := node as Button
		if button.text in ["New Project", "New Character Project"]:
			button.tooltip_text = "Choose how to start a new project (Ctrl+N)."


func _on_new_project_method_v0201(method_id: String, template_id: String) -> void:
	super._create_new_character()
	if _workspace == null or _workspace.current_project().is_empty():
		return
	var project := _workspace.current_project()
	var character_id := CCFStorageService.active_character_id(project)
	CCFTemplatePreferenceService.assign_character_template(
		project, character_id, template_id
	)
	var save_result := CCFStorageService.save_project(project)
	if not bool(save_result.get("ok", false)):
		_global_status.text = str(
			save_result.get("error", "Could not apply the selected starting template.")
		)
		return
	_workspace.load_project(
		project, CCFTemplateService.load_template(template_id), _settings
	)
	call_deferred("_route_new_project_method_v0201", method_id)


func _route_new_project_method_v0201(method_id: String) -> void:
	if _workspace == null:
		return
	match method_id:
		"manual_guided":
			_workspace.call("_open_manual_guided")
		"idea_generator":
			_workspace.call("_open_idea_generator")
		"collaborator":
			_workspace.call("_open_character_collaborator_v015")
		"idea_notebook":
			_workspace.call("open_idea_notebook_v01532")
		"import":
			_workspace.call("_open_import_export_studio")
		"template":
			_global_status.text = "Template draft ready. Edit fields directly or choose another Workspace tool."
		_:
			_global_status.text = "Blank character workspace ready."


func _run_quick_action_v0201(action_id: String) -> void:
	match action_id:
		"quick_actions":
			_open_quick_actions_v0201()
		"new_project":
			_open_new_project_chooser_v0201()
		"library":
			_show_view("library")
		"library_search":
			_show_view("library")
			call_deferred("_focus_library_search_v0201")
		"image_studio":
			_open_image_studio()
		"settings":
			_show_view("settings")
		"getting_started":
			_open_getting_started_v0201()
		_:
			if _current_view != "workspace" or _workspace.current_project().is_empty():
				_global_status.text = "Open or create a project before using that Workspace action."
				return
			if _workspace.has_method("run_shortcut_action_v0201"):
				_workspace.call("run_shortcut_action_v0201", action_id)


func _open_quick_actions_v0201() -> void:
	if _quick_actions_v0201 != null:
		_quick_actions_v0201.open_palette()


func _open_getting_started_v0201() -> void:
	if _getting_started_v0201 != null:
		_getting_started_v0201.open_guide()


func _focus_library_search_v0201() -> void:
	if _library == null:
		return
	var search_value: Variant = _library.get("_search")
	var search := search_value as LineEdit
	if search != null:
		search.grab_focus()


func _getting_started_seen_v0201() -> bool:
	var ui_value: Variant = _settings.get("ui", {})
	return ui_value is Dictionary and bool(
		(ui_value as Dictionary).get("getting_started_seen_v0201", false)
	)


func _mark_getting_started_seen_v0201() -> void:
	var ui_value: Variant = _settings.get("ui", {})
	var ui: Dictionary = {}
	if ui_value is Dictionary:
		ui = (ui_value as Dictionary).duplicate(true)
	ui["getting_started_seen_v0201"] = true
	_settings["ui"] = ui
	CCFSettingsService.save_settings(_settings)


func _update_comparison_version_v0180_hotfix2() -> String:
	if OS.has_feature("editor"):
		return BUILD_DISPLAY_VERSION_V0201
	return super._update_comparison_version_v0180_hotfix2()


func _update_build_version_label_v0201() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V0201
			node.tooltip_text = (
				"v0.20.1 adds guided project creation, searchable Quick Actions, "
				+ "discoverable keyboard shortcuts, task-focused workspace layouts "
				+ "and a reopenable Getting Started guide."
			)
			return
