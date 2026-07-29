class_name CCFImportExportWindowV0135
extends CCFImportExportWindow


func _request_png_source() -> void:
	project_refresh_requested.emit()
	_pending_png_source = _active_portrait_source_path()
	if not _pending_png_source.is_empty():
		_png_save_dialog.current_file = CCFCardFormatService.suggested_filename(
			_project, _active_character_id, "png"
		)
		_status.text = "Using the active character portrait as the PNG card artwork. Choose where to save the exported card."
		_png_save_dialog.popup_centered_ratio(0.72)
		return
	_status.text = "This character has no available portrait. Choose a PNG image to use as the card artwork."
	_png_source_dialog.popup_centered_ratio(0.72)


func _active_portrait_source_path() -> String:
	if _project.is_empty() or _active_character_id.is_empty():
		return ""
	var character := CCFStorageService.get_character(_project, _active_character_id)
	if character.is_empty():
		return ""
	var assets = character.get("assets", {})
	if not assets is Dictionary:
		return ""
	var portrait_path := str(assets.get("portrait", "")).strip_edges()
	if portrait_path.is_empty():
		return ""
	var resolved_path := portrait_path
	if not portrait_path.begins_with("user://") and not portrait_path.is_absolute_path():
		resolved_path = CCFStorageService.project_folder(
			str(_project.get("project_id", ""))
		).path_join(portrait_path)
	if not FileAccess.file_exists(resolved_path):
		return ""
	return resolved_path
