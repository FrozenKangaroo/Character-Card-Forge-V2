extends SceneTree

const TEST_USER_DATA_ISOLATION = preload("res://tools/test_user_data_isolation.gd")
var _test_user_data_isolation := TEST_USER_DATA_ISOLATION.activate(
	"v02117-front-porch-pockets-defaults"
)


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V02117_FRONT_PORCH_POCKETS_DEFAULTS_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var service := CCFFrontPorchExtensionServiceCurrent.new()
	if not _test_character_default_and_inventory(service):
		return
	if not _test_group_defaults_and_members():
		return
	var capabilities := service.capabilities()
	if not _require(
		str(capabilities.get("rawhide_pockets_pr708_commit", ""))
		== "04f260783499728ffc93708132eb36900e280868"
		and bool(capabilities.get("pockets_character_default_is_tristate", false)),
		"Capabilities must identify the merged Rawhide PR #708 contract."
	):
		return
	print("V02117_FRONT_PORCH_POCKETS_DEFAULTS_OK")
	quit(0)


func _test_character_default_and_inventory(
	service: CCFFrontPorchExtensionServiceCurrent
) -> bool:
	var field := service.field_by_id("fp_pockets_enabled")
	if not _require(
		str(field.get("label", "")).contains("default for new chats")
		and str(field.get("help_text", "")).contains("Existing conversations")
		and str(field.get("help_text", "")).contains("session switch"),
		"The character editor must describe a new-chat default, not a runtime switch."
	):
		return false
	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var document := CCFStorageService.character_workspace_document(
		project, character_id
	)
	if not _require(
		not service.is_included(document, field)
		and service.value_for(document, field) == true,
		"A missing character default must remain absent while reading as Rawhide's enabled default."
	):
		return false
	CCFStorageService.set_value_at_path(
		document,
		"character.card_extensions.front_porch.realism_engine.future_pockets_rule",
		{"keep": true}
	)
	var enabled := _enabled_map(service, document)
	var values := _value_map(service, document)
	enabled["fp_pockets_enabled"] = true
	values["fp_pockets_enabled"] = true
	enabled["fp_inventory_worn"] = true
	values["fp_inventory_worn"] = ["Sundress (rain-soaked, hem torn)"]
	enabled["fp_inventory_carrying"] = true
	values["fp_inventory_carrying"] = [
		"Silver phone (two chats, kept private)",
		"\"秘密\", keys and a folded note\nkept in the inner pocket"
	]
	var applied := service.apply_control_values(
		document, enabled, values, true
	)
	if not _require(
		bool(applied.get("ok", false))
		and CCFStorageService.get_value_at_path(
			document,
			"character.card_extensions.front_porch.realism_engine.pockets_enabled",
			null
		) == true,
		"An explicitly included true character default must remain explicit."
	):
		return false
	CCFStorageService.update_character(project, document)
	var exported := CCFCardFormatService.export_character_v2(
		project, character_id
	)
	var realism: Dictionary = CCFStorageService.get_value_at_path(
		exported, "data.extensions.front_porch.realism_engine", {}
	)
	if not _require(
		realism.get("pockets_enabled") == true
		and realism.get("inventory", {}).get("worn", [])
		== ["Sundress (rain-soaked, hem torn)"]
		and realism.get("inventory", {}).get("carrying", []) == values["fp_inventory_carrying"]
		and realism.get("future_pockets_rule", {}).get("keep", false)
		and not realism.has("pockets_switch"),
		"Character export must retain the explicit default, atomic inventory arrays and unknown card data without session switches."
	):
		return false
	var imported := CCFCardFormatService.import_card_to_project(exported, "json")
	if not _require(bool(imported.get("ok", false)), "The character card must re-import."):
		return false
	var imported_project: Dictionary = imported.get("project", {})
	var imported_id := CCFStorageService.active_character_id(imported_project)
	var imported_document := CCFStorageService.character_workspace_document(
		imported_project, imported_id
	)
	if not _require(
		service.is_included(imported_document, field)
		and service.value_for(imported_document, field) == true,
		"Re-import must preserve explicit true rather than collapsing it to absence."
	):
		return false
	var imported_enabled := _enabled_map(service, imported_document)
	var imported_values := _value_map(service, imported_document)
	imported_enabled["fp_pockets_enabled"] = false
	service.apply_control_values(
		imported_document, imported_enabled, imported_values, true
	)
	if not _require(
		not service.is_included(imported_document, field),
		"Turning Include off must restore field absence."
	):
		return false
	imported_enabled["fp_pockets_enabled"] = true
	imported_values["fp_pockets_enabled"] = false
	service.apply_control_values(
		imported_document, imported_enabled, imported_values, true
	)
	return _require(
		service.is_included(imported_document, field)
		and service.value_for(imported_document, field) == false,
		"Explicit false must remain present and editable."
	)


