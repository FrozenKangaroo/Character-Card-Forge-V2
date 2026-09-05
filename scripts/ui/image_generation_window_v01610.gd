class_name CCFImageGenerationWindowV01610
extends "res://scripts/ui/image_generation_window_v0169.gd"

const IMAGE_SERVICE_V01610 = preload(
	"res://scripts/services/image_generation_service_v01610.gd"
)

var _result_workflow_panel_v01610: VBoxContainer
var _reuse_settings_button_v01610: Button
var _favourite_button_v01610: Button
var _compare_a_button_v01610: Button
var _compare_b_button_v01610: Button
var _show_comparison_button_v01610: Button
var _recover_button_v01610: Button
var _cost_label_v01610: Label
var _comparison_dialog_v01610: AcceptDialog
var _comparison_text_v01610: TextEdit
var _recovery_dialog_v01610: FileDialog
var _compare_a_v01610: Dictionary = {}
var _compare_b_v01610: Dictionary = {}


func _ready() -> void:
	super._ready()
	_install_image_service_v01610()
	ensure_result_workflow_surface_v01610()


func _build_ui() -> void:
	super._build_ui()
	_install_result_workflow_surface_v01610()


func result_workflow_capabilities_v01610() -> Dictionary:
	return {
		"version": "0.16.10",
		"exact_composed_prompt_history": true,
		"execution_settings_snapshot": true,
		"reuse_settings_without_generation": true,
		"regenerate_same_seed": true,
		"new_seed_variation": true,
		"favourites": true,
		"two_result_comparison": true,
		"missing_asset_recovery": true,
		"optional_explicit_cost_estimate": true,
		"pricing_required": false
	}


func ensure_result_workflow_surface_v01610() -> void:
	_install_result_workflow_surface_v01610()
	_refresh_result_workflow_v01610()


func result_workflow_surface_ready_v01610() -> bool:
	return (
		_result_workflow_panel_v01610 != null
		and is_instance_valid(_result_workflow_panel_v01610)
		and _result_workflow_panel_v01610.is_inside_tree()
		and _reuse_settings_button_v01610 != null
		and _favourite_button_v01610 != null
	)


func _install_image_service_v01610() -> void:
	if _image_service is CCFImageGenerationServiceV01610:
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
	var upgraded := IMAGE_SERVICE_V01610.new() as CCFImageGenerationServiceV01610
	add_child(upgraded)
	upgraded.generation_started.connect(_on_generation_started)
	upgraded.generation_batch_completed.connect(_on_generation_batch_completed)
	upgraded.generation_failed.connect(_on_generation_failed)
	upgraded.generation_cancelled.connect(_on_generation_cancelled)
	upgraded.generation_queued.connect(_on_image_generation_queued_v01526)
	_image_service = upgraded
	if _scheduler_for_image_v01526 != null:
		upgraded.configure_scheduler_v01526(_scheduler_for_image_v01526)


