class_name CCFSettingsV0200View
extends "res://scripts/ui/settings_view_v0195.gd"

const PORTABLE_LIBRARY_SERVICE_V0200 = preload(
	"res://scripts/services/portable_library_service_v0200.gd"
)
const LIBRARY_CACHE_SERVICE_V0200 = preload(
	"res://scripts/services/library_cache_service_v0200.gd"
)

var _portable_path_v0200: LineEdit
var _active_library_v0200: Label
var _library_status_v0200: Label
var _thumbnail_limit_v0200: SpinBox
var _thumbnail_age_v0200: SpinBox
var _virtual_buffer_v0200: SpinBox
var _library_folder_dialog_v0200: FileDialog


func _ready() -> void:
	super._ready()
	_build_library_storage_tab_v0200()
	_load_library_storage_v0200()


func load_settings(settings: Dictionary) -> void:
	super.load_settings(settings)
	_load_library_storage_v0200()


func _build_library_storage_tab_v0200() -> void:
	var parent := _make_scroll_tab("Library Storage")
	var heading := Label.new()
	heading.text = "Library storage and large-library performance"
	heading.add_theme_font_size_override("font_size", 20)
	parent.add_child(heading)

	var explanation := Label.new()
	explanation.text = (
		"The normal local library remains the default. You may explicitly select a "
		+ "portable or shared-folder library; projects stay there while disposable "
		+ "indexes and optimized thumbnails remain on this computer."
	)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.modulate = Color(0.68, 0.72, 0.82)
	parent.add_child(explanation)

	_active_library_v0200 = Label.new()
	_active_library_v0200.name = "ActiveLibraryLocationV0200"
	_active_library_v0200.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(_active_library_v0200)

	var location_row := HBoxContainer.new()
	location_row.add_theme_constant_override("separation", 8)
	parent.add_child(location_row)
	_portable_path_v0200 = LineEdit.new()
	_portable_path_v0200.name = "PortableLibraryPathV0200"
	_portable_path_v0200.placeholder_text = "/path/to/Character Card Forge Library"
	_portable_path_v0200.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	location_row.add_child(_portable_path_v0200)
	var browse_button := Button.new()
	browse_button.text = "Choose Folder…"
	browse_button.pressed.connect(_browse_portable_library_v0200)
	location_row.add_child(browse_button)
	var inspect_button := Button.new()
	inspect_button.text = "Check Folder"
	inspect_button.pressed.connect(_inspect_portable_library_v0200)
	location_row.add_child(inspect_button)

	var location_actions := HBoxContainer.new()
	location_actions.add_theme_constant_override("separation", 10)
	parent.add_child(location_actions)
	var use_portable_button := Button.new()
	use_portable_button.name = "UsePortableLibraryV0200"
	use_portable_button.text = "Initialize / Use Selected Library"
	use_portable_button.pressed.connect(_activate_portable_library_v0200)
	location_actions.add_child(use_portable_button)
	var use_local_button := Button.new()
	use_local_button.name = "UseLocalLibraryV0200"
	use_local_button.text = "Return to Local Library"
	use_local_button.pressed.connect(_activate_local_library_v0200)
	location_actions.add_child(use_local_button)
	var open_button := Button.new()
	open_button.text = "Open Active Library Folder"
	open_button.pressed.connect(_open_active_library_v0200)
	location_actions.add_child(open_button)

	var safety := Label.new()
	safety.text = (
		"Switching locations never moves, merges or deletes projects. Reopen an already "
		+ "open project after switching. Shared folders use cooperative save locks and "
		+ "external-change checks, but remain single-writer: this is not multi-user editing "
		+ "or automatic cloud sync. If a share disappears, CCF refuses writes and does not "
		+ "silently open the local library instead."
	)
	safety.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	safety.modulate = Color(0.88, 0.69, 0.48)
	parent.add_child(safety)

	_library_status_v0200 = Label.new()
	_library_status_v0200.name = "LibraryStorageStatusV0200"
	_library_status_v0200.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_library_status_v0200.modulate = Color(0.7, 0.82, 0.72)
	parent.add_child(_library_status_v0200)

	parent.add_child(HSeparator.new())
	var cache_heading := Label.new()
	cache_heading.text = "Local thumbnail cache"
	cache_heading.add_theme_font_size_override("font_size", 18)
	parent.add_child(cache_heading)
	var cache_hint := Label.new()
	cache_hint.text = (
		"Visible cards use optimized local derivatives. Age and size limits clean only "
		+ "disposable cache files; original artwork is never removed."
	)
	cache_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cache_hint.modulate = Color(0.68, 0.72, 0.82)
	parent.add_child(cache_hint)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	parent.add_child(grid)
	grid.add_child(_label("Maximum cache size"))
	_thumbnail_limit_v0200 = SpinBox.new()
	_thumbnail_limit_v0200.min_value = 64
	_thumbnail_limit_v0200.max_value = 4096
	_thumbnail_limit_v0200.step = 64
	_thumbnail_limit_v0200.suffix = " MB"
	_thumbnail_limit_v0200.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(_thumbnail_limit_v0200)
	grid.add_child(_label("Remove unused thumbnails after"))
	_thumbnail_age_v0200 = SpinBox.new()
	_thumbnail_age_v0200.min_value = 7
	_thumbnail_age_v0200.max_value = 3650
	_thumbnail_age_v0200.step = 1
	_thumbnail_age_v0200.suffix = " days"
	_thumbnail_age_v0200.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(_thumbnail_age_v0200)
	grid.add_child(_label("Preload rows around the visible grid"))
	_virtual_buffer_v0200 = SpinBox.new()
	_virtual_buffer_v0200.min_value = 1
	_virtual_buffer_v0200.max_value = 8
	_virtual_buffer_v0200.step = 1
	_virtual_buffer_v0200.suffix = " rows"
	_virtual_buffer_v0200.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(_virtual_buffer_v0200)

	var cache_actions := HBoxContainer.new()
	cache_actions.add_theme_constant_override("separation", 10)
	parent.add_child(cache_actions)
	var save_cache_button := Button.new()
	save_cache_button.text = "Save Performance Limits"
	save_cache_button.pressed.connect(_save_library_limits_v0200)
	cache_actions.add_child(save_cache_button)
	var clean_cache_button := Button.new()
	clean_cache_button.name = "ClearThumbnailCacheV0200"
	clean_cache_button.text = "Clear Disposable Thumbnail Cache"
	clean_cache_button.pressed.connect(_clear_thumbnail_cache_v0200)
	cache_actions.add_child(clean_cache_button)

	_library_folder_dialog_v0200 = FileDialog.new()
	_library_folder_dialog_v0200.title = "Choose a portable Character Card Forge library folder"
	_library_folder_dialog_v0200.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	_library_folder_dialog_v0200.access = FileDialog.ACCESS_FILESYSTEM
	_library_folder_dialog_v0200.use_native_dialog = true
	_library_folder_dialog_v0200.dir_selected.connect(_on_library_folder_selected_v0200)
	add_child(_library_folder_dialog_v0200)


