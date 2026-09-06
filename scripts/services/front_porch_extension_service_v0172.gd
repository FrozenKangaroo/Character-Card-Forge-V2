class_name CCFFrontPorchExtensionServiceV0172
extends RefCounted

const CATALOG_PATH := "res://data/front_porch_fields_v0172.json"
const EXTENSION_KEY := "front_porch"
const REALISM_KEY := "realism_engine"
const TARGET_EXTENSION_VERSION := "2.5"
const CONTRACT_VERSION := 1

var _catalog: Dictionary = {}


func _init() -> void:
	_catalog = _load_catalog()


func groups() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_group in _catalog.get("groups", []):
		if raw_group is Dictionary:
			result.append((raw_group as Dictionary).duplicate(true))
	return result


func all_fields() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for group in groups():
		for raw_field in group.get("fields", []):
			if raw_field is Dictionary:
				var field := (raw_field as Dictionary).duplicate(true)
				field["group_id"] = str(group.get("id", ""))
				field["group_label"] = str(group.get("label", "Front Porch"))
				field["path"] = full_project_path(field)
				result.append(field)
	return result


func greeting_seed_fields() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_field in _catalog.get("greeting_seed_fields", []):
		if raw_field is Dictionary:
			result.append((raw_field as Dictionary).duplicate(true))
	return result


func fields_for_group(group_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for field in all_fields():
		if str(field.get("group_id", "")) == group_id:
			result.append(field)
	return result


func field_by_id(field_id: String) -> Dictionary:
	for field in all_fields():
		if str(field.get("id", "")) == field_id:
			return field
	return {}


func full_project_path(field: Dictionary) -> String:
	var card_path := str(field.get("card_path", "")).strip_edges()
	if not card_path.is_empty():
		return card_path
	var key_path := str(field.get("key_path", "")).strip_edges()
	if key_path.is_empty():
		return ""
	return "character.card_extensions.%s.%s.%s" % [
		EXTENSION_KEY, REALISM_KEY, key_path
	]


func is_included(document: Dictionary, field: Dictionary) -> bool:
	return _path_exists(document, full_project_path(field))


func value_for(document: Dictionary, field: Dictionary) -> Variant:
	var default_value: Variant = field.get("default", "")
	if default_value is Dictionary or default_value is Array:
		default_value = default_value.duplicate(true)
	var value: Variant = CCFStorageService.get_value_at_path(
		document, full_project_path(field), default_value
	)
	if str(field.get("type", "")) == "color_value" and value is int:
		return str(value)
	return value


func apply_control_values(
	document: Dictionary,
	enabled_fields: Dictionary,
	values: Dictionary,
	adult_fields_unlocked: bool
) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var character_value: Variant = document.get("character", {})
	var character: Dictionary = (
		(character_value as Dictionary).duplicate(true)
		if character_value is Dictionary
		else {}
	)
	var extensions_value: Variant = character.get("card_extensions", {})
	var extensions: Dictionary = (
		(extensions_value as Dictionary).duplicate(true)
		if extensions_value is Dictionary
		else {}
	)
	var extension_value: Variant = extensions.get(EXTENSION_KEY, {})
	var extension: Dictionary = (
		(extension_value as Dictionary).duplicate(true)
		if extension_value is Dictionary
		else {}
	)
	var realism_value: Variant = extension.get(REALISM_KEY, {})
	var realism: Dictionary = (
		(realism_value as Dictionary).duplicate(true)
		if realism_value is Dictionary
		else {}
	)

	for field in all_fields():
		var field_id := str(field.get("id", ""))
		var is_adult := bool(field.get("adult", false))
		if is_adult and not adult_fields_unlocked:
			# Hidden adult data is preserved until the author explicitly unlocks it.
			continue
		var enabled := bool(enabled_fields.get(field_id, false))
		var card_path := str(field.get("card_path", "")).strip_edges()
		if not card_path.is_empty():
			if enabled:
				var normalised_card := _normalise_value(field, values.get(field_id))
				if bool(normalised_card.get("ok", false)):
					_set_nested(character, card_path.trim_prefix("character."), normalised_card.get("value"))
				else:
					errors.append("%s: %s" % [str(field.get("label", field_id)), str(normalised_card.get("error", "Invalid value."))])
			else:
				_erase_nested(character, card_path.trim_prefix("character."))
			continue

		var key_path := str(field.get("key_path", ""))
		if enabled:
			var normalised := _normalise_value(field, values.get(field_id))
			if bool(normalised.get("ok", false)):
				_set_nested(realism, key_path, normalised.get("value"))
			else:
				errors.append("%s: %s" % [str(field.get("label", field_id)), str(normalised.get("error", "Invalid value."))])
		else:
			_erase_nested(realism, key_path)

	if not realism.is_empty():
		extension[REALISM_KEY] = realism
		if not extension.has("version"):
			extension["version"] = TARGET_EXTENSION_VERSION
	else:
		extension.erase(REALISM_KEY)

	var has_extension_payload := false
	for raw_key in extension:
		if str(raw_key) != "version":
			has_extension_payload = true
			break
	if has_extension_payload:
		extensions[EXTENSION_KEY] = extension
	else:
		extensions.erase(EXTENSION_KEY)
	character["card_extensions"] = extensions
	document["character"] = character

	var validation := validate_document(document)
	for error_text in validation.get("errors", []):
		if not errors.has(str(error_text)):
			errors.append(str(error_text))
	for warning_text in validation.get("warnings", []):
		warnings.append(str(warning_text))
	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"included_count": included_field_count(document),
		"has_extension": extensions.has(EXTENSION_KEY)
	}


