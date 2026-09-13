class_name CCFExpressionSetWindowV0193
extends Window

signal create_requested(labels: Array, baseline_mode: String)
signal resume_requested(batch_id: String)
signal pause_requested(batch_id: String)
signal retry_requested(batch_id: String, label: String)
signal accept_requested(batch_id: String, label: String, replace_existing: bool)

const SERVICE = preload("res://scripts/services/expression_set_service_v0193.gd")

var _project: Dictionary = {}
var _character_id := ""
var _selected_batch_id := ""
var _baseline_availability: Dictionary = {}

var _baseline_selector: OptionButton
var _labels: ItemList
var _batch_selector: OptionButton
var _items: ItemList
var _preview: TextureRect
var _report: TextEdit
var _status: Label
var _create_button: Button
var _resume_button: Button
var _pause_button: Button
var _retry_button: Button
var _accept_button: Button
var _replace_button: Button
var _create_confirm: ConfirmationDialog
var _create_confirm_text: Label
var _replace_confirm: ConfirmationDialog
var _replace_confirm_text: Label
var _pending_create_labels: Array = []
var _pending_create_baseline := "prompt"
var _pending_replace_label := ""
var _pending_replace_batch_id := ""


func _ready() -> void:
	visible = false
	title = "Expression Set Generation"
	size = Vector2i(1180, 820)
	min_size = Vector2i(900, 640)
	force_native = true
	transient = true
	exclusive = false
	close_requested.connect(_hide_window)
	_build_ui()
	_build_confirmations()
	hide()


func open_for_context(project: Dictionary, character_id: String, baseline_availability: Dictionary) -> void:
	update_context(project, character_id, baseline_availability)
	CCFToolWindowStateService.show_window(self, "expression_set_v0193", Vector2i(1180, 820))


func update_context(project: Dictionary, character_id: String, baseline_availability: Dictionary = {}) -> void:
	_project = project.duplicate(true)
	_character_id = character_id
	_baseline_availability = baseline_availability.duplicate(true)
	_refresh_baselines()
	_refresh_batches()


func selected_batch_id() -> String:
	return _selected_batch_id


