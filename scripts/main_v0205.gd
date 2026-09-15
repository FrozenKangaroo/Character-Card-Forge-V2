extends "res://scripts/main_v0204.gd"

const BUILD_DISPLAY_VERSION_V0205 := "0.20.5"


func _ready() -> void:
	super._ready()
	_update_build_version_label_v0205()


func _update_comparison_version_v0180_hotfix2() -> String:
	if OS.has_feature("editor"):
		return BUILD_DISPLAY_VERSION_V0205
	return super._update_comparison_version_v0180_hotfix2()


func _update_build_version_label_v0205() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V0205
			node.tooltip_text = (
				"v0.20.5 expands the offline Help Center into a complete task manual "
				+ "with one validated source for in-app and GitHub Wiki guidance."
			)
			return
