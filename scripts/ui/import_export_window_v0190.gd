class_name CCFImportExportWindowV0190
extends "res://scripts/ui/import_export_window_v0185.gd"

const AUTHORING_SERVICE = preload(
	"res://scripts/services/rich_authoring_service_v0190.gd"
)


func _remove_world_v0180() -> void:
	var world_id := str(_world_record_v0180.get("world_id", ""))
	if world_id.is_empty():
		return
	var warnings := AUTHORING_SERVICE.deletion_warnings(
		_project, "world", world_id
	)
	if not warnings.is_empty():
		_status.text = (
			"This world is still referenced and was not removed. Unlink it first: %s"
			% " ".join(warnings)
		)
		return
	super._remove_world_v0180()
