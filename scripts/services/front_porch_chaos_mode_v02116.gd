class_name CCFFrontPorchChaosModeV02116
extends RefCounted

const MODE_DISABLED := "disabled"
const MODE_RARE := "rare"
const MODE_NORMAL := "normal"
const MODE_WILD := "wild"
const ENABLED_MODES := [MODE_RARE, MODE_NORMAL, MODE_WILD]


static func normalise_control_value(raw_value: Variant) -> Dictionary:
	if raw_value is bool:
		return {
			"ok": true,
			"value": MODE_NORMAL if bool(raw_value) else MODE_DISABLED
		}
	var value := str(raw_value).strip_edges().to_lower()
	if value in ENABLED_MODES or value == MODE_DISABLED:
		return {"ok": true, "value": value}
	if value in ["true", "enabled", "on"]:
		return {"ok": true, "value": MODE_NORMAL}
	if value in ["false", "off", "none"]:
		return {"ok": true, "value": MODE_DISABLED}
	return {
		"ok": false,
		"error": "Choose Disabled, Rare, Normal or Wild."
	}


static func is_present(realism: Dictionary) -> bool:
	return realism.has("chaos_mode_enabled") or realism.has("chaos_frequency")


static func mode_from_realism(realism: Dictionary) -> String:
	if realism.has("chaos_mode_enabled") and not bool(realism.get("chaos_mode_enabled")):
		return MODE_DISABLED
	var frequency := str(realism.get("chaos_frequency", "")).strip_edges().to_lower()
	if frequency in ENABLED_MODES:
		return frequency
	if realism.has("chaos_mode_enabled"):
		return MODE_NORMAL if bool(realism.get("chaos_mode_enabled")) else MODE_DISABLED
	if realism.has("chaos_frequency"):
		# Rawhide's ChaosFrequency.fromName fallback is Normal for unknown values.
		return MODE_NORMAL
	return MODE_DISABLED


static func apply_mode(
	realism: Dictionary, included: bool, raw_value: Variant
) -> Dictionary:
	if not included:
		realism.erase("chaos_mode_enabled")
		realism.erase("chaos_frequency")
		return {"ok": true, "value": MODE_DISABLED}
	var parsed := normalise_control_value(raw_value)
	if not bool(parsed.get("ok", false)):
		return parsed
	var mode := str(parsed.get("value", MODE_DISABLED))
	realism["chaos_mode_enabled"] = mode != MODE_DISABLED
	if mode == MODE_DISABLED:
		realism.erase("chaos_frequency")
	else:
		realism["chaos_frequency"] = mode
	return {"ok": true, "value": mode}
