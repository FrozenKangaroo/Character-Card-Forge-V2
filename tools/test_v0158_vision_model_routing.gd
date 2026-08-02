extends SceneTree


func _init() -> void:
	var service_source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v0158.gd")
	assert(service_source.contains("profile.get(\"vision_model\""), "v0.15.8 must read the dedicated Vision model field.")
	assert(service_source.contains("routed_profile[\"model\"] = vision_model"), "Vision requests must route _queue_chat_job's model field to vision_model.")
	assert(service_source.contains("profile.duplicate(true)"), "Vision routing must not mutate the stored AI profile used by Text generation.")
	assert(service_source.contains("does not have a Vision model configured"), "Missing Vision models must fail clearly rather than falling back to the Text model.")
	assert(service_source.contains("super.queue_collaborator_vision_summary"), "v0.15.8 must preserve the full-scene Vision pipeline from v0.15.7.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v0158.gd")
	assert(workspace_source.contains("GENERATION_SERVICE_V0158"), "Workspace must install the v0.15.8 routing service.")
	assert(_active_shell_inherits_v0158(), "The active app shell must inherit from v0.15.8 or a later shell built on it.")

	print("v0.15.8 Vision model routing regression passed")
	quit(0)


func _active_shell_inherits_v0158() -> bool:
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	var marker := "res://scripts/main_v"
	var marker_index := scene_source.find(marker)
	if marker_index < 0:
		return false
	var end_index := scene_source.find(".gd", marker_index)
	if end_index < 0:
		return false
	var script_path := scene_source.substr(marker_index, end_index + 3 - marker_index)
	var visited: Dictionary = {}
	for _depth in range(32):
		if script_path == "res://scripts/main_v0158.gd":
			return true
		if script_path.is_empty() or visited.has(script_path):
			return false
		visited[script_path] = true
		var source := FileAccess.get_file_as_string(script_path)
		var extends_marker := "extends \""
		var extends_index := source.find(extends_marker)
		if extends_index < 0:
			return false
		var path_start := extends_index + extends_marker.length()
		var path_end := source.find("\"", path_start)
		if path_end < 0:
			return false
		script_path = source.substr(path_start, path_end - path_start)
	return false
