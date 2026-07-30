class_name CCFImageGenerationControllerV0133
extends CCFImageGenerationController

const IMAGE_PROMPT_SERVICE_V0139 = preload("res://scripts/services/image_prompt_service_v0139.gd")
const IMAGE_PROMPT_GENERATION_SERVICE_V01312 = preload("res://scripts/services/image_prompt_generation_service_v01312.gd")

var _prompt_character_scope := ""
var _prompt_generation_service: CCFGenerationService
var _prompt_generation_job_id := ""
var _ai_prompt_button: Button
var _local_prompt_button: Button


func _ready() -> void:
	super._ready()
	_install_prompt_generation_service()
	_enable_prompt_wrapping()
	_upgrade_prompt_actions()
	_relocate_generation_actions()


func _install_prompt_generation_service() -> void:
	_prompt_generation_service = IMAGE_PROMPT_GENERATION_SERVICE_V01312.new()
	add_child(_prompt_generation_service)
	_prompt_generation_service.job_completed.connect(_on_prompt_job_completed)
	_prompt_generation_service.job_failed.connect(_on_prompt_job_failed)
	_prompt_generation_service.job_cancelled.connect(_on_prompt_job_cancelled)


func _upgrade_prompt_actions() -> void:
	for node in find_children("*", "Button", true, false):
		if node is Button and node.text == "Build Prompt from Character":
			_ai_prompt_button = node
			break
	if _ai_prompt_button == null:
		return
	_ai_prompt_button.text = "Generate Prompt from Character"
	_ai_prompt_button.tooltip_text = "Use the configured Character AI Text role to write a purpose-built image prompt from the selected character."
	_local_prompt_button = Button.new()
	_local_prompt_button.text = "Build Local Fallback"
	_local_prompt_button.tooltip_text = "Build a prompt locally from visual anchors without calling a text model."
	_local_prompt_button.pressed.connect(_build_local_prompt_from_character)
	var parent := _ai_prompt_button.get_parent()
	if parent != null:
		parent.add_child(_local_prompt_button)
		parent.move_child(_local_prompt_button, _ai_prompt_button.get_index() + 1)
	if _prompt_edit != null:
		_prompt_edit.placeholder_text = "Generate an AI-authored prompt from the selected character, then edit it freely."


func _build_prompt_from_character() -> void:
	if _prompt_edit == null:
		return
	if _prompt_generation_service != null and _prompt_generation_service.has_active_job():
		_prompt_generation_service.cancel_active_job()
		return
	_prepare_character_prompt_scope()
	_prompt_edit.text = ""
	if _project.is_empty() or _active_character_id.is_empty():
		_status.text = "Select a saved character before generating an image prompt. Previous character prompt text has been cleared."
		return
	var resolved_style := _resolved_prompt_style()
	var text_profile := CCFSettingsService.profile_for_role(
		_settings, CCFSettingsService.ROLE_TEXT
	)
	var generation_settings: Dictionary = _settings.get("generation", {})
	var retry_count := int(generation_settings.get("retry_count", 1))
	var result: Dictionary = _prompt_generation_service.queue_image_prompt(
		_project,
		_active_character_id,
		text_profile,
		resolved_style,
		_extra_direction_edit.text,
		retry_count
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not queue image-prompt generation."))
		return
	_prompt_generation_job_id = str(result.get("job_id", ""))
	if _ai_prompt_button != null:
		_ai_prompt_button.text = "Cancel Prompt Generation"
	_status.text = "Generating a purpose-built %s image prompt with the Character AI Text role…" % (
		"Stable Diffusion-style" if resolved_style == "stable_diffusion" else "natural-language"
	)


func _build_local_prompt_from_character() -> void:
	if _prompt_edit == null:
		return
	_prepare_character_prompt_scope()
	_prompt_edit.text = ""
	if _project.is_empty() or _active_character_id.is_empty():
		_status.text = "Select a saved character before building a local image prompt."
		return
	var resolved_style := _resolved_prompt_style()
	var prompt: String = IMAGE_PROMPT_SERVICE_V0139.build_prompt(
		_project,
		_active_character_id,
		resolved_style,
		_extra_direction_edit.text
	)
	_prompt_edit.text = prompt
	if prompt.is_empty():
		_status.text = "Not enough visual character information to build the local fallback prompt. Add a physical Description or enter visual direction manually."
	else:
		_status.text = "Built the local fallback prompt from stable visual anchors. The normal Generate Prompt action uses the Character AI Text role instead."


func _resolved_prompt_style() -> String:
	var resolved_style := _selected_prompt_style()
	if resolved_style == "auto":
		var backend := CCFImageGenerationService.backend_for_profile(_selected_profile())
		resolved_style = (
			"stable_diffusion"
			if backend == CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111
			else "natural"
		)
	return resolved_style


func _on_prompt_job_completed(
	job_id: String,
	job_type: String,
	data: Variant,
	metadata: Dictionary
) -> void:
	if job_type != "image_prompt" or job_id != _prompt_generation_job_id:
		return
	_reset_prompt_generation_ui()
	if str(metadata.get("character_id", "")) != _active_character_id:
		_status.text = "Image prompt finished after the active character changed, so it was not applied."
		return
	if not data is Dictionary:
		_status.text = "The Text role returned image-prompt data in an unexpected shape."
		return
	var generated_prompt := str(data.get("prompt", "")).strip_edges()
	if generated_prompt.is_empty():
		_status.text = "The Text role returned an empty image prompt."
		return
	_prompt_edit.text = generated_prompt
	var negative_prompt := str(data.get("negative_prompt", "")).strip_edges()
	if not negative_prompt.is_empty():
		_negative_prompt_edit.text = negative_prompt
	_status.text = "Generated a purpose-built image prompt with the Character AI Text role. Review or edit it before generating the image."


func _on_prompt_job_failed(job_id: String, job_type: String, message: String) -> void:
	if job_type != "image_prompt" or job_id != _prompt_generation_job_id:
		return
	_reset_prompt_generation_ui()
	_status.text = "Image-prompt generation failed: %s" % message


func _on_prompt_job_cancelled(job_id: String, job_type: String) -> void:
	if job_type != "image_prompt" or job_id != _prompt_generation_job_id:
		return
	_reset_prompt_generation_ui()
	_status.text = "Image-prompt generation cancelled."


func _reset_prompt_generation_ui() -> void:
	_prompt_generation_job_id = ""
	if _ai_prompt_button != null:
		_ai_prompt_button.text = "Generate Prompt from Character"


func _prepare_character_prompt_scope() -> void:
	var project_id := str(_project.get("project_id", "")).strip_edges()
	var scope_key := "%s::%s" % [project_id, _active_character_id]
	if scope_key == _prompt_character_scope:
		return
	if _prompt_generation_service != null and _prompt_generation_service.has_active_job():
		_prompt_generation_service.cancel_active_job()
	_prompt_character_scope = scope_key
	if _prompt_edit != null:
		_prompt_edit.text = ""
	if _negative_prompt_edit != null:
		_negative_prompt_edit.text = ""
	if _extra_direction_edit != null:
		_extra_direction_edit.text = ""


func _enable_prompt_wrapping() -> void:
	for editor in [_extra_direction_edit, _prompt_edit, _negative_prompt_edit]:
		if editor is TextEdit:
			(editor as TextEdit).wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY


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
