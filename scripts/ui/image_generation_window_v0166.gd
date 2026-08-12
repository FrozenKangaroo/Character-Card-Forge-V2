class_name CCFImageGenerationWindowV0166
extends "res://scripts/ui/image_generation_window_v0165.gd"

var _comfy_panel_v0166: VBoxContainer
var _comfy_enabled_v0166: CheckButton
var _comfy_profile_id_v0166: LineEdit
var _comfy_profile_name_v0166: LineEdit
var _comfy_workflow_v0166: TextEdit
var _comfy_output_node_v0166: LineEdit
var _comfy_mapping_controls_v0166: Dictionary = {}
var _comfy_validation_v0166: Label
var _loading_comfy_v0166 := false


func _ready() -> void:
	super._ready()
	ensure_comfyui_generation_profile_surface_v0166()
	_refresh_comfyui_generation_profile_v0166()


func _build_ui() -> void:
	super._build_ui()
	_install_comfyui_generation_profile_surface_v0166()


func comfyui_generation_profile_capabilities_v0166() -> Dictionary:
	return {
		"version": "0.16.6",
		"versioned_generation_profiles": true,
		"workflow_snapshot_separate_from_mapping": true,
		"explicit_node_input_mapping": true,
		"unknown_workflow_fields_preserved": true,
		"deterministic_materialisation": true,
		"workflow_provenance_capabilities": true,
		"offline_validation": true,
		"live_queue_transport": false
	}


func ensure_comfyui_generation_profile_surface_v0166() -> void:
	_install_comfyui_generation_profile_surface_v0166()
	_refresh_comfyui_generation_profile_v0166()


func comfyui_generation_profile_surface_ready_v0166() -> bool:
	return (
		_comfy_panel_v0166 != null
		and is_instance_valid(_comfy_panel_v0166)
		and _comfy_panel_v0166.is_inside_tree()
	)


func current_normalized_capabilities_v0161() -> Dictionary:
	var image_profile := _selected_profile()
	if bool(image_profile.get("comfyui_enabled_v0166", false)):
		var comfy_profile := CCFComfyUIGenerationProfileServiceV0166.profile_from_image_provider(image_profile)
		return CCFComfyUIGenerationProfileServiceV0166.capability_document(comfy_profile)
	return super.current_normalized_capabilities_v0161()


func _load_selected_profile_settings() -> void:
	super._load_selected_profile_settings()
	call_deferred("_refresh_comfyui_generation_profile_v0166")


