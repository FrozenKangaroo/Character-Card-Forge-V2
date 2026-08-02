class_name CCFFileDialogStateServiceV01510
extends Node

const STATE_PATH_V01510 := "user://file_dialog_state_v01510.json"
const SAVE_POLL_SECONDS_V01510 := 0.75
const MAX_RECENT_DIRS_V01510 := 20

var _state_v01510: Dictionary = {}
var _tracked_dialog_ids_v01510: Dictionary = {}
var _poll_elapsed_v01510 := 0.0
var _restoring_sort_v01510 := false


func _ready() -> void:
	_state_v01510 = _load_state_v01510()
	_restore_shared_lists_v01510()
	_track_tree_v01510(get_tree().root)
	if not get_tree().node_added.is_connected(_on_node_added_v01510):
		get_tree().node_added.connect(_on_node_added_v01510)
	set_process(true)


func _exit_tree() -> void:
	_capture_shared_lists_v01510()
	_save_state_v01510()
	if get_tree() != null and get_tree().node_added.is_connected(_on_node_added_v01510):
		get_tree().node_added.disconnect(_on_node_added_v01510)


func _process(delta: float) -> void:
	_poll_elapsed_v01510 += delta
	if _poll_elapsed_v01510 < SAVE_POLL_SECONDS_V01510:
		return
	_poll_elapsed_v01510 = 0.0
	if _capture_shared_lists_v01510():
		_save_state_v01510()


func _default_state_v01510() -> Dictionary:
	var favorites: Array = _packed_to_array_v01510(FileDialog.get_favorite_list())
	var downloads := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS).strip_edges()
	if not downloads.is_empty() and DirAccess.dir_exists_absolute(downloads) and downloads not in favorites:
		favorites.append(downloads)
	return {
		"format_version": 1,
		"favorites": favorites,
		"recents": _packed_to_array_v01510(FileDialog.get_recent_list()),
		"display_mode": FileDialog.DISPLAY_THUMBNAILS,
		"show_hidden_files": false,
		"last_filesystem_dir": downloads if not downloads.is_empty() else "",
		"sort_menu_id": -1
	}


func _load_state_v01510() -> Dictionary:
	var defaults := _default_state_v01510()
	if not FileAccess.file_exists(STATE_PATH_V01510):
		return defaults
	var file := FileAccess.open(STATE_PATH_V01510, FileAccess.READ)
	if file == null:
		return defaults
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return defaults
	var result: Dictionary = defaults.duplicate(true)
	result.merge(parsed, true)
	result["favorites"] = _normalise_path_list_v01510(result.get("favorites", []), 0)
	result["recents"] = _normalise_path_list_v01510(result.get("recents", []), MAX_RECENT_DIRS_V01510)
	result["display_mode"] = clampi(int(result.get("display_mode", FileDialog.DISPLAY_THUMBNAILS)), FileDialog.DISPLAY_THUMBNAILS, FileDialog.DISPLAY_LIST)
	result["show_hidden_files"] = bool(result.get("show_hidden_files", false))
	result["last_filesystem_dir"] = str(result.get("last_filesystem_dir", "")).strip_edges()
	result["sort_menu_id"] = int(result.get("sort_menu_id", -1))
	return result


