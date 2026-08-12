class_name CCFImageGenerationWindowV0164
extends "res://scripts/ui/image_generation_window_v0163.gd"

const CAPABILITY_SERVICE_V0164 = preload(
	"res://scripts/services/image_capability_service_v0164.gd"
)
const IMAGE_SERVICE_V0164 = preload(
	"res://scripts/services/image_generation_service_v0164.gd"
)

var _dynamic_panel_v0164: VBoxContainer
var _dynamic_summary_v0164: Label
var _dynamic_parameters_v0164: VBoxContainer
var _dynamic_parameter_controls_v0164: Dictionary = {}
var _dynamic_parameter_descriptors_v0164: Dictionary = {}
var _dynamic_resolution_v0164: OptionButton
var _refresh_models_button_v0164: Button
var _rebuilding_dynamic_v0164 := false


func _ready() -> void:
	super._ready()
	_install_v0164_services()
	ensure_dynamic_provider_surface_v0164()
	if _model_edit != null and not _model_edit.text_changed.is_connected(_on_dynamic_model_changed_v0164):
		_model_edit.text_changed.connect(_on_dynamic_model_changed_v0164)
	_refresh_dynamic_provider_controls_v0164()


func _build_ui() -> void:
	super._build_ui()
	_install_dynamic_provider_surface_v0164()


func dynamic_provider_capabilities_v0164() -> Dictionary:
	return {
		"version": "0.16.4",
		"preferred_rich_endpoint": CCFImageProviderModelCatalogServiceV0164.PREFERRED_ENDPOINT_SUFFIX,
		"legacy_rich_endpoint_fallback": CCFImageProviderModelCatalogServiceV0164.LEGACY_ENDPOINT_SUFFIX,
		"generic_models_fallback": CCFImageProviderModelCatalogServiceV0164.GENERIC_ENDPOINT_SUFFIX,
		"cached_model_catalog": true,
		"manual_refresh": true,
		"passive_browsing_no_network": true,
		"vanished_model_safe": true,
		"dynamic_resolution_choices": true,
		"dynamic_image_count_constraints": true,
		"dynamic_provider_parameters": true,
		"unknown_additive_parameters_preserved": true,
		"pricing_metadata_preserved": true,
		"provider_parameters_reach_generation_payload": true
	}


func ensure_dynamic_provider_surface_v0164() -> void:
	_install_dynamic_provider_surface_v0164()
	_refresh_dynamic_provider_controls_v0164()


func dynamic_provider_surface_ready_v0164() -> bool:
	return (
		_dynamic_panel_v0164 != null
		and is_instance_valid(_dynamic_panel_v0164)
		and _dynamic_panel_v0164.is_inside_tree()
		and _dynamic_parameters_v0164 != null
		and is_instance_valid(_dynamic_parameters_v0164)
	)


func current_normalized_capabilities_v0161() -> Dictionary:
	var profile := _selected_profile()
	var catalog := CCFImageProviderModelCatalogServiceV0164.catalog_from_profile(profile)
	if not (catalog.get("records", []) as Array).is_empty():
		var selected_model := _model_edit.text.strip_edges() if _model_edit != null else ""
		return CCFImageProviderModelCatalogServiceV0164.normalized_capabilities_for_model(
			profile, catalog, selected_model
		)
	return super.current_normalized_capabilities_v0161()


func _load_selected_profile_settings() -> void:
	super._load_selected_profile_settings()
	call_deferred("_refresh_dynamic_provider_controls_v0164")


