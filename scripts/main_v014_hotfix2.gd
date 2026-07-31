extends "res://scripts/main_v014_hotfix1.gd"

const BUILD_DISPLAY_VERSION_V014_HOTFIX2 := "0.14.0-hotfix2"


func _update_build_version_label() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V014_HOTFIX2
			node.tooltip_text = "Development build version. Release metadata is synchronised when release.sh promotes a tagged release."
			return
