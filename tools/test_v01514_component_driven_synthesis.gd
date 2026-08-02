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
	assert(_active_shell_inherits_v01514(), "The active scene must use v0.15.14 or a later shell inheriting from it.")

	print("v0.15.14 component-driven full synthesis regression passed")
	quit(0)


func _active_shell_inherits_v01514() -> bool:
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	var marker := "res://scripts/"
	var marker_at := scene_source.find(marker)
	if marker_at < 0:
		return false
	var end_at := scene_source.find("\"", marker_at)
	if end_at < 0:
		return false
	var path := scene_source.substr(marker_at, end_at - marker_at)
	for _depth in range(16):
		if path == "res://scripts/main_v01514.gd":
			return true
		if not FileAccess.file_exists(path):
			return false
		var source := FileAccess.get_file_as_string(path)
		var extends_marker := "extends \""
		var extends_at := source.find(extends_marker)
		if extends_at < 0:
			return false
		var start_at := extends_at + extends_marker.length()
		var next_end := source.find("\"", start_at)
		if next_end < 0:
			return false
		path = source.substr(start_at, next_end - start_at)
	return false
