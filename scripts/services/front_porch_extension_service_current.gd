class_name CCFFrontPorchExtensionServiceCurrent
extends "res://scripts/services/front_porch_extension_service_v0172.gd"

const WORK_DAYS_V02111 = preload(
	"res://scripts/services/front_porch_work_days_v02111.gd"
)


func _normalise_value(field: Dictionary, raw_value: Variant) -> Dictionary:
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
	result["version"] = "0.21.11"
	result["typed_work_hours"] = true
	result["work_days_preview_normalisation"] = true
	result["work_days_tolerant_generation_formats"] = [
		"integer array", "comma-separated IDs", "day-name array",
		"day-name range", "weekdays", "weekends"
	]
	return result
