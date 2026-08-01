class_name CCFCharacterCollaboratorWindowV0151
extends "res://scripts/ui/character_collaborator_window_v015.gd"

const CONTEXT_WARNING_PERCENT_V0151 := 75
const CONTEXT_CRITICAL_PERCENT_V0151 := 90
const MIN_INPUT_HEADROOM_V0151 := 1024


func _refresh_context_usage() -> void:
	var budget := _context_budget_v0151()
	var used := int(budget.get("used", 0))
	var context_window := int(budget.get("context_window", 0))
	var configured_output := int(budget.get("configured_output", 0))
	if context_window <= 0:
		_context_usage.text = "Estimated input ~%s tokens • context limit unknown • max output %s" % [
			_format_tokens_v0151(used),
			_format_tokens_v0151(configured_output)
		]
		_context_usage.modulate = Color(0.78, 0.80, 0.88)
		if _status.text.begins_with("Context exceeds") or _status.text.begins_with("This conversation is too large"):
			_status.text = "Context-window limit is unknown for this model. Sending is allowed; set Context Window in Settings for headroom warnings and overflow protection."
		return

	var reserve := int(budget.get("reserve", 0))
	var available_input := int(budget.get("available_input", 0))
	var remaining := int(budget.get("remaining", 0))
	var percentage := int(budget.get("percentage", 0))
	_context_usage.text = "Input ~%s / %s (%d%%) • response reserve %s • headroom %s • context %s" % [
		_format_tokens_v0151(used),
		_format_tokens_v0151(available_input),
		percentage,
		_format_tokens_v0151(reserve),
		_format_tokens_v0151(maxi(0, remaining)),
		_format_tokens_v0151(context_window)
	]
	if used > available_input:
		_context_usage.modulate = Color(1.0, 0.52, 0.52)
		_status.text = "Context exceeds the selected model budget. Choose a larger context window, reduce the response limit, remove context, or summarise older messages before sending."
	elif percentage >= CONTEXT_CRITICAL_PERCENT_V0151:
		_context_usage.modulate = Color(1.0, 0.67, 0.38)
		_status.text = "Character Collaborator is close to the model context limit. Consider summarising older messages before the conversation grows further."
	elif percentage >= CONTEXT_WARNING_PERCENT_V0151:
		_context_usage.modulate = Color(1.0, 0.82, 0.45)
	elif not _context_usage.modulate.is_equal_approx(Color(0.78, 0.80, 0.88)):
		_context_usage.modulate = Color(0.78, 0.80, 0.88)


func _can_send_with_context_budget() -> bool:
	var budget := _context_budget_v0151()
	var context_window := int(budget.get("context_window", 0))
	if context_window <= 0:
		return true
	if int(budget.get("used", 0)) <= int(budget.get("available_input", 0)):
		return true
	_status.text = "This conversation is too large for the selected model's current context budget. Summarise older messages, remove context, reduce Max Output Tokens, or choose a larger Context Window."
	return false


func _context_budget_v0151() -> Dictionary:
	var profile := CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_TEXT)
	var context_window := maxi(0, int(profile.get("context_window_tokens", 0)))
	var configured_output := maxi(128, int(profile.get("max_output_tokens", 6000)))
	var used := _estimated_input_tokens()
	if context_window <= 0:
		return {
			"used": used,
			"context_window": 0,
			"configured_output": configured_output,
			"reserve": configured_output,
			"available_input": -1,
			"remaining": -1,
			"percentage": 0
		}
	var maximum_reserve := maxi(128, context_window - MIN_INPUT_HEADROOM_V0151)
	var reserve := mini(configured_output, maximum_reserve)
	var available_input := maxi(MIN_INPUT_HEADROOM_V0151, context_window - reserve)
	var remaining := available_input - used
	var percentage := int(round(float(used) * 100.0 / float(maxi(1, available_input))))
	return {
		"used": used,
		"context_window": context_window,
		"configured_output": configured_output,
		"reserve": reserve,
		"available_input": available_input,
		"remaining": remaining,
		"percentage": percentage,
		"reserve_was_clamped": configured_output > reserve
	}


func _format_tokens_v0151(value: int) -> String:
	var text := str(maxi(0, value))
	var result := ""
	while text.length() > 3:
		result = ",%s%s" % [text.substr(text.length() - 3), result]
		text = text.substr(0, text.length() - 3)
	return text + result
