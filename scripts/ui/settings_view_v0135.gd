class_name CCFSettingsV0135View
extends CCFSettingsView

var _vision_model: LineEdit
var _use_fetched_for_vision_button: Button


func _ready() -> void:
	super._ready()
	_install_vision_model_control()
	_load_active_profile()


func _install_vision_model_control() -> void:
	if _model == null or _model.get_parent() == null:
		return
	_model.placeholder_text = "Enter the text-generation model ID"
	var model_box := _model.get_parent().get_parent()
	var form := model_box.get_parent()
	if form is GridContainer:
		for child in form.get_children():
			if child is Label and child.text == "Model":
				child.text = "Text model"
				break
		form.add_child(_label("Vision model"))
		_vision_model = LineEdit.new()
		_vision_model.placeholder_text = "Enter the vision/multimodal model ID"
		_vision_model.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		form.add_child(_vision_model)
	if model_box is VBoxContainer:
		_use_fetched_for_vision_button = Button.new()
		_use_fetched_for_vision_button.text = "Use Selected Fetched Model for Vision"
		_use_fetched_for_vision_button.tooltip_text = "Assign the currently selected discovered model ID to the Vision model field."
		_use_fetched_for_vision_button.pressed.connect(_use_fetched_model_for_vision)
		model_box.add_child(_use_fetched_for_vision_button)


func _load_active_profile() -> void:
	var profile := CCFSettingsService.active_profile(_settings)
	_loaded_profile_id = str(profile.get("id", "default"))
	_profile_name.text = str(profile.get("name", "Default"))
	_base_url.text = str(profile.get("base_url", ""))
	_api_key.text = str(profile.get("api_key", ""))
	_model.text = str(profile.get("model", ""))
	if _vision_model != null:
		var vision_value := str(profile.get("vision_model", "")).strip_edges()
		if not profile.has("vision_model"):
			vision_value = str(profile.get("model", "")).strip_edges()
		_vision_model.text = vision_value
	_temperature.value = float(profile.get("temperature", 0.8))
	_max_tokens.value = int(profile.get("max_output_tokens", 6000))
	_select_metadata(_vision_detail, str(profile.get("vision_detail", "auto")))
	_reset_fetched_models()


func _capture_loaded_profile() -> void:
	if _loaded_profile_id.is_empty():
		return
	var profile := CCFSettingsService.profile_by_id(_settings, _loaded_profile_id).duplicate(true)
	var display_name := _profile_name.text.strip_edges()
	profile["name"] = display_name if not display_name.is_empty() else "Profile"
	profile["base_url"] = _base_url.text.strip_edges()
	profile["api_key"] = _api_key.text.strip_edges()
	profile["model"] = _model.text.strip_edges()
	if _vision_model != null:
		profile["vision_model"] = _vision_model.text.strip_edges()
	profile["temperature"] = _temperature.value
	profile["max_output_tokens"] = int(_max_tokens.value)
	profile["vision_detail"] = str(_vision_detail.get_selected_metadata()) if _vision_detail.selected >= 0 else "auto"
	CCFSettingsService.replace_profile_by_id(_settings, _loaded_profile_id, profile)


func _use_fetched_model_for_vision() -> void:
	if _vision_model == null or _fetched_models == null or _fetched_models.selected <= 0:
		_status.text = "Choose a fetched model first."
		return
	_vision_model.text = _fetched_models.get_item_text(_fetched_models.selected)
	_status.text = "Selected vision model %s." % _vision_model.text
