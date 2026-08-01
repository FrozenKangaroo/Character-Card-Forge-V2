class_name CCFWorkspaceV01414View
extends "res://scripts/ui/workspace_v01413.gd"

const BUILDER_WINDOW_V01414 = preload("res://scripts/ui/character_builder_window_v01414.gd")


func _build_character_builder_window() -> void:
	_builder_window = BUILDER_WINDOW_V01414.new()
	_builder_window.visible = false
	_builder_window.title = "Character Builder — Full Character + Focused Builders"
	_builder_window.size = Vector2i(1280, 860)
	_builder_window.min_size = Vector2i(980, 680)
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
