class_name CCFWorkspaceV0137View
extends CCFWorkspaceV0136View

var _preview_diagnostics_label: Label


func _build_preview_window() -> void:
	super._build_preview_window()
	if _preview_summary == null or _preview_summary.get_parent() == null:
		return
	_preview_diagnostics_label = Label.new()
	_preview_diagnostics_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_diagnostics_label.modulate = Color(0.68, 0.72, 0.84)
	_preview_diagnostics_label.text = ""
	var parent := _preview_summary.get_parent()
	parent.add_child(_preview_diagnostics_label)
	parent.move_child(_preview_diagnostics_label, _preview_summary.get_index() + 1)


func _on_queue_changed(pending_count: int, active_job_id: String, active_label: String) -> void:
	super._on_queue_changed(pending_count, active_job_id, active_label)
	if _queue_status == null:
		return
	_queue_status.text = CCFGenerationDiagnosticsService.progress_text(
		active_label if not active_job_id.is_empty() else "",
		pending_count
	)


func _show_generation_preview(
	generated: Dictionary, metadata: Dictionary, preview_title: String
) -> void:
	super._show_generation_preview(generated, metadata, preview_title)
	if _preview_diagnostics_label == null:
		return
	_preview_diagnostics_label.text = CCFGenerationDiagnosticsService.preview_text(metadata)


func _hide_preview() -> void:
	if _preview_diagnostics_label != null:
		_preview_diagnostics_label.text = ""
	super._hide_preview()
