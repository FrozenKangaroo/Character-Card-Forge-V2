class_name CCFImageGenerationWindowV0168
extends "res://scripts/ui/image_generation_window_v0166.gd"

const IMAGE_SERVICE_V0168 = preload(
	"res://scripts/services/image_generation_service_v0168.gd"
)

var _image_input_panel_v0168: VBoxContainer
var _operation_selector_v0168: OptionButton
var _source_summary_v0168: Label
var _mask_summary_v0168: Label
var _reference_summary_v0168: Label
var _denoise_v0168: SpinBox
var _mask_blur_v0168: SpinBox
var _source_dialog_v0168: FileDialog
var _mask_dialog_v0168: FileDialog
var _reference_dialog_v0168: FileDialog
var _source_image_path_v0168 := ""
var _source_image_id_v0168 := ""
var _mask_image_path_v0168 := ""
var _reference_image_paths_v0168: Array[String] = []


func _ready() -> void:
	super._ready()
	_install_image_service_v0168()
	ensure_image_input_surface_v0168()
	_refresh_image_input_capabilities_v0168()


func _build_ui() -> void:
	super._build_ui()
	_install_image_input_surface_v0168()


func image_input_capabilities_v0168() -> Dictionary:
	return {
		"version": "0.16.8",
		"first_class_image_operation_selector": true,
		"gallery_or_external_source_image": true,
		"multiple_reference_images": true,
		"inpainting_mask": true,
		"denoise_strength": true,
		"forge_a1111_img2img_transport": true,
		"forge_a1111_inpainting_transport": true,
		"provider_profile_transport_mapping": true,
		"capability_gated_operations": true,
		"comfyui_live_queue_transport": false
	}


func ensure_image_input_surface_v0168() -> void:
	_install_image_input_surface_v0168()
	_refresh_image_input_capabilities_v0168()
	_refresh_image_input_summary_v0168()


func image_input_surface_ready_v0168() -> bool:
	return (
		_image_input_panel_v0168 != null
		and is_instance_valid(_image_input_panel_v0168)
		and _image_input_panel_v0168.is_inside_tree()
		and _operation_selector_v0168 != null
	)


func current_normalized_capabilities_v0161() -> Dictionary:
	return CCFImageInputAssetServiceV0168.with_execution_readiness(
		super.current_normalized_capabilities_v0161(),
		_selected_profile()
	)


func _load_selected_profile_settings() -> void:
	super._load_selected_profile_settings()
	call_deferred("_refresh_image_input_capabilities_v0168")


func _on_dynamic_model_changed_v0164(new_text: String) -> void:
	super._on_dynamic_model_changed_v0164(new_text)
	call_deferred("_refresh_image_input_capabilities_v0168")


func _current_generation_options(generation_mode: String, source_image_id: String) -> Dictionary:
	var result := super._current_generation_options(generation_mode, source_image_id)
	result["image_operation"] = _selected_operation_v0168()
	result["source_image_path"] = _source_image_path_v0168
	result["mask_image_path"] = _mask_image_path_v0168
	result["reference_image_paths"] = _reference_image_paths_v0168.duplicate()
	result["denoise_strength"] = float(_denoise_v0168.value) if _denoise_v0168 != null else 0.65
	result["mask_blur"] = int(_mask_blur_v0168.value) if _mask_blur_v0168 != null else 4
	if source_image_id.is_empty() and not _source_image_id_v0168.is_empty():
		result["source_image_id"] = _source_image_id_v0168
	return result


func _install_image_service_v0168() -> void:
	if _image_service is CCFImageGenerationServiceV0168:
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
	var upgraded := IMAGE_SERVICE_V0168.new() as CCFImageGenerationServiceV0168
	add_child(upgraded)
	upgraded.generation_started.connect(_on_generation_started)
	upgraded.generation_batch_completed.connect(_on_generation_batch_completed)
	upgraded.generation_failed.connect(_on_generation_failed)
	upgraded.generation_cancelled.connect(_on_generation_cancelled)
	upgraded.generation_queued.connect(_on_image_generation_queued_v01526)
	_image_service = upgraded
	if _scheduler_for_image_v01526 != null:
		upgraded.configure_scheduler_v01526(_scheduler_for_image_v01526)


