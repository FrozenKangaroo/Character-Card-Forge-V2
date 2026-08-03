extends SceneTree


func _init() -> void:
	var service_source := FileAccess.get_file_as_string("res://scripts/services/file_dialog_state_service_v01510.gd")
	assert(service_source.contains("FileDialog.get_favorite_list()"), "v0.15.10 must capture FileDialog favorites.")
	assert(service_source.contains("FileDialog.set_favorite_list"), "v0.15.10 must restore FileDialog favorites.")
	assert(service_source.contains("FileDialog.get_recent_list()"), "v0.15.10 must capture FileDialog history/recents.")
	assert(service_source.contains("FileDialog.set_recent_list"), "v0.15.10 must restore FileDialog history/recents.")
	assert(service_source.contains("OS.SYSTEM_DIR_DOWNLOADS"), "Downloads must be seeded as a default quick location.")
	assert(service_source.contains("display_mode"), "FileDialog list/thumbnail layout must persist.")
	assert(service_source.contains("show_hidden_files"), "FileDialog hidden-file view preference must persist.")
	assert(service_source.contains("sort_menu_id"), "FileDialog sort selection must persist across launches.")
	assert(service_source.contains("MAX_RECENT_DIRS_V01510 := 20"), "Recent folder history must be bounded.")
	assert(service_source.contains("STATE_PATH_V01510"), "FileDialog state must have independent user:// persistence.")

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01510.gd")
	assert(main_source.contains("FILE_DIALOG_STATE_SERVICE_V01510"), "The v0.15.10 shell must install the shared FileDialog state service.")
	assert(main_source.contains("BUILD_DISPLAY_VERSION_V01510 := \"0.15.10\""), "The v0.15.10 shell must expose the new build version.")
	assert(_active_shell_inherits_v01510(), "The active scene must use v0.15.10 or a later shell that inherits it.")

	print("v0.15.10 persistent FileDialog state regression passed")
	quit(0)


func _active_shell_inherits_v01510() -> bool:
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	var marker := "res://scripts/main_v"
	var start := scene_source.find(marker)
	if start < 0:
		return false
	var end := scene_source.find(".gd", start)
	if end < 0:
		return false
	var script_path := scene_source.substr(start, end - start + 3)
	# Keep historical feature-shell checks forward-compatible as later releases
	# add thin inherited composition layers above v0.15.10.
	for _depth in range(64):
		if script_path == "res://scripts/main_v01510.gd":
			return true
		var source := FileAccess.get_file_as_string(script_path)
		var extends_prefix := "extends \""
		var extends_start := source.find(extends_prefix)
		if extends_start < 0:
			return false
		extends_start += extends_prefix.length()
		var extends_end := source.find("\"", extends_start)
		if extends_end < 0:
			return false
		script_path = source.substr(extends_start, extends_end - extends_start)
	return false