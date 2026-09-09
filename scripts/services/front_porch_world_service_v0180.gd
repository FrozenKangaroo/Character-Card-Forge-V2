class_name CCFFrontPorchWorldServiceV0180
extends RefCounted

const PROJECT_KEY := "front_porch_worlds"
const FORMAT_VERSION := 1
const CATALOG_PATH := "res://data/front_porch_world_biomes_v0180.json"
const MAX_COVER_EDGE := 1024
const COVER_SOFT_LIMIT_BYTES := 350 * 1024


static func capabilities() -> Dictionary:
	return {
		"fpworld_format_version": FORMAT_VERSION,
		"lossless_unknown_fields": true,
		"bare_lorebook_import": true,
		"climate_authoring": true,
		"stoop_metadata": true,
		"explicit_privacy_review": true,
		"direct_stoop_publish": false,
		"network_calls": false,
		"raw_database_writes": false
	}


static func new_world_record(world_name: String = "Untitled World") -> Dictionary:
	var clean_name := world_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "Untitled World"
	var world_id := _new_uuid()
	var now := Time.get_datetime_string_from_system(true)
	return {
		"world_id": world_id,
		"package": {
			"formatVersion": FORMAT_VERSION,
			"id": world_id,
			"name": clean_name,
			"description": "",
			"lorebook": {"name": clean_name, "entries": []},
			"lorebooks": [{"name": clean_name, "entries": []}],
			"climate_enabled": true,
			"biome": _biome_by_id("temperate"),
			"place_traits": {"atmosphere": "breathable", "gravity": "earth"},
			"meta": {
				"author": "",
				"createdAt": now,
				"appVersion": "Character Card Forge 0.18.0",
				"sourceId": world_id
			}
		},
		"publishing": {
			"summary": "",
			"creator": "",
			"original_creator": "",
			"tags": [],
			"adult_content": false,
			"comments_enabled": true,
			"stable_update_identity": world_id
		},
		"provenance": {"source_path": "", "imported_at": "", "updated_at": now}
	}


static func worlds_for_project(project: Dictionary) -> Array:
	var value: Variant = project.get(PROJECT_KEY, [])
	return value.duplicate(true) if value is Array else []


static func upsert_world(project: Dictionary, record: Dictionary) -> Dictionary:
	var result := project.duplicate(true)
	var worlds := worlds_for_project(result)
	var clean := _normalise_record(record)
	var target_id := str(clean.get("world_id", ""))
	var replaced := false
	for index in range(worlds.size()):
		if worlds[index] is Dictionary and str(worlds[index].get("world_id", "")) == target_id:
			worlds[index] = clean
			replaced = true
			break
	if not replaced:
		worlds.append(clean)
	result[PROJECT_KEY] = worlds
	return result


static func remove_world(project: Dictionary, world_id: String) -> Dictionary:
	var result := project.duplicate(true)
	var kept: Array = []
	for value in worlds_for_project(result):
		if value is Dictionary and str(value.get("world_id", "")) != world_id:
			kept.append(value.duplicate(true))
	result[PROJECT_KEY] = kept
	return result


