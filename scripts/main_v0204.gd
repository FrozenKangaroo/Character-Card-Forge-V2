extends "res://scripts/main_v0203.gd"

const BUILD_DISPLAY_VERSION_V0204 := "0.20.4"


func _ready() -> void:
	super._ready()
	_update_build_version_label_v0204()


func _update_comparison_version_v0180_hotfix2() -> String:
	if OS.has_feature("editor"):
		return BUILD_DISPLAY_VERSION_V0204
	return super._update_comparison_version_v0180_hotfix2()


func _update_build_version_label_v0204() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = "Godot rewrite • v%s" % BUILD_DISPLAY_VERSION_V0204
			node.tooltip_text = (
				"v0.20.4 adds deterministic release preflight checks, reviewed "
				+ "version-matched notes and verified platform package checksums."
			)
			return
