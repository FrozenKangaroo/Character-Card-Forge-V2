class_name CCFImageGenerationWindowV0169
extends "res://scripts/ui/image_generation_window_v0168.gd"

const STYLE_PRESET_SERVICE_V0169 = preload(
	"res://scripts/services/image_style_preset_service_v0169.gd"
)

var _style_panel_v0169: VBoxContainer
var _style_selector_v0169: OptionButton
var _style_name_v0169: LineEdit
var _style_description_v0169: Label
var _style_records_v0169: Array[Dictionary] = []
var _style_loading_v0169 := false


func _ready() -> void:
	super._ready()
	ensure_style_preset_surface_v0169()
	_refresh_style_presets_v0169()
	_apply_effective_default_v0169(false)


func _build_ui() -> void:
	super._build_ui()
	_install_style_preset_surface_v0169()


func style_preset_capabilities_v0169() -> Dictionary:
	return {
		"version": "0.16.9",
		"provider_independent": true,
		"built_in_versioned_catalog": true,
		"global_reusable_presets": true,
		"project_visual_identity": true,
		"per_character_defaults": true,
		"character_overrides_project": true,
		"technical_provider_settings_excluded": true,
		"passive_browsing_spends_provider_credits": false
	}


func ensure_style_preset_surface_v0169() -> void:
	_install_style_preset_surface_v0169()
	_refresh_style_presets_v0169()


func style_preset_surface_ready_v0169() -> bool:
	return (
		_style_panel_v0169 != null
		and is_instance_valid(_style_panel_v0169)
		and _style_panel_v0169.is_inside_tree()
		and _style_selector_v0169 != null
	)


func _load_project(project_id: String) -> void:
	super._load_project(project_id)
	call_deferred("_refresh_style_context_v0169")


func _on_character_selected(index: int) -> void:
	super._on_character_selected(index)
	call_deferred("_refresh_style_context_v0169")


func _refresh_style_context_v0169() -> void:
	_refresh_style_presets_v0169()
	_apply_effective_default_v0169(false)


func _install_style_preset_surface_v0169() -> void:
	if _style_panel_v0169 != null and is_instance_valid(_style_panel_v0169):
		return
	if _creative_panel_v0162 == null or not is_instance_valid(_creative_panel_v0162):
		return

	var panel := PanelContainer.new()
	panel.name = "ImageStudioStylePresetPanelV0169"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel_v0169 = VBoxContainer.new()
	_style_panel_v0169.name = "ImageStudioStylePresetControlsV0169"
	_style_panel_v0169.add_theme_constant_override("separation", 6)
	panel.add_child(_style_panel_v0169)
	_creative_panel_v0162.add_child(panel)
	_creative_panel_v0162.move_child(panel, 0)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	_style_panel_v0169.add_child(header)
	var heading := Label.new()
	heading.text = "Image Style Presets"
	heading.add_theme_font_size_override("font_size", 16)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var portability := Label.new()
	portability.text = "Creative intent only"
	portability.tooltip_text = "Style presets never store provider, model, checkpoint, sampler, steps, CFG, seed, transport or workflow settings."
	portability.modulate = Color(0.62, 0.72, 0.86)
	header.add_child(portability)

	var choose_row := HFlowContainer.new()
	choose_row.add_theme_constant_override("separation", 7)
	_style_panel_v0169.add_child(choose_row)
	choose_row.add_child(_label("Preset"))
	_style_selector_v0169 = OptionButton.new()
	_style_selector_v0169.name = "ImageStudioStylePresetSelectorV0169"
	_style_selector_v0169.custom_minimum_size.x = 260
	_style_selector_v0169.item_selected.connect(_on_style_preset_selected_v0169)
	choose_row.add_child(_style_selector_v0169)
	var apply_button := Button.new()
	apply_button.name = "ImageStudioApplyStylePresetV0169"
	apply_button.text = "Apply"
	apply_button.pressed.connect(_apply_selected_style_v0169)
	choose_row.add_child(apply_button)
	var refresh_button := Button.new()
	refresh_button.text = "Refresh"
	refresh_button.pressed.connect(_refresh_style_presets_v0169)
	choose_row.add_child(refresh_button)

	var save_row := HFlowContainer.new()
	save_row.add_theme_constant_override("separation", 7)
	_style_panel_v0169.add_child(save_row)
	save_row.add_child(_label("Name"))
	_style_name_v0169 = LineEdit.new()
	_style_name_v0169.name = "ImageStudioStylePresetNameV0169"
	_style_name_v0169.custom_minimum_size.x = 220
	_style_name_v0169.placeholder_text = "Reusable style name"
	save_row.add_child(_style_name_v0169)
	var save_global := Button.new()
	save_global.name = "ImageStudioSaveGlobalStyleV0169"
	save_global.text = "Save Global"
	save_global.tooltip_text = "Save the current structured Creative selections as a reusable preset available to all projects."
	save_global.pressed.connect(_save_global_style_v0169)
	save_row.add_child(save_global)
	var set_project := Button.new()
	set_project.name = "ImageStudioSetProjectStyleV0169"
	set_project.text = "Set Project Identity"
	set_project.tooltip_text = "Use the current Creative selections as this project's default visual identity."
	set_project.pressed.connect(_set_project_style_v0169)
	save_row.add_child(set_project)
	var set_character := Button.new()
	set_character.name = "ImageStudioSetCharacterStyleV0169"
	set_character.text = "Set Character Default"
	set_character.tooltip_text = "Use the current Creative selections as this character's style override. Character defaults override the project identity."
	set_character.pressed.connect(_set_character_style_v0169)
	save_row.add_child(set_character)

	var maintenance_row := HFlowContainer.new()
	maintenance_row.add_theme_constant_override("separation", 7)
	_style_panel_v0169.add_child(maintenance_row)
	var delete_global := Button.new()
	delete_global.text = "Delete Selected Global"
	delete_global.pressed.connect(_delete_selected_global_style_v0169)
	maintenance_row.add_child(delete_global)
	var clear_project := Button.new()
	clear_project.text = "Clear Project Identity"
	clear_project.pressed.connect(_clear_project_style_v0169)
	maintenance_row.add_child(clear_project)
	var clear_character := Button.new()
	clear_character.text = "Clear Character Default"
	clear_character.pressed.connect(_clear_character_style_v0169)
	maintenance_row.add_child(clear_character)

	_style_description_v0169 = Label.new()
	_style_description_v0169.name = "ImageStudioStylePresetDescriptionV0169"
	_style_description_v0169.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_description_v0169.modulate = Color(0.64, 0.7, 0.8)
	_style_panel_v0169.add_child(_style_description_v0169)

	_refresh_style_presets_v0169()


