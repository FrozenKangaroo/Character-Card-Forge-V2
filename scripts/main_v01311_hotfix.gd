extends "res://scripts/main_v01311.gd"

const WORKSPACE_V01311 = preload("res://scripts/ui/workspace_v01311.gd")
const GENERATION_SERVICE_V01311_HOTFIX = preload("res://scripts/services/generation_service_v01311_hotfix.gd")
const BUILD_DISPLAY_VERSION_V01311_HOTFIX := "0.13.11-hotfix1"


func _install_workspace_v0133() -> void:
	if _content == null:
		return
	var previous_workspace: CCFWorkspaceView = _workspace
	if previous_workspace != null and previous_workspace.get_script() == WORKSPACE_V01311:
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
	var upgraded: CCFWorkspaceView = WORKSPACE_V01311.new()
	upgraded.visible = should_be_visible
	upgraded.project_saved.connect(_on_project_saved)
	upgraded.library_requested.connect(_show_library_from_workspace)
	upgraded.settings_requested.connect(_show_settings_from_workspace)
	upgraded.template_manager_requested.connect(_show_templates_from_workspace)
	upgraded.series_manager_requested.connect(_show_series_from_workspace)
	upgraded.project_imported.connect(_on_project_imported)
	_workspace = upgraded
	_content.add_child(upgraded)


func _install_generation_parity_service() -> void:
	if _workspace == null:
		return
	var current_service: CCFGenerationService = _workspace._generation_service
	if current_service != null and current_service.get_script() == GENERATION_SERVICE_V01311_HOTFIX:
		return
	if current_service != null:
		_disconnect_workspace_generation_signals(current_service)
		if current_service.get_parent() == _workspace:
			_workspace.remove_child(current_service)
		current_service.queue_free()
	var upgraded_service: CCFGenerationService = GENERATION_SERVICE_V01311_HOTFIX.new()
	_workspace._generation_service = upgraded_service
	_workspace.add_child(upgraded_service)
	upgraded_service.job_started.connect(_workspace._on_job_started)
	upgraded_service.job_completed.connect(_workspace._on_job_completed)
	upgraded_service.job_failed.connect(_workspace._on_job_failed)
	upgraded_service.job_cancelled.connect(_workspace._on_job_cancelled)
	upgraded_service.queue_changed.connect(_workspace._on_queue_changed)
	_rebind_workspace_generation_clients(upgraded_service)


func _update_build_version_label() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V01311_HOTFIX
			node.tooltip_text = "Development build version. Release metadata is synchronised when release.sh promotes a tagged release."
			return
