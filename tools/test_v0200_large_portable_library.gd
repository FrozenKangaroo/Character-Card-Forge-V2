extends SceneTree

const PORTABLE_LIBRARY_SERVICE = preload(
	"res://scripts/services/portable_library_service_v0200.gd"
)
const CACHE_SERVICE = preload(
	"res://scripts/services/library_cache_service_v0200.gd"
)


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0200_LARGE_LIBRARY_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _portable_settings(root_path: String, writer_id: String = "writer-test") -> Dictionary:
	var settings := CCFSettingsService.default_settings()
	var storage: Dictionary = settings.get("library_storage", {}).duplicate(true)
	storage["mode"] = "portable"
	storage["portable_root"] = root_path
	storage["writer_id"] = writer_id
	storage["virtualization_buffer_rows"] = 2
	settings["library_storage"] = storage
	return settings


func _write_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "  "))
	file.flush()
	file.close()
	return true


func _row(index: int) -> Dictionary:
	return {
		"project_id": "virtual-%04d" % index,
		"name": "Virtual Project %04d" % index,
		"summary": "A generated row used to prove bounded card-node creation.",
		"thumbnail_path": "",
		"character_count": 1,
		"character_names": ["Character %04d" % index],
		"workflow_state": "draft",
		"favorite": false,
		"archived": false,
		"sensitive": false,
		"series_name": "",
		"folder": "",
		"collections": [],
		"all_tags": [],
		"front_porch_sync_states_v0185": [],
		"front_porch_deployment_queued_v0185": false
	}


