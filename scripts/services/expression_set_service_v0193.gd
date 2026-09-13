class_name CCFExpressionSetServiceV0193
extends RefCounted

const FORMAT_VERSION := 1
const WORKFLOW_KEY := "expression_set_workflow_v0193"
const MAX_BATCH_HISTORY := 12
const DIRECTIONS_PATH := "res://data/expression_directions_v0193.json"
const GALLERY_SERVICE = preload(
	"res://scripts/services/front_porch_avatar_gallery_service_v0175.gd"
)

const STATE_QUEUED := "queued"
const STATE_GENERATING := "generating"
const STATE_REVIEW := "review"
const STATE_ACCEPTED := "accepted"
const STATE_FAILED := "failed"
const STATE_CANCELLED := "cancelled"


static func capabilities() -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"managed_image_studio_queue": true,
		"supported_labels": GALLERY_SERVICE.EMOTION_LABELS.duplicate(),
		"explicit_visual_baseline": true,
		"per_expression_review": true,
		"failed_member_only_retry": true,
		"avatar_gallery_destination": true,
		"parallel_image_store": false,
		"front_porch_zip_and_install_reused": true
	}


static func directions() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIRECTIONS_PATH))
	if not parsed is Dictionary:
		return {}
	var labels_value: Variant = (parsed as Dictionary).get("labels", {})
	return (labels_value as Dictionary).duplicate(true) if labels_value is Dictionary else {}


static func compose_prompt(base_prompt: String, label: String) -> String:
	var clean_label := label.strip_edges().to_lower()
	var direction := str(directions().get(clean_label, clean_label)).strip_edges()
	return "%s\n\nExpression-set direction: Keep the same character identity, design, clothing, framing, lighting, background and art style. Change only the face and subtle pose as needed to show %s. Produce one finished image with no text, labels, collage or contact sheet." % [base_prompt.strip_edges(), direction]


static func create_batch(
	project: Dictionary,
	character_id: String,
	labels: Array,
	baseline: Dictionary,
	execution_snapshot: Dictionary
) -> Dictionary:
	var character_index := CCFStorageService.character_index(project, character_id)
	if character_index < 0:
		return {"ok": false, "error": "The active character could not be found."}
	var clean_labels: Array[String] = []
	for raw_label in labels:
		var clean_label := str(raw_label).strip_edges().to_lower()
		if clean_label in GALLERY_SERVICE.EMOTION_LABELS and clean_label not in clean_labels:
			clean_labels.append(clean_label)
	if clean_labels.is_empty():
		return {"ok": false, "error": "Choose at least one supported expression."}
	var base_prompt := str(execution_snapshot.get("composed_prompt", "")).strip_edges()
	if base_prompt.is_empty():
		return {"ok": false, "error": "The current Image Studio prompt is empty."}
	var now := Time.get_datetime_string_from_system(true)
	var batch_id := "expressions_%s_%s" % [int(Time.get_unix_time_from_system()), randi_range(100000, 999999)]
	var items: Array = []
	for clean_label in clean_labels:
		items.append({
			"label": clean_label,
			"prompt": compose_prompt(base_prompt, clean_label),
			"state": STATE_QUEUED,
			"attempts": 0,
			"result": {},
			"error": "",
			"gallery_id": ""
		})
	var batch := {
		"format_version": FORMAT_VERSION,
		"batch_id": batch_id,
		"character_id": character_id,
		"created_at": now,
		"updated_at": now,
		"paused": false,
		"baseline": baseline.duplicate(true),
		"execution_snapshot": execution_snapshot.duplicate(true),
		"items": items
	}
	var updated := project.duplicate(true)
	var characters: Array = updated.get("characters", []).duplicate(true)
	var character: Dictionary = (characters[character_index] as Dictionary).duplicate(true)
	var workflow := _workflow(character)
	var batches: Array = workflow.get("batches", []).duplicate(true)
	batches.append(batch)
	while batches.size() > MAX_BATCH_HISTORY:
		batches.pop_front()
	workflow["batches"] = batches
	workflow["active_batch_id"] = batch_id
	character[WORKFLOW_KEY] = workflow
	characters[character_index] = character
	updated["characters"] = characters
	return {"ok": true, "project": updated, "batch": batch}