func _load_library_storage_v0200() -> void:
	if _portable_path_v0200 == null:
		return
	var storage_value: Variant = _settings.get("library_storage", {})
	var storage: Dictionary = storage_value if storage_value is Dictionary else {}
	_portable_path_v0200.text = str(storage.get("portable_root", ""))
	_thumbnail_limit_v0200.value = int(storage.get("thumbnail_cache_max_mb", 512))
	_thumbnail_age_v0200.value = int(storage.get("thumbnail_cache_max_age_days", 90))
	_virtual_buffer_v0200.value = int(storage.get("virtualization_buffer_rows", 2))
	_refresh_active_library_status_v0200()


func _browse_portable_library_v0200() -> void:
	if _library_folder_dialog_v0200 == null:
		return
	var requested := _portable_path_v0200.text.strip_edges()
	if not requested.is_empty() and requested.is_absolute_path():
		_library_folder_dialog_v0200.current_dir = requested
	_library_folder_dialog_v0200.popup_centered_ratio(0.72)


func _on_library_folder_selected_v0200(path: String) -> void:
	_portable_path_v0200.text = path
	_inspect_portable_library_v0200()


func _inspect_portable_library_v0200() -> void:
	var result := PORTABLE_LIBRARY_SERVICE_V0200.inspect_location_v0200(
		_portable_path_v0200.text
	)
	_library_status_v0200.text = str(
		result.get("message", result.get("error", "Could not inspect the folder."))
	)
	_library_status_v0200.modulate = (
		Color(0.7, 0.82, 0.72)
		if bool(result.get("ok", false))
		else Color(1.0, 0.55, 0.48)
	)


