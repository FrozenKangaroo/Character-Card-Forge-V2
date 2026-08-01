class_name CCFIdeaGeneratorWindowV01412
extends "res://scripts/ui/concept_studio_window_v01411.gd"

var _ai_ideas_host: MarginContainer
var _embedded_ai_window: Window


func _ready() -> void:
	super._ready()
	title = "Idea Generator"
	for node in find_children("*", "Label", true, false):
		if node is Label and node.text == "Concept Studio":
			node.text = "Idea Generator"
		elif node is Label and node.text.begins_with("Use V2 AI Ideas"):
			node.text = "Generate several prompt-driven ideas or build one Main Concept from configurable structured ingredients."


func _build_ai_tab() -> void:
	var tab := VBoxContainer.new()
	tab.name = "AI Ideas"
	tab.add_theme_constant_override("separation", 8)
	_tabs.add_child(tab)
	var description := Label.new()
	description.text = "Enter a theme, fragments, or constraints, choose how many ideas to generate, then select Use This Idea."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tab.add_child(description)
	_ai_ideas_host = MarginContainer.new()
	_ai_ideas_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ai_ideas_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab.add_child(_ai_ideas_host)
	var waiting := Label.new()
	waiting.name = "WaitingForAIIdeas"
	waiting.text = "Loading AI Ideas…"
	waiting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	waiting.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	waiting.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ai_ideas_host.add_child(waiting)


func attach_ai_idea_window(legacy_window: Window) -> void:
	if legacy_window == null or legacy_window == self:
		return
	_embedded_ai_window = legacy_window
	legacy_window.hide()
	for child in _ai_ideas_host.get_children():
		child.queue_free()
	for child in legacy_window.get_children():
		if not child is Control:
			continue
		var control := child as Control
		control.reparent(_ai_ideas_host)
		control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	legacy_window.close_requested.connect(_on_embedded_ai_close_requested)


func open_generator() -> void:
	open_studio()
	_tabs.current_tab = 0


func _on_embedded_ai_close_requested() -> void:
	hide()
