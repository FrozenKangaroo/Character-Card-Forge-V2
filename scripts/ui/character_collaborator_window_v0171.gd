class_name CCFCharacterCollaboratorWindowV0171
extends "res://scripts/ui/character_collaborator_window_v0170.gd"

const PRECEDENCE_SERVICE_V0171 = preload(
	"res://scripts/services/collaborator_source_precedence_service_v0171.gd"
)

var _precedence_panel_v0171: PanelContainer
var _precedence_summary_v0171: Label
var _precedence_roles_v0171: VBoxContainer
var _precedence_notices_v0171: Label
var _evidence_review_dialog_v0171: AcceptDialog
var _evidence_review_text_v0171: TextEdit
var _stream_job_id_v02112 := ""
var _stream_reply_v02112 := ""
var _stream_phase_v02112 := ""


func set_generation_service(service: CCFGenerationService) -> void:
	var previous := _generation_service
	if previous != null:
		if previous.job_stream_delta.is_connected(_on_stream_delta_v02112):
			previous.job_stream_delta.disconnect(_on_stream_delta_v02112)
		if previous.job_stream_reset.is_connected(_on_stream_reset_v02112):
			previous.job_stream_reset.disconnect(_on_stream_reset_v02112)
		if previous.job_phase_changed.is_connected(_on_stream_phase_v02112):
			previous.job_phase_changed.disconnect(_on_stream_phase_v02112)
	super.set_generation_service(service)
	if _generation_service != null:
		_generation_service.job_stream_delta.connect(_on_stream_delta_v02112)
		_generation_service.job_stream_reset.connect(_on_stream_reset_v02112)
		_generation_service.job_phase_changed.connect(_on_stream_phase_v02112)


func _on_generation_started(job_id: String, job_type: String, label: String) -> void:
	if job_type == "collaborator_reply":
		_stream_job_id_v02112 = job_id
		_stream_reply_v02112 = ""
		_stream_phase_v02112 = "generating"
	super._on_generation_started(job_id, job_type, label)


func _on_generation_completed(
	job_id: String, job_type: String, data: Variant, metadata: Dictionary
) -> void:
	_clear_stream_reply_v02112(job_id)
	super._on_generation_completed(job_id, job_type, data, metadata)


func _on_generation_failed(job_id: String, job_type: String, message: String) -> void:
	_clear_stream_reply_v02112(job_id)
	super._on_generation_failed(job_id, job_type, message)


func _working_text_v0153() -> String:
	if (
		_active_collaborator_job_type_v0153 == "collaborator_reply"
		and not _stream_reply_v02112.is_empty()
	):
		var state := "Checking completed reply…" if _stream_phase_v02112 == "checking" else "Character Collaborator is writing…"
		return "%s\n\n%s\n\nProvisional — not yet saved" % [state, _stream_reply_v02112]
	return super._working_text_v0153()


func _on_stream_delta_v02112(
	job_id: String, job_type: String, text_delta: String, _metadata: Dictionary
) -> void:
	if job_id != _stream_job_id_v02112 or job_type != "collaborator_reply":
		return
	_stream_reply_v02112 += text_delta
	_refresh_chat()


func _on_stream_reset_v02112(
	job_id: String, job_type: String, _metadata: Dictionary
) -> void:
	if job_id != _stream_job_id_v02112 or job_type != "collaborator_reply":
		return
	_stream_reply_v02112 = ""
	_stream_phase_v02112 = "generating"
	_refresh_chat()


func _on_stream_phase_v02112(
	job_id: String, job_type: String, phase: String, _metadata: Dictionary
) -> void:
	if job_id != _stream_job_id_v02112 or job_type != "collaborator_reply":
		return
	_stream_phase_v02112 = phase
	if phase in ["checking", "streaming"]:
		_refresh_chat()


func _clear_stream_reply_v02112(job_id: String) -> void:
	if job_id != _stream_job_id_v02112:
		return
	_stream_job_id_v02112 = ""
	_stream_reply_v02112 = ""
	_stream_phase_v02112 = ""


func _ready() -> void:
	super._ready()
	_install_precedence_surface_v0171()
	_refresh_source_panel_v01533()


func _refresh_all() -> void:
	super._refresh_all()
	_refresh_source_panel_v01533()


func collaborator_source_capabilities_v01533() -> Dictionary:
	var result := super.collaborator_source_capabilities_v01533()
	result.merge(PRECEDENCE_SERVICE_V0171.capabilities(), true)
	return result


