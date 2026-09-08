class_name CCFCardWorkflowWindowV0174
extends CCFCardWorkflowWindow

const GROUP_SERVICE_V0174 = preload(
	"res://scripts/services/front_porch_group_card_service_v0174.gd"
)

var _group_panel_v0174: VBoxContainer
var _turn_order_v0174: OptionButton
var _auto_advance_v0174: CheckBox
var _director_mode_v0174: CheckBox
var _inherit_lorebooks_v0174: CheckBox
var _chaos_mode_v0174: CheckBox
var _chaos_nsfw_v0174: CheckBox
var _group_system_prompt_v0174: TextEdit
var _group_lorebook_v0174: TextEdit
var _world_ids_v0174: LineEdit
var _world_names_v0174: LineEdit
var _character_prompts_v0174: TextEdit
var _member_objectives_v0174: TextEdit
var _baseline_realism_v0174: TextEdit
var _default_realism_v0174: TextEdit
var _extensions_v0174: TextEdit
var _preserved_fields_v0174: Dictionary = {}
var _group_generate_button_v0174: Button
var _group_job_id_v0174 := ""


func _build_ui() -> void:
	super._build_ui()
	_build_group_fields_v0174()
	_mode_selector.item_selected.connect(func(_index: int): _refresh_group_visibility_v0174())
	_refresh_group_visibility_v0174()


func _build_group_fields_v0174() -> void:
	_group_panel_v0174 = VBoxContainer.new()
	_group_panel_v0174.add_theme_constant_override("separation", 8)
	_member_root.get_parent().add_child(_group_panel_v0174)
	_group_panel_v0174.add_child(HSeparator.new())
	var heading := Label.new()
	heading.text = "Front Porch Group Card — Optional"
	heading.add_theme_font_size_override("font_size", 18)
	_group_panel_v0174.add_child(heading)
	var hint := Label.new()
	hint.text = (
		"Used only by Group-card plan mode. Every field can be edited manually; AI can draft "
		+ "the writing fields. Neutral realism defaults can be restored at any time."
	)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.68, 0.72, 0.82)
	_group_panel_v0174.add_child(hint)
	var actions := HFlowContainer.new()
	_group_panel_v0174.add_child(actions)
	_group_generate_button_v0174 = Button.new()
	_group_generate_button_v0174.text = "Generate Group Writing"
	_group_generate_button_v0174.pressed.connect(_generate_group_fields_v0174)
	actions.add_child(_group_generate_button_v0174)
	var defaults_button := Button.new()
	defaults_button.text = "Restore Neutral Realism"
	defaults_button.pressed.connect(_restore_realism_defaults_v0174)
	actions.add_child(defaults_button)
	_turn_order_v0174 = OptionButton.new()
	_turn_order_v0174.add_item("Round robin")
	_turn_order_v0174.set_item_metadata(0, "roundRobin")
	_turn_order_v0174.add_item("Random")
	_turn_order_v0174.set_item_metadata(1, "random")
	_group_panel_v0174.add_child(_label_v0174("Turn order"))
	_group_panel_v0174.add_child(_turn_order_v0174)
	_auto_advance_v0174 = _check_v0174("Automatically advance to the next member", true)
	_director_mode_v0174 = _check_v0174("Enable director mode", false)
	_inherit_lorebooks_v0174 = _check_v0174("Inherit each character's lorebook", true)
	_chaos_mode_v0174 = _check_v0174("Enable chaos mode", false)
	_chaos_nsfw_v0174 = _check_v0174("Allow adult chaos events", false)
	for checkbox in [_auto_advance_v0174, _director_mode_v0174, _inherit_lorebooks_v0174,
		_chaos_mode_v0174, _chaos_nsfw_v0174]:
		_group_panel_v0174.add_child(checkbox)
	_group_system_prompt_v0174 = _group_text_v0174("Group system prompt", 110)
	_group_lorebook_v0174 = _group_text_v0174("Group lorebook JSON (or leave empty)", 100)
	_world_ids_v0174 = _group_line_v0174("World IDs — comma separated")
	_world_names_v0174 = _group_line_v0174("World names — comma separated")
	_character_prompts_v0174 = _group_text_v0174("Per-character system prompts JSON", 130)
	_member_objectives_v0174 = _group_text_v0174("Member objectives JSON", 150)
	_baseline_realism_v0174 = _group_text_v0174("Baseline realism JSON", 140)
	_default_realism_v0174 = _group_text_v0174("Default per-member realism JSON", 180)
	_extensions_v0174 = _group_text_v0174("Front Porch extensions JSON — optional", 100)