func included_field_count(document: Dictionary) -> int:
	var count := 0
	for field in all_fields():
		if is_included(document, field):
			count += 1
	return count


func greeting_seeds(document: Dictionary) -> Array:
	var value: Variant = CCFStorageService.get_value_at_path(
		document,
		"character.card_extensions.%s.%s.greeting_seeds" % [
			EXTENSION_KEY, REALISM_KEY
		],
		[]
	)
	return value.duplicate(true) if value is Array else []


func greeting_seed_field_included(
	document: Dictionary, greeting_index: int, field: Dictionary
) -> bool:
	var seeds := greeting_seeds(document)
	if greeting_index < 0 or greeting_index >= seeds.size():
		return false
	var seed_value: Variant = seeds[greeting_index]
	return (
		seed_value is Dictionary
		and _path_exists(seed_value as Dictionary, str(field.get("key_path", "")))
	)


func greeting_seed_value(
	document: Dictionary, greeting_index: int, field: Dictionary
) -> Variant:
	var default_value: Variant = field.get("default", "")
	if default_value is Array or default_value is Dictionary:
		default_value = default_value.duplicate(true)
	var seeds := greeting_seeds(document)
	if greeting_index < 0 or greeting_index >= seeds.size():
		return default_value
	var seed_value: Variant = seeds[greeting_index]
	if not seed_value is Dictionary:
		return default_value
	return CCFStorageService.get_value_at_path(
		seed_value as Dictionary,
		str(field.get("key_path", "")),
		default_value
	)


func apply_greeting_seed_values(
	document: Dictionary,
	greeting_index: int,
	seed_enabled: bool,
	enabled_fields: Dictionary,
	values: Dictionary
) -> Dictionary:
	var errors: Array[String] = []
	var extensions_value: Variant = CCFStorageService.get_value_at_path(
		document, "character.card_extensions", {}
	)
	var extensions: Dictionary = (
		(extensions_value as Dictionary).duplicate(true)
		if extensions_value is Dictionary
		else {}
	)
	var extension_value: Variant = extensions.get(EXTENSION_KEY, {})
	var extension: Dictionary = (
		(extension_value as Dictionary).duplicate(true)
		if extension_value is Dictionary
		else {}
	)
	var realism_value: Variant = extension.get(REALISM_KEY, {})
	var realism: Dictionary = (
		(realism_value as Dictionary).duplicate(true)
		if realism_value is Dictionary
		else {}
	)
	var seeds_value: Variant = realism.get("greeting_seeds", [])
	var seeds: Array = seeds_value.duplicate(true) if seeds_value is Array else []
	while seeds.size() <= greeting_index:
		seeds.append(null)
	if not seed_enabled:
		seeds[greeting_index] = null
	else:
		var existing_seed_value: Variant = seeds[greeting_index]
		var seed: Dictionary = (
			(existing_seed_value as Dictionary).duplicate(true)
			if existing_seed_value is Dictionary
			else {}
		)
		for field in greeting_seed_fields():
			var field_id := str(field.get("id", ""))
			var key_path := str(field.get("key_path", ""))
			if bool(enabled_fields.get(field_id, false)):
				var normalised := _normalise_value(field, values.get(field_id))
				if bool(normalised.get("ok", false)):
					_set_nested(seed, key_path, normalised.get("value"))
				else:
					errors.append("%s: %s" % [str(field.get("label", field_id)), str(normalised.get("error", "Invalid value."))])
			else:
				_erase_nested(seed, key_path)
		seeds[greeting_index] = seed
	while not seeds.is_empty() and seeds[-1] == null:
		seeds.pop_back()
	if seeds.is_empty():
		realism.erase("greeting_seeds")
	else:
		realism["greeting_seeds"] = seeds
	if realism.is_empty():
		extension.erase(REALISM_KEY)
	else:
		extension[REALISM_KEY] = realism
		if not extension.has("version"):
			extension["version"] = TARGET_EXTENSION_VERSION
	var has_extension_payload := false
	for raw_key in extension:
		if str(raw_key) != "version":
			has_extension_payload = true
			break
	if has_extension_payload:
		extensions[EXTENSION_KEY] = extension
	else:
		extensions.erase(EXTENSION_KEY)
	CCFStorageService.set_value_at_path(
		document, "character.card_extensions", extensions
	)
	return {"ok": errors.is_empty(), "errors": errors, "seed_count": seeds.size()}


