extends SceneTree


func _init() -> void:
	var service_source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v01512.gd")
	assert(service_source.contains("queue_full_character_synthesis"), "v0.15.12 needs a dedicated full Workspace synthesis path.")
	assert(service_source.contains("template.get(\"sections\", [])"), "Full synthesis must read all template Workspace fields as source material.")
	assert(service_source.contains("CCFTemplateService.generation_fields(template)"), "The active template must remain the generated output contract.")
	assert(service_source.contains("populated Workspace fields as authoritative source material"), "Populated fields must be treated as source/canon rather than skipped.")
	assert(service_source.contains("Do not omit an output merely because the Workspace already contains a value"), "Full synthesis must regenerate template output even when fields are already filled.")
	assert(service_source.contains("\"generation_scope\": \"full_workspace_synthesis\""), "Full synthesis jobs need explicit scope metadata.")
	assert(service_source.contains("\"preserve_existing_facts\": true"), "Full synthesis must preserve established facts by default.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01512.gd")
	assert(workspace_source.contains("GENERATION_SERVICE_V01512"), "Workspace must install the v0.15.12 generation service.")
	assert(workspace_source.contains("queue_full_character_synthesis"), "Generate Character must call the full synthesis path.")
	assert(not workspace_source.contains("include_existing_fields"), "Generate Character must not fall back to missing/existing-field gating.")

	var base_workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_view.gd")
	assert(base_workspace_source.contains("_suggest_field"), "Selective field generation must remain available separately.")
	assert(base_workspace_source.contains("Controlled Build"), "Controlled/selective generation must remain available separately.")

	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(scene_source.contains("main_v01512.gd"), "The active scene must use v0.15.12.")

	print("v0.15.12 full character synthesis regression passed")
	quit(0)
