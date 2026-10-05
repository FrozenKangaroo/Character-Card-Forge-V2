class_name CCFSettingsCurrentView
extends "res://scripts/ui/settings_view_v0208.gd"

var _stream_ai_responses_v02112: CheckButton
var _streaming_status_v02112: Label
var _collaborator_handoff_strategy_v02115: OptionButton


func _ready() -> void:
	super._ready()
	_build_generation_transport_tab_v02112()
	_load_streaming_setting_v02112()
	_load_collaborator_handoff_setting_v02115()


func load_settings(settings: Dictionary) -> void:
	super.load_settings(settings)
	_load_streaming_setting_v02112()
	_load_collaborator_handoff_setting_v02115()


func _save() -> void:
	_capture_streaming_setting_v02112()
	_capture_collaborator_handoff_setting_v02115()
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

	var collaborator_heading := Label.new()
	collaborator_heading.text = "Character Collaborator → Workspace"
	collaborator_heading.add_theme_font_size_override("font_size", 18)
	parent.add_child(collaborator_heading)

	var collaborator_explanation := Label.new()
	collaborator_explanation.text = (
		"This setting applies only when Character Collaborator builds a Generation "
		+ "Blueprint or Detailed Workspace Draft. It is independent of the normal "
		+ "Generate Character strategy."
	)
	collaborator_explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	collaborator_explanation.modulate = Color(0.72, 0.76, 0.86)
	parent.add_child(collaborator_explanation)

	_collaborator_handoff_strategy_v02115 = OptionButton.new()
	_collaborator_handoff_strategy_v02115.name = "CollaboratorHandoffStrategyV02115"
	_collaborator_handoff_strategy_v02115.add_item(
		"Safe Section Build — Recommended"
	)
	_collaborator_handoff_strategy_v02115.set_item_metadata(0, "safe_section")
	_collaborator_handoff_strategy_v02115.add_item(
		"Single Response — Faster / fewer requests"
	)
	_collaborator_handoff_strategy_v02115.set_item_metadata(1, "single_response")
	_collaborator_handoff_strategy_v02115.tooltip_text = (
		"Safe Section Build preserves and validates one complete blueprint section at a "
		+ "time. Detailed Workspace Draft then reuses the normal validated field-by-field "
		+ "engine. Single Response retains the faster established handoff."
	)
	parent.add_child(_collaborator_handoff_strategy_v02115)

	var collaborator_hint := Label.new()
	collaborator_hint.text = (
		"Safe Section Build uses more provider requests but is much less vulnerable to a "
		+ "long handoff ending early. Single Response automatically attempts one bounded "
		+ "repair from the first incomplete Generation Concept section onward, preserving "
		+ "every complete section before it."
	)
	collaborator_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	collaborator_hint.modulate = Color(0.62, 0.66, 0.76)
	parent.add_child(collaborator_hint)

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


func _load_collaborator_handoff_setting_v02115() -> void:
	if _collaborator_handoff_strategy_v02115 == null:
		return
	var generation_value: Variant = _settings.get("generation", {})
	var strategy := "safe_section"
	if generation_value is Dictionary:
		strategy = str((generation_value as Dictionary).get(
			"collaborator_handoff_strategy", "safe_section"
		))
	if strategy != "single_response":
		strategy = "safe_section"
	for index in range(_collaborator_handoff_strategy_v02115.item_count):
		if str(
			_collaborator_handoff_strategy_v02115.get_item_metadata(index)
		) == strategy:
			_collaborator_handoff_strategy_v02115.select(index)
			break


func _capture_collaborator_handoff_setting_v02115() -> void:
	if _collaborator_handoff_strategy_v02115 == null:
		return
	var generation_value: Variant = _settings.get("generation", {})
	var generation: Dictionary = (
		generation_value.duplicate(true) if generation_value is Dictionary else {}
	)
	var strategy := "safe_section"
	if _collaborator_handoff_strategy_v02115.selected >= 0:
		strategy = str(
			_collaborator_handoff_strategy_v02115.get_selected_metadata()
		)
	if strategy != "single_response":
		strategy = "safe_section"
	generation["collaborator_handoff_strategy"] = strategy
	_settings["generation"] = generation
