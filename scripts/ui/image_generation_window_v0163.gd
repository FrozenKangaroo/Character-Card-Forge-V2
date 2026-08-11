class_name CCFImageGenerationWindowV0163
extends "res://scripts/ui/image_generation_window_v0162.gd"

var _studio_tabs_v0163: TabContainer
var _prompt_page_v0163: MarginContainer
var _creative_page_v0163: MarginContainer
var _advanced_page_v0163: MarginContainer
var _advanced_stack_v0163: VBoxContainer


func _ready() -> void:
	super._ready()
	ensure_tabbed_layout_v0163()


func _build_ui() -> void:
	super._build_ui()
	_install_tabbed_layout_v0163()


func tabbed_image_studio_capabilities_v0163() -> Dictionary:
	return {
		"version": "0.16.3",
		"prompt_results_tab": true,
		"creative_tab": true,
		"advanced_optional_tab": true,
		"provider_model_context_stays_global": true,
		"technical_controls_progressively_disclosed": true,
		"capability_inspection_in_advanced": true,
		"preserves_v0162_prompt_composer": true,
		"preserves_v0161_capability_model": true
	}


func ensure_tabbed_layout_v0163() -> void:
	_install_tabbed_layout_v0163()


func tabbed_layout_ready_v0163() -> bool:
	return (
		_studio_tabs_v0163 != null
		and is_instance_valid(_studio_tabs_v0163)
		and _studio_tabs_v0163.is_inside_tree()
		and _studio_tabs_v0163.get_tab_count() == 3
		and _prompt_edit != null
		and _is_descendant_of_v0163(_prompt_edit, _prompt_page_v0163)
		and _creative_panel_v0162 != null
		and _is_descendant_of_v0163(_creative_panel_v0162, _creative_page_v0163)
		and _sampler_edit != null
		and _is_descendant_of_v0163(_sampler_edit, _advanced_page_v0163)
	)


