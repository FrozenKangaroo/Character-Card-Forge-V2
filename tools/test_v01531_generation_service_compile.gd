extends SceneTree


func _init() -> void:
	var path := "res://scripts/services/generation_service_v01531.gd"
	var source := FileAccess.get_file_as_string(path)
	assert(not source.is_empty(), "v0.15.31 generation service source must be readable.")
	var script := GDScript.new()
	script.source_code = source
	var error := script.reload()
	if error != OK:
		push_error(
			"Direct v0.15.31 generation-service compile failed with error code %d." % error
		)
		quit(1)
		return
	print("v0.15.31 generation service direct compile passed")
	quit(0)
