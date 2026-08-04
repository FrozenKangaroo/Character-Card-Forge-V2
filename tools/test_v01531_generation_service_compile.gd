extends SceneTree


func _init() -> void:
	var path := "res://scripts/services/generation_service_v01531.gd"
	var source := FileAccess.get_file_as_string(path)
	assert(not source.is_empty(), "v0.15.31 generation service source must be readable.")
	var loaded := ResourceLoader.load(path, "Script", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded == null or not loaded is Script:
		push_error("ResourceLoader could not compile/load the v0.15.31 generation service.")
		quit(1)
		return
	print("v0.15.31 generation service direct compile passed")
	quit(0)
