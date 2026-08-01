class_name CCFGenerationServiceV01415
extends "res://scripts/services/generation_service_v01413.gd"


func _shared_context_text(project: Dictionary) -> String:
	var base_context := super._shared_context_text(project)
	var lore_context := CCFLorebookContextServiceV01415.generation_context_for_project(project)
	if lore_context.is_empty():
		return base_context
	if base_context.is_empty():
		return "LOREBOOK CONTEXT:\n%s" % lore_context
	return "%s\n\nLOREBOOK CONTEXT:\n%s" % [base_context, lore_context]
