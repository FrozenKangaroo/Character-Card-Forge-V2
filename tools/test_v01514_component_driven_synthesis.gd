extends SceneTree


func _init() -> void:
	var service_source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v01514.gd")
	assert(service_source.contains("_full_synthesis_plan_v01514"), "v0.15.14 must build an explicit component-driven synthesis plan.")
	assert(service_source.contains("CCFTemplateService.generation_groups(template)"), "Full synthesis must consume template generation groups.")
	assert(service_source.contains("GENERATION COMPONENT PLAN"), "The model prompt must receive the generation component plan.")
	assert(service_source.contains("Generation Components as the transformation recipe"), "Component instructions must be authoritative transformation rules.")
	assert(service_source.contains("disabled generation groups and disabled components".to_upper()) or service_source.contains("Disabled generation groups and disabled components"), "Disabled groups/components must be excluded from generation.")
	assert(service_source.contains("enabled_generation_group_ids"), "Synthesis metadata must record enabled generation groups.")
	assert(service_source.contains("disabled_generation_group_ids"), "Synthesis metadata must record disabled generation groups.")
	assert(service_source.contains("generation_components_authoritative"), "Synthesis metadata must mark Generation Components authoritative.")
	assert(service_source.contains("Compose ONE coherent final"), "Grouped component outputs must materialise into one destination field, not component subkeys.")

	var template_source := FileAccess.get_file_as_string("res://scripts/services/template_service.gd")
	assert(template_source.contains("static func generation_groups"), "Template service must expose generation groups.")
	assert(template_source.contains("output_field_id"), "Generation groups must bind to output fields.")
	assert(template_source.contains("instruction"), "Generation components must expose author instructions.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01514.gd")
	assert(workspace_source.contains("GENERATION_SERVICE_V01514"), "Workspace must install the v0.15.14 service.")
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(scene_source.contains("main_v01514.gd"), "The active scene must use v0.15.14.")

	print("v0.15.14 component-driven full synthesis regression passed")
	quit(0)
