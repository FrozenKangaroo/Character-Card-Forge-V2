class_name CCFFrontPorchWorkScheduleV0209
extends RefCounted

const RANGE_PATTERN := (
	"^(\\d{1,2})(?::(\\d{2}))?\\s*(a\\.?m\\.?|p\\.?m\\.?)?"
	+ "\\s*(?:[-–—]|\\s+to\\s+)\\s*"
	+ "(\\d{1,2})(?::(\\d{2}))?\\s*(a\\.?m\\.?|p\\.?m\\.?)?$"
)


static func normalise(raw_value: Variant) -> Dictionary:
	var start_text := ""
	var end_text := ""
	if raw_value is Dictionary:
		start_text = str((raw_value as Dictionary).get("start", "")).strip_edges()
		end_text = str((raw_value as Dictionary).get("end", "")).strip_edges()
		if start_text.is_empty() and end_text.is_empty():
			return {"ok": true, "value": "", "start": "", "end": ""}
		var start_minutes := _parse_clock_value(start_text)
		var end_minutes := _parse_clock_value(end_text)
		if start_minutes < 0 or end_minutes < 0:
			return {
				"ok": false,
				"error": "Set both Start and End using 24-hour HH:MM times."
			}
		return _result(start_minutes, end_minutes)

	var text := str(raw_value).strip_edges().to_lower()
	if text.is_empty():
		return {"ok": true, "value": "", "start": "", "end": ""}
	var expression := RegEx.new()
	if expression.compile(RANGE_PATTERN) != OK:
		return {"ok": false, "error": "The work-hours parser is unavailable."}
	var matched := expression.search(text)
	if matched == null:
		return {
			"ok": false,
			"error": "Use actual Start and End times, for example 09:00 and 17:00."
		}
	var start_minutes := _parts_to_minutes(
		matched.get_string(1), matched.get_string(2), matched.get_string(3)
	)
	var end_minutes := _parts_to_minutes(
		matched.get_string(4), matched.get_string(5), matched.get_string(6)
	)
	if start_minutes < 0 or end_minutes < 0:
		return {
			"ok": false,
			"error": "Use real clock times for both Start and End."
		}
	if (
		matched.get_string(3).is_empty()
		and matched.get_string(6).is_empty()
		and end_minutes <= start_minutes
		and end_minutes <= 12 * 60
		and start_minutes <= 12 * 60
	):
		end_minutes += 12 * 60
	return _result(start_minutes, end_minutes)


static func display_parts(raw_value: Variant) -> Dictionary:
	var parsed := normalise(raw_value)
	if not bool(parsed.get("ok", false)):
		return {
			"ok": false,
			"start": "",
			"end": "",
			"legacy": str(raw_value).strip_edges(),
			"error": str(parsed.get("error", "Invalid work hours."))
		}
	return parsed


static func _result(start_minutes: int, end_minutes: int) -> Dictionary:
	start_minutes = posmod(start_minutes, 24 * 60)
	end_minutes = posmod(end_minutes, 24 * 60)
	return {
		"ok": true,
		"value": "%s–%s" % [_front_porch_clock(start_minutes), _front_porch_clock(end_minutes)],
		"start": _twenty_four_hour_clock(start_minutes),
		"end": _twenty_four_hour_clock(end_minutes),
		"start_minutes": start_minutes,
		"end_minutes": end_minutes
	}


static func _parse_clock_value(value: String) -> int:
	var expression := RegEx.new()
	if expression.compile("^([01]?\\d|2[0-3]):([0-5]\\d)$") != OK:
		return -1
	var matched := expression.search(value.strip_edges())
	if matched == null:
		return -1
	return int(matched.get_string(1)) * 60 + int(matched.get_string(2))


static func _parts_to_minutes(
	hour_text: String, minute_text: String, meridiem_text: String
) -> int:
	if not hour_text.is_valid_int():
		return -1
	var hour := int(hour_text)
	var minute := 0 if minute_text.is_empty() else int(minute_text)
	if minute < 0 or minute > 59:
		return -1
	var meridiem := meridiem_text.replace(".", "").to_lower()
	if meridiem.is_empty():
		if hour < 0 or hour > 24 or (hour == 24 and minute != 0):
			return -1
		return (0 if hour == 24 else hour) * 60 + minute
	if hour < 1 or hour > 12:
		return -1
	if meridiem == "am":
		hour = 0 if hour == 12 else hour
	else:
		hour = 12 if hour == 12 else hour + 12
	return hour * 60 + minute


static func _front_porch_clock(minutes: int) -> String:
	var hour_24 := floori(float(minutes) / 60.0)
	var minute := minutes % 60
	var suffix := "am" if hour_24 < 12 else "pm"
	var hour_12 := hour_24 % 12
	if hour_12 == 0:
		hour_12 = 12
	if minute == 0:
		return "%d%s" % [hour_12, suffix]
	return "%d:%02d%s" % [hour_12, minute, suffix]


static func _twenty_four_hour_clock(minutes: int) -> String:
	return "%02d:%02d" % [floori(float(minutes) / 60.0), minutes % 60]