func _refresh_style_presets_v0169() -> void:
	if _style_selector_v0169 == null:
		return
	_style_loading_v0169 = true
	_style_records_v0169.clear()
	_style_selector_v0169.clear()
	for preset in STYLE_PRESET_SERVICE_V0169.load_builtin_presets():
		_add_style_record_v0169(preset, "Built-in")
	for preset in STYLE_PRESET_SERVICE_V0169.load_global_presets():
		_add_style_record_v0169(preset, "Global")
	if not _project.is_empty():
		var project_preset := STYLE_PRESET_SERVICE_V0169.project_default(_project)
		if not project_preset.is_empty():
			_add_style_record_v0169(project_preset, "Project")
		var character_preset := STYLE_PRESET_SERVICE_V0169.character_default(_project, _active_character_id)
		if not character_preset.is_empty():
			_add_style_record_v0169(character_preset, "Character")
	if _style_selector_v0169.item_count == 0:
		_style_selector_v0169.add_item("No presets available")
		_style_selector_v0169.set_item_disabled(0, true)
	else:
		_style_selector_v0169.select(0)
	_style_loading_v0169 = false
	_update_style_description_v0169()


func _add_style_record_v0169(preset: Dictionary, source_label: String) -> void:
	var record := preset.duplicate(true)
	record["source_label_v0169"] = source_label
	_style_records_v0169.append(record)
	_style_selector_v0169.add_item("%s — %s" % [source_label, str(record.get("name", "Style"))])
	_style_selector_v0169.set_item_metadata(_style_selector_v0169.item_count - 1, _style_records_v0169.size() - 1)


func _selected_style_record_v0169() -> Dictionary:
	if _style_selector_v0169 == null or _style_selector_v0169.selected < 0:
		return {}
	var record_index := int(_style_selector_v0169.get_selected_metadata())
	if record_index < 0 or record_index >= _style_records_v0169.size():
		return {}
	return _style_records_v0169[record_index].duplicate(true)


func _on_style_preset_selected_v0169(_index: int) -> void:
	if _style_loading_v0169:
		return
	_update_style_description_v0169()


func _update_style_description_v0169() -> void:
	if _style_description_v0169 == null:
		return
	var preset := _selected_style_record_v0169()
	if preset.is_empty():
		_style_description_v0169.text = "No style preset selected."
		return
	var scope := str(preset.get("source_label_v0169", preset.get("scope", "Preset")))
	var description := str(preset.get("description", "")).strip_edges()
	_style_description_v0169.text = "%s preset%s" % [scope, ": " + description if not description.is_empty() else "."]


func _apply_selected_style_v0169() -> void:
	var preset := _selected_style_record_v0169()
	if preset.is_empty():
		return
	_apply_style_preset_v0169(preset, true)


