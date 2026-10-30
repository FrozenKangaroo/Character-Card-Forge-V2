class_name CCFFrontPorchRawhideCharacterV02116
extends RefCounted

const RAW_HIDE_COMMIT := "2876ee5d8e92290d2f4498bf0f459652010aa735"
const NEED_KEYS := ["hunger", "bladder", "energy", "social", "fun", "hygiene", "comfort"]
const NEED_PACES := ["sloth", "normal", "fast"]
const SEX_VALUES := ["male", "female", "other"]
const RECOVERY_MODES := ["auto", "hard", "soft"]
const PCD_MODES := ["off", "rare", "sometimes"]


static func normalise_needs_off(value: Variant) -> Dictionary:
	if not value is Array:
		return {"ok": false, "error": "Needs Off must be a list."}
	var result: Array[String] = []
	for raw_item in value:
		var raw_text := str(raw_item).strip_edges()
		var canonical := raw_text.to_lower()
		var item := canonical if canonical in NEED_KEYS else raw_text
		if not item.is_empty() and item not in result:
			result.append(item)
	return {"ok": true, "value": result}


static func normalise_recovery(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {"ok": false, "error": "Recovery must be an object."}
	var source: Dictionary = (value as Dictionary).duplicate(true)
	var mode := str(source.get("mode", "auto")).strip_edges().to_lower()
	var pcd := str(source.get("pcd", "off")).strip_edges().to_lower()
	var result := source
	result["mode"] = mode
	if pcd == "off":
		result.erase("pcd")
	else:
		result["pcd"] = pcd
	if mode == "hard":
		var duration := explicit_recovery_minutes(source)
		if bool(duration.get("present", false)):
			result["minutes"] = int(duration.get("value", 0))
		else:
			result.erase("minutes")
	elif mode in RECOVERY_MODES:
		result.erase("minutes")
	if mode == "auto" and pcd == "off" and result.size() == 1:
		return {"ok": true, "value": {}, "is_default": true}
	return {"ok": true, "value": result, "is_default": false}


static func explicit_recovery_minutes(value: Variant) -> Dictionary:
	if not value is Dictionary or not (value as Dictionary).has("minutes"):
		return {"present": false}
	var raw_minutes: Variant = (value as Dictionary).get("minutes")
	var parsed: int
	if raw_minutes is int or raw_minutes is float:
		parsed = int(raw_minutes)
	elif raw_minutes is String and str(raw_minutes).strip_edges().is_valid_int():
		parsed = int(str(raw_minutes).strip_edges())
	else:
		return {"present": false}
	if parsed < 0:
		return {"present": false}
	return {"present": true, "value": clampi(parsed, 0, 180)}
