class_name CCFIdeaGeneratorWindowV01533
extends "res://scripts/ui/idea_generator_window_v01532_hotfix1.gd"

signal collaborator_source_requested(source: Dictionary)

const SOURCE_SERVICE_V01533 = preload(
	"res://scripts/services/collaborator_source_context_service_v01533.gd"
)
const NOTEBOOK_SERVICE_V01533 = preload(
	"res://scripts/services/idea_notebook_service_v01532.gd"
)

var _develop_generated_button_v01533: Button
var _develop_saved_button_v01533: Button
var _generated_source_dialog_v01533: ConfirmationDialog
var _generated_source_selector_v01533: OptionButton


func _ready() -> void:
	super._ready()
	_install_collaborator_handoffs_v01533()
	_build_generated_source_dialog_v01533()
	_refresh_collaborator_handoff_state_v01533()


func set_last_generated_ideas_v01532(ideas: Array, metadata: Dictionary = {}) -> void:
	super.set_last_generated_ideas_v01532(ideas, metadata)
	_refresh_collaborator_handoff_state_v01533()


func _set_editor_enabled_v01532(enabled: bool) -> void:
	super._set_editor_enabled_v01532(enabled)
	if _develop_saved_button_v01533 != null:
		_develop_saved_button_v01533.disabled = not enabled


func _install_collaborator_handoffs_v01533() -> void:
	var action_row := find_child(
		"IdeaNotebookActionButtonsV01532Hotfix1", true, false
	) as HBoxContainer
	if action_row != null:
		_develop_generated_button_v01533 = Button.new()
		_develop_generated_button_v01533.name = "DevelopGeneratedIdeaV01533"
		_develop_generated_button_v01533.text = "Develop Generated Idea…"
		_develop_generated_button_v01533.tooltip_text = (
			"Choose one idea from the latest completed batch and start a new Character Collaborator conversation from a read-only structured snapshot. This does not save the idea to Idea Notebook."
		)
		_develop_generated_button_v01533.pressed.connect(
			_open_generated_source_dialog_v01533
		)
		action_row.add_child(_develop_generated_button_v01533)
		# Keep the expanding spacer last so the three authoring actions remain grouped.
		var spacers := action_row.find_children("*", "Control", false, false)
		for candidate in spacers:
			if candidate is Control and candidate.size_flags_horizontal == Control.SIZE_EXPAND_FILL:
				action_row.move_child(_develop_generated_button_v01533, candidate.get_index())
				break

	if _use_idea_button_v01532 != null and _use_idea_button_v01532.get_parent() != null:
		var saved_actions := _use_idea_button_v01532.get_parent()
		_develop_saved_button_v01533 = Button.new()
		_develop_saved_button_v01533.name = "DevelopSavedIdeaV01533"
		_develop_saved_button_v01533.text = "Develop in Collaborator"
		_develop_saved_button_v01533.tooltip_text = (
			"Start a new source-aware Character Collaborator conversation from this saved idea. The Notebook entry remains unchanged."
		)
		_develop_saved_button_v01533.pressed.connect(_develop_saved_idea_v01533)
		saved_actions.add_child(_develop_saved_button_v01533)
		saved_actions.move_child(
			_develop_saved_button_v01533,
			_use_idea_button_v01532.get_index()
		)


func _build_generated_source_dialog_v01533() -> void:
	_generated_source_dialog_v01533 = ConfirmationDialog.new()
	_generated_source_dialog_v01533.visible = false
	_generated_source_dialog_v01533.title = "Develop Generated Idea in Collaborator"
	_generated_source_dialog_v01533.ok_button_text = "Develop in Collaborator"
	_generated_source_dialog_v01533.dialog_text = (
		"Choose one idea from the latest completed batch. The idea is passed as a read-only structured source snapshot and is not automatically saved to Idea Notebook."
	)
	_generated_source_dialog_v01533.confirmed.connect(_develop_generated_idea_v01533)
	add_child(_generated_source_dialog_v01533)
	_generated_source_dialog_v01533.hide()

	_generated_source_selector_v01533 = OptionButton.new()
	_generated_source_selector_v01533.custom_minimum_size = Vector2(540, 36)
	_generated_source_dialog_v01533.add_child(_generated_source_selector_v01533)


func _open_generated_source_dialog_v01533() -> void:
	if _last_generated_ideas_v01532.is_empty():
		return
	_generated_source_selector_v01533.clear()
	for index in range(_last_generated_ideas_v01532.size()):
		var raw: Variant = _last_generated_ideas_v01532[index]
		if not raw is Dictionary:
			continue
		var idea: Dictionary = raw
		var title_text := str(idea.get("title", "Untitled idea"))
		var role := str(idea.get("character_role", "")).strip_edges()
		if not role.is_empty():
			title_text += " • %s" % role
		_generated_source_selector_v01533.add_item(title_text)
		_generated_source_selector_v01533.set_item_metadata(
			_generated_source_selector_v01533.item_count - 1, index
		)
	if _generated_source_selector_v01533.item_count <= 0:
		return
	_generated_source_selector_v01533.select(0)
	_generated_source_dialog_v01533.popup_centered(Vector2i(680, 240))


func _develop_generated_idea_v01533() -> void:
	if _generated_source_selector_v01533 == null:
		return
	var selected := _generated_source_selector_v01533.selected
	if selected < 0 or selected >= _generated_source_selector_v01533.item_count:
		return
	var idea_index := int(_generated_source_selector_v01533.get_item_metadata(selected))
	if idea_index < 0 or idea_index >= _last_generated_ideas_v01532.size():
		return
	var raw: Variant = _last_generated_ideas_v01532[idea_index]
	if not raw is Dictionary:
		return
	var source := SOURCE_SERVICE_V01533.from_generated_idea(
		raw as Dictionary, _last_generation_metadata_v01532
	)
	collaborator_source_requested.emit(source)


func _develop_saved_idea_v01533() -> void:
	if _selected_idea_id_v01532.is_empty():
		return
	var loaded := NOTEBOOK_SERVICE_V01533.load_idea(_selected_idea_id_v01532)
	if not bool(loaded.get("ok", false)):
		_status_v01532.text = str(
			loaded.get("error", "Could not load the saved idea for Collaborator.")
		)
		return
	var idea_value: Variant = loaded.get("data", {})
	if not idea_value is Dictionary:
		_status_v01532.text = "The selected Notebook idea is not a valid structured idea."
		return
	var source := SOURCE_SERVICE_V01533.from_saved_idea(idea_value as Dictionary)
	collaborator_source_requested.emit(source)


func _refresh_collaborator_handoff_state_v01533() -> void:
	if _develop_generated_button_v01533 != null:
		_develop_generated_button_v01533.disabled = _last_generated_ideas_v01532.is_empty()
	if _develop_saved_button_v01533 != null:
		_develop_saved_button_v01533.disabled = _selected_idea_id_v01532.is_empty()
