class_name CCFIncrementalJSONStreamV02112
extends RefCounted

# Conservative incremental JSON framing for provider text deltas. This class never
# decides whether generated content is valid CCF data; it only emits top-level JSON
# units after Godot's JSON parser can parse the complete unit.

var _buffer := ""
var _scan_index := 0
var _root_kind := ""
var _root_start := -1
var _unit_start := -1
var _depth := 0
var _in_string := false
var _escaped := false
var _finished := false


func reset() -> void:
	_buffer = ""
	_scan_index = 0
	_root_kind = ""
	_root_start = -1
	_unit_start = -1
	_depth = 0
	_in_string = false
	_escaped = false
	_finished = false


func feed(delta: String) -> Dictionary:
	var result := {"items": [], "fields": [], "root_completed": false}
	if delta.is_empty() or _finished:
		return result
	_buffer += delta
	while _scan_index < _buffer.length():
		var character := _buffer.substr(_scan_index, 1)
		if _root_kind.is_empty():
			if character == "[" or character == "{":
				_root_kind = "array" if character == "[" else "object"
				_root_start = _scan_index
				_unit_start = _scan_index + 1
				_depth = 1
			_scan_index += 1
			continue

		if _in_string:
			if _escaped:
				_escaped = false
			elif character == "\\":
				_escaped = true
			elif character == "\"":
				_in_string = false
			_scan_index += 1
			continue

		if character == "\"":
			_in_string = true
			_scan_index += 1
			continue
		if character == "[" or character == "{":
			_depth += 1
			_scan_index += 1
			continue
		if character == "]" or character == "}":
			_depth -= 1
			if _depth == 0:
				_emit_unit(_unit_start, _scan_index, result)
				_finished = true
				result["root_completed"] = true
				result["root"] = _parse_root()
				_scan_index += 1
				break
			_scan_index += 1
			continue
		if character == "," and _depth == 1:
			_emit_unit(_unit_start, _scan_index, result)
			_unit_start = _scan_index + 1
		_scan_index += 1
	return result


func accumulated_text() -> String:
	return _buffer


func root_kind() -> String:
	return _root_kind


func is_complete() -> bool:
	return _finished


func _emit_unit(start_index: int, end_index: int, result: Dictionary) -> void:
	if start_index < 0 or end_index <= start_index:
		return
	var unit := _buffer.substr(start_index, end_index - start_index).strip_edges()
	if unit.is_empty():
		return
	if _root_kind == "array":
		var parsed_item = JSON.parse_string(unit)
		if parsed_item != null:
			(result["items"] as Array).append(parsed_item)
		return
	var parsed_field = JSON.parse_string("{%s}" % unit)
	if not parsed_field is Dictionary or parsed_field.size() != 1:
		return
	var key: String = str(parsed_field.keys()[0])
	(result["fields"] as Array).append({"name": key, "value": parsed_field[key]})


func _parse_root() -> Variant:
	if _root_start < 0 or _scan_index < _root_start:
		return null
	return JSON.parse_string(_buffer.substr(_root_start, _scan_index - _root_start + 1))
