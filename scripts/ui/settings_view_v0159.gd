class_name CCFSettingsV0159View
extends "res://scripts/ui/settings_view_v0152.gd"

var _vision_context_window_v0159: SpinBox
var _vision_max_output_v0159: SpinBox


func _ready() -> void:
	super._ready()
	_install_vision_token_controls_v0159()
	_load_active_profile()


func _install_vision_token_controls_v0159() -> void:
	if _vision_detail == null or _vision_detail.get_parent() == null:
		return
	var form := _vision_detail.get_parent()
	if not form is GridContainer:
		return

	form.add_child(_label("Vision context window tokens"))
	_vision_context_window_v0159 = SpinBox.new()
	_vision_context_window_v0159.min_value = 0
	_vision_context_window_v0159.max_value = 4194304
	_vision_context_window_v0159.step = 1024
	_vision_context_window_v0159.allow_greater = true
	_vision_context_window_v0159.suffix = " tokens"
	_vision_context_window_v0159.tooltip_text = "Total input + output context window of the configured Vision model. This is independent from the Text model context window. Set 0 when unknown."
	_vision_context_window_v0159.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(_vision_context_window_v0159)

	form.add_child(_label("Vision maximum output tokens"))
	_vision_max_output_v0159 = SpinBox.new()
	_vision_max_output_v0159.min_value = 128
	_vision_max_output_v0159.max_value = 4194304
	_vision_max_output_v0159.step = 128
	_vision_max_output_v0159.allow_greater = true
	_vision_max_output_v0159.suffix = " tokens"
	_vision_max_output_v0159.tooltip_text = "Maximum response tokens requested from the Vision model. Keep this within that model's supported output/context limits; it does not change the Text model response limit."
	_vision_max_output_v0159.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(_vision_max_output_v0159)

	var hint := Label.new()
	hint.text = "Text and Vision models can have completely different token limits. Vision image-analysis requests use only the Vision context/output values above; normal Character Collaborator replies continue to use the Text limits."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.68, 0.72, 0.82)
	form.add_child(hint)
	form.add_child(Control.new())


func _load_active_profile() -> void:
	super._load_active_profile()
	if _vision_context_window_v0159 == null or _vision_max_output_v0159 == null:
		return
	var profile := CCFSettingsService.active_profile(_settings)
	_vision_context_window_v0159.value = maxi(0, int(profile.get("vision_context_window_tokens", 0)))
	_vision_max_output_v0159.value = maxi(128, int(profile.get("vision_max_output_tokens", 4096)))


func _capture_loaded_profile() -> void:
	super._capture_loaded_profile()
	if _loaded_profile_id.is_empty() or _vision_context_window_v0159 == null or _vision_max_output_v0159 == null:
		return
	var profile := CCFSettingsService.profile_by_id(_settings, _loaded_profile_id).duplicate(true)
	profile["vision_context_window_tokens"] = maxi(0, int(_vision_context_window_v0159.value))
	profile["vision_max_output_tokens"] = maxi(128, int(_vision_max_output_v0159.value))
	CCFSettingsService.replace_profile_by_id(_settings, _loaded_profile_id, profile)