func _on_capabilities_loaded(capabilities: Dictionary) -> void:
	super._on_capabilities_loaded(capabilities)
	var catalog_value: Variant = capabilities.get("rich_model_catalog", {})
	if not catalog_value is Dictionary or catalog_value.is_empty():
		_refresh_dynamic_provider_controls_v0164()
		return
	if _profile_selector == null or _profile_selector.selected < 0:
		return
	var profile_id := str(_profile_selector.get_selected_metadata())
	var updated_settings := _settings.duplicate(true)
	var profile := CCFSettingsService.image_profile_by_id(updated_settings, profile_id).duplicate(true)
	if profile.is_empty():
		return
	profile = CCFImageProviderModelCatalogServiceV0164.cache_catalog_in_profile(profile, catalog_value)
	var selected_model := _model_edit.text.strip_edges() if _model_edit != null else ""
	var selected_record := CCFImageProviderModelCatalogServiceV0164.record_for_model(catalog_value, selected_model)
	if not selected_record.is_empty():
		profile[CCFImageCapabilityCacheServiceV0161.CACHE_KEY] = (
			CCFImageModelCapabilityServiceV0161.normalise_provider_model_record(profile, selected_record)
		)
	CCFSettingsService.replace_image_profile_by_id(updated_settings, profile_id, profile)
	var save_result := CCFSettingsService.save_settings(updated_settings)
	if bool(save_result.get("ok", false)):
		_settings = CCFSettingsService.load_settings()
		if _status != null:
			_status.text += " Rich per-model metadata was cached for passive browsing."
	elif _status != null:
		_status.text += " Rich model catalog cache failed: %s" % str(save_result.get("error", "Unknown settings error"))
	_refresh_dynamic_provider_controls_v0164()


func _current_generation_options(generation_mode: String, source_image_id: String) -> Dictionary:
	var result := super._current_generation_options(generation_mode, source_image_id)
	result["provider_parameters"] = _dynamic_provider_parameter_values_v0164()
	return result


func _install_v0164_services() -> void:
	_install_capability_service_v0164()
	_install_image_service_v0164()
	if _discover_button != null:
		_discover_button.text = "Refresh Model Capabilities"
		_discover_button.tooltip_text = "Explicitly refresh provider model/capability metadata. Cached metadata is used for passive browsing; opening Image Studio does not spend credits or make discovery requests."


func _install_capability_service_v0164() -> void:
	if _capability_service is CCFImageCapabilityServiceV0164:
		return
	var previous := _capability_service
	if previous != null:
		if previous.capabilities_started.is_connected(_on_capabilities_started):
			previous.capabilities_started.disconnect(_on_capabilities_started)
		if previous.capabilities_loaded.is_connected(_on_capabilities_loaded):
			previous.capabilities_loaded.disconnect(_on_capabilities_loaded)
		if previous.capabilities_failed.is_connected(_on_capabilities_failed):
			previous.capabilities_failed.disconnect(_on_capabilities_failed)
		if previous.capabilities_cancelled.is_connected(_on_capabilities_cancelled):
			previous.capabilities_cancelled.disconnect(_on_capabilities_cancelled)
		if previous.get_parent() == self:
			remove_child(previous)
		previous.queue_free()
	var upgraded := CAPABILITY_SERVICE_V0164.new() as CCFImageCapabilityServiceV0164
	add_child(upgraded)
	upgraded.capabilities_started.connect(_on_capabilities_started)
	upgraded.capabilities_loaded.connect(_on_capabilities_loaded)
	upgraded.capabilities_failed.connect(_on_capabilities_failed)
	upgraded.capabilities_cancelled.connect(_on_capabilities_cancelled)
	_capability_service = upgraded