func _install_image_input_surface_v0168() -> void:
	if _image_input_panel_v0168 != null and is_instance_valid(_image_input_panel_v0168):
		return
	if _prompt_page_v0163 == null or not is_instance_valid(_prompt_page_v0163):
		return
	var prompt_holder := _prompt_page_v0163.find_child(
		"ImageStudioPromptTabContentV0163", true, false
	) as VBoxContainer
	if prompt_holder == null:
		return
	var panel := PanelContainer.new()
	panel.name = "ImageStudioImageInputPanelV0168"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_image_input_panel_v0168 = VBoxContainer.new()
	_image_input_panel_v0168.name = "ImageStudioImageInputControlsV0168"
	_image_input_panel_v0168.add_theme_constant_override("separation", 6)
	panel.add_child(_image_input_panel_v0168)
	prompt_holder.add_child(panel)
	prompt_holder.move_child(panel, 0)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	_image_input_panel_v0168.add_child(header)
	var heading := Label.new()
	heading.text = "Generation operation"
	heading.add_theme_font_size_override("font_size", 16)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	_operation_selector_v0168 = OptionButton.new()
	_operation_selector_v0168.name = "ImageStudioOperationSelectorV0168"
	for entry in [
		{"label": "Text to Image", "value": CCFImageInputAssetServiceV0168.OP_TEXT_TO_IMAGE},
		{"label": "Image to Image", "value": CCFImageInputAssetServiceV0168.OP_IMAGE_TO_IMAGE},
		{"label": "Inpainting", "value": CCFImageInputAssetServiceV0168.OP_INPAINTING},
		{"label": "Reference Images", "value": CCFImageInputAssetServiceV0168.OP_REFERENCE_IMAGES}
	]:
		_operation_selector_v0168.add_item(str(entry.get("label", "Operation")))
		_operation_selector_v0168.set_item_metadata(
			_operation_selector_v0168.item_count - 1,
			str(entry.get("value", CCFImageInputAssetServiceV0168.OP_TEXT_TO_IMAGE))
		)
	_operation_selector_v0168.item_selected.connect(_on_operation_selected_v0168)
	header.add_child(_operation_selector_v0168)

	var hint := Label.new()
	hint.text = "Operations are capability-gated. Forge/A1111 can execute img2img and inpainting directly; other providers require an explicit profile transport mapping. ComfyUI workflow mappings remain offline-only until live queue transport is added."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.66, 0.73, 0.84)
	_image_input_panel_v0168.add_child(hint)

	var source_row := HFlowContainer.new()
	source_row.add_theme_constant_override("separation", 7)
	_image_input_panel_v0168.add_child(source_row)
	source_row.add_child(_label("Source image"))
	_source_summary_v0168 = Label.new()
	_source_summary_v0168.name = "ImageStudioSourceImageSummaryV0168"
	_source_summary_v0168.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_source_summary_v0168.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	source_row.add_child(_source_summary_v0168)
	var gallery_source := Button.new()
	gallery_source.text = "Use Selected Gallery Image"
	gallery_source.pressed.connect(_use_gallery_as_source_v0168)
	source_row.add_child(gallery_source)
	var choose_source := Button.new()
	choose_source.text = "Choose Image…"
	choose_source.pressed.connect(_choose_source_image_v0168)
	source_row.add_child(choose_source)
	var clear_source := Button.new()
	clear_source.text = "Clear"
	clear_source.pressed.connect(_clear_source_image_v0168)
	source_row.add_child(clear_source)

	var reference_row := HFlowContainer.new()
	reference_row.add_theme_constant_override("separation", 7)
	_image_input_panel_v0168.add_child(reference_row)
	reference_row.add_child(_label("Reference images"))
	_reference_summary_v0168 = Label.new()
	_reference_summary_v0168.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reference_row.add_child(_reference_summary_v0168)
	var gallery_reference := Button.new()
	gallery_reference.text = "Add Selected Gallery Image"
	gallery_reference.pressed.connect(_add_gallery_reference_v0168)
	reference_row.add_child(gallery_reference)
	var choose_references := Button.new()
	choose_references.text = "Choose Images…"
	choose_references.pressed.connect(_choose_reference_images_v0168)
	reference_row.add_child(choose_references)
	var clear_references := Button.new()
	clear_references.text = "Clear"
	clear_references.pressed.connect(_clear_reference_images_v0168)
	reference_row.add_child(clear_references)

	var mask_row := HFlowContainer.new()
	mask_row.add_theme_constant_override("separation", 7)
	_image_input_panel_v0168.add_child(mask_row)
	mask_row.add_child(_label("Inpaint mask"))
	_mask_summary_v0168 = Label.new()
	_mask_summary_v0168.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mask_summary_v0168.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	mask_row.add_child(_mask_summary_v0168)
	var choose_mask := Button.new()
	choose_mask.text = "Choose Mask…"
	choose_mask.pressed.connect(_choose_mask_image_v0168)
	mask_row.add_child(choose_mask)
	var clear_mask := Button.new()
	clear_mask.text = "Clear"
	clear_mask.pressed.connect(_clear_mask_image_v0168)
	mask_row.add_child(clear_mask)

	var strength_row := HFlowContainer.new()
	strength_row.add_theme_constant_override("separation", 7)
	_image_input_panel_v0168.add_child(strength_row)
	strength_row.add_child(_label("Denoise / strength"))
	_denoise_v0168 = SpinBox.new()
	_denoise_v0168.min_value = 0.0
	_denoise_v0168.max_value = 1.0
	_denoise_v0168.step = 0.05
	_denoise_v0168.value = 0.65
	_denoise_v0168.custom_minimum_size.x = 100
	strength_row.add_child(_denoise_v0168)
	strength_row.add_child(_label("Mask blur"))
	_mask_blur_v0168 = SpinBox.new()
	_mask_blur_v0168.min_value = 0
	_mask_blur_v0168.max_value = 64
	_mask_blur_v0168.step = 1
	_mask_blur_v0168.value = 4
	_mask_blur_v0168.custom_minimum_size.x = 90
	strength_row.add_child(_mask_blur_v0168)

	_source_dialog_v0168 = _make_image_dialog_v0168("Choose source image", FileDialog.FILE_MODE_OPEN_FILE)
	_source_dialog_v0168.file_selected.connect(_on_source_image_selected_v0168)
	_mask_dialog_v0168 = _make_image_dialog_v0168("Choose inpainting mask", FileDialog.FILE_MODE_OPEN_FILE)
	_mask_dialog_v0168.file_selected.connect(_on_mask_image_selected_v0168)
	_reference_dialog_v0168 = _make_image_dialog_v0168("Choose reference images", FileDialog.FILE_MODE_OPEN_FILES)
	_reference_dialog_v0168.files_selected.connect(_on_reference_images_selected_v0168)
	_refresh_image_input_summary_v0168()


