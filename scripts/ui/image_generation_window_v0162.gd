class_name CCFImageGenerationWindowV0162
extends "res://scripts/ui/image_generation_window_v0161.gd"

const PROMPT_COMPOSER_V0162 = preload(
	"res://scripts/services/image_prompt_composer_service_v0162.gd"
)

var _creative_catalog_v0162: Dictionary = {}
var _creative_panel_v0162: VBoxContainer
var _creative_subject_v0162: LineEdit
var _creative_selectors_v0162: Dictionary = {}
var _creative_modifier_checks_v0162: Dictionary = {}
var _creative_contributions_v0162: Label
var _creative_compose_button_v0162: Button
var _creative_reset_button_v0162: Button


func _ready() -> void:
	super._ready()
	ensure_structured_prompt_surface_v0162()


func _build_ui() -> void:
	super._build_ui()
	_install_structured_prompt_surface_v0162()


func structured_prompt_capabilities_v0162() -> Dictionary:
	return {
		"version": "0.16.2",
		"provider_independent": true,
		"external_versioned_catalog": true,
		"deterministic_composition_order": true,
		"visual_style": true,
		"medium": true,
		"camera_composition": true,
		"lighting": true,
		"colour_palette": true,
		"material_surface": true,
		"atmosphere_elements": true,
		"multi_modifier_selection": true,
		"editable_final_prompt": true,
		"contribution_transparency": true,
		"no_provider_request_on_browse": true
	}


func ensure_structured_prompt_surface_v0162() -> void:
	_install_structured_prompt_surface_v0162()
	_refresh_contribution_summary_v0162()


func structured_prompt_surface_ready_v0162() -> bool:
	return (
		_creative_panel_v0162 != null
		and is_instance_valid(_creative_panel_v0162)
		and _creative_panel_v0162.is_inside_tree()
		and _creative_compose_button_v0162 != null
		and is_instance_valid(_creative_compose_button_v0162)
	)


func current_creative_selection_v0162() -> Dictionary:
	var selections := {"categories": {}, "modifiers": []}
	for category_id_variant in _creative_selectors_v0162.keys():
		var category_id := str(category_id_variant)
		var selector: OptionButton = _creative_selectors_v0162.get(category_id)
		if selector == null or selector.selected < 0:
			continue
		selections["categories"][category_id] = str(selector.get_selected_metadata())
	for modifier_id_variant in _creative_modifier_checks_v0162.keys():
		var modifier_id := str(modifier_id_variant)
		var check: CheckButton = _creative_modifier_checks_v0162.get(modifier_id)
		if check != null and check.button_pressed:
			selections["modifiers"].append(modifier_id)
	return selections


func compose_current_prompt_v0162() -> Dictionary:
	if _creative_catalog_v0162.is_empty():
		return {"ok": false, "error": "Creative prompt catalog is unavailable."}
	var base_prompt := ""
	if _creative_subject_v0162 != null:
		base_prompt = _creative_subject_v0162.text.strip_edges()
	if base_prompt.is_empty() and _prompt_edit != null:
		base_prompt = _prompt_edit.text.strip_edges()
	var selections := current_creative_selection_v0162()
	var result := PROMPT_COMPOSER_V0162.compose(base_prompt, selections, _creative_catalog_v0162)
	result["ok"] = true
	return result