func _install_comfyui_generation_profile_surface_v0166() -> void:
	if _comfy_panel_v0166 != null and is_instance_valid(_comfy_panel_v0166):
		return
	if _advanced_stack_v0163 == null or not is_instance_valid(_advanced_stack_v0163):
		return
	var panel := PanelContainer.new()
	panel.name = "ImageStudioComfyUIGenerationProfilePanelV0166"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_comfy_panel_v0166 = VBoxContainer.new()
	_comfy_panel_v0166.name = "ImageStudioComfyUIGenerationProfileControlsV0166"
	_comfy_panel_v0166.add_theme_constant_override("separation", 7)
	panel.add_child(_comfy_panel_v0166)
	_advanced_stack_v0163.add_child(panel)

	var heading := Label.new()
	heading.text = "ComfyUI Generation Profile"
	heading.add_theme_font_size_override("font_size", 16)
	_comfy_panel_v0166.add_child(heading)
	var hint := Label.new()
	hint.text = "Maps CCF concepts onto explicit ComfyUI workflow node inputs. The workflow snapshot remains intact; mappings are stored separately so profiles stay understandable and editable. Live ComfyUI queue transport is intentionally not enabled in this release."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.66, 0.73, 0.84)
	_comfy_panel_v0166.add_child(hint)

	_comfy_enabled_v0166 = CheckButton.new()
	_comfy_enabled_v0166.name = "ImageStudioComfyUIEnabledV0166"
	_comfy_enabled_v0166.text = "Use a ComfyUI workflow profile with this Image provider"
	_comfy_panel_v0166.add_child(_comfy_enabled_v0166)

	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", 8)
	_comfy_panel_v0166.add_child(identity)
	identity.add_child(_make_label_v0166("Profile ID"))
	_comfy_profile_id_v0166 = LineEdit.new()
	_comfy_profile_id_v0166.custom_minimum_size.x = 190
	identity.add_child(_comfy_profile_id_v0166)
	identity.add_child(_make_label_v0166("Name"))
	_comfy_profile_name_v0166 = LineEdit.new()
	_comfy_profile_name_v0166.custom_minimum_size.x = 260
	_comfy_profile_name_v0166.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(_comfy_profile_name_v0166)

	var workflow_label := Label.new()
	workflow_label.text = "ComfyUI API workflow JSON"
	_comfy_panel_v0166.add_child(workflow_label)
	_comfy_workflow_v0166 = TextEdit.new()
	_comfy_workflow_v0166.name = "ImageStudioComfyUIWorkflowJSONV0166"
	_comfy_workflow_v0166.custom_minimum_size.y = 210
	_comfy_workflow_v0166.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_comfy_panel_v0166.add_child(_comfy_workflow_v0166)

	var mapping_heading := Label.new()
	mapping_heading.text = "CCF input mappings — node ID + input name"
	_comfy_panel_v0166.add_child(mapping_heading)
	var mapping_grid := GridContainer.new()
	mapping_grid.columns = 3
	mapping_grid.add_theme_constant_override("h_separation", 8)
	mapping_grid.add_theme_constant_override("v_separation", 5)
	_comfy_panel_v0166.add_child(mapping_grid)
	mapping_grid.add_child(_make_label_v0166("CCF input"))
	mapping_grid.add_child(_make_label_v0166("Node ID"))
	mapping_grid.add_child(_make_label_v0166("Input"))
	for input_name in CCFComfyUIGenerationProfileServiceV0166.STANDARD_INPUTS:
		mapping_grid.add_child(_make_label_v0166(str(input_name).replace("_", " ").capitalize()))
		var node_edit := LineEdit.new()
		node_edit.custom_minimum_size.x = 110
		mapping_grid.add_child(node_edit)
		var input_edit := LineEdit.new()
		input_edit.custom_minimum_size.x = 150
		mapping_grid.add_child(input_edit)
		_comfy_mapping_controls_v0166[str(input_name)] = {"node": node_edit, "input": input_edit}

	var output_row := HBoxContainer.new()
	output_row.add_theme_constant_override("separation", 8)
	_comfy_panel_v0166.add_child(output_row)
	output_row.add_child(_make_label_v0166("Image output node"))
	_comfy_output_node_v0166 = LineEdit.new()
	_comfy_output_node_v0166.custom_minimum_size.x = 180
	output_row.add_child(_comfy_output_node_v0166)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	_comfy_panel_v0166.add_child(actions)
	var validate_button := Button.new()
	validate_button.name = "ImageStudioValidateComfyUIProfileV0166"
	validate_button.text = "Validate Profile"
	validate_button.pressed.connect(_validate_comfyui_profile_v0166)
	actions.add_child(validate_button)
	var save_button := Button.new()
	save_button.name = "ImageStudioSaveComfyUIProfileV0166"
	save_button.text = "Save Generation Profile"
	save_button.pressed.connect(_save_comfyui_profile_v0166)
	actions.add_child(save_button)

	_comfy_validation_v0166 = Label.new()
	_comfy_validation_v0166.name = "ImageStudioComfyUIValidationV0166"
	_comfy_validation_v0166.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_comfy_validation_v0166.modulate = Color(0.66, 0.73, 0.84)
	_comfy_panel_v0166.add_child(_comfy_validation_v0166)


func _refresh_comfyui_generation_profile_v0166() -> void:
	if _comfy_panel_v0166 == null or _loading_comfy_v0166:
		return
	_loading_comfy_v0166 = true
	var image_profile := _selected_profile()
	_comfy_enabled_v0166.button_pressed = bool(image_profile.get("comfyui_enabled_v0166", false))
	var generation_profile := CCFComfyUIGenerationProfileServiceV0166.profile_from_image_provider(image_profile)
	_comfy_profile_id_v0166.text = str(generation_profile.get("id", "comfy_default"))
	_comfy_profile_name_v0166.text = str(generation_profile.get("name", "ComfyUI Workflow"))
	_comfy_workflow_v0166.text = JSON.stringify(generation_profile.get("workflow", {}), "  ")
	var mappings: Dictionary = generation_profile.get("mappings", {})
	for input_name in _comfy_mapping_controls_v0166.keys():
		var controls: Dictionary = _comfy_mapping_controls_v0166[input_name]
		var mapping: Dictionary = mappings.get(input_name, {})
		(controls.get("node") as LineEdit).text = str(mapping.get("node_id", ""))
		(controls.get("input") as LineEdit).text = str(mapping.get("input", ""))
	_comfy_output_node_v0166.text = str((generation_profile.get("output", {}) as Dictionary).get("node_id", ""))
	_comfy_validation_v0166.text = "Profile editing is local. Validate before saving; opening this panel performs no network request."
	_loading_comfy_v0166 = false


