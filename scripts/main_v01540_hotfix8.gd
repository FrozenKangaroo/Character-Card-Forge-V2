extends "res://scripts/main_v01540_hotfix7.gd"

const BUILD_DISPLAY_VERSION_V01540_HOTFIX8 := "0.15.40-hotfix8"


func _ready() -> void:
	super._ready()
	_update_build_version_label_v01540_hotfix8()


func _update_build_version_label_v01540_hotfix8() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = (
				"Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V01540_HOTFIX8
			)
			node.tooltip_text = "Development build version. Release target metadata is tracked separately in VERSION and synchronised by release.sh when a tagged release is promoted."
			return
