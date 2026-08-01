class_name CCFWorkspaceV01412View
extends "res://scripts/ui/workspace_v01411.gd"

const IDEA_GENERATOR_V01412 = preload("res://scripts/ui/idea_generator_window_v01412.gd")

var _idea_generator_v01412: CCFIdeaGeneratorWindowV01412
var _legacy_ai_ideas_attached := false


func _ready() -> void:
	super._ready()
	_route_existing_idea_generator_button()


func _build_concept_studio() -> void:
	_idea_generator_v01412 = IDEA_GENERATOR_V01412.new()
	_idea_generator_v01412.visible = false
	_idea_generator_v01412.concept_selected.connect(_on_structured_concept_selected)
	add_child(_idea_generator_v01412)
	_idea_generator_v01412.hide()
	_concept_studio = _idea_generator_v01412


func _add_concept_studio_route() -> void:
	# v0.14.12 deliberately keeps one Author entry: the existing Idea Generator.
	pass


func _route_existing_idea_generator_button() -> void:
	var button := _find_workspace_button("Idea Generator")
	if button == null:
		_status.text = "Idea Generator button could not be found."
		return
	# Replace the legacy window-opening callback rather than adding a second
	# callback. Keeping both caused the emptied legacy native Window to appear
	# beside the unified Idea Generator after its controls were embedded.
	for connection_value in button.pressed.get_connections():
		if not connection_value is Dictionary:
			continue
		var connection: Dictionary = connection_value
		var callable_value: Variant = connection.get("callable")
		if callable_value is Callable:
			var callback: Callable = callable_value
			if button.pressed.is_connected(callback):
				button.pressed.disconnect(callback)
	button.pressed.connect(_on_unified_idea_generator_pressed)


func _on_unified_idea_generator_pressed() -> void:
	call_deferred("_finish_opening_unified_idea_generator")


func _finish_opening_unified_idea_generator() -> void:
	if not _legacy_ai_ideas_attached:
		var legacy_window := _find_legacy_ai_idea_window()
		if legacy_window != null:
			_idea_generator_v01412.attach_ai_idea_window(legacy_window)
			_legacy_ai_ideas_attached = true
	_idea_generator_v01412.open_generator()
	_status.text = "Idea Generator opened. Choose AI Ideas or Structured Builder."


func _find_legacy_ai_idea_window() -> Window:
	for node in find_children("*", "Window", true, false):
		if not node is Window:
			continue
		var candidate := node as Window
		if candidate == _idea_generator_v01412:
			continue
		if candidate.title == "Idea Generator" or candidate.name.to_lower().contains("idea"):
			return candidate
	return null


func _open_concept_studio() -> void:
	# Retained for compatibility with older callers, but now opens the single Idea Generator.
	_finish_opening_unified_idea_generator()


func _close_tool_windows_for_project_change() -> void:
	if _idea_generator_v01412 != null and _idea_generator_v01412.visible:
		_idea_generator_v01412.hide()
	super._close_tool_windows_for_project_change()
