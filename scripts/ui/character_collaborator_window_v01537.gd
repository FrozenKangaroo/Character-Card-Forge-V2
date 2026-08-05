class_name CCFCharacterCollaboratorWindowV01537
extends "res://scripts/ui/character_collaborator_window_v01535.gd"

const SOURCE_SERVICE_V01537 = preload(
	"res://scripts/services/collaborator_source_context_service_v01537.gd"
)

var _suppress_legacy_source_v01537 := false
var _multi_source_list_v01537: VBoxContainer
var _paste_source_dialog_v01537: ConfirmationDialog
var _paste_source_label_v01537: LineEdit
var _paste_source_text_v01537: TextEdit


func _ready() -> void:
	super._ready()
	_install_multi_source_controls_v01537()
	_build_paste_source_dialog_v01537()
	_refresh_source_panel_v01533()


func start_source_session_v01533(source: Dictionary) -> Dictionary:
	var requested_role := SOURCE_SERVICE_V01537.ROLE_REFERENCE
	if str(source.get("source_type", "")) == SOURCE_SERVICE_V01537.TYPE_CHARACTER:
		requested_role = SOURCE_SERVICE_V01537.ROLE_TARGET
	var clean := SOURCE_SERVICE_V01537.upgrade_source(source, requested_role)
	if clean.is_empty():
		return {"ok": false, "error": "The Collaborator source context is invalid."}
	if not _active_session_is_pristine_v01533():
		_create_new_session(false)
	var session := _active_session().duplicate(true)
	if session.is_empty():
		return {"ok": false, "error": "Could not create a Collaborator conversation for this source."}
	_store_sources_in_session_v01537(session, [clean])
	session["title"] = "%s • %s" % [
		SOURCE_SERVICE_V01537.display_type(clean),
		str(clean.get("label", "Source material"))
	]
	_store_active_session(session)
	_pending_regenerate_index = -1
	_refresh_all()
	_status.text = "Source-aware conversation started. Add more characters, cards, Ideas, or pasted source whenever useful."
	popup_centered()
	call_deferred("_scroll_chat_to_bottom")
	return {
		"ok": true,
		"session_id": str(session.get("session_id", "")),
		"source_context_id": str(clean.get("source_context_id", "")),
		"source_count": 1
	}


func active_source_context_v01533() -> Dictionary:
	if _suppress_legacy_source_v01537:
		return {}
	return SOURCE_SERVICE_V01537.legacy_primary_source(active_source_contexts_v01537())


func active_source_contexts_v01537() -> Array[Dictionary]:
	var session := _active_session()
	var legacy_value: Variant = session.get("source_context", {})
	var legacy: Dictionary = legacy_value if legacy_value is Dictionary else {}
	return SOURCE_SERVICE_V01537.normalise_collection(
		session.get("source_contexts", []), legacy
	)


func add_source_v01537(source: Dictionary, make_target: bool = false) -> Dictionary:
	var role := SOURCE_SERVICE_V01537.ROLE_REFERENCE
	if make_target:
		role = SOURCE_SERVICE_V01537.ROLE_TARGET
	var clean := SOURCE_SERVICE_V01537.upgrade_source(source, role)
	if clean.is_empty():
		return {"ok": false, "error": "The source could not be normalised for Collaborator."}
	var session := _active_session().duplicate(true)
	if session.is_empty():
		return {"ok": false, "error": "Open Character Collaborator before adding another source."}
	var sources := active_source_contexts_v01537()
	if make_target and SOURCE_SERVICE_V01537.can_be_target(clean):
		for index in range(sources.size()):
			var existing: Dictionary = sources[index].duplicate(true)
			existing["source_role"] = SOURCE_SERVICE_V01537.ROLE_REFERENCE
			sources[index] = existing
		clean["source_role"] = SOURCE_SERVICE_V01537.ROLE_TARGET
	sources.append(clean)
	sources = SOURCE_SERVICE_V01537.normalise_collection(sources)
	_store_sources_in_session_v01537(session, sources)
	_store_active_session(session)
	_refresh_all()
	popup_centered()
	_status.text = "%s added as a Collaborator %s source." % [
		str(clean.get("label", "Source material")),
		str(clean.get("source_role", SOURCE_SERVICE_V01537.ROLE_REFERENCE))
	]
	return {"ok": true, "source_count": sources.size()}


func add_pasted_source_v01537(text: String, label: String = "Pasted source") -> Dictionary:
	var source := SOURCE_SERVICE_V01537.from_pasted_text(text, label)
	if source.is_empty():
		return {"ok": false, "error": "Paste some source material first."}
	return add_source_v01537(source, false)


func remove_source_v01537(source_context_id: String) -> Dictionary:
	var sources := active_source_contexts_v01537()
	var kept: Array[Dictionary] = []
	var removed := false
	for source in sources:
		if str(source.get("source_context_id", "")) == source_context_id:
			removed = true
			continue
		kept.append(source.duplicate(true))
	if not removed:
		return {"ok": false, "error": "The Collaborator source was not found."}
	var session := _active_session().duplicate(true)
	_store_sources_in_session_v01537(session, kept)
	_store_active_session(session)
	_refresh_all()
	_status.text = "Source removed from future Collaborator context; the transcript is unchanged."
	return {"ok": true, "source_count": kept.size()}


