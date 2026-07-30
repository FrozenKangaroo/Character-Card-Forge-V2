class_name CCFSettingsV01310View
extends CCFSettingsV0135View

var _default_template_selector: OptionButton
var _default_template_status: Label


func _ready() -> void:
	super._ready()
	_build_authoring_defaults_tab()
	_populate_default_template_selector()


func load_settings(settings: Dictionary) -> void:
	super.load_settings(settings)
	if _default_template_selector != null:
		_populate_default_template_selector()


func _build_authoring_defaults_tab() -> void:
	if _tabs == null:
		return
	var root := _make_scroll_tab("Defaults")
	var heading := Label.new()
	heading.text = "Authoring defaults"
	heading.add_theme_font_size_override("font_size", 22)
	root.add_child(heading)
	var hint := Label.new()
	hint.text = "Choose the template automatically assigned to future new characters. Changing this setting never rewrites the template already assigned to an existing character."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.75, 0.77, 0.84)
	root.add_child(hint)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	root.add_child(grid)
	grid.add_child(_label("Default character template"))
	_default_template_selector = OptionButton.new()
	_default_template_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(_default_template_selector)
	var save_button := Button.new()
	save_button.text = "Save Authoring Defaults"
	save_button.custom_minimum_size = Vector2(190, 42)
	save_button.pressed.connect(_save_default_template_setting)
	root.add_child(save_button)
	_default_template_status = Label.new()
	_default_template_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_default_template_status.modulate = Color(0.72, 0.82, 0.72)
	root.add_child(_default_template_status)


func _populate_default_template_selector() -> void:
	if _default_template_selector == null:
		return
	_default_template_selector.clear()
	var requested := CCFTemplatePreferenceService.requested_default_template_id(_settings)
	var resolved := CCFTemplatePreferenceService.default_template_id(_settings)
	var selected_index := 0
	for raw_summary in CCFTemplateService.list_templates():
		if not raw_summary is Dictionary:
			continue
		var template_id := str(raw_summary.get("template_id", ""))
		var label := str(raw_summary.get("name", "Template"))
		if bool(raw_summary.get("built_in", false)):
			label += "  • Built-in"
		_default_template_selector.add_item(label)
		var index := _default_template_selector.item_count - 1
		_default_template_selector.set_item_metadata(index, template_id)
		if template_id == resolved:
			selected_index = index
	if _default_template_selector.item_count > 0:
		_default_template_selector.select(selected_index)
	if _default_template_status != null:
		if requested != resolved:
			_default_template_status.text = "The previously selected default template is no longer available. New characters will use the built-in Default template until you save another choice."
		else:
			_default_template_status.text = "Existing characters keep their assigned template when this default changes."


func _save_default_template_setting() -> void:
	if _default_template_selector == null or _default_template_selector.selected < 0:
		return
	var selected_id := str(_default_template_selector.get_selected_metadata())
	var resolved := CCFTemplatePreferenceService.set_default_template_id(_settings, selected_id)
	var result := CCFSettingsService.save_settings(_settings)
	if not bool(result.get("ok", false)):
		_default_template_status.text = str(result.get("error", "Could not save authoring defaults."))
		return
	_settings = CCFSettingsService.load_settings()
	_populate_default_template_selector()
	var template := CCFTemplateService.load_template(resolved)
	_default_template_status.text = "Default character template saved: %s." % str(template.get("name", "Default Character Card"))
	settings_saved.emit(_settings.duplicate(true))
