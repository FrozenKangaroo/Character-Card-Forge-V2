class_name CCFIdeaNotebookTreeV0215
extends Tree

signal hierarchy_drop(kind: String, item_id: String, destination_folder_id: String)
signal idea_drop(idea_ids: Array[String], destination_folder_id: String)


func _ready() -> void:
	set_drop_mode_flags(Tree.DROP_MODE_ON_ITEM)


func _get_drag_data(at_position: Vector2) -> Variant:
	var item := get_item_at_position(at_position)
	if item == null:
		return null
	var metadata_value: Variant = item.get_metadata(0)
	if not metadata_value is Dictionary:
		return null
	var metadata: Dictionary = metadata_value
	var kind := str(metadata.get("kind", ""))
	if kind != "folder":
		return null
	var item_id := str(metadata.get("id", ""))
	if item_id.is_empty():
		return null
	var preview := Label.new()
	preview.text = item.get_text(0)
	preview.modulate = Color(0.88, 0.90, 1.0)
	set_drag_preview(preview)
	return {"kind": kind, "id": item_id}


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var item := get_item_at_position(at_position)
	if item == null:
		return can_accept_drop_metadata_v0217(data as Dictionary, {}, false)
	var metadata_value: Variant = item.get_metadata(0)
	if not metadata_value is Dictionary:
		return can_accept_drop_metadata_v0217(data as Dictionary, {}, true)
	return can_accept_drop_metadata_v0217(
		data as Dictionary, metadata_value as Dictionary, true
	)


func can_accept_drop_metadata_v0217(
	data: Dictionary, metadata: Dictionary, has_item: bool = true
) -> bool:
	var kind := str(data.get("kind", ""))
	var item_id := str(data.get("id", ""))
	var idea_ids_value: Variant = data.get("ids", [])
	var is_idea_batch := (
		kind == "ideas"
		and idea_ids_value is Array
		and not (idea_ids_value as Array).is_empty()
	)
	if not is_idea_batch and (kind != "folder" or item_id.is_empty()):
		return false
	if not has_item:
		return not is_idea_batch
	if metadata.is_empty():
		return true
	var destination_kind := str(metadata.get("kind", ""))
	if destination_kind == "folder":
		return not (kind == "folder" and str(metadata.get("id", "")) == item_id)
	if destination_kind == "special":
		var special_id := str(metadata.get("id", ""))
		return special_id == "__unfiled__" or (kind == "folder" and special_id == "__all__")
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data):
		return
	var payload: Dictionary = data
	var destination_folder_id := ""
	var item := get_item_at_position(at_position)
	if item != null:
		var metadata_value: Variant = item.get_metadata(0)
		if metadata_value is Dictionary:
			var metadata: Dictionary = metadata_value
			var destination_kind := str(metadata.get("kind", ""))
			if destination_kind == "folder":
				destination_folder_id = str(metadata.get("id", ""))
	if str(payload.get("kind", "")) == "ideas":
		var idea_ids: Array[String] = []
		for value in payload.get("ids", []):
			var idea_id := str(value).strip_edges()
			if not idea_id.is_empty() and not idea_id in idea_ids:
				idea_ids.append(idea_id)
		idea_drop.emit(idea_ids, destination_folder_id)
		return
	hierarchy_drop.emit(
		str(payload.get("kind", "")),
		str(payload.get("id", "")),
		destination_folder_id
	)
