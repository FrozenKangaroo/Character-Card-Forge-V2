class_name CCFFrontPorchExtensionServiceCurrent
extends "res://scripts/services/front_porch_extension_service_v0172.gd"


func _normalise_value(field: Dictionary, raw_value: Variant) -> Dictionary:
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


func validate_document(document: Dictionary) -> Dictionary:
	var validation := super.validate_document(document)
	var errors: Array = validation.get("errors", [])
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
	result["version"] = "0.20.9"
	result["typed_work_hours"] = true
	result["work_days_preview_normalisation"] = true
	return result
