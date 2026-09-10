extends "res://scripts/main_v0180_hotfix2.gd"

const BUILD_DISPLAY_VERSION_V0180_HOTFIX3 := "0.18.0-hotfix3"


func _ready() -> void:
	super._ready()
	_update_build_version_label_v0180_hotfix3()


func _update_comparison_version_v0180_hotfix2() -> String:
	if OS.has_feature("editor"):
		return BUILD_DISPLAY_VERSION_V0180_HOTFIX3
	return super._update_comparison_version_v0180_hotfix2()


func _update_build_version_label_v0180_hotfix3() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = (
				"Godot rewrite • v%s"
				% BUILD_DISPLAY_VERSION_V0180_HOTFIX3
			)
			node.tooltip_text = (
				"Development hotfix with automatic word wrapping in Lorebook "
				+ "multiline text editors."
			)
			return
