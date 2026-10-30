extends SceneTree

const RAW_HIDE = preload(
	"res://scripts/services/front_porch_rawhide_character_v02116.gd"
)
const RECOVERY_CONTROL = preload(
	"res://scripts/ui/front_porch_recovery_control_v02116.gd"
)


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V02116_RAWHIDE_CHARACTER_COMPATIBILITY_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var service := CCFFrontPorchExtensionServiceCurrent.new()
	if not _test_catalog_and_values(service):
		return
	if not _test_recovery_duration_normalisation():
		return
	if not _test_recovery_editor_round_trip(service):
		return
	if not _test_card_v2_round_trip(service):
		return
	if not _test_group_lore_world_ids():
		return
	var capabilities := service.capabilities()
	if not _require(
		str(capabilities.get("rawhide_schema_commit", "")) == RAW_HIDE.RAW_HIDE_COMMIT,
		"Capabilities must identify the audited Rawhide commit."
	):
		return
	print("V02116_RAWHIDE_CHARACTER_COMPATIBILITY_OK")
	quit(0)


func _test_catalog_and_values(service: CCFFrontPorchExtensionServiceCurrent) -> bool:
	for field_id in [
		"fp_pockets_enabled", "fp_needs_enabled", "fp_needs_pace", "fp_needs_off",
		"fp_sex", "fp_recovery", "fp_world_names", "fp_lore_world_names"
	]:
		if not _require(not service.field_by_id(field_id).is_empty(), "%s must exist." % field_id):
			return false
	for legacy_id in [
		"fp_needs_strength", "fp_decay_hunger", "fp_decay_bladder",
		"fp_decay_energy", "fp_decay_social", "fp_decay_fun",
		"fp_decay_hygiene", "fp_decay_comfort"
	]:
		var field := service.field_by_id(legacy_id)
		if not _require(
			bool(field.get("legacy_ignored", false)) and not bool(field.get("generate", true)),
			"%s must be retained as a non-generated legacy value." % legacy_id
		):
			return false
	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	var document := CCFStorageService.character_workspace_document(project, character_id)
	var maps := _control_maps(service, document)
	var enabled: Dictionary = maps.enabled
	var values: Dictionary = maps.values
	enabled["fp_pockets_enabled"] = true
	values["fp_pockets_enabled"] = false
	enabled["fp_needs_enabled"] = true
	values["fp_needs_enabled"] = false
	enabled["fp_needs_pace"] = true
	values["fp_needs_pace"] = "fast"
	enabled["fp_needs_off"] = true
	values["fp_needs_off"] = ["hunger", "comfort"]
	enabled["fp_sex"] = true
	values["fp_sex"] = "female"
	enabled["fp_recovery"] = true
	values["fp_recovery"] = {"mode": "hard", "minutes": 240, "pcd": "sometimes"}
	var applied := service.apply_control_values(document, enabled, values, true)
	var realism: Dictionary = CCFStorageService.get_value_at_path(
		document, "character.card_extensions.front_porch.realism_engine", {}
	)
	if not _require(
		bool(applied.get("ok", false))
		and realism.get("pockets_enabled") == false
		and realism.get("needs_sim_enabled") == false
		and str(realism.get("needs_pace", "")) == "fast"
		and realism.get("needs_off", []) == ["hunger", "comfort"]
		and str(realism.get("sex", "")) == "female"
		and realism.get("recovery", {}).get("minutes") == 180,
		"Current Rawhide values must apply with explicit false and recovery clamping."
	):
		return false
	var unknown_needs := RAW_HIDE.normalise_needs_off(["hunger", "futureNeed"])
	var unknown_recovery := RAW_HIDE.normalise_recovery({
		"mode": "future_mode", "pcd": "future_pcd", "future_rule": 7
	})
	if not _require(
		unknown_needs.get("value", []) == ["hunger", "futureNeed"]
		and unknown_recovery.get("value", {}).get("future_rule") == 7,
		"Unknown future Needs and Recovery values must remain lossless."
	):
		return false
	values["fp_pockets_enabled"] = true
	values["fp_needs_off"] = []
	values["fp_recovery"] = {"mode": "auto", "pcd": "off"}
	applied = service.apply_control_values(document, enabled, values, true)
	realism = CCFStorageService.get_value_at_path(
		document, "character.card_extensions.front_porch.realism_engine", {}
	)
	return _require(
		bool(applied.get("ok", false))
		and not realism.has("pockets_enabled")
		and not realism.has("needs_off")
		and not realism.has("recovery"),
		"Rawhide defaults and empty lists must use canonical omission semantics."
	)


