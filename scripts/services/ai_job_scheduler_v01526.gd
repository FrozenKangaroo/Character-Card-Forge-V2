class_name CCFAIJobSchedulerV01526
extends Node

signal capacity_changed
signal state_changed(snapshot: Dictionary)

const FORMAT_VERSION := 1
const ROLE_TEXT := "text"
const ROLE_VISION := "vision"
const ROLE_IMAGE := "image"

var _config: Dictionary = default_config()
var _active: Dictionary = {}
var _waiting_order: Array[String] = []
var _waiting: Dictionary = {}


static func default_config() -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"max_total_jobs": 1,
		"max_text_jobs": 1,
		"max_vision_jobs": 1,
		"max_image_jobs": 1,
		"max_sections_per_character": 1,
		"parallel_safe_sections": false,
		"vision_counts_toward_total": true,
		"image_counts_toward_total": true
	}


static func normalise_config(value: Variant) -> Dictionary:
	var result := default_config()
	if value is Dictionary:
		result.merge(value, true)
	result["format_version"] = FORMAT_VERSION
	result["max_total_jobs"] = clampi(int(result.get("max_total_jobs", 1)), 1, 32)
	result["max_text_jobs"] = clampi(
		int(result.get("max_text_jobs", result["max_total_jobs"])), 1, 32
	)
	result["max_vision_jobs"] = clampi(int(result.get("max_vision_jobs", 1)), 1, 16)
	result["max_image_jobs"] = clampi(int(result.get("max_image_jobs", 1)), 1, 16)
	result["max_sections_per_character"] = clampi(
		int(result.get("max_sections_per_character", 1)), 1, 16
	)
	result["parallel_safe_sections"] = bool(result.get("parallel_safe_sections", false))
	result["vision_counts_toward_total"] = bool(
		result.get("vision_counts_toward_total", true)
	)
	result["image_counts_toward_total"] = bool(
		result.get("image_counts_toward_total", true)
	)
	return result


func configure(value: Variant) -> void:
	_config = normalise_config(value)
	_emit_state()
	capacity_changed.emit()


func config() -> Dictionary:
	return _config.duplicate(true)


func request_slot(
	worker_id: String,
	role: String,
	parent_id: String = "",
	counts_toward_total: Variant = null,
	label: String = ""
) -> bool:
	var clean_id := worker_id.strip_edges()
	if clean_id.is_empty():
		return false
	if _active.has(clean_id):
		return true
	var descriptor := _descriptor(clean_id, role, parent_id, counts_toward_total, label)
	_waiting[clean_id] = descriptor
	if clean_id not in _waiting_order:
		_waiting_order.append(clean_id)
	var first_eligible := _first_eligible_waiter()
	if first_eligible != clean_id:
		_emit_state()
		return false
	_waiting.erase(clean_id)
	_waiting_order.erase(clean_id)
	_active[clean_id] = descriptor
	_emit_state()
	return true


func release_slot(worker_id: String) -> void:
	var clean_id := worker_id.strip_edges()
	var changed := false
	if _active.has(clean_id):
		_active.erase(clean_id)
		changed = true
	if _waiting.has(clean_id):
		_waiting.erase(clean_id)
		changed = true
	if clean_id in _waiting_order:
		_waiting_order.erase(clean_id)
		changed = true
	if not changed:
		return
	_emit_state()
	capacity_changed.emit()


func cancel_wait(worker_id: String) -> void:
	var clean_id := worker_id.strip_edges()
	var changed := false
	if _waiting.has(clean_id):
		_waiting.erase(clean_id)
		changed = true
	if clean_id in _waiting_order:
		_waiting_order.erase(clean_id)
		changed = true
	if changed:
		_emit_state()
		capacity_changed.emit()


func has_slot(worker_id: String) -> bool:
	return _active.has(worker_id)


func snapshot() -> Dictionary:
	var by_role := {ROLE_TEXT: 0, ROLE_VISION: 0, ROLE_IMAGE: 0}
	var total_counted := 0
	var by_parent: Dictionary = {}
	for descriptor_value in _active.values():
		if not descriptor_value is Dictionary:
			continue
		var descriptor: Dictionary = descriptor_value
		var role := str(descriptor.get("role", ROLE_TEXT))
		by_role[role] = int(by_role.get(role, 0)) + 1
		if bool(descriptor.get("counts_toward_total", true)):
			total_counted += 1
		var parent_id := str(descriptor.get("parent_id", ""))
		if not parent_id.is_empty():
			by_parent[parent_id] = int(by_parent.get(parent_id, 0)) + 1
	return {
		"format_version": FORMAT_VERSION,
		"running": _active.size(),
		"running_counted": total_counted,
		"waiting": _waiting_order.size(),
		"by_role": by_role,
		"by_parent": by_parent,
		"active": _active.duplicate(true),
		"waiting_descriptors": _waiting.duplicate(true),
		"config": _config.duplicate(true)
	}


func _descriptor(
	worker_id: String,
	role_value: String,
	parent_id: String,
	counts_toward_total: Variant,
	label: String
) -> Dictionary:
	var role := role_value.strip_edges().to_lower()
	if role not in [ROLE_TEXT, ROLE_VISION, ROLE_IMAGE]:
		role = ROLE_TEXT
	var counts := true
	if counts_toward_total is bool:
		counts = bool(counts_toward_total)
	elif role == ROLE_VISION:
		counts = bool(_config.get("vision_counts_toward_total", true))
	elif role == ROLE_IMAGE:
		counts = bool(_config.get("image_counts_toward_total", true))
	return {
		"worker_id": worker_id,
		"role": role,
		"parent_id": parent_id.strip_edges(),
		"counts_toward_total": counts,
		"label": label.strip_edges()
	}


func _first_eligible_waiter() -> String:
	for worker_id in _waiting_order:
		var descriptor_value: Variant = _waiting.get(worker_id, {})
		if descriptor_value is Dictionary and _has_capacity(descriptor_value):
			return worker_id
	return ""


func _has_capacity(descriptor: Dictionary) -> bool:
	var state := snapshot()
	var role := str(descriptor.get("role", ROLE_TEXT))
	var by_role_value: Variant = state.get("by_role", {})
	var by_role: Dictionary = by_role_value if by_role_value is Dictionary else {}
	var role_limit := int(_config.get("max_text_jobs", 1))
	if role == ROLE_VISION:
		role_limit = int(_config.get("max_vision_jobs", 1))
	elif role == ROLE_IMAGE:
		role_limit = int(_config.get("max_image_jobs", 1))
	if int(by_role.get(role, 0)) >= role_limit:
		return false
	if bool(descriptor.get("counts_toward_total", true)):
		if int(state.get("running_counted", 0)) >= int(_config.get("max_total_jobs", 1)):
			return false
	var parent_id := str(descriptor.get("parent_id", ""))
	if not parent_id.is_empty():
		var by_parent_value: Variant = state.get("by_parent", {})
		var by_parent: Dictionary = by_parent_value if by_parent_value is Dictionary else {}
		if int(by_parent.get(parent_id, 0)) >= int(
			_config.get("max_sections_per_character", 1)
		):
			return false
	return true


func _emit_state() -> void:
	state_changed.emit(snapshot())
