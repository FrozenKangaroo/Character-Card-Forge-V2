extends SceneTree

const CAPABILITY_SERVICE = preload("res://scripts/services/model_capability_service.gd")
const GENERATION_SERVICE = preload("res://scripts/services/generation_service_v01311.gd")
const SETTINGS_VIEW = preload("res://scripts/ui/settings_view_v01311.gd")


func _init() -> void:
	var capabilities = CAPABILITY_SERVICE.new()
	var parsed: Dictionary = capabilities.capability_from_entry({
		"id": "vision-large",
		"context_length": 1000000,
		"top_provider": {"max_completion_tokens": 250000},
		"input_modalities": ["text", "image"]
	})
	_expect(int(parsed.get("context_window", 0)) == 1000000, "Context-window metadata should be preserved.")
	_expect(int(parsed.get("max_output_tokens", 0)) == 250000, "Nested maximum-output metadata should be preserved.")
	_expect(bool(parsed.get("vision", false)), "Image modality should advertise vision capability.")

	var generation = GENERATION_SERVICE.new()
	var profile := {
		"model": "text-large",
		"vision_model": "vision-large",
		"max_output_tokens": 180000,
		"vision_max_output_tokens": 64000,
		"text_output_auto": true,
		"vision_output_auto": true,
		"model_capabilities": {
			"text-large": {"max_output_tokens": 200000},
			"vision-large": {"max_output_tokens": 96000}
		}
	}
	_expect(generation._resolved_output_limit(profile, "text-large", false) == 200000, "Text output Auto should use the text model capability.")
	_expect(generation._resolved_output_limit(profile, "vision-large", true) == 96000, "Vision output Auto should use the vision model capability independently.")
	profile["vision_output_auto"] = false
	_expect(generation._resolved_output_limit(profile, "vision-large", true) == 64000, "Vision Manual should use its separate manual output value.")

	var settings = SETTINGS_VIEW.new()
	var token_box: SpinBox = settings._large_token_spinbox("")
	_expect(token_box.max_value > 1000000, "Token controls must not clamp at the old 131072 ceiling.")
	_expect(token_box.allow_greater, "Large token controls should allow values beyond the displayed range.")

	print("v0.13.11 vision/capability regression passed.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
