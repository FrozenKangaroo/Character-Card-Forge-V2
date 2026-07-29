class_name CCFImageGenerationControllerV0133
extends CCFImageGenerationController

var _prompt_character_scope := ""


func _ready() -> void:
	super._ready()
	_relocate_generation_actions()


func _build_prompt_from_character() -> void:
	if _prompt_edit == null:
		return
	_prepare_character_prompt_scope()
	# Never leave a previous character's prompt visible when the newly selected
	# character cannot produce one. The prompt is rebuilt from the current scope
	# below or remains deliberately blank.
	_prompt_edit.text = ""
	if _project.is_empty() or _active_character_id.is_empty():
		if _status != null:
			_status.text = "Select a saved character before building an image prompt. Previous character prompt text has been cleared."
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


func _prepare_character_prompt_scope() -> void:
	var project_id := str(_project.get("project_id", "")).strip_edges()
	var scope_key := "%s::%s" % [project_id, _active_character_id]
	if scope_key == _prompt_character_scope:
		return
	_prompt_character_scope = scope_key
	# Prompt-authoring controls are character-specific working state. A new
	# character must start clean instead of inheriting the previous character's
	# manually edited/generated prompt, negative prompt, or extra direction.
	if _prompt_edit != null:
		_prompt_edit.text = ""
	if _negative_prompt_edit != null:
		_negative_prompt_edit.text = ""
	if _extra_direction_edit != null:
		_extra_direction_edit.text = ""


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