func validate_document(document: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var birthday_field := field_by_id("fp_birthday")
	if is_included(document, birthday_field):
		var birthday := str(value_for(document, birthday_field)).strip_edges()
		if not birthday.is_empty() and not _valid_iso_date(birthday, false):
			errors.append("Birthday must be a valid YYYY-MM-DD date; February 29 is not supported by Front Porch.")
	var story_date_field := field_by_id("fp_story_start_date")
	if is_included(document, story_date_field):
		var story_date := str(value_for(document, story_date_field)).strip_edges()
		if not story_date.is_empty() and not _valid_iso_date(story_date, true):
			errors.append("Story start date must be a valid YYYY-MM-DD date.")
	var story_time_field := field_by_id("fp_story_start_time")
	if is_included(document, story_time_field):
		var story_time := str(value_for(document, story_time_field)).strip_edges()
		if not story_time.is_empty() and not _valid_story_time(story_time):
			errors.append("Story start time must use 24-hour HH:MM format.")
	for inventory_id in ["fp_inventory_worn", "fp_inventory_carrying"]:
		var inventory_field := field_by_id(inventory_id)
		if is_included(document, inventory_field):
			var inventory_value: Variant = value_for(document, inventory_field)
			if inventory_value is Array and inventory_value.size() > 8:
				warnings.append("%s has more than Front Porch's eight-item starting limit." % str(inventory_field.get("label", "Inventory")))
	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings}


func generation_fields(
	group_id: String,
	enabled_only: bool,
	enabled_fields: Dictionary,
	adult_fields_unlocked: bool
) -> Array[Dictionary]:
	var source := all_fields() if group_id.is_empty() else fields_for_group(group_id)
	var result: Array[Dictionary] = []
	for field in source:
		if not bool(field.get("generate", false)):
			continue
		if bool(field.get("adult", false)) and not adult_fields_unlocked:
			continue
		if enabled_only and not bool(enabled_fields.get(str(field.get("id", "")), false)):
			continue
		result.append(field)
	return result


func capabilities() -> Dictionary:
	return {
		"version": "0.17.2",
		"contract_version": CONTRACT_VERSION,
		"catalog_format_version": int(_catalog.get("format_version", 0)),
		"front_porch_extension_version": str(_catalog.get("front_porch_extension_version", TARGET_EXTENSION_VERSION)),
		"extension_key": EXTENSION_KEY,
		"optional_fields": true,
		"manual_authoring": true,
		"selective_ai_review": true,
		"unknown_field_round_trip": true,
		"adult_opt_in": true,
		"raw_database_writes": false,
		"field_count": all_fields().size(),
		"group_count": groups().size(),
		"greeting_seed_field_count": greeting_seed_fields().size(),
		"alternative_greeting_seeds": true
	}


func _normalise_value(field: Dictionary, raw_value: Variant) -> Dictionary:
	var field_type := str(field.get("type", "line"))
	match field_type:
		"tags":
			return {"ok": true, "value": _normalise_string_array(raw_value)}
		"integer_tags":
			var integers: Array[int] = []
			var source: Array = _variant_items(raw_value)
			var minimum := int(field.get("minimum", -2147483648))
			var maximum := int(field.get("maximum", 2147483647))
			for item in source:
				var text := str(item).strip_edges()
				if not text.is_valid_int():
					return {"ok": false, "error": "Use comma-separated whole numbers."}
				var number := int(text)
				if number < minimum or number > maximum:
					return {"ok": false, "error": "Values must be between %d and %d." % [minimum, maximum]}
				if not integers.has(number):
					integers.append(number)
			integers.sort()
			return {"ok": true, "value": integers}
		"number":
			var number_value := float(raw_value)
			number_value = clampf(number_value, float(field.get("minimum", number_value)), float(field.get("maximum", number_value)))
			return {"ok": true, "value": int(round(number_value))}
		"checkbox":
			return {"ok": true, "value": bool(raw_value)}
		"color_value":
			var color_text := str(raw_value).strip_edges()
			if color_text.is_empty():
				return {"ok": false, "error": "Enter an ARGB hex colour or integer, or turn Include off."}
			if color_text.is_valid_int():
				return {"ok": true, "value": int(color_text)}
			var clean_hex := color_text.trim_prefix("#")
			if clean_hex.length() in [6, 8] and clean_hex.is_valid_hex_number(false):
				if clean_hex.length() == 6:
					clean_hex = "FF" + clean_hex
				return {"ok": true, "value": clean_hex.hex_to_int()}
			return {"ok": false, "error": "Use #RRGGBB, #AARRGGBB or a decimal ARGB integer."}
		_:
			var text_value := str(raw_value).strip_edges()
			var key_path := str(field.get("key_path", ""))
			if key_path == "birthday" and not text_value.is_empty():
				if not _valid_iso_date(text_value, false):
					return {"ok": false, "error": "Use a valid YYYY-MM-DD date; February 29 is not supported."}
			if key_path == "story_start_date" and not text_value.is_empty():
				if not _valid_iso_date(text_value, true):
					return {"ok": false, "error": "Use a valid YYYY-MM-DD date."}
			if key_path == "story_start_time" and not text_value.is_empty():
				if not _valid_story_time(text_value):
					return {"ok": false, "error": "Use 24-hour HH:MM format."}
			return {"ok": true, "value": text_value}


