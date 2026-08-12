class_name CCFImageGenerationWindowV0165
extends "res://scripts/ui/image_generation_window_v0164.gd"

var _local_profile_panel_v0165: VBoxContainer
var _local_family_v0165: OptionButton
var _local_notes_v0165: LineEdit
var _local_resolution_v0165: LineEdit
var _local_sampler_v0165: LineEdit
var _local_steps_v0165: SpinBox
var _local_cfg_v0165: SpinBox
var _local_override_controls_v0165: Dictionary = {}
var _loading_local_profile_v0165 := false

const OPERATION_KEYS_V0165 := [
	"text_to_image", "image_to_image", "inpainting", "reference_images"
]
const PARAMETER_KEYS_V0165 := [
	"negative_prompt", "seed", "sampler", "steps", "cfg_scale"
]


func _ready() -> void:
	super._ready()
	ensure_local_model_profile_surface_v0165()
	if _model_edit != null and not _model_edit.text_changed.is_connected(_on_local_checkpoint_changed_v0165):
		_model_edit.text_changed.connect(_on_local_checkpoint_changed_v0165)
	_refresh_local_model_profile_v0165()


func _build_ui() -> void:
	super._build_ui()
	_install_local_model_profile_surface_v0165()


func local_model_profile_capabilities_v0165() -> Dictionary:
	return {
		"version": "0.16.5",
		"forge_a1111_only": true,
		"checkpoint_specific_profiles": true,
		"external_family_catalog": true,
		"family_defaults_are_not_capability_claims": true,
		"preferred_generation_defaults": true,
		"explicit_operation_overrides": true,
		"explicit_parameter_overrides": true,
		"user_override_provenance": true,
		"checkpoint_notes": true,
		"reset_profile": true
	}


func ensure_local_model_profile_surface_v0165() -> void:
	_install_local_model_profile_surface_v0165()
	_refresh_local_model_profile_v0165()


func local_model_profile_surface_ready_v0165() -> bool:
	return (
		_local_profile_panel_v0165 != null
		and is_instance_valid(_local_profile_panel_v0165)
		and _local_profile_panel_v0165.is_inside_tree()
	)


func current_normalized_capabilities_v0161() -> Dictionary:
	var result := super.current_normalized_capabilities_v0161()
	var image_profile := _selected_profile()
	if CCFSettingsService.image_backend(image_profile) != CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111:
		return result
	var checkpoint_id := _model_edit.text.strip_edges() if _model_edit != null else ""
	if checkpoint_id.is_empty():
		return result
	var local_profile := CCFImageLocalModelProfileServiceV0165.checkpoint_profile(
		image_profile, checkpoint_id
	)
	return CCFImageLocalModelProfileServiceV0165.apply_to_capabilities(
		result, local_profile
	)


func _load_selected_profile_settings() -> void:
	super._load_selected_profile_settings()
	call_deferred("_refresh_local_model_profile_v0165")


