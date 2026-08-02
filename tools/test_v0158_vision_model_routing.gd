extends SceneTree


func _init() -> void:
	var service_source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v0158.gd")
	assert(service_source.contains("profile.get(\"vision_model\""), "v0.15.8 must read the dedicated Vision model field.")
	assert(service_source.contains("routed_profile[\"model\"] = vision_model"), "Vision requests must route _queue_chat_job's model field to vision_model.")
	assert(service_source.contains("profile.duplicate(true)"), "Vision routing must not mutate the stored AI profile used by Text generation.")
	assert(service_source.contains("does not have a Vision model configured"), "Missing Vision models must fail clearly rather than falling back to the Text model.")
	assert(service_source.contains("super.queue_collaborator_vision_summary"), "v0.15.8 must preserve the full-scene Vision pipeline from v0.15.7.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v0158.gd")
	assert(workspace_source.contains("GENERATION_SERVICE_V0158"), "Workspace must install the v0.15.8 routing service.")
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(scene_source.contains("main_v0158.gd"), "The active scene must use v0.15.8.")

	print("v0.15.8 Vision model routing regression passed")
	quit(0)