func _make_image_dialog_v0168(title_text: String, mode: FileDialog.FileMode) -> FileDialog:
	var dialog := FileDialog.new()
	dialog.title = title_text
	dialog.file_mode = mode
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.filters = PackedStringArray([
		"*.png ; PNG Images",
		"*.jpg,*.jpeg ; JPEG Images",
		"*.webp ; WebP Images"
	])
	add_child(dialog)
	return dialog


func _selected_operation_v0168() -> String:
	if _operation_selector_v0168 == null or _operation_selector_v0168.selected < 0:
		return CCFImageInputAssetServiceV0168.OP_TEXT_TO_IMAGE
	return CCFImageInputAssetServiceV0168.normalise_operation(
		str(_operation_selector_v0168.get_selected_metadata())
	)


func _on_operation_selected_v0168(_index: int) -> void:
	_refresh_image_input_summary_v0168()


func _refresh_image_input_capabilities_v0168() -> void:
	if _operation_selector_v0168 == null:
		return
	var capabilities := current_normalized_capabilities_v0161()
	for index in range(_operation_selector_v0168.item_count):
		var operation := CCFImageInputAssetServiceV0168.normalise_operation(
			str(_operation_selector_v0168.get_item_metadata(index))
		)
		var ready := CCFImageInputAssetServiceV0168.operation_execution_ready(
			capabilities, operation
		)
		_operation_selector_v0168.set_item_disabled(index, not ready)
	if _operation_selector_v0168.is_item_disabled(_operation_selector_v0168.selected):
		_operation_selector_v0168.select(0)
	_refresh_image_input_summary_v0168()
	_refresh_capability_surface_v0161()


