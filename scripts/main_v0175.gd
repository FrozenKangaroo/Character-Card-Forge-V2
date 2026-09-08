extends "res://scripts/main_v0174.gd"

const WORKSPACE_V0175 = preload("res://scripts/ui/workspace_v0175.gd")
const IMAGE_WINDOW_V0175 = preload(
	"res://scripts/ui/image_generation_window_v0175.gd"
)
const BUILD_DISPLAY_VERSION_V0175 := "0.17.5"


func _ready() -> void:
	super._ready()
	_update_build_version_label_v0175()


func _install_workspace_v01526() -> void:
	if _content == null:
		return
	var previous_workspace: CCFWorkspaceView = _workspace
	if previous_workspace != null and previous_workspace.get_script() == WORKSPACE_V0175:
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
	var upgraded: CCFWorkspaceView = WORKSPACE_V0175.new()
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
	if previous != null and previous.get_script() == IMAGE_WINDOW_V0175:
		previous.call("ensure_front_porch_gallery_surface_v0175")
		_inject_image_scheduler_v01526()
		return
	if previous != null:
		if previous.project_changed.is_connected(_on_image_project_changed):
			previous.project_changed.disconnect(_on_image_project_changed)
		if previous.has_signal("collaborator_handoff_requested"):
			var handoff_callable := Callable(
				self, "_on_image_collaborator_handoff_requested_v0170"
			)
			if previous.is_connected(
				"collaborator_handoff_requested", handoff_callable
			):
				previous.disconnect(
					"collaborator_handoff_requested", handoff_callable
				)
		if previous.get_parent() == self:
			remove_child(previous)
		previous.queue_free()
	var upgraded: CCFImageGenerationWindowV0175 = IMAGE_WINDOW_V0175.new()
	upgraded.visible = false
	upgraded.title = "Character Card Forge — Image Generation Studio"
	upgraded.size = Vector2i(1280, 920)
	upgraded.min_size = Vector2i(1000, 720)
	upgraded.force_native = true
	upgraded.transient = true
	upgraded.exclusive = false
	upgraded.project_changed.connect(_on_image_project_changed)
	upgraded.collaborator_handoff_requested.connect(
		_on_image_collaborator_handoff_requested_v0170
	)
	_image_generation_window = upgraded
	add_child(upgraded)
	upgraded.ensure_capability_surface_v0161()
	upgraded.ensure_structured_prompt_surface_v0162()
	upgraded.ensure_tabbed_layout_v0163()
	upgraded.ensure_dynamic_provider_surface_v0164()
	upgraded.ensure_local_model_profile_surface_v0165()
	upgraded.ensure_comfyui_generation_profile_surface_v0166()
	upgraded.ensure_image_input_surface_v0168()
	upgraded.ensure_style_preset_surface_v0169()
	upgraded.ensure_result_workflow_surface_v01610()
	upgraded.ensure_collaborator_handoff_surface_v0170()
	upgraded.ensure_front_porch_gallery_surface_v0175()
	upgraded.hide()
	_inject_image_scheduler_v01526()
	upgraded.update_settings_v01528(_settings)
	_sync_current_workspace_to_image_studio_v01528()


func _update_build_version_label_v0175() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V0175
			node.tooltip_text = (
				"Development build version. v0.17.5 adds Front Porch expression and "
				+ "alternate-look authoring from Image Studio or manual images, canonical "
				+ "favourites, portable expression ZIPs and authenticated API installation."
			)
			return
