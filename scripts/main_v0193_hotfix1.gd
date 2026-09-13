extends "res://scripts/main_v0193.gd"

const BUILD_DISPLAY_VERSION_V0193_HOTFIX1 := "0.19.3-hotfix1"


func _ready() -> void:
	super._ready()
	_update_build_version_label_v0193_hotfix1()


func _update_comparison_version_v0180_hotfix2() -> String:
	if OS.has_feature("editor"):
		return BUILD_DISPLAY_VERSION_V0193_HOTFIX1
	return super._update_comparison_version_v0180_hotfix2()


func _update_build_version_label_v0193_hotfix1() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = (
				"Godot rewrite • v%s"
				% BUILD_DISPLAY_VERSION_V0193_HOTFIX1
			)
			node.tooltip_text = (
				"v0.19.3-hotfix1 restores Front Porch Test Chat live completion "
				+ "updates by following the supported WebSocket event envelope."
			)
			return
