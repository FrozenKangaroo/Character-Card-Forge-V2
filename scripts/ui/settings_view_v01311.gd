extends "res://scripts/ui/settings_view_v01310.gd"

const CAPABILITY_SERVICE = preload("res://scripts/services/model_capability_service.gd")

var _capability_service: Node
var _text_context: SpinBox
var _vision_context: SpinBox
var _vision_max_tokens: SpinBox
var _vision_temperature: SpinBox
var _text_output_auto: CheckBox
var _vision_output_auto: CheckBox
var _text_context_auto: CheckBox
var _vision_context_auto: CheckBox
var _text_detected: Label
var _vision_detected: Label


func _ready() -> void:
	super._ready()
	_capability_service = CAPABILITY_SERVICE.new()
	add_child(_capability_service)
	_capability_service.capabilities_loaded.connect(_on_capabilities_loaded)
	_capability_service.capabilities_failed.connect(_on_capabilities_failed)
	_expand_text_output_control()
	_build_model_limits_tab()
	_load_active_profile()


func _expand_text_output_control() -> void:
	if _max_tokens != null:
		_max_tokens.max_value = 2147483647
		_max_tokens.step = 128
		_max_tokens.tooltip_text = "Manual fallback/override for text generation. The provider/model remains authoritative."
	var form: Node = _max_tokens.get_parent() if _max_tokens != null else null
	if form != null:
		for child in form.get_children():
			if child is Label and child.text == "Maximum output tokens":
				child.text = "Text maximum output tokens"
				break


func _build_model_limits_tab() -> void:
	if _tabs == null:
		return
	var root := _make_scroll_tab("Model Limits")
	var heading := Label.new()
	heading.text = "Text and Vision model limits"
	heading.add_theme_font_size_override("font_size", 22)
	root.add_child(heading)
	var intro := Label.new()
	intro.text = "Text and Vision models can have different context windows and output limits. Fetch Models now preserves capability metadata when the provider exposes it. Auto uses detected limits when available; otherwise the manual value remains the fallback."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(intro)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	root.add_child(grid)

	grid.add_child(_label("Text context window"))
	_text_context = _large_token_spinbox(" tokens")
	grid.add_child(_text_context)
	grid.add_child(_label("Text context mode"))
	_text_context_auto = CheckBox.new()
	_text_context_auto.text = "Auto when detected"
	grid.add_child(_text_context_auto)
	grid.add_child(_label("Text output mode"))
	_text_output_auto = CheckBox.new()
	_text_output_auto.text = "Auto when detected"
	grid.add_child(_text_output_auto)
	grid.add_child(_label("Text detected capability"))
	_text_detected = _capability_label()
	grid.add_child(_text_detected)

	grid.add_child(HSeparator.new())
	grid.add_child(HSeparator.new())

	grid.add_child(_label("Vision context window"))
	_vision_context = _large_token_spinbox(" tokens")
	grid.add_child(_vision_context)
	grid.add_child(_label("Vision context mode"))
	_vision_context_auto = CheckBox.new()
	_vision_context_auto.text = "Auto when detected"
	grid.add_child(_vision_context_auto)
	grid.add_child(_label("Vision maximum output tokens"))
	_vision_max_tokens = _large_token_spinbox("")
	_vision_max_tokens.min_value = 128
	_vision_max_tokens.value = 6000
	grid.add_child(_vision_max_tokens)
	grid.add_child(_label("Vision output mode"))
	_vision_output_auto = CheckBox.new()
	_vision_output_auto.text = "Auto when detected"
	grid.add_child(_vision_output_auto)
	grid.add_child(_label("Vision temperature"))
	_vision_temperature = SpinBox.new()
	_vision_temperature.min_value = 0.0
	_vision_temperature.max_value = 2.0
	_vision_temperature.step = 0.05
	_vision_temperature.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(_vision_temperature)
	grid.add_child(_label("Vision detected capability"))
	_vision_detected = _capability_label()
	grid.add_child(_vision_detected)

	var note := Label.new()
	note.text = "A model's context window and maximum output are separate capabilities. Unknown means the provider did not publish a recognised value; Character Card Forge does not guess one."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.modulate = Color(0.7, 0.73, 0.82)
	root.add_child(note)


func _large_token_spinbox(suffix_text: String) -> SpinBox:
	var box := SpinBox.new()
	box.min_value = 0
	box.max_value = 2147483647
	box.step = 128
	box.allow_greater = true
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.suffix = suffix_text
	return box


func _capability_label() -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "Unknown — fetch models to inspect provider metadata."
	return label


func _load_active_profile() -> void:
	super._load_active_profile()
	if _text_context == null:
		return
	var profile := CCFSettingsService.active_profile(_settings)
	_text_context.value = int(profile.get("text_context_window", 0))
	_vision_context.value = int(profile.get("vision_context_window", 0))
	_vision_max_tokens.value = int(profile.get("vision_max_output_tokens", profile.get("max_output_tokens", 6000)))
	_vision_temperature.value = float(profile.get("vision_temperature", profile.get("temperature", 0.8)))
	_text_output_auto.button_pressed = bool(profile.get("text_output_auto", true))
	_vision_output_auto.button_pressed = bool(profile.get("vision_output_auto", true))
	_text_context_auto.button_pressed = bool(profile.get("text_context_auto", true))
	_vision_context_auto.button_pressed = bool(profile.get("vision_context_auto", true))
	_update_detected_labels(profile)