func _profile_from_controls_v0166() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_comfy_workflow_v0166.text)
	var workflow: Dictionary = parsed if parsed is Dictionary else {}
	var mappings: Dictionary = {}
	for input_name in _comfy_mapping_controls_v0166.keys():
		var controls: Dictionary = _comfy_mapping_controls_v0166[input_name]
		var node_id := (controls.get("node") as LineEdit).text.strip_edges()
		var target_input := (controls.get("input") as LineEdit).text.strip_edges()
		if node_id.is_empty() or target_input.is_empty():
			continue
		mappings[input_name] = {
			"node_id": node_id,
			"input": target_input,
			"value_type": _value_type_for_input_v0166(str(input_name)),
			"required": input_name == CCFComfyUIGenerationProfileServiceV0166.INPUT_PROMPT
		}
	return CCFComfyUIGenerationProfileServiceV0166.normalise_profile({
		"id": _comfy_profile_id_v0166.text.strip_edges(),
		"name": _comfy_profile_name_v0166.text.strip_edges(),
		"workflow": workflow,
		"mappings": mappings,
		"output": {"node_id": _comfy_output_node_v0166.text.strip_edges(), "kind": "image"}
	})


func _validate_comfyui_profile_v0166() -> void:
	var profile := _profile_from_controls_v0166()
	var validation := CCFComfyUIGenerationProfileServiceV0166.validate_profile(profile)
	var lines: Array[String] = []
	if bool(validation.get("ok", false)):
		lines.append("Profile is valid.")
	else:
		lines.append("Profile has errors.")
	for error_text in validation.get("errors", []):
		lines.append("Error: %s" % str(error_text))
	for warning_text in validation.get("warnings", []):
		lines.append("Warning: %s" % str(warning_text))
	_comfy_validation_v0166.text = "\n".join(lines)


func _save_comfyui_profile_v0166() -> void:
	if _profile_selector == null or _profile_selector.selected < 0:
		return
	var generation_profile := _profile_from_controls_v0166()
	var validation := CCFComfyUIGenerationProfileServiceV0166.validate_profile(generation_profile)
	if not bool(validation.get("ok", false)):
		_validate_comfyui_profile_v0166()
		_status.text = "ComfyUI Generation Profile has validation errors and was not saved."
		return
	var result := CCFComfyUIGenerationProfileServiceV0166.store_profile(
		_settings,
		str(_profile_selector.get_selected_metadata()),
		generation_profile
	)
	if bool(result.get("ok", false)):
		_settings = result.get("settings", _settings).duplicate(true)
		_status.text = "Saved ComfyUI Generation Profile '%s'." % str(generation_profile.get("name", "Workflow"))
		_refresh_comfyui_generation_profile_v0166()
		_refresh_capability_surface_v0161()
	else:
		_status.text = str(result.get("error", "Could not save ComfyUI Generation Profile."))


func _value_type_for_input_v0166(input_name: String) -> String:
	match input_name:
		CCFComfyUIGenerationProfileServiceV0166.INPUT_SEED,
		CCFComfyUIGenerationProfileServiceV0166.INPUT_STEPS,
		CCFComfyUIGenerationProfileServiceV0166.INPUT_WIDTH,
		CCFComfyUIGenerationProfileServiceV0166.INPUT_HEIGHT:
			return "integer"
		CCFComfyUIGenerationProfileServiceV0166.INPUT_CFG,
		CCFComfyUIGenerationProfileServiceV0166.INPUT_DENOISE:
			return "number"
		CCFComfyUIGenerationProfileServiceV0166.INPUT_PROMPT,
		CCFComfyUIGenerationProfileServiceV0166.INPUT_NEGATIVE_PROMPT:
			return "text"
		_:
			return "auto"


func _make_label_v0166(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	return label
