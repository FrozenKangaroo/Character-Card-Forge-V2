class_name CCFCharacterCollaboratorWindowV01537Sources
extends "res://scripts/ui/character_collaborator_window_v01537.gd"

const IDEA_NOTEBOOK_SERVICE_V01532 = preload(
	"res://scripts/services/idea_notebook_service_v01532.gd"
)

var _idea_source_dialog_v01537: ConfirmationDialog
var _idea_source_list_v01537: ItemList
var _idea_source_rows_v01537: Array[Dictionary] = []


func _ready() -> void:
	super._ready()
	_install_saved_idea_source_button_v01537()
	_build_idea_source_dialog_v01537()


func _install_saved_idea_source_button_v01537() -> void:
	if _source_panel_v01533 == null:
		return
	var actions: HFlowContainer = null
	for child in _source_panel_v01533.get_children():
		if child is HFlowContainer and child.name == "CollaboratorMultiSourceActionsV01537":
			actions = child as HFlowContainer
			break
	if actions == null:
		return
	var button := Button.new()
	button.text = "Add Saved Idea…"
	button.tooltip_text = "Add an Idea Notebook entry to this conversation as another read-only reference source."
	button.pressed.connect(_open_idea_source_dialog_v01537)
	actions.add_child(button)


func _build_idea_source_dialog_v01537() -> void:
	_idea_source_dialog_v01537 = ConfirmationDialog.new()
	_idea_source_dialog_v01537.visible = false
	_idea_source_dialog_v01537.title = "Add Saved Idea as Collaborator Source"
	_idea_source_dialog_v01537.min_size = Vector2i(760, 560)
	_idea_source_dialog_v01537.confirmed.connect(_confirm_idea_source_v01537)
	add_child(_idea_source_dialog_v01537)
	var root := VBoxContainer.new()
	_idea_source_dialog_v01537.add_child(root)
	var hint := Label.new()
	hint.text = "Choose a saved Idea Notebook entry. It remains a read-only reference and does not replace the explicit character target."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(hint)
	_idea_source_list_v01537 = ItemList.new()
	_idea_source_list_v01537.custom_minimum_size = Vector2(700, 430)
	root.add_child(_idea_source_list_v01537)
	_idea_source_dialog_v01537.hide()


func _open_idea_source_dialog_v01537() -> void:
	_idea_source_rows_v01537 = IDEA_NOTEBOOK_SERVICE_V01532.list_ideas()
	_idea_source_list_v01537.clear()
	for idea in _idea_source_rows_v01537:
		var title := str(idea.get("title", "Untitled idea"))
		var character_name := str(idea.get("character_name", "")).strip_edges()
		var display := title
		if not character_name.is_empty():
			display += " — %s" % character_name
		_idea_source_list_v01537.add_item(display)
	if _idea_source_rows_v01537.is_empty():
		_status.text = "Idea Notebook has no saved ideas to add."
		return
	_idea_source_list_v01537.select(0)
	_idea_source_dialog_v01537.popup_centered(Vector2i(780, 580))


func _confirm_idea_source_v01537() -> void:
	var selected := _idea_source_list_v01537.get_selected_items()
	if selected.is_empty():
		return
	var index := int(selected[0])
	if index < 0 or index >= _idea_source_rows_v01537.size():
		return
	var source := SOURCE_SERVICE_V01537.from_saved_idea(
		_idea_source_rows_v01537[index]
	)
	var result := add_source_v01537(source, false)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not add the saved Idea source."))


func collaborator_source_capabilities_v01533() -> Dictionary:
	var result := super.collaborator_source_capabilities_v01533()
	result["saved_idea_picker"] = true
	return result
