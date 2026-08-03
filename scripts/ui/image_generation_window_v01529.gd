class_name CCFImageGenerationWindowV01529
extends "res://scripts/ui/image_generation_window_v01528.gd"

const IMAGE_PROMPT_GENERATION_SERVICE_V01529 = preload(
	"res://scripts/services/image_prompt_generation_service_v01529.gd"
)

var _prompt_generation_service_v01529: CCFImagePromptGenerationServiceV01529
var _prompt_generation_job_id_v01529 := ""
var _prompt_character_scope_v01529 := ""
var _ai_prompt_button_v01529: Button
var _local_prompt_button_v01529: Button


func _ready() -> void:
	super._ready()
	_install_prompt_generation_service_v01529()
	_upgrade_prompt_actions_v01529()


func open_studio() -> void:
	# Image Studio is a main-navigation page. Keep this compatibility entry point
	# refresh-only so an inherited caller can never turn it back into a popup.
	_reload_settings()
	_refresh_profiles()
	_refresh_projects()


func set_scheduler_v01526(scheduler: CCFAIJobSchedulerV01526) -> void:
	super.set_scheduler_v01526(scheduler)
	if _prompt_generation_service_v01529 != null:
		_prompt_generation_service_v01529.configure_scheduler_v01526(
			scheduler,
			"image_prompt_%d" % get_instance_id(),
			"Image prompt generation"
		)


func _install_prompt_generation_service_v01529() -> void:
	if _prompt_generation_service_v01529 != null:
		return
	_prompt_generation_service_v01529 = IMAGE_PROMPT_GENERATION_SERVICE_V01529.new()
	add_child(_prompt_generation_service_v01529)
	_prompt_generation_service_v01529.job_completed.connect(
		_on_prompt_job_completed_v01529
	)
	_prompt_generation_service_v01529.job_failed.connect(
		_on_prompt_job_failed_v01529
	)
	_prompt_generation_service_v01529.job_cancelled.connect(
		_on_prompt_job_cancelled_v01529
	)
	var scheduler := scheduler_v01526()
	if scheduler != null:
		_prompt_generation_service_v01529.configure_scheduler_v01526(
			scheduler,
			"image_prompt_%d" % get_instance_id(),
			"Image prompt generation"
		)


func _upgrade_prompt_actions_v01529() -> void:
	for node in find_children("*", "Button", true, false):
		if node is Button and node.text == "Build Prompt from Character":
			_ai_prompt_button_v01529 = node as Button
			break
	if _ai_prompt_button_v01529 == null:
		return
	if _ai_prompt_button_v01529.pressed.is_connected(_build_prompt_from_character):
		_ai_prompt_button_v01529.pressed.disconnect(_build_prompt_from_character)
	if not _ai_prompt_button_v01529.pressed.is_connected(
		_generate_prompt_from_character_v01529
	):
		_ai_prompt_button_v01529.pressed.connect(
			_generate_prompt_from_character_v01529
		)
	_ai_prompt_button_v01529.text = "Generate Prompt from Character"
	_ai_prompt_button_v01529.tooltip_text = (
		"Use the configured Character AI Text role to write a purpose-built image prompt from the selected character."
	)

	_local_prompt_button_v01529 = Button.new()
	_local_prompt_button_v01529.text = "Build Local Fallback"
	_local_prompt_button_v01529.tooltip_text = (
		"Build a deterministic prompt from visual character anchors without calling the Text model."
	)
	_local_prompt_button_v01529.pressed.connect(
		_build_local_prompt_from_character_v01529
	)
	var parent := _ai_prompt_button_v01529.get_parent()
	if parent != null:
		parent.add_child(_local_prompt_button_v01529)
		parent.move_child(
			_local_prompt_button_v01529,
			_ai_prompt_button_v01529.get_index() + 1
		)
	if _prompt_edit != null:
		_prompt_edit.placeholder_text = (
			"Generate an AI-authored prompt from the selected character, then edit it freely."
		)


func _build_prompt_from_character() -> void:
	# Base Image Studio calls this hook during project/character refresh. It must
	# remain passive: browsing characters never spends Text-provider tokens.
	_prepare_character_prompt_scope_v01529()


