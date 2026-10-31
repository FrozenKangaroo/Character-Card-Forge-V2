extends SceneTree

const CHAOS = preload(
	"res://scripts/services/front_porch_chaos_mode_v02116.gd"
)


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V02116_FRONT_PORCH_CHAOS_MODES_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var service := CCFFrontPorchExtensionServiceCurrent.new()
	var field := service.field_by_id("fp_chaos_mode")
	if not _require(
		str(field.get("type", "")) == "select"
		and field.get("options", []) == ["disabled", "rare", "normal", "wild"]
		and str(field.get("key_path", "")) == "chaos_frequency",
		"The existing Front Porch Chaos control must be the four-choice selector."
	):
		return
	var labels_value: Variant = field.get("option_labels", {})
	var labels: Dictionary = labels_value if labels_value is Dictionary else {}
	if not _require(
		str(labels.get("disabled", "")) == "Disabled"
		and str(labels.get("rare", "")) == "Rare"
		and str(labels.get("normal", "")) == "Normal"
		and str(labels.get("wild", "")) == "Wild",
		"Chaos selector labels must match the Rawhide names."
	):
		return

	if not _test_legacy_project_values(service, field):
		return
	if not _test_legacy_card_import(service, field):
		return
	for mode in [CHAOS.MODE_DISABLED, CHAOS.MODE_RARE, CHAOS.MODE_NORMAL, CHAOS.MODE_WILD]:
		if not _test_round_trip(service, field, mode):
			return
	if not _test_unknown_rawhide_fallback(service, field):
		return
	if not _test_removal_and_unknown_preservation(service):
		return

	var capabilities := service.capabilities()
	if not _require(
		str(capabilities.get("version", "")) == "0.21.16"
		and capabilities.get("chaos_modes", []) == ["rare", "normal", "wild"]
		and bool(capabilities.get("chaos_legacy_boolean_compatibility", false)),
		"Current Front Porch capabilities must disclose multi-mode and legacy support."
	):
		return
	print("V02116_FRONT_PORCH_CHAOS_MODES_OK")
	quit(0)


func _test_legacy_project_values(
	service: CCFFrontPorchExtensionServiceCurrent, field: Dictionary
) -> bool:
	for legacy_enabled in [false, true]:
		var project := CCFStorageService.new_project()
		var character_id := CCFStorageService.active_character_id(project)
		var document := CCFStorageService.character_workspace_document(
			project, character_id
		)
		CCFStorageService.set_value_at_path(
			document,
			"character.card_extensions.front_porch.realism_engine.chaos_mode_enabled",
			legacy_enabled
		)
		var expected := CHAOS.MODE_NORMAL if legacy_enabled else CHAOS.MODE_DISABLED
		if not _require(
			service.is_included(document, field)
			and str(service.value_for(document, field)) == expected,
			"Legacy Chaos %s must load as %s."
			% [str(legacy_enabled), expected]
		):
			return false
	return true


func _test_legacy_card_import(
	service: CCFFrontPorchExtensionServiceCurrent, field: Dictionary
) -> bool:
	for legacy_enabled in [false, true]:
		var source_project := CCFStorageService.new_project()
		var source_id := CCFStorageService.active_character_id(source_project)
		var card := CCFCardFormatService.export_character_v2(source_project, source_id)
		CCFStorageService.set_value_at_path(
			card,
			"data.extensions.front_porch",
			{
				"version": "2.5",
				"realism_engine": {"chaos_mode_enabled": legacy_enabled}
			}
		)
		var imported := CCFCardFormatService.import_card_to_project(card, "json")
		if not _require(
			bool(imported.get("ok", false)),
			"A legacy boolean-only Front Porch card must import."
		):
			return false
		var project_value: Variant = imported.get("project", {})
		var project: Dictionary = project_value if project_value is Dictionary else {}
		var character_id := CCFStorageService.active_character_id(project)
		var document := CCFStorageService.character_workspace_document(
			project, character_id
		)
		var expected := CHAOS.MODE_NORMAL if legacy_enabled else CHAOS.MODE_DISABLED
		if not _require(
			service.is_included(document, field)
			and str(service.value_for(document, field)) == expected,
			"Legacy Front Porch card Chaos %s must import as %s."
			% [str(legacy_enabled), expected]
		):
			return false
	return true