func capabilities_v0193() -> Dictionary:
	return SERVICE.capabilities()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	var heading := Label.new()
	heading.text = "Generate a reviewable expression set"
	heading.add_theme_font_size_override("font_size", 21)
	root.add_child(heading)
	var explanation := Label.new()
	explanation.text = "Choose exact Front Porch expression labels and a visible identity baseline. Each label runs as one ordinary Image Studio job. Results wait for individual approval and are never installed automatically."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.modulate = Color(0.72, 0.76, 0.85)
	root.add_child(explanation)

	var setup_panel := PanelContainer.new()
	root.add_child(setup_panel)
	var setup := VBoxContainer.new()
	setup.add_theme_constant_override("separation", 6)
	setup_panel.add_child(setup)
	var baseline_row := HFlowContainer.new()
	setup.add_child(baseline_row)
	var baseline_label := Label.new()
	baseline_label.text = "Visual identity baseline"
	baseline_row.add_child(baseline_label)
	_baseline_selector = OptionButton.new()
	_baseline_selector.custom_minimum_size.x = 390
	for entry in [
		{"label": "Current Image Studio prompt and style", "value": "prompt"},
		{"label": "Current character portrait as reference", "value": "portrait"},
		{"label": "Selected Image Studio result as source", "value": "selected_result"}
	]:
		_baseline_selector.add_item(str(entry.get("label", "Baseline")))
		_baseline_selector.set_item_metadata(_baseline_selector.item_count - 1, str(entry.get("value", "prompt")))
	baseline_row.add_child(_baseline_selector)
	var helper := Label.new()
	helper.text = "Reference/source choices are enabled only when the selected provider profile proves that operation is executable."
	helper.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	helper.modulate = Color(0.62, 0.7, 0.82)
	setup.add_child(helper)
	_labels = ItemList.new()
	_labels.name = "ExpressionSetLabelsV0193"
	_labels.select_mode = ItemList.SELECT_MULTI
	_labels.custom_minimum_size.y = 155
	for label_value in SERVICE.capabilities().get("supported_labels", []):
		_labels.add_item(str(label_value).capitalize())
		_labels.set_item_metadata(_labels.item_count - 1, str(label_value))
	setup.add_child(_labels)
	var selection_actions := HFlowContainer.new()
	setup.add_child(selection_actions)
	selection_actions.add_child(_button("Select Common Set", _select_common))
	selection_actions.add_child(_button("Select All", _select_all))
	selection_actions.add_child(_button("Clear", _clear_selection))
	_create_button = _button("Generate Selected Expressions…", _request_create)
	_create_button.name = "GenerateExpressionSetConfirmV0193"
	selection_actions.add_child(_create_button)

	var batch_row := HFlowContainer.new()
	root.add_child(batch_row)
	var batch_label := Label.new()
	batch_label.text = "Saved batch"
	batch_row.add_child(batch_label)
	_batch_selector = OptionButton.new()
	_batch_selector.custom_minimum_size.x = 430
	_batch_selector.item_selected.connect(_on_batch_selected)
	batch_row.add_child(_batch_selector)
	_resume_button = _button("Resume Remaining", _request_resume)
	batch_row.add_child(_resume_button)
	_pause_button = _button("Pause after Current", _request_pause)
	batch_row.add_child(_pause_button)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(split)
	_items = ItemList.new()
	_items.name = "ExpressionSetReviewItemsV0193"
	_items.custom_minimum_size.x = 330
	_items.item_selected.connect(_on_item_selected)
	split.add_child(_items)
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 7)
	split.add_child(detail)
	_preview = TextureRect.new()
	_preview.custom_minimum_size = Vector2(320, 280)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail.add_child(_preview)
	_report = TextEdit.new()
	_report.name = "ExpressionSetExactReportV0193"
	_report.editable = false
	_report.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_report.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(_report)
	var review_actions := HFlowContainer.new()
	detail.add_child(review_actions)
	_retry_button = _button("Retry Selected", _request_retry)
	review_actions.add_child(_retry_button)
	_accept_button = _button("Accept into Avatar Gallery", _request_accept)
	review_actions.add_child(_accept_button)
	_replace_button = _button("Replace Existing Label…", _request_replace)
	review_actions.add_child(_replace_button)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.68, 0.78, 0.9)
	root.add_child(_status)
	_refresh_review_actions()


func _refresh_baselines() -> void:
	if _baseline_selector == null:
		return
	for index in range(_baseline_selector.item_count):
		var baseline_mode := str(_baseline_selector.get_item_metadata(index))
		_baseline_selector.set_item_disabled(index, not bool(_baseline_availability.get(baseline_mode, baseline_mode == "prompt")))
	if _baseline_selector.selected < 0 or _baseline_selector.is_item_disabled(_baseline_selector.selected):
		_baseline_selector.select(0)


func _refresh_batches() -> void:
	if _batch_selector == null:
		return
	var previous := _selected_batch_id
	_batch_selector.clear()
	var character := CCFStorageService.get_character(_project, _character_id)
	var batches := SERVICE.batches_for_character(character)
	for reverse_index in range(batches.size() - 1, -1, -1):
		var batch: Dictionary = batches[reverse_index]
		var counts := SERVICE.status_counts(batch)
		_batch_selector.add_item("%s — %d review, %d accepted, %d failed" % [
			str(batch.get("created_at", "Batch")).replace("T", " "),
			int(counts.get(SERVICE.STATE_REVIEW, 0)),
			int(counts.get(SERVICE.STATE_ACCEPTED, 0)),
			int(counts.get(SERVICE.STATE_FAILED, 0)) + int(counts.get(SERVICE.STATE_CANCELLED, 0))
		])
		var item_index := _batch_selector.item_count - 1
		_batch_selector.set_item_metadata(item_index, str(batch.get("batch_id", "")))
		if str(batch.get("batch_id", "")) == previous:
			_batch_selector.select(item_index)
	if _batch_selector.item_count > 0:
		if _batch_selector.selected < 0:
			_batch_selector.select(0)
		_selected_batch_id = str(_batch_selector.get_selected_metadata())
	else:
		_selected_batch_id = ""
	_refresh_items()


