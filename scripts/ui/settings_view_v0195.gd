class_name CCFSettingsV0195View
extends "res://scripts/ui/settings_view_v0180_hotfix2.gd"

var _fast_text_role_selector_v0195: OptionButton
var _deep_text_role_selector_v0195: OptionButton
var _fallback_text_role_selector_v0195: OptionButton
var _text_fallback_enabled_v0195: CheckBox


func _build_character_ai_settings(parent: VBoxContainer) -> void:
	super._build_character_ai_settings(parent)

	var heading := Label.new()
	heading.text = "Task-specific Text routing"
	heading.add_theme_font_size_override("font_size", 19)
	parent.add_child(heading)

	var explanation := Label.new()
	explanation.text = (
		"Primary Text remains the default for every task. Optional assignments let "
		+ "quick single-field suggestions and deep AI Review use different profiles "
		+ "without changing Vision or Image Generation."
	)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.modulate = Color(0.68, 0.72, 0.82)
	parent.add_child(explanation)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	parent.add_child(grid)

	_fast_text_role_selector_v0195 = _add_text_route_selector_v0195(
		grid,
		"Fast / Suggestion Text",
		CCFSettingsService.ROLE_TEXT_FAST,
		"Used by single-field AI Suggest actions, including individual Front Porch fields."
	)
	_deep_text_role_selector_v0195 = _add_text_route_selector_v0195(
		grid,
		"Deep Review Text",
		CCFSettingsService.ROLE_TEXT_DEEP,
		"Used by the optional full AI Review report."
	)
	_fallback_text_role_selector_v0195 = _add_text_route_selector_v0195(
		grid,
		"Fallback Text",
		CCFSettingsService.ROLE_TEXT_FALLBACK,
		"A single alternate profile for eligible technical failures."
	)

	_text_fallback_enabled_v0195 = CheckBox.new()
	_text_fallback_enabled_v0195.text = (
		"Allow one fallback attempt for network, unavailable endpoint/model, rate-limit or service failures"
	)
	_text_fallback_enabled_v0195.tooltip_text = (
		"Off by default. Invalid content, refusals, parsing failures and validation "
		+ "failures never switch models automatically. A fallback cannot trigger another fallback."
	)
	parent.add_child(_text_fallback_enabled_v0195)

	var safety := Label.new()
	safety.text = (
		"Fallback is used only after normal retries are exhausted, only when enabled, "
		+ "and only when Fallback Text names a different profile. The producing profile "
		+ "and model are retained in result provenance."
	)
	safety.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	safety.modulate = Color(0.62, 0.67, 0.77)
	parent.add_child(safety)

	var save_routing := Button.new()
	save_routing.text = "Save Text Routing Settings"
	save_routing.custom_minimum_size = Vector2(210, 42)
	save_routing.pressed.connect(_save)
	parent.add_child(save_routing)


func load_settings(settings: Dictionary) -> void:
	super.load_settings(settings)
	if _text_fallback_enabled_v0195 != null:
		var generation: Dictionary = _settings.get("generation", {})
		_text_fallback_enabled_v0195.button_pressed = bool(
			generation.get("text_fallback_enabled", false)
		)


func _save() -> void:
	var generation: Dictionary = _settings.get("generation", {}).duplicate(true)
	generation["text_fallback_enabled"] = (
		_text_fallback_enabled_v0195 != null
		and _text_fallback_enabled_v0195.button_pressed
	)
	_settings["generation"] = generation
	super._save()


func _refresh_role_selectors() -> void:
	super._refresh_role_selectors()
	if _fast_text_role_selector_v0195 == null:
		return
	_loading_roles = true
	_populate_optional_text_selector_v0195(
		_fast_text_role_selector_v0195, CCFSettingsService.ROLE_TEXT_FAST
	)
	_populate_optional_text_selector_v0195(
		_deep_text_role_selector_v0195, CCFSettingsService.ROLE_TEXT_DEEP
	)
	_populate_optional_text_selector_v0195(
		_fallback_text_role_selector_v0195, CCFSettingsService.ROLE_TEXT_FALLBACK
	)
	_loading_roles = false


func _capture_role_assignments() -> void:
	super._capture_role_assignments()
	_capture_optional_text_selector_v0195(
		_fast_text_role_selector_v0195, CCFSettingsService.ROLE_TEXT_FAST
	)
	_capture_optional_text_selector_v0195(
		_deep_text_role_selector_v0195, CCFSettingsService.ROLE_TEXT_DEEP
	)
	_capture_optional_text_selector_v0195(
		_fallback_text_role_selector_v0195, CCFSettingsService.ROLE_TEXT_FALLBACK
	)


func _on_image_settings_saved(settings: Dictionary) -> void:
	super._on_image_settings_saved(settings)
	if _text_fallback_enabled_v0195 != null:
		var generation: Dictionary = _settings.get("generation", {})
		_text_fallback_enabled_v0195.button_pressed = bool(
			generation.get("text_fallback_enabled", false)
		)


func _add_text_route_selector_v0195(
	grid: GridContainer, label_text: String, role: String, tooltip: String
) -> OptionButton:
	var label := _label(label_text)
	label.tooltip_text = tooltip
	grid.add_child(label)
	var selector := OptionButton.new()
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.tooltip_text = tooltip
	selector.item_selected.connect(_on_role_selected.bind(role))
	grid.add_child(selector)
	return selector


func _populate_optional_text_selector_v0195(
	selector: OptionButton, role: String
) -> void:
	selector.clear()
	selector.add_item("Use Primary Text (default)")
	selector.set_item_metadata(0, CCFSettingsService.USE_PRIMARY_PROFILE_ID)
	for raw_profile in _settings.get("api_profiles", []):
		if not raw_profile is Dictionary:
			continue
		var profile: Dictionary = raw_profile
		selector.add_item(str(profile.get("name", "Profile")))
		selector.set_item_metadata(
			selector.item_count - 1, str(profile.get("id", "default"))
		)
	_select_profile_id(
		selector, CCFSettingsService.role_profile_id(_settings, role)
	)


func _capture_optional_text_selector_v0195(
	selector: OptionButton, role: String
) -> void:
	if selector == null or selector.selected < 0:
		return
	CCFSettingsService.set_role_profile(
		_settings, role, str(selector.get_selected_metadata())
	)