func _refresh_image_input_summary_v0168() -> void:
	if _source_summary_v0168 != null:
		_source_summary_v0168.text = (
			_source_image_path_v0168.get_file()
			if not _source_image_path_v0168.is_empty()
			else "None selected"
		)
		_source_summary_v0168.tooltip_text = _source_image_path_v0168
	if _mask_summary_v0168 != null:
		_mask_summary_v0168.text = (
			_mask_image_path_v0168.get_file()
			if not _mask_image_path_v0168.is_empty()
			else "None selected"
		)
		_mask_summary_v0168.tooltip_text = _mask_image_path_v0168
	if _reference_summary_v0168 != null:
		_reference_summary_v0168.text = (
			"%d selected" % _reference_image_paths_v0168.size()
			if not _reference_image_paths_v0168.is_empty()
			else "None selected"
		)
		_reference_summary_v0168.tooltip_text = "\n".join(_reference_image_paths_v0168)
	var operation := _selected_operation_v0168()
	if _denoise_v0168 != null:
		_denoise_v0168.editable = operation in [
			CCFImageInputAssetServiceV0168.OP_IMAGE_TO_IMAGE,
			CCFImageInputAssetServiceV0168.OP_INPAINTING
		]
	if _mask_blur_v0168 != null:
		_mask_blur_v0168.editable = operation == CCFImageInputAssetServiceV0168.OP_INPAINTING


func _gallery_image_path_v0168() -> Dictionary:
	var entry := _selected_gallery_entry()
	if entry.is_empty():
		return {}
	var path_text := CCFImageGenerationService.resolve_generated_image_path(
		str(_project.get("project_id", "")),
		str(entry.get("path", ""))
	)
	if path_text.is_empty():
		return {}
	return {"path": path_text, "image_id": str(entry.get("image_id", ""))}


func _use_gallery_as_source_v0168() -> void:
	var gallery_source := _gallery_image_path_v0168()
	if gallery_source.is_empty():
		_status.text = "Select a generated gallery image first."
		return
	_source_image_path_v0168 = str(gallery_source.get("path", ""))
	_source_image_id_v0168 = str(gallery_source.get("image_id", ""))
	_refresh_image_input_summary_v0168()


func _add_gallery_reference_v0168() -> void:
	var gallery_source := _gallery_image_path_v0168()
	if gallery_source.is_empty():
		_status.text = "Select a generated gallery image first."
		return
	var path_text := str(gallery_source.get("path", ""))
	if not path_text in _reference_image_paths_v0168:
		_reference_image_paths_v0168.append(path_text)
	_refresh_image_input_summary_v0168()


func _choose_source_image_v0168() -> void:
	_source_dialog_v0168.popup_centered_ratio(0.75)


func _choose_mask_image_v0168() -> void:
	_mask_dialog_v0168.popup_centered_ratio(0.75)


func _choose_reference_images_v0168() -> void:
	_reference_dialog_v0168.popup_centered_ratio(0.75)


func _on_source_image_selected_v0168(path_text: String) -> void:
	_source_image_path_v0168 = path_text
	_source_image_id_v0168 = ""
	_refresh_image_input_summary_v0168()


func _on_mask_image_selected_v0168(path_text: String) -> void:
	_mask_image_path_v0168 = path_text
	_refresh_image_input_summary_v0168()


func _on_reference_images_selected_v0168(paths: PackedStringArray) -> void:
	_reference_image_paths_v0168.clear()
	for path_text in paths:
		var clean := str(path_text).strip_edges()
		if not clean.is_empty() and not clean in _reference_image_paths_v0168:
			_reference_image_paths_v0168.append(clean)
	_refresh_image_input_summary_v0168()


func _clear_source_image_v0168() -> void:
	_source_image_path_v0168 = ""
	_source_image_id_v0168 = ""
	_refresh_image_input_summary_v0168()


func _clear_mask_image_v0168() -> void:
	_mask_image_path_v0168 = ""
	_refresh_image_input_summary_v0168()


func _clear_reference_images_v0168() -> void:
	_reference_image_paths_v0168.clear()
	_refresh_image_input_summary_v0168()
