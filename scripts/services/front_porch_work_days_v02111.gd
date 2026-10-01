class_name CCFFrontPorchWorkDaysV02111
extends RefCounted

const DAY_IDS := {
	"monday": 1, "mon": 1,
	"tuesday": 2, "tue": 2, "tues": 2,
	"wednesday": 3, "wed": 3,
	"thursday": 4, "thu": 4, "thur": 4, "thurs": 4,
	"friday": 5, "fri": 5,
	"saturday": 6, "sat": 6,
	"sunday": 7, "sun": 7
}


static func normalise(raw_value: Variant) -> Dictionary:
	var values: Array = []
	if raw_value is Array:
		values = raw_value
	elif (
		raw_value is PackedInt32Array
		or raw_value is PackedInt64Array
		or raw_value is PackedStringArray
	):
		values = Array(raw_value)
	elif raw_value is String:
		var text := str(raw_value).strip_edges().to_lower()
		text = text.replace("–", "-").replace("—", "-")
		if text == "weekdays":
			return {"ok": true, "value": [1, 2, 3, 4, 5]}
		if text == "weekends":
			return {"ok": true, "value": [6, 7]}
		var range_result := _parse_range(text)
		if bool(range_result.get("matched", false)):
			return range_result
		if text.contains(","):
			values = text.split(",", false)
		elif not text.is_empty():
			values = [text]
	else:
		return _error()
	if values.is_empty():
		return _error()
	var result: Array[int] = []
	for raw_day in values:
		var parsed := _day_id(raw_day)
		if parsed < 1:
			return _error()
		if parsed not in result:
			result.append(parsed)
	result.sort()
	return {"ok": true, "value": result}


static func _parse_range(text: String) -> Dictionary:
	var parts: PackedStringArray
	if text.contains(" to "):
		parts = text.split(" to ", false)
	elif text.contains("-"):
		parts = text.split("-", false)
	else:
		return {"matched": false}
	if parts.size() != 2:
		return {"matched": true, "ok": false, "error": _error_text()}
	var first := _day_id(parts[0])
	var last := _day_id(parts[1])
	if first < 1 or last < 1 or first > last:
		return {"matched": true, "ok": false, "error": _error_text()}
	var result: Array[int] = []
	for day in range(first, last + 1):
		result.append(day)
	return {"matched": true, "ok": true, "value": result}


static func _day_id(raw_day: Variant) -> int:
	if raw_day is float and raw_day != floor(raw_day):
		return -1
	if raw_day is int or raw_day is float:
		var number := int(raw_day)
		return number if number >= 1 and number <= 7 else -1
	var text := str(raw_day).strip_edges().to_lower()
	if text.is_valid_int():
		var number := int(text)
		return number if number >= 1 and number <= 7 else -1
	return int(DAY_IDS.get(text, -1))


static func _error() -> Dictionary:
	return {"ok": false, "error": _error_text()}


static func _error_text() -> String:
	return (
		"Use day IDs 1–7, exact day names, a clear inclusive range, "
		+ "weekdays, or weekends."
	)
