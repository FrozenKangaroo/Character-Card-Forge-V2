extends "res://scripts/main_v0173.gd"

const BUILD_DISPLAY_VERSION_V0173_HOTFIX1 := "0.17.3-hotfix1"


func _ready() -> void:
	super._ready()
	_update_build_version_label_v0173_hotfix1()


func _update_build_version_label_v0173_hotfix1() -> void:
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text.begins_with("Godot rewrite • v"):
			node.text = (
				"Godot rewrite • v%s"
				% BUILD_DISPLAY_VERSION_V0173_HOTFIX1
			)
			node.tooltip_text = (
				"Development hotfix. OpenRouter image profiles use its native "
				+ "/api/v1/images generation and /api/v1/images/models discovery APIs."
			)
			return
