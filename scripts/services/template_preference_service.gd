class_name CCFTemplatePreferenceService
extends RefCounted

const BUILT_IN_DEFAULT_TEMPLATE_ID := "default"


static func available_template_ids() -> Array[String]:
	var result: Array[String] = []
	for raw_summary in CCFTemplateService.list_templates():
		if not raw_summary is Dictionary:
			continue
		var template_id := str(raw_summary.get("template_id", "")).strip_edges()
		if not template_id.is_empty() and not result.has(template_id):
			result.append(template_id)
	if not result.has(BUILT_IN_DEFAULT_TEMPLATE_ID):
		result.push_front(BUILT_IN_DEFAULT_TEMPLATE_ID)
	return result


static func resolve_template_id(template_id: String) -> String:
	var requested := template_id.strip_edges()
	if requested.is_empty():
		requested = BUILT_IN_DEFAULT_TEMPLATE_ID
	if available_template_ids().has(requested):
		return requested
	return BUILT_IN_DEFAULT_TEMPLATE_ID


static func default_template_id(settings: Dictionary) -> String:
	var generation_value: Variant = settings.get("generation", {})
	var generation: Dictionary = generation_value if generation_value is Dictionary else {}
	return resolve_template_id(str(generation.get("default_template_id", BUILT_IN_DEFAULT_TEMPLATE_ID)))


static func requested_default_template_id(settings: Dictionary) -> String:
	var generation_value: Variant = settings.get("generation", {})
	var generation: Dictionary = generation_value if generation_value is Dictionary else {}
	var requested := str(generation.get("default_template_id", BUILT_IN_DEFAULT_TEMPLATE_ID)).strip_edges()
	return requested if not requested.is_empty() else BUILT_IN_DEFAULT_TEMPLATE_ID


static func set_default_template_id(settings: Dictionary, template_id: String) -> String:
	var resolved := resolve_template_id(template_id)
	var generation_value: Variant = settings.get("generation", {})
	var generation: Dictionary = generation_value.duplicate(true) if generation_value is Dictionary else {}
	generation["default_template_id"] = resolved
	settings["generation"] = generation
	return resolved


static func repair_missing_default(settings: Dictionary) -> bool:
	var requested := requested_default_template_id(settings)
	var resolved := resolve_template_id(requested)
	if requested == resolved:
		return false
	set_default_template_id(settings, resolved)
	return true


static func assign_character_template(project: Dictionary, character_id: String, template_id: String) -> String:
	var index := CCFStorageService.character_index(project, character_id)
	if index < 0:
		return BUILT_IN_DEFAULT_TEMPLATE_ID
	var resolved := resolve_template_id(template_id)
	var characters: Array = project.get("characters", []).duplicate(true)
	if index >= characters.size() or not characters[index] is Dictionary:
		return BUILT_IN_DEFAULT_TEMPLATE_ID
	var character: Dictionary = characters[index].duplicate(true)
	var generation_value: Variant = character.get("generation", {})
	var generation: Dictionary = generation_value.duplicate(true) if generation_value is Dictionary else {}
	generation["template_id"] = resolved
	character["generation"] = generation
	characters[index] = character
	project["characters"] = characters
	return resolved
