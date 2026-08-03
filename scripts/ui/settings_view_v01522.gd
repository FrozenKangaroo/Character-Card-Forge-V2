class_name CCFSettingsV01522View
extends CCFSettingsView

const STRATEGY_SAFE_SECTION := "safe_section"
const STRATEGY_FAST_FULL := "fast_full"

var _generation_strategy_v01522: OptionButton


func _build_character_ai_settings(parent: VBoxContainer) -> void:
	super._build_character_ai_settings(parent)

	var heading := Label.new()
	heading.text = "Generation strategy"
	heading.add_theme_font_size_override("font_size", 18)
	parent.add_child(heading)

	var explanation := Label.new()
	explanation.text = "This is separate from Generation Mode / Style. It controls how Character Card Forge divides a Generate Character job into provider requests."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.modulate = Color(0.68, 0.71, 0.8)
	parent.add_child(explanation)

	_generation_strategy_v01522 = OptionButton.new()
	_generation_strategy_v01522.add_item("Safe Section Build — Recommended")
	_generation_strategy_v01522.set_item_metadata(0, STRATEGY_SAFE_SECTION)
	_generation_strategy_v01522.add_item("Fast Full Card — Faster / fewer requests")
	_generation_strategy_v01522.set_item_metadata(1, STRATEGY_FAST_FULL)
	_generation_strategy_v01522.tooltip_text = "Safe Section Build uses a fresh request for each enabled Generation Output Group and standalone generatable field. Fast Full Card uses one main request and is more prone to incomplete initial output."
	parent.add_child(_generation_strategy_v01522)

	var safe_hint := Label.new()
	safe_hint.text = "Safe Section Build is the default. Each Output Group is generated and validated as one section; standalone fields such as Scenario and First Message are separate sections. Missing required Generation Components are repaired individually. Fast Full Card keeps the existing one-request synthesis path for lower latency and fewer API calls, with a higher risk of omissions."
	safe_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	safe_hint.modulate = Color(0.62, 0.66, 0.76)
	parent.add_child(safe_hint)


func load_settings(settings: Dictionary) -> void:
	super.load_settings(settings)
	if _generation_strategy_v01522 == null:
		return
	var generation_value: Variant = _settings.get("generation", {})
	var strategy := STRATEGY_SAFE_SECTION
	if generation_value is Dictionary:
		strategy = str(generation_value.get("generation_strategy", STRATEGY_SAFE_SECTION))
	if strategy != STRATEGY_FAST_FULL:
		strategy = STRATEGY_SAFE_SECTION
	for index in range(_generation_strategy_v01522.item_count):
		if str(_generation_strategy_v01522.get_item_metadata(index)) == strategy:
			_generation_strategy_v01522.select(index)
			break


func _save() -> void:
	var generation_settings: Dictionary = _settings.get("generation", {}).duplicate(true)
	var strategy := STRATEGY_SAFE_SECTION
	if _generation_strategy_v01522 != null and _generation_strategy_v01522.selected >= 0:
		strategy = str(_generation_strategy_v01522.get_selected_metadata())
	if strategy != STRATEGY_FAST_FULL:
		strategy = STRATEGY_SAFE_SECTION
	generation_settings["generation_strategy"] = strategy
	_settings["generation"] = generation_settings
	super._save()
