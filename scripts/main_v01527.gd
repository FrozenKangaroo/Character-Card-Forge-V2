extends "res://scripts/main_v01526.gd"

const BUILD_DISPLAY_VERSION_V01527 := "0.15.27"


func _ready() -> void:
	super._ready()
	_update_build_version_label()


func _update_build_version_label() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V01527
			node.tooltip_text = "Development build version. Release metadata is synchronised when release.sh promotes a tagged release."
			return