func _install_local_model_profile_surface_v0165() -> void:
	if _local_profile_panel_v0165 != null and is_instance_valid(_local_profile_panel_v0165):
		return
	if _advanced_stack_v0163 == null or not is_instance_valid(_advanced_stack_v0163):
		return
	var panel := PanelContainer.new()
	panel.name = "ImageStudioLocalModelProfilePanelV0165"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_local_profile_panel_v0165 = VBoxContainer.new()
	_local_profile_panel_v0165.name = "ImageStudioLocalModelProfileControlsV0165"
	_local_profile_panel_v0165.add_theme_constant_override("separation", 7)
	panel.add_child(_local_profile_panel_v0165)
	_advanced_stack_v0163.add_child(panel)
	_advanced_stack_v0163.move_child(panel, mini(3, _advanced_stack_v0163.get_child_count() - 1))

	var heading := Label.new()
	heading.text = "Local checkpoint profile"
	heading.add_theme_font_size_override("font_size", 16)
	_local_profile_panel_v0165.add_child(heading)
	var hint := Label.new()
	hint.text = "Forge / Automatic1111 only. Family selection supplies optional workflow defaults; it does not automatically claim capabilities for every checkpoint. Explicit overrides below are checkpoint-specific."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.66, 0.73, 0.84)
	_local_profile_panel_v0165.add_child(hint)

	var family_row := HBoxContainer.new()
	family_row.add_theme_constant_override("separation", 8)
	_local_profile_panel_v0165.add_child(family_row)
	family_row.add_child(_label("Model family"))
	_local_family_v0165 = OptionButton.new()
	_local_family_v0165.custom_minimum_size.x = 260
	family_row.add_child(_local_family_v0165)
	for raw_family in CCFImageLocalModelProfileServiceV0165.family_catalog().get("families", []):
		if not raw_family is Dictionary:
			continue
		_local_family_v0165.add_item(str(raw_family.get("name", raw_family.get("id", "Family"))))
		_local_family_v0165.set_item_metadata(
			_local_family_v0165.item_count - 1, str(raw_family.get("id", "generic"))
		)
	_local_notes_v0165 = LineEdit.new()
	_local_notes_v0165.custom_minimum_size.x = 340
	_local_notes_v0165.placeholder_text = "Optional checkpoint notes"
	family_row.add_child(_local_notes_v0165)

	var defaults_row := HFlowContainer.new()
	defaults_row.add_theme_constant_override("separation", 8)
	_local_profile_panel_v0165.add_child(defaults_row)
	defaults_row.add_child(_label("Preferred size"))
	_local_resolution_v0165 = LineEdit.new()
	_local_resolution_v0165.custom_minimum_size.x = 120
	defaults_row.add_child(_local_resolution_v0165)
	defaults_row.add_child(_label("Sampler"))
	_local_sampler_v0165 = LineEdit.new()
	_local_sampler_v0165.custom_minimum_size.x = 150
	defaults_row.add_child(_local_sampler_v0165)
	defaults_row.add_child(_label("Steps"))
	_local_steps_v0165 = SpinBox.new()
	_local_steps_v0165.min_value = 0
	_local_steps_v0165.max_value = 150
	_local_steps_v0165.step = 1
	_local_steps_v0165.custom_minimum_size.x = 80
	defaults_row.add_child(_local_steps_v0165)
	defaults_row.add_child(_label("CFG"))
	_local_cfg_v0165 = SpinBox.new()
	_local_cfg_v0165.min_value = 0.0
	_local_cfg_v0165.max_value = 30.0
	_local_cfg_v0165.step = 0.5
	_local_cfg_v0165.custom_minimum_size.x = 80
	defaults_row.add_child(_local_cfg_v0165)
	var apply_button := Button.new()
	apply_button.text = "Apply Profile Defaults"
	apply_button.pressed.connect(_apply_local_defaults_v0165)
	defaults_row.add_child(apply_button)

	var overrides_label := Label.new()
	overrides_label.text = "Checkpoint capability overrides (Auto keeps inherited backend/model information)"
	_local_profile_panel_v0165.add_child(overrides_label)
	var overrides_flow := HFlowContainer.new()
	overrides_flow.name = "ImageStudioLocalOverridesV0165"
	overrides_flow.add_theme_constant_override("separation", 10)
	_local_profile_panel_v0165.add_child(overrides_flow)
	for operation_name in OPERATION_KEYS_V0165:
		_add_override_selector_v0165(overrides_flow, "operation:" + operation_name, operation_name.replace("_", " ").capitalize())
	for parameter_name in PARAMETER_KEYS_V0165:
		_add_override_selector_v0165(overrides_flow, "parameter:" + parameter_name, parameter_name.replace("_", " ").capitalize())

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	_local_profile_panel_v0165.add_child(actions)
	var save_button := Button.new()
	save_button.name = "ImageStudioSaveLocalModelProfileV0165"
	save_button.text = "Save Checkpoint Profile"
	save_button.pressed.connect(_save_local_model_profile_v0165)
	actions.add_child(save_button)
	var reset_button := Button.new()
	reset_button.name = "ImageStudioResetLocalModelProfileV0165"
	reset_button.text = "Reset Checkpoint Profile"
	reset_button.pressed.connect(_reset_local_model_profile_v0165)
	actions.add_child(reset_button)


