class_name CCFLibraryV0135View
extends CCFLibraryView


func _ready() -> void:
	super._ready()
	_search.placeholder_text = "Search character projects, characters, series, card text, tags, creators, folders, and import metadata..."
	for node in find_children("*", "Button", true, false):
		if node is Button and node.text == "New Project":
			node.text = "New Character Project"
		elif node is Button and node.text == "All Projects":
			node.text = "All Character Projects"


func _rebuild_list() -> void:
	_list_view.clear()
	for raw_row in _filtered:
		var row := _presentation_row(raw_row)
		var project_id := str(row.get("project_id", ""))
		var character_count := int(row.get("character_count", 0))
		var label := "%s%s   •   %s" % [
			"★ " if bool(row.get("favorite", false)) else "",
			str(row.get("name", "Untitled Project")),
			"Single-character project" if character_count == 1 else "%d characters" % character_count
		]
		var series_name := str(row.get("series_name", "")).strip_edges()
		if not series_name.is_empty():
			label += "   •   Series: %s" % series_name
		var folder_text := str(row.get("folder", "")).strip_edges()
		if not folder_text.is_empty():
			label += "   •   %s" % folder_text
		var names: Array[String] = _string_array(row.get("character_names", []))
		if character_count != 1 and not names.is_empty():
			label += "   •   " + _join_values(names, ", ").left(80)
		var summary_text := str(row.get("summary", "")).strip_edges()
		if not summary_text.is_empty() and summary_text != "Single-character project":
			label += "   •   " + summary_text.replace("\n", " ").left(90)
		var item_index := _list_view.item_count
		_list_view.add_item(label)
		_list_view.set_item_metadata(item_index, project_id)
		if _selected_project_ids.has(project_id):
			_list_view.select(item_index, false)


func _rebuild_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_card_nodes.clear()
	for raw_row in _filtered:
		var row := _presentation_row(raw_row)
		var project_id := str(row.get("project_id", ""))
		var card := CCFLibraryProjectCard.new()
		card.configure(row, _selected_project_ids.has(project_id))
		card.primary_requested.connect(_on_card_primary_requested)
		card.selection_changed.connect(_on_card_selection_changed)
		card.open_requested.connect(_open_project_id)
		_grid.add_child(card)
		_card_nodes[project_id] = card
	call_deferred("_update_grid_columns")


func _update_detail(row: Dictionary) -> void:
	super._update_detail(_presentation_row(row))


func _presentation_row(source: Dictionary) -> Dictionary:
	if source.is_empty():
		return source
	var row := source.duplicate(true)
	var project_name := str(row.get("name", "")).strip_edges()
	var character_count := int(row.get("character_count", 0))
	var names: Array[String] = _string_array(row.get("character_names", []))
	var default_project_name := (
		project_name.is_empty()
		or project_name == "Untitled Project"
		or project_name == "Untitled Character"
	)
	if character_count == 1 and names.size() == 1 and default_project_name:
		row["name"] = names[0]
		if str(row.get("summary", "")).strip_edges().is_empty():
			row["summary"] = "Single-character project"
	return row
