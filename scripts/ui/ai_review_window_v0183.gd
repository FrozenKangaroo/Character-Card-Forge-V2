class_name CCFAIReviewWindowV0183
extends Window

signal review_requested_v0183()
signal project_changed_v0183(
	project: Dictionary, active_character_id: String, message: String
)

const REVIEW_SERVICE = preload(
	"res://scripts/services/ai_review_service_v0183.gd"
)

var _project_data: Dictionary = {}
var _character_id := ""
var _active_job_id := ""
var _selected_review_id := ""
var _review_history: OptionButton
var _score_label: Label
var _stale_label: Label
var _summary: TextEdit
var _rubric_tree: Tree
var _findings_tree: Tree
var _finding_detail: TextEdit
var _proposal_list: VBoxContainer
var _proposal_rows: Array[Dictionary] = []
var _report_text: TextEdit
var _report_export_button: Button
var _run_button: Button
var _approve_all_button: Button
var _apply_button: Button
var _status: Label
var _apply_confirm: ConfirmationDialog
var _report_dialog: FileDialog


func _ready() -> void:
	title = "AI Review"
	size = Vector2i(1240, 860)
	min_size = Vector2i(940, 680)
	force_native = true
	transient = true
	exclusive = false
	close_requested.connect(hide)
	_build_ui()
	_build_dialog()
	hide()


func open_for_character(project: Dictionary, character_id: String) -> void:
	_project_data = project.duplicate(true)
	_character_id = character_id
	_active_job_id = ""
	_refresh_history()
	popup_centered()


func owns_project(project_id: String) -> bool:
	return (
		not _project_data.is_empty()
		and str(_project_data.get("project_id", "")) == project_id
	)


func update_project_context(project: Dictionary, character_id: String) -> void:
	if not owns_project(str(project.get("project_id", ""))):
		return
	_project_data = project.duplicate(true)
	_character_id = character_id
	_refresh_history()


func begin_review(job_id: String) -> void:
	_active_job_id = job_id
	_run_button.disabled = true
	_status.text = "AI Review is running… No card fields will change automatically."


func handle_job_completed(
	job_id: String, data: Variant, metadata: Dictionary
) -> bool:
	if job_id != _active_job_id:
		return false
	_active_job_id = ""
	_run_button.disabled = false
	var expected_hash := str(metadata.get("content_hash", ""))
	if (
		not expected_hash.is_empty()
		and expected_hash != REVIEW_SERVICE.character_content_hash(_project_data, _character_id)
	):
		_status.text = "The card changed while AI Review was running. This result was not saved; run it again."
		return true
	var validated := REVIEW_SERVICE.validate_result(_project_data, _character_id, data)
	if not bool(validated.get("ok", false)):
		_status.text = str(validated.get("error", "AI Review returned an unusable result."))
		return true
	var recorded := REVIEW_SERVICE.record_review(
		_project_data, _character_id, validated, metadata
	)
	if not bool(recorded.get("ok", false)):
		_status.text = str(recorded.get("error", "AI Review could not be recorded."))
		return true
	_project_data = recorded.get("project", _project_data).duplicate(true)
	_selected_review_id = str(recorded.get("review", {}).get("review_id", ""))
	_refresh_history()
	_status.text = "AI Review finished. Review the complete change set; nothing has been applied."
	project_changed_v0183.emit(
		_project_data.duplicate(true), _character_id, "AI Review history saved; no card fields changed."
	)
	return true


func handle_job_failed(job_id: String, message: String) -> bool:
	if job_id != _active_job_id:
		return false
	_active_job_id = ""
	_run_button.disabled = false
	_status.text = message
	return true