func _install_result_workflow_surface_v01610() -> void:
	if _result_workflow_panel_v01610 != null and is_instance_valid(_result_workflow_panel_v01610):
		return
	if _gallery == null or _gallery.get_parent() == null:
		return
	var panel := PanelContainer.new()
	panel.name = "ImageStudioResultWorkflowPanelV01610"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_result_workflow_panel_v01610 = VBoxContainer.new()
	_result_workflow_panel_v01610.name = "ImageStudioResultWorkflowControlsV01610"
	_result_workflow_panel_v01610.add_theme_constant_override("separation", 6)
	panel.add_child(_result_workflow_panel_v01610)
	_gallery.get_parent().add_child(panel)

	var heading := Label.new()
	heading.text = "Result workflow"
	heading.add_theme_font_size_override("font_size", 16)
	_result_workflow_panel_v01610.add_child(heading)
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("separation", 7)
	_result_workflow_panel_v01610.add_child(actions)
	_reuse_settings_button_v01610 = _result_button_v01610("Reuse Settings", _reuse_selected_v01610)
	_reuse_settings_button_v01610.name = "ImageStudioReuseSettingsV01610"
	actions.add_child(_reuse_settings_button_v01610)
	_favourite_button_v01610 = _result_button_v01610("Favourite", _toggle_favourite_v01610)
	_favourite_button_v01610.name = "ImageStudioFavouriteResultV01610"
	actions.add_child(_favourite_button_v01610)
	_compare_a_button_v01610 = _result_button_v01610("Set Compare A", _set_compare_a_v01610)
	actions.add_child(_compare_a_button_v01610)
	_compare_b_button_v01610 = _result_button_v01610("Set Compare B", _set_compare_b_v01610)
	actions.add_child(_compare_b_button_v01610)
	_show_comparison_button_v01610 = _result_button_v01610("Compare…", _show_comparison_v01610)
	_show_comparison_button_v01610.name = "ImageStudioCompareResultsV01610"
	actions.add_child(_show_comparison_button_v01610)
	_recover_button_v01610 = _result_button_v01610("Recover Missing File…", _choose_recovery_file_v01610)
	_recover_button_v01610.name = "ImageStudioRecoverResultV01610"
	actions.add_child(_recover_button_v01610)

	_cost_label_v01610 = Label.new()
	_cost_label_v01610.name = "ImageStudioCostEstimateV01610"
	_cost_label_v01610.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cost_label_v01610.modulate = Color(0.64, 0.72, 0.84)
	_result_workflow_panel_v01610.add_child(_cost_label_v01610)

	_comparison_dialog_v01610 = AcceptDialog.new()
	_comparison_dialog_v01610.title = "Compare Image Studio Results"
	_comparison_dialog_v01610.min_size = Vector2i(780, 560)
	add_child(_comparison_dialog_v01610)
	_comparison_text_v01610 = TextEdit.new()
	_comparison_text_v01610.editable = false
	_comparison_text_v01610.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_comparison_text_v01610.custom_minimum_size = Vector2(740, 500)
	_comparison_dialog_v01610.add_child(_comparison_text_v01610)

	_recovery_dialog_v01610 = FileDialog.new()
	_recovery_dialog_v01610.title = "Recover generated image file"
	_recovery_dialog_v01610.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_recovery_dialog_v01610.access = FileDialog.ACCESS_FILESYSTEM
	_recovery_dialog_v01610.use_native_dialog = true
	_recovery_dialog_v01610.filters = PackedStringArray(["*.png ; PNG Images", "*.jpg,*.jpeg ; JPEG Images", "*.webp ; WebP Images"])
	_recovery_dialog_v01610.file_selected.connect(_recover_selected_file_v01610)
	add_child(_recovery_dialog_v01610)


