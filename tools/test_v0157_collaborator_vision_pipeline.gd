extends SceneTree


func _init() -> void:
	var service_source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v0157.gd")
	assert(service_source.contains("queue_collaborator_vision_summary"), "v0.15.7 must override Collaborator Vision analysis.")
	assert(service_source.contains("image_url"), "Vision analysis must send the original image only to the multimodal Vision request.")
	assert(service_source.contains("ENTIRE visible image"), "Vision analysis must describe the entire scene, not only physical appearance.")
	assert(service_source.contains("setting/environment"), "Vision analysis must include scene setting/environment.")
	assert(service_source.contains("readable or partially readable text"), "Vision analysis must include visible text when legible.")
	assert(service_source.contains("apparent action/event/situation"), "Vision analysis must describe what appears to be happening in the scene.")
	assert(service_source.contains("CCFSettingsService.ROLE_VISION"), "Vision job metadata must identify the Vision role.")
	assert(service_source.contains("vision_description_of_user_attached_image"), "Vision output must carry explicit provenance.")

	var window_source := FileAccess.get_file_as_string("res://scripts/ui/character_collaborator_window_v0157.gd")
	assert(window_source.contains("profile_for_role(_settings, CCFSettingsService.ROLE_VISION)"), "The image caller must resolve the configured Vision profile, not the Text profile.")
	assert(window_source.contains("VISION DESCRIPTION OF USER-ATTACHED IMAGE"), "The Text model context must explicitly identify Vision-derived image description.")
	assert(window_source.contains("does NOT receive the image itself"), "The Text-model handoff must state that it receives description rather than image data.")
	assert(window_source.contains("vision_description"), "Raw Vision description must be retained separately in context metadata.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v0157.gd")
	assert(workspace_source.contains("GENERATION_SERVICE_V0157"), "Workspace must install the v0.15.7 Vision-capable service.")
	assert(workspace_source.contains("CHARACTER_COLLABORATOR_WINDOW_V0157"), "Workspace must install the v0.15.7 Collaborator window.")
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(scene_source.contains("main_v0157.gd"), "The active scene must use v0.15.7.")

	print("v0.15.7 Collaborator Vision pipeline regression passed")
	quit(0)
