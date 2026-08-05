extends "res://scripts/ui/workspace_v01535.gd"


func load_project(project: Dictionary, template: Dictionary, settings: Dictionary) -> void:
	var incoming_project_id := str(project.get("project_id", "")).strip_edges()
	if (
		not _pending_completion_project_id_v01535.is_empty()
		and incoming_project_id != _pending_completion_project_id_v01535
	):
		_clear_pending_completion_v01535()
		if (
			_completion_destination_window_v01535 != null
			and _completion_destination_window_v01535.visible
		):
			_completion_destination_window_v01535.hide()
	super.load_project(project, template, settings)