func handle_job_cancelled(job_id: String) -> bool:
	if job_id != _active_job_id:
		return false
	_active_job_id = ""
	_run_button.disabled = false
	_status.text = "AI Review cancelled. No card fields changed."
	return true


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 9)
	margin.add_child(page)
	var heading := Label.new()
	heading.text = "AI Review, Rating and Selective Improvement"
	heading.add_theme_font_size_override("font_size", 22)
	page.add_child(heading)
	var notice := Label.new()
	notice.text = (
		"Optional and advisory: the score uses visible rubric v%d and is not an objective "
		+ "measure of quality. Reviews never run merely because the library opens, and AI "
		+ "suggestions never change the card until you approve them."
	) % REVIEW_SERVICE.RUBRIC_VERSION
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(notice)
	var toolbar := HBoxContainer.new()
	page.add_child(toolbar)
	_run_button = Button.new()
	_run_button.text = "Run AI Review"
	_run_button.pressed.connect(_request_review)
	toolbar.add_child(_run_button)
	var history_label := Label.new()
	history_label.text = "Review history"
	toolbar.add_child(history_label)
	_review_history = OptionButton.new()
	_review_history.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_review_history.item_selected.connect(_select_history)
	toolbar.add_child(_review_history)
	_score_label = Label.new()
	_score_label.text = "No score"
	toolbar.add_child(_score_label)
	_stale_label = Label.new()
	_stale_label.text = ""
	toolbar.add_child(_stale_label)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(tabs)
	_build_overview_tab(tabs)
	_build_findings_tab(tabs)
	_build_changes_tab(tabs)
	_build_report_tab(tabs)
	var actions := HBoxContainer.new()
	page.add_child(actions)
	_approve_all_button = Button.new()
	_approve_all_button.text = "Approve All Visible Changes"
	_approve_all_button.tooltip_text = "Available only after the complete proposal list is displayed."
	_approve_all_button.pressed.connect(_approve_all)
	actions.add_child(_approve_all_button)
	_apply_button = Button.new()
	_apply_button.text = "Review Decisions and Apply…"
	_apply_button.pressed.connect(_request_apply)
	actions.add_child(_apply_button)
	_status = Label.new()
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actions.add_child(_status)


func _build_overview_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "RubricOverview"
	tabs.add_child(page)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Score & Rubric")
	_rubric_tree = Tree.new()
	_rubric_tree.columns = 3
	_rubric_tree.column_titles_visible = true
	_rubric_tree.set_column_title(0, "Category")
	_rubric_tree.set_column_title(1, "Weight")
	_rubric_tree.set_column_title(2, "AI score / 10")
	_rubric_tree.hide_root = true
	_rubric_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_rubric_tree)
	_summary = TextEdit.new()
	_summary.editable = false
	_summary.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_summary.custom_minimum_size.y = 130
	page.add_child(_summary)


func _build_findings_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "Findings"
	tabs.add_child(page)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Findings")
	var explanation := Label.new()
	explanation.text = "Check Dismiss for an intentional choice you want retained in review history."
	page.add_child(explanation)
	var split := VSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(split)
	_findings_tree = Tree.new()
	_findings_tree.columns = 4
	_findings_tree.column_titles_visible = true
	_findings_tree.set_column_title(0, "Severity")
	_findings_tree.set_column_title(1, "Category")
	_findings_tree.set_column_title(2, "Finding")
	_findings_tree.set_column_title(3, "Dismiss")
	_findings_tree.set_column_expand(2, true)
	_findings_tree.hide_root = true
	_findings_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_findings_tree.custom_minimum_size.y = 180
	_findings_tree.item_selected.connect(_show_selected_finding)
	split.add_child(_findings_tree)
	_finding_detail = TextEdit.new()
	_finding_detail.editable = false
	_finding_detail.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_finding_detail.custom_minimum_size.y = 180
	_finding_detail.placeholder_text = "Select a finding above to read its complete explanation and affected fields."
	split.add_child(_finding_detail)


func _build_changes_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "SelectiveChanges"
	tabs.add_child(page)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Selective Changes")
	var explanation := Label.new()
	explanation.text = (
		"Every proposed field is shown. Reject is the default. Choose Approve, and edit the "
		+ "proposed value directly if needed before applying the batch. Arrays/objects use JSON."
	)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(explanation)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	_proposal_list = VBoxContainer.new()
	_proposal_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_proposal_list.add_theme_constant_override("separation", 12)
	scroll.add_child(_proposal_list)