func _normalise_string_array(raw_value: Variant) -> Array[String]:
	var source: Array = _variant_items(raw_value)
	var result: Array[String] = []
	for item in source:
		var text := str(item).strip_edges()
		if not text.is_empty() and not result.has(text):
			result.append(text)
	return result


func _variant_items(raw_value: Variant) -> Array:
	if raw_value is Array:
		return (raw_value as Array).duplicate(true)
	var result: Array = []
	if raw_value is PackedStringArray:
		for item in raw_value as PackedStringArray:
			result.append(item)
		return result
	for item in str(raw_value).split(",", false):
		result.append(item)
	return result


func _path_exists(data: Dictionary, path: String) -> bool:
	var current: Variant = data
	for part in path.split(".", false):
		if not current is Dictionary or not (current as Dictionary).has(part):
			return false
		current = (current as Dictionary).get(part)
	return true


func _set_nested(data: Dictionary, path: String, value: Variant) -> void:
	var parts := path.split(".", false)
	if parts.is_empty():
		return
	var current := data
	for index in range(parts.size() - 1):
		var key := parts[index]
		if not current.has(key) or not current.get(key) is Dictionary:
			current[key] = {}
		current = current[key]
	current[parts[-1]] = value.duplicate(true) if value is Dictionary or value is Array else value


func _erase_nested(data: Dictionary, path: String) -> void:
	var parts := path.split(".", false)
	if parts.is_empty():
		return
	_erase_nested_parts(data, parts, 0)


func _erase_nested_parts(data: Dictionary, parts: PackedStringArray, index: int) -> bool:
	var key := parts[index]
	if not data.has(key):
		return data.is_empty()
	if index == parts.size() - 1:
		data.erase(key)
		return data.is_empty()
	var child_value: Variant = data.get(key)
	if not child_value is Dictionary:
		return data.is_empty()
	var child := (child_value as Dictionary).duplicate(true)
	var child_empty := _erase_nested_parts(child, parts, index + 1)
	if child_empty:
		data.erase(key)
	else:
		data[key] = child
	return data.is_empty()


func _valid_iso_date(value: String, allow_february_29: bool) -> bool:
	var expression := RegEx.new()
	expression.compile("^(\\d{4})-(\\d{2})-(\\d{2})$")
	var match_value := expression.search(value)
	if match_value == null:
		return false
	var year := int(match_value.get_string(1))
	var month := int(match_value.get_string(2))
	var day := int(match_value.get_string(3))
	if month < 1 or month > 12 or day < 1:
		return false
	var days := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	var leap := year % 400 == 0 or (year % 4 == 0 and year % 100 != 0)
	if month == 2 and leap:
		days[1] = 29
	if day > int(days[month - 1]):
		return false
	return allow_february_29 or not (month == 2 and day == 29)


func _valid_story_time(value: String) -> bool:
	var expression := RegEx.new()
	expression.compile("^([01]\\d|2[0-3]):[0-5]\\d$")
	return expression.search(value) != null


func _load_catalog() -> Dictionary:
	if not FileAccess.file_exists(CATALOG_PATH):
		push_error("Front Porch v0.17.2 field catalog is missing.")
		return {"format_version": 0, "groups": []}
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("Front Porch v0.17.2 field catalog could not be opened.")
		return {"format_version": 0, "groups": []}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Front Porch v0.17.2 field catalog is not valid JSON.")
		return {"format_version": 0, "groups": []}
	return (parsed as Dictionary).duplicate(true)