func _activate_portable_library_v0200() -> void:
	var storage: Dictionary = _settings.get("library_storage", {})
	var prepared := PORTABLE_LIBRARY_SERVICE_V0200.prepare_location_v0200(
		_portable_path_v0200.text, str(storage.get("writer_id", ""))
	)
	if not bool(prepared.get("ok", false)):
		_library_status_v0200.text = str(prepared.get("error", "Could not use this library."))
		_library_status_v0200.modulate = Color(1.0, 0.55, 0.48)
		return
	var updated := PORTABLE_LIBRARY_SERVICE_V0200.settings_for_portable_v0200(
		_settings, str(prepared.get("root", _portable_path_v0200.text))
	)
	var save_result := CCFSettingsService.save_settings(updated)
	if not bool(save_result.get("ok", false)):
		_library_status_v0200.text = str(save_result.get("error", "Could not save the library location."))
		return
	_settings = CCFSettingsService.load_settings()
	_refresh_active_library_status_v0200()
	_library_status_v0200.text = str(prepared.get("message", "Portable library selected."))
	settings_saved.emit(_settings.duplicate(true))


func _activate_local_library_v0200() -> void:
	var updated := PORTABLE_LIBRARY_SERVICE_V0200.settings_for_local_v0200(_settings)
	var save_result := CCFSettingsService.save_settings(updated)
	if not bool(save_result.get("ok", false)):
		_library_status_v0200.text = str(save_result.get("error", "Could not select the local library."))
		return
	_settings = CCFSettingsService.load_settings()
	_refresh_active_library_status_v0200()
	_library_status_v0200.text = "Local library selected. Portable files were not moved or deleted."
	settings_saved.emit(_settings.duplicate(true))


func _save_library_limits_v0200() -> void:
	var storage: Dictionary = _settings.get("library_storage", {}).duplicate(true)
	storage["thumbnail_cache_max_mb"] = int(_thumbnail_limit_v0200.value)
	storage["thumbnail_cache_max_age_days"] = int(_thumbnail_age_v0200.value)
	storage["virtualization_buffer_rows"] = int(_virtual_buffer_v0200.value)
	_settings["library_storage"] = storage
	var save_result := CCFSettingsService.save_settings(_settings)
	if not bool(save_result.get("ok", false)):
		_library_status_v0200.text = str(save_result.get("error", "Could not save performance limits."))
		return
	_settings = CCFSettingsService.load_settings()
	var maintenance := LIBRARY_CACHE_SERVICE_V0200.maintain_v0200(_settings)
	_library_status_v0200.text = (
		"Performance limits saved. Cache now contains %d optimized file%s."
		% [
			int(maintenance.get("entries", 0)),
			"" if int(maintenance.get("entries", 0)) == 1 else "s"
		]
	)
	settings_saved.emit(_settings.duplicate(true))


func _clear_thumbnail_cache_v0200() -> void:
	var result := LIBRARY_CACHE_SERVICE_V0200.clear_v0200()
	_library_status_v0200.text = (
		"Cleared %d disposable cache file%s. Original artwork was preserved."
		% [
			int(result.get("removed", 0)),
			"" if int(result.get("removed", 0)) == 1 else "s"
		]
		if bool(result.get("ok", false))
		else str(result.get("error", "Could not clear the thumbnail cache."))
	)


func _open_active_library_v0200() -> void:
	var status := CCFStorageService.library_storage_status_v0200()
	if not bool(status.get("available", false)):
		_library_status_v0200.text = "The active library folder is unavailable."
		return
	OS.shell_open(str(status.get("absolute_root", "")))


func _refresh_active_library_status_v0200() -> void:
	if _active_library_v0200 == null:
		return
	var status := CCFStorageService.library_storage_status_v0200()
	var mode_label := "Portable/shared" if str(status.get("mode", "local")) == "portable" else "Local"
	_active_library_v0200.text = "Active library: %s\n%s" % [
		mode_label, str(status.get("absolute_root", ""))
	]
	if not bool(status.get("available", false)):
		_active_library_v0200.text += "\nUnavailable — no fallback library will be opened."
		_active_library_v0200.modulate = Color(1.0, 0.55, 0.48)
	else:
		_active_library_v0200.modulate = Color(0.7, 0.82, 0.72)


func library_settings_capabilities_v0200() -> Dictionary:
	return PORTABLE_LIBRARY_SERVICE_V0200.capabilities_v0200()
