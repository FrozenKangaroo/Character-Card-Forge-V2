class_name CCFTemplateManagerV013View
extends CCFTemplateManagerView

var _generation_editor: CCFGenerationComponentEditorGuardWindow
var _generation_button: Button


func _ready() -> void:
	super._ready()
	_generation_editor = CCFGenerationComponentEditorGuardWindow.new()
	_generation_editor.visible = false
	_generation_editor.groups_applied.connect(_on_generation_groups_applied)
	add_child(_generation_editor)
	_generation_editor.hide()
	_build_generation_toolbar()
	_update_generation_button()


func refresh_templates(select_template_id := "") -> void:
	super.refresh_templates(select_template_id)
	_update_generation_button()


func _build_generation_toolbar() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var hint := Label.new()
	hint.text = "Generation structure controls the labelled subfields the AI builds inside normal card fields such as Description and Personality."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(hint)
	_generation_button = Button.new()
	_generation_button.text = "Edit Generation Components"
	_generation_button.tooltip_text = "Add, remove, reorder, enable or disable structured generation components and choose which card field they fold into."
	_generation_button.pressed.connect(_open_generation_editor)
	row.add_child(_generation_button)
	add_child(row)
	move_child(row, 1)


func _open_generation_editor() -> void:
	if _current_template.is_empty():
		return
	_generation_editor.open_for_template(_current_template, _current_template_id == "default")


func _on_generation_groups_applied(groups: Array) -> void:
	if _current_template_id.is_empty() or _current_template_id == "default":
		return
	_current_template["generation_groups"] = groups.duplicate(true)
	_status.text = "Generation components changed. Press Save Template to persist them."
	_update_generation_button()


func _update_generation_button() -> void:
	if _generation_button == null:
		return
	_generation_button.disabled = _current_template.is_empty()
	var group_count := 0
	var component_count := 0
	var raw_groups: Variant = _current_template.get("generation_groups", []) if not _current_template.is_empty() else []
	if raw_groups is Array:
		group_count = raw_groups.size()
		for raw_group in raw_groups:
			if raw_group is Dictionary:
				var raw_components: Variant = raw_group.get("components", [])
				if raw_components is Array:
					component_count += raw_components.size()
	_generation_button.text = "Edit Generation Components (%d / %d)" % [group_count, component_count]
