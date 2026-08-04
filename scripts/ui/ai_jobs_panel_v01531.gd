class_name CCFAIJobsPanelV01531
extends PanelContainer

signal cancel_requested(worker_id: String, cancel_job_id: String, record_id: String)

var _summary_label: Label
var _list: VBoxContainer
var _empty_label: Label


func _ready() -> void:
	_build_ui_v01531()


func set_jobs_v01531(records: Array, scheduler_snapshot: Dictionary) -> void:
	if _list == null:
		_build_ui_v01531()
	for child: Node in _list.get_children():
		child.queue_free()
	var running: int = int(scheduler_snapshot.get("running", 0))
	var waiting: int = int(scheduler_snapshot.get("waiting", 0))
	var counted: int = int(scheduler_snapshot.get("running_counted", 0))
	_summary_label.text = "%d running • %d scheduler-waiting • %d counted toward global limit" % [
		running, waiting, counted
	]
	if records.is_empty():
		_empty_label = Label.new()
		_empty_label.text = "No active or queued AI jobs."
		_empty_label.modulate = Color(0.68, 0.71, 0.8)
		_list.add_child(_empty_label)
		return
	for raw_record: Variant in records:
		if raw_record is Dictionary:
			_list.add_child(_build_job_row_v01531(raw_record))


func _build_ui_v01531() -> void:
	if _list != null:
		return
	custom_minimum_size.y = 180
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "AI Jobs"
	title.add_theme_font_size_override("font_size", 17)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_summary_label = Label.new()
	_summary_label.text = "AI queue: idle"
	_summary_label.modulate = Color(0.7, 0.74, 0.84)
	header.add_child(_summary_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 140
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 5)
	scroll.add_child(_list)


func _build_job_row_v01531(record: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var parent_id: String = str(record.get("parent_id", ""))
	var status: String = str(record.get("status", "queued"))
	var status_label := Label.new()
	status_label.custom_minimum_size.x = 128
	status_label.text = _status_text_v01531(status)
	status_label.modulate = _status_colour_v01531(status)
	row.add_child(status_label)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 2)
	row.add_child(body)
	var title := Label.new()
	title.text = ("↳ " if not parent_id.is_empty() else "") + str(
		record.get("label", "AI job")
	)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(title)

	var detail_parts: Array[String] = []
	var worker_label: String = str(record.get("worker_label", "")).strip_edges()
	if not worker_label.is_empty() and parent_id.is_empty():
		detail_parts.append(worker_label)
	var role: String = str(record.get("role", "")).strip_edges()
	if not role.is_empty():
		detail_parts.append(role.capitalize())
	var stage: String = str(record.get("stage", "")).strip_edges()
	if not stage.is_empty():
		detail_parts.append(stage)
	var profile_name: String = str(record.get("profile_name", "")).strip_edges()
	if not profile_name.is_empty():
		detail_parts.append(profile_name)
	var model: String = str(record.get("model", "")).strip_edges()
	if not model.is_empty():
		detail_parts.append(model)
	var detail: String = str(record.get("detail", "")).strip_edges()
	if not detail.is_empty():
		detail_parts.append(detail)
	var queue_position: int = int(record.get("queue_position", 0))
	if status == "queued" and queue_position > 0:
		detail_parts.append("Queue position %d" % queue_position)
	var detail_label := Label.new()
	detail_label.text = _join_strings_v01531(detail_parts, " • ")
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.modulate = Color(0.65, 0.69, 0.79)
	body.add_child(detail_label)

	if bool(record.get("can_cancel", false)):
		var cancel := Button.new()
		cancel.text = "Cancel Build" if not parent_id.is_empty() else "Cancel"
		cancel.tooltip_text = (
			"Cancel the parent Character build."
			if not parent_id.is_empty()
			else "Cancel only this AI job."
		)
		var worker_id: String = str(record.get("worker_id", ""))
		var cancel_job_id: String = str(
			record.get("cancel_job_id", record.get("job_id", ""))
		)
		var record_id: String = str(record.get("record_id", ""))
		cancel.pressed.connect(
			func(): cancel_requested.emit(worker_id, cancel_job_id, record_id)
		)
		row.add_child(cancel)
	return panel


func _status_text_v01531(status: String) -> String:
	match status:
		"running": return "RUNNING"
		"coordinating": return "COORDINATING"
		"waiting_capacity": return "WAITING FOR SLOT"
		"waiting_dependency": return "WAITING"
		"completed": return "COMPLETE"
		"queued": return "QUEUED"
		_: return status.replace("_", " ").to_upper()


func _status_colour_v01531(status: String) -> Color:
	match status:
		"running", "coordinating": return Color(0.55, 0.9, 0.64)
		"waiting_capacity", "waiting_dependency": return Color(0.96, 0.78, 0.42)
		"completed": return Color(0.55, 0.75, 0.95)
		"queued": return Color(0.75, 0.72, 0.9)
		_: return Color(0.8, 0.8, 0.85)


func _join_strings_v01531(values: Array[String], separator: String) -> String:
	var result: String = ""
	for index: int in range(values.size()):
		if index > 0:
			result += separator
		result += values[index]
	return result