func _generate_prompt_from_character_v01529() -> void:
	if _prompt_edit == null or _status == null:
		return
	if _prompt_generation_service_v01529 == null:
		_install_prompt_generation_service_v01529()
	if _prompt_generation_service_v01529 == null:
		_status.text = "Image-prompt generation service is unavailable."
		return
	if _prompt_generation_service_v01529.has_active_job():
		_prompt_generation_service_v01529.cancel_active_job()
		return

	_prepare_character_prompt_scope_v01529()
	_prompt_edit.text = ""
	if _project.is_empty():
		_status.text = "Generate Prompt could not run because no saved project is selected."
		return
	if _active_character_id.is_empty():
		_status.text = "Generate Prompt could not run because the selected project has no active character."
		return
	var character := CCFStorageService.get_character(_project, _active_character_id)
	if character.is_empty():
		_status.text = "Generate Prompt could not run because the selected character is no longer present in the project."
		return

	var resolved_style := _resolved_prompt_style_v01529()
	var text_profile := CCFSettingsService.profile_for_role(
		_settings, CCFSettingsService.ROLE_TEXT
	)
	var generation_settings: Dictionary = _settings.get("generation", {})
	var retry_count := int(generation_settings.get("retry_count", 1))
	var result := _prompt_generation_service_v01529.queue_image_prompt(
		_project,
		_active_character_id,
		text_profile,
		resolved_style,
		_extra_direction_edit.text,
		retry_count
	)
	if not bool(result.get("ok", false)):
		_status.text = str(
			result.get("error", "Could not queue image-prompt generation.")
		)
		return
	_prompt_generation_job_id_v01529 = str(result.get("job_id", ""))
	if _ai_prompt_button_v01529 != null:
		_ai_prompt_button_v01529.text = "Cancel Prompt Generation"
	_status.text = (
		"Generating a purpose-built %s image prompt with the Character AI Text role…"
		% (
			"Stable Diffusion-style"
			if resolved_style == "stable_diffusion"
			else "natural-language"
		)
	)


func _build_local_prompt_from_character_v01529() -> void:
	if _prompt_edit == null or _status == null:
		return
	_prepare_character_prompt_scope_v01529()
	_prompt_edit.text = ""
	if _project.is_empty() or _active_character_id.is_empty():
		_status.text = "Select a saved project and character before building a local fallback prompt."
		return
	var prompt := CCFImageGenerationService.build_prompt(
		_project,
		_active_character_id,
		_resolved_prompt_style_v01529(),
		_extra_direction_edit.text
	)
	_prompt_edit.text = prompt
	if prompt.strip_edges().is_empty():
		_status.text = "The local fallback found no usable visual character information."
	else:
		_status.text = (
			"Built the deterministic local fallback. Generate Prompt from Character uses the configured Character AI Text role instead."
		)


func _resolved_prompt_style_v01529() -> String:
	var resolved_style := _selected_prompt_style()
	if resolved_style == "auto":
		var backend := CCFImageGenerationService.backend_for_profile(_selected_profile())
		resolved_style = (
			"stable_diffusion"
			if backend == CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111
			else "natural"
		)
	return resolved_style


func _on_prompt_job_completed_v01529(
	job_id: String,
	job_type: String,
	data: Variant,
	metadata: Dictionary
) -> void:
	if job_type != "image_prompt" or job_id != _prompt_generation_job_id_v01529:
		return
	_reset_prompt_generation_ui_v01529()
	if str(metadata.get("character_id", "")) != _active_character_id:
		_status.text = "Image prompt finished after the active character changed, so it was not applied."
		return
	if not data is Dictionary:
		_status.text = "The Character AI Text role returned image-prompt data in an unexpected shape."
		return
	var generated_prompt := str(data.get("prompt", "")).strip_edges()
	if generated_prompt.is_empty():
		_status.text = "The Character AI Text role returned an empty image prompt."
		return
	_prompt_edit.text = generated_prompt
	var negative_prompt := str(data.get("negative_prompt", "")).strip_edges()
	if not negative_prompt.is_empty():
		_negative_prompt_edit.text = negative_prompt
	_status.text = (
		"Generated a purpose-built image prompt with the Character AI Text role. Review or edit it before generating the image."
	)


func _on_prompt_job_failed_v01529(
	job_id: String, job_type: String, message_text: String
) -> void:
	if job_type != "image_prompt" or job_id != _prompt_generation_job_id_v01529:
		return
	_reset_prompt_generation_ui_v01529()
	_status.text = "Image-prompt generation failed: %s" % message_text


func _on_prompt_job_cancelled_v01529(job_id: String, job_type: String) -> void:
	if job_type != "image_prompt" or job_id != _prompt_generation_job_id_v01529:
		return
	_reset_prompt_generation_ui_v01529()
	_status.text = "Image-prompt generation cancelled."


func _reset_prompt_generation_ui_v01529() -> void:
	_prompt_generation_job_id_v01529 = ""
	if _ai_prompt_button_v01529 != null:
		_ai_prompt_button_v01529.text = "Generate Prompt from Character"


func _prepare_character_prompt_scope_v01529() -> void:
	var project_id := str(_project.get("project_id", "")).strip_edges()
	var scope_key := "%s::%s" % [project_id, _active_character_id]
	if scope_key == _prompt_character_scope_v01529:
		return
	if (
		_prompt_generation_service_v01529 != null
		and _prompt_generation_service_v01529.has_active_job()
	):
		_prompt_generation_service_v01529.cancel_active_job()
	_prompt_character_scope_v01529 = scope_key
	if _prompt_edit != null:
		_prompt_edit.text = ""
	if _negative_prompt_edit != null:
		_negative_prompt_edit.text = ""
	if _extra_direction_edit != null:
		_extra_direction_edit.text = ""