func _label_v0174(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	return label


func _check_v0174(text_value: String, enabled: bool) -> CheckBox:
	var checkbox := CheckBox.new()
	checkbox.text = text_value
	checkbox.button_pressed = enabled
	return checkbox


func _group_text_v0174(label_text: String, height: int) -> TextEdit:
	_group_panel_v0174.add_child(_label_v0174(label_text))
	var editor := TextEdit.new()
	editor.custom_minimum_size.y = height
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_group_panel_v0174.add_child(editor)
	return editor


func _group_line_v0174(label_text: String) -> LineEdit:
	_group_panel_v0174.add_child(_label_v0174(label_text))
	var editor := LineEdit.new()
	_group_panel_v0174.add_child(editor)
	return editor


func _new_draft() -> void:
	super._new_draft()
	if _group_panel_v0174 != null:
		_load_group_options_v0174(GROUP_SERVICE_V0174.default_group_options(_project, {}))
		_refresh_group_visibility_v0174()


func _load_workflow(workflow: Dictionary) -> void:
	super._load_workflow(workflow)
	var options = workflow.get("front_porch_group", {})
	if not options is Dictionary:
		options = {}
	var merged := GROUP_SERVICE_V0174.default_group_options(_project, workflow)
	merged.merge(options, true)
	_load_group_options_v0174(merged)
	_refresh_group_visibility_v0174()


func _load_generated_result(data: Dictionary, metadata: Dictionary) -> void:
	super._load_generated_result(data, metadata)
	_refresh_group_visibility_v0174()


func handle_job_completed(job_id: String, data: Variant, metadata: Dictionary) -> bool:
	if job_id != _group_job_id_v0174:
		return super.handle_job_completed(job_id, data, metadata)
	_group_job_id_v0174 = ""
	_group_generate_button_v0174.disabled = false
	if str(metadata.get("project_id", "")) != _project_id or not data is Dictionary:
		_status.text = "The generated group writing could not be applied to this project."
		return true
	_group_system_prompt_v0174.text = str(data.get("system_prompt", ""))
	_group_lorebook_v0174.text = str(data.get("group_lorebook", ""))
	_character_prompts_v0174.text = JSON.stringify(data.get("character_system_prompts", {}), "  ")
	_member_objectives_v0174.text = JSON.stringify(data.get("member_objectives", {}), "  ")
	_status.text = "Front Porch group writing generated. Review and edit it before saving the workflow."
	return true


func handle_job_failed(job_id: String, message: String) -> bool:
	if job_id != _group_job_id_v0174:
		return super.handle_job_failed(job_id, message)
	_group_job_id_v0174 = ""
	_group_generate_button_v0174.disabled = false
	_status.text = message
	return true


func handle_job_cancelled(job_id: String) -> bool:
	if job_id != _group_job_id_v0174:
		return super.handle_job_cancelled(job_id)
	_group_job_id_v0174 = ""
	_group_generate_button_v0174.disabled = false
	_status.text = "Front Porch group writing generation cancelled."
	return true


func _generate_group_fields_v0174() -> void:
	project_refresh_requested.emit()
	if _generation_service == null or not _generation_service.has_method("queue_front_porch_group_generation_v0174"):
		_status.text = "Front Porch group writing generation is unavailable."
		return
	var selected_ids := _selected_character_ids()
	if selected_ids.size() < 2:
		_status.text = "Select at least two characters first."
		return
	var profile := CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_TEXT)
	var generation_settings = _settings.get("generation", {})
	var retry_count := int(generation_settings.get("retry_count", 1)) if generation_settings is Dictionary else 1
	var queued: Dictionary = _generation_service.call(
		"queue_front_porch_group_generation_v0174", _project, selected_ids,
		_instructions.text, profile, retry_count
	)
	if not bool(queued.get("ok", false)):
		_status.text = str(queued.get("error", "Could not queue group writing generation."))
		return
	_group_job_id_v0174 = str(queued.get("job_id", ""))
	_group_generate_button_v0174.disabled = true
	_status.text = "Front Porch group writing queued."