func _build_report_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "FullReport"
	tabs.add_child(page)
	tabs.set_tab_title(tabs.get_tab_count() - 1, "Full Report")
	var explanation := Label.new()
	explanation.text = (
		"Complete text-only record of the selected review, including provenance, rubric, "
		+ "full findings, complete current/proposed values and recorded decisions."
	)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(explanation)
	_report_text = TextEdit.new()
	_report_text.editable = false
	_report_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_report_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_report_text)
	var report_actions := HBoxContainer.new()
	page.add_child(report_actions)
	_report_export_button = Button.new()
	_report_export_button.text = "Export Full Report…"
	_report_export_button.pressed.connect(_request_report_export)
	report_actions.add_child(_report_export_button)
	var copy_report_button := Button.new()
	copy_report_button.text = "Copy Full Report"
	copy_report_button.pressed.connect(_copy_report)
	report_actions.add_child(copy_report_button)


func _build_dialog() -> void:
	_apply_confirm = ConfirmationDialog.new()
	_apply_confirm.title = "Apply reviewed AI changes?"
	_apply_confirm.dialog_text = (
		"Only fields marked Approve will change. Rejected changes and dismissed findings "
		+ "remain in private review history. An automatic revision recovery point will be created."
	)
	_apply_confirm.confirmed.connect(_apply_decisions)
	add_child(_apply_confirm)
	_report_dialog = FileDialog.new()
	_report_dialog.title = "Export AI Review Report"
	_report_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_report_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_report_dialog.filters = PackedStringArray(["*.txt ; Plain-text AI Review report"])
	_report_dialog.file_selected.connect(_save_report)
	add_child(_report_dialog)


func _request_review() -> void:
	if _character_id.is_empty() or not _active_job_id.is_empty():
		return
	review_requested_v0183.emit()


func _refresh_history() -> void:
	_review_history.clear()
	var reviews := REVIEW_SERVICE.list_reviews(_project_data, _character_id)
	for review_value in reviews:
		var review: Dictionary = review_value
		var label := "%s • %.1f/10 • %s" % [
			str(review.get("created_at", "Unknown time")),
			float(review.get("overall_score", 0.0)),
			str(review.get("status", "reviewed")).capitalize()
		]
		_review_history.add_item(label)
		_review_history.set_item_metadata(
			_review_history.item_count - 1, str(review.get("review_id", ""))
		)
	if reviews.is_empty():
		_selected_review_id = ""
		_render_review({})
		return
	var selected_index := reviews.size() - 1
	if not _selected_review_id.is_empty():
		for index in range(_review_history.item_count):
			if str(_review_history.get_item_metadata(index)) == _selected_review_id:
				selected_index = index
				break
	_review_history.select(selected_index)
	_selected_review_id = str(_review_history.get_item_metadata(selected_index))
	_render_review(REVIEW_SERVICE.get_review(
		_project_data, _character_id, _selected_review_id
	))


func _select_history(index: int) -> void:
	_selected_review_id = str(_review_history.get_item_metadata(index))
	_render_review(REVIEW_SERVICE.get_review(
		_project_data, _character_id, _selected_review_id
	))


func _render_review(review: Dictionary) -> void:
	_rubric_tree.clear()
	_findings_tree.clear()
	_finding_detail.clear()
	_clear_proposal_rows()
	var rubric_root := _rubric_tree.create_item()
	var finding_root := _findings_tree.create_item()
	if review.is_empty():
		_score_label.text = "No score"
		_stale_label.text = ""
		_summary.text = "Run AI Review when you want an advisory consistency check."
		_report_text.text = "No AI Review is selected."
		_report_export_button.disabled = true
		_approve_all_button.disabled = true
		_apply_button.disabled = true
		return
	_score_label.text = "AI Review Score: %.1f / 10" % float(review.get("overall_score", 0.0))
	var stale := REVIEW_SERVICE.review_is_stale(_project_data, _character_id, review)
	_stale_label.text = "STALE" if stale else "Current"
	_stale_label.modulate = Color(1.0, 0.55, 0.25) if stale else Color(0.45, 0.9, 0.62)
	_summary.text = str(review.get("summary", "No summary supplied."))
	_report_text.text = REVIEW_SERVICE.full_report_text(
		_project_data, _character_id, review
	)
	_report_export_button.disabled = false
	var scores: Dictionary = review.get("scores", {})
	for category in REVIEW_SERVICE.rubric():
		var item := _rubric_tree.create_item(rubric_root)
		var category_id := str(category.get("id", ""))
		item.set_text(0, str(category.get("label", category_id)))
		item.set_text(1, "%d%%" % int(category.get("weight", 0)))
		item.set_text(2, "%.1f" % float(scores.get(category_id, 0.0)))
	var dismissed: Array = review.get("dismissed_finding_ids", [])
	for finding_value in review.get("findings", []):
		var finding: Dictionary = finding_value
		var item := _findings_tree.create_item(finding_root)
		item.set_text(0, str(finding.get("severity", "info")).capitalize())
		item.set_text(1, str(finding.get("category", "")))
		item.set_text(2, str(finding.get("title", "Review note")))
		item.set_tooltip_text(2, "Select this row to read the complete finding below.")
		item.set_cell_mode(3, TreeItem.CELL_MODE_CHECK)
		item.set_editable(3, str(review.get("status", "reviewed")) == "reviewed" and not stale)
		item.set_checked(3, dismissed.has(str(finding.get("id", ""))))
		item.set_metadata(3, str(finding.get("id", "")))
		item.set_metadata(2, finding.duplicate(true))
	for proposal_value in review.get("proposals", []):
		var proposal: Dictionary = proposal_value
		_add_proposal_row(
			proposal,
			str(review.get("status", "reviewed")) == "reviewed" and not stale
		)
	var first_finding := finding_root.get_first_child()
	if first_finding != null:
		first_finding.select(2)
		_show_finding(first_finding.get_metadata(2))
	var editable := str(review.get("status", "reviewed")) == "reviewed" and not stale
	var proposal_count := int(review.get("proposals", []).size())
	_approve_all_button.disabled = not editable or proposal_count == 0
	_apply_button.disabled = not editable or (
		proposal_count == 0 and review.get("findings", []).is_empty()
	)