func _capture_loaded_profile() -> void:
	super._capture_loaded_profile()
	if _loaded_profile_id.is_empty() or _text_context == null:
		return
	var profile := CCFSettingsService.profile_by_id(_settings, _loaded_profile_id).duplicate(true)
	profile["text_context_window"] = int(_text_context.value)
	profile["vision_context_window"] = int(_vision_context.value)
	profile["vision_max_output_tokens"] = int(_vision_max_tokens.value)
	profile["vision_temperature"] = float(_vision_temperature.value)
	profile["text_output_auto"] = _text_output_auto.button_pressed
	profile["vision_output_auto"] = _vision_output_auto.button_pressed
	profile["text_context_auto"] = _text_context_auto.button_pressed
	profile["vision_context_auto"] = _vision_context_auto.button_pressed
	CCFSettingsService.replace_profile_by_id(_settings, _loaded_profile_id, profile)


func _fetch_models() -> void:
	_capture_loaded_profile()
	var profile := CCFSettingsService.profile_by_id(_settings, _loaded_profile_id)
	var result: Dictionary = _capability_service.fetch_capabilities(profile)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not fetch model capabilities."))
		return
	_fetch_models_button.disabled = true
	_status.text = "Fetching model IDs and capability metadata…"


func _on_capabilities_loaded(models: Array) -> void:
	_fetch_models_button.disabled = false
	var profile := CCFSettingsService.profile_by_id(_settings, _loaded_profile_id).duplicate(true)
	var stored: Dictionary = profile.get("model_capabilities", {}).duplicate(true)
	var detected_count := 0
	_fetched_models.clear()
	_fetched_models.add_item("Choose a fetched model…")
	_fetched_models.set_item_disabled(0, true)
	for raw_model in models:
		if not raw_model is Dictionary:
			continue
		var model: Dictionary = raw_model
		var model_id := str(model.get("id", "")).strip_edges()
		if model_id.is_empty():
			continue
		stored[model_id] = model.duplicate(true)
		_fetched_models.add_item(model_id)
		if int(model.get("context_window", 0)) > 0 or int(model.get("max_output_tokens", 0)) > 0:
			detected_count += 1
	profile["model_capabilities"] = stored
	CCFSettingsService.replace_profile_by_id(_settings, _loaded_profile_id, profile)
	_fetched_models.select(0)
	_update_detected_labels(profile)
	_status.text = "Loaded %d models; %d exposed recognised token limits." % [models.size(), detected_count]


func _on_capabilities_failed(message: String) -> void:
	_fetch_models_button.disabled = false
	_status.text = message


func _on_fetched_model_selected(index: int) -> void:
	super._on_fetched_model_selected(index)
	if index > 0:
		var profile := CCFSettingsService.profile_by_id(_settings, _loaded_profile_id).duplicate(true)
		profile["model"] = _model.text.strip_edges()
		CCFSettingsService.replace_profile_by_id(_settings, _loaded_profile_id, profile)
		_update_detected_labels(profile)


func _use_fetched_model_for_vision() -> void:
	super._use_fetched_model_for_vision()
	if _vision_model != null:
		var profile := CCFSettingsService.profile_by_id(_settings, _loaded_profile_id).duplicate(true)
		profile["vision_model"] = _vision_model.text.strip_edges()
		CCFSettingsService.replace_profile_by_id(_settings, _loaded_profile_id, profile)
		_update_detected_labels(profile)


func _update_detected_labels(profile: Dictionary) -> void:
	if _text_detected == null or _vision_detected == null:
		return
	_text_detected.text = _capability_summary(profile, str(profile.get("model", "")), false)
	_vision_detected.text = _capability_summary(profile, str(profile.get("vision_model", profile.get("model", ""))), true)


func _capability_summary(profile: Dictionary, model_id: String, vision_role: bool) -> String:
	if model_id.strip_edges().is_empty():
		return "No model selected."
	var capabilities: Variant = profile.get("model_capabilities", {})
	var capability: Dictionary = {}
	if capabilities is Dictionary:
		var value: Variant = capabilities.get(model_id, {})
		if value is Dictionary:
			capability = value
	var context := int(capability.get("context_window", 0))
	var output := int(capability.get("max_output_tokens", 0))
	var parts: Array[String] = [model_id]
	parts.append("context %s" % (_format_tokens(context) if context > 0 else "unknown"))
	parts.append("max output %s" % (_format_tokens(output) if output > 0 else "unknown"))
	if bool(capability.get("vision", false)):
		parts.append("vision advertised")
	elif vision_role:
		parts.append("vision capability not advertised")
	return " • ".join(parts)


func _format_tokens(value: int) -> String:
	return "%d tokens" % value