static func import_fpworld(project: Dictionary, path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not open the selected .fpworld file."}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {"ok": false, "error": "The selected file does not contain a JSON object."}
	var package: Dictionary = parsed.duplicate(true)
	var is_envelope := (
		package.has("formatVersion")
		or (package.has("id") and package.has("name") and (package.has("lorebook") or package.has("lorebooks")))
	)
	if not is_envelope and package.has("entries"):
		var fallback_name := path.get_file().get_basename()
		var record := new_world_record(fallback_name)
		record["package"] = {
			"formatVersion": 0,
			"id": str(record.get("world_id", "")),
			"name": str(package.get("name", fallback_name)),
			"description": "",
			"lorebook": package.duplicate(true),
			"lorebooks": [package.duplicate(true)],
			"climate_enabled": true,
			"meta": {"sourceId": str(record.get("world_id", ""))}
		}
		return _finish_import(project, record, path)
	var validation := validate_package(package)
	if not bool(validation.get("ok", false)):
		return {"ok": false, "error": "\n".join(validation.get("errors", [])), "validation": validation}
	var imported_record := new_world_record(str(package.get("name", "Imported World")))
	imported_record["package"] = package.duplicate(true)
	var package_meta: Variant = package.get("meta", {})
	var meta: Dictionary = package_meta if package_meta is Dictionary else {}
	var publishing: Dictionary = imported_record.get("publishing", {})
	publishing["creator"] = str(meta.get("author", ""))
	publishing["stable_update_identity"] = str(meta.get("sourceId", package.get("id", "")))
	imported_record["publishing"] = publishing
	return _finish_import(project, imported_record, path)


static func export_fpworld(record: Dictionary, path: String) -> Dictionary:
	var clean := _normalise_record(record)
	var package: Dictionary = clean.get("package", {}).duplicate(true)
	var validation := validate_package(package)
	if not bool(validation.get("ok", false)):
		return {"ok": false, "error": "\n".join(validation.get("errors", [])), "validation": validation}
	var destination := path if path.to_lower().ends_with(".fpworld") else path + ".fpworld"
	var file := FileAccess.open(destination, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not write the selected .fpworld destination."}
	file.store_string(JSON.stringify(package, "  ") + "\n")
	return {"ok": true, "path": destination, "validation": validation}


static func validate_package(package: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	if str(package.get("name", "")).strip_edges().is_empty():
		errors.append("World name is required.")
	var has_single := package.get("lorebook", null) is Dictionary
	var has_many := package.get("lorebooks", null) is Array
	if not has_single and not has_many:
		errors.append("A lorebook object or lorebooks array is required.")
	if has_many and (package.get("lorebooks", []) as Array).is_empty():
		errors.append("The lorebooks array cannot be empty.")
	if package.has("biome") and not package.get("biome") is Dictionary:
		errors.append("Biome must be a JSON object.")
	if package.has("place_traits") and not package.get("place_traits") is Dictionary:
		errors.append("Place traits must be a JSON object.")
	var version := int(package.get("formatVersion", 0))
	if version > FORMAT_VERSION:
		warnings.append("This package uses future .fpworld format version %d; unknown fields will be preserved." % version)
	if not bool(package.get("climate_enabled", true)) and (package.has("biome") or package.has("place_traits")):
		warnings.append("Climate is disabled; Front Porch may ignore the preserved biome and place traits.")
	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings}


static func apply_editor_fields(record: Dictionary, fields: Dictionary) -> Dictionary:
	var result := _normalise_record(record)
	var package: Dictionary = result.get("package", {}).duplicate(true)
	for key in ["name", "description", "cover", "climate_enabled", "biome", "place_traits", "lorebook", "lorebooks"]:
		if fields.has(key):
			if key == "cover" and str(fields.get(key, "")).strip_edges().is_empty():
				package.erase("cover")
			else:
				package[key] = _copy(fields[key])
	if fields.has("id"):
		package["id"] = str(fields.get("id", ""))
	var publishing: Dictionary = result.get("publishing", {}).duplicate(true)
	var publishing_value: Variant = fields.get("publishing", {})
	if publishing_value is Dictionary:
		publishing.merge(publishing_value, true)
	publishing["tags"] = _string_array(publishing.get("tags", []))
	result["publishing"] = publishing
	var meta_value: Variant = package.get("meta", {})
	var meta: Dictionary = meta_value.duplicate(true) if meta_value is Dictionary else {}
	if not str(publishing.get("creator", "")).strip_edges().is_empty():
		meta["author"] = str(publishing.get("creator", "")).strip_edges()
	var stable_id := str(publishing.get("stable_update_identity", "")).strip_edges()
	if stable_id.is_empty():
		stable_id = str(package.get("id", result.get("world_id", "")))
	meta["sourceId"] = stable_id
	meta["appVersion"] = "Character Card Forge 0.18.0"
	package["meta"] = meta
	result["package"] = package
	result["provenance"]["updated_at"] = Time.get_datetime_string_from_system(true)
	return result


static func stoop_readiness(record: Dictionary) -> Dictionary:
	var clean := _normalise_record(record)
	var package: Dictionary = clean.get("package", {})
	var publishing: Dictionary = clean.get("publishing", {})
	var missing: Array[String] = []
	if str(package.get("name", "")).strip_edges().is_empty():
		missing.append("world name")
	if str(publishing.get("summary", "")).strip_edges().is_empty():
		missing.append("publishing summary")
	if str(package.get("cover", "")).strip_edges().is_empty():
		missing.append("cover image")
	if str(publishing.get("stable_update_identity", "")).strip_edges().is_empty():
		missing.append("stable update identity")
	return {
		"ready": missing.is_empty(),
		"missing": missing,
		"adult_content": bool(publishing.get("adult_content", false)),
		"requires_private_context_review": true,
		"requires_adult_declaration_review": bool(publishing.get("adult_content", false)),
		"direct_publish_available": false
	}


static func cover_data_url_from_image(path: String) -> Dictionary:
	var source := Image.load_from_file(path)
	if source == null or source.is_empty():
		return {"ok": false, "error": "The selected cover image could not be decoded."}
	var longest := maxi(source.get_width(), source.get_height())
	if longest > MAX_COVER_EDGE:
		var scale := float(MAX_COVER_EDGE) / float(longest)
		source.resize(maxi(1, roundi(source.get_width() * scale)), maxi(1, roundi(source.get_height() * scale)), Image.INTERPOLATE_LANCZOS)
	source.convert(Image.FORMAT_RGB8)
	var quality := 0.86
	var encoded := source.save_jpg_to_buffer(quality)
	while encoded.size() > COVER_SOFT_LIMIT_BYTES and quality > 0.52:
		quality -= 0.08
		encoded = source.save_jpg_to_buffer(quality)
	while encoded.size() > COVER_SOFT_LIMIT_BYTES and maxi(source.get_width(), source.get_height()) > 480:
		source.resize(maxi(1, roundi(source.get_width() * 0.82)), maxi(1, roundi(source.get_height() * 0.82)), Image.INTERPOLATE_LANCZOS)
		encoded = source.save_jpg_to_buffer(0.70)
	return {
		"ok": true,
		"data_url": "data:image/jpeg;base64,%s" % Marshalls.raw_to_base64(encoded),
		"byte_size": encoded.size(),
		"width": source.get_width(),
		"height": source.get_height()
	}


static func catalog() -> Dictionary:
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return {"biomes": [], "place_traits": {}}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {"biomes": [], "place_traits": {}}


static func _finish_import(project: Dictionary, record: Dictionary, path: String) -> Dictionary:
	record = _normalise_record(record)
	record["provenance"]["source_path"] = path
	record["provenance"]["imported_at"] = Time.get_datetime_string_from_system(true)
	var result_project := upsert_world(project, record)
	return {"ok": true, "project": result_project, "record": record, "validation": validate_package(record.get("package", {}))}


static func _normalise_record(record: Dictionary) -> Dictionary:
	var fallback := new_world_record()
	var result := record.duplicate(true)
	var package_value: Variant = result.get("package", {})
	if not package_value is Dictionary:
		package_value = fallback.get("package", {}).duplicate(true)
	result["package"] = package_value
	var package: Dictionary = result["package"]
	var world_id := str(result.get("world_id", package.get("id", ""))).strip_edges()
	if world_id.is_empty():
		world_id = _new_uuid()
	result["world_id"] = world_id
	if not package.has("id"):
		package["id"] = world_id
	if not package.has("climate_enabled"):
		package["climate_enabled"] = true
	result["package"] = package
	var publishing_value: Variant = result.get("publishing", {})
	var publishing: Dictionary = fallback.get("publishing", {}).duplicate(true)
	if publishing_value is Dictionary:
		publishing.merge(publishing_value, true)
	publishing["tags"] = _string_array(publishing.get("tags", []))
	result["publishing"] = publishing
	var provenance_value: Variant = result.get("provenance", {})
	var provenance: Dictionary = fallback.get("provenance", {}).duplicate(true)
	if provenance_value is Dictionary:
		provenance.merge(provenance_value, true)
	result["provenance"] = provenance
	return result


static func _biome_by_id(biome_id: String) -> Dictionary:
	for value in catalog().get("biomes", []):
		if value is Dictionary and str(value.get("id", "")) == biome_id:
			return value.duplicate(true)
	return {"id": biome_id}


static func _string_array(value: Variant) -> Array:
	var result: Array = []
	if value is Array:
		for entry in value:
			var clean := str(entry).strip_edges()
			if not clean.is_empty() and not result.has(clean):
				result.append(clean)
	return result


static func _copy(value: Variant) -> Variant:
	return value.duplicate(true) if value is Dictionary or value is Array else value


static func _new_uuid() -> String:
	var crypto := Crypto.new()
	var bytes := crypto.generate_random_bytes(16)
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	var hex := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4), hex.substr(16, 4), hex.substr(20, 12)]