static func batches_for_character(character: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_batch in _workflow(character).get("batches", []):
		if raw_batch is Dictionary:
			result.append((raw_batch as Dictionary).duplicate(true))
	return result


static func batch_by_id(project: Dictionary, character_id: String, batch_id: String) -> Dictionary:
	var character := CCFStorageService.get_character(project, character_id)
	for batch in batches_for_character(character):
		if str(batch.get("batch_id", "")) == batch_id:
			return batch
	return {}


static func active_batch(project: Dictionary, character_id: String) -> Dictionary:
	var character := CCFStorageService.get_character(project, character_id)
	return batch_by_id(project, character_id, str(_workflow(character).get("active_batch_id", "")))


static func next_queued_item(batch: Dictionary) -> Dictionary:
	if bool(batch.get("paused", false)):
		return {}
	for raw_item in batch.get("items", []):
		if raw_item is Dictionary and str((raw_item as Dictionary).get("state", "")) == STATE_QUEUED:
			return (raw_item as Dictionary).duplicate(true)
	return {}


static func set_paused(project: Dictionary, character_id: String, batch_id: String, paused: bool) -> Dictionary:
	return _mutate_batch(project, character_id, batch_id, func(batch: Dictionary) -> Dictionary:
		batch["paused"] = paused
		return batch
	)


static func mark_generating(project: Dictionary, character_id: String, batch_id: String, label: String) -> Dictionary:
	return _mutate_item(project, character_id, batch_id, label, func(item: Dictionary) -> Dictionary:
		item["state"] = STATE_GENERATING
		item["attempts"] = int(item.get("attempts", 0)) + 1
		item["error"] = ""
		return item
	)


static func attach_result(project: Dictionary, character_id: String, batch_id: String, label: String, result_record: Dictionary) -> Dictionary:
	return _mutate_item(project, character_id, batch_id, label, func(item: Dictionary) -> Dictionary:
		item["state"] = STATE_REVIEW
		item["result"] = result_record.duplicate(true)
		item["error"] = ""
		return item
	)


static func mark_failed(project: Dictionary, character_id: String, batch_id: String, label: String, error_text: String, cancelled := false) -> Dictionary:
	return _mutate_item(project, character_id, batch_id, label, func(item: Dictionary) -> Dictionary:
		item["state"] = STATE_CANCELLED if cancelled else STATE_FAILED
		item["error"] = error_text.strip_edges()
		return item
	)


static func retry_item(project: Dictionary, character_id: String, batch_id: String, label: String) -> Dictionary:
	return _mutate_item(project, character_id, batch_id, label, func(item: Dictionary) -> Dictionary:
		if str(item.get("state", "")) in [STATE_FAILED, STATE_CANCELLED, STATE_REVIEW]:
			item["state"] = STATE_QUEUED
			item["result"] = {}
			item["error"] = ""
			item["gallery_id"] = ""
		return item
	)


static func accept_item(project: Dictionary, character_id: String, batch_id: String, label: String, replace_existing := false) -> Dictionary:
	var batch := batch_by_id(project, character_id, batch_id)
	var item := _item_by_label(batch, label)
	var result_value: Variant = item.get("result", {})
	if str(item.get("state", "")) != STATE_REVIEW or not result_value is Dictionary:
		return {"ok": false, "error": "The selected expression has no result awaiting review."}
	var working_project := project.duplicate(true)
	var existing_ids: Array[String] = []
	for entry in GALLERY_SERVICE.entries_for_character(CCFStorageService.get_character(working_project, character_id)):
		if str(entry.get("kind", "")) == "expression" and str(entry.get("label", "")) == label:
			existing_ids.append(str(entry.get("gallery_id", "")))
	if not existing_ids.is_empty() and not replace_existing:
		return {"ok": false, "needs_replace": true, "error": "The Avatar Gallery already has a %s expression. Choose Replace Existing to continue." % label}
	if replace_existing:
		for gallery_id in existing_ids:
			var removal := GALLERY_SERVICE.remove_entry(working_project, character_id, gallery_id)
			if not bool(removal.get("ok", false)):
				return removal
			working_project = (removal.get("project", {}) as Dictionary).duplicate(true)
	var result_record := (result_value as Dictionary).duplicate(true)
	var addition := GALLERY_SERVICE.add_source(working_project, character_id, {
		"kind": "image_studio_expression_set_v0193",
		"path": str(result_record.get("path", "")),
		"source_record": result_record
	}, "expression", label)
	if not bool(addition.get("ok", false)):
		return addition
	working_project = (addition.get("project", {}) as Dictionary).duplicate(true)
	var gallery_entry: Dictionary = addition.get("entry", {})
	var mutation := _mutate_item(working_project, character_id, batch_id, label, func(updated_item: Dictionary) -> Dictionary:
		updated_item["state"] = STATE_ACCEPTED
		updated_item["gallery_id"] = str(gallery_entry.get("gallery_id", ""))
		updated_item["error"] = ""
		return updated_item
	)
	if not bool(mutation.get("ok", false)):
		return mutation
	mutation["entry"] = gallery_entry
	mutation["replaced_gallery_ids"] = existing_ids
	return mutation


static func status_counts(batch: Dictionary) -> Dictionary:
	var counts := {STATE_QUEUED: 0, STATE_GENERATING: 0, STATE_REVIEW: 0, STATE_ACCEPTED: 0, STATE_FAILED: 0, STATE_CANCELLED: 0}
	for raw_item in batch.get("items", []):
		if raw_item is Dictionary:
			var state := str((raw_item as Dictionary).get("state", ""))
			if counts.has(state):
				counts[state] = int(counts[state]) + 1
	return counts


static func _workflow(character: Dictionary) -> Dictionary:
	var value: Variant = character.get(WORKFLOW_KEY, {})
	var workflow := (value as Dictionary).duplicate(true) if value is Dictionary else {}
	workflow["format_version"] = FORMAT_VERSION
	if not workflow.get("batches", []) is Array:
		workflow["batches"] = []
	workflow["active_batch_id"] = str(workflow.get("active_batch_id", ""))
	return workflow


static func _item_by_label(batch: Dictionary, label: String) -> Dictionary:
	for raw_item in batch.get("items", []):
		if raw_item is Dictionary and str((raw_item as Dictionary).get("label", "")) == label:
			return (raw_item as Dictionary).duplicate(true)
	return {}


static func _mutate_item(project: Dictionary, character_id: String, batch_id: String, label: String, mutator: Callable) -> Dictionary:
	return _mutate_batch(project, character_id, batch_id, func(batch: Dictionary) -> Dictionary:
		var items: Array = batch.get("items", []).duplicate(true)
		var found := false
		for index in range(items.size()):
			if items[index] is Dictionary and str((items[index] as Dictionary).get("label", "")) == label:
				items[index] = mutator.call((items[index] as Dictionary).duplicate(true))
				found = true
				break
		if found:
			batch["items"] = items
		else:
			batch["mutation_error"] = "The selected expression is no longer in this batch."
		return batch
	)


static func _mutate_batch(project: Dictionary, character_id: String, batch_id: String, mutator: Callable) -> Dictionary:
	var character_index := CCFStorageService.character_index(project, character_id)
	if character_index < 0:
		return {"ok": false, "error": "The active character could not be found."}
	var updated := project.duplicate(true)
	var characters: Array = updated.get("characters", []).duplicate(true)
	var character: Dictionary = (characters[character_index] as Dictionary).duplicate(true)
	var workflow := _workflow(character)
	var batches: Array = workflow.get("batches", []).duplicate(true)
	var found := false
	var updated_batch: Dictionary = {}
	for index in range(batches.size()):
		if batches[index] is Dictionary and str((batches[index] as Dictionary).get("batch_id", "")) == batch_id:
			updated_batch = mutator.call((batches[index] as Dictionary).duplicate(true))
			if updated_batch.has("mutation_error"):
				return {"ok": false, "error": str(updated_batch.get("mutation_error", "Could not update the expression."))}
			updated_batch["updated_at"] = Time.get_datetime_string_from_system(true)
			batches[index] = updated_batch
			found = true
			break
	if not found:
		return {"ok": false, "error": "The selected expression batch could not be found."}
	workflow["batches"] = batches
	workflow["active_batch_id"] = batch_id
	character[WORKFLOW_KEY] = workflow
	characters[character_index] = character
	updated["characters"] = characters
	return {"ok": true, "project": updated, "batch": updated_batch}
