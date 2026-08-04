class_name CCFIdeaGeneratorWindowV01533Hotfix1
extends "res://scripts/ui/idea_generator_window_v01533.gd"

const SOURCE_SERVICE_V01533_HOTFIX1 = preload(
	"res://scripts/services/collaborator_source_context_service_v01533.gd"
)

var _develop_structured_button_v01533_hotfix1: Button
var _structured_collaborator_status_v01533_hotfix1: Label


func _build_structured_tab() -> void:
	super._build_structured_tab()
	var tab := _tabs.get_node_or_null("Structured Builder") as VBoxContainer
	if tab == null:
		return
	var build_button := _find_button_by_text_v01533_hotfix1(
		tab, "Build Idea into Main Concept"
	)
	if build_button == null or build_button.get_parent() == null:
		return
	var parent := build_button.get_parent()
	var insert_index := build_button.get_index()
	var actions := HFlowContainer.new()
	actions.name = "StructuredBuilderActionsV01533Hotfix1"
	actions.add_theme_constant_override("separation", 8)
	parent.add_child(actions)
	parent.move_child(actions, insert_index)
	build_button.reparent(actions)

	_develop_structured_button_v01533_hotfix1 = Button.new()
	_develop_structured_button_v01533_hotfix1.name = "DevelopStructuredBuilderV01533Hotfix1"
	_develop_structured_button_v01533_hotfix1.text = "Develop in Collaborator"
	_develop_structured_button_v01533_hotfix1.tooltip_text = (
		"Start a new Character Collaborator conversation directly from the current Structured Builder ingredients. The ingredient values and custom instructions are preserved as read-only structured source context."
	)
	_develop_structured_button_v01533_hotfix1.pressed.connect(
		_develop_structured_in_collaborator_v01533_hotfix1
	)
	actions.add_child(_develop_structured_button_v01533_hotfix1)

	_structured_collaborator_status_v01533_hotfix1 = Label.new()
	_structured_collaborator_status_v01533_hotfix1.name = "StructuredBuilderCollaboratorStatusV01533Hotfix1"
	_structured_collaborator_status_v01533_hotfix1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_structured_collaborator_status_v01533_hotfix1.modulate = Color(0.72, 0.76, 0.86)
	parent.add_child(_structured_collaborator_status_v01533_hotfix1)
	parent.move_child(_structured_collaborator_status_v01533_hotfix1, actions.get_index() + 1)


func _develop_structured_in_collaborator_v01533_hotfix1() -> void:
	var ingredients: Array = []
	for raw_field in _options.get("fields", []):
		if not raw_field is Dictionary:
			continue
		var field: Dictionary = raw_field
		var field_id := str(field.get("id", ""))
		var control_value: Variant = _field_controls.get(field_id, {})
		if not control_value is Dictionary:
			continue
		var control: Dictionary = control_value
		var edit := control.get("edit") as LineEdit
		if edit == null:
			continue
		var value := edit.text.strip_edges()
		if value.is_empty():
			continue
		ingredients.append({
			"id": field_id,
			"label": str(field.get("label", field_id)),
			"value": value,
			"multi_select": bool(field.get("multi_select", false))
		})
	var extra := ""
	if _custom_instructions != null:
		extra = _custom_instructions.text.strip_edges()
	var source := SOURCE_SERVICE_V01533_HOTFIX1.from_structured_builder(
		ingredients,
		extra,
		{"options_format_version": int(_options.get("format_version", 0))}
	)
	if source.is_empty():
		if _structured_collaborator_status_v01533_hotfix1 != null:
			_structured_collaborator_status_v01533_hotfix1.text = (
				"Choose or enter at least one Structured Builder ingredient, or add custom instructions, before developing it in Collaborator."
			)
		return
	if _structured_collaborator_status_v01533_hotfix1 != null:
		_structured_collaborator_status_v01533_hotfix1.text = "Opening Character Collaborator from the current Structured Builder ingredients…"
	collaborator_source_requested.emit(source)


func _find_button_by_text_v01533_hotfix1(root: Node, button_text: String) -> Button:
	if root is Button and (root as Button).text == button_text:
		return root as Button
	for child in root.get_children():
		if not child is Node:
			continue
		var found := _find_button_by_text_v01533_hotfix1(child as Node, button_text)
		if found != null:
			return found
	return null