func _install_structured_prompt_surface_v0162() -> void:
	if _creative_panel_v0162 != null and is_instance_valid(_creative_panel_v0162):
		return
	if _prompt_edit == null or _prompt_edit.get_parent() == null:
		return
	var prompt_side := _prompt_edit.get_parent()
	var body := prompt_side.get_parent()
	if body == null or body.get_parent() == null:
		return
	var root := body.get_parent()

	var catalog_result := PROMPT_COMPOSER_V0162.load_catalog()
	if not bool(catalog_result.get("ok", false)):
		if _status != null:
			_status.text = "Image Studio creative controls unavailable: %s" % str(catalog_result.get("error", "Unknown catalog error"))
		return
	_creative_catalog_v0162 = (catalog_result.get("catalog", {}) as Dictionary).duplicate(true)

	var panel_container := PanelContainer.new()
	panel_container.name = "ImageStudioCreativePanelContainerV0162"
	panel_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(panel_container)
	root.move_child(panel_container, body.get_index())

	_creative_panel_v0162 = VBoxContainer.new()
	_creative_panel_v0162.name = "ImageStudioCreativeControlsV0162"
	_creative_panel_v0162.add_theme_constant_override("separation", 6)
	panel_container.add_child(_creative_panel_v0162)

	var heading_row := HBoxContainer.new()
	heading_row.add_theme_constant_override("separation", 8)
	_creative_panel_v0162.add_child(heading_row)
	var heading := Label.new()
	heading.text = "Structured Creative Controls"
	heading.add_theme_font_size_override("font_size", 16)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(heading)
	var portability := Label.new()
	portability.text = "Provider-independent"
	portability.modulate = Color(0.62, 0.72, 0.86)
	portability.tooltip_text = "These selections describe creative intent. Switching Image providers/models does not change their meaning."
	heading_row.add_child(portability)

	var subject_row := HBoxContainer.new()
	subject_row.add_theme_constant_override("separation", 8)
	_creative_panel_v0162.add_child(subject_row)
	var subject_label := Label.new()
	subject_label.text = "Base / subject"
	subject_row.add_child(subject_label)
	_creative_subject_v0162 = LineEdit.new()
	_creative_subject_v0162.name = "ImageStudioCreativeSubjectV0162"
	_creative_subject_v0162.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_creative_subject_v0162.placeholder_text = "Optional base subject/scene. If blank, Compose uses the current Image prompt as its base."
	_creative_subject_v0162.text_changed.connect(_on_creative_selection_changed_v0162)
	subject_row.add_child(_creative_subject_v0162)

	var categories_flow := HFlowContainer.new()
	categories_flow.name = "ImageStudioCreativeCategoryFlowV0162"
	categories_flow.add_theme_constant_override("h_separation", 8)
	categories_flow.add_theme_constant_override("v_separation", 5)
	_creative_panel_v0162.add_child(categories_flow)
	for category_variant in _creative_catalog_v0162.get("categories", []):
		if not category_variant is Dictionary:
			continue
		var category: Dictionary = category_variant
		var category_id := str(category.get("id", "")).strip_edges()
		if category_id.is_empty():
			continue
		var field := VBoxContainer.new()
		field.custom_minimum_size.x = 175
		field.add_theme_constant_override("separation", 2)
		categories_flow.add_child(field)
		var label := Label.new()
		label.text = str(category.get("label", category_id))
		label.modulate = Color(0.76, 0.8, 0.88)
		field.add_child(label)
		var selector := OptionButton.new()
		selector.name = "CreativeSelector_%s_V0162" % category_id
		selector.custom_minimum_size.x = 175
		for option_variant in category.get("options", []):
			if not option_variant is Dictionary:
				continue
			var option: Dictionary = option_variant
			selector.add_item(str(option.get("label", option.get("id", "Option"))))
			selector.set_item_metadata(selector.item_count - 1, str(option.get("id", "")))
		selector.item_selected.connect(_on_creative_selector_changed_v0162.bind(category_id))
		field.add_child(selector)
		_creative_selectors_v0162[category_id] = selector

	var modifiers_label := Label.new()
	modifiers_label.text = "Modifiers"
	modifiers_label.modulate = Color(0.76, 0.8, 0.88)
	_creative_panel_v0162.add_child(modifiers_label)
	var modifiers_flow := HFlowContainer.new()
	modifiers_flow.name = "ImageStudioCreativeModifiersV0162"
	modifiers_flow.add_theme_constant_override("h_separation", 8)
	modifiers_flow.add_theme_constant_override("v_separation", 3)
	_creative_panel_v0162.add_child(modifiers_flow)
	for modifier_variant in _creative_catalog_v0162.get("modifiers", []):
		if not modifier_variant is Dictionary:
			continue
		var modifier: Dictionary = modifier_variant
		var modifier_id := str(modifier.get("id", "")).strip_edges()
		if modifier_id.is_empty():
			continue
		var check := CheckButton.new()
		check.name = "CreativeModifier_%s_V0162" % modifier_id
		check.text = str(modifier.get("label", modifier_id))
		check.tooltip_text = str(modifier.get("prompt", ""))
		check.toggled.connect(_on_creative_modifier_toggled_v0162.bind(modifier_id))
		modifiers_flow.add_child(check)
		_creative_modifier_checks_v0162[modifier_id] = check

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	_creative_panel_v0162.add_child(action_row)
	_creative_compose_button_v0162 = Button.new()
	_creative_compose_button_v0162.name = "ImageStudioComposePromptButtonV0162"
	_creative_compose_button_v0162.text = "Compose into Image Prompt"
	_creative_compose_button_v0162.tooltip_text = "Apply the selected creative intent to the editable Image prompt without calling any provider."
	_creative_compose_button_v0162.pressed.connect(_compose_into_prompt_v0162)
	action_row.add_child(_creative_compose_button_v0162)
	_creative_reset_button_v0162 = Button.new()
	_creative_reset_button_v0162.name = "ImageStudioResetCreativeControlsV0162"
	_creative_reset_button_v0162.text = "Reset Controls"
	_creative_reset_button_v0162.pressed.connect(_reset_creative_controls_v0162)
	action_row.add_child(_creative_reset_button_v0162)
	_creative_contributions_v0162 = Label.new()
	_creative_contributions_v0162.name = "ImageStudioCreativeContributionsV0162"
	_creative_contributions_v0162.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_creative_contributions_v0162.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_creative_contributions_v0162.modulate = Color(0.62, 0.69, 0.8)
	action_row.add_child(_creative_contributions_v0162)

	_refresh_contribution_summary_v0162()


