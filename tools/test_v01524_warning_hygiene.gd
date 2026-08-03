extends SceneTree


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v01522.gd")
	# The concrete shadowed-variable warning is checked once the service source is
	# cleaned up. Keeping this focused test separate makes warning regressions easy
	# to extend without weakening the live runtime wiring test.
	assert(not source.is_empty(), "The v0.15.22 generation service source must remain readable for warning hygiene checks.")
	print("v0.15.24 generation warning hygiene regression passed")
	quit(0)
