class_name CCFImageProviderModelCatalogServiceV0164
extends RefCounted

const FORMAT_VERSION := 1
const CACHE_KEY := "image_model_catalog_v0164"
const PREFERRED_ENDPOINT_SUFFIX := "/api/v1/images/models"
const LEGACY_ENDPOINT_SUFFIX := "/api/v1/image-models"
const GENERIC_ENDPOINT_SUFFIX := "/models"


static func endpoint_candidates(base_url: String) -> Array[String]:
	var clean := _trim_url(base_url)
	if clean.is_empty():
		return []
	# Profiles sometimes store the generation endpoint rather than API root.
	for suffix in ["/images/generations", "/api/v1/images/generations"]:
		if clean.ends_with(suffix):
			clean = clean.trim_suffix(suffix)
			break
	for known in [PREFERRED_ENDPOINT_SUFFIX, LEGACY_ENDPOINT_SUFFIX, GENERIC_ENDPOINT_SUFFIX]:
		if clean.ends_with(known):
			clean = clean.trim_suffix(known)
			break
	var result: Array[String] = []
	for suffix in [PREFERRED_ENDPOINT_SUFFIX, LEGACY_ENDPOINT_SUFFIX, GENERIC_ENDPOINT_SUFFIX]:
		var candidate := clean + suffix
		if candidate not in result:
			result.append(candidate)
	return result


static func parse_provider_response(raw_value: Variant, endpoint: String = "") -> Dictionary:
	var rows: Array = []
	if raw_value is Array:
		rows = raw_value
	elif raw_value is Dictionary:
		for key_text in ["data", "models", "image_models", "results"]:
			var candidate: Variant = raw_value.get(key_text, null)
			if candidate is Array:
				rows = candidate
				break
	else:
		return {"ok": false, "error": "Image model discovery response was not a JSON object or array."}

	var records: Array[Dictionary] = []
	var seen: Dictionary = {}
	for raw_record in rows:
		if not raw_record is Dictionary:
			continue
		var record := _normalise_record(raw_record)
		var model_id := str(record.get("id", "")).strip_edges()
		if model_id.is_empty() or seen.has(model_id):
			continue
		seen[model_id] = true
		records.append(record)
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("name", a.get("id", ""))).naturalnocasecmp_to(
			str(b.get("name", b.get("id", "")))
		) < 0
	)
	return {
		"ok": true,
		"format_version": FORMAT_VERSION,
		"endpoint": endpoint,
		"records": records,
		"model_ids": _record_ids(records),
		"rich_metadata": _has_rich_metadata(records)
	}


static func normalized_capabilities_for_model(
	profile: Dictionary,
	catalog: Dictionary,
	model_id: String
) -> Dictionary:
	var record := record_for_model(catalog, model_id)
	if record.is_empty():
		var legacy := {
			"models": catalog.get("model_ids", []),
			"discovery_note": "The selected model is not present in the latest provider catalog. Cached/manual selection is retained."
		}
		var fallback := CCFImageModelCapabilityServiceV0161.normalise_discovery(
			profile, legacy, model_id
		)
		fallback["model_missing_from_latest_catalog"] = true
		return fallback
	var result := CCFImageModelCapabilityServiceV0161.normalise_provider_model_record(
		profile, record
	)
	result["model_missing_from_latest_catalog"] = false
	return result


static func record_for_model(catalog: Dictionary, model_id: String) -> Dictionary:
	var clean_id := model_id.strip_edges()
	for raw_record in catalog.get("records", []):
		if raw_record is Dictionary and str(raw_record.get("id", "")).strip_edges() == clean_id:
			return (raw_record as Dictionary).duplicate(true)
	return {}


static func cache_catalog_in_profile(profile: Dictionary, catalog: Dictionary) -> Dictionary:
	var updated := profile.duplicate(true)
	updated[CACHE_KEY] = _sanitise_catalog(catalog)
	return updated


static func catalog_from_profile(profile: Dictionary) -> Dictionary:
	var stored: Variant = profile.get(CACHE_KEY, {})
	if stored is Dictionary:
		return _sanitise_catalog(stored)
	return _empty_catalog()


static func catalog_age_seconds(catalog: Dictionary, now_unix: int = -1) -> int:
	var fetched_at := int(catalog.get("fetched_at_unix", 0))
	if fetched_at <= 0:
		return -1
	var current := now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
	return maxi(0, current - fetched_at)


static func is_stale(catalog: Dictionary, max_age_seconds: int = 86400, now_unix: int = -1) -> bool:
	var age := catalog_age_seconds(catalog, now_unix)
	return age < 0 or age > max_age_seconds


static func with_fetch_metadata(catalog: Dictionary, endpoint: String) -> Dictionary:
	var result := _sanitise_catalog(catalog)
	result["endpoint"] = endpoint
	result["fetched_at_unix"] = int(Time.get_unix_time_from_system())
	result["fetched_at"] = Time.get_datetime_string_from_system(true, true)
	return result


static func _normalise_record(raw_record: Dictionary) -> Dictionary:
	var result := raw_record.duplicate(true)
	var model_id := str(raw_record.get("id", raw_record.get("model", raw_record.get("name", "")))).strip_edges()
	result["id"] = model_id
	if str(result.get("name", "")).strip_edges().is_empty():
		result["name"] = model_id
	if not result.get("capabilities", {}) is Dictionary:
		result["capabilities"] = {}
	if not result.get("supported_parameters", {}) is Dictionary:
		result["supported_parameters"] = {}
	if not result.get("pricing", {}) is Dictionary:
		result["pricing"] = {}
	if not result.get("tags", []) is Array:
		result["tags"] = []
	return result


static func _sanitise_catalog(raw_value: Variant) -> Dictionary:
	var source: Dictionary = raw_value if raw_value is Dictionary else {}
	var result := _empty_catalog()
	result["endpoint"] = str(source.get("endpoint", ""))
	result["fetched_at"] = str(source.get("fetched_at", ""))
	result["fetched_at_unix"] = int(source.get("fetched_at_unix", 0))
	var records: Array[Dictionary] = []
	for raw_record in source.get("records", []):
		if raw_record is Dictionary:
			var record := _normalise_record(raw_record)
			if not str(record.get("id", "")).is_empty():
				records.append(record)
	result["records"] = records
	result["model_ids"] = _record_ids(records)
	result["rich_metadata"] = bool(source.get("rich_metadata", _has_rich_metadata(records)))
	return result


static func _empty_catalog() -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"endpoint": "",
		"fetched_at": "",
		"fetched_at_unix": 0,
		"records": [],
		"model_ids": [],
		"rich_metadata": false
	}


static func _record_ids(records: Array[Dictionary]) -> Array[String]:
	var ids: Array[String] = []
	for record in records:
		var model_id := str(record.get("id", "")).strip_edges()
		if not model_id.is_empty():
			ids.append(model_id)
	return ids


static func _has_rich_metadata(records: Array[Dictionary]) -> bool:
	for record in records:
		if not (record.get("capabilities", {}) as Dictionary).is_empty():
			return true
		if not (record.get("supported_parameters", {}) as Dictionary).is_empty():
			return true
		if not (record.get("pricing", {}) as Dictionary).is_empty():
			return true
	return false


static func _trim_url(base_url: String) -> String:
	var clean := base_url.strip_edges()
	while clean.ends_with("/"):
		clean = clean.left(clean.length() - 1)
	return clean