func _approve_all() -> void:
	for row in _proposal_rows:
		var decision_value: Variant = row.get("decision")
		if decision_value is OptionButton and not (decision_value as OptionButton).disabled:
			(decision_value as OptionButton).select(1)


func _request_apply() -> void:
	if _selected_review_id.is_empty():
		return
	_apply_confirm.popup_centered()


func _apply_decisions() -> void:
	var decisions: Array = []
	for row in _proposal_rows:
		var selector := row.get("decision") as OptionButton
		var editor := row.get("proposed") as TextEdit
		var action := "approve" if selector != null and selector.selected == 1 else "reject"
		var decision := {"path": str(row.get("path", "")), "action": action}
		if action == "approve":
			var parsed := _parse_edited_value(
				editor.text if editor != null else "", int(row.get("value_type", TYPE_STRING))
			)
			if not bool(parsed.get("ok", false)):
				_status.text = str(parsed.get("error", "An edited proposal is invalid."))
				return
			decision["value"] = parsed.get("value")
		decisions.append(decision)
	var finding_root := _findings_tree.get_root()
	var finding_item := finding_root.get_first_child() if finding_root != null else null
	while finding_item != null:
		if finding_item.is_checked(3):
			decisions.append({
				"action": "dismiss_finding",
				"finding_id": str(finding_item.get_metadata(3))
			})
		finding_item = finding_item.get_next()
	var result := REVIEW_SERVICE.apply_review_decisions(
		_project_data, _character_id, _selected_review_id, decisions
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "The reviewed decisions could not be applied."))
		return
	_project_data = result.get("project", _project_data).duplicate(true)
	var accepted_count := int(result.get("accepted_count", 0))
	_refresh_history()
	var message := (
		"Applied %d explicitly approved AI Review field(s) and created revision checkpoints."
		% accepted_count
		if accepted_count > 0
		else "Recorded rejected changes and intentionally dismissed findings; no card fields changed."
	)
	_status.text = message
	project_changed_v0183.emit(_project_data.duplicate(true), _character_id, message)


