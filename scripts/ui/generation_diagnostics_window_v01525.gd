class_name CCFGenerationDiagnosticsWindowV01525
extends "res://scripts/ui/generation_diagnostics_window_v01522.gd"


func show_diagnostics(bundle: Dictionary) -> void:
	super.show_diagnostics(bundle)
	var extra_lines: Array[String] = []

	var budget_value: Variant = bundle.get("token_budget", {})
	if budget_value is Dictionary and not budget_value.is_empty():
		var budget: Dictionary = budget_value
		extra_lines.append("Token budget")
		var configured := int(budget.get("configured_character_max_output_tokens", 0))
		var requested := int(budget.get("request_max_tokens", 0))
		if configured > 0:
			extra_lines.append("Configured Text maximum output: %s tokens" % _format_token_count_v01525(configured))
		if requested > 0:
			extra_lines.append("This request max_tokens: %s" % _format_token_count_v01525(requested))
		if bool(budget.get("hidden_stage_caps_allowed", true)) == false:
			extra_lines.append("Per-stage hidden output caps: disabled")

	var termination_value: Variant = bundle.get("provider_termination", {})
	if termination_value is Dictionary and not termination_value.is_empty():
		var termination: Dictionary = termination_value
		if not extra_lines.is_empty():
			extra_lines.append("")
		extra_lines.append("Provider termination")
		var limit_reached := bool(termination.get("limit_reached", false))
		if limit_reached:
			extra_lines.append("OUTPUT LIMIT REACHED")
		var finish_reason := str(termination.get("finish_reason", "")).strip_edges()
		if not finish_reason.is_empty():
			extra_lines.append("Finish reason: %s" % finish_reason)
		var incomplete_reason := str(termination.get("incomplete_reason", "")).strip_edges()
		if not incomplete_reason.is_empty():
			extra_lines.append("Incomplete reason: %s" % incomplete_reason)
		var prompt_tokens := int(termination.get("prompt_tokens", 0))
		var completion_tokens := int(termination.get("completion_tokens", 0))
		var total_tokens := int(termination.get("total_tokens", 0))
		if prompt_tokens > 0:
			extra_lines.append("Provider input tokens: %s" % _format_token_count_v01525(prompt_tokens))
		if completion_tokens > 0:
			extra_lines.append("Provider output tokens: %s" % _format_token_count_v01525(completion_tokens))
		if total_tokens > 0:
			extra_lines.append("Provider total tokens: %s" % _format_token_count_v01525(total_tokens))
		var summary := str(termination.get("summary", "")).strip_edges()
		if not summary.is_empty():
			extra_lines.append(summary)

	if not extra_lines.is_empty():
		_overview.text += "\n\n" + "\n".join(extra_lines)


func _format_token_count_v01525(value: int) -> String:
	var text := str(absi(value))
	var grouped := ""
	while text.length() > 3:
		grouped = "," + text.right(3) + grouped
		text = text.left(text.length() - 3)
	grouped = text + grouped
	return ("-" if value < 0 else "") + grouped
