extends "res://scripts/main_v01536_hotfix2.gd"

const WORKSPACE_V01536_HOTFIX3 = preload(
	"res://scripts/ui/workspace_v01536_hotfix3.gd"
)
const BUILD_DISPLAY_VERSION_V01536_HOTFIX3 := "0.15.36-hotfix3"


func _ready() -> void:
	super._ready()
	_update_build_version_label_v01536_hotfix3()


func _install_workspace_v01526() -> void:
	if _content == null:
		return
	var previous_workspace: CCFWorkspaceView = _workspace
	if previous_workspace != null and previous_workspace.get_script() == WORKSPACE_V01536_HOTFIX3:
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
	var upgraded: CCFWorkspaceView = WORKSPACE_V01536_HOTFIX3.new()
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
	var template_id := CCFTemplatePreferenceService.default_template_id(_settings)
	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	CCFTemplatePreferenceService.assign_character_template(
		project,
		character_id,
		template_id
	)
	_workspace.load_project(
		project,
		CCFTemplateService.load_template(template_id),
		_settings
	)
	_show_view("workspace")
	_global_status.text = (
		"New character project ready — add some content and Save when you want to keep it"
	)
	_refresh_home_and_library()


func _update_build_version_label_v01536_hotfix3() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V01536_HOTFIX3
		node.tooltip_text = (
			"Development build version. Release metadata is synchronised when release.sh promotes a tagged release."
		)
		return
