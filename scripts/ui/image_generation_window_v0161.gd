class_name CCFImageGenerationWindowV0161
extends "res://scripts/ui/image_generation_window_v01538_indexed.gd"

var _capability_summary_v0161: Label
var _capability_details_button_v0161: Button
var _capability_dialog_v0161: AcceptDialog
var _capability_details_v0161: RichTextLabel


func _ready() -> void:
	super._ready()
	ensure_capability_surface_v0161()
	if _model_edit != null and not _model_edit.text_changed.is_connected(_on_model_text_changed_v0161):
		_model_edit.text_changed.connect(_on_model_text_changed_v0161)


func _build_ui() -> void:
	super._build_ui()
	_install_capability_surface_v0161()


func image_studio_foundation_capabilities_v0161() -> Dictionary:
	return {
		"version": "0.16.1",
		"normalized_capability_format": CCFImageModelCapabilityServiceV0161.FORMAT_VERSION,
		"tri_state_capabilities": true,
		"capability_provenance": true,
		"execution_readiness_separate_from_backend_support": true,
		"provider_model_records": true,
		"generic_additive_supported_parameters": true,
		"pricing_metadata_preserved": true,
		"legacy_capability_cache_migration": true,
		"user_override_layer_ready": true,
		"forge_a1111_backend_profile": true,
		"openai_compatible_unknown_safe_defaults": true,
		"comfyui_workflow_source_reserved": true
	}


func ensure_capability_surface_v0161() -> void:
	# This method is intentionally idempotent. Image Studio can be constructed as
	# a native Window, embedded by tests, or replaced by a later versioned shell.
	# Calling it after the Window is attached guarantees the inherited provider
	# controls exist even if a lifecycle path did not dispatch our _build_ui()
	# override during construction.
	_install_capability_surface_v0161()
	_refresh_capability_surface_v0161()


func capability_surface_ready_v0161() -> bool:
	return (
		_capability_summary_v0161 != null
		and is_instance_valid(_capability_summary_v0161)
		and _capability_summary_v0161.is_inside_tree()
		and _capability_details_button_v0161 != null
		and is_instance_valid(_capability_details_button_v0161)
		and _capability_details_button_v0161.is_inside_tree()
	)


func current_normalized_capabilities_v0161() -> Dictionary:
	var profile := _selected_profile()
	var capabilities := CCFImageCapabilityCacheServiceV0161.capabilities_from_profile(profile)
	var selected_model := ""
	if _model_edit != null:
		selected_model = _model_edit.text.strip_edges()
	if not selected_model.is_empty():
		capabilities["model_id"] = selected_model
		if str(capabilities.get("model_name", "")).strip_edges().is_empty():
			capabilities["model_name"] = selected_model
	return capabilities


func _install_capability_surface_v0161() -> void:
	if _capability_summary_v0161 != null and is_instance_valid(_capability_summary_v0161):
		return
	if _backend_label == null or _backend_label.get_parent() == null:
		return
	var provider_row := _backend_label.get_parent()
	var root := provider_row.get_parent()
	if root == null:
		return

	var capability_row := HBoxContainer.new()
	capability_row.name = "ImageStudioCapabilityRowV0161"
	capability_row.add_theme_constant_override("separation", 8)
	_capability_summary_v0161 = Label.new()
	_capability_summary_v0161.name = "ImageStudioCapabilitySummaryV0161"
	_capability_summary_v0161.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_capability_summary_v0161.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_capability_summary_v0161.modulate = Color(0.68, 0.78, 0.9)
	capability_row.add_child(_capability_summary_v0161)
	_capability_details_button_v0161 = Button.new()
	_capability_details_button_v0161.name = "ImageStudioCapabilityDetailsButtonV0161"
	_capability_details_button_v0161.text = "Capability Details…"
	_capability_details_button_v0161.tooltip_text = (
		"Inspect what CCF knows, does not know, and can currently execute for this Image provider/model."
	)
	_capability_details_button_v0161.pressed.connect(_show_capability_details_v0161)
	capability_row.add_child(_capability_details_button_v0161)
	root.add_child(capability_row)
	root.move_child(capability_row, provider_row.get_index() + 1)

	_capability_dialog_v0161 = AcceptDialog.new()
	_capability_dialog_v0161.name = "ImageStudioCapabilityDialogV0161"
	_capability_dialog_v0161.title = "Image Studio — Model Capabilities"
	_capability_dialog_v0161.min_size = Vector2i(760, 560)
	add_child(_capability_dialog_v0161)
	_capability_details_v0161 = RichTextLabel.new()
	_capability_details_v0161.name = "ImageStudioCapabilityDetailsV0161"
	_capability_details_v0161.bbcode_enabled = true
	_capability_details_v0161.fit_content = false
	_capability_details_v0161.scroll_active = true
	_capability_details_v0161.custom_minimum_size = Vector2(720, 500)
	_capability_details_v0161.selection_enabled = true
	_capability_dialog_v0161.add_child(_capability_details_v0161)
	_capability_dialog_v0161.hide()


func _load_selected_profile_settings() -> void:
	super._load_selected_profile_settings()
	_refresh_capability_surface_v0161()


func _on_capabilities_loaded(capabilities: Dictionary) -> void:
	super._on_capabilities_loaded(capabilities)
	if _profile_selector == null or _profile_selector.selected < 0:
		_refresh_capability_surface_v0161()
		return
	var profile_id := str(_profile_selector.get_selected_metadata())
	var selected_model := _model_edit.text.strip_edges() if _model_edit != null else ""
	var cache_result := CCFImageCapabilityCacheServiceV0161.store_for_profile(
		_settings,
		profile_id,
		capabilities,
		selected_model
	)
	if bool(cache_result.get("ok", false)):
		_settings = cache_result.get("settings", _settings).duplicate(true)
		if _status != null:
			_status.text += " Normalized v0.16.1 capability metadata was cached too."
	elif _status != null:
		_status.text += " Normalized capability cache failed: %s" % str(
			cache_result.get("error", "Unknown settings error")
		)
	_refresh_capability_surface_v0161()


