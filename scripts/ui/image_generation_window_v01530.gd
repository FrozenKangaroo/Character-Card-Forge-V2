class_name CCFImageGenerationWindowV01530
extends "res://scripts/ui/image_generation_window_v01529.gd"


func _ready() -> void:
	super._ready()
	_apply_prompt_word_wrap_v01530()


func _apply_prompt_word_wrap_v01530() -> void:
	for editor in [_prompt_edit, _negative_prompt_edit]:
		if editor == null:
			continue
		editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		editor.scroll_horizontal = 0