func source_precedence_capabilities_v0171() -> Dictionary:
	return PRECEDENCE_SERVICE_V0171.capabilities()


func precedence_surface_ready_v0171() -> bool:
	return (
		_precedence_panel_v0171 != null
		and is_instance_valid(_precedence_panel_v0171)
		and _precedence_panel_v0171.is_inside_tree()
		and _precedence_summary_v0171 != null
		and _precedence_roles_v0171 != null
		and _precedence_notices_v0171 != null
		and _evidence_review_dialog_v0171 != null
	)


func precedence_surface_snapshot_v0171() -> Dictionary:
	var session := _active_session()
	return PRECEDENCE_SERVICE_V0171.presentation(
		active_source_contexts_v01537(),
		session.get("context_items", [])
	)


func _context_blocks() -> Array[String]:
	var result := super._context_blocks()
	var session := _active_session()
	var block := PRECEDENCE_SERVICE_V0171.model_precedence_block(
		active_source_contexts_v01537(),
		session.get("context_items", [])
	)
	if not block.is_empty():
		result.push_front(block)
	return result


func _refresh_source_panel_v01533() -> void:
	super._refresh_source_panel_v01533()
	if _source_panel_v01533 == null:
		return
	if _precedence_panel_v0171 == null:
		return
	var sources := active_source_contexts_v01537()
	_precedence_panel_v0171.visible = not sources.is_empty()
	if sources.is_empty():
		return
	var session := _active_session()
	var view := PRECEDENCE_SERVICE_V0171.presentation(
		sources, session.get("context_items", [])
	)
	var rows_value: Variant = view.get("rows", [])
	var rows: Array = rows_value as Array if rows_value is Array else []
	var target_note := (
		"One explicit target; all other sources remain references."
		if bool(view.get("has_target", false))
		else "No existing character target; every source is reference-only."
	)
	_precedence_summary_v0171.text = (
		"%d source%s • %s Evidence roles describe how each source should be used; they never rewrite stored data."
		% [
			int(view.get("source_count", 0)),
			"" if int(view.get("source_count", 0)) == 1 else "s",
			target_note
		]
	)
	var notices_value: Variant = view.get("notices", [])
	var notices: Array = notices_value as Array if notices_value is Array else []
	if notices.is_empty():
		_precedence_notices_v0171.text = (
			"No cross-evidence review flags. Conflicting details must still be surfaced rather than silently blended."
		)
	else:
		var notice_lines: Array[String] = ["Review before resolving:"]
		for raw_notice in notices:
			notice_lines.append("• %s" % str(raw_notice))
		_precedence_notices_v0171.text = "\n".join(notice_lines)
	_refresh_evidence_role_list_v0171(rows)
	_apply_evidence_roles_to_source_rows_v0171(rows)


func _install_precedence_surface_v0171() -> void:
	if _precedence_panel_v0171 != null and is_instance_valid(_precedence_panel_v0171):
		return
	if _source_panel_v01533 == null:
		return
	_precedence_panel_v0171 = PanelContainer.new()
	_precedence_panel_v0171.name = "CollaboratorEvidenceRolesPanelV0171"
	_precedence_panel_v0171.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	_precedence_panel_v0171.add_child(stack)
	var heading := Label.new()
	heading.text = "Evidence roles & conflict review"
	heading.add_theme_font_size_override("font_size", 15)
	stack.add_child(heading)
	_precedence_summary_v0171 = Label.new()
	_precedence_summary_v0171.name = "CollaboratorEvidenceRoleSummaryV0171"
	_precedence_summary_v0171.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_precedence_summary_v0171)
	_precedence_roles_v0171 = VBoxContainer.new()
	_precedence_roles_v0171.name = "CollaboratorEvidenceRoleListV0171"
	_precedence_roles_v0171.add_theme_constant_override("separation", 4)
	stack.add_child(_precedence_roles_v0171)
	_precedence_notices_v0171 = Label.new()
	_precedence_notices_v0171.name = "CollaboratorEvidenceConflictNoticesV0171"
	_precedence_notices_v0171.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_precedence_notices_v0171.modulate = Color(0.92, 0.76, 0.42)
	stack.add_child(_precedence_notices_v0171)
	_source_panel_v01533.add_child(_precedence_panel_v0171)
	if _multi_source_list_v01537 != null:
		_source_panel_v01533.move_child(
			_precedence_panel_v0171, _multi_source_list_v01537.get_index()
		)

	_evidence_review_dialog_v0171 = AcceptDialog.new()
	_evidence_review_dialog_v0171.name = "CollaboratorEvidenceReviewDialogV0171"
	_evidence_review_dialog_v0171.title = "Review Structured Source and Vision Evidence"
	_evidence_review_dialog_v0171.min_size = Vector2i(900, 680)
	add_child(_evidence_review_dialog_v0171)
	_evidence_review_text_v0171 = TextEdit.new()
	_evidence_review_text_v0171.name = "CollaboratorEvidenceReviewTextV0171"
	_evidence_review_text_v0171.editable = false
	_evidence_review_text_v0171.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_evidence_review_text_v0171.custom_minimum_size = Vector2(850, 610)
	_evidence_review_dialog_v0171.add_child(_evidence_review_text_v0171)
	_evidence_review_dialog_v0171.hide()