func _on_model_text_changed_v0161(_new_text: String) -> void:
	_refresh_capability_surface_v0161()


func _refresh_capability_surface_v0161() -> void:
	if _capability_summary_v0161 == null:
		return
	var capabilities := current_normalized_capabilities_v0161()
	_capability_summary_v0161.text = CCFImageModelCapabilityServiceV0161.summary(capabilities)
	var discovery: Dictionary = (
		capabilities.get("discovery", {})
		if capabilities.get("discovery", {}) is Dictionary
		else {}
	)
	var source := str(discovery.get("source", "inferred")).replace("_", " ").capitalize()
	var confidence := str(discovery.get("confidence", "inferred")).replace("_", " ").capitalize()
	_capability_summary_v0161.tooltip_text = (
		"Capability source: %s\nConfidence: %s\nUnknown means the backend/provider has not supplied enough information; it does not mean unsupported."
		% [source, confidence]
	)


func _show_capability_details_v0161() -> void:
	if _capability_dialog_v0161 == null or _capability_details_v0161 == null:
		return
	var capabilities := current_normalized_capabilities_v0161()
	_capability_details_v0161.text = _capability_details_text_v0161(capabilities)
	_capability_dialog_v0161.popup_centered(Vector2i(820, 620))


func _capability_details_text_v0161(capabilities: Dictionary) -> String:
	var lines: Array[String] = []
	var backend_label := str(capabilities.get("backend_label", "Unknown backend"))
	var model_name := str(capabilities.get("model_name", capabilities.get("model_id", ""))).strip_edges()
	if model_name.is_empty():
		model_name = "No model selected"
	lines.append("[font_size=20][b]%s[/b][/font_size]" % _bbcode_escape_v0161(model_name))
	lines.append("[color=#aebed8]%s[/color]" % _bbcode_escape_v0161(backend_label))
	lines.append("")

	var discovery: Dictionary = (
		capabilities.get("discovery", {})
		if capabilities.get("discovery", {}) is Dictionary
		else {}
	)
	lines.append("[b]Capability provenance[/b]")
	lines.append("Source: %s" % _bbcode_escape_v0161(str(discovery.get("source", "inferred")).replace("_", " ").capitalize()))
	lines.append("Confidence: %s" % _bbcode_escape_v0161(str(discovery.get("confidence", "inferred")).replace("_", " ").capitalize()))
	var note := str(discovery.get("note", "")).strip_edges()
	if not note.is_empty():
		lines.append(_bbcode_escape_v0161(note))
	lines.append("")

	lines.append("[b]Generation operations[/b]")
	var operations: Dictionary = (
		capabilities.get("operations", {})
		if capabilities.get("operations", {}) is Dictionary
		else {}
	)
	var operation_labels := {
		"text_to_image": "Text to Image",
		"image_to_image": "Image to Image",
		"inpainting": "Inpainting",
		"reference_images": "Reference Images"
	}
	for operation_name in ["text_to_image", "image_to_image", "inpainting", "reference_images"]:
		var descriptor: Dictionary = operations.get(operation_name, {})
		var state := CCFImageModelCapabilityServiceV0161.operation_state(capabilities, operation_name)
		var execution_text := "available in Studio" if bool(descriptor.get("execution_ready", false)) else "not yet exposed by Studio"
		if state != CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED:
			execution_text = "—"
		lines.append("• %s: [b]%s[/b]  %s" % [
			operation_labels.get(operation_name, operation_name),
			state.replace("_", " ").capitalize(),
			execution_text
		])
	lines.append("")

	lines.append("[b]Technical parameters[/b]")
	var parameters: Dictionary = (
		capabilities.get("parameters", {})
		if capabilities.get("parameters", {}) is Dictionary
		else {}
	)
	var parameter_keys := parameters.keys()
	parameter_keys.sort()
	if parameter_keys.is_empty():
		lines.append("No model-specific parameters have been described yet.")
	for raw_key in parameter_keys:
		var key_text := str(raw_key)
		var descriptor: Dictionary = parameters.get(raw_key, {})
		var state := str(descriptor.get("state", CCFImageModelCapabilityServiceV0161.STATE_UNKNOWN))
		var detail := str(descriptor.get("value_type", "unknown"))
		var values: Variant = descriptor.get("values", [])
		if values is Array and not values.is_empty():
			var display_values: Array[String] = []
			for raw_value in values:
				display_values.append(str(raw_value))
			detail += " · " + ", ".join(display_values).left(400)
		if descriptor.has("maximum"):
			detail += " · max %s" % descriptor.get("maximum")
		if bool(descriptor.get("fixed", false)):
			detail += " · fixed"
		lines.append("• %s: [b]%s[/b]  [color=#aebed8]%s[/color]" % [
			_bbcode_escape_v0161(key_text.replace("_", " ").capitalize()),
			_bbcode_escape_v0161(state.replace("_", " ").capitalize()),
			_bbcode_escape_v0161(detail)
		])
	lines.append("")
	lines.append("[color=#9aa5b8]Unknown is deliberate: CCF will not treat missing discovery metadata as proof that a model lacks a feature. Creative prompt controls remain separate from these provider/model capabilities.[/color]")
	return "\n".join(lines)


func _bbcode_escape_v0161(text: String) -> String:
	return text.replace("[", "[​").replace("]", "​]")
