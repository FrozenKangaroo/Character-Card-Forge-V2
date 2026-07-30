extends SceneTree

const TEMPLATE_PREFERENCES = preload("res://scripts/services/template_preference_service.gd")

var _created_template_id := ""


func _init() -> void:
	var settings := CCFSettingsService.default_settings()
	if TEMPLATE_PREFERENCES.default_template_id(settings) != "default":
		_fail("Fresh settings should resolve to the built-in Default template.")
		return

	var custom_template := CCFTemplateService.create_template("Regression Default Template")
	var save_result := CCFTemplateService.save_template(custom_template)
	if not bool(save_result.get("ok", false)):
		_fail("Could not create regression template: %s" % str(save_result.get("error", "unknown error")))
		return
	_created_template_id = str(custom_template.get("template_id", ""))
	if _created_template_id.is_empty():
		_fail("Regression template did not receive a stable ID.")
		return

	var resolved := TEMPLATE_PREFERENCES.set_default_template_id(settings, _created_template_id)
	if resolved != _created_template_id:
		_fail("Custom template could not become the global default.")
		return
	if TEMPLATE_PREFERENCES.default_template_id(settings) != _created_template_id:
		_fail("Saved default template preference did not resolve to the custom template.")
		return

	var project := CCFStorageService.new_project()
	var first_id := CCFStorageService.active_character_id(project)
	TEMPLATE_PREFERENCES.assign_character_template(project, first_id, resolved)
	if CCFStorageService.active_character_template_id(project) != _created_template_id:
		_fail("First new character did not inherit the selected default template.")
		return

	var second_id := CCFStorageService.add_character(project, "Second Character")
	TEMPLATE_PREFERENCES.assign_character_template(
		project, second_id, TEMPLATE_PREFERENCES.default_template_id(settings)
	)
	var second := CCFStorageService.get_character(project, second_id)
	var second_generation: Variant = second.get("generation", {})
	if not second_generation is Dictionary or str(second_generation.get("template_id", "")) != _created_template_id:
		_fail("Additional characters did not inherit the selected default template.")
		return

	TEMPLATE_PREFERENCES.set_default_template_id(settings, "default")
	var first := CCFStorageService.get_character(project, first_id)
	var first_generation: Variant = first.get("generation", {})
	if not first_generation is Dictionary or str(first_generation.get("template_id", "")) != _created_template_id:
		_fail("Changing the global default rewrote an existing character assignment.")
		return
	second = CCFStorageService.get_character(project, second_id)
	second_generation = second.get("generation", {})
	if not second_generation is Dictionary or str(second_generation.get("template_id", "")) != _created_template_id:
		_fail("Changing the global default rewrote another existing character assignment.")
		return

	var stale_settings := CCFSettingsService.default_settings()
	var stale_generation: Dictionary = stale_settings.get("generation", {}).duplicate(true)
	stale_generation["default_template_id"] = _created_template_id
	stale_settings["generation"] = stale_generation
	_cleanup_template()
	if TEMPLATE_PREFERENCES.default_template_id(stale_settings) != "default":
		_fail("Missing custom default template did not fall back to the built-in Default template.")
		return
	if not TEMPLATE_PREFERENCES.repair_missing_default(stale_settings):
		_fail("Missing default-template preference was not reported as repaired.")
		return
	if TEMPLATE_PREFERENCES.requested_default_template_id(stale_settings) != "default":
		_fail("Repair did not persist the built-in fallback template ID.")
		return

	print("Default template selection regression passed.")
	quit(0)


func _cleanup_template() -> void:
	if _created_template_id.is_empty():
		return
	CCFTemplateService.delete_template(_created_template_id)
	_created_template_id = ""


func _fail(message: String) -> void:
	_cleanup_template()
	push_error(message)
	quit(1)