func _refresh_evidence_role_list_v0171(rows: Array) -> void:
	if _precedence_roles_v0171 == null:
		return
	for child in _precedence_roles_v0171.get_children():
		_precedence_roles_v0171.remove_child(child)
		child.queue_free()
	for raw_row in rows:
		if not raw_row is Dictionary:
			continue
		var row: Dictionary = raw_row
		var card := PanelContainer.new()
		card.set_meta(
			"source_context_id", str(row.get("source_context_id", ""))
		)
		_precedence_roles_v0171.add_child(card)
		var stack := VBoxContainer.new()
		card.add_child(stack)
		var heading := Label.new()
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		heading.text = "%s • %s • %s%s" % [
			str(row.get("evidence_role_label", "REFERENCE")),
			str(row.get("display_type", "Source")),
			str(row.get("label", "Source material")),
			(
				" • VISION OBSERVATION LINKED"
				if int(row.get("linked_vision_count", 0)) > 0
				else ""
			)
		]
		stack.add_child(heading)
		var explanation := Label.new()
		explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		explanation.text = str(row.get("explanation", ""))
		explanation.modulate = Color(0.68, 0.74, 0.84)
		stack.add_child(explanation)
		if not bool(row.get("review_available", false)):
			continue
		var review := Button.new()
		review.name = "ReviewEvidenceV0171"
		review.text = "Review Evidence…"
		review.tooltip_text = (
			"Compare the structured/raw source snapshot with its separately linked Vision observation. No conflict is resolved automatically."
		)
		review.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		review.pressed.connect(
			_open_evidence_review_v0171.bind(
				str(row.get("source_context_id", ""))
			)
		)
		stack.add_child(review)


func _apply_evidence_roles_to_source_rows_v0171(rows: Array) -> void:
	if _multi_source_list_v01537 == null:
		return
	var rows_by_id := {}
	for raw_row in rows:
		if raw_row is Dictionary:
			rows_by_id[str((raw_row as Dictionary).get("source_context_id", ""))] = raw_row
	for child in _multi_source_list_v01537.get_children():
		if child.is_queued_for_deletion() or not child.has_meta("source_context_id"):
			continue
		var source_id := str(child.get_meta("source_context_id", ""))
		var row_value: Variant = rows_by_id.get(source_id, {})
		if not row_value is Dictionary:
			continue
		var row: Dictionary = row_value
		var label := child.find_child("SourceLabelV01540Hotfix2", true, false) as Label
		if label == null:
			label = child.find_child("SourceLabelV01540Hotfix1", true, false) as Label
		if label != null:
			label.text = "%s • %s • %s • %s" % [
				str(row.get("evidence_role_label", "REFERENCE")),
				str(row.get("source_role", "reference")).to_upper(),
				str(row.get("display_type", "Source")),
				str(row.get("label", "Source material"))
			]
			if int(row.get("linked_vision_count", 0)) > 0:
				label.text += " • Vision linked • VISION OBSERVATION"


func _open_evidence_review_v0171(source_context_id: String) -> void:
	var selected_source: Dictionary = {}
	for source in active_source_contexts_v01537():
		if str(source.get("source_context_id", "")) == source_context_id:
			selected_source = source
			break
	if selected_source.is_empty():
		_status.text = "The selected evidence source is no longer available."
		return
	var session := _active_session()
	_evidence_review_text_v0171.text = PRECEDENCE_SERVICE_V0171.evidence_review_text(
		selected_source, session.get("context_items", [])
	)
	_evidence_review_dialog_v0171.popup_centered(Vector2i(920, 700))
