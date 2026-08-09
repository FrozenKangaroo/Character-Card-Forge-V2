extends "res://scripts/main_v01540_hotfix8.gd"

const BUILD_DISPLAY_VERSION_V01540_HOTFIX9 := "0.15.40-hotfix9"


func _ready() -> void:
	super._ready()
	_update_build_version_label_v01540_hotfix9()


func _update_build_version_label_v01540_hotfix9() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = (
				"Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V01540_HOTFIX9
			)
			node.tooltip_text = "Development build version. Release target metadata is tracked separately and interrupted release metadata is recoverable by update.sh."
			return
