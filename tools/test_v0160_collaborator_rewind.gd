extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0160_COLLABORATOR_REWIND_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _messages_for_rewind() -> Array:
	return [
		{
			"role": "user",
			"content": "Keep this author message."
		},
		{
			"role": "assistant",
			"content": "Keep this Collaborator reply.",
			"variants": ["Keep this Collaborator reply."],
			"variant_index": 0
		},
		{
			"role": "user",
			"content": "ACCIDENTAL PASTE THAT MUST BE DELETED"
		},
		{
			"role": "assistant",
			"content": "Reply based on accidental context.",
			"variants": [
				"Reply based on accidental context.",
				"Alternate reply that must also disappear."
			],
			"variant_index": 1
		},
		{
			"role": "user",
			"content": "Later author message that depends on the bad branch."
		},
		{
			"role": "assistant",
			"content": "Later reply that must disappear too."
		}
	]


func _run() -> void:
	CCFStorageService.ensure_directories()
	var scene := load("res://scenes/main.tscn") as PackedScene
	if not _require(scene != null, "The v0.16.0 main scene must load."):
		return
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame

	if not _require(
		app.has_method("_update_build_version_label_v0160"),
		"The active application shell must identify v0.16.0."
	):
		return
	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		workspace_value is CCFWorkspaceV0160View,
		"The real app must install the v0.16.0 Workspace."
	):
		return
	var workspace := workspace_value as CCFWorkspaceV0160View
	var collaborator_value: Variant = workspace.get("_character_collaborator_window")
	if not _require(
		collaborator_value is CCFCharacterCollaboratorWindowV0160,
		"The real Workspace must install the v0.16.0 Collaborator."
	):
		return
	var collaborator := collaborator_value as CCFCharacterCollaboratorWindowV0160

	var capabilities := collaborator.collaborator_rewind_capabilities_v0160()
	if not _require(
		bool(capabilities.get("truncates_selected_and_future_messages", false)),
		"v0.16.0 must advertise truncating the selected message and future transcript."
	):
		return
	if not _require(
		bool(capabilities.get("invalidates_derived_summary_when_required", false)),
		"v0.16.0 must advertise summary invalidation when deleted context was summarized."
	):
		return

	var project := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(project)
	collaborator.open_for_project(project, {}, character_id, {})
	await process_frame
	await process_frame

	# Add a real structured source through the public multi-source path. Rewinding
	# the conversation must not remove independently managed Reference Context.
	var source_result := collaborator.add_pasted_source_v01537(
		JSON.stringify({
			"name": "Persistent Reference Character",
			"description": "This structured source is independent of transcript history."
		}),
		"Persistent Reference Character"
	)
	if not _require(
		bool(source_result.get("ok", false)),
		"A structured Reference Context source must be addable before the rewind test."
	):
		return

	var session_value: Variant = collaborator.call("_active_session")
	var session: Dictionary = (
		session_value.duplicate(true) if session_value is Dictionary else {}
	)
	session["messages"] = _messages_for_rewind()
	session["context_items"] = [
		{
			"type": "text_attachment",
			"label": "persistent-notes.txt",
			"content": "Independent attachment context must survive transcript rewind."
		}
	]
	# This summary covers only messages 0..1, before the accidental paste at 2.
	session["memory_summary"] = "Valid summary of the retained first exchange."
	session["summarized_through"] = 1
	collaborator.call("_store_active_session", session)
	collaborator.call("_refresh_all")
	await process_frame
	await process_frame

	var rewind_buttons := collaborator.find_children(
		"DeleteFromHereButtonV0160",
		"Button",
		true,
		false
	)
	if not _require(
		rewind_buttons.size() == 3,
		"Every rendered author message must expose Delete From Here while assistant/Vision messages do not."
	):
		return

	var before_rewind_value: Variant = collaborator.call("_active_session")
	var before_rewind: Dictionary = (
		before_rewind_value.duplicate(true)
		if before_rewind_value is Dictionary
		else {}
	)
	var source_contexts_before: Variant = before_rewind.get("source_contexts", [])
	var context_items_before: Array = (
		(before_rewind.get("context_items", []) as Array).duplicate(true)
		if before_rewind.get("context_items", []) is Array
		else []
	)

	collaborator.set("_pending_regenerate_index", 5)
	var rewind_result := collaborator.rewind_conversation_from_message_v0160(2)
	if not _require(bool(rewind_result.get("ok", false)), "Deleting the accidental author message must succeed."):
		return
	if not _require(int(rewind_result.get("removed_count", 0)) == 4, "Rewind must delete the selected user message plus all four messages from that point onward."):
		return
	if not _require(not bool(rewind_result.get("summary_invalidated", true)), "A summary that ends before the rewind point must remain valid."):
		return

	var after_value: Variant = collaborator.call("_active_session")
	var after_session: Dictionary = after_value if after_value is Dictionary else {}
	var after_messages: Array = after_session.get("messages", [])
	if not _require(after_messages.size() == 2, "Only the two messages before the accidental paste may remain."):
		return
	if not _require(str((after_messages[0] as Dictionary).get("content", "")) == "Keep this author message.", "The retained author message must stay unchanged."):
		return
	if not _require(str((after_messages[1] as Dictionary).get("content", "")) == "Keep this Collaborator reply.", "The retained assistant message must stay unchanged."):
		return
	if not _require(str(after_session.get("memory_summary", "")) == "Valid summary of the retained first exchange.", "A summary covering only retained history must survive."):
		return
	if not _require(int(after_session.get("summarized_through", -1)) == 1, "The retained summary boundary must remain unchanged."):
		return
	if not _require(int(collaborator.get("_pending_regenerate_index")) == -1, "Rewinding must clear pending response regeneration state."):
		return
	if not _require(after_session.get("source_contexts", []) == source_contexts_before, "Structured Reference Context must not be removed by transcript rewind."):
		return
	if not _require(after_session.get("context_items", []) == context_items_before, "Ordinary attachment/Vision Reference Context must not be removed by transcript rewind."):
		return

	# Now prove that a summary which already incorporated the deleted branch is
	# invalidated. Otherwise the deleted accidental paste could still reach the
	# model through memory_summary despite disappearing from the visible chat.
	after_session["messages"] = _messages_for_rewind()
	after_session["memory_summary"] = "Summary containing the accidental paste and later branch."
	after_session["summarized_through"] = 4
	collaborator.call("_store_active_session", after_session)
	var invalidating_result := collaborator.rewind_conversation_from_message_v0160(2)
	if not _require(bool(invalidating_result.get("ok", false)), "Rewind of summarized history must succeed."):
		return
	if not _require(bool(invalidating_result.get("summary_invalidated", false)), "A memory summary that includes the rewind point must be invalidated."):
		return
	var invalidated_value: Variant = collaborator.call("_active_session")
	var invalidated: Dictionary = invalidated_value if invalidated_value is Dictionary else {}
	if not _require(str(invalidated.get("memory_summary", "")).is_empty(), "Invalidated memory_summary must be cleared so deleted context cannot leak into future requests."):
		return
	if not _require(int(invalidated.get("summarized_through", 999)) == -1, "Invalidated summarized_through must reset to -1 so retained messages become authoritative again."):
		return

	# The public truncation API intentionally rejects assistant-message deletion;
	# the UI exposes the destructive action on author messages only.
	invalidated["messages"] = _messages_for_rewind()
	collaborator.call("_store_active_session", invalidated)
	var rejected := collaborator.rewind_conversation_from_message_v0160(1)
	if not _require(not bool(rejected.get("ok", true)), "Assistant-message rewind must be rejected by the v0.16.0 contract."):
		return
	var rejected_session_value: Variant = collaborator.call("_active_session")
	var rejected_session: Dictionary = rejected_session_value if rejected_session_value is Dictionary else {}
	if not _require((rejected_session.get("messages", []) as Array).size() == 6, "Rejected assistant deletion must leave the transcript unchanged."):
		return

	app.queue_free()
	await process_frame
	print("v0.16.0 Character Collaborator rewind regression passed")
	quit(0)