func _test_round_trip(
	service: CCFFrontPorchExtensionServiceCurrent,
	field: Dictionary,
	mode: String
) -> bool:
	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var document := CCFStorageService.character_workspace_document(project, character_id)
	var maps := _control_maps(service, document)
	var enabled: Dictionary = maps.get("enabled", {})
	var values: Dictionary = maps.get("values", {})
	enabled["fp_chaos_mode"] = true
	values["fp_chaos_mode"] = mode
	var applied := service.apply_control_values(document, enabled, values, false)
	if not _require(
		bool(applied.get("ok", false))
		and str(service.value_for(document, field)) == mode,
		"Chaos mode %s must apply through the existing Front Porch service." % mode
	):
		return false
	var realism_value: Variant = CCFStorageService.get_value_at_path(
		document,
		"character.card_extensions.front_porch.realism_engine",
		{}
	)
	var realism: Dictionary = realism_value if realism_value is Dictionary else {}
	var enabled_expected := mode != CHAOS.MODE_DISABLED
	if not _require(
		bool(realism.get("chaos_mode_enabled", not enabled_expected)) == enabled_expected,
		"Chaos mode %s must retain Rawhide's portable enable flag." % mode
	):
		return false
	if not _require(
		(
			(not realism.has("chaos_frequency"))
			if mode == CHAOS.MODE_DISABLED
			else str(realism.get("chaos_frequency", "")) == mode
		),
		"Chaos mode %s must use the current Rawhide frequency representation." % mode
	):
		return false

	CCFStorageService.update_character(project, document)
	var card := CCFCardFormatService.export_character_v2(project, character_id)
	var exported_realism_value: Variant = CCFStorageService.get_value_at_path(
		card, "data.extensions.front_porch.realism_engine", {}
	)
	var exported_realism: Dictionary = (
		exported_realism_value if exported_realism_value is Dictionary else {}
	)
	if not _require(
		bool(exported_realism.get("chaos_mode_enabled", not enabled_expected))
		== enabled_expected,
		"Character Card V2 export must carry the Chaos enable flag for %s." % mode
	):
		return false
	if mode != CHAOS.MODE_DISABLED and not _require(
		str(exported_realism.get("chaos_frequency", "")) == mode,
		"Character Card V2 export must carry Chaos frequency %s." % mode
	):
		return false

	var imported := CCFCardFormatService.import_card_to_project(card, "json")
	if not _require(
		bool(imported.get("ok", false)),
		"A card containing Chaos mode %s must import again." % mode
	):
		return false
	var imported_project_value: Variant = imported.get("project", {})
	var imported_project: Dictionary = (
		imported_project_value if imported_project_value is Dictionary else {}
	)
	var imported_id := CCFStorageService.active_character_id(imported_project)
	var imported_document := CCFStorageService.character_workspace_document(
		imported_project, imported_id
	)
	return _require(
		service.is_included(imported_document, field)
		and str(service.value_for(imported_document, field)) == mode,
		"Export then import must preserve Chaos mode %s." % mode
	)


func _test_unknown_rawhide_fallback(
	service: CCFFrontPorchExtensionServiceCurrent, field: Dictionary
) -> bool:
	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var document := CCFStorageService.character_workspace_document(project, character_id)
	CCFStorageService.set_value_at_path(
		document,
		"character.card_extensions.front_porch.realism_engine.chaos_frequency",
		"future-frequency"
	)
	return _require(
		str(service.value_for(document, field)) == CHAOS.MODE_NORMAL,
		"Unknown imported Rawhide frequency values must follow Rawhide's Normal fallback."
	)


func _test_removal_and_unknown_preservation(
	service: CCFFrontPorchExtensionServiceCurrent
) -> bool:
	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var document := CCFStorageService.character_workspace_document(project, character_id)
	CCFStorageService.set_value_at_path(
		document,
		"character.card_extensions.front_porch.realism_engine",
		{
			"chaos_mode_enabled": true,
			"chaos_frequency": "wild",
			"future_chaos_option": 17
		}
	)
	var maps := _control_maps(service, document)
	var enabled: Dictionary = maps.get("enabled", {})
	var values: Dictionary = maps.get("values", {})
	enabled["fp_chaos_mode"] = false
	var applied := service.apply_control_values(document, enabled, values, false)
	var realism_value: Variant = CCFStorageService.get_value_at_path(
		document,
		"character.card_extensions.front_porch.realism_engine",
		{}
	)
	var realism: Dictionary = realism_value if realism_value is Dictionary else {}
	return _require(
		bool(applied.get("ok", false))
		and not realism.has("chaos_mode_enabled")
		and not realism.has("chaos_frequency")
		and int(realism.get("future_chaos_option", 0)) == 17,
		"Turning Include off must remove both known Chaos keys without losing future data."
	)


func _control_maps(
	service: CCFFrontPorchExtensionServiceCurrent, document: Dictionary
) -> Dictionary:
	var enabled: Dictionary = {}
	var values: Dictionary = {}
	for field in service.all_fields():
		var field_id := str(field.get("id", ""))
		enabled[field_id] = service.is_included(document, field)
		values[field_id] = service.value_for(document, field)
	return {"enabled": enabled, "values": values}
