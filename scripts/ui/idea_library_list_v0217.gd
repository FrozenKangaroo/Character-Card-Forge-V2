class_name CCFIdeaLibraryListV0217
extends ItemList


func _get_drag_data(at_position: Vector2) -> Variant:
	var index := get_item_at_position(at_position, true)
	if index < 0:
		return null
	var idea_ids := drag_idea_ids_for_index_v0217(index)
	if idea_ids.is_empty():
		return null
	var preview := Label.new()
	preview.text = (
		get_item_text(index).get_slice("\n", 0)
		if idea_ids.size() == 1
		else "%d selected Ideas" % idea_ids.size()
	)
	preview.modulate = Color(0.88, 0.90, 1.0)
	set_drag_preview(preview)
	return {"kind": "ideas", "ids": idea_ids}


func drag_idea_ids_for_index_v0217(index: int) -> Array[String]:
	var idea_ids: Array[String] = []
	if index < 0 or index >= item_count:
		return idea_ids
	if not is_selected(index):
		deselect_all()
		select(index)
	for selected_value in get_selected_items():
		var selected_index := int(selected_value)
		var metadata_value: Variant = get_item_metadata(selected_index)
		var idea_id := str(metadata_value).strip_edges()
		if not idea_id.is_empty() and not idea_id in idea_ids:
			idea_ids.append(idea_id)
	return idea_ids
