class_name CCFImageGenerationControllerV0133
extends CCFImageGenerationController


func _ready() -> void:
	super._ready()
	_relocate_generation_actions()


func _build_prompt_from_character() -> void:
	if _project.is_empty() or _active_character_id.is_empty() or _prompt_edit == null:
		return
	var resolved_style := _selected_prompt_style()
	if resolved_style == "auto":
		var backend := CCFImageGenerationService.backend_for_profile(_selected_profile())
		resolved_style = (
			"stable_diffusion"
			if backend == CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111
			else "natural"
		)
	var prompt := CCFImagePromptService.build_prompt(
		_project,
		_active_character_id,
		resolved_style,
		_extra_direction_edit.text
	)
	_prompt_edit.text = prompt
	if prompt.is_empty():
		_status.text = "Not enough visual character information to build an image prompt. Add a physical Description or enter visual direction manually. Raw Generation Concept text is no longer used as an image-prompt fallback."
	elif resolved_style == "stable_diffusion":
		_status.text = "Built a Stable Diffusion tag-style prompt from physical Description plus visually detectable Scenario setting/time/lighting."
	else:
		_status.text = "Built a natural-language image prompt from physical Description plus visually detectable Scenario setting/time/lighting."


func _relocate_generation_actions() -> void:
	if _generate_button == null or _cancel_button == null or _prompt_style_selector == null:
		return
	var old_parent := _generate_button.get_parent()
	var option_parent := _prompt_style_selector.get_parent()
	if option_parent == null:
		return
	_generate_button.reparent(option_parent)
	_cancel_button.reparent(option_parent)
	_generate_button.tooltip_text = "Generate using the prompt below. This action stays in the upper control row so it cannot be pushed below the visible workspace."
	if old_parent != null and old_parent.get_child_count() == 0:
		old_parent.queue_free()
