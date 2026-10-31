class_name CCFFrontPorchExtensionServiceCurrent
extends "res://scripts/services/front_porch_extension_service_v0172.gd"

const WORK_DAYS_V02111 = preload(
	"res://scripts/services/front_porch_work_days_v02111.gd"
)
const CHAOS_MODE_V02116 = preload(
	"res://scripts/services/front_porch_chaos_mode_v02116.gd"
)
const RAW_HIDE_CHARACTER_V02116 = preload(
	"res://scripts/services/front_porch_rawhide_character_v02116.gd"
)

const CHAOS_FIELD_ID_V02116 := "fp_chaos_mode"


func is_included(document: Dictionary, field: Dictionary) -> bool:
	if str(field.get("id", "")) != CHAOS_FIELD_ID_V02116:
		return super.is_included(document, field)
	return CHAOS_MODE_V02116.is_present(_chaos_realism_v02116(document))


func value_for(document: Dictionary, field: Dictionary) -> Variant:
	if str(field.get("id", "")) != CHAOS_FIELD_ID_V02116:
		return super.value_for(document, field)
	return CHAOS_MODE_V02116.mode_from_realism(_chaos_realism_v02116(document))


func apply_control_values(
	document: Dictionary,
	enabled_fields: Dictionary,
	values: Dictionary,
	adult_fields_unlocked: bool
) -> Dictionary:
	var result := super.apply_control_values(
		document, enabled_fields, values, adult_fields_unlocked
	)
	var included := bool(enabled_fields.get(CHAOS_FIELD_ID_V02116, false))
	var realism := _chaos_realism_v02116(document)
	var chaos_result := CHAOS_MODE_V02116.apply_mode(
		realism, included, values.get(CHAOS_FIELD_ID_V02116, "disabled")
	)
	if bool(chaos_result.get("ok", false)):
		_write_chaos_realism_v02116(document, realism)
	else:
		var errors: Array = result.get("errors", [])
		var chaos_error := (
			"Chaos Mode: %s"
			% str(chaos_result.get("error", "Invalid mode."))
		)
		if not errors.has(chaos_error):
			errors.append(chaos_error)
		result["errors"] = errors
	_canonicalise_rawhide_omissions_v02116(document)
	var validation := validate_document(document)
	var final_errors: Array = result.get("errors", [])
	for error_text in validation.get("errors", []):
		if not final_errors.has(str(error_text)):
			final_errors.append(str(error_text))
	var final_warnings: Array = result.get("warnings", [])
	for warning_text in validation.get("warnings", []):
		if not final_warnings.has(str(warning_text)):
			final_warnings.append(str(warning_text))
	result["errors"] = final_errors
	result["warnings"] = final_warnings
	result["ok"] = final_errors.is_empty()
	result["included_count"] = included_field_count(document)
	result["has_extension"] = _path_exists(
		document, "character.card_extensions.front_porch"
	)
	return result


func _normalise_value(field: Dictionary, raw_value: Variant) -> Dictionary:
	var field_id := str(field.get("id", ""))
	if field_id == "fp_needs_off":
		return RAW_HIDE_CHARACTER_V02116.normalise_needs_off(raw_value)
	if field_id == "fp_recovery":
		return RAW_HIDE_CHARACTER_V02116.normalise_recovery(raw_value)
	if field_id == "fp_needs_pace":
		var raw_pace := str(raw_value).strip_edges()
		var pace := raw_pace.to_lower()
		if raw_pace.is_empty():
			return {"ok": false, "error": "Choose a Needs pace."}
		return {"ok": true, "value": pace if pace in RAW_HIDE_CHARACTER_V02116.NEED_PACES else raw_pace}
	if field_id == "fp_sex":
		var raw_sex := str(raw_value).strip_edges()
		var sex := raw_sex.to_lower()
		if raw_sex.is_empty():
			return {"ok": false, "error": "Choose a Sex value."}
		return {"ok": true, "value": sex if sex in RAW_HIDE_CHARACTER_V02116.SEX_VALUES else raw_sex}
	if str(field.get("id", "")) == CHAOS_FIELD_ID_V02116:
		return CHAOS_MODE_V02116.normalise_control_value(raw_value)
	if str(field.get("id", "")) == "fp_work_days":
		return WORK_DAYS_V02111.normalise(raw_value)
	if str(field.get("id", "")) == "fp_work_hours":
		return CCFFrontPorchWorkScheduleV0209.normalise(raw_value)
	return super._normalise_value(field, raw_value)


func normalise_preview_value_v0209(
	field: Dictionary, raw_value: Variant
) -> Dictionary:
	var canonical := field_by_id(str(field.get("id", "")))
	if canonical.is_empty():
		canonical = field
	return _normalise_value(canonical, raw_value)


