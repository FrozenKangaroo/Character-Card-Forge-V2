extends SceneTree


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v01311_hotfix.gd")
	if source.contains("func _begin_creative_expansion(seed: Dictionary)"):
		push_error("Creative Concept helper must not shadow Godot's built-in seed() identifier.")
		quit(1)
		return
	if not source.contains("func _begin_creative_expansion(visual_seed: Dictionary)"):
		push_error("Expected the Creative Concept helper to use the visual_seed parameter name.")
		quit(1)
		return
	print("v0.13.11 seed identifier regression passed.")
	quit(0)
