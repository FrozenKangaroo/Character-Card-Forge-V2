class_name CCFSettingsV01526View
extends "res://scripts/ui/settings_view_v01522.gd"

var _max_total_jobs_v01526: SpinBox
var _max_text_jobs_v01526: SpinBox
var _max_vision_jobs_v01526: SpinBox
var _max_image_jobs_v01526: SpinBox
var _max_sections_v01526: SpinBox
var _parallel_sections_v01526: CheckBox
var _vision_counts_total_v01526: CheckBox
var _image_counts_total_v01526: CheckBox


func _build_character_ai_settings(parent: VBoxContainer) -> void:
	super._build_character_ai_settings(parent)

	var heading := Label.new()
	heading.text = "AI job concurrency"
	heading.add_theme_font_size_override("font_size", 18)
	parent.add_child(heading)

	var explanation := Label.new()
	explanation.text = "Run independent AI work at the same time. Interview/Q&A remains a required barrier for Safe Section Build; eligible sections can then run concurrently and are always assembled in template order. Jobs beyond these limits wait in the queue."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.modulate = Color(0.68, 0.71, 0.8)
	parent.add_child(explanation)

	_max_total_jobs_v01526 = _add_concurrency_spin_v01526(
		parent, "Maximum concurrent counted jobs", 1, 32
	)
	_max_text_jobs_v01526 = _add_concurrency_spin_v01526(
		parent, "Maximum concurrent Text jobs", 1, 32
	)
	_max_vision_jobs_v01526 = _add_concurrency_spin_v01526(
		parent, "Maximum concurrent Vision jobs", 1, 16
	)
	_max_image_jobs_v01526 = _add_concurrency_spin_v01526(
		parent, "Maximum concurrent Image jobs", 1, 16
	)
	_max_sections_v01526 = _add_concurrency_spin_v01526(
		parent, "Maximum concurrent Safe Sections per character", 1, 16
	)

	_parallel_sections_v01526 = CheckBox.new()
	_parallel_sections_v01526.text = "Generate eligible Safe Sections in parallel"
	_parallel_sections_v01526.tooltip_text = "Interview/Q&A completes first. Sections in the same dependency wave use one frozen context snapshot; completion timing cannot change their prompts or final template order."
	parent.add_child(_parallel_sections_v01526)

	_vision_counts_total_v01526 = CheckBox.new()
	_vision_counts_total_v01526.text = "Vision jobs count toward the overall maximum"
	parent.add_child(_vision_counts_total_v01526)

	_image_counts_total_v01526 = CheckBox.new()
	_image_counts_total_v01526.text = "Image jobs count toward the overall maximum"
	parent.add_child(_image_counts_total_v01526)

	var pool_hint := Label.new()
	pool_hint.text = "Disable an overall-count option when that role uses an independent backend, such as cloud Text plus local Vision or Stable Diffusion. Its role-specific maximum still applies. Shared provider/GPU resource pools remain a later refinement."
	pool_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pool_hint.modulate = Color(0.62, 0.66, 0.76)
	parent.add_child(pool_hint)


func load_settings(settings: Dictionary) -> void:
	super.load_settings(settings)
	var generation_value: Variant = _settings.get("generation", {})
	var raw_config: Variant = {}
	if generation_value is Dictionary:
		raw_config = generation_value.get("ai_concurrency", {})
	var config := CCFAIJobSchedulerV01526.normalise_config(raw_config)
	_max_total_jobs_v01526.value = int(config.get("max_total_jobs", 1))
	_max_text_jobs_v01526.value = int(config.get("max_text_jobs", 1))
	_max_vision_jobs_v01526.value = int(config.get("max_vision_jobs", 1))
	_max_image_jobs_v01526.value = int(config.get("max_image_jobs", 1))
	_max_sections_v01526.value = int(config.get("max_sections_per_character", 1))
	_parallel_sections_v01526.button_pressed = bool(
		config.get("parallel_safe_sections", false)
	)
	_vision_counts_total_v01526.button_pressed = bool(
		config.get("vision_counts_toward_total", true)
	)
	_image_counts_total_v01526.button_pressed = bool(
		config.get("image_counts_toward_total", true)
	)


func _save() -> void:
	var generation_settings: Dictionary = _settings.get("generation", {}).duplicate(true)
	generation_settings["ai_concurrency"] = CCFAIJobSchedulerV01526.normalise_config({
		"max_total_jobs": int(_max_total_jobs_v01526.value),
		"max_text_jobs": int(_max_text_jobs_v01526.value),
		"max_vision_jobs": int(_max_vision_jobs_v01526.value),
		"max_image_jobs": int(_max_image_jobs_v01526.value),
		"max_sections_per_character": int(_max_sections_v01526.value),
		"parallel_safe_sections": _parallel_sections_v01526.button_pressed,
		"vision_counts_toward_total": _vision_counts_total_v01526.button_pressed,
		"image_counts_toward_total": _image_counts_total_v01526.button_pressed
	})
	_settings["generation"] = generation_settings
	super._save()


func _add_concurrency_spin_v01526(
	parent: VBoxContainer, label_text: String, minimum: int, maximum: int
) -> SpinBox:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 330
	row.add_child(label)
	var spin := SpinBox.new()
	spin.min_value = minimum
	spin.max_value = maximum
	spin.step = 1
	spin.allow_greater = false
	spin.custom_minimum_size.x = 120
	row.add_child(spin)
	return spin