func _run() -> void:
	var defaults := CCFSettingsService.default_settings()
	var default_storage: Dictionary = defaults.get("library_storage", {})
	if not _require(
		int(defaults.get("format_version", 0)) == 9
		and str(default_storage.get("mode", "")) == "local"
		and int(default_storage.get("thumbnail_cache_max_mb", 0)) == 512
		and int(default_storage.get("thumbnail_cache_max_age_days", 0)) == 90,
		"v0.20.0 settings must preserve the local default and bounded cache policy."
	):
		return

	var capabilities := PORTABLE_LIBRARY_SERVICE.capabilities_v0200()
	if not _require(
		bool(capabilities.get("optional_portable_location", false))
		and bool(capabilities.get("local_indexes_and_thumbnails", false))
		and bool(capabilities.get("cooperative_single_writer_lock", false))
		and bool(capabilities.get("atomic_project_json_replace", false))
		and bool(capabilities.get("external_change_conflicts", false))
		and bool(capabilities.get("unavailable_share_never_falls_back", false))
		and not bool(capabilities.get("automatic_cloud_sync", true))
		and not bool(capabilities.get("collaborative_multi_user_editing", true)),
		"The portable-library contract must describe its exact safety boundary."
	):
		return

	var test_root := "/tmp/ccf-v0200-library-%d" % int(Time.get_ticks_usec())
	var prepared := PORTABLE_LIBRARY_SERVICE.prepare_location_v0200(
		test_root, "writer-test"
	)
	if not _require(
		bool(prepared.get("ok", false))
		and bool(prepared.get("initialized", false))
		and FileAccess.file_exists(test_root.path_join(".ccf-library.json"))
		and DirAccess.dir_exists_absolute(test_root.path_join("characters")),
		"An explicit action must initialize a versioned portable library and characters folder."
	):
		return
	var inspection := PORTABLE_LIBRARY_SERVICE.inspect_location_v0200(test_root)
	if not _require(
		bool(inspection.get("ok", false))
		and bool(inspection.get("available", false))
		and bool(inspection.get("initialized", false))
		and not str(inspection.get("library_id", "")).is_empty(),
		"Initialized portable libraries must be inspectable without changing active storage."
	):
		return

	var portable_settings := _portable_settings(test_root)
	CCFStorageService.configure_library_storage_v0200(portable_settings)
	var project := CCFStorageService.new_project()
	var project_id := str(project.get("project_id", ""))
	var saved := CCFStorageService.save_project(project)
	var project_path := test_root.path_join("characters").path_join(
		project_id
	).path_join(CCFStorageService.PROJECT_FILE)
	if not _require(
		bool(saved.get("ok", false))
		and FileAccess.file_exists(project_path)
		and not FileAccess.file_exists(project_path + ".ccf-previous")
		and not FileAccess.file_exists(test_root.path_join(".ccf-library.lock")),
		"Portable project saves must finalize safely and release their cooperative lock."
	):
		return

	var loaded_result := CCFStorageService.load_project(project_id)
	var loaded: Dictionary = loaded_result.get("data", {})
	var external_file := FileAccess.open(project_path, FileAccess.READ)
	var external_data: Dictionary = JSON.parse_string(external_file.get_as_text())
	external_file.close()
	var external_metadata: Dictionary = external_data.get("metadata", {}).duplicate(true)
	external_metadata["summary"] = "Changed by another writer"
	external_data["metadata"] = external_metadata
	if not _require(
		_write_json(project_path, external_data),
		"The conflict fixture must be able to simulate an external writer."
	):
		return
	var loaded_metadata: Dictionary = loaded.get("metadata", {}).duplicate(true)
	loaded_metadata["summary"] = "Our stale edit"
	loaded["metadata"] = loaded_metadata
	var conflict := CCFStorageService.save_project(loaded)
	if not _require(
		not bool(conflict.get("ok", true)) and bool(conflict.get("conflict", false)),
		"A changed on-disk project must be rejected instead of silently overwritten."
	):
		return

	var origin_project := CCFStorageService.new_project()
	var origin_save := CCFStorageService.save_project(origin_project)
	var origin_id := str(origin_project.get("project_id", ""))
	var origin_loaded := CCFStorageService.load_project(origin_id).get("data", {}) as Dictionary
	CCFStorageService.configure_library_storage_v0200(defaults)
	var wrong_origin_save := CCFStorageService.save_project(origin_loaded)
	if not _require(
		bool(origin_save.get("ok", false))
		and not bool(wrong_origin_save.get("ok", true))
		and bool(wrong_origin_save.get("storage_origin_changed", false)),
		"An open project must not be copied into a newly selected library by a later save."
	):
		return

	var unavailable_root := test_root + "-not-mounted"
	CCFStorageService.configure_library_storage_v0200(
		_portable_settings(unavailable_root)
	)
	var unavailable_status := CCFStorageService.library_storage_status_v0200()
	var unavailable_index := CCFLibraryService.refresh_index(false)
	if not _require(
		not bool(unavailable_status.get("available", true))
		and not bool(unavailable_index.get("ok", true))
		and bool(unavailable_index.get("library_unavailable", false))
		and not DirAccess.dir_exists_absolute(unavailable_root),
		"An unavailable share must remain unavailable and must never fall back to local projects."
	):
		return

	CCFStorageService.configure_library_storage_v0200(portable_settings)
	var future := int(Time.get_unix_time_from_system()) + 120
	if not _require(
		_write_json(
			test_root.path_join(".ccf-library.lock"),
			{
				"format_version": 1,
				"writer_id": "another-writer",
				"expires_at_unix": future
			}
		),
		"The lock fixture must be writable."
	):
		return
	var locked_save := CCFStorageService.save_project(CCFStorageService.new_project())
	if not _require(
		not bool(locked_save.get("ok", true))
		and bool(locked_save.get("library_locked", false)),
		"A live lock from another writer must block a portable-library save."
	):
		return
	DirAccess.remove_absolute(test_root.path_join(".ccf-library.lock"))

	CCFStorageService.configure_library_storage_v0200(defaults)
	var view := CCFLibraryV0200View.new()
	view.size = Vector2(1280, 720)
	root.add_child(view)
	await process_frame
	await process_frame
	var rows: Array[Dictionary] = []
	for row_index in range(1000):
		rows.append(_row(row_index))
	view.set("_filtered", rows)
	view.call("_update_grid_columns")
	view.call("_rebuild_grid")
	await process_frame
	await process_frame
	var virtual_capabilities := view.large_library_capabilities_v0200()
	var rendered := int(virtual_capabilities.get("rendered_card_count", 0))
	var grid := view.get("_grid") as GridContainer
	var bottom_spacer := view.find_child("VirtualBottomSpacerV0200", true, false) as Control
	if not _require(
		bool(virtual_capabilities.get("virtualized_grid", false))
		and rendered > 0
		and rendered < 100
		and grid != null
		and grid.get_child_count() == rendered
		and bottom_spacer != null
		and bottom_spacer.custom_minimum_size.y > 0.0,
		"A thousand-row library must instantiate only the visible and nearby card window."
	):
		return

	var settings_view := CCFSettingsV0200View.new()
	root.add_child(settings_view)
	await process_frame
	var settings_capabilities := settings_view.library_settings_capabilities_v0200()
	if not _require(
		settings_view.find_child("PortableLibraryPathV0200", true, false) != null
		and settings_view.find_child("UsePortableLibraryV0200", true, false) != null
		and settings_view.find_child("ClearThumbnailCacheV0200", true, false) != null
		and bool(settings_capabilities.get("local_indexes_and_thumbnails", false)),
		"Library Storage settings must expose explicit location and safe cache controls."
	):
		return

	var cache_result := CACHE_SERVICE.maintain_v0200(defaults)
	if not _require(
		bool(cache_result.get("ok", false))
		and bool(cache_result.get("local_only", false))
		and bool(cache_result.get("originals_preserved", false)),
		"Thumbnail maintenance must be bounded, local-only and preserve originals."
	):
		return

	print("V0200_LARGE_LIBRARY_OK")
	view.queue_free()
	settings_view.queue_free()
	await process_frame
	quit(0)
