class_name CCFCharacterCollaboratorWindowV0151
extends "res://scripts/ui/character_collaborator_window_v015.gd"

const CONTEXT_WARNING_PERCENT_V0151 := 75
const CONTEXT_CRITICAL_PERCENT_V0151 := 90


func _refresh_context_usage() -> void:
	var budget := _context_budget_v0151()
	var used := int(budget.get("used", 0))
	var context_window := int(budget.get("context_window", 0))
	if context_window <= 0:
		_context_usage.text = "Estimated input ~%s tokens • context limit unknown • Collaborator reply request %s" % [
			_format_tokens_v0151(used),
			_format_tokens_v0151(int(budget.get("reserve", 0)))
		]
		_context_usage.modulate = Color(0.78, 0.80, 0.88)
		if _status.text.begins_with("Input exceeds") or _status.text.begins_with("This conversation is too large"):
			_status.text = "Context-window limit is unknown for this model. Sending is allowed; set Context Window in Settings for headroom warnings and overflow protection."
		return

	var reserve := int(budget.get("reserve", 0))
	var available_input := int(budget.get("available_input", 0))
	var remaining := int(budget.get("remaining", 0))
	var percentage := int(budget.get("percentage", 0))
	_context_usage.text = "Input ~%s / %s (%d%%) • reply request %s • headroom %s • context %s" % [
		_format_tokens_v0151(used),
		_format_tokens_v0151(available_input),
		percentage,
		_format_tokens_v0151(reserve),
		_format_tokens_v0151(maxi(0, remaining)),
		_format_tokens_v0151(context_window)
	]
	if used > available_input:
		_context_usage.modulate = Color(1.0, 0.52, 0.52)
		_status.text = "Input exceeds this Collaborator budget. Reduce the Collaborator reply request in Settings, remove reference context, summarise older messages, or choose a larger model context window."
	elif percentage >= CONTEXT_CRITICAL_PERCENT_V0151:
		_context_usage.modulate = Color(1.0, 0.67, 0.38)
		_status.text = "Character Collaborator is close to the model context limit. Consider summarising older messages before the conversation grows further."
	elif percentage >= CONTEXT_WARNING_PERCENT_V0151:
		_context_usage.modulate = Color(1.0, 0.82, 0.45)
	elif not _context_usage.modulate.is_equal_approx(Color(0.78, 0.80, 0.88)):
		_context_usage.modulate = Color(0.78, 0.80, 0.88)
	if used <= available_input and (
		_status.text.begins_with("Input exceeds")
		or _status.text.begins_with("This conversation is too large")
	):
		_status.text = "Collaborator input is within the selected model's estimated context budget."


func _can_send_with_context_budget() -> bool:
	var budget := _context_budget_v0151()
	var context_window := int(budget.get("context_window", 0))
	if context_window <= 0:
		return true
	if int(budget.get("used", 0)) <= int(budget.get("available_input", 0)):
		return true
	_status.text = "This conversation is too large for the selected model's current context budget. Remove context, summarise older messages, reduce the Collaborator reply request in Settings, or choose a larger Context Window."
	return false


func _context_budget_v0151() -> Dictionary:
	var profile := CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_TEXT)
	return CCFCollaboratorTokenBudgetCurrent.budget(profile, _estimated_input_tokens())


func _format_tokens_v0151(value: int) -> String:
	var text := str(maxi(0, value))
	var result := ""
	while text.length() > 3:
		result = ",%s%s" % [text.substr(text.length() - 3), result]
		text = text.substr(0, text.length() - 3)
	return text + result