func _add_override_selector_v0165(parent: Control, key_text: String, label_text: String) -> void:
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 145
	parent.add_child(box)
	var field_label := Label.new()
	field_label.text = label_text
	box.add_child(field_label)
	var selector := OptionButton.new()
	for entry in [
		{"label": "Auto", "value": "auto"},
		{"label": "Supported", "value": CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED},
		{"label": "Unsupported", "value": CCFImageModelCapabilityServiceV0161.STATE_UNSUPPORTED},
		{"label": "Unknown", "value": CCFImageModelCapabilityServiceV0161.STATE_UNKNOWN}
	]:
		selector.add_item(str(entry["label"]))
		selector.set_item_metadata(selector.item_count - 1, str(entry["value"]))
	box.add_child(selector)
	_local_override_controls_v0165[key_text] = selector


func _refresh_local_model_profile_v0165() -> void:
	if _local_profile_panel_v0165 == null or _loading_local_profile_v0165:
		return
	var image_profile := _selected_profile()
	var is_local := CCFSettingsService.image_backend(image_profile) == CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111
	_local_profile_panel_v0165.get_parent().visible = is_local
	if not is_local:
		return
	_loading_local_profile_v0165 = true
	var checkpoint_id := _model_edit.text.strip_edges() if _model_edit != null else ""
	var profile_value := CCFImageLocalModelProfileServiceV0165.checkpoint_profile(image_profile, checkpoint_id)
	_select_metadata_v0165(_local_family_v0165, str(profile_value.get("family_id", "generic")))
	_local_notes_v0165.text = str(profile_value.get("notes", ""))
	var defaults: Dictionary = profile_value.get("preferred_defaults", {})
	_local_resolution_v0165.text = str(defaults.get("resolution", ""))
	_local_sampler_v0165.text = str(defaults.get("sampler", ""))
	_local_steps_v0165.value = float(defaults.get("steps", 0))
	_local_cfg_v0165.value = float(defaults.get("cfg_scale", 0.0))
	var overrides: Dictionary = profile_value.get("capability_overrides", {})
	var operations: Dictionary = overrides.get("operations", {})
	var parameters: Dictionary = overrides.get("parameters", {})
	for operation_name in OPERATION_KEYS_V0165:
		_set_override_selector_v0165("operation:" + operation_name, operations.get(operation_name, {}))
	for parameter_name in PARAMETER_KEYS_V0165:
		_set_override_selector_v0165("parameter:" + parameter_name, parameters.get(parameter_name, {}))
	_loading_local_profile_v0165 = false


func _save_local_model_profile_v0165() -> void:
	if _loading_local_profile_v0165:
		return
	if _profile_selector == null or _profile_selector.selected < 0:
		return
	var checkpoint_id := _model_edit.text.strip_edges() if _model_edit != null else ""
	if checkpoint_id.is_empty():
		_status.text = "Select a local checkpoint before saving its profile."
		return
	var defaults: Dictionary = {}
	if not _local_resolution_v0165.text.strip_edges().is_empty():
		defaults["resolution"] = _local_resolution_v0165.text.strip_edges()
	if not _local_sampler_v0165.text.strip_edges().is_empty():
		defaults["sampler"] = _local_sampler_v0165.text.strip_edges()
	if _local_steps_v0165.value > 0:
		defaults["steps"] = int(_local_steps_v0165.value)
	if _local_cfg_v0165.value > 0.0:
		defaults["cfg_scale"] = _local_cfg_v0165.value
	var profile_value := {
		"checkpoint_id": checkpoint_id,
		"family_id": str(_local_family_v0165.get_selected_metadata()),
		"notes": _local_notes_v0165.text,
		"preferred_defaults": defaults,
		"capability_overrides": _build_overrides_v0165()
	}
	var result := CCFImageLocalModelProfileServiceV0165.store_checkpoint_profile(
		_settings,
		str(_profile_selector.get_selected_metadata()),
		checkpoint_id,
		profile_value
	)
	if bool(result.get("ok", false)):
		_settings = result.get("settings", _settings).duplicate(true)
		_status.text = "Saved local checkpoint profile for %s." % checkpoint_id
		_refresh_local_model_profile_v0165()
		_refresh_capability_surface_v0161()
		_refresh_dynamic_provider_controls_v0164()
	else:
		_status.text = str(result.get("error", "Could not save local checkpoint profile."))