func _save_workflow() -> void:
	var selected_ids := _selected_character_ids()
	if selected_ids.size() < 2:
		_status.text = "Select at least two characters before saving this workflow."
		return
	if _selected_mode() == "group_card":
		var validation := _validate_group_editors_v0174()
		if not validation.is_empty():
			_status.text = validation
			return
	if _current_workflow_id.is_empty():
		_current_workflow_id = "workflow_%d" % Time.get_ticks_usec()
	var now := Time.get_datetime_string_from_system(true)
	var existing := _find_workflow(_current_workflow_id)
	var workflow := {
		"workflow_id": _current_workflow_id,
		"created_at": str(existing.get("created_at", now)),
		"updated_at": now,
		"mode": _selected_mode(),
		"title": _title_edit.text,
		"selected_character_ids": selected_ids,
		"instructions": _instructions.text,
		"summary": _summary_edit.text,
		"shared_scenario": _shared_scenario_edit.text,
		"opening_message": _opening_message_edit.text,
		"notes": _notes_edit.text,
		"members": _capture_members(),
		"front_porch_group": _capture_group_options_v0174()
	}
	workflow_saved.emit(workflow)
	_status.text = "Workflow draft saved into the project. Save the project file when ready."


func _validate_group_editors_v0174() -> String:
	for field in [
		{"name": "Per-character system prompts", "editor": _character_prompts_v0174, "allow_empty": false},
		{"name": "Member objectives", "editor": _member_objectives_v0174, "allow_empty": false},
		{"name": "Baseline realism", "editor": _baseline_realism_v0174, "allow_empty": false},
		{"name": "Default per-member realism", "editor": _default_realism_v0174, "allow_empty": false},
		{"name": "Front Porch extensions", "editor": _extensions_v0174, "allow_empty": true}
	]:
		var editor: TextEdit = field.get("editor")
		var text_value := editor.text.strip_edges()
		if text_value.is_empty() and bool(field.get("allow_empty", false)):
			continue
		if not JSON.parse_string(text_value) is Dictionary:
			return "%s must be a valid JSON object." % str(field.get("name", "This field"))
	var lorebook := _group_lorebook_v0174.text.strip_edges()
	if not lorebook.is_empty() and JSON.parse_string(lorebook) == null:
		return "Group lorebook must contain valid JSON or be empty."
	return ""


func _capture_group_options_v0174() -> Dictionary:
	return {
		"turn_order": str(_turn_order_v0174.get_item_metadata(_turn_order_v0174.selected)),
		"auto_advance": _auto_advance_v0174.button_pressed,
		"director_mode": _director_mode_v0174.button_pressed,
		"system_prompt": _group_system_prompt_v0174.text,
		"character_system_prompts": _parse_object_v0174(_character_prompts_v0174.text),
		"group_lorebook": _group_lorebook_v0174.text,
		"world_ids": _split_list_v0174(_world_ids_v0174.text),
		"world_names": _split_list_v0174(_world_names_v0174.text),
		"inherit_character_lorebooks": _inherit_lorebooks_v0174.button_pressed,
		"chaos_mode_enabled": _chaos_mode_v0174.button_pressed,
		"chaos_nsfw_enabled": _chaos_nsfw_v0174.button_pressed,
		"baseline_realism_state": _baseline_realism_v0174.text,
		"default_member_realism_state": _default_realism_v0174.text,
		"member_objectives": _parse_object_v0174(_member_objectives_v0174.text),
		"extensions": _parse_object_v0174(_extensions_v0174.text),
		"preserved_fields": _preserved_fields_v0174.duplicate(true)
	}