func _result_button_v01610(label_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label_text
	button.pressed.connect(callback)
	return button


func _refresh_gallery() -> void:
	super._refresh_gallery()
	if _gallery != null:
		for index in range(_gallery.item_count):
			var entry: Variant = _gallery.get_item_metadata(index)
			if entry is Dictionary and CCFImageResultWorkflowServiceV01610.is_favourite(entry):
				_gallery.set_item_text(index, "★ " + _gallery.get_item_text(index))
	_refresh_result_workflow_v01610()


func _on_gallery_selected(index: int) -> void:
	super._on_gallery_selected(index)
	_refresh_result_workflow_v01610()


func _refresh_gallery_action_state() -> void:
	super._refresh_gallery_action_state()
	_refresh_result_workflow_v01610()


func _refresh_result_workflow_v01610() -> void:
	if _result_workflow_panel_v01610 == null:
		return
	var entry := _selected_gallery_entry()
	var has_selection := not entry.is_empty()
	for button in [_reuse_settings_button_v01610, _favourite_button_v01610, _compare_a_button_v01610, _compare_b_button_v01610]:
		if button != null:
			button.disabled = not has_selection or (_image_service != null and _image_service.is_active())
	if _favourite_button_v01610 != null:
		_favourite_button_v01610.text = "Unfavourite" if CCFImageResultWorkflowServiceV01610.is_favourite(entry) else "Favourite"
	if _show_comparison_button_v01610 != null:
		_show_comparison_button_v01610.disabled = _compare_a_v01610.is_empty() or _compare_b_v01610.is_empty()
	if _recover_button_v01610 != null:
		_recover_button_v01610.disabled = not has_selection or _selected_file_exists_v01610(entry)
	if _cost_label_v01610 != null:
		var capabilities := current_normalized_capabilities_v0161()
		var pricing: Dictionary = capabilities.get("pricing", {}) if capabilities.get("pricing", {}) is Dictionary else {}
		_cost_label_v01610.text = CCFImageResultWorkflowServiceV01610.cost_label(
			CCFImageResultWorkflowServiceV01610.estimate_cost(pricing, int(_batch_size.value))
		)


func _reuse_selected_v01610() -> void:
	var entry := _selected_gallery_entry()
	if entry.is_empty():
		return
	_load_generation_from_entry(entry, true)
	_restore_snapshot_extensions_v01610(entry)
	_status.text = "Reused the selected result's prompt, provider/model and generation settings. No provider request was made."


func _regenerate_selected() -> void:
	var entry := _selected_gallery_entry()
	if entry.is_empty():
		return
	_load_generation_from_entry(entry, true)
	_restore_snapshot_extensions_v01610(entry)
	_batch_size.value = 1
	_start_generation("regenerate", entry)


func _variant_selected() -> void:
	var entry := _selected_gallery_entry()
	if entry.is_empty():
		return
	_load_generation_from_entry(entry, false)
	_restore_snapshot_extensions_v01610(entry)
	_batch_size.value = 1
	_seed.value = -1
	_start_generation("variant", entry)


func _restore_snapshot_extensions_v01610(entry: Dictionary) -> void:
	var snapshot := CCFImageResultWorkflowServiceV01610.snapshot_from_record(entry)
	var wanted_operation := str(snapshot.get("image_operation", "text_to_image"))
	if _operation_selector_v0168 != null:
		for index in range(_operation_selector_v0168.item_count):
			if str(_operation_selector_v0168.get_item_metadata(index)) == wanted_operation and not _operation_selector_v0168.is_item_disabled(index):
				_operation_selector_v0168.select(index)
				break
	_source_image_path_v0168 = str(snapshot.get("source_image_path", ""))
	_source_image_id_v0168 = str(snapshot.get("source_image_id", ""))
	_mask_image_path_v0168 = str(snapshot.get("mask_image_path", ""))
	_reference_image_paths_v0168.clear()
	for raw_path in snapshot.get("reference_image_paths", []):
		_reference_image_paths_v0168.append(str(raw_path))
	_denoise_v0168.value = float(snapshot.get("denoise_strength", 0.65))
	_mask_blur_v0168.value = int(snapshot.get("mask_blur", 4))
	_restore_provider_parameters_v01610(snapshot.get("provider_parameters", {}))
	_refresh_image_input_summary_v0168()


func _restore_provider_parameters_v01610(value: Variant) -> void:
	if not value is Dictionary:
		return
	for raw_key in value.keys():
		var control: Control = _dynamic_parameter_controls_v0164.get(raw_key)
		var wanted: Variant = value.get(raw_key)
		if control is OptionButton:
			var option := control as OptionButton
			for index in range(option.item_count):
				if option.get_item_metadata(index) == wanted or str(option.get_item_metadata(index)) == str(wanted):
					option.select(index)
					break
		elif control is CheckButton:
			(control as CheckButton).button_pressed = bool(wanted)
		elif control is LineEdit:
			(control as LineEdit).text = str(wanted)


func _toggle_favourite_v01610() -> void:
	var entry := _selected_gallery_entry()
	if entry.is_empty():
		return
	var updated := CCFImageResultWorkflowServiceV01610.with_favourite(
		entry, not CCFImageResultWorkflowServiceV01610.is_favourite(entry)
	)
	if _replace_gallery_record_v01610(updated):
		_status.text = "Result favourite updated."


func _set_compare_a_v01610() -> void:
	_compare_a_v01610 = _selected_gallery_entry()
	_status.text = "Comparison result A selected."
	_refresh_result_workflow_v01610()


func _set_compare_b_v01610() -> void:
	_compare_b_v01610 = _selected_gallery_entry()
	_status.text = "Comparison result B selected."
	_refresh_result_workflow_v01610()


func _show_comparison_v01610() -> void:
	_comparison_text_v01610.text = CCFImageResultWorkflowServiceV01610.comparison_text(_compare_a_v01610, _compare_b_v01610)
	_comparison_dialog_v01610.popup_centered(Vector2i(820, 600))


func _selected_file_exists_v01610(entry: Dictionary) -> bool:
	if entry.is_empty():
		return false
	var path := CCFImageGenerationService.resolve_generated_image_path(str(_project.get("project_id", "")), str(entry.get("path", "")))
	return not path.is_empty() and FileAccess.file_exists(path)


func _choose_recovery_file_v01610() -> void:
	if _selected_gallery_entry().is_empty():
		return
	_recovery_dialog_v01610.popup_centered(Vector2i(860, 620))


func _recover_selected_file_v01610(source_path: String) -> void:
	var entry := _selected_gallery_entry()
	if entry.is_empty() or not FileAccess.file_exists(source_path):
		return
	var original_entry := entry.duplicate(true)
	var project_id := str(_project.get("project_id", ""))
	var folder := CCFStorageService.project_folder(project_id) + "/characters/" + _active_character_id + "/generated_images"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var extension := source_path.get_extension().to_lower()
	if extension not in ["png", "jpg", "jpeg", "webp"]:
		extension = "png"
	var file_name := "recovered_%s_%s.%s" % [int(Time.get_unix_time_from_system()), randi_range(1000, 9999), extension]
	var relative_path := "characters/%s/generated_images/%s" % [_active_character_id, file_name]
	var destination := ProjectSettings.globalize_path(CCFStorageService.project_folder(project_id) + "/" + relative_path)
	var copy_error := DirAccess.copy_absolute(source_path, destination)
	if copy_error != OK:
		_status.text = "Could not recover the selected result file (error %s)." % copy_error
		return
	entry["path"] = relative_path
	entry["recovered_at_v01610"] = Time.get_datetime_string_from_system(true)
	if _replace_gallery_record_v01610(entry, original_entry):
		_status.text = "Recovered the missing result into the project asset folder."


func _replace_gallery_record_v01610(updated: Dictionary, original: Dictionary = {}) -> bool:
	var character_index := CCFStorageService.character_index(_project, _active_character_id)
	if character_index < 0:
		return false
	var characters: Array = _project.get("characters", []).duplicate(true)
	var character: Dictionary = characters[character_index].duplicate(true)
	var assets: Dictionary = character.get("assets", {}).duplicate(true)
	var records: Array = assets.get("generated_images", []).duplicate(true)
	var replaced := false
	var match_record := original if not original.is_empty() else updated
	for index in range(records.size()):
		var candidate := _normalise_gallery_entry(records[index])
		if CCFImageResultWorkflowServiceV01610.same_record(candidate, match_record):
			records[index] = updated.duplicate(true)
			replaced = true
			break
	if not replaced:
		return false
	assets["generated_images"] = records
	character["assets"] = assets
	characters[character_index] = character
	_project["characters"] = characters
	var save_result := CCFStorageService.save_project(_project)
	if not bool(save_result.get("ok", false)):
		_status.text = str(save_result.get("error", "Could not save the result update."))
		return false
	_refresh_gallery()
	project_changed.emit(_project.duplicate(true))
	return true