func _install_image_service_v0164() -> void:
	if _image_service is CCFImageGenerationServiceV0164:
		return
	var previous := _image_service
	if previous != null:
		if previous.generation_started.is_connected(_on_generation_started):
			previous.generation_started.disconnect(_on_generation_started)
		if previous.generation_batch_completed.is_connected(_on_generation_batch_completed):
			previous.generation_batch_completed.disconnect(_on_generation_batch_completed)
		if previous.generation_failed.is_connected(_on_generation_failed):
			previous.generation_failed.disconnect(_on_generation_failed)
		if previous.generation_cancelled.is_connected(_on_generation_cancelled):
			previous.generation_cancelled.disconnect(_on_generation_cancelled)
		if previous.get_parent() == self:
			remove_child(previous)
		previous.queue_free()
	var upgraded := IMAGE_SERVICE_V0164.new() as CCFImageGenerationServiceV0164
	add_child(upgraded)
	upgraded.generation_started.connect(_on_generation_started)
	upgraded.generation_batch_completed.connect(_on_generation_batch_completed)
	upgraded.generation_failed.connect(_on_generation_failed)
	upgraded.generation_cancelled.connect(_on_generation_cancelled)
	upgraded.generation_queued.connect(_on_image_generation_queued_v01526)
	_image_service = upgraded
	if _scheduler_for_image_v01526 != null:
		upgraded.configure_scheduler_v01526(_scheduler_for_image_v01526)


func _install_dynamic_provider_surface_v0164() -> void:
	if _dynamic_panel_v0164 != null and is_instance_valid(_dynamic_panel_v0164):
		return
	if _advanced_stack_v0163 == null or not is_instance_valid(_advanced_stack_v0163):
		return
	var panel := PanelContainer.new()
	panel.name = "ImageStudioDynamicProviderPanelV0164"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dynamic_panel_v0164 = VBoxContainer.new()
	_dynamic_panel_v0164.name = "ImageStudioDynamicProviderControlsV0164"
	_dynamic_panel_v0164.add_theme_constant_override("separation", 7)
	panel.add_child(_dynamic_panel_v0164)
	_advanced_stack_v0163.add_child(panel)
	_advanced_stack_v0163.move_child(panel, mini(2, _advanced_stack_v0163.get_child_count() - 1))

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	_dynamic_panel_v0164.add_child(header)
	var section_title := Label.new()
	section_title.text = "Dynamic model parameters"
	section_title.add_theme_font_size_override("font_size", 16)
	section_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(section_title)
	_refresh_models_button_v0164 = Button.new()
	_refresh_models_button_v0164.name = "ImageStudioRefreshModelCapabilitiesV0164"
	_refresh_models_button_v0164.text = "Refresh"
	_refresh_models_button_v0164.pressed.connect(_discover_capabilities)
	header.add_child(_refresh_models_button_v0164)

	_dynamic_summary_v0164 = Label.new()
	_dynamic_summary_v0164.name = "ImageStudioDynamicCapabilitySummaryV0164"
	_dynamic_summary_v0164.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dynamic_summary_v0164.modulate = Color(0.66, 0.73, 0.84)
	_dynamic_panel_v0164.add_child(_dynamic_summary_v0164)
	_dynamic_parameters_v0164 = VBoxContainer.new()
	_dynamic_parameters_v0164.name = "ImageStudioDynamicParameterRowsV0164"
	_dynamic_parameters_v0164.add_theme_constant_override("separation", 5)
	_dynamic_panel_v0164.add_child(_dynamic_parameters_v0164)


