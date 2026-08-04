extends "res://scripts/main_v01530.gd"

const WORKSPACE_V01531 = preload("res://scripts/ui/workspace_v01531.gd")
const IMAGE_WINDOW_V01531 = preload(
	"res://scripts/ui/image_generation_window_v01531.gd"
)
const BUILD_DISPLAY_VERSION_V01531 := "0.15.31"


func _ready() -> void:
	super._ready()
	_wire_ai_jobs_controller_v01531()
	_update_build_version_label()


func _install_workspace_v01526() -> void:
	if _content == null:
		return
	var previous_workspace: CCFWorkspaceView = _workspace
	if previous_workspace != null and previous_workspace.get_script() == WORKSPACE_V01531:
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
	var upgraded: CCFWorkspaceView = WORKSPACE_V01531.new()
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


func _install_image_window_v01529() -> void:
	var previous := _image_generation_window
	if previous != null and previous.get_script() == IMAGE_WINDOW_V01531:
		_inject_image_scheduler_v01526()
		_wire_ai_jobs_controller_v01531()
		return
	if previous != null:
		if previous.project_changed.is_connected(_on_image_project_changed):
			previous.project_changed.disconnect(_on_image_project_changed)
		if previous.get_parent() == self:
			remove_child(previous)
		previous.queue_free()
	var upgraded := IMAGE_WINDOW_V01531.new() as CCFImageGenerationWindowV01531
	upgraded.visible = false
	upgraded.title = "Character Card Forge — Image Generation Studio"
	upgraded.size = Vector2i(1180, 820)
	upgraded.min_size = Vector2i(920, 650)
	upgraded.force_native = true
	upgraded.transient = true
	upgraded.exclusive = false
	upgraded.project_changed.connect(_on_image_project_changed)
	_image_generation_window = upgraded
	add_child(upgraded)
	upgraded.hide()
	_inject_image_scheduler_v01526()
	upgraded.update_settings_v01528(_settings)
	_sync_current_workspace_to_image_studio_v01528()
	_wire_ai_jobs_controller_v01531()


func _wire_ai_jobs_controller_v01531() -> void:
	if not _workspace is CCFWorkspaceV01531View:
		return
	var workspace := _workspace as CCFWorkspaceV01531View
	if _image_generation_window is CCFImageGenerationWindowV01531:
		workspace.set_image_jobs_controller_v01531(
			_image_generation_window as CCFImageGenerationWindowV01531
		)
	else:
		workspace.set_image_jobs_controller_v01531(null)


func _update_build_version_label() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V01531
			node.tooltip_text = (
				"Development build version. Release metadata is synchronised when release.sh promotes a tagged release."
			)
			return
