class_name CCFSettingsCurrentView
extends "res://scripts/ui/settings_view_v0208.gd"

var _stream_ai_responses_v02112: CheckButton
var _streaming_status_v02112: Label


func _ready() -> void:
	super._ready()
	_build_generation_transport_tab_v02112()
	_load_streaming_setting_v02112()


func load_settings(settings: Dictionary) -> void:
	super.load_settings(settings)
	_load_streaming_setting_v02112()


func _save() -> void:
	_capture_streaming_setting_v02112()
	super._save()
	if _streaming_status_v02112 != null:
		_streaming_status_v02112.text = (
			"Streaming preference saved. New AI jobs will use it immediately."
		)


func _build_generation_transport_tab_v02112() -> void:
	if _tabs == null:
		return
	var parent := _make_scroll_tab("AI / Generation")
	var heading := Label.new()
	heading.text = "AI response delivery"
	heading.add_theme_font_size_override("font_size", 22)
	parent.add_child(heading)

	var explanation := Label.new()
	explanation.text = (
		"Streaming can show safe provisional content while a provider is still replying. "
		+ "Completed responses, parsing, validation, retries and final project changes remain "
		+ "authoritative. Providers that cannot stream continue through the normal response path."
	)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.modulate = Color(0.72, 0.76, 0.86)
	parent.add_child(explanation)

	_stream_ai_responses_v02112 = CheckButton.new()
	_stream_ai_responses_v02112.name = "StreamAIResponsesV02112"
	_stream_ai_responses_v02112.text = "Stream AI responses"
	_stream_ai_responses_v02112.tooltip_text = (
		"Use real provider streaming when the selected OpenAI-compatible endpoint supports it. "
		+ "Leave off for the established completed-response behaviour."
	)
	parent.add_child(_stream_ai_responses_v02112)

	var safety := Label.new()
	safety.text = (
		"Provisional text is never saved or applied as final content. Cancelling, retrying or a "
		+ "failed validation removes it. Structured JSON is shown only in complete parsed units."
	)
	safety.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	safety.modulate = Color(0.88, 0.69, 0.48)
	parent.add_child(safety)

	var save_button := Button.new()
	save_button.text = "Save AI Generation Settings"
	save_button.custom_minimum_size = Vector2(220, 42)
	save_button.pressed.connect(_save)
	parent.add_child(save_button)

	_streaming_status_v02112 = Label.new()
	_streaming_status_v02112.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_streaming_status_v02112.modulate = Color(0.72, 0.82, 0.72)
	parent.add_child(_streaming_status_v02112)


func _load_streaming_setting_v02112() -> void:
	if _stream_ai_responses_v02112 == null:
		return
	var generation_value: Variant = _settings.get("generation", {})
	var generation: Dictionary = generation_value if generation_value is Dictionary else {}
	_stream_ai_responses_v02112.button_pressed = bool(
		generation.get("stream_ai_responses", false)
	)


func _capture_streaming_setting_v02112() -> void:
	if _stream_ai_responses_v02112 == null:
		return
	var generation_value: Variant = _settings.get("generation", {})
	var generation: Dictionary = (
		generation_value.duplicate(true) if generation_value is Dictionary else {}
	)
	generation["stream_ai_responses"] = _stream_ai_responses_v02112.button_pressed
	_settings["generation"] = generation
