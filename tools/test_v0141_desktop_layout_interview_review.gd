extends SceneTree


func _init() -> void:
	_assert_equal(
		str(ProjectSettings.get_setting("display/window/stretch/mode", "")),
		"disabled",
		"Desktop app window resizing must expose more workspace instead of scaling the entire canvas."
	)

	var service := CCFGenerationServiceV0141.new()
	var review := service.build_interview_review({
		"interview_questions": [
			{"id": "manual_q", "label": "Manual Question", "question": "Manual?", "required": true},
			{"id": "ai_q", "label": "AI Question", "question": "AI?", "required": false}
		],
		"interview_answers": {
			"manual_q": "Author answer",
			"ai_q": "Generated planning answer"
		},
		"interview_manual_ids": ["manual_q"]
	})
	var entries: Array = review.get("entries", [])
	_assert_equal(entries.size(), 2, "Interview review must preserve answered questions.")
	_assert_equal(str(entries[0].get("source", "")), "manual", "Manual provenance must survive.")
	_assert_equal(str(entries[1].get("source", "")), "ai", "AI provenance must survive.")
	_assert_equal(
		str(entries[1].get("answer", "")),
		"Generated planning answer",
		"AI Interview response text must remain reviewable."
	)

	var workspace := CCFWorkspaceV0141View.new()
	workspace._project = {"generation": {}}
	workspace._template = {
		"sections": [{
			"kind": "interview",
			"fields": [
				{"id": "manual_q", "path": "interview.manual_q"},
				{"id": "ai_q", "path": "interview.ai_q"}
			]
		}]
	}
	var content := VBoxContainer.new()
	workspace.add_child(content)
	var interview_hint := Label.new()
	interview_hint.text = "Interview / Q&A section — field instructions can act as direct questions for AI generation."
	content.add_child(interview_hint)
	var field_control := LineEdit.new()
	content.add_child(field_control)
	workspace._field_controls = {
		"interview.manual_q": {"control": field_control},
		"interview.ai_q": {"control": field_control}
	}
	workspace._store_interview_review(review)
	var stored: Dictionary = CCFStorageService.get_value_at_path(
		workspace._project, "generation.interview_review", {}
	)
	_assert_equal(
		stored.get("entries", []).size(),
		2,
		"Latest interview review must persist in character-local generation state."
	)
	var panel := workspace.find_child(
		CCFWorkspaceV0141View.INTERVIEW_REVIEW_PANEL_NAME,
		true,
		false
	)
	_assert_true(
		panel is PanelContainer,
		"Interview / Q&A UI must render the persisted review panel."
	)
	_assert_true(
		_has_label_text(panel, "Source: AI Interview"),
		"Rendered review must identify AI Interview provenance."
	)
	_assert_true(
		_has_label_text(panel, "Generated planning answer"),
		"Rendered review must show the AI response text."
	)

	workspace.queue_free()
	service.queue_free()
	print("v0.14.1 desktop layout and interview review regression passed")
	quit(0)


func _has_label_text(root: Node, expected: String) -> bool:
	for node in root.find_children("*", "Label", true, false):
		if node is Label and node.text == expected:
			return true
	return false


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_fail("%s Expected %s, got %s." % [message, str(expected), str(actual)])


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_fail(message)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