func _refresh_dynamic_provider_controls_v0164() -> void:
	if _rebuilding_dynamic_v0164 or _dynamic_parameters_v0164 == null:
		return
	_rebuilding_dynamic_v0164 = true
	for child in _dynamic_parameters_v0164.get_children():
		_dynamic_parameters_v0164.remove_child(child)
		child.queue_free()
	_dynamic_parameter_controls_v0164.clear()
	_dynamic_parameter_descriptors_v0164.clear()
	_dynamic_resolution_v0164 = null

	var profile := _selected_profile()
	var catalog := CCFImageProviderModelCatalogServiceV0164.catalog_from_profile(profile)
	var model_id := _model_edit.text.strip_edges() if _model_edit != null else ""
	var capabilities := current_normalized_capabilities_v0161()
	var missing := bool(capabilities.get("model_missing_from_latest_catalog", false))
	var records: Array = catalog.get("records", [])
	if records.is_empty():
		_dynamic_summary_v0164.text = "No rich model catalog is cached for this profile. Refresh explicitly to discover model-specific capabilities; passive browsing makes no request."
		_rebuilding_dynamic_v0164 = false
		return
	var age := CCFImageProviderModelCatalogServiceV0164.catalog_age_seconds(catalog)
	var age_text := "unknown age" if age < 0 else _format_age_v0164(age)
	if missing and not model_id.is_empty():
		_dynamic_summary_v0164.text = "Model '%s' is not in the latest provider catalog. Its manual selection is retained; refresh or choose an available model before relying on technical controls. Catalog: %s." % [model_id, age_text]
		_rebuilding_dynamic_v0164 = false
		return
	_dynamic_summary_v0164.text = "%d provider model(s) cached · %s · %s" % [records.size(), age_text, str(catalog.get("endpoint", "provider endpoint"))]

	var parameters: Dictionary = capabilities.get("parameters", {}) if capabilities.get("parameters", {}) is Dictionary else {}
	var resolution_descriptor: Dictionary = parameters.get("resolution", {})
	if str(resolution_descriptor.get("state", "unknown")) == CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED:
		var resolutions: Variant = resolution_descriptor.get("values", [])
		if resolutions is Array and not resolutions.is_empty():
			_add_resolution_row_v0164(resolutions)
	var image_count_descriptor: Dictionary = parameters.get("image_count", {})
	_apply_image_count_constraints_v0164(image_count_descriptor)

	var skip_keys := {
		"resolution": true, "resolutions": true, "image_count": true,
		"max_images": true, "fixed_image_count": true, "negative_prompt": true,
		"seed": true, "sampler": true, "steps": true, "cfg_scale": true
	}
	var parameter_keys := parameters.keys()
	parameter_keys.sort()
	for raw_key in parameter_keys:
		var key_text := str(raw_key)
		if skip_keys.has(key_text):
			continue
		var descriptor: Dictionary = parameters.get(raw_key, {})
		if str(descriptor.get("state", "unknown")) != CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED:
			continue
		_add_dynamic_parameter_row_v0164(key_text, descriptor)
	var pricing: Dictionary = capabilities.get("pricing", {}) if capabilities.get("pricing", {}) is Dictionary else {}
	if not pricing.is_empty():
		var pricing_label := Label.new()
		pricing_label.name = "ImageStudioProviderPricingV0164"
		pricing_label.text = "Provider pricing metadata: %s" % JSON.stringify(pricing)
		pricing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pricing_label.modulate = Color(0.62, 0.69, 0.78)
		_dynamic_parameters_v0164.add_child(pricing_label)
	_rebuilding_dynamic_v0164 = false


func _add_resolution_row_v0164(values: Array) -> void:
	var row := HBoxContainer.new()
	row.name = "DynamicParameter_resolution_V0164"
	row.add_theme_constant_override("separation", 8)
	_dynamic_parameters_v0164.add_child(row)
	var label := Label.new()
	label.text = "Resolution / size"
	row.add_child(label)
	_dynamic_resolution_v0164 = OptionButton.new()
	_dynamic_resolution_v0164.custom_minimum_size.x = 220
	for raw_value in values:
		_dynamic_resolution_v0164.add_item(str(raw_value))
		_dynamic_resolution_v0164.set_item_metadata(_dynamic_resolution_v0164.item_count - 1, raw_value)
	var existing := _image_size_edit.text.strip_edges() if _image_size_edit != null else ""
	for index in range(_dynamic_resolution_v0164.item_count):
		if str(_dynamic_resolution_v0164.get_item_metadata(index)) == existing:
			_dynamic_resolution_v0164.select(index)
			break
	_dynamic_resolution_v0164.item_selected.connect(_on_dynamic_resolution_selected_v0164)
	row.add_child(_dynamic_resolution_v0164)