func _test_group_defaults_and_members() -> bool:
	var missing_state := JSON.stringify({
		"perChar": {}, "future_group_rule": {"keep": true}
	})
	if not _require(
		CCFFrontPorchGroupCardServiceV0174.group_pockets_default_for_new_chats_v02117(
			missing_state
		),
		"A missing group default must read as enabled."
	):
		return false
	var disabled_state := (
		CCFFrontPorchGroupCardServiceV0174.with_group_pockets_default_for_new_chats_v02117(
			missing_state, false
		)
	)
	var disabled_data: Dictionary = JSON.parse_string(disabled_state)
	if not _require(
		disabled_data.get("pockets_enabled") == false
		and disabled_data.get("future_group_rule", {}).get("keep", false)
		and not CCFFrontPorchGroupCardServiceV0174.group_pockets_default_for_new_chats_v02117(
			disabled_state
		),
		"The confirmed group-level default must live in default_member_realism_state and preserve unknown keys."
	):
		return false
	var enabled_state := (
		CCFFrontPorchGroupCardServiceV0174.with_group_pockets_default_for_new_chats_v02117(
			disabled_state, true
		)
	)
	var enabled_data: Dictionary = JSON.parse_string(enabled_state)
	if not _require(
		not enabled_data.has("pockets_enabled")
		and enabled_data.get("future_group_rule", {}).get("keep", false),
		"Rawhide's enabled group default must use canonical omission without losing future data."
	):
		return false

	var project := CCFStorageService.new_project()
	var characters: Array = project.get("characters", [])
	var first: Dictionary = characters[0]
	first["character"]["name"] = "Mara"
	first["character"]["description"] = "A careful archivist."
	CCFStorageService.set_value_at_path(
		first,
		"character.card_extensions.front_porch.realism_engine.pockets_enabled",
		false
	)
	var first_id := str(first.get("character_id", ""))
	characters[0] = first
	var second := CCFStorageService.new_character_record("Ben")
	second["character"]["description"] = "A patient expedition guide."
	CCFStorageService.set_value_at_path(
		second,
		"character.card_extensions.front_porch.realism_engine.pockets_enabled",
		true
	)
	var second_id := str(second.get("character_id", ""))
	characters.append(second)
	project["characters"] = characters
	var workflow := {
		"workflow_id": "pockets-defaults",
		"mode": "group_card",
		"title": "Mara and Ben",
		"selected_character_ids": [first_id, second_id],
		"shared_scenario": "They prepare for an expedition.",
		"opening_message": "The bags are packed.",
		"front_porch_group": CCFFrontPorchGroupCardServiceV0174.default_group_options(
			project, {"selected_character_ids": [first_id, second_id]}
		)
	}
	workflow["front_porch_group"]["default_member_realism_state"] = disabled_state
	var built := CCFFrontPorchGroupCardServiceV0174.build_group_payload(
		project, workflow
	)
	if not _require(bool(built.get("ok", false)), "The group payload must build."):
		return false
	var payload: Dictionary = built.get("payload", {})
	var group_state: Dictionary = JSON.parse_string(
		str(payload.get("default_member_realism_state", "{}"))
	)
	var raw_members: Array = payload.get("raw_member_data", [])
	var first_realism: Dictionary = CCFStorageService.get_value_at_path(
		raw_members[0], "extensions.front_porch.realism_engine", {}
	)
	var second_realism: Dictionary = CCFStorageService.get_value_at_path(
		raw_members[1], "extensions.front_porch.realism_engine", {}
	)
	if not _require(
		group_state.get("pockets_enabled") == false
		and group_state.get("future_group_rule", {}).get("keep", false)
		and first_realism.get("pockets_enabled") == false
		and second_realism.get("pockets_enabled") == true
		and not group_state.has("pockets_switch"),
		"Group export must preserve the group default and each member card default without exporting session switches."
	):
		return false
	var imported := CCFFrontPorchGroupCardServiceV0174.import_group_to_project(
		payload
	)
	if not _require(bool(imported.get("ok", false)), "The group card must import."):
		return false
	var imported_project: Dictionary = imported.get("project", {})
	var imported_workflow: Dictionary = imported_project.get("card_workflows", [])[0]
	var imported_state: Dictionary = JSON.parse_string(
		str(imported_workflow.get("front_porch_group", {}).get(
			"default_member_realism_state", "{}"
		))
	)
	var imported_values: Array = []
	for character in imported_project.get("characters", []):
		imported_values.append(CCFStorageService.get_value_at_path(
			character,
			"character.card_extensions.front_porch.realism_engine.pockets_enabled",
			null
		))
	return _require(
		imported_state.get("pockets_enabled") == false
		and imported_state.get("future_group_rule", {}).get("keep", false)
		and imported_values == [false, true],
		"Group import must restore the group and per-member new-chat defaults losslessly."
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
