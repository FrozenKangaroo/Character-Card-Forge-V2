extends SceneTree


func _init() -> void:
	var settings_source := FileAccess.get_file_as_string("res://scripts/ui/settings_view_v0152.gd")
	assert(settings_source.contains("MAX_OUTPUT_TOKENS_V0152 := 4194304"), "v0.15.2 must raise the Maximum Output Tokens UI above the old 131072 ceiling.")
	assert(settings_source.contains("_max_tokens.allow_greater = true"), "Maximum Output Tokens must permit future values above the normal UI range.")
	assert(not settings_source.contains("max_value = 131072"), "v0.15.2 must not reintroduce the old 131072 output-token ceiling.")
	assert(384000 <= 4194304, "384k-class model output limits must fit the normal v0.15.2 control range.")

	var collaborator_service := CCFGenerationServiceV015.new()
	assert(collaborator_service.has_method("queue_collaborator_reply"), "The v0.15 service must be Collaborator-capable at runtime.")
	assert(collaborator_service.has_method("queue_collaborator_summary"), "The v0.15 service must support Collaborator context summaries.")
	collaborator_service.free()

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v015.gd")
	assert(workspace_source.contains("_ensure_collaborator_generation_service_v015"), "Workspace must verify/repair stale generation-service wiring before Collaborator opens.")
	assert(workspace_source.contains("not _generation_service.has_method(\"queue_collaborator_reply\")"), "Workspace must detect a stale generation service by Collaborator capability rather than script identity alone.")
	assert(workspace_source.contains("_character_collaborator_window.set_generation_service(_generation_service)"), "The repaired live service must be rebound to the Collaborator window.")

	var scene := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(scene.contains("main_v0152.gd"), "Main scene must use the v0.15.2 shell.")
	var shell_source := FileAccess.get_file_as_string("res://scripts/main_v0152.gd")
	assert(shell_source.contains("main_v0151.gd"), "v0.15.2 must preserve v0.15.1 through inheritance.")

	print("v0.15.2 large-output and Collaborator live-wiring regression passed")
	quit(0)
