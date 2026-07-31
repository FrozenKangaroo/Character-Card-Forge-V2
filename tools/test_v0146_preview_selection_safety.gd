extends SceneTree

const WORKSPACE = preload("res://scripts/ui/workspace_v0146.gd")


func _init() -> void:
	var workspace := WORKSPACE.new()

	var vision_project := {
		"concept": {"prompt": "Keep this existing generation concept."},
		"character": {"description": "Old visual description."}
	}
	var concept_check := CheckBox.new()
	concept_check.button_pressed = false
	var concept_edit := TextEdit.new()
	concept_edit.text = ""
	var description_check := CheckBox.new()
	description_check.button_pressed = true
	var description_edit := TextEdit.new()
	description_edit.text = "New vision description."
	var vision_rows := [
		{
			"field": {"id": "concept", "path": "concept.prompt", "type": "multiline"},
			"checkbox": concept_check,
			"editor": concept_edit
		},
		{
			"field": {"id": "description", "path": "character.description", "type": "multiline"},
			"checkbox": description_check,
			"editor": description_edit
		}
	]
	var vision_applied := workspace._apply_selected_preview_rows_to_project(vision_project, vision_rows)
	assert(vision_applied == ["description"], "Vision Preview should apply only the checked Description proposal.")
	assert(
		str(CCFStorageService.get_value_at_path(vision_project, "concept.prompt", ""))
		== "Keep this existing generation concept.",
		"Unticking Generation Concept must preserve the existing concept instead of replacing it with blank/null preview data."
	)
	assert(
		str(CCFStorageService.get_value_at_path(vision_project, "character.description", ""))
		== "New vision description.",
		"Checked Vision Preview fields should still apply normally."
	)

	var normal_project := {
		"character": {
			"personality": "Existing personality that must survive.",
			"scenario": "Existing scenario."
		}
	}
	var personality_check := CheckBox.new()
	personality_check.button_pressed = false
	var personality_edit := TextEdit.new()
	personality_edit.text = "Generated replacement personality."
	var scenario_check := CheckBox.new()
	scenario_check.button_pressed = true
	var scenario_edit := TextEdit.new()
	scenario_edit.text = "Generated replacement scenario."
	var normal_rows := [
		{
			"field": {"id": "personality", "path": "character.personality", "type": "multiline"},
			"checkbox": personality_check,
			"editor": personality_edit
		},
		{
			"field": {"id": "scenario", "path": "character.scenario", "type": "multiline"},
			"checkbox": scenario_check,
			"editor": scenario_edit
		}
	]
	var normal_applied := workspace._apply_selected_preview_rows_to_project(normal_project, normal_rows)
	assert(normal_applied == ["scenario"], "Normal Generation Preview should apply only checked fields.")
	assert(
		str(CCFStorageService.get_value_at_path(normal_project, "character.personality", ""))
		== "Existing personality that must survive.",
		"Unticked normal-generation fields must be preserved exactly."
	)
	assert(
		str(CCFStorageService.get_value_at_path(normal_project, "character.scenario", ""))
		== "Generated replacement scenario.",
		"Checked normal-generation fields should still apply normally."
	)

	var source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v0146.gd")
	assert(source.contains("_capture_all_fields()"), "Preview Apply must capture live workspace edits immediately before applying selections.")
	assert(source.contains("if not checkbox.button_pressed"), "Preview selection safety must explicitly skip unchecked rows.")
	assert(source.contains("continue"), "Unchecked preview rows must perform no project write.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v0146.gd")
	assert(main_source.contains("0.14.6"), "v0.14.6 development label is missing.")

	workspace.free()
	concept_check.free()
	concept_edit.free()
	description_check.free()
	description_edit.free()
	personality_check.free()
	personality_edit.free()
	scenario_check.free()
	scenario_edit.free()
	print("v0.14.6 preview selection safety regression passed")
	quit(0)