func _refresh_items() -> void:
	_items.clear()
	_preview.texture = null
	_report.text = "Select an expression result to see its exact prompt, settings and status."
	var batch := SERVICE.batch_by_id(_project, _character_id, _selected_batch_id)
	for raw_item in batch.get("items", []):
		if not raw_item is Dictionary:
			continue
		var item := raw_item as Dictionary
		_items.add_item("%s  —  %s%s" % [
			str(item.get("label", "expression")).capitalize(),
			str(item.get("state", "queued")).capitalize(),
			" (attempt %d)" % int(item.get("attempts", 0)) if int(item.get("attempts", 0)) > 0 else ""
		])
		_items.set_item_metadata(_items.item_count - 1, item.duplicate(true))
	if _items.item_count > 0:
		_items.select(0)
		_on_item_selected(0)
	var counts := SERVICE.status_counts(batch)
	_status.text = "%d queued • %d generating • %d awaiting review • %d accepted • %d failed/cancelled. Accepted images can be installed or exported as a ZIP from Import / Export → Avatar Gallery." % [
		int(counts.get(SERVICE.STATE_QUEUED, 0)), int(counts.get(SERVICE.STATE_GENERATING, 0)),
		int(counts.get(SERVICE.STATE_REVIEW, 0)), int(counts.get(SERVICE.STATE_ACCEPTED, 0)),
		int(counts.get(SERVICE.STATE_FAILED, 0)) + int(counts.get(SERVICE.STATE_CANCELLED, 0))
	]
	_refresh_review_actions()


func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _items.item_count:
		return
	var item_value: Variant = _items.get_item_metadata(index)
	if not item_value is Dictionary:
		return
	var item := item_value as Dictionary
	var batch := SERVICE.batch_by_id(_project, _character_id, _selected_batch_id)
	var snapshot_value: Variant = batch.get("execution_snapshot", {})
	var snapshot: Dictionary = snapshot_value if snapshot_value is Dictionary else {}
	var result_value: Variant = item.get("result", {})
	var result: Dictionary = result_value if result_value is Dictionary else {}
	if not result.is_empty():
		snapshot = CCFImageResultWorkflowServiceV01610.snapshot_from_record(result)
	var recorded_seed: Variant = result.get("seed", snapshot.get("seed", -1))
	_report.text = "Expression: %s\nStatus: %s\nAttempts: %d\n\nExact prompt\n%s\n\nExecution settings\nProfile: %s\nBackend: %s\nModel: %s\nSize: %s\nSampler: %s\nSteps: %s\nCFG: %s\nSeed: %s\nOperation: %s\n\n%s" % [
		str(item.get("label", "")).capitalize(), str(item.get("state", "")).capitalize(), int(item.get("attempts", 0)),
		str(item.get("prompt", "")), str(snapshot.get("profile_name", "")), str(snapshot.get("backend", "")),
		str(snapshot.get("model", "")), str(snapshot.get("size", "")), str(snapshot.get("sampler", "")),
		str(snapshot.get("steps", "")), str(snapshot.get("cfg_scale", "")), str(recorded_seed),
		str(snapshot.get("image_operation", "text_to_image")), str(item.get("error", ""))
	]
	_preview.texture = _texture_for_record(result)
	_refresh_review_actions()


func _selected_item() -> Dictionary:
	var selected := _items.get_selected_items()
	if selected.is_empty():
		return {}
	var value: Variant = _items.get_item_metadata(int(selected[0]))
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _refresh_review_actions() -> void:
	if _retry_button == null:
		return
	var item := _selected_item()
	var state := str(item.get("state", ""))
	_retry_button.disabled = state not in [SERVICE.STATE_FAILED, SERVICE.STATE_CANCELLED, SERVICE.STATE_REVIEW]
	_accept_button.disabled = state != SERVICE.STATE_REVIEW
	_replace_button.disabled = state != SERVICE.STATE_REVIEW
	var has_batch := not _selected_batch_id.is_empty()
	_resume_button.disabled = not has_batch
	_pause_button.disabled = not has_batch


func _request_create() -> void:
	var selected_labels: Array = []
	for index_value in _labels.get_selected_items():
		selected_labels.append(str(_labels.get_item_metadata(int(index_value))))
	if selected_labels.is_empty():
		_status.text = "Choose at least one expression label."
		return
	_pending_create_labels = selected_labels.duplicate()
	_pending_create_baseline = str(_baseline_selector.get_selected_metadata())
	_create_confirm_text.text = "Generate %d separate provider requests for:\n\n%s\n\nBaseline: %s\n\nEvery result will wait for individual review; nothing is installed automatically." % [
		_pending_create_labels.size(), ", ".join(_pending_create_labels),
		_baseline_label(_pending_create_baseline)
	]
	_create_confirm.popup_centered(Vector2i(640, 360))