func _apply_image_count_constraints_v0164(descriptor: Dictionary) -> void:
	if _batch_size == null or descriptor.is_empty():
		return
	if str(descriptor.get("state", "unknown")) != CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED:
		return
	if descriptor.has("maximum"):
		_batch_size.max_value = maxf(1.0, float(descriptor.get("maximum", 1)))
		_batch_size.value = minf(_batch_size.value, _batch_size.max_value)
	if bool(descriptor.get("fixed", false)):
		var fixed_value := maxf(1.0, float(descriptor.get("default", 1)))
		_batch_size.min_value = fixed_value
		_batch_size.max_value = fixed_value
		_batch_size.value = fixed_value
	else:
		_batch_size.min_value = 1.0


func _add_dynamic_parameter_row_v0164(key_text: String, descriptor: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.name = "DynamicParameter_%s_V0164" % key_text
	row.add_theme_constant_override("separation", 8)
	_dynamic_parameters_v0164.add_child(row)
	var label := Label.new()
	label.text = key_text.replace("_", " ").capitalize()
	label.custom_minimum_size.x = 180
	row.add_child(label)
	var value_type := str(descriptor.get("value_type", "unknown"))
	var control: Control
	if value_type == "choice" and descriptor.get("values", []) is Array and not (descriptor.get("values", []) as Array).is_empty():
		var choice := OptionButton.new()
		choice.custom_minimum_size.x = 240
		for raw_value in descriptor.get("values", []):
			choice.add_item(str(raw_value))
			choice.set_item_metadata(choice.item_count - 1, raw_value)
		control = choice
	elif value_type == "boolean":
		var check := CheckButton.new()
		check.text = "Enabled"
		check.button_pressed = bool(descriptor.get("default", false))
		control = check
	else:
		var edit := LineEdit.new()
		edit.custom_minimum_size.x = 240
		if descriptor.get("default", null) != null:
			edit.text = str(descriptor.get("default"))
		edit.placeholder_text = value_type
		control = edit
	row.add_child(control)
	_dynamic_parameter_controls_v0164[key_text] = control
	_dynamic_parameter_descriptors_v0164[key_text] = descriptor.duplicate(true)


func _dynamic_provider_parameter_values_v0164() -> Dictionary:
	var result: Dictionary = {}
	for raw_key in _dynamic_parameter_controls_v0164.keys():
		var key_text := str(raw_key)
		var control: Control = _dynamic_parameter_controls_v0164.get(raw_key)
		var descriptor: Dictionary = _dynamic_parameter_descriptors_v0164.get(raw_key, {})
		if control is OptionButton:
			var option := control as OptionButton
			if option.selected >= 0:
				result[key_text] = option.get_selected_metadata()
		elif control is CheckButton:
			result[key_text] = (control as CheckButton).button_pressed
		elif control is LineEdit:
			var text := (control as LineEdit).text.strip_edges()
			if text.is_empty():
				continue
			match str(descriptor.get("value_type", "unknown")):
				"integer": result[key_text] = int(text)
				"number": result[key_text] = float(text)
				_: result[key_text] = text
	return result


func _on_dynamic_resolution_selected_v0164(index: int) -> void:
	if _dynamic_resolution_v0164 == null or _image_size_edit == null:
		return
	_image_size_edit.text = str(_dynamic_resolution_v0164.get_item_metadata(index))


func _on_dynamic_model_changed_v0164(_new_text: String) -> void:
	call_deferred("_refresh_dynamic_provider_controls_v0164")


func _format_age_v0164(seconds: int) -> String:
	if seconds < 60:
		return "updated just now"
	if seconds < 3600:
		return "updated %dm ago" % int(float(seconds) / 60.0)
	if seconds < 86400:
		return "updated %dh ago" % int(float(seconds) / 3600.0)
	return "updated %dd ago" % int(float(seconds) / 86400.0)