extends "res://scripts/main_v0161.gd"

const IMAGE_WINDOW_V0162 = preload(
	"res://scripts/ui/image_generation_window_v0162.gd"
)
const BUILD_DISPLAY_VERSION_V0162 := "0.16.2"


func _ready() -> void:
	super._ready()
	_update_build_version_label_v0162()


func _install_image_window_v01529() -> void:
	var previous := _image_generation_window
	if previous != null and previous.get_script() == IMAGE_WINDOW_V0162:
		if previous.has_method("ensure_capability_surface_v0161"):
			previous.ensure_capability_surface_v0161()
		if previous.has_method("ensure_structured_prompt_surface_v0162"):
			previous.ensure_structured_prompt_surface_v0162()
		_inject_image_scheduler_v01526()
		return
	if previous != null:
		if previous.project_changed.is_connected(_on_image_project_changed):
			previous.project_changed.disconnect(_on_image_project_changed)
		if previous.get_parent() == self:
			remove_child(previous)
		previous.queue_free()
	var upgraded := IMAGE_WINDOW_V0162.new()
	upgraded.visible = false
	upgraded.title = "Character Card Forge — Image Generation Studio"
	upgraded.size = Vector2i(1240, 900)
	upgraded.min_size = Vector2i(980, 700)
	upgraded.force_native = true
	upgraded.transient = true
	upgraded.exclusive = false
	upgraded.project_changed.connect(_on_image_project_changed)
	_image_generation_window = upgraded
	add_child(upgraded)
	upgraded.ensure_capability_surface_v0161()
	upgraded.ensure_structured_prompt_surface_v0162()
	upgraded.hide()
	_inject_image_scheduler_v01526()
	upgraded.update_settings_v01528(_settings)
	_sync_current_workspace_to_image_studio_v01528()


func _update_build_version_label_v0162() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V0162
			node.tooltip_text = (
				"Development build version. v0.16.2 adds provider-independent structured creative prompt composition on top of the v0.16.1 Image Studio capability foundation."
			)
			return
