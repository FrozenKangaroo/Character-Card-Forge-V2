class_name CCFWorkspaceV01411View
extends "res://scripts/ui/workspace_v01410.gd"

const CONCEPT_STUDIO = preload("res://scripts/ui/concept_studio_window_v01411.gd")

var _concept_studio: CCFConceptStudioWindowV01411


func _ready() -> void:
	super._ready()
	_build_concept_studio()
	_add_concept_studio_route()


func _build_concept_studio() -> void:
	_concept_studio = CONCEPT_STUDIO.new()
	_concept_studio.visible = false
	_concept_studio.concept_selected.connect(_on_structured_concept_selected)
	_concept_studio.open_ai_ideas_requested.connect(_open_existing_ai_idea_generator)
	add_child(_concept_studio)
	_concept_studio.hide()


func _add_concept_studio_route() -> void:
	for node in find_children("*", "MenuButton", true, false):
		if node is MenuButton and node.text == "Author":
			var popup := node.get_popup()
			var route_id := 1411
			popup.add_separator()
			popup.add_item("Concept Studio — AI Ideas + Structured Builder", route_id)
			popup.id_pressed.connect(func(id: int) -> void:
				if id == route_id:
					_open_concept_studio()
			)
			return


func _open_concept_studio() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		_status.text = "Open a character before creating a concept."
		return
	_concept_studio.open_studio()
	_status.text = "Concept Studio opened."


func _open_existing_ai_idea_generator() -> void:
	var button := _find_workspace_button("Idea Generator")
	if button == null:
		_status.text = "The existing AI Idea Generator could not be opened."
		return
	button.pressed.emit()


func _on_structured_concept_selected(concept_text: String) -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	var active_character := CCFStorageService.get_character(_project_container, _active_character_id)
	if active_character.is_empty():
		return
	var concept_value: Variant = active_character.get("concept", {})
	var concept: Dictionary = concept_value.duplicate(true) if concept_value is Dictionary else {}
	concept["prompt"] = concept_text
	active_character["concept"] = concept
	CCFStorageService.update_character(_project_container, active_character)
	_project = CCFStorageService.character_workspace_document(_project_container, _active_character_id)
	_dirty = true
	_rebuild_form()
	_update_header()
	_status.text = "Structured ingredients applied to Main Concept. Review or edit it before generating the character."


func _close_tool_windows_for_project_change() -> void:
	if _concept_studio != null and _concept_studio.visible:
		_concept_studio.hide()
	super._close_tool_windows_for_project_change()
