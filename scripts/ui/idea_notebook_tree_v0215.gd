class_name CCFIdeaNotebookTreeV0215
extends Tree

signal hierarchy_drop(kind: String, item_id: String, destination_folder_id: String)


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
	if kind != "folder" and kind != "notebook":
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
	var kind := str((data as Dictionary).get("kind", ""))
	var item_id := str((data as Dictionary).get("id", ""))
	if (kind != "folder" and kind != "notebook") or item_id.is_empty():
		return false
	var item := get_item_at_position(at_position)
	if item == null:
		return true
	var metadata_value: Variant = item.get_metadata(0)
	if not metadata_value is Dictionary:
		return true
	var metadata: Dictionary = metadata_value
	var destination_kind := str(metadata.get("kind", ""))
	if destination_kind == "folder":
		return not (kind == "folder" and str(metadata.get("id", "")) == item_id)
	return destination_kind == "notebook" or destination_kind == "special"


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
			elif destination_kind == "notebook":
				destination_folder_id = str(metadata.get("parent_folder_id", ""))
	hierarchy_drop.emit(
		str(payload.get("kind", "")),
		str(payload.get("id", "")),
		destination_folder_id
	)
