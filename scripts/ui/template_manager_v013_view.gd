class_name CCFTemplateManagerV013View
extends CCFTemplateManagerView

const DEFAULT_INTERVIEW_PATH := "res://data/generation_interviews/default.json"

var _generation_editor: CCFGenerationComponentEditorGuardWindow
var _generation_button: Button


func _ready() -> void:
	super._ready()
	_generation_editor = CCFGenerationComponentEditorGuardWindow.new()
	_generation_editor.visible = false
	_generation_editor.groups_applied.connect(_on_generation_groups_applied)
	add_child(_generation_editor)
	_generation_editor.hide()
	_build_generation_toolbar()
	_update_generation_button()


func refresh_templates(select_template_id := "") -> void:
	super.refresh_templates(select_template_id)
	_update_generation_button()


func _load_template(template_id: String) -> void:
	super._load_template(template_id)
	if _current_template.is_empty():
		return
	if not _inject_bundled_interview_if_missing():
		return
	_refresh_section_list()
	_update_read_only_state()
	if _current_template_id == "default":
		_status.text = "Loaded Default Character Card. Interview / Q&A shows the bundled private-generation questions. Duplicate the template to customise them."
	else:
		_status.text = "Loaded %s. This template inherits the bundled Interview / Q&A questions; edit them and Save Template to make the interview explicit for this template." % str(_current_template.get("name", "Template"))


func _inject_bundled_interview_if_missing() -> bool:
	var sections_value: Variant = _current_template.get("sections", [])
	var sections: Array = sections_value.duplicate(true) if sections_value is Array else []
	for raw_section in sections:
		if raw_section is Dictionary and str(raw_section.get("kind", "standard")) == "interview":
			return false
	var interview_section := _bundled_interview_section()
	var fields_value: Variant = interview_section.get("fields", {})
	if not fields_value is Array or fields_value.is_empty():
		return false
	sections.append(interview_section)
	_current_template["sections"] = sections
	return true


func _bundled_interview_section() -> Dictionary:
	var fields: Array = []
	for raw_question in _read_bundled_interview_questions():
		if not raw_question is Dictionary:
			continue
		var question: Dictionary = raw_question
		var question_id := str(question.get("id", "")).strip_edges()
		var question_text := str(question.get("question", "")).strip_edges()
		if question_id.is_empty() or question_text.is_empty():
			continue
		fields.append(
			{
				"id": question_id,
				"label": str(question.get("label", question_id.replace("_", " ").capitalize())),
				"type": "multiline",
				"path": "generation.interview_answers.%s" % question_id,
				"placeholder": "Optional manual answer. Leave blank to let the private generation interview resolve this question.",
				"generate": true,
				"height": 110,
				"required": bool(question.get("required", true)),
				"generation_prompt": question_text
			}
		)
	return {
		"id": "generation_interview",
		"title": "Interview / Q&A",
		"description": "Private planning questions used before full-character generation. Enter an answer manually to make it authoritative, or leave it blank and the planning pass will answer it. These questions are not requested as final Character Card fields.",
		"kind": "interview",
		"fields": fields
	}


func _read_bundled_interview_questions() -> Array:
	if not FileAccess.file_exists(DEFAULT_INTERVIEW_PATH):
		return []
	var file := FileAccess.open(DEFAULT_INTERVIEW_PATH, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return []
	var questions_value: Variant = parsed.get("questions", [])
	return questions_value.duplicate(true) if questions_value is Array else []


func _build_generation_toolbar() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var hint := Label.new()
	hint.text = "Generation structure controls the labelled subfields the AI builds inside normal card fields such as Description and Personality. Interview / Q&A sections control the private planning questions used before full generation."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(hint)
	_generation_button = Button.new()
	_generation_button.text = "Edit Generation Components"
	_generation_button.tooltip_text = "Add, remove, reorder, enable or disable structured generation components and choose which card field they fold into."
	_generation_button.pressed.connect(_open_generation_editor)
	row.add_child(_generation_button)
	add_child(row)
	move_child(row, 1)


func _open_generation_editor() -> void:
	if _current_template.is_empty():
		return
	_generation_editor.open_for_template(_current_template, _current_template_id == "default")


func _on_generation_groups_applied(groups: Array) -> void:
	if _current_template_id.is_empty() or _current_template_id == "default":
		return
	_current_template["generation_groups"] = groups.duplicate(true)
	_status.text = "Generation components changed. Press Save Template to persist them."
	_update_generation_button()


func _update_generation_button() -> void:
	if _generation_button == null:
		return
	_generation_button.disabled = _current_template.is_empty()
	var group_count := 0
	var component_count := 0
	var raw_groups: Variant = _current_template.get("generation_groups", []) if not _current_template.is_empty() else []
	if raw_groups is Array:
		group_count = raw_groups.size()
		for raw_group in raw_groups:
			if raw_group is Dictionary:
				var raw_components: Variant = raw_group.get("components", [])
				if raw_components is Array:
					component_count += raw_components.size()
	_generation_button.text = "Edit Generation Components (%d / %d)" % [group_count, component_count]