func _request_resume() -> void:
	if not _selected_batch_id.is_empty():
		resume_requested.emit(_selected_batch_id)


func _request_pause() -> void:
	if not _selected_batch_id.is_empty():
		pause_requested.emit(_selected_batch_id)


func _request_retry() -> void:
	var item := _selected_item()
	if not item.is_empty():
		retry_requested.emit(_selected_batch_id, str(item.get("label", "")))


func _request_accept() -> void:
	var item := _selected_item()
	if not item.is_empty():
		accept_requested.emit(_selected_batch_id, str(item.get("label", "")), false)


func _request_replace() -> void:
	var item := _selected_item()
	if not item.is_empty():
		_pending_replace_label = str(item.get("label", ""))
		_pending_replace_batch_id = _selected_batch_id
		_replace_confirm_text.text = "Replace the current Avatar Gallery association for %s with this reviewed result?\n\nThe previous generated image file will remain in Image Studio for recovery." % _pending_replace_label.capitalize()
		_replace_confirm.popup_centered(Vector2i(560, 260))


func _on_batch_selected(index: int) -> void:
	if index < 0:
		return
	_selected_batch_id = str(_batch_selector.get_item_metadata(index))
	_refresh_items()


func _select_common() -> void:
	_clear_selection()
	for index in range(_labels.item_count):
		if str(_labels.get_item_metadata(index)) in ["neutral", "joy", "sadness", "anger", "surprise", "fear"]:
			_labels.select(index, false)


func _select_all() -> void:
	for index in range(_labels.item_count):
		_labels.select(index, false)


func _clear_selection() -> void:
	_labels.deselect_all()


func _button(label_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label_text
	button.pressed.connect(callback)
	return button


func _build_confirmations() -> void:
	_create_confirm = ConfirmationDialog.new()
	_create_confirm.title = "Confirm Expression Set"
	_create_confirm.ok_button_text = "Start Managed Batch"
	_create_confirm.min_size = Vector2i(600, 320)
	_create_confirm_text = Label.new()
	_create_confirm_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_create_confirm.add_child(_create_confirm_text)
	_create_confirm.confirmed.connect(_confirm_create)
	add_child(_create_confirm)
	_create_confirm.hide()
	_replace_confirm = ConfirmationDialog.new()
	_replace_confirm.title = "Replace Existing Expression Label"
	_replace_confirm.ok_button_text = "Replace Association"
	_replace_confirm.min_size = Vector2i(520, 230)
	_replace_confirm_text = Label.new()
	_replace_confirm_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_replace_confirm.add_child(_replace_confirm_text)
	_replace_confirm.confirmed.connect(_confirm_replace)
	add_child(_replace_confirm)
	_replace_confirm.hide()


func _confirm_create() -> void:
	if not _pending_create_labels.is_empty():
		create_requested.emit(_pending_create_labels.duplicate(), _pending_create_baseline)


func _confirm_replace() -> void:
	if not _pending_replace_batch_id.is_empty() and not _pending_replace_label.is_empty():
		accept_requested.emit(_pending_replace_batch_id, _pending_replace_label, true)


func _baseline_label(baseline_mode: String) -> String:
	match baseline_mode:
		"portrait":
			return "Current character portrait as reference"
		"selected_result":
			return "Selected Image Studio result as source"
		_:
			return "Current Image Studio prompt and style"


func _texture_for_record(record: Dictionary) -> Texture2D:
	var stored_path := str(record.get("path", ""))
	if stored_path.is_empty():
		return null
	var resolved := CCFImageGenerationService.resolve_generated_image_path(str(_project.get("project_id", "")), stored_path)
	if resolved.is_empty() or not FileAccess.file_exists(resolved):
		return null
	var image := Image.load_from_file(resolved)
	return ImageTexture.create_from_image(image) if image != null and not image.is_empty() else null


func _hide_window() -> void:
	CCFToolWindowStateService.save_window(self, "expression_set_v0193")
	hide()
