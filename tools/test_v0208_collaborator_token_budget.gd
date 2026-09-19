extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _require(condition: bool, message_text: String) -> bool:
	if condition:
		return true
	push_error(message_text)
	print("V0208_COLLABORATOR_BUDGET_ERROR: %s" % message_text)
	quit(1)
	return false


func _run() -> void:
	var profile := {
		"context_window_tokens": 1384448,
		"max_output_tokens": 1000064,
		"collaborator_reply_output_tokens": 16384
	}
	var large_attachment_budget := CCFCollaboratorTokenBudgetCurrent.budget(profile, 432662)
	if not _require(
		int(large_attachment_budget.get("reserve", -1)) == 16384
		and int(large_attachment_budget.get("available_input", -1)) == 1368064
		and int(large_attachment_budget.get("remaining", -1)) == 935402,
		"A large model output capability must not consume the Collaborator input allowance."
	):
		return
	var request := CCFCollaboratorTokenBudgetCurrent.request_profile(profile)
	if not _require(
		int(request.get("max_output_tokens", -1)) == 16384
		and int(profile.get("max_output_tokens", -1)) == 1000064,
		"The provider request must use the separate Collaborator limit without changing the saved model capability."
	):
		return
	profile["collaborator_reply_output_tokens"] = 1000064
	var oversized := CCFCollaboratorTokenBudgetCurrent.budget(profile, 432662)
	if not _require(
		int(oversized.get("available_input", -1)) == 384384
		and int(oversized.get("remaining", 0)) < 0,
		"An explicitly huge reply request must still be reported as over budget."
	):
		return
	profile["collaborator_reply_output_tokens"] = 2000000
	if not _require(
		CCFCollaboratorTokenBudgetCurrent.requested_output_tokens(profile) == 1000064,
		"The actual request must never exceed the model output ceiling."
	):
		return
	profile["context_window_tokens"] = 0
	if not _require(
		int(CCFCollaboratorTokenBudgetCurrent.budget(profile, 432662).get("available_input", 0)) == -1,
		"Unknown context windows must keep the established non-blocking policy."
	):
		return

	var view := CCFSettingsV0208View.new()
	root.add_child(view)
	await process_frame
	var settings := CCFSettingsService.default_settings()
	var active: Dictionary = CCFSettingsService.active_profile(settings).duplicate(true)
	active["context_window_tokens"] = 1384448
	active["max_output_tokens"] = 1000064
	active["collaborator_reply_output_tokens"] = 16384
	CCFSettingsService.replace_profile_by_id(settings, str(active.get("id", "default")), active)
	view.load_settings(settings)
	var output_control := view.find_child("CollaboratorReplyOutputV0208", true, false) as SpinBox
	var allowance_label := view.find_child("CollaboratorInputAllowanceV0208", true, false) as Label
	if not _require(
		output_control != null and int(output_control.value) == 16384
		and allowance_label != null and allowance_label.text.contains("1,368,064"),
		"Settings must show the editable reply request and the derived input allowance."
	):
		return
	output_control.value = 32768
	view.call("_capture_loaded_profile")
	var stored: Dictionary = CCFSettingsService.active_profile(view.get("_settings") as Dictionary)
	if not _require(
		int(stored.get("collaborator_reply_output_tokens", 0)) == 32768
		and int(stored.get("max_output_tokens", 0)) == 1000064,
		"Saving the reply request must leave the model output ceiling intact."
	):
		return
	view.queue_free()
	await process_frame
	print("V0208_COLLABORATOR_BUDGET_OK")
	quit(0)
