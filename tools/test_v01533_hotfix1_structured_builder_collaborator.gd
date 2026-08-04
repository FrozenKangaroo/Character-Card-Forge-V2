extends SceneTree

const SOURCE_SERVICE = preload(
	"res://scripts/services/collaborator_source_context_service_v01533.gd"
)
const GENERATOR_HOTFIX = preload(
	"res://scripts/ui/idea_generator_window_v01533_hotfix1.gd"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_source_contract()
	await _test_generator_handoff()
	await _test_real_main_wiring()
	print("v0.15.33-hotfix1 Structured Builder Collaborator regression passed")
	quit(0)


func _test_source_contract() -> void:
	var source := SOURCE_SERVICE.from_structured_builder(
		[
			{"id": "setting", "label": "Setting", "value": "University"},
			{"id": "relationship", "label": "Relationship", "value": "Classmate"}
		],
		"Keep {{user}} central to the opening dynamic.",
		{"options_format_version": 3}
	)
	assert(SOURCE_SERVICE.is_valid(source), "Structured Builder must produce a valid Collaborator source.")
	assert(str(source.get("source_type", "")) == "structured_builder")
	assert(SOURCE_SERVICE.display_type(source) == "Structured Builder")
	var snapshot: Dictionary = source.get("snapshot", {})
	assert((snapshot.get("ingredients", []) as Array).size() == 2)
	assert(str(snapshot.get("custom_instructions", "")).contains("{{user}}"))
	assert(str(snapshot.get("concept", "")).contains("Setting: University"))
	var provenance: Dictionary = source.get("provenance", {})
	assert(str(provenance.get("origin", "")) == "structured_builder")
	assert(int(provenance.get("options_format_version", 0)) == 3)
	var model_block := SOURCE_SERVICE.model_context_block(source)
	assert(model_block.contains("Source type: Structured Builder"))
	assert(model_block.contains("ESTABLISHED SOURCE FACTS"))
	assert(model_block.contains("University"))


func _test_generator_handoff() -> void:
	var generator := GENERATOR_HOTFIX.new() as CCFIdeaGeneratorWindowV01533Hotfix1
	root.add_child(generator)
	await process_frame
	await process_frame
	var button := generator.find_child("DevelopStructuredBuilderV01533Hotfix1", true, false) as Button
	assert(button != null, "Structured Builder must expose Develop in Collaborator.")
	assert(button.text == "Develop in Collaborator")

	var controls_value: Variant = generator.get("_field_controls")
	assert(controls_value is Dictionary and not (controls_value as Dictionary).is_empty())
	var controls: Dictionary = controls_value
	var chosen_label := ""
	var chosen_value := "Regression Ingredient"
	for raw_control in controls.values():
		if not raw_control is Dictionary:
			continue
		var control: Dictionary = raw_control
		var edit := control.get("edit") as LineEdit
		var field_value: Variant = control.get("field", {})
		if edit == null or not field_value is Dictionary:
			continue
		var field: Dictionary = field_value
		chosen_label = str(field.get("label", "Field"))
		edit.text = chosen_value
		break
	assert(not chosen_label.is_empty(), "Regression fixture must find a Structured Builder field.")
	var custom := generator.get("_custom_instructions") as TextEdit
	assert(custom != null)
	custom.text = "Preserve the selected ingredients exactly."

	var capture := {"source": {}}
	generator.collaborator_source_requested.connect(
		func(source: Dictionary) -> void:
			capture["source"] = source.duplicate(true)
	)
	generator.call("_develop_structured_in_collaborator_v01533_hotfix1")
	var source_value: Variant = capture.get("source", {})
	assert(source_value is Dictionary and not (source_value as Dictionary).is_empty())
	var source: Dictionary = source_value
	assert(str(source.get("source_type", "")) == "structured_builder")
	var snapshot: Dictionary = source.get("snapshot", {})
	var concept := str(snapshot.get("concept", ""))
	assert(concept.contains(chosen_label + ": " + chosen_value))
	assert(concept.contains("Preserve the selected ingredients exactly."))

	generator.queue_free()
	await process_frame


func _test_real_main_wiring() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	assert(packed != null, "The real main scene must load.")
	var app := packed.instantiate()
	root.add_child(app)
	for _frame in range(5):
		await process_frame
	var workspace_value: Variant = app.get("_workspace")
	assert(
		workspace_value is CCFWorkspaceV01533Hotfix1View,
		"The live app must install the v0.15.33-hotfix1 Workspace."
	)
	var workspace := workspace_value as CCFWorkspaceV01533Hotfix1View
	var capabilities: Dictionary = workspace.collaborator_source_capabilities_v01533()
	assert(bool(capabilities.get("structured_builder_handoff", false)))
	var generator_value: Variant = workspace.get("_idea_generator_v01532")
	assert(
		generator_value is CCFIdeaGeneratorWindowV01533Hotfix1,
		"The live Workspace must install the Structured Builder Collaborator hotfix."
	)
	var live_generator := generator_value as CCFIdeaGeneratorWindowV01533Hotfix1
	assert(
		live_generator.find_child("DevelopStructuredBuilderV01533Hotfix1", true, false) != null,
		"The live Structured Builder must contain Develop in Collaborator."
	)
	app.queue_free()
	await process_frame
