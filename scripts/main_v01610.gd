extends "res://scripts/main_v0169.gd"

const IMAGE_WINDOW_V01610 = preload(
	"res://scripts/ui/image_generation_window_v01610.gd"
)
const BUILD_DISPLAY_VERSION_V01610 := "0.16.10"


func _ready() -> void:
	super._ready()
	_update_build_version_label_v01610()


func _install_image_window_v01529() -> void:
	var previous := _image_generation_window
	if previous != null and previous.get_script() == IMAGE_WINDOW_V01610:
		if previous.has_method("ensure_result_workflow_surface_v01610"):
			previous.ensure_result_workflow_surface_v01610()
		_inject_image_scheduler_v01526()
		return
	if previous != null:
		if previous.project_changed.is_connected(_on_image_project_changed):
			previous.project_changed.disconnect(_on_image_project_changed)
		if previous.get_parent() == self:
			remove_child(previous)
		previous.queue_free()
	var upgraded: CCFImageGenerationWindowV01610 = IMAGE_WINDOW_V01610.new()
	upgraded.visible = false
	upgraded.title = "Character Card Forge — Image Generation Studio"
	upgraded.size = Vector2i(1280, 920)
	upgraded.min_size = Vector2i(1000, 720)
	upgraded.force_native = true
	upgraded.transient = true
	upgraded.exclusive = false
	upgraded.project_changed.connect(_on_image_project_changed)
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
	upgraded.hide()
	_inject_image_scheduler_v01526()
	upgraded.update_settings_v01528(_settings)
	_sync_current_workspace_to_image_studio_v01528()


func _update_build_version_label_v01610() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V01610
			node.tooltip_text = "Development build version. v0.16.10 adds exact Image result provenance, reusable settings, favourites, comparison, recovery and optional cost estimates."
			return