func _compose_into_prompt_v0162() -> void:
	if _prompt_edit == null:
		return
	var result := compose_current_prompt_v0162()
	if not bool(result.get("ok", false)):
		if _status != null:
			_status.text = str(result.get("error", "Could not compose the image prompt."))
		return
	_prompt_edit.text = str(result.get("prompt", ""))
	_refresh_contribution_summary_v0162()
	if _status != null:
		_status.text = "Applied structured creative controls locally. The final Image prompt remains fully editable."


func _reset_creative_controls_v0162() -> void:
	if _creative_subject_v0162 != null:
		_creative_subject_v0162.text = ""
	for selector_variant in _creative_selectors_v0162.values():
		var selector: OptionButton = selector_variant
		if selector != null and selector.item_count > 0:
			selector.select(0)
	for check_variant in _creative_modifier_checks_v0162.values():
		var check: CheckButton = check_variant
		if check != null:
			check.button_pressed = false
	_refresh_contribution_summary_v0162()
	if _status != null:
		_status.text = "Reset structured creative controls. The existing Image prompt was left unchanged."


func _on_creative_selector_changed_v0162(_index: int, _category_id: String) -> void:
	_refresh_contribution_summary_v0162()


func _on_creative_modifier_toggled_v0162(_pressed: bool, _modifier_id: String) -> void:
	_refresh_contribution_summary_v0162()


func _on_creative_selection_changed_v0162(_text: String) -> void:
	_refresh_contribution_summary_v0162()


func _refresh_contribution_summary_v0162() -> void:
	if _creative_contributions_v0162 == null or _creative_catalog_v0162.is_empty():
		return
	var rows := PROMPT_COMPOSER_V0162.contribution_rows(current_creative_selection_v0162(), _creative_catalog_v0162)
	if rows.is_empty():
		_creative_contributions_v0162.text = "No creative modifiers selected."
		_creative_contributions_v0162.tooltip_text = "Select structured controls, then compose them into the editable Image prompt."
		return
	var labels: Array[String] = []
	var detail_lines: Array[String] = []
	for row in rows:
		labels.append(str(row.get("label", "")))
		detail_lines.append("%s: %s" % [str(row.get("category", "")), str(row.get("prompt", ""))])
	_creative_contributions_v0162.text = "Adds: %s" % ", ".join(labels)
	_creative_contributions_v0162.tooltip_text = "\n".join(detail_lines)