func _test_card_v2_round_trip(service: CCFFrontPorchExtensionServiceCurrent) -> bool:
	var source := CCFStorageService.new_project()
	var source_id := CCFStorageService.active_character_id(source)
	var card := CCFCardFormatService.export_character_v2(source, source_id)
	var data: Dictionary = card.get("data", {})
	data["world_names"] = ["Town", "Campus"]
	data["lore_world_names"] = []
	data["future_world_link"] = {"id": "future-1", "enabled": true}
	card["data"] = data
	var imported := CCFCardFormatService.import_card_to_project(card, "json")
	if not _require(bool(imported.get("ok", false)), "Extended V2 card must import."):
		return false
	var project: Dictionary = imported.get("project", {})
	var character_id := CCFStorageService.active_character_id(project)
	var document := CCFStorageService.character_workspace_document(project, character_id)
	if not _require(
		service.value_for(document, service.field_by_id("fp_world_names")) == ["Town", "Campus"]
		and service.is_included(document, service.field_by_id("fp_lore_world_names"))
		and service.value_for(document, service.field_by_id("fp_lore_world_names")) == [],
		"World names and explicit empty lore-world names must retain presence semantics."
	):
		return false
	var exported := CCFCardFormatService.export_character_v2(project, character_id)
	var exported_data: Dictionary = exported.get("data", {})
	return _require(
		exported_data.get("world_names", []) == ["Town", "Campus"]
		and exported_data.has("lore_world_names")
		and exported_data.get("lore_world_names") == []
		and exported_data.get("future_world_link", {}).get("id") == "future-1",
		"Known world links and unknown V2 data must round-trip losslessly."
	)


func _test_recovery_duration_normalisation() -> bool:
	var cases := [
		{"input": {"mode": "hard"}, "present": false, "value": -1},
		{"input": {"mode": "hard", "minutes": null}, "present": false, "value": -1},
		{"input": {"mode": "hard", "minutes": "invalid"}, "present": false, "value": -1},
		{"input": {"mode": "hard", "minutes": -1}, "present": false, "value": -1},
		{"input": {"mode": "hard", "minutes": 0}, "present": true, "value": 0},
		{"input": {"mode": "hard", "minutes": 30}, "present": true, "value": 30},
		{"input": {"mode": "hard", "minutes": 90}, "present": true, "value": 90},
		{"input": {"mode": "hard", "minutes": 180}, "present": true, "value": 180},
		{"input": {"mode": "hard", "minutes": 240}, "present": true, "value": 180}
	]
	for test_case in cases:
		var normalised := RAW_HIDE.normalise_recovery(test_case.get("input", {}))
		var recovery: Dictionary = normalised.get("value", {})
		var expected_present := bool(test_case.get("present", false))
		if not _require(
			bool(normalised.get("ok", false))
			and recovery.has("minutes") == expected_present
			and (
				not expected_present
				or int(recovery.get("minutes", -1)) == int(test_case.get("value", -1))
			),
			"Recovery duration case %s must match Rawhide null/clamp semantics."
			% JSON.stringify(test_case.get("input", {}))
		):
			return false
	var soft: Dictionary = RAW_HIDE.normalise_recovery(
		{"mode": "soft", "minutes": 90, "pcd": "rare"}
	).get("value", {})
	var default_recovery: Dictionary = RAW_HIDE.normalise_recovery(
		{"mode": "auto", "minutes": 30, "pcd": "off"}
	).get("value", {})
	return _require(
		not soft.has("minutes")
		and str(soft.get("pcd", "")) == "rare"
		and default_recovery.is_empty(),
		"Soft must drop duration and default Auto/Off must remain canonically omitted."
	)


