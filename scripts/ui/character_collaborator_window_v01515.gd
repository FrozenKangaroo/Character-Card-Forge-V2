class_name CCFCharacterCollaboratorWindowV01515
extends "res://scripts/ui/character_collaborator_window_v01513.gd"

const HANDOFF_BLUEPRINT_V01515 := 0
const HANDOFF_DETAILED_DRAFT_V01515 := 1

var _handoff_mode_v01515: OptionButton
var _handoff_label_v01515: Label


func _ready() -> void:
	super._ready()
	_install_handoff_mode_v01515()
	_refresh_action_state()


func _install_handoff_mode_v01515() -> void:
	if _generate_button == null or _generate_button.get_parent() == null:
		return
	var actions := _generate_button.get_parent()
	_handoff_label_v01515 = Label.new()
	_handoff_label_v01515.text = "Workspace handoff"
	_handoff_label_v01515.tooltip_text = "Choose whether the collaboration becomes one detailed Generation Concept blueprint or is immediately distributed into Workspace fields."
	actions.add_child(_handoff_label_v01515)
	actions.move_child(_handoff_label_v01515, _generate_button.get_index())

	_handoff_mode_v01515 = OptionButton.new()
	_handoff_mode_v01515.custom_minimum_size.x = 300
	_handoff_mode_v01515.add_item("Blueprint → Generation Concept (Recommended)", HANDOFF_BLUEPRINT_V01515)
	_handoff_mode_v01515.set_item_tooltip(
		HANDOFF_BLUEPRINT_V01515,
		"Ask the AI for a high-detail, loss-minimising canonical blueprint and place it in Generation Concept. Normal Generate Character then materialises the card from that source."
	)
	_handoff_mode_v01515.add_item("Detailed Workspace Draft", HANDOFF_DETAILED_DRAFT_V01515)
	_handoff_mode_v01515.set_item_tooltip(
		HANDOFF_DETAILED_DRAFT_V01515,
		"Immediately distribute the collaboration into detailed template fields, Alternative Greetings and the Character Lorebook."
	)
	_handoff_mode_v01515.select(HANDOFF_BLUEPRINT_V01515)
	actions.add_child(_handoff_mode_v01515)
	actions.move_child(_handoff_mode_v01515, _generate_button.get_index())

	_generate_button.text = "Send Character → Workspace"
	_generate_button.tooltip_text = "Use the selected handoff mode to materialise this collaboration into Workspace."


func _working_text_v0153() -> String:
	match _active_collaborator_job_type_v0153:
		"collaborator_blueprint":
			return "Character Collaborator is building a detailed Generation Blueprint…"
		"collaborator_character_detailed":
			return "Character Collaborator is building a detailed Workspace draft, Alternative Greetings and Lorebook…"
		_:
			return super._working_text_v0153()


func _refresh_action_state() -> void:
	super._refresh_action_state()
	var busy := _generation_service != null and _generation_service.has_active_job()
	if _handoff_mode_v01515 != null:
		_handoff_mode_v01515.disabled = busy


func _generate_character() -> void:
	if _generation_service == null or _generation_service.has_active_job():
		return
	if not _can_send_with_context_budget():
		return
	var session := _active_session()
	if session.is_empty():
		return
	var profile := CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_TEXT)
	var retry_count := int((_settings.get("generation", {}) as Dictionary).get("retry_count", 1))
	var selected_mode := HANDOFF_BLUEPRINT_V01515
	if _handoff_mode_v01515 != null:
		selected_mode = _handoff_mode_v01515.get_selected_id()

	var result: Dictionary
	if selected_mode == HANDOFF_DETAILED_DRAFT_V01515:
		var alternate_count := _alternate_greeting_count_v01515()
		result = _generation_service.call(
			"queue_collaborator_detailed_draft",
			_active_messages_for_model(),
			_context_blocks(),
			str(session.get("memory_summary", "")),
			_template,
			profile,
			retry_count,
			str(session.get("session_id", "")),
			alternate_count
		)
		if bool(result.get("ok", false)):
			_status.text = "Building a detailed Workspace draft from the collaboration, including Alternative Greetings and Character Lorebook material."
	else:
		result = _generation_service.call(
			"queue_collaborator_blueprint",
			_active_messages_for_model(),
			_context_blocks(),
			str(session.get("memory_summary", "")),
			profile,
			retry_count,
			str(session.get("session_id", ""))
		)
		if bool(result.get("ok", false)):
			_status.text = "Building a high-detail Generation Blueprint. It will be placed in Generation Concept without prematurely rewriting the card fields."

	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not queue Collaborator Workspace handoff."))
	_refresh_action_state()


func _on_generation_completed(job_id: String, job_type: String, data: Variant, metadata: Dictionary) -> void:
	if job_type not in ["collaborator_blueprint", "collaborator_character_detailed"]:
		super._on_generation_completed(job_id, job_type, data, metadata)
		return

	_active_collaborator_job_type_v0153 = ""
	if not data is Dictionary:
		_status.text = "Character Collaborator returned an invalid Workspace handoff payload."
		_refresh_all()
		return
	var payload: Dictionary = (data as Dictionary).duplicate(true)
	if job_type == "collaborator_blueprint":
		payload["handoff_mode"] = "blueprint"
	else:
		payload["handoff_mode"] = "detailed_workspace_draft"
	var session := _active_session()
	character_draft_ready.emit(payload, str(session.get("title", "Character Collaboration")))
	if job_type == "collaborator_blueprint":
		_status.text = "Generation Blueprint sent to Workspace. Review the Generation Concept, then use Generate Character when ready."
	else:
		_status.text = "Detailed character draft, Alternative Greetings and Lorebook sent to Workspace."
	_refresh_all()
	call_deferred("_scroll_chat_to_bottom")


func _alternate_greeting_count_v01515() -> int:
	if _project.is_empty() or _active_character_id.is_empty():
		return 3
	var character := CCFStorageService.get_character(_project, _active_character_id)
	if character.is_empty():
		return 3
	var settings_value: Variant = CCFStorageService.get_value_at_path(
		character,
		"generation.alternate_greetings_settings",
		{}
	)
	if settings_value is Dictionary:
		return clampi(int((settings_value as Dictionary).get("count", 3)), 1, 8)
	return 3