func _install_tabbed_layout_v0163() -> void:
	if _studio_tabs_v0163 != null and is_instance_valid(_studio_tabs_v0163):
		return
	if _prompt_edit == null or _prompt_edit.get_parent() == null:
		return
	if _creative_panel_v0162 == null or _creative_panel_v0162.get_parent() == null:
		return
	if _sampler_edit == null or _sampler_edit.get_parent() == null:
		return

	var prompt_side := _prompt_edit.get_parent()
	var body := prompt_side.get_parent()
	if body == null:
		return
	var root := body.get_parent()
	if root == null:
		return

	var creative_container := _direct_child_under_v0163(_creative_panel_v0162, root)
	var advanced_row := _direct_child_under_v0163(_sampler_edit, root)
	var capability_row: Control = null
	if _capability_summary_v0161 != null and is_instance_valid(_capability_summary_v0161):
		capability_row = _direct_child_under_v0163(_capability_summary_v0161, root)
	if creative_container == null or advanced_row == null:
		return

	var insertion_index := mini(body.get_index(), creative_container.get_index())
	if capability_row != null:
		insertion_index = mini(insertion_index, capability_row.get_index())
	insertion_index = mini(insertion_index, advanced_row.get_index())

	_studio_tabs_v0163 = TabContainer.new()
	_studio_tabs_v0163.name = "ImageStudioTabsV0163"
	_studio_tabs_v0163.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_studio_tabs_v0163.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_studio_tabs_v0163.custom_minimum_size.y = 430
	root.add_child(_studio_tabs_v0163)
	root.move_child(_studio_tabs_v0163, insertion_index)

	_prompt_page_v0163 = _make_tab_page_v0163("Prompt & Results")
	_creative_page_v0163 = _make_tab_page_v0163("Creative")
	_advanced_page_v0163 = _make_tab_page_v0163("Advanced")
	_studio_tabs_v0163.add_child(_prompt_page_v0163)
	_studio_tabs_v0163.add_child(_creative_page_v0163)
	_studio_tabs_v0163.add_child(_advanced_page_v0163)

	var prompt_holder := VBoxContainer.new()
	prompt_holder.name = "ImageStudioPromptTabContentV0163"
	prompt_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_prompt_page_v0163.add_child(prompt_holder)
	_move_control_v0163(body, prompt_holder)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var creative_scroll := ScrollContainer.new()
	creative_scroll.name = "ImageStudioCreativeTabScrollV0163"
	creative_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	creative_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_creative_page_v0163.add_child(creative_scroll)
	var creative_holder := VBoxContainer.new()
	creative_holder.name = "ImageStudioCreativeTabContentV0163"
	creative_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	creative_scroll.add_child(creative_holder)
	_move_control_v0163(creative_container, creative_holder)

	var advanced_scroll := ScrollContainer.new()
	advanced_scroll.name = "ImageStudioAdvancedTabScrollV0163"
	advanced_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	advanced_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_advanced_page_v0163.add_child(advanced_scroll)
	_advanced_stack_v0163 = VBoxContainer.new()
	_advanced_stack_v0163.name = "ImageStudioAdvancedTabContentV0163"
	_advanced_stack_v0163.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_advanced_stack_v0163.add_theme_constant_override("separation", 10)
	advanced_scroll.add_child(_advanced_stack_v0163)

	var advanced_heading := Label.new()
	advanced_heading.text = "Optional model / backend controls"
	advanced_heading.add_theme_font_size_override("font_size", 16)
	_advanced_stack_v0163.add_child(advanced_heading)
	var advanced_hint := Label.new()
	advanced_hint.text = "These controls are useful for models/backends that expose them. Creative intent and the editable Image prompt stay independent of these technical settings."
	advanced_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	advanced_hint.modulate = Color(0.66, 0.71, 0.8)
	_advanced_stack_v0163.add_child(advanced_hint)

	if capability_row != null:
		_move_control_v0163(capability_row, _advanced_stack_v0163)
	_move_control_v0163(advanced_row, _advanced_stack_v0163)
	var inherited_advanced_hint := _find_root_label_v0163(root, "Sampler, Steps, CFG and Seed")
	if inherited_advanced_hint != null:
		_move_control_v0163(inherited_advanced_hint, _advanced_stack_v0163)

	_studio_tabs_v0163.set_tab_title(0, "Prompt & Results")
	_studio_tabs_v0163.set_tab_title(1, "Creative")
	_studio_tabs_v0163.set_tab_title(2, "Advanced")
	_studio_tabs_v0163.current_tab = 0


func _make_tab_page_v0163(page_name: String) -> MarginContainer:
	var page := MarginContainer.new()
	page.name = page_name
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("margin_left", 6)
	page.add_theme_constant_override("margin_right", 6)
	page.add_theme_constant_override("margin_top", 8)
	page.add_theme_constant_override("margin_bottom", 6)
	return page


func _direct_child_under_v0163(node: Node, ancestor: Node) -> Control:
	if node == null or ancestor == null:
		return null
	var current := node
	while current != null and current.get_parent() != ancestor:
		current = current.get_parent()
	return current as Control


func _move_control_v0163(control: Control, new_parent: Node) -> void:
	if control == null or new_parent == null or control.get_parent() == new_parent:
		return
	var old_parent := control.get_parent()
	if old_parent != null:
		old_parent.remove_child(control)
	new_parent.add_child(control)


func _find_root_label_v0163(root: Node, prefix: String) -> Label:
	if root == null:
		return null
	for child in root.get_children():
		if child is Label and (child as Label).text.begins_with(prefix):
			return child as Label
	return null


func _is_descendant_of_v0163(node: Node, ancestor: Node) -> bool:
	if node == null or ancestor == null:
		return false
	var current := node
	while current != null:
		if current == ancestor:
			return true
		current = current.get_parent()
	return false