func _apply_style_preset_v0169(preset: Dictionary, show_status: bool) -> bool:
	if _creative_catalog_v0162.is_empty():
		return false
	var selection: Dictionary = preset.get("selection", {})
	if not STYLE_PRESET_SERVICE_V0169.selection_is_compatible(selection, _creative_catalog_v0162):
		if show_status and _status != null:
			_status.text = "This Image Style preset references creative options that are not available in the current catalog."
		return false
	var categories: Dictionary = selection.get("categories", {})
	for category_id_variant in _creative_selectors_v0162.keys():
		var category_id := str(category_id_variant)
		var selector: OptionButton = _creative_selectors_v0162.get(category_id)
		if selector == null:
			continue
		var wanted := str(categories.get(category_id, "none"))
		for index in range(selector.item_count):
			if str(selector.get_item_metadata(index)) == wanted:
				selector.select(index)
				break
	var modifiers: Array = selection.get("modifiers", [])
	for modifier_id_variant in _creative_modifier_checks_v0162.keys():
		var modifier_id := str(modifier_id_variant)
		var check: CheckButton = _creative_modifier_checks_v0162.get(modifier_id)
		if check != null:
			check.button_pressed = modifiers.has(modifier_id)
	_refresh_contribution_summary_v0162()
	if show_status and _status != null:
		_status.text = "Applied Image Style preset '%s' to the Creative controls. The editable Image prompt was not overwritten." % str(preset.get("name", "Style"))
	return true


func _current_style_preset_v0169(scope: String) -> Dictionary:
	var name_text := _style_name_v0169.text.strip_edges() if _style_name_v0169 != null else ""
	if name_text.is_empty():
		name_text = "Current Creative Style"
	var preset := STYLE_PRESET_SERVICE_V0169.make_preset(name_text, current_creative_selection_v0162())
	preset["scope"] = scope
	return preset


func _save_global_style_v0169() -> void:
	var preset := _current_style_preset_v0169("global")
	var result := STYLE_PRESET_SERVICE_V0169.upsert_global_preset(preset)
	if _status != null:
		_status.text = "Saved reusable global Image Style preset." if bool(result.get("ok", false)) else str(result.get("error", "Could not save Image Style preset."))
	_refresh_style_presets_v0169()


func _set_project_style_v0169() -> void:
	if _project.is_empty():
		if _status != null:
			_status.text = "Select a saved project before assigning a project visual identity."
		return
	var preset := _current_style_preset_v0169("project")
	STYLE_PRESET_SERVICE_V0169.set_project_default(_project, preset)
	_save_style_project_v0169("Saved the project visual identity.")


func _set_character_style_v0169() -> void:
	if _project.is_empty() or _active_character_id.is_empty():
		if _status != null:
			_status.text = "Select a saved character before assigning a character Image Style default."
		return
	var preset := _current_style_preset_v0169("character")
	if not STYLE_PRESET_SERVICE_V0169.set_character_default(_project, _active_character_id, preset):
		if _status != null:
			_status.text = "Could not find the selected character in the project."
		return
	_save_style_project_v0169("Saved the character Image Style default.")


func _clear_project_style_v0169() -> void:
	if _project.is_empty():
		return
	STYLE_PRESET_SERVICE_V0169.clear_project_default(_project)
	_save_style_project_v0169("Cleared the project visual identity.")


func _clear_character_style_v0169() -> void:
	if _project.is_empty() or _active_character_id.is_empty():
		return
	STYLE_PRESET_SERVICE_V0169.clear_character_default(_project, _active_character_id)
	_save_style_project_v0169("Cleared the character Image Style default. The project identity will apply when present.")
	_apply_effective_default_v0169(false)


func _delete_selected_global_style_v0169() -> void:
	var preset := _selected_style_record_v0169()
	if preset.is_empty() or str(preset.get("source_label_v0169", "")) != "Global":
		if _status != null:
			_status.text = "Only reusable Global presets can be deleted from this list."
		return
	var result := STYLE_PRESET_SERVICE_V0169.delete_global_preset(str(preset.get("id", "")))
	if _status != null:
		_status.text = "Deleted the selected Global Image Style preset." if bool(result.get("ok", false)) else str(result.get("error", "Could not delete the preset."))
	_refresh_style_presets_v0169()


func _save_style_project_v0169(success_text: String) -> void:
	var result := CCFStorageService.save_project(_project)
	if bool(result.get("ok", false)):
		project_changed.emit(_project.duplicate(true))
		if _status != null:
			_status.text = success_text
	else:
		if _status != null:
			_status.text = str(result.get("error", "Could not save Image Style defaults."))
	_refresh_style_presets_v0169()


func _apply_effective_default_v0169(show_status: bool) -> void:
	if _project.is_empty() or _active_character_id.is_empty():
		return
	var preset := STYLE_PRESET_SERVICE_V0169.effective_default(_project, _active_character_id)
	if preset.is_empty():
		return
	_apply_style_preset_v0169(preset, show_status)