func normalise_generated_preview_value_v02116(
	field: Dictionary, raw_value: Variant
) -> Dictionary:
	var canonical := field_by_id(str(field.get("id", "")))
	if canonical.is_empty():
		canonical = field
	if str(canonical.get("type", "")) != "tags":
		return _normalise_value(canonical, raw_value)
	if not raw_value is Array:
		return {
			"ok": false,
			"error": (
				"Expected a JSON array of strings for %s; the model returned %s. "
				+ "The existing value was preserved. Edit each complete item explicitly or regenerate."
			) % [
				str(canonical.get("label", canonical.get("id", "this field"))),
				type_string(typeof(raw_value))
			]
		}
	var result: Array[String] = []
	for index in range((raw_value as Array).size()):
		var item: Variant = (raw_value as Array)[index]
		if not item is String:
			return {
				"ok": false,
				"error": (
					"Expected every %s item to be a JSON string; item %d was %s. "
					+ "The existing value was preserved."
				) % [
					str(canonical.get("label", canonical.get("id", "list"))),
					index + 1,
					type_string(typeof(item))
				]
			}
		var text := str(item).strip_edges()
		if not text.is_empty():
			result.append(text)
	return {"ok": true, "value": result}


func validate_document(document: Dictionary) -> Dictionary:
	var validation := super.validate_document(document)
	var errors: Array = validation.get("errors", [])
	var work_days_field := field_by_id("fp_work_days")
	if is_included(document, work_days_field):
		var parsed_days: Dictionary = WORK_DAYS_V02111.normalise(
			value_for(document, work_days_field)
		)
		if not bool(parsed_days.get("ok", false)):
			errors.append(
				"Work days: %s" % str(parsed_days.get("error", "Invalid work days."))
			)
	var work_hours_field := field_by_id("fp_work_hours")
	if is_included(document, work_hours_field):
		var parsed := CCFFrontPorchWorkScheduleV0209.normalise(
			value_for(document, work_hours_field)
		)
		if not bool(parsed.get("ok", false)):
			errors.append(
				"Work hours: %s" % str(parsed.get("error", "Invalid work hours."))
			)
	validation["errors"] = errors
	validation["ok"] = errors.is_empty()
	return validation


func capabilities() -> Dictionary:
	var result := super.capabilities()
	result["version"] = "0.21.16"
	result["typed_work_hours"] = true
	result["work_days_preview_normalisation"] = true
	result["work_days_tolerant_generation_formats"] = [
		"integer array", "comma-separated IDs", "day-name array",
		"day-name range", "weekdays", "weekends"
	]
	result["chaos_modes"] = CHAOS_MODE_V02116.ENABLED_MODES.duplicate()
	result["chaos_legacy_boolean_compatibility"] = true
	result["rawhide_schema_commit"] = RAW_HIDE_CHARACTER_V02116.RAW_HIDE_COMMIT
	result["needs_paces"] = RAW_HIDE_CHARACTER_V02116.NEED_PACES.duplicate()
	result["needs_off_keys"] = RAW_HIDE_CHARACTER_V02116.NEED_KEYS.duplicate()
	result["recovery_modes"] = RAW_HIDE_CHARACTER_V02116.RECOVERY_MODES.duplicate()
	result["pcd_modes"] = RAW_HIDE_CHARACTER_V02116.PCD_MODES.duplicate()
	return result


func _canonicalise_rawhide_omissions_v02116(document: Dictionary) -> void:
	var realism := _chaos_realism_v02116(document)
	if realism.get("needs_off", null) is Array and realism.get("needs_off", []).is_empty():
		realism.erase("needs_off")
	if bool(realism.get("pockets_enabled", false)):
		realism.erase("pockets_enabled")
	var recovery_value: Variant = realism.get("recovery", null)
	if recovery_value is Dictionary:
		var normalised := RAW_HIDE_CHARACTER_V02116.normalise_recovery(recovery_value)
		if bool(normalised.get("ok", false)):
			var recovery: Dictionary = normalised.get("value", {})
			if recovery.is_empty():
				realism.erase("recovery")
			else:
				realism["recovery"] = recovery
	_write_chaos_realism_v02116(document, realism)


func _chaos_realism_v02116(document: Dictionary) -> Dictionary:
	var value: Variant = CCFStorageService.get_value_at_path(
		document,
		"character.card_extensions.front_porch.realism_engine",
		{}
	)
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _write_chaos_realism_v02116(
	document: Dictionary, realism: Dictionary
) -> void:
	var extensions_value: Variant = CCFStorageService.get_value_at_path(
		document, "character.card_extensions", {}
	)
	var extensions: Dictionary = (
		(extensions_value as Dictionary).duplicate(true)
		if extensions_value is Dictionary else {}
	)
	var extension_value: Variant = extensions.get(EXTENSION_KEY, {})
	var extension: Dictionary = (
		(extension_value as Dictionary).duplicate(true)
		if extension_value is Dictionary else {}
	)
	if realism.is_empty():
		extension.erase(REALISM_KEY)
	else:
		extension[REALISM_KEY] = realism
		if not extension.has("version"):
			extension["version"] = TARGET_EXTENSION_VERSION
	var has_payload := false
	for raw_key in extension:
		if str(raw_key) != "version":
			has_payload = true
			break
	if has_payload:
		extensions[EXTENSION_KEY] = extension
	else:
		extensions.erase(EXTENSION_KEY)
	CCFStorageService.set_value_at_path(
		document, "character.card_extensions", extensions
	)
