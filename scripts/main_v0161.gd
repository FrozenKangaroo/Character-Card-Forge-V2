extends "res://scripts/main_v0160.gd"

const IMAGE_WINDOW_V0161 = preload(
	"res://scripts/ui/image_generation_window_v0161.gd"
)
const BUILD_DISPLAY_VERSION_V0161 := "0.16.1"


func _ready() -> void:
	super._ready()
	_update_build_version_label_v0161()


func _install_image_window_v01529() -> void:
	var previous := _image_generation_window
	if previous != null and previous.get_script() == IMAGE_WINDOW_V0161:
		if previous.has_method("ensure_capability_surface_v0161"):
			previous.ensure_capability_surface_v0161()
		_inject_image_scheduler_v01526()
		return
	if previous != null:
		if previous.project_changed.is_connected(_on_image_project_changed):
			previous.project_changed.disconnect(_on_image_project_changed)
		if previous.get_parent() == self:
			remove_child(previous)
		previous.queue_free()
	var upgraded := IMAGE_WINDOW_V0161.new()
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
	# add_child() completes the Window's _ready() lifecycle before returning. An
	# explicit idempotent ensure here makes the v0.16.1 capability surface
	# independent of inherited _build_ui() dispatch details and keeps embedded,
	# native-window, and headless construction paths consistent.
	upgraded.ensure_capability_surface_v0161()
	upgraded.hide()
	_inject_image_scheduler_v01526()
	upgraded.update_settings_v01528(_settings)
	_sync_current_workspace_to_image_studio_v01528()


func _update_build_version_label_v0161() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V0161
			node.tooltip_text = (
				"Development build version. v0.16.1 begins the Image Studio 2 capability-aware architecture while public release metadata remains synchronised separately by release.sh."
			)
			return
