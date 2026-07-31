class_name CCFWorkspaceV0143View
extends "res://scripts/ui/workspace_v0142.gd"

const REVIEW_WARNING_PANEL_NAME := "RecoverableGenerationReviewWarning"


func _on_job_completed(
	job_id: String, job_type: String, data: Variant, metadata: Dictionary
) -> void:
	super._on_job_completed(job_id, job_type, data, metadata)
	if job_type != "character":
		return
	var recovery_value: Variant = metadata.get("review_recovery", {})
	if recovery_value is Dictionary and bool(recovery_value.get("recoverable", false)):
		_status.text = "Generation finished with review warnings. The candidate was preserved so you can keep, edit, selectively apply, or repair individual fields."


func _show_generation_preview(
	generated: Dictionary, metadata: Dictionary, preview_title: String
) -> void:
	super._show_generation_preview(generated, metadata, preview_title)
	var recovery_value: Variant = metadata.get("review_recovery", {})
	if not recovery_value is Dictionary or not bool(recovery_value.get("recoverable", false)):
		return
	if _preview_result_box == null or _preview_summary == null:
		return

	var recovery: Dictionary = recovery_value
	_preview_summary.text = (
		"Review warning: automatic validation still found problems after its repair pass, but the generated character was preserved. "
		+ _preview_summary.text
	)

	var panel := PanelContainer.new()
	panel.name = REVIEW_WARNING_PANEL_NAME
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview_result_box.add_child(panel)
	_preview_result_box.move_child(panel, 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)

	var heading := Label.new()
	heading.text = "Review found issues — generated data was not discarded"
	heading.add_theme_font_size_override("font_size", 17)
	content.add_child(heading)

	var guidance := Label.new()
	guidance.text = str(
		recovery.get(
			"guidance",
			"Apply the fields you want, edit proposals here, or regenerate an affected field later with its normal AI Suggest button."
		)
	)
	guidance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guidance.modulate = Color(0.86, 0.74, 0.48)
	content.add_child(guidance)

	var issues_value: Variant = recovery.get("issues", [])
	if issues_value is Array:
		for raw_issue in issues_value:
			if not raw_issue is Dictionary:
				continue
			var issue: Dictionary = raw_issue
			var field_id := str(issue.get("field_id", "Field")).strip_edges()
			var label := str(issue.get("label", "")).strip_edges()
			var reason := str(issue.get("reason", "Needs review.")).strip_edges()
			var issue_label := Label.new()
			issue_label.text = "• %s%s — %s" % [
				field_id,
				" / %s" % label if not label.is_empty() and label != field_id else "",
				reason
			]
			issue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			content.add_child(issue_label)
