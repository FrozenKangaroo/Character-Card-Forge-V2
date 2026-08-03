extends "res://scripts/main_v01529.gd"

const IMAGE_WINDOW_V01530 = preload(
	"res://scripts/ui/image_generation_window_v01530.gd"
)
const BUILD_DISPLAY_VERSION_V01530 := "0.15.30"


func _install_image_window_v01529() -> void:
	var previous := _image_generation_window
	if previous != null and previous.get_script() == IMAGE_WINDOW_V01530:
		_inject_image_scheduler_v01526()
		return
	if previous != null:
		if previous.project_changed.is_connected(_on_image_project_changed):
			previous.project_changed.disconnect(_on_image_project_changed)
		if previous.get_parent() == self:
			remove_child(previous)
		previous.queue_free()
	var upgraded := IMAGE_WINDOW_V01530.new() as CCFImageGenerationWindowV01530
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


func _update_build_version_label() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V01530
			node.tooltip_text = (
				"Development build version. Release metadata is synchronised when release.sh promotes a tagged release."
			)
			return
