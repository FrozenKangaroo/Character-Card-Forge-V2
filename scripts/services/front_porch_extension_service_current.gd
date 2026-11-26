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
const RAW_HIDE_POCKETS_PR708_COMMIT_V02117 := (
	"04f260783499728ffc93708132eb36900e280868"
)
const RAW_HIDE_AFTERGLOW_PR669_COMMIT_V02118 := (
	"756d1a33959036498a6657bc0d0989438654e2f4"
)
const AFTERGLOW_FIELD_ID_V02118 := "fp_afterglow_enabled"
const TRAIT_KIT_FIELD_ID_V02119 := "fp_trait_kit"
const TRAIT_KIT_MAX_ENTRIES_V02119 := 6
const TRAIT_KIT_MAX_BOGEYS_V02119 := 3
const TRAIT_KIT_KINDS_V02119 := ["boon", "bogey"]
const TRAIT_KIT_TIERS_V02119 := ["emerging", "developing", "established"]


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
	if str(field.get("type", "")) == "checkbox":
		# AI proposals and hand-typed values can arrive as booleans, numbers or
		# the strings "true"/"false". bool("false") is true in GDScript, so a
		# text boolean must be parsed explicitly instead of coerced.
		return _normalise_checkbox_value_v02118(field, raw_value)
	if field_id == "fp_needs_off":
		return RAW_HIDE_CHARACTER_V02116.normalise_needs_off(raw_value)
	if field_id == TRAIT_KIT_FIELD_ID_V02119:
		return normalise_trait_kit_v02119(raw_value)
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
	var trait_kit_field := field_by_id(TRAIT_KIT_FIELD_ID_V02119)
	if is_included(document, trait_kit_field):
		var kit_result := normalise_trait_kit_v02119(
			value_for(document, trait_kit_field)
		)
		if not bool(kit_result.get("ok", false)):
			errors.append(
				"Boons & Bogies: %s"
				% str(kit_result.get("error", "Invalid trait kit."))
			)
	validation["errors"] = errors
	validation["ok"] = errors.is_empty()
	return validation


func capabilities() -> Dictionary:
	var result := super.capabilities()
	# Report the running application version from project.godot instead of a
	# hand-maintained copy that silently went stale in earlier releases.
	result["version"] = str(
		ProjectSettings.get_setting("application/config/version", "0")
	)
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
	result["rawhide_pockets_pr708_commit"] = (
		RAW_HIDE_POCKETS_PR708_COMMIT_V02117
	)
	result["pockets_character_default_is_tristate"] = true
	result["rawhide_afterglow_pr669_commit"] = (
		RAW_HIDE_AFTERGLOW_PR669_COMMIT_V02118
	)
	result["afterglow_character_default_is_tristate"] = true
	result["afterglow_field_id"] = AFTERGLOW_FIELD_ID_V02118
	result["checkbox_values_accept_text_booleans"] = true
	result["trait_kit_field_id"] = TRAIT_KIT_FIELD_ID_V02119
	result["trait_kit_max_entries"] = TRAIT_KIT_MAX_ENTRIES_V02119
	result["trait_kit_max_bogeys"] = TRAIT_KIT_MAX_BOGEYS_V02119
	result["trait_kit_kinds"] = TRAIT_KIT_KINDS_V02119.duplicate()
	result["trait_kit_tiers"] = TRAIT_KIT_TIERS_V02119.duplicate()
	result["trait_kit_links_boons_by_text"] = true
	return result


func _normalise_checkbox_value_v02118(
	field: Dictionary, raw_value: Variant
) -> Dictionary:
	if raw_value is bool:
		return {"ok": true, "value": raw_value}
	if raw_value is int or raw_value is float:
		return {"ok": true, "value": float(raw_value) != 0.0}
	if raw_value is String:
		var text := (raw_value as String).strip_edges().to_lower()
		if text in ["true", "1", "yes", "on", "enabled"]:
			return {"ok": true, "value": true}
		if text in ["false", "0", "no", "off", "disabled"]:
			return {"ok": true, "value": false}
		return {
			"ok": false,
			"error": (
				"Use a true or false value for %s."
				% str(field.get("label", field.get("id", "this field")))
			)
		}
	if raw_value == null:
		# An absent proposal must not silently flip a checkbox off.
		return {
			"ok": false,
			"error": (
				"No value was proposed for %s."
				% str(field.get("label", field.get("id", "this field")))
			)
		}
	return {
		"ok": false,
		"error": (
			"Use a true or false value for %s."
			% str(field.get("label", field.get("id", "this field")))
		)
	}