func set_target_source_v01537(source_context_id: String) -> Dictionary:
	var sources := active_source_contexts_v01537()
	var requested: Dictionary = {}
	for source in sources:
		if str(source.get("source_context_id", "")) == source_context_id:
			requested = source
			break
	if requested.is_empty() or not SOURCE_SERVICE_V01537.can_be_target(requested):
		return {"ok": false, "error": "Only an existing Workspace character can be the Compare & Apply target."}
	var updated := SOURCE_SERVICE_V01537.set_target(sources, source_context_id)
	var session := _active_session().duplicate(true)
	_store_sources_in_session_v01537(session, updated)
	_store_active_session(session)
	_refresh_all()
	_status.text = "%s is now the explicit refinement target; all other sources remain references." % str(requested.get("label", "Character"))
	return {"ok": true}


func collaborator_source_capabilities_v01533() -> Dictionary:
	var result := super.collaborator_source_capabilities_v01533()
	result.merge(SOURCE_SERVICE_V01537.capabilities(), true)
	result["single_source"] = false
	result["multi_source"] = true
	result["add_source_during_session"] = true
	result["paste_source"] = true
	result["attached_card_auto_detection"] = true
	return result


func _normalise_sessions() -> void:
	super._normalise_sessions()
	for index in range(_sessions.size()):
		if not _sessions[index] is Dictionary:
			continue
		var session: Dictionary = (_sessions[index] as Dictionary).duplicate(true)
		var legacy_value: Variant = session.get("source_context", {})
		var legacy: Dictionary = legacy_value if legacy_value is Dictionary else {}
		var sources := SOURCE_SERVICE_V01537.normalise_collection(
			session.get("source_contexts", []), legacy
		)
		_store_sources_in_session_v01537(session, sources)
		_sessions[index] = session


func _context_blocks() -> Array[String]:
	_suppress_legacy_source_v01537 = true
	var result: Array[String] = super._context_blocks()
	_suppress_legacy_source_v01537 = false
	var block := SOURCE_SERVICE_V01537.model_context_block(active_source_contexts_v01537())
	if not block.is_empty():
		result.push_front(block)
	return result


func _refresh_context_usage() -> void:
	_suppress_legacy_source_v01537 = true
	super._refresh_context_usage()
	_suppress_legacy_source_v01537 = false
	var source_tokens := CCFGenerationService.estimate_tokens(
		SOURCE_SERVICE_V01537.model_context_block(active_source_contexts_v01537())
	)
	if source_tokens > 0:
		_context_usage.text += " • sources ~%s" % _format_tokens_v0151(source_tokens)


func _refresh_source_panel_v01533() -> void:
	if _source_panel_v01533 == null:
		return
	var sources := active_source_contexts_v01537()
	_source_panel_v01533.visible = not sources.is_empty()
	if sources.is_empty():
		return
	var target_label := "None"
	for source in sources:
		if str(source.get("source_role", "")) == SOURCE_SERVICE_V01537.ROLE_TARGET:
			target_label = str(source.get("label", "Character"))
			break
	_source_header_v01533.text = "Sources • %d • Target: %s" % [sources.size(), target_label]
	var excluded_total := 0
	for source in sources:
		excluded_total += int(source.get("excluded_user_persona_count", 0))
	if excluded_total > 0:
		_source_summary_v01533.text = "%d embedded UserPersona section%s excluded from AI context. Raw source snapshots are preserved." % [excluded_total, "" if excluded_total == 1 else "s"]
	else:
		_source_summary_v01533.text = "Sources stay individually identified and read-only."
	_source_note_v01533.text = "Only one existing Workspace character can be the Compare & Apply target. References can inform continuity without becoming overwrite targets."
	_refresh_multi_source_list_v01537()


func _install_multi_source_controls_v01537() -> void:
	if _source_panel_v01533 == null:
		return
	var actions := HFlowContainer.new()
	actions.name = "CollaboratorMultiSourceActionsV01537"
	_source_panel_v01533.add_child(actions)
	var paste_button := Button.new()
	paste_button.text = "Paste Source…"
	paste_button.tooltip_text = "Paste card text or JSON as a read-only source. Separate UserPersona sections are excluded from AI context."
	paste_button.pressed.connect(_open_paste_source_dialog_v01537)
	actions.add_child(paste_button)
	var attach_hint := Label.new()
	attach_hint.text = "Character Card JSON/PNG added through Attach Files… is detected as structured source automatically."
	attach_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actions.add_child(attach_hint)
	_multi_source_list_v01537 = VBoxContainer.new()
	_multi_source_list_v01537.name = "CollaboratorMultiSourceListV01537"
	_source_panel_v01533.add_child(_multi_source_list_v01537)