func _load_group_options_v0174(options: Dictionary) -> void:
	var turn_order := str(options.get("turn_order", "roundRobin"))
	_turn_order_v0174.select(1 if turn_order == "random" else 0)
	_auto_advance_v0174.button_pressed = bool(options.get("auto_advance", true))
	_director_mode_v0174.button_pressed = bool(options.get("director_mode", false))
	_inherit_lorebooks_v0174.button_pressed = bool(options.get("inherit_character_lorebooks", true))
	_chaos_mode_v0174.button_pressed = bool(options.get("chaos_mode_enabled", false))
	_chaos_nsfw_v0174.button_pressed = bool(options.get("chaos_nsfw_enabled", false))
	_group_system_prompt_v0174.text = str(options.get("system_prompt", ""))
	_group_lorebook_v0174.text = str(options.get("group_lorebook", ""))
	_world_ids_v0174.text = ", ".join(PackedStringArray(options.get("world_ids", [])))
	_world_names_v0174.text = ", ".join(PackedStringArray(options.get("world_names", [])))
	_character_prompts_v0174.text = JSON.stringify(options.get("character_system_prompts", {}), "  ")
	_member_objectives_v0174.text = JSON.stringify(options.get("member_objectives", {}), "  ")
	_baseline_realism_v0174.text = str(options.get("baseline_realism_state", "{}"))
	_default_realism_v0174.text = str(options.get("default_member_realism_state", "{}"))
	_extensions_v0174.text = JSON.stringify(options.get("extensions", {}), "  ")
	var preserved = options.get("preserved_fields", {})
	_preserved_fields_v0174 = preserved.duplicate(true) if preserved is Dictionary else {}


func _restore_realism_defaults_v0174() -> void:
	var workflow := {"selected_character_ids": _selected_character_ids()}
	var defaults := GROUP_SERVICE_V0174.default_group_options(_project, workflow)
	_baseline_realism_v0174.text = str(defaults.get("baseline_realism_state", "{}"))
	_default_realism_v0174.text = str(defaults.get("default_member_realism_state", "{}"))
	var prompts: Dictionary = {}
	var objectives: Dictionary = {}
	for character_id in _selected_character_ids():
		prompts[character_id] = str(_parse_object_v0174(_character_prompts_v0174.text).get(character_id, ""))
		objectives[character_id] = _parse_object_v0174(_member_objectives_v0174.text).get(character_id, [])
	_character_prompts_v0174.text = JSON.stringify(prompts, "  ")
	_member_objectives_v0174.text = JSON.stringify(objectives, "  ")
	_status.text = "Neutral Front Porch realism defaults restored for the selected members."


func _refresh_group_visibility_v0174() -> void:
	if _group_panel_v0174 != null:
		_group_panel_v0174.visible = _selected_mode() == "group_card"


func _parse_object_v0174(text_value: String) -> Dictionary:
	var parsed = JSON.parse_string(text_value)
	return parsed if parsed is Dictionary else {}


func _split_list_v0174(text_value: String) -> Array[String]:
	var result: Array[String] = []
	for raw_value in text_value.replace("\n", ",").split(","):
		var clean_value := str(raw_value).strip_edges()
		if not clean_value.is_empty() and clean_value not in result:
			result.append(clean_value)
	return result