func _save_state_v01510() -> void:
	var file := FileAccess.open(STATE_PATH_V01510, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save FileDialog preferences to %s" % STATE_PATH_V01510)
		return
	file.store_string(JSON.stringify(_state_v01510, "  "))
	file.close()


func _restore_shared_lists_v01510() -> void:
	FileDialog.set_favorite_list(PackedStringArray(_state_v01510.get("favorites", [])))
	FileDialog.set_recent_list(PackedStringArray(_state_v01510.get("recents", [])))


func _capture_shared_lists_v01510() -> bool:
	var favorites := _normalise_path_list_v01510(FileDialog.get_favorite_list(), 0)
	var recents := _normalise_path_list_v01510(FileDialog.get_recent_list(), MAX_RECENT_DIRS_V01510)
	var changed := favorites != _state_v01510.get("favorites", []) or recents != _state_v01510.get("recents", [])
	if changed:
		_state_v01510["favorites"] = favorites
		_state_v01510["recents"] = recents
	return changed


func _track_tree_v01510(node: Node) -> void:
	if node is FileDialog:
		_track_dialog_v01510(node)
	for child in node.get_children():
		_track_tree_v01510(child)


func _on_node_added_v01510(node: Node) -> void:
	if node is FileDialog:
		call_deferred("_track_dialog_v01510", node)


func _track_dialog_v01510(dialog: FileDialog) -> void:
	if not is_instance_valid(dialog):
		return
	var instance_id := dialog.get_instance_id()
	if _tracked_dialog_ids_v01510.has(instance_id):
		return
	_tracked_dialog_ids_v01510[instance_id] = true
	dialog.display_mode = int(_state_v01510.get("display_mode", FileDialog.DISPLAY_THUMBNAILS))
	dialog.show_hidden_files = bool(_state_v01510.get("show_hidden_files", false))
	var last_dir := str(_state_v01510.get("last_filesystem_dir", "")).strip_edges()
	if dialog.access == FileDialog.ACCESS_FILESYSTEM and not last_dir.is_empty() and DirAccess.dir_exists_absolute(last_dir):
		dialog.current_dir = last_dir
	if not dialog.visibility_changed.is_connected(_on_dialog_visibility_changed_v01510.bind(dialog)):
		dialog.visibility_changed.connect(_on_dialog_visibility_changed_v01510.bind(dialog))
	if not dialog.file_selected.is_connected(_on_dialog_file_selected_v01510.bind(dialog)):
		dialog.file_selected.connect(_on_dialog_file_selected_v01510.bind(dialog))
	if not dialog.files_selected.is_connected(_on_dialog_files_selected_v01510.bind(dialog)):
		dialog.files_selected.connect(_on_dialog_files_selected_v01510.bind(dialog))
	if not dialog.dir_selected.is_connected(_on_dialog_dir_selected_v01510.bind(dialog)):
		dialog.dir_selected.connect(_on_dialog_dir_selected_v01510.bind(dialog))
	call_deferred("_wire_sort_menu_v01510", dialog)


func _on_dialog_visibility_changed_v01510(dialog: FileDialog) -> void:
	if not is_instance_valid(dialog):
		return
	if dialog.visible:
		dialog.display_mode = int(_state_v01510.get("display_mode", dialog.display_mode))
		dialog.show_hidden_files = bool(_state_v01510.get("show_hidden_files", dialog.show_hidden_files))
		FileDialog.set_favorite_list(PackedStringArray(_state_v01510.get("favorites", [])))
		FileDialog.set_recent_list(PackedStringArray(_state_v01510.get("recents", [])))
		call_deferred("_wire_sort_menu_v01510", dialog)
		call_deferred("_restore_sort_menu_v01510", dialog)
		return
	_capture_dialog_preferences_v01510(dialog)


func _on_dialog_file_selected_v01510(path: String, dialog: FileDialog) -> void:
	if dialog.access == FileDialog.ACCESS_FILESYSTEM:
		_remember_directory_v01510(path.get_base_dir())
	_capture_dialog_preferences_v01510(dialog)


func _on_dialog_files_selected_v01510(paths: PackedStringArray, dialog: FileDialog) -> void:
	if dialog.access == FileDialog.ACCESS_FILESYSTEM and not paths.is_empty():
		_remember_directory_v01510(str(paths[0]).get_base_dir())
	_capture_dialog_preferences_v01510(dialog)


func _on_dialog_dir_selected_v01510(path: String, dialog: FileDialog) -> void:
	if dialog.access == FileDialog.ACCESS_FILESYSTEM:
		_remember_directory_v01510(path)
	_capture_dialog_preferences_v01510(dialog)


func _capture_dialog_preferences_v01510(dialog: FileDialog) -> void:
	if not is_instance_valid(dialog):
		return
	_state_v01510["display_mode"] = int(dialog.display_mode)
	_state_v01510["show_hidden_files"] = bool(dialog.show_hidden_files)
	if dialog.access == FileDialog.ACCESS_FILESYSTEM:
		var current_dir := dialog.current_dir.strip_edges()
		if not current_dir.is_empty() and DirAccess.dir_exists_absolute(current_dir):
			_state_v01510["last_filesystem_dir"] = current_dir
	_capture_shared_lists_v01510()
	_save_state_v01510()


func _remember_directory_v01510(directory: String) -> void:
	var clean := directory.strip_edges()
	if clean.is_empty() or not DirAccess.dir_exists_absolute(clean):
		return
	_state_v01510["last_filesystem_dir"] = clean
	var recents: Array = _normalise_path_list_v01510(FileDialog.get_recent_list(), 0)
	recents.erase(clean)
	recents.push_front(clean)
	while recents.size() > MAX_RECENT_DIRS_V01510:
		recents.pop_back()
	_state_v01510["recents"] = recents
	FileDialog.set_recent_list(PackedStringArray(recents))
	_save_state_v01510()


func _wire_sort_menu_v01510(dialog: FileDialog) -> void:
	if not is_instance_valid(dialog) or dialog.use_native_dialog:
		return
	var popup := _find_sort_popup_v01510(dialog)
	if popup == null:
		return
	var callback := _on_sort_menu_id_pressed_v01510.bind(dialog)
	if not popup.id_pressed.is_connected(callback):
		popup.id_pressed.connect(callback)


func _restore_sort_menu_v01510(dialog: FileDialog) -> void:
	if not is_instance_valid(dialog) or dialog.use_native_dialog:
		return
	var saved_id := int(_state_v01510.get("sort_menu_id", -1))
	if saved_id < 0:
		return
	var popup := _find_sort_popup_v01510(dialog)
	if popup == null or popup.get_item_index(saved_id) < 0:
		return
	_restoring_sort_v01510 = true
	popup.id_pressed.emit(saved_id)
	_restoring_sort_v01510 = false


func _on_sort_menu_id_pressed_v01510(id: int, dialog: FileDialog) -> void:
	if _restoring_sort_v01510 or not is_instance_valid(dialog):
		return
	_state_v01510["sort_menu_id"] = id
	_state_v01510["display_mode"] = int(dialog.display_mode)
	_save_state_v01510()


func _find_sort_popup_v01510(root: Node) -> PopupMenu:
	for child in root.get_children():
		if child is MenuButton:
			var menu_button := child as MenuButton
			var popup := menu_button.get_popup()
			if _looks_like_sort_popup_v01510(menu_button, popup):
				return popup
		var nested := _find_sort_popup_v01510(child)
		if nested != null:
			return nested
	return null


func _looks_like_sort_popup_v01510(button: MenuButton, popup: PopupMenu) -> bool:
	var tooltip := button.tooltip_text.to_lower()
	if tooltip.contains("sort"):
		return true
	var has_name := false
	var has_modified := false
	for index in range(popup.item_count):
		var item_text := popup.get_item_text(index).to_lower()
		has_name = has_name or item_text.contains("name")
		has_modified = has_modified or item_text.contains("modified") or item_text.contains("date")
	return has_name and has_modified


func _normalise_path_list_v01510(raw_values: Variant, limit: int) -> Array:
	var result: Array = []
	if raw_values is Array or raw_values is PackedStringArray:
		for raw_value in raw_values:
			var value := str(raw_value).strip_edges()
			if value.is_empty() or value in result:
				continue
			if value.begins_with("res://") or value.begins_with("user://") or DirAccess.dir_exists_absolute(value):
				result.append(value)
			if limit > 0 and result.size() >= limit:
				break
	return result


func _packed_to_array_v01510(values: PackedStringArray) -> Array:
	var result: Array = []
	for value in values:
		result.append(str(value))
	return result
