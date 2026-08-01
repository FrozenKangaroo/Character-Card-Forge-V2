class_name CCFSettingsV0151View
extends "res://scripts/ui/settings_view_v01310.gd"

var _context_window_tokens_v0151: SpinBox


func _ready() -> void:
	super._ready()
	_install_context_window_control_v0151()
	_load_active_profile()


func _install_context_window_control_v0151() -> void:
	if _max_tokens == null or _max_tokens.get_parent() == null:
		return
	var form := _max_tokens.get_parent()
	if not form is GridContainer:
		return
	form.add_child(_label("Context window tokens"))
	_context_window_tokens_v0151 = SpinBox.new()
	_context_window_tokens_v0151.min_value = 0
	_context_window_tokens_v0151.max_value = 4194304
	_context_window_tokens_v0151.step = 1024
	_context_window_tokens_v0151.allow_greater = true
	_context_window_tokens_v0151.suffix = " tokens"
	_context_window_tokens_v0151.tooltip_text = "Total input + output context window for this model. Set 0 when unknown; Character Collaborator will show an estimate but will not block sending when the limit is unknown."
	_context_window_tokens_v0151.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(_context_window_tokens_v0151)
	var hint := Label.new()
	hint.text = "Context Window is the model's total request capacity. Maximum Output Tokens is only the response limit. Character Collaborator uses both values because conversation history grows the input every turn. Set Context Window to 0 if the provider/model limit is unknown."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.68, 0.72, 0.82)
	form.add_child(hint)
	var spacer := Control.new()
	form.add_child(spacer)


func _load_active_profile() -> void:
	super._load_active_profile()
	if _context_window_tokens_v0151 == null:
		return
	var profile := CCFSettingsService.active_profile(_settings)
	_context_window_tokens_v0151.value = int(profile.get("context_window_tokens", 0))


func _capture_loaded_profile() -> void:
	super._capture_loaded_profile()
	if _loaded_profile_id.is_empty() or _context_window_tokens_v0151 == null:
		return
	var profile := CCFSettingsService.profile_by_id(_settings, _loaded_profile_id).duplicate(true)
	profile["context_window_tokens"] = maxi(0, int(_context_window_tokens_v0151.value))
	CCFSettingsService.replace_profile_by_id(_settings, _loaded_profile_id, profile)
