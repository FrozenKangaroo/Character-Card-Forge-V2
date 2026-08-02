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
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(scene_source.contains("main_v01510.gd"), "The active scene must use v0.15.10.")

	print("v0.15.10 persistent FileDialog state regression passed")
	quit(0)
