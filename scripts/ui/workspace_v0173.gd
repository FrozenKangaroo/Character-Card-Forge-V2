class_name CCFWorkspaceV0173View
extends "res://scripts/ui/workspace_v0172.gd"

const IMPORT_EXPORT_WINDOW_V0173 = preload(
	"res://scripts/ui/import_export_window_v0173.gd"
)


func _build_import_export_window() -> void:
	_import_export_window = IMPORT_EXPORT_WINDOW_V0173.new()
	_import_export_window.visible = false
	_import_export_window.project_refresh_requested.connect(
		_refresh_import_export_project_context
	)
	_import_export_window.project_imported.connect(_on_external_project_imported)
	add_child(_import_export_window)
	_import_export_window.hide()


func front_porch_direct_install_capabilities_v0173() -> Dictionary:
	if (
		_import_export_window != null
		and _import_export_window.has_method(
			"front_porch_install_capabilities_v0173"
		)
	):
		return _import_export_window.call(
			"front_porch_install_capabilities_v0173"
		) as Dictionary
	return {
		"install_tab": false,
		"raw_database_writes": false,
		"portable_json_fallback": true
	}
