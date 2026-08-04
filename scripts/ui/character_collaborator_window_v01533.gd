class_name CCFCharacterCollaboratorWindowV01533
extends "res://scripts/ui/character_collaborator_window_v01521.gd"

const SOURCE_SERVICE_V01533 = preload(
	"res://scripts/services/collaborator_source_context_service_v01533.gd"
)

var _source_panel_v01533: VBoxContainer
var _source_header_v01533: Label
var _source_summary_v01533: Label
var _source_note_v01533: Label


func _ready() -> void:
	super._ready()
	_install_source_panel_v01533()
	_refresh_source_panel_v01533()


func open_with_source_v01533(
	project: Dictionary,
	settings: Dictionary,
	character_id: String,
	template: Dictionary,
	source: Dictionary
) -> Dictionary:
	var clean := SOURCE_SERVICE_V01533.normalise(source)
	if clean.is_empty():
		return {"ok": false, "error": "The Collaborator source context is invalid."}
	open_for_project(project, settings, character_id, template)
	return start_source_session_v01533(clean)


func start_source_session_v01533(source: Dictionary) -> Dictionary:
	var clean := SOURCE_SERVICE_V01533.normalise(source)
	if clean.is_empty():
		return {"ok": false, "error": "The Collaborator source context is invalid."}

	if not _active_session_is_pristine_v01533():
		_create_new_session(false)
	var session := _active_session().duplicate(true)
	if session.is_empty():
		return {"ok": false, "error": "Could not create a Collaborator conversation for this source."}

	session["source_context"] = clean.duplicate(true)
	session["source_context_format_version"] = 1
	session["title"] = "%s • %s" % [
		SOURCE_SERVICE_V01533.display_type(clean),
		str(clean.get("label", "Source material"))
	]
	_store_active_session(session)
	_pending_regenerate_index = -1
	_refresh_all()
	_status.text = (
		"Started a new source-aware Collaborator conversation from %s. "
		+ "The source snapshot is read-only; tell the Collaborator what you want to develop, preserve, change or branch."
	) % SOURCE_SERVICE_V01533.display_type(clean)
	popup_centered()
	call_deferred("_scroll_chat_to_bottom")
	return {
		"ok": true,
		"session_id": str(session.get("session_id", "")),
		"source_context_id": str(clean.get("source_context_id", ""))
	}


func active_source_context_v01533() -> Dictionary:
	var session := _active_session()
	var source_value: Variant = session.get("source_context", {})
	if not source_value is Dictionary:
		return {}
	return SOURCE_SERVICE_V01533.normalise(source_value as Dictionary)


func collaborator_source_capabilities_v01533() -> Dictionary:
	return {
		"format_version": 1,
		"single_source": true,
		"generated_idea": true,
		"saved_idea": true,
		"existing_character_schema": true,
		"source_session_persistence": true,
		"source_is_read_only": true,
		"multi_source": false
	}


func _normalise_sessions() -> void:
	super._normalise_sessions()
	for index in range(_sessions.size()):
		if not _sessions[index] is Dictionary:
			continue
		var session: Dictionary = (_sessions[index] as Dictionary).duplicate(true)
		var source_value: Variant = session.get("source_context", {})
		if source_value is Dictionary and not (source_value as Dictionary).is_empty():
			var clean := SOURCE_SERVICE_V01533.normalise(source_value as Dictionary)
			if not clean.is_empty():
				session["source_context"] = clean
				session["source_context_format_version"] = 1
			else:
				session.erase("source_context")
		_sessions[index] = session


func _context_blocks() -> Array[String]:
	var result: Array[String] = super._context_blocks()
	var source := active_source_context_v01533()
	if source.is_empty():
		return result
	var source_block := SOURCE_SERVICE_V01533.model_context_block(source)
	if not source_block.is_empty():
		result.push_front(source_block)
	return result


func _refresh_all() -> void:
	super._refresh_all()
	_refresh_source_panel_v01533()


func _refresh_context_usage() -> void:
	super._refresh_context_usage()
	var source := active_source_context_v01533()
	if source.is_empty():
		return
	var source_tokens := CCFGenerationService.estimate_tokens(
		SOURCE_SERVICE_V01533.model_context_block(source)
	)
	if source_tokens > 0:
		_context_usage.text += " • source ~%s" % _format_tokens_v0151(source_tokens)


func _install_source_panel_v01533() -> void:
	if _context_list == null:
		return
	var context_scroll := _context_list.get_parent()
	if context_scroll == null:
		return
	var context_panel := context_scroll.get_parent()
	if context_panel == null:
		return

	_source_panel_v01533 = VBoxContainer.new()
	_source_panel_v01533.name = "CollaboratorSourceContextV01533"
	_source_panel_v01533.add_theme_constant_override("separation", 3)
	_source_panel_v01533.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_source_panel_v01533.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	context_panel.add_child(_source_panel_v01533)
	context_panel.move_child(_source_panel_v01533, context_scroll.get_index())

	_source_header_v01533 = Label.new()
	_source_header_v01533.add_theme_font_size_override("font_size", 16)
	_source_header_v01533.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_source_panel_v01533.add_child(_source_header_v01533)

	_source_summary_v01533 = Label.new()
	_source_summary_v01533.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_source_summary_v01533.modulate = Color(0.78, 0.82, 0.92)
	_source_panel_v01533.add_child(_source_summary_v01533)

	_source_note_v01533 = Label.new()
	_source_note_v01533.text = "Read-only source • established facts stay authoritative unless you explicitly ask to change or branch them."
	_source_note_v01533.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_source_note_v01533.modulate = Color(0.64, 0.70, 0.80)
	_source_panel_v01533.add_child(_source_note_v01533)


func _refresh_source_panel_v01533() -> void:
	if _source_panel_v01533 == null:
		return
	var source := active_source_context_v01533()
	_source_panel_v01533.visible = not source.is_empty()
	if source.is_empty():
		return
	_source_header_v01533.text = "Source • %s • %s" % [
		SOURCE_SERVICE_V01533.display_type(source),
		str(source.get("label", "Source material"))
	]
	var summary := SOURCE_SERVICE_V01533.display_summary(source)
	_source_summary_v01533.text = summary if not summary.is_empty() else "Structured source snapshot attached to this conversation."


func _active_session_is_pristine_v01533() -> bool:
	var session := _active_session()
	if session.is_empty():
		return false
	var messages_value: Variant = session.get("messages", [])
	var context_value: Variant = session.get("context_items", [])
	var source_value: Variant = session.get("source_context", {})
	var no_messages := not messages_value is Array or (messages_value as Array).is_empty()
	var no_context := not context_value is Array or (context_value as Array).is_empty()
	var no_source := not source_value is Dictionary or (source_value as Dictionary).is_empty()
	return no_messages and no_context and no_source and str(session.get("memory_summary", "")).is_empty()
