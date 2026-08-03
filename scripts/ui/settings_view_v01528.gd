class_name CCFSettingsV01528View
extends "res://scripts/ui/settings_view_v01526.gd"

const IMAGE_SETTINGS_V01528 = preload(
	"res://scripts/ui/image_provider_settings_view_v01528.gd"
)


func _ready() -> void:
	super._ready()
	_install_image_settings_v01528()


func _install_image_settings_v01528() -> void:
	var previous := _image_settings_view
	if previous != null and previous.get_script() == IMAGE_SETTINGS_V01528:
		previous.load_settings(_settings)
		return
	var parent_node: Node = previous.get_parent() if previous != null else null
	var child_index := previous.get_index() if previous != null else -1
	if previous != null:
		if previous.settings_saved.is_connected(_on_image_settings_saved):
			previous.settings_saved.disconnect(_on_image_settings_saved)
		if parent_node != null:
			parent_node.remove_child(previous)
		previous.queue_free()
	if parent_node == null:
		return
	var upgraded := IMAGE_SETTINGS_V01528.new() as CCFImageProviderSettingsViewV01528
	upgraded.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgraded.settings_saved.connect(_on_image_settings_saved)
	parent_node.add_child(upgraded)
	if child_index >= 0:
		parent_node.move_child(upgraded, child_index)
	_image_settings_view = upgraded
	upgraded.load_settings(_settings)