func normalise_trait_kit_v02119(raw_value: Variant) -> Dictionary:
	# Front Porch docs/design/boons-and-bogies.md §4: at most six entries
	# combined, at most three bogeys, unique text, and `linkedTo` only on a
	# bogey, naming a boon's exact text. Unknown per-entry keys are preserved
	# so a later Front Porch field survives the round trip.
	if raw_value == null:
		return {"ok": true, "value": []}
	if not raw_value is Array:
		return {
			"ok": false,
			"error": "Expected a JSON array of boon and bogey entries."
		}
	var entries: Array = raw_value as Array
	if entries.size() > TRAIT_KIT_MAX_ENTRIES_V02119:
		return {
			"ok": false,
			"error": (
				"A card may carry at most %d boons and bogies combined; this has %d."
				% [TRAIT_KIT_MAX_ENTRIES_V02119, entries.size()]
			)
		}
	var result: Array = []
	var seen_texts := {}
	var bogey_count := 0
	for index in range(entries.size()):
		var raw_entry: Variant = entries[index]
		if not raw_entry is Dictionary:
			return {
				"ok": false,
				"error": "Entry %d must be a JSON object with kind, text and tier." % (index + 1)
			}
		var entry: Dictionary = raw_entry
		var kind := str(entry.get("kind", "")).strip_edges().to_lower()
		if kind not in TRAIT_KIT_KINDS_V02119:
			return {
				"ok": false,
				"error": (
					"Entry %d must be kind \"boon\" or \"bogey\"." % (index + 1)
				)
			}
		var text := str(entry.get("text", "")).strip_edges()
		if text.is_empty():
			return {
				"ok": false,
				"error": "Entry %d has no text." % (index + 1)
			}
		var text_key := text.to_lower()
		if seen_texts.has(text_key):
			return {
				"ok": false,
				"error": (
					"Entry %d repeats an earlier text; every boon and bogey must be unique."
					% (index + 1)
				)
			}
		seen_texts[text_key] = true
		var tier := str(entry.get("tier", "emerging")).strip_edges().to_lower()
		if tier not in TRAIT_KIT_TIERS_V02119:
			return {
				"ok": false,
				"error": (
					"Entry %d must use tier emerging, developing or established."
					% (index + 1)
				)
			}
		var pinned_result := _normalise_checkbox_value_v02118(
			{"label": "Pinned"}, entry.get("pinned", false)
		)
		if not bool(pinned_result.get("ok", false)):
			return {
				"ok": false,
				"error": (
					"Entry %d: %s" % [index + 1, str(pinned_result.get("error", ""))]
				)
			}
		if kind == "bogey":
			bogey_count += 1
		var clean: Dictionary = entry.duplicate(true)
		clean["kind"] = kind
		clean["text"] = text
		clean["tier"] = tier
		clean["pinned"] = bool(pinned_result.get("value", false))
		if entry.has("linkedTo"):
			if kind != "bogey":
				return {
					"ok": false,
					"error": (
						"Entry %d: only a bogey may link to a boon." % (index + 1)
					)
				}
			var link := str(entry.get("linkedTo", "")).strip_edges()
			if link.is_empty():
				clean.erase("linkedTo")
			else:
				clean["linkedTo"] = link
		result.append(clean)
	if bogey_count > TRAIT_KIT_MAX_BOGEYS_V02119:
		return {
			"ok": false,
			"error": (
				"A card may carry at most %d bogies; this has %d. Card bogies share "
				+ "the same three-flaw budget."
			) % [TRAIT_KIT_MAX_BOGEYS_V02119, bogey_count]
		}
	var boon_texts := {}
	for entry_value in result:
		var entry: Dictionary = entry_value
		if str(entry.get("kind", "")) == "boon":
			boon_texts[str(entry.get("text", ""))] = true
	for index in range(result.size()):
		var entry: Dictionary = result[index]
		if not entry.has("linkedTo"):
			continue
		if not boon_texts.has(str(entry.get("linkedTo", ""))):
			return {
				"ok": false,
				"error": (
					"Entry %d links to \"%s\", which is not one of this kit's boons."
					% [index + 1, str(entry.get("linkedTo", ""))]
				)
			}
	return {"ok": true, "value": result}


func _canonicalise_rawhide_omissions_v02116(document: Dictionary) -> void:
	var realism := _chaos_realism_v02116(document)
	if realism.get("needs_off", null) is Array and realism.get("needs_off", []).is_empty():
		realism.erase("needs_off")
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
