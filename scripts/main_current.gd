extends "res://scripts/main_v0201.gd"

# This is the first semantic current-runtime layer. Historical versioned shells remain
# available for regression and compatibility evidence, but new releases should update
# this layer instead of extending the active main-shell chain again.
const SUPPORT_CENTER_CURRENT = preload(
	"res://scripts/ui/support_center_window_v0202.gd"
)
const HELP_CENTER_CURRENT = preload(
	"res://scripts/ui/help_center_window_v0203.gd"
)
const SETTINGS_VIEW_CURRENT = preload("res://scripts/ui/settings_view_v0208.gd")
const WORKSPACE_CURRENT = preload("res://scripts/ui/workspace_current.gd")
const CURRENT_BUILD_VERSION := "0.21.1"

var _support_center_v0202: CCFSupportCenterWindowV0202
var _help_center_v0203: CCFHelpCenterWindowV0203


func _ready() -> void:
	super._ready()
	_build_support_center_current()
	_install_support_navigation_current()
	_build_help_center_current()
	_install_help_navigation_current()
	_update_current_build_label()


func _install_settings_view_v01528() -> void:
	if _content == null:
		return
	var previous_settings: CCFSettingsView = _settings_view
	if previous_settings != null and previous_settings.get_script() == SETTINGS_VIEW_CURRENT:
		previous_settings.load_settings(_settings)
		return
	var should_be_visible := _current_view == "settings"
	if previous_settings != null:
		if previous_settings.settings_saved.is_connected(_on_settings_saved):
			previous_settings.settings_saved.disconnect(_on_settings_saved)
		if previous_settings.get_parent() == _content:
			_content.remove_child(previous_settings)
		previous_settings.queue_free()
	var upgraded: CCFSettingsView = SETTINGS_VIEW_CURRENT.new()
	upgraded.visible = should_be_visible
	upgraded.settings_saved.connect(_on_settings_saved)
	_settings_view = upgraded
	_content.add_child(upgraded)
	upgraded.load_settings(_settings)


func _install_workspace_v01526() -> void:
	if _content == null:
		return
	var previous_workspace: CCFWorkspaceView = _workspace
	if previous_workspace != null and previous_workspace.get_script() == WORKSPACE_CURRENT:
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
	var upgraded: CCFWorkspaceView = WORKSPACE_CURRENT.new()
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


func _build_support_center_current() -> void:
	_support_center_v0202 = SUPPORT_CENTER_CURRENT.new()
	_support_center_v0202.visible = false
	add_child(_support_center_v0202)
	_support_center_v0202.hide()


func _install_support_navigation_current() -> void:
	var guide := find_child("GettingStartedButtonV0201", true, false) as Button
	if guide == null or guide.get_parent() == null:
		return
	var side := guide.get_parent() as VBoxContainer
	if side == null:
		return
	var support := Button.new()
	support.name = "SupportCenterButtonV0202"
	support.text = "Support & Diagnostics"
	support.alignment = HORIZONTAL_ALIGNMENT_LEFT
	support.custom_minimum_size.y = 44
	support.tooltip_text = "Create a privacy-safe technical report for troubleshooting."
	support.pressed.connect(_open_support_center_v0202)
	side.add_child(support)
	side.move_child(support, guide.get_index() + 1)


func _build_help_center_current() -> void:
	_help_center_v0203 = HELP_CENTER_CURRENT.new()
	_help_center_v0203.visible = false
	_help_center_v0203.action_requested.connect(_run_quick_action_v0201)
	add_child(_help_center_v0203)
	_help_center_v0203.hide()


func _install_help_navigation_current() -> void:
	var support := find_child("SupportCenterButtonV0202", true, false) as Button
	if support == null or support.get_parent() == null:
		return
	var side := support.get_parent() as VBoxContainer
	if side == null:
		return
	var help := Button.new()
	help.name = "HelpCenterButtonV0203"
	help.text = "Help Center"
	help.alignment = HORIZONTAL_ALIGNMENT_LEFT
	help.custom_minimum_size.y = 44
	help.tooltip_text = "Search offline task guides for Character Card Forge."
	help.pressed.connect(_open_help_center_v0203)
	side.add_child(help)
	side.move_child(help, support.get_index())


func _run_quick_action_v0201(action_id: String) -> void:
	match action_id:
		"help_center":
			_open_help_center_v0203()
		"support_diagnostics":
			_open_support_center_v0202()
		_:
			super._run_quick_action_v0201(action_id)


func _open_support_center_v0202() -> void:
	if _support_center_v0202 != null:
		_support_center_v0202.open_support_center(
			_settings, CURRENT_BUILD_VERSION
		)


func _open_help_center_v0203(article_id := "") -> void:
	if _help_center_v0203 != null:
		_help_center_v0203.open_help_center(article_id)


func support_capabilities_v0202() -> Dictionary:
	return CCFSupportReportServiceV0202.capabilities()


func help_capabilities_v0203() -> Dictionary:
	return CCFHelpContentServiceV0203.capabilities()


func _update_comparison_version_v0180_hotfix2() -> String:
	if OS.has_feature("editor"):
		return CURRENT_BUILD_VERSION
	return super._update_comparison_version_v0180_hotfix2()


func _update_current_build_label() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % CURRENT_BUILD_VERSION
			node.tooltip_text = (
				"v0.21.1 adds a Custom Idea Generator detail mode with an approximate "
				+ "per-idea character target, bounded output budgeting and visible actual lengths."
			)
			return