func _add_proposal_row(proposal: Dictionary, editable: bool) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_proposal_list.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var field_label := Label.new()
	field_label.text = str(proposal.get("label", proposal.get("path", "Field")))
	field_label.add_theme_font_size_override("font_size", 17)
	field_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(field_label)
	var path_label := Label.new()
	path_label.text = str(proposal.get("path", ""))
	path_label.modulate = Color(0.68, 0.72, 0.8)
	header.add_child(path_label)
	var decision := OptionButton.new()
	decision.add_item("Reject")
	decision.add_item("Approve")
	decision.select(0)
	decision.disabled = not editable
	decision.custom_minimum_size.x = 125
	header.add_child(decision)
	var reason := Label.new()
	reason.text = "Reason: %s" % str(proposal.get("reason", "No reason supplied."))
	reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(reason)
	var comparison := HBoxContainer.new()
	comparison.add_theme_constant_override("separation", 10)
	content.add_child(comparison)
	var current_column := VBoxContainer.new()
	current_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comparison.add_child(current_column)
	var current_label := Label.new()
	current_label.text = "Current value"
	current_column.add_child(current_label)
	var current_editor := TextEdit.new()
	current_editor.text = _display_value(proposal.get("current_value"))
	current_editor.editable = false
	current_editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	current_editor.custom_minimum_size.y = 190
	current_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_column.add_child(current_editor)
	var proposed_column := VBoxContainer.new()
	proposed_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comparison.add_child(proposed_column)
	var proposed_label := Label.new()
	proposed_label.text = "Proposed value — editable before approval"
	proposed_column.add_child(proposed_label)
	var proposed_editor := TextEdit.new()
	proposed_editor.text = _display_value(proposal.get("new_value"))
	proposed_editor.editable = editable
	proposed_editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	proposed_editor.custom_minimum_size.y = 190
	proposed_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	proposed_column.add_child(proposed_editor)
	_proposal_rows.append({
		"path": str(proposal.get("path", "")),
		"value_type": typeof(proposal.get("new_value")),
		"decision": decision,
		"current": current_editor,
		"proposed": proposed_editor,
		"panel": panel
	})


func _clear_proposal_rows() -> void:
	_proposal_rows.clear()
	if _proposal_list == null:
		return
	for child in _proposal_list.get_children():
		_proposal_list.remove_child(child)
		child.queue_free()


func _show_selected_finding() -> void:
	var selected := _findings_tree.get_selected()
	if selected == null:
		return
	_show_finding(selected.get_metadata(2))


func _show_finding(finding_value: Variant) -> void:
	if not finding_value is Dictionary:
		_finding_detail.clear()
		return
	var finding: Dictionary = finding_value
	var paths: Array[String] = []
	for path_value in finding.get("field_paths", []):
		paths.append(str(path_value))
	_finding_detail.text = "%s\n\nSeverity: %s\nCategory: %s\nAffected fields: %s\n\n%s" % [
		str(finding.get("title", "Review note")),
		str(finding.get("severity", "info")).capitalize(),
		str(finding.get("category", "")),
		", ".join(paths) if not paths.is_empty() else "None specified",
		str(finding.get("explanation", "No explanation supplied."))
	]


func _request_report_export() -> void:
	if _selected_review_id.is_empty() or _report_text.text.is_empty():
		return
	var record := CCFStorageService.get_character(_project_data, _character_id)
	var base_name := CCFStorageService.character_display_name(record)
	_report_dialog.current_file = "%s-ai-review.txt" % _safe_filename(base_name)
	_report_dialog.popup_centered_ratio(0.74)


func _copy_report() -> void:
	if _report_text.text.is_empty() or _selected_review_id.is_empty():
		return
	DisplayServer.clipboard_set(_report_text.text)
	_status.text = "Full AI Review report copied to the clipboard."


func _save_report(destination_path: String) -> void:
	var target := destination_path.strip_edges()
	if target.is_empty():
		return
	if not target.to_lower().ends_with(".txt"):
		target += ".txt"
	var file := FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		_status.text = "Could not export the AI Review report."
		return
	file.store_string(_report_text.text)
	file.close()
	_status.text = "Full AI Review report exported."


func _safe_filename(value: String) -> String:
	var result := value.strip_edges()
	for character in ["/", "\\", ":", "*", "?", '"', "<", ">", "|"]:
		result = result.replace(character, "_")
	return result if not result.is_empty() else "character"


func _display_value(value: Variant) -> String:
	if value is Dictionary or value is Array:
		return JSON.stringify(value, "  ")
	return str(value)


func _parse_edited_value(text: String, expected_type: int) -> Dictionary:
	if expected_type == TYPE_ARRAY or expected_type == TYPE_DICTIONARY:
		var parsed: Variant = JSON.parse_string(text)
		if typeof(parsed) != expected_type:
			return {"ok": false, "error": "Structured proposed values must remain valid JSON of the same type."}
		return {"ok": true, "value": parsed}
	return {"ok": true, "value": text}
