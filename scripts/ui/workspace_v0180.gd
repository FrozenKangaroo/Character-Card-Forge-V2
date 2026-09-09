class_name CCFWorkspaceV0180View
extends CCFWorkspaceV0175View

const IMPORT_EXPORT_WINDOW_V0180 = preload(
	"res://scripts/ui/import_export_window_v0180.gd"
)


func _build_import_export_window() -> void:
	_import_export_window = IMPORT_EXPORT_WINDOW_V0180.new()
	_import_export_window.visible = false
	_import_export_window.project_refresh_requested.connect(
		_refresh_import_export_project_context
	)
	_import_export_window.project_imported.connect(_on_external_project_imported)
	_import_export_window.gallery_project_changed_v0175.connect(
		_on_front_porch_gallery_project_changed_v0175
	)
	_import_export_window.world_project_changed_v0180.connect(
		_on_front_porch_world_project_changed_v0180
	)
	add_child(_import_export_window)
	_import_export_window.hide()


func _on_front_porch_world_project_changed_v0180(
	updated_project: Dictionary
) -> void:
	if (
		str(updated_project.get("project_id", ""))
		!= str(_project_container.get("project_id", ""))
	):
		return
	_project_container = updated_project.duplicate(true)
	_project = CCFStorageService.character_workspace_document(
		_project_container, _active_character_id
	)
	_dirty = false
	_update_header()
	_update_project_level_window_contexts()
	project_saved.emit(_project_container.duplicate(true))
	_status.text = "Front Porch World Studio updated and saved."


func front_porch_world_capabilities_v0180() -> Dictionary:
	if (
		_import_export_window != null
		and _import_export_window.has_method(
			"front_porch_world_capabilities_v0180"
		)
	):
		return _import_export_window.call(
			"front_porch_world_capabilities_v0180"
		) as Dictionary
	return {
		"lossless_unknown_fields": false,
		"stoop_metadata": false,
		"direct_stoop_publish": false,
		"network_calls": false,
		"raw_database_writes": false
	}
