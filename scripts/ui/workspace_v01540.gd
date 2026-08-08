class_name CCFWorkspaceV01540View
extends "res://scripts/ui/workspace_v01539.gd"

const AI_ACTIVITY_LIVE_STATUSES_V01540 := [
	"running",
	"coordinating",
	"waiting_capacity",
	"queued",
	"waiting_dependency"
]

var _ai_activity_status_owned_v01540 := false
var _ai_activity_last_rendered_v01540 := ""
var _ai_activity_last_job_id_v01540 := ""
var _ai_activity_reconcile_pending_v01540 := false


func _on_job_started(job_id: String, job_type: String, label: String) -> void:
	super._on_job_started(job_id, job_type, label)
	_ai_activity_status_owned_v01540 = true
	_ai_activity_last_job_id_v01540 = job_id
	_ai_activity_last_rendered_v01540 = _status.text if _status != null else ""
	_schedule_ai_activity_reconcile_v01540()


func _on_job_completed(
	job_id: String,
	job_type: String,
	data: Variant,
	metadata: Dictionary
) -> void:
	var before_status := _status.text if _status != null else ""
	super._on_job_completed(job_id, job_type, data, metadata)
	_mark_external_status_if_changed_v01540(before_status)
	_schedule_ai_activity_reconcile_v01540()


func _on_job_failed(job_id: String, job_type: String, message: String) -> void:
	var before_status := _status.text if _status != null else ""
	super._on_job_failed(job_id, job_type, message)
	_mark_external_status_if_changed_v01540(before_status)
	_schedule_ai_activity_reconcile_v01540()


func _on_job_cancelled(job_id: String, job_type: String) -> void:
	var before_status := _status.text if _status != null else ""
	super._on_job_cancelled(job_id, job_type)
	_mark_external_status_if_changed_v01540(before_status)
	_schedule_ai_activity_reconcile_v01540()


func _on_worker_queue_changed_v01526(
	pending_count: int,
	active_job_id: String,
	active_label: String
) -> void:
	super._on_worker_queue_changed_v01526(
		pending_count,
		active_job_id,
		active_label
	)
	_schedule_ai_activity_reconcile_v01540()


func _on_scheduler_state_changed_v01526(snapshot: Dictionary) -> void:
	super._on_scheduler_state_changed_v01526(snapshot)
	_schedule_ai_activity_reconcile_v01540()


func _schedule_ai_activity_reconcile_v01540() -> void:
	if _ai_activity_reconcile_pending_v01540:
		return
	_ai_activity_reconcile_pending_v01540 = true
	call_deferred("_reconcile_workspace_ai_activity_v01540")


func _reconcile_workspace_ai_activity_v01540() -> void:
	_ai_activity_reconcile_pending_v01540 = false
	if _status == null:
		return
	var records := _live_ai_activity_records_v01540()
	_reconcile_workspace_ai_activity_from_records_v01540(records)


func _reconcile_workspace_ai_activity_from_records_v01540(records: Array) -> void:
	if _status == null:
		return
	var live_records: Array[Dictionary] = []
	for raw_record in records:
		if not raw_record is Dictionary:
			continue
		var record: Dictionary = raw_record
		if str(record.get("status", "")) not in AI_ACTIVITY_LIVE_STATUSES_V01540:
			continue
		live_records.append(record)

	if live_records.is_empty():
		if (
			_ai_activity_status_owned_v01540
			and _status.text == _ai_activity_last_rendered_v01540
		):
			_status.text = "Ready."
		_ai_activity_status_owned_v01540 = false
		_ai_activity_last_rendered_v01540 = ""
		_ai_activity_last_job_id_v01540 = ""
		return

	var selected := _select_ai_activity_record_v01540(live_records)
	if selected.is_empty():
		return
	var activity_text := _render_ai_activity_record_v01540(selected)
	if activity_text.is_empty():
		return
	_status.text = activity_text
	_ai_activity_status_owned_v01540 = true
	_ai_activity_last_rendered_v01540 = activity_text
	_ai_activity_last_job_id_v01540 = str(selected.get("job_id", ""))


func _live_ai_activity_records_v01540() -> Array:
	if not has_method("ai_job_records_v01531"):
		return []
	var records_value: Variant = call("ai_job_records_v01531")
	return records_value if records_value is Array else []


func _select_ai_activity_record_v01540(records: Array[Dictionary]) -> Dictionary:
	var selected: Dictionary = {}
	var selected_rank := 99999
	for record in records:
		var status := str(record.get("status", ""))
		# Lifecycle state is authoritative. Parent/child preference is only a
		# tie-breaker inside the same state so a genuinely running child still
		# outranks a merely coordinating or queued parent.
		var rank := _ai_activity_status_rank_v01540(status) * 100
		if not str(record.get("parent_id", "")).strip_edges().is_empty():
			rank += 10
		if str(record.get("job_type", "")) == "safe_section":
			rank += 10
		if rank >= selected_rank:
			continue
		selected = record
		selected_rank = rank
	return selected.duplicate(true)


func _ai_activity_status_rank_v01540(status: String) -> int:
	match status:
		"running":
			return 0
		"coordinating":
			return 1
		"waiting_capacity":
			return 2
		"queued":
			return 3
		"waiting_dependency":
			return 4
	return 100


func _render_ai_activity_record_v01540(record: Dictionary) -> String:
	var label := str(record.get("label", "")).strip_edges()
	if label.is_empty():
		label = str(record.get("worker_label", "AI job")).strip_edges()
	if label.is_empty():
		label = "AI job"
	match str(record.get("status", "")):
		"running":
			return "%s…" % label.trim_suffix("…").trim_suffix("...")
		"coordinating":
			return "%s — coordinating…" % label
		"waiting_capacity":
			return "%s — waiting for AI capacity…" % label
		"queued":
			return "%s — queued…" % label
		"waiting_dependency":
			return "%s — waiting for dependencies…" % label
	return ""


func _mark_external_status_if_changed_v01540(before_status: String) -> void:
	if _status == null:
		return
	if _status.text == before_status:
		return
	if _status.text == _ai_activity_last_rendered_v01540:
		return
	_ai_activity_status_owned_v01540 = false
	_ai_activity_last_rendered_v01540 = ""
	_ai_activity_last_job_id_v01540 = ""


func workspace_ai_activity_capabilities_v01540() -> Dictionary:
	return {
		"version": "0.15.40",
		"authoritative_ai_jobs_state": true,
		"clears_stale_activity_when_idle": true,
		"switches_to_remaining_live_job": true,
		"preserves_external_status_changes": true,
		"success_failure_cancel_reconciled": true,
		"queued_and_waiting_states_supported": true
	}
