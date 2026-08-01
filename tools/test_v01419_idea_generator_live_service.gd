extends SceneTree

class FakeLegacyIdeaWindow extends Window:
	var received_service: Node

	func set_generation_service(service: Node) -> void:
		received_service = service


func _init() -> void:
	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01419.gd")
	for required_text in [
		"_wire_ai_idea_controller_to_current_service",
		"set_generation_service",
		"_finish_opening_unified_idea_generator",
		"super._finish_opening_unified_idea_generator()",
		"_find_legacy_ai_idea_window"
	]:
		assert(workspace_source.contains(required_text), "v0.14.19 live Idea Generator wiring is missing %s." % required_text)

	var workspace := CCFWorkspaceV01419View.new()
	var service := CCFGenerationServiceV01418.new()
	var legacy := FakeLegacyIdeaWindow.new()
	legacy.title = "Idea Generator"
	workspace.add_child(legacy)
	workspace._generation_service = service
	workspace._wire_ai_idea_controller_to_current_service()
	assert(legacy.received_service == service, "Embedded AI Ideas controller must receive the workspace's live generation service.")

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01419.gd")
	assert(main_source.contains("extends \"res://scripts/main_v01418.gd\""), "v0.14.19 must retain the v0.14.18 user-centric contract.")
	var scene := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(scene.contains("main_v01419.gd"), "Main scene must use the v0.14.19 shell.")

	workspace.remove_child(legacy)
	legacy.free()
	service.free()
	workspace.free()
	print("v0.14.19 live Idea Generator service regression passed")
	quit(0)