func _reset_local_model_profile_v0165() -> void:
	if _profile_selector == null or _profile_selector.selected < 0:
		return
	var checkpoint_id := _model_edit.text.strip_edges() if _model_edit != null else ""
	if checkpoint_id.is_empty():
		return
	var result := CCFImageLocalModelProfileServiceV0165.clear_checkpoint_profile(
		_settings, str(_profile_selector.get_selected_metadata()), checkpoint_id
	)
	if bool(result.get("ok", false)):
		_settings = result.get("settings", _settings).duplicate(true)
		_status.text = "Reset local checkpoint profile for %s to inherited backend behavior." % checkpoint_id
		_refresh_local_model_profile_v0165()
		_refresh_capability_surface_v0161()
		_refresh_dynamic_provider_controls_v0164()
	else:
		_status.text = str(result.get("error", "Could not reset local checkpoint profile."))


func _build_overrides_v0165() -> Dictionary:
	var operations: Dictionary = {}
	var parameters: Dictionary = {}
	for operation_name in OPERATION_KEYS_V0165:
		var state := _selected_override_state_v0165("operation:" + operation_name)
		if state != "auto":
			operations[operation_name] = {
				"state": state,
				"execution_ready": state == CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED and operation_name == "text_to_image"
			}
	for parameter_name in PARAMETER_KEYS_V0165:
		var state := _selected_override_state_v0165("parameter:" + parameter_name)
		if state != "auto":
			parameters[parameter_name] = {"state": state}
	return {"operations": operations, "parameters": parameters}


func _apply_local_defaults_v0165() -> void:
	var image_profile := _selected_profile()
	var checkpoint_id := _model_edit.text.strip_edges() if _model_edit != null else ""
	var profile_value := CCFImageLocalModelProfileServiceV0165.checkpoint_profile(image_profile, checkpoint_id)
	var defaults := CCFImageLocalModelProfileServiceV0165.effective_defaults(profile_value)
	if defaults.has("resolution") and _image_size_edit != null:
		_image_size_edit.text = str(defaults["resolution"])
	if defaults.has("sampler") and _sampler_edit != null:
		_sampler_edit.text = str(defaults["sampler"])
	if defaults.has("steps") and _steps != null:
		_steps.value = float(defaults["steps"])
	if defaults.has("cfg_scale") and _cfg_scale != null:
		_cfg_scale.value = float(defaults["cfg_scale"])
	_status.text = "Applied local checkpoint profile defaults without changing saved capability overrides."


func _on_local_checkpoint_changed_v0165(_new_text: String) -> void:
	call_deferred("_refresh_local_model_profile_v0165")


func _set_override_selector_v0165(key_text: String, raw_descriptor: Variant) -> void:
	var selector: OptionButton = _local_override_controls_v0165.get(key_text)
	if selector == null:
		return
	var state := "auto"
	if raw_descriptor is Dictionary:
		state = str(raw_descriptor.get("state", "auto"))
	_select_metadata_v0165(selector, state)


func _selected_override_state_v0165(key_text: String) -> String:
	var selector: OptionButton = _local_override_controls_v0165.get(key_text)
	if selector == null or selector.selected < 0:
		return "auto"
	return str(selector.get_selected_metadata())


func _select_metadata_v0165(selector: OptionButton, wanted: String) -> void:
	if selector == null:
		return
	for index in range(selector.item_count):
		if str(selector.get_item_metadata(index)) == wanted:
			selector.select(index)
			return
	if selector.item_count > 0:
		selector.select(0)
