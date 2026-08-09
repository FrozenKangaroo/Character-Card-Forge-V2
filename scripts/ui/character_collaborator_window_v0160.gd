class_name CCFCharacterCollaboratorWindowV0160
extends "res://scripts/ui/character_collaborator_window_v01540_hotfix6.gd"

var _rewind_confirm_v0160: ConfirmationDialog
var _pending_rewind_message_index_v0160 := -1
var _render_message_index_v0160 := -1


func _ready() -> void:
	super._ready()
	_build_rewind_dialog_v0160()


func _build_rewind_dialog_v0160() -> void:
	_rewind_confirm_v0160 = ConfirmationDialog.new()
	_rewind_confirm_v0160.visible = false
	_rewind_confirm_v0160.title = "Delete From Here"
	_rewind_confirm_v0160.ok_button_text = "Delete From Here"
	_rewind_confirm_v0160.confirmed.connect(_confirm_rewind_from_message_v0160)
	add_child(_rewind_confirm_v0160)
	_rewind_confirm_v0160.hide()


func _refresh_chat() -> void:
	# The historical renderer only receives the message Dictionary. Track the
	# render position around the inherited real refresh path so the per-message
	# action targets the exact transcript index without adding provider-facing
	# IDs or changing the stored message schema.
	_render_message_index_v0160 = 0
	super._refresh_chat()
	_render_message_index_v0160 = -1


func _build_message_card_v0153(message: Dictionary) -> Control:
	var message_index := _render_message_index_v0160
	if _render_message_index_v0160 >= 0:
		_render_message_index_v0160 += 1
	var panel := super._build_message_card_v0153(message)
	if message_index < 0 or str(message.get("role", "")) != "user":
		return panel

	var headers := panel.find_children("*", "HBoxContainer", true, false)
	if headers.is_empty():
		return panel
	var header := headers[0] as HBoxContainer
	if header == null:
		return panel
	var delete_button := Button.new()
	delete_button.name = "DeleteFromHereButtonV0160"
	delete_button.text = "Delete From Here…"
	delete_button.tooltip_text = "Delete this message and every later conversation message, rewinding the Collaborator to the point before this was sent."
	delete_button.disabled = _collaborator_busy_v0160()
	delete_button.pressed.connect(
		func(): _request_rewind_from_message_v0160(message_index)
	)
	header.add_child(delete_button)
	return panel


func _request_rewind_from_message_v0160(message_index: int) -> void:
	if _collaborator_busy_v0160():
		_status.text = "Wait for the current Collaborator job to finish before rewinding the conversation."
		return
	var session := _active_session()
	var messages_value: Variant = session.get("messages", [])
	if not messages_value is Array:
		return
	var messages: Array = messages_value
	if message_index < 0 or message_index >= messages.size():
		return
	var message_value: Variant = messages[message_index]
	if not message_value is Dictionary:
		return
	var message: Dictionary = message_value
	if str(message.get("role", "")) != "user":
		return

	_pending_rewind_message_index_v0160 = message_index
	var affected_count := messages.size() - message_index
	var preview := _truncate(str(message.get("content", "")), 180).replace("\n", " ")
	_rewind_confirm_v0160.dialog_text = (
		"Delete this message and all %d message%s from this point onward?\n\n"
		+ "This rewinds the conversation to immediately before the selected message so later replies cannot retain context that no longer exists. Reference Context sources/attachments are separate and will not be removed.\n\n"
		+ "Selected message: %s"
	) % [
		affected_count,
		"" if affected_count == 1 else "s",
		preview
	]
	_rewind_confirm_v0160.popup_centered(Vector2i(720, 320))


func _confirm_rewind_from_message_v0160() -> void:
	var message_index := _pending_rewind_message_index_v0160
	_pending_rewind_message_index_v0160 = -1
	var result := rewind_conversation_from_message_v0160(message_index)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not rewind the Collaborator conversation."))
		return
	var removed_count := int(result.get("removed_count", 0))
	var summary_invalidated := bool(result.get("summary_invalidated", false))
	_status.text = "Conversation rewound. Deleted %d message%s%s" % [
		removed_count,
		"" if removed_count == 1 else "s",
		" and cleared the older AI memory summary because it included deleted context." if summary_invalidated else "."
	]


func rewind_conversation_from_message_v0160(message_index: int) -> Dictionary:
	if _collaborator_busy_v0160():
		return {
			"ok": false,
			"error": "Wait for the current Collaborator job to finish before rewinding the conversation."
		}
	var session := _active_session()
	if session.is_empty():
		return {"ok": false, "error": "No Collaborator conversation is active."}
	var messages_value: Variant = session.get("messages", [])
	if not messages_value is Array:
		return {"ok": false, "error": "The active conversation has invalid message data."}
	var messages: Array = messages_value.duplicate(true)
	if message_index < 0 or message_index >= messages.size():
		return {"ok": false, "error": "The selected Collaborator message no longer exists."}
	var selected_value: Variant = messages[message_index]
	if not selected_value is Dictionary:
		return {"ok": false, "error": "The selected Collaborator message is invalid."}
	var selected: Dictionary = selected_value
	if str(selected.get("role", "")) != "user":
		return {
			"ok": false,
			"error": "Delete From Here is intentionally available only on author messages."
		}

	var removed_count := messages.size() - message_index
	var retained: Array = []
	for index in range(message_index):
		var retained_value: Variant = messages[index]
		retained.append(
			retained_value.duplicate(true)
			if retained_value is Dictionary
			else retained_value
		)
	session["messages"] = retained

	# memory_summary is derived from the original transcript. It remains valid only
	# when its summarized range ends strictly before the rewind point. If the
	# selected/deleted message was already included, keeping the summary would leak
	# deleted facts back into every future model request even though the visible
	# message was gone.
	var summarized_through := int(session.get("summarized_through", -1))
	var summary_invalidated := summarized_through >= message_index
	if summary_invalidated:
		session["memory_summary"] = ""
		session["summarized_through"] = -1

	_pending_regenerate_index = -1
	_active_collaborator_job_type_v0153 = ""
	_store_active_session(session)
	_refresh_all()
	return {
		"ok": true,
		"removed_count": removed_count,
		"remaining_count": retained.size(),
		"summary_invalidated": summary_invalidated,
		"reference_context_preserved": true
	}


func _collaborator_busy_v0160() -> bool:
	return _generation_service != null and _generation_service.has_active_job()


func collaborator_rewind_capabilities_v0160() -> Dictionary:
	return {
		"version": "0.16.0",
		"user_message_delete_from_here": true,
		"truncates_selected_and_future_messages": true,
		"preserves_independent_reference_context": true,
		"invalidates_derived_summary_when_required": true,
		"clears_pending_regeneration": true,
		"autosaves_through_existing_session_store": true,
		"blocked_while_collaborator_job_active": true
	}
