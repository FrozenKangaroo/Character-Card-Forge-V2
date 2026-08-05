class_name CCFWorkspaceV01536Hotfix3View
extends "res://scripts/ui/workspace_v01536_hotfix2.gd"

const PROJECT_PERSISTENCE_V01536_HOTFIX3 = preload(
	"res://scripts/services/project_persistence_service_v01536_hotfix3.gd"
)


func save_project() -> void:
	if _project_container.is_empty():
		return
	_commit_active_character_to_container()
	_capture_project_name()
	var result := PROJECT_PERSISTENCE_V01536_HOTFIX3.save_if_meaningful(
		_project_container,
		_template
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not save project."))
		return
	if bool(result.get("skipped_empty", false)):
		_dirty = false
		_populate_project_controls()
		_status.text = (
			"Nothing to save yet. Empty projects stay in Workspace and are not added to the Library."
		)
		_update_header()
		return
	_dirty = false
	_populate_project_controls()
	_status.text = "Saved at %s" % Time.get_time_string_from_system()
	_update_header()
	project_saved.emit(_project_container.duplicate(true))


func project_persistence_capabilities_v01536_hotfix3() -> Dictionary:
	return PROJECT_PERSISTENCE_V01536_HOTFIX3.capabilities()
