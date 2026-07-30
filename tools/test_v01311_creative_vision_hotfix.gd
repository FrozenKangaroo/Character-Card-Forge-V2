extends SceneTree

const SERVICE = preload("res://scripts/services/generation_service_v01311_hotfix.gd")
const ATTACHMENT_WINDOW = preload("res://scripts/ui/attachment_manager_window_v01311.gd")


func _init() -> void:
	var service = SERVICE.new()
	var profile := {
		"model": "text-model",
		"vision_model": "vision-model",
		"max_output_tokens": 5000,
		"vision_max_output_tokens": 2400,
		"text_output_auto": false,
		"vision_output_auto": false,
		"text_context_window": 3000,
		"vision_context_window": 8000,
		"text_context_auto": false,
		"vision_context_auto": false,
		"model_capabilities": {
			"text-model": {"context_window": 50000, "max_output_tokens": 9000},
			"vision-model": {"context_window": 64000, "max_output_tokens": 7000}
		}
	}

	_expect(
		service._resolved_context_window(profile, "text-model", false) == 3000,
		"Text manual context must use the Text context setting."
	)
	_expect(
		service._resolved_context_window(profile, "vision-model", true) == 8000,
		"Vision manual context must use the Vision context setting independently."
	)
	profile["text_context_auto"] = true
	profile["vision_context_auto"] = true
	_expect(
		service._resolved_context_window(profile, "text-model", false) == 50000,
		"Text context Auto must use the text model capability."
	)
	_expect(
		service._resolved_context_window(profile, "vision-model", true) == 64000,
		"Vision context Auto must use the vision model capability independently."
	)

	profile["text_context_auto"] = false
	var long_text := "x".repeat(6000)
	var text_configuration: Dictionary = service._request_configuration(
		profile,
		[
			{"role": "system", "content": "test"},
			{"role": "user", "content": long_text}
		],
		false
	)
	_expect(bool(text_configuration.get("ok", false)), "Text request should fit its manual context after output budgeting.")
	_expect(
		int(text_configuration.get("max_output_tokens", 0)) < 5000,
		"Text context window must constrain effective output when input consumes context."
	)

	var image_payload := "data:image/png;base64," + "A".repeat(200000)
	var vision_configuration: Dictionary = service._request_configuration(
		profile,
		[
			{
				"role": "user",
				"content": [
					{"type": "text", "text": "Describe visible anchors."},
					{"type": "image_url", "image_url": {"url": image_payload, "detail": "auto"}}
				]
			}
		],
		true
	)
	_expect(bool(vision_configuration.get("ok", false)), "Vision request should ignore base64 image bytes in text-token estimation.")
	_expect(
		int(vision_configuration.get("estimated_input_tokens", 999999)) < 1000,
		"Base64 image payload must not be treated as hundreds of thousands of text characters."
	)

	var settings := CCFSettingsService.default_settings()
	var stored_profile := CCFSettingsService.profile_by_id(settings, "default").duplicate(true)
	stored_profile["text_context_window"] = 123456
	stored_profile["vision_context_window"] = 654321
	stored_profile["text_context_auto"] = false
	stored_profile["vision_context_auto"] = true
	stored_profile["vision_max_output_tokens"] = 34567
	stored_profile["vision_temperature"] = 1.15
	CCFSettingsService.replace_profile_by_id(settings, "default", stored_profile)
	var round_trip := CCFSettingsService.profile_by_id(settings, "default")
	_expect(int(round_trip.get("text_context_window", 0)) == 123456, "Text context setting must survive profile normalisation.")
	_expect(int(round_trip.get("vision_context_window", 0)) == 654321, "Vision context setting must survive profile normalisation.")
	_expect(int(round_trip.get("vision_max_output_tokens", 0)) == 34567, "Vision output setting must survive profile normalisation.")
	_expect(absf(float(round_trip.get("vision_temperature", 0.0)) - 1.15) < 0.001, "Vision temperature must survive profile normalisation.")

	var attachment_window = ATTACHMENT_WINDOW.new()
	attachment_window._build_ui()
	_expect(attachment_window._analysis_mode.item_count == 2, "Vision mode selector should expose exactly the two intended modes.")
	_expect(attachment_window._analysis_mode.get_item_text(0) == "Visual Analysis", "First mode should be named Visual Analysis directly.")
	_expect(str(attachment_window._analysis_mode.get_item_metadata(0)) == "concept", "Visual Analysis metadata should retain the conservative route.")
	_expect(attachment_window._analysis_mode.get_item_text(1) == "Creative Concept", "Second mode should be named Creative Concept directly.")
	_expect(str(attachment_window._analysis_mode.get_item_metadata(1)) == "creative_concept", "Creative Concept should use an explicit route instead of UI renaming of full_card.")
	attachment_window.free()
	service.free()

	print("v0.13.11 creative vision hotfix regression passed.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