func _test_recovery_editor_round_trip(
	service: CCFFrontPorchExtensionServiceCurrent
) -> bool:
	var source := CCFStorageService.new_project()
	var source_id := CCFStorageService.active_character_id(source)
	var card := CCFCardFormatService.export_character_v2(source, source_id)
	CCFStorageService.set_value_at_path(
		card,
		"data.extensions.front_porch.realism_engine.recovery",
		{"mode": "hard", "future_rule": {"enabled": true}}
	)
	var imported := CCFCardFormatService.import_card_to_project(card, "json")
	if not _require(bool(imported.get("ok", false)), "Hard/personality Recovery must import."):
		return false
	var project: Dictionary = imported.get("project", {})
	var character_id := CCFStorageService.active_character_id(project)
	var document := CCFStorageService.character_workspace_document(project, character_id)
	var field := service.field_by_id("fp_recovery")
	var control := RECOVERY_CONTROL.new()
	control.set_recovery_value(service.value_for(document, field))
	var duration := control.find_child("DurationMode", true, false) as OptionButton
	var minutes := control.find_child("FixedMinutes", true, false) as SpinBox
	var mode := control.find_child("RecoveryMode", true, false) as OptionButton
	if not _require(
		duration != null and minutes != null and mode != null
		and str(duration.get_selected_metadata()) == "personality"
		and not control.recovery_value().has("minutes")
		and control.recovery_value().get("future_rule", {}).get("enabled", false),
		"Hard Recovery without minutes must load as Personality decides and preserve unknown data."
	):
		control.free()
		return false
	var maps := _control_maps(service, document)
	var enabled: Dictionary = maps.enabled
	var values: Dictionary = maps.values
	enabled["fp_recovery"] = true
	values["fp_recovery"] = control.recovery_value()
	if not _apply_and_expect_minutes(
		service, project, document, character_id, enabled, values, false, -1,
		"Saving an untouched personality-determined duration must keep minutes absent."
	):
		control.free()
		return false
	duration.select(1)
	duration.item_selected.emit(1)
	minutes.value = 30
	values["fp_recovery"] = control.recovery_value()
	if not _apply_and_expect_minutes(
		service, project, document, character_id, enabled, values, true, 30,
		"Fixed duration must export the exact selected number."
	):
		control.free()
		return false
	duration.select(0)
	duration.item_selected.emit(0)
	values["fp_recovery"] = control.recovery_value()
	if not _apply_and_expect_minutes(
		service, project, document, character_id, enabled, values, false, -1,
		"Switching back to Personality decides must remove minutes."
	):
		control.free()
		return false
	mode.select(0)
	mode.item_selected.emit(0)
	if not _require(
		duration.disabled and not minutes.editable,
		"Auto Recovery must disable Hard-duration controls."
	):
		control.free()
		return false
	mode.select(2)
	mode.item_selected.emit(2)
	if not _require(
		duration.disabled and not minutes.editable,
		"Soft Recovery must disable Hard-duration controls."
	):
		control.free()
		return false
	control.free()
	return true


func _apply_and_expect_minutes(
	service: CCFFrontPorchExtensionServiceCurrent,
	project: Dictionary,
	document: Dictionary,
	character_id: String,
	enabled: Dictionary,
	values: Dictionary,
	expects_minutes: bool,
	expected_minutes: int,
	message: String
) -> bool:
	var applied := service.apply_control_values(document, enabled, values, true)
	CCFStorageService.update_character(project, document)
	var exported := CCFCardFormatService.export_character_v2(project, character_id)
	var recovery_value: Variant = CCFStorageService.get_value_at_path(
		exported, "data.extensions.front_porch.realism_engine.recovery", {}
	)
	var recovery: Dictionary = recovery_value if recovery_value is Dictionary else {}
	return _require(
		bool(applied.get("ok", false))
		and recovery.has("minutes") == expects_minutes
		and (not expects_minutes or int(recovery.get("minutes", -1)) == expected_minutes)
		and recovery.get("future_rule", {}).get("enabled", false),
		message
	)


func _test_group_lore_world_ids() -> bool:
	var project := CCFStorageService.new_project()
	var characters: Array = project.get("characters", [])
	var first: Dictionary = characters[0]
	first["character"]["name"] = "One"
	first["character"]["description"] = "First member."
	first["metadata"]["name"] = "One"
	characters[0] = first
	var second := CCFStorageService.new_character_record("Two")
	second["character"]["description"] = "Second member."
	characters.append(second)
	project["characters"] = characters
	var ids := [str(first.get("character_id", "")), str(second.get("character_id", ""))]
	var workflow := {
		"title": "World Test", "mode": "group_card", "selected_character_ids": ids,
		"shared_scenario": "A shared world.", "opening_message": "Hello."
	}
	var options := CCFFrontPorchGroupCardServiceV0174.default_group_options(project, workflow)
	options["lore_world_ids"] = []
	workflow["front_porch_group"] = options
	var explicit := CCFFrontPorchGroupCardServiceV0174.build_group_payload(project, workflow)
	if not _require(
		bool(explicit.get("ok", false))
		and explicit.get("payload", {}).has("lore_world_ids")
		and explicit.get("payload", {}).get("lore_world_ids") == [],
		"Group cards must preserve an explicit empty lore_world_ids list."
	):
		return false
	options["lore_world_ids"] = null
	workflow["front_porch_group"] = options
	var absent := CCFFrontPorchGroupCardServiceV0174.build_group_payload(project, workflow)
	return _require(
		bool(absent.get("ok", false)) and not absent.get("payload", {}).has("lore_world_ids"),
		"Group cards must preserve absent lore_world_ids as absent."
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
