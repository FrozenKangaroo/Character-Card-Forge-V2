extends SceneTree


func _init() -> void:
	var service := FileAccess.get_file_as_string("res://scripts/services/generation_service_v01413.gd")
	assert(service.contains("POINT-OF-VIEW CONTRACT"), "Idea Generator POV contract is missing.")
	assert(service.contains("neutral third person"), "Idea concepts must require neutral third person.")
	assert(service.contains("Never write 'You are <character name>'"), "Second-person generated-character prohibition is missing.")
	assert(service.contains("{{user}} always means the eventual chat user"), "{{user}} role guidance is missing.")
	assert(service.contains("Do not give {{user}} a name"), "User identity protection is missing.")
	assert(service.contains("concept_point_of_view"), "Idea job metadata must record the POV contract.")
	var workspace := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01413.gd")
	assert(workspace.contains("GENERATION_SERVICE_V01413"), "v0.14.13 generation service is not installed.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01413.gd")
	assert(main_source.contains("WORKSPACE_V01413"), "v0.14.13 workspace is not installed.")
	var scene := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(scene.contains("main_v01413.gd"), "Main scene must use the v0.14.13 shell.")
	print("v0.14.13 Idea Generator point-of-view regression passed")
	quit(0)
