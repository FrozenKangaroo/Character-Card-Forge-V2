extends SceneTree

const TEST_USER_DATA_ISOLATION = preload("res://tools/test_user_data_isolation.gd")
var _test_user_data_isolation := TEST_USER_DATA_ISOLATION.activate(
	"v02118-front-porch-afterglow-defaults"
)


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V02118_FRONT_PORCH_AFTERGLOW_DEFAULTS_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var service := CCFFrontPorchExtensionServiceCurrent.new()
	if not _test_field_contract(service):
		return
	if not _test_tristate_round_trip(service):
		return
	if not _test_ai_value_normalisation(service):
		return
	var capabilities := service.capabilities()
	if not _require(
		str(capabilities.get("rawhide_afterglow_pr669_commit", ""))
		== "756d1a33959036498a6657bc0d0989438654e2f4"
		and bool(capabilities.get("afterglow_character_default_is_tristate", false))
		and str(capabilities.get("version", ""))
		== str(ProjectSettings.get_setting("application/config/version", "")),
		"Capabilities must identify the Rawhide Afterglow contract and the current service version."
	):
		return
	print("V02118_FRONT_PORCH_AFTERGLOW_DEFAULTS_OK")
	quit(0)


func _test_field_contract(
	service: CCFFrontPorchExtensionServiceCurrent
) -> bool:
	var field := service.field_by_id("fp_afterglow_enabled")
	if not _require(
		not field.is_empty(),
		"Rawhide's afterglow_enabled card property must have a Front Porch field."
	):
		return false
	var path := service.full_project_path(field)
	if not _require(
		path
		== "character.card_extensions.front_porch.realism_engine.afterglow_enabled",
		"The Afterglow field must map onto the Rawhide realism_engine property."
	):
		return false
	return _require(
		str(field.get("label", "")).contains("default for new chats")
		and str(field.get("help_text", "")).contains("Existing conversations")
		and str(field.get("type", "")) == "checkbox"
		and bool(field.get("default", false)),
		"The control must describe a new-chat default whose unset state reads as enabled."
	)


func _test_tristate_round_trip(
	service: CCFFrontPorchExtensionServiceCurrent
) -> bool:
	var field := service.field_by_id("fp_afterglow_enabled")
	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var document := CCFStorageService.character_workspace_document(
		project, character_id
	)
	if not _require(
		not service.is_included(document, field)
		and service.value_for(document, field) == true,
		"A missing card default must read as Rawhide's enabled default while staying absent."
	):
		return false

	var enabled := _enabled_map(service, document)
	var values := _value_map(service, document)
	enabled["fp_afterglow_enabled"] = true
	values["fp_afterglow_enabled"] = false
	var applied := service.apply_control_values(document, enabled, values, true)
	if not _require(
		bool(applied.get("ok", false))
		and CCFStorageService.get_value_at_path(
			document,
			"character.card_extensions.front_porch.realism_engine.afterglow_enabled",
			null
		) == false,
		"Turning the default off must write an explicit false."
	):
		return false

	CCFStorageService.update_character(project, document)
	var exported := CCFCardFormatService.export_character_v2(project, character_id)
	var realism: Dictionary = CCFStorageService.get_value_at_path(
		exported, "data.extensions.front_porch.realism_engine", {}
	)
	if not _require(
		realism.get("afterglow_enabled") == false
		and not realism.has("afterglow_switch"),
		"Export must carry the explicit false and no runtime session switch."
	):
		return false

	var imported := CCFCardFormatService.import_card_to_project(exported, "json")
	if not _require(bool(imported.get("ok", false)), "The card must re-import."):
		return false
	var imported_project: Dictionary = imported.get("project", {})
	var imported_id := CCFStorageService.active_character_id(imported_project)
	var imported_document := CCFStorageService.character_workspace_document(
		imported_project, imported_id
	)
	if not _require(
		service.is_included(imported_document, field)
		and service.value_for(imported_document, field) == false,
		"Re-import must preserve the explicit false."
	):
		return false

	var imported_enabled := _enabled_map(service, imported_document)
	var imported_values := _value_map(service, imported_document)
	imported_enabled["fp_afterglow_enabled"] = true
	imported_values["fp_afterglow_enabled"] = true
	service.apply_control_values(
		imported_document, imported_enabled, imported_values, true
	)
	if not _require(
		service.is_included(imported_document, field)
		and service.value_for(imported_document, field) == true,
		"An explicitly included true default must remain explicit."
	):
		return false

	imported_enabled["fp_afterglow_enabled"] = false
	service.apply_control_values(
		imported_document, imported_enabled, imported_values, true
	)
	return _require(
		not service.is_included(imported_document, field)
		and service.value_for(imported_document, field) == true,
		"Turning Include off must restore absence, which Rawhide reads as enabled."
	)


func _test_ai_value_normalisation(
	service: CCFFrontPorchExtensionServiceCurrent
) -> bool:
	var field := service.field_by_id("fp_afterglow_enabled")
	var false_result := service.normalise_generated_preview_value_v02116(
		field, "false"
	)
	var true_result := service.normalise_generated_preview_value_v02116(
		field, "TRUE"
	)
	var zero_result := service.normalise_generated_preview_value_v02116(field, 0)
	var invalid_result := service.normalise_generated_preview_value_v02116(
		field, "maybe"
	)
	var missing_result := service.normalise_generated_preview_value_v02116(
		field, null
	)
	return _require(
		bool(false_result.get("ok", false))
		and false_result.get("value") == false
		and bool(true_result.get("ok", false))
		and true_result.get("value") == true
		and bool(zero_result.get("ok", false))
		and zero_result.get("value") == false
		and not bool(invalid_result.get("ok", true))
		and not bool(missing_result.get("ok", true)),
		"Text booleans, numbers, invalid text and absent values must not be coerced by bool()."
	)


func _enabled_map(
	service: CCFFrontPorchExtensionServiceCurrent, document: Dictionary
) -> Dictionary:
	var result: Dictionary = {}
	for field in service.all_fields():
		result[str(field.get("id", ""))] = service.is_included(document, field)
	return result


func _value_map(
	service: CCFFrontPorchExtensionServiceCurrent, document: Dictionary
) -> Dictionary:
	var result: Dictionary = {}
	for field in service.all_fields():
		result[str(field.get("id", ""))] = service.value_for(document, field)
	return result