func _refresh_multi_source_list_v01537() -> void:
	if _multi_source_list_v01537 == null:
		return
	for child in _multi_source_list_v01537.get_children():
		child.queue_free()
	for source in active_source_contexts_v01537():
		var row := HBoxContainer.new()
		_multi_source_list_v01537.add_child(row)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = "%s • %s • %s" % [
			str(source.get("source_role", SOURCE_SERVICE_V01537.ROLE_REFERENCE)).to_upper(),
			SOURCE_SERVICE_V01537.display_type(source),
			str(source.get("label", "Source material"))
		]
		if int(source.get("excluded_user_persona_count", 0)) > 0:
			label.text += " • UserPersona excluded"
		row.add_child(label)
		var source_id := str(source.get("source_context_id", ""))
		if SOURCE_SERVICE_V01537.can_be_target(source) and str(source.get("source_role", "")) != SOURCE_SERVICE_V01537.ROLE_TARGET:
			var target_button := Button.new()
			target_button.text = "Make Target"
			target_button.pressed.connect(_on_make_target_v01537.bind(source_id))
			row.add_child(target_button)
		var remove_button := Button.new()
		remove_button.text = "×"
		remove_button.pressed.connect(_on_remove_source_v01537.bind(source_id))
		row.add_child(remove_button)


func _build_paste_source_dialog_v01537() -> void:
	_paste_source_dialog_v01537 = ConfirmationDialog.new()
	_paste_source_dialog_v01537.visible = false
	_paste_source_dialog_v01537.title = "Add Pasted Collaborator Source"
	_paste_source_dialog_v01537.min_size = Vector2i(820, 620)
	_paste_source_dialog_v01537.confirmed.connect(_confirm_pasted_source_v01537)
	add_child(_paste_source_dialog_v01537)
	var root := VBoxContainer.new()
	_paste_source_dialog_v01537.add_child(root)
	var hint := Label.new()
	hint.text = "Raw pasted source is preserved. Separate <UserPersona>/User Persona sections are excluded from the AI-facing copy, while character-established facts involving {{user}} remain."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(hint)
	_paste_source_label_v01537 = LineEdit.new()
	_paste_source_label_v01537.placeholder_text = "Source label (optional)"
	root.add_child(_paste_source_label_v01537)
	_paste_source_text_v01537 = TextEdit.new()
	_paste_source_text_v01537.custom_minimum_size = Vector2(760, 430)
	_paste_source_text_v01537.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	root.add_child(_paste_source_text_v01537)
	_paste_source_dialog_v01537.hide()


func _open_paste_source_dialog_v01537() -> void:
	_paste_source_label_v01537.text = ""
	_paste_source_text_v01537.text = ""
	_paste_source_dialog_v01537.popup_centered(Vector2i(860, 650))


func _confirm_pasted_source_v01537() -> void:
	var result := add_pasted_source_v01537(
		_paste_source_text_v01537.text,
		_paste_source_label_v01537.text
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not add pasted source."))


func _on_attachment_files_selected_v01521(paths: PackedStringArray) -> void:
	var remaining := PackedStringArray()
	var cards_added := 0
	for path in paths:
		if path.get_extension().to_lower() in ["json", "png", "apng"]:
			var loaded := SOURCE_SERVICE_V01537.from_card_file(path)
			if bool(loaded.get("ok", false)):
				var source_value: Variant = loaded.get("source", {})
				if source_value is Dictionary:
					var added := add_source_v01537(source_value as Dictionary, false)
					if bool(added.get("ok", false)):
						cards_added += 1
						continue
		remaining.append(path)
	if not remaining.is_empty():
		super._on_attachment_files_selected_v01521(remaining)
	if cards_added > 0:
		_status.text = "%d Character Card%s detected and added as structured source%s.%s" % [
			cards_added,
			"" if cards_added == 1 else "s",
			"" if cards_added == 1 else "s",
			" Other selected files kept their normal attachment behavior." if not remaining.is_empty() else ""
		]


func _on_make_target_v01537(source_context_id: String) -> void:
	var result := set_target_source_v01537(source_context_id)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not change Collaborator target."))


func _on_remove_source_v01537(source_context_id: String) -> void:
	var result := remove_source_v01537(source_context_id)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not remove Collaborator source."))


func _store_sources_in_session_v01537(session: Dictionary, sources: Array) -> void:
	var clean := SOURCE_SERVICE_V01537.normalise_collection(sources)
	session["source_contexts"] = clean
	session["source_contexts_format_version"] = SOURCE_SERVICE_V01537.FORMAT_VERSION
	var legacy := SOURCE_SERVICE_V01537.legacy_primary_source(clean)
	if legacy.is_empty() or str(legacy.get("source_type", "")) not in SOURCE_SERVICE_V01537.LEGACY_TYPES:
		session.erase("source_context")
		session.erase("source_context_format_version")
	else:
		session["source_context"] = legacy
		session["source_context_format_version"] = 1
