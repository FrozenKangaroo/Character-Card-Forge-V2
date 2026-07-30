class_name CCFWorkspaceV014View
extends CCFWorkspaceV01311View

const BUILDER_WINDOW_V014 = preload("res://scripts/ui/character_builder_window_v014.gd")


func _build_character_builder_window() -> void:
	_builder_window = BUILDER_WINDOW_V014.new()
	_builder_window.visible = false
	_builder_window.title = "Character Builder — Option-Driven Authoring"
	_builder_window.size = Vector2i(1180, 820)
	_builder_window.min_size = Vector2i(880, 620)
	_builder_window.force_native = true
	_builder_window.transient = true
	_builder_window.exclusive = false
	_builder_window.set_generation_service(_generation_service)
	_builder_window.builder_state_changed.connect(_on_builder_state_changed)
	_builder_window.concept_apply_requested.connect(_on_builder_concept_apply_requested)
	_builder_window.character_apply_requested.connect(_on_builder_character_apply_requested)
	_builder_window.concept_refresh_requested.connect(_refresh_builder_project_context)
	add_child(_builder_window)
	_builder_window.hide()
