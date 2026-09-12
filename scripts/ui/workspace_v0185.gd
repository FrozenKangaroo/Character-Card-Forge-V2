class_name CCFWorkspaceV0185View
extends "res://scripts/ui/workspace_v0183.gd"

const IMPORT_EXPORT_WINDOW_V0185 = preload(
	"res://scripts/ui/import_export_window_v0185.gd"
)


func _build_import_export_window() -> void:
	_import_export_window = IMPORT_EXPORT_WINDOW_V0185.new()
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
	_import_export_window.inspection_project_changed_v0182.connect(
		_on_inspection_project_changed_v0182
	)
	_import_export_window.front_porch_sync_project_changed_v0185.connect(
		_on_front_porch_sync_project_changed_v0185
	)
	add_child(_import_export_window)
	_import_export_window.hide()


func _on_front_porch_sync_project_changed_v0185(
	updated_project: Dictionary,
	active_character_id: String,
	message_text: String
) -> void:
	_on_inspection_project_changed_v0182(
		updated_project, active_character_id, message_text
	)


func front_porch_workspace_capabilities_v0185() -> Dictionary:
	return {
		"sync_window": _import_export_window is CCFImportExportWindowV0185,
		"sync_changes_use_normal_project_save": true
	}
