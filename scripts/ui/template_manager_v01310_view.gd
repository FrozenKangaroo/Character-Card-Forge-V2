class_name CCFTemplateManagerV01310View
extends CCFTemplateManagerV013View

var _default_template_button: Button
var _default_template_hint: Label
var _preference_settings: Dictionary = {}


func _ready() -> void:
	super._ready()
	_build_default_template_toolbar()
	refresh_templates(_current_template_id)


func refresh_templates(select_template_id := "") -> void:
	_preference_settings = CCFSettingsService.load_settings()
	var repaired := CCFTemplatePreferenceService.repair_missing_default(_preference_settings)
	if repaired:
		CCFSettingsService.save_settings(_preference_settings)
	super.refresh_templates(select_template_id)
	_mark_default_template_in_list()
	_update_default_template_controls()


func _build_default_template_toolbar() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_default_template_hint = Label.new()
	_default_template_hint.text = "The default template is assigned automatically to new characters. Existing characters keep their own assigned template."
	_default_template_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_default_template_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_default_template_hint)
	_default_template_button = Button.new()
	_default_template_button.text = "Set as Default"
	_default_template_button.tooltip_text = "Use the selected template automatically for future new characters. Existing characters are not changed."
	_default_template_button.pressed.connect(_set_selected_as_default)
	row.add_child(_default_template_button)
	add_child(row)
	move_child(row, 1)


func _set_selected_as_default() -> void:
	if _current_template_id.is_empty():
		return
	_preference_settings = CCFSettingsService.load_settings()
	var resolved := CCFTemplatePreferenceService.set_default_template_id(
		_preference_settings, _current_template_id
	)
	var save_result := CCFSettingsService.save_settings(_preference_settings)
	if not bool(save_result.get("ok", false)):
		_status.text = str(save_result.get("error", "Could not save the default template."))
		return
	refresh_templates(_current_template_id)
	templates_changed.emit()
	_status.text = "'%s' is now the default template for new characters." % str(_current_template.get("name", resolved))


func _delete_template() -> void:
	var deleting_id := _current_template_id
	var was_default := (
		CCFTemplatePreferenceService.default_template_id(CCFSettingsService.load_settings())
		== deleting_id
	)
	var result := CCFTemplateService.delete_template(deleting_id)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not delete template."))
		return
	if was_default:
		_preference_settings = CCFSettingsService.load_settings()
		CCFTemplatePreferenceService.set_default_template_id(_preference_settings, "default")
		CCFSettingsService.save_settings(_preference_settings)
	_current_template_id = ""
	templates_changed.emit()
	refresh_templates("default")
	_status.text = (
		"Template deleted. The built-in Default template is now the default for new characters."
		if was_default
		else "Template deleted."
	)


func _mark_default_template_in_list() -> void:
	if _template_list == null:
		return
	var default_id := CCFTemplatePreferenceService.default_template_id(_preference_settings)
	for index in range(_template_list.item_count):
		var template_id := str(_template_list.get_item_metadata(index))
		var label := _template_list.get_item_text(index)
		label = label.replace("  • Default", "")
		if template_id == default_id:
			label += "  • Default"
		_template_list.set_item_text(index, label)


func _update_default_template_controls() -> void:
	if _default_template_button == null:
		return
	var default_id := CCFTemplatePreferenceService.default_template_id(_preference_settings)
	var selected_is_default := not _current_template_id.is_empty() and _current_template_id == default_id
	_default_template_button.disabled = _current_template_id.is_empty() or selected_is_default
	_default_template_button.text = "Default Template ✓" if selected_is_default else "Set as Default"
