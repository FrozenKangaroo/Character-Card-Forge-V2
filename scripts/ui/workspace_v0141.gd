class_name CCFWorkspaceV0141View
extends "res://scripts/ui/workspace_v014.gd"

const INTERVIEW_REVIEW_PATH := "generation.interview_review"
const INTERVIEW_REVIEW_PANEL_NAME := "InterviewGenerationReview"


func _rebuild_form() -> void:
	super._rebuild_form()
	_decorate_interview_review()


func _on_job_completed(
	job_id: String, job_type: String, data: Variant, metadata: Dictionary
) -> void:
	if job_type == "character":
		var review_value: Variant = metadata.get("generation_interview_review", {})
		if review_value is Dictionary and not review_value.get("entries", []).is_empty():
			_store_interview_review(review_value)
	super._on_job_completed(job_id, job_type, data, metadata)


func _store_interview_review(review_value: Dictionary) -> void:
	if _project.is_empty():
		return
	CCFStorageService.set_value_at_path(
		_project, INTERVIEW_REVIEW_PATH, review_value.duplicate(true)
	)
	_dirty = true
	_refresh_interview_review_panels()


func _refresh_interview_review_panels() -> void:
	for node in find_children(INTERVIEW_REVIEW_PANEL_NAME, "PanelContainer", true, false):
		if node is PanelContainer:
			var parent := node.get_parent()
			if parent != null:
				parent.remove_child(node)
			node.queue_free()
	_decorate_interview_review()


func _decorate_interview_review() -> void:
	if _project.is_empty():
		return
	var review_value: Variant = CCFStorageService.get_value_at_path(
		_project, INTERVIEW_REVIEW_PATH, {}
	)
	if not review_value is Dictionary:
		return
	var entries_value: Variant = review_value.get("entries", [])
	if not entries_value is Array or entries_value.is_empty():
		return

	for raw_section in _template.get("sections", []):
		if not raw_section is Dictionary:
			continue
		var section: Dictionary = raw_section
		if str(section.get("kind", "standard")) != "interview":
			continue
		var content := _interview_section_content(section)
		if content == null:
			continue
		var section_ids: Dictionary = {}
		for raw_field in section.get("fields", []):
			if raw_field is Dictionary:
				section_ids[str(raw_field.get("id", ""))] = true
		var section_entries: Array[Dictionary] = []
		for raw_entry in entries_value:
			if not raw_entry is Dictionary:
				continue
			var entry: Dictionary = raw_entry
			if section_ids.has(str(entry.get("id", ""))):
				section_entries.append(entry)
		if section_entries.is_empty():
			continue
		_add_interview_review_panel(content, section_entries)


func _interview_section_content(section: Dictionary) -> VBoxContainer:
	for raw_field in section.get("fields", []):
		if not raw_field is Dictionary:
			continue
		var path := str(raw_field.get("path", ""))
		var row_value: Variant = _field_controls.get(path, {})
		if not row_value is Dictionary:
			continue
		var control_value: Variant = row_value.get("control", null)
		if control_value is Control and control_value.get_parent() is VBoxContainer:
			return control_value.get_parent() as VBoxContainer
	return null


func _add_interview_review_panel(
	content: VBoxContainer, entries: Array[Dictionary]
) -> void:
	var panel := PanelContainer.new()
	panel.name = INTERVIEW_REVIEW_PANEL_NAME
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var title := Label.new()
	title.text = "Latest generation interview responses"
	title.add_theme_font_size_override("font_size", 17)
	root.add_child(title)

	var intro := Label.new()
	intro.text = "These are the planning answers used by the latest completed character generation. AI Interview answers remain AI-sourced and are not silently promoted to manual answers."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.modulate = Color(0.68, 0.72, 0.84)
	root.add_child(intro)

	for entry in entries:
		root.add_child(HSeparator.new())
		var heading := Label.new()
		heading.text = str(entry.get("label", entry.get("id", "Question")))
		heading.add_theme_font_size_override("font_size", 15)
		root.add_child(heading)

		var question_text := str(entry.get("question", "")).strip_edges()
		if not question_text.is_empty() and question_text != heading.text:
			var question_label := Label.new()
			question_label.text = question_text
			question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			question_label.modulate = Color(0.65, 0.68, 0.76)
			root.add_child(question_label)

		var source_label := Label.new()
		source_label.text = (
			"Source: Manual answer"
			if str(entry.get("source", "ai")) == "manual"
			else "Source: AI Interview"
		)
		source_label.modulate = Color(0.66, 0.78, 0.9)
		root.add_child(source_label)

		var answer_label := Label.new()
		answer_label.text = str(entry.get("answer", ""))
		answer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root.add_child(answer_label)

	content.add_child(panel)
	var insert_index := content.get_child_count() - 1
	for child_index in range(content.get_child_count()):
		var child := content.get_child(child_index)
		if child is Label and child.text.begins_with("Interview / Q&A section"):
			insert_index = mini(child_index + 1, content.get_child_count() - 1)
			break
	content.move_child(panel, insert_index)
