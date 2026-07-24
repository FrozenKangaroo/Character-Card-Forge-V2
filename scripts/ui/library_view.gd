class_name CCFLibraryView
extends VBoxContainer

signal new_character_requested()
signal open_project_requested(project_id: String)
signal project_changed()

const VIEW_GRID := "grid"
const VIEW_LIST := "list"
const SORT_UPDATED_DESC := "updated_desc"
const SORT_UPDATED_ASC := "updated_asc"
const SORT_NAME_ASC := "name_asc"
const SORT_NAME_DESC := "name_desc"
const SORT_CREATED_DESC := "created_desc"
const SORT_CHARACTER_COUNT := "character_count"
const SORT_FAVORITES := "favorites"

var _search: LineEdit
var _view_option: OptionButton
var _sort_option: OptionButton
var _favorites_only: CheckButton
var _status: Label
var _result_count: Label
var _folder_list: ItemList
var _collection_list: ItemList
var _tag_list: ItemList
var _series_list: ItemList
var _bulk_series_option: OptionButton
var _list_view: ItemList
var _grid_scroll: ScrollContainer
var _grid: GridContainer
var _selection_label: Label
var _bulk_tags: LineEdit
var _bulk_tags_characters: CheckBox
var _folder_edit: LineEdit
var _collection_edit: LineEdit
var _detail_portrait: TextureRect
var _detail_fallback: Label
var _detail_name: Label
var _detail_summary: Label
var _detail_metadata: Label
var _detail_characters: Label
var _open_button: Button
var _favorite_button: Button
var _duplicate_button: Button
var _delete_button: Button
var _delete_confirm: ConfirmationDialog
var _merge_window: Window
var _merge_old_tag: LineEdit
var _merge_new_tag: LineEdit
var _merge_status: Label
var _projects: Array[Dictionary] = []
var _filtered: Array[Dictionary] = []
var _selected_project_ids: Dictionary = {}
var _primary_project_id := ""
var _view_state: Dictionary = {}
var _active_folder := ""
var _active_collection := ""
var _active_tag := ""
var _active_series_id := ""
var _card_nodes: Dictionary = {}


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_view_state = CCFLibraryService.load_view_state()
	_active_folder = str(_view_state.get("folder_filter", ""))
	_active_collection = str(_view_state.get("collection_filter", ""))
	_active_tag = str(_view_state.get("tag_filter", ""))
	_active_series_id = str(_view_state.get("series_filter", ""))
	_build_toolbar()
	_build_library_body()
	_build_dialogs()
	refresh_projects()


func refresh_projects(force_rebuild: bool = false) -> void:
	var result := CCFLibraryService.refresh_index(force_rebuild)
	_projects.clear()
	if result.get("ok", false):
		var raw_rows: Variant = result.get("rows", [])
		if raw_rows is Array:
			for raw_row in raw_rows:
				if raw_row is Dictionary:
					_projects.append(raw_row)
		_status.text = "Index: %d refreshed • %d reused%s" % [
			int(result.get("refreshed", 0)),
			int(result.get("reused", 0)),
			" • %d skipped" % int(result.get("skipped", 0)) if int(result.get("skipped", 0)) > 0 else ""
		]
	else:
		_status.text = str(result.get("error", "Could not refresh the library index."))
	_prune_selection()
	_populate_bulk_series_option()
	_rebuild_facets()
	_apply_filters()


func _prune_selection() -> void:
	var existing_ids: Dictionary = {}
	for row in _projects:
		existing_ids[str(row.get("project_id", ""))] = true
	for raw_project_id in _selected_project_ids.keys():
		if not existing_ids.has(str(raw_project_id)):
			_selected_project_ids.erase(raw_project_id)
	if not _primary_project_id.is_empty() and not existing_ids.has(_primary_project_id):
		_primary_project_id = ""


func _build_toolbar() -> void:
	var toolbar := HFlowContainer.new()
	toolbar.add_theme_constant_override("h_separation", 8)
	toolbar.add_theme_constant_override("v_separation", 8)
	add_child(toolbar)

	_search = LineEdit.new()
	_search.placeholder_text = "Search projects, characters, series, card text, tags, creators, folders, and import metadata..."
	_search.custom_minimum_size.x = 440
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(func(_query: String): _apply_filters())
	toolbar.add_child(_search)

	_view_option = OptionButton.new()
	_view_option.add_item("Thumbnail Grid", 0)
	_view_option.add_item("Compact List", 1)
	_view_option.select(0 if str(_view_state.get("view_mode", VIEW_GRID)) == VIEW_GRID else 1)
	_view_option.item_selected.connect(func(_index: int): _change_view_mode())
	toolbar.add_child(_view_option)

	_sort_option = OptionButton.new()
	_sort_option.add_item("Updated: Newest", 0)
	_sort_option.add_item("Updated: Oldest", 1)
	_sort_option.add_item("Name: A–Z", 2)
	_sort_option.add_item("Name: Z–A", 3)
	_sort_option.add_item("Created: Newest", 4)
	_sort_option.add_item("Character Count", 5)
	_sort_option.add_item("Favourites First", 6)
	_select_sort_option(str(_view_state.get("sort_mode", SORT_UPDATED_DESC)))
	_sort_option.item_selected.connect(func(_index: int): _change_sort_mode())
	toolbar.add_child(_sort_option)

	_favorites_only = CheckButton.new()
	_favorites_only.text = "Favourites only"
	_favorites_only.button_pressed = bool(_view_state.get("favorites_only", false))
	_favorites_only.toggled.connect(func(_pressed: bool): _apply_filters())
	toolbar.add_child(_favorites_only)

	var refresh_button := Button.new()
	refresh_button.text = "Refresh"
	refresh_button.tooltip_text = "Reuse unchanged index entries and rescan edited projects"
	refresh_button.pressed.connect(func(): refresh_projects(false))
	toolbar.add_child(refresh_button)

	var rebuild_button := Button.new()
	rebuild_button.text = "Rebuild Index"
	rebuild_button.tooltip_text = "Discard the disposable index and thumbnail cache entries, then scan everything"
	rebuild_button.pressed.connect(func(): refresh_projects(true))
	toolbar.add_child(rebuild_button)

	var new_button := Button.new()
	new_button.text = "New Project"
	new_button.pressed.connect(func(): new_character_requested.emit())
	toolbar.add_child(new_button)

	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 12)
	add_child(info_row)
	_result_count = Label.new()
	_result_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(_result_count)
	_status = Label.new()
	_status.modulate = Color(0.66, 0.69, 0.78)
	info_row.add_child(_status)


func _build_library_body() -> void:
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(split)
	split.add_child(_build_filter_sidebar())

	var centre := VBoxContainer.new()
	centre.custom_minimum_size.x = 430
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.add_theme_constant_override("separation", 8)
	split.add_child(centre)
	centre.add_child(_build_bulk_toolbar())

	_list_view = ItemList.new()
	_list_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_view.select_mode = ItemList.SELECT_TOGGLE
	_list_view.allow_reselect = true
	_list_view.item_selected.connect(_on_list_item_selected)
	_list_view.multi_selected.connect(_on_list_multi_selected)
	_list_view.item_activated.connect(_on_list_item_activated)
	centre.add_child(_list_view)

	_grid_scroll = ScrollContainer.new()
	_grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_grid_scroll.resized.connect(_update_grid_columns)
	centre.add_child(_grid_scroll)
	_grid = GridContainer.new()
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	_grid_scroll.add_child(_grid)

	split.add_child(_build_detail_panel())
	_apply_view_visibility()


func _build_filter_sidebar() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 190
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var sidebar := VBoxContainer.new()
	sidebar.add_theme_constant_override("separation", 8)
	margin.add_child(sidebar)

	var title_label := Label.new()
	title_label.text = "Library Filters"
	title_label.add_theme_font_size_override("font_size", 18)
	sidebar.add_child(title_label)

	var all_button := Button.new()
	all_button.text = "All Projects"
	all_button.pressed.connect(_clear_organisation_filters)
	sidebar.add_child(all_button)
	var unfiled_button := Button.new()
	unfiled_button.text = "Unfiled"
	unfiled_button.pressed.connect(_filter_unfiled)
	sidebar.add_child(unfiled_button)

	sidebar.add_child(_section_label("Series"))
	_series_list = ItemList.new()
	_series_list.custom_minimum_size.y = 120
	_series_list.item_selected.connect(_on_series_filter_selected)
	sidebar.add_child(_series_list)

	sidebar.add_child(_section_label("Folders"))
	_folder_list = ItemList.new()
	_folder_list.custom_minimum_size.y = 110
	_folder_list.item_selected.connect(_on_folder_selected)
	sidebar.add_child(_folder_list)

	sidebar.add_child(_section_label("Collections"))
	_collection_list = ItemList.new()
	_collection_list.custom_minimum_size.y = 110
	_collection_list.item_selected.connect(_on_collection_selected)
	sidebar.add_child(_collection_list)

	sidebar.add_child(_section_label("Tags"))
	_tag_list = ItemList.new()
	_tag_list.custom_minimum_size.y = 150
	_tag_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tag_list.item_selected.connect(_on_tag_selected)
	sidebar.add_child(_tag_list)

	var merge_button := Button.new()
	merge_button.text = "Merge Tags..."
	merge_button.pressed.connect(_open_merge_window)
	sidebar.add_child(merge_button)
	return panel


func _build_bulk_toolbar() -> Control:
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	margin.add_child(rows)

	var selection_row := HFlowContainer.new()
	selection_row.add_theme_constant_override("h_separation", 6)
	selection_row.add_theme_constant_override("v_separation", 6)
	rows.add_child(selection_row)
	_selection_label = Label.new()
	_selection_label.text = "No projects selected"
	_selection_label.custom_minimum_size.x = 155
	selection_row.add_child(_selection_label)
	selection_row.add_child(_small_button("Favourite", func(): _set_selected_favorite(true)))
	selection_row.add_child(_small_button("Unfavourite", func(): _set_selected_favorite(false)))
	selection_row.add_child(_small_button("Clear Selection", _clear_selection))

	var series_row := HFlowContainer.new()
	series_row.add_theme_constant_override("h_separation", 6)
	series_row.add_theme_constant_override("v_separation", 6)
	rows.add_child(series_row)
	var series_label := Label.new()
	series_label.text = "Series"
	series_row.add_child(series_label)
	_bulk_series_option = OptionButton.new()
	_bulk_series_option.custom_minimum_size.x = 220
	series_row.add_child(_bulk_series_option)
	series_row.add_child(_small_button("Assign", _assign_bulk_series))
	series_row.add_child(_small_button("Clear", _clear_bulk_series))
	series_row.add_child(_small_button("Auto Match", _auto_match_selected_series))
	series_row.add_child(_small_button("Apply Default Tags", _apply_selected_series_tags))

	var organisation_row := HFlowContainer.new()
	organisation_row.add_theme_constant_override("h_separation", 6)
	organisation_row.add_theme_constant_override("v_separation", 6)
	rows.add_child(organisation_row)
	_bulk_tags = LineEdit.new()
	_bulk_tags.placeholder_text = "Tags: fantasy, rival, healer"
	_bulk_tags.custom_minimum_size.x = 240
	organisation_row.add_child(_bulk_tags)
	organisation_row.add_child(_small_button("Add Tags", _add_bulk_tags))
	_bulk_tags_characters = CheckBox.new()
	_bulk_tags_characters.text = "Also add to characters"
	organisation_row.add_child(_bulk_tags_characters)

	_folder_edit = LineEdit.new()
	_folder_edit.placeholder_text = "Virtual folder"
	_folder_edit.custom_minimum_size.x = 170
	organisation_row.add_child(_folder_edit)
	organisation_row.add_child(_small_button("Set Folder", _set_bulk_folder))
	organisation_row.add_child(_small_button("Clear Folder", _clear_bulk_folder))

	_collection_edit = LineEdit.new()
	_collection_edit.placeholder_text = "Collection"
	_collection_edit.custom_minimum_size.x = 170
	organisation_row.add_child(_collection_edit)
	organisation_row.add_child(_small_button("Add Collection", _add_bulk_collection))
	organisation_row.add_child(_small_button("Remove Collection", _remove_bulk_collection))
	return panel


func _build_detail_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 310
	var scroll := ScrollContainer.new()
	panel.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(margin)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 10)
	margin.add_child(detail)

	var portrait_panel := PanelContainer.new()
	portrait_panel.custom_minimum_size.y = 230
	detail.add_child(portrait_panel)
	_detail_portrait = TextureRect.new()
	_detail_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_panel.add_child(_detail_portrait)
	_detail_fallback = Label.new()
	_detail_fallback.text = "CCF"
	_detail_fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail_fallback.add_theme_font_size_override("font_size", 44)
	_detail_fallback.modulate = Color(0.68, 0.64, 0.86)
	portrait_panel.add_child(_detail_fallback)

	_detail_name = Label.new()
	_detail_name.text = "Select a project"
	_detail_name.add_theme_font_size_override("font_size", 22)
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_detail_name)
	_detail_summary = Label.new()
	_detail_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_summary.modulate = Color(0.79, 0.8, 0.87)
	detail.add_child(_detail_summary)
	_detail_metadata = Label.new()
	_detail_metadata.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_metadata.modulate = Color(0.66, 0.69, 0.78)
	detail.add_child(_detail_metadata)
	detail.add_child(HSeparator.new())
	_detail_characters = Label.new()
	_detail_characters.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_detail_characters)

	_open_button = Button.new()
	_open_button.text = "Open Project"
	_open_button.disabled = true
	_open_button.pressed.connect(_open_primary)
	detail.add_child(_open_button)
	_favorite_button = Button.new()
	_favorite_button.text = "Favourite"
	_favorite_button.disabled = true
	_favorite_button.pressed.connect(_toggle_primary_favorite)
	detail.add_child(_favorite_button)
	_duplicate_button = Button.new()
	_duplicate_button.text = "Duplicate"
	_duplicate_button.disabled = true
	_duplicate_button.pressed.connect(_duplicate_primary)
	detail.add_child(_duplicate_button)
	_delete_button = Button.new()
	_delete_button.text = "Delete Project(s)"
	_delete_button.disabled = true
	_delete_button.pressed.connect(_request_delete)
	detail.add_child(_delete_button)
	return panel


func _build_dialogs() -> void:
	_delete_confirm = ConfirmationDialog.new()
	_delete_confirm.title = "Delete Projects"
	_delete_confirm.confirmed.connect(_delete_selected)
	add_child(_delete_confirm)

	_merge_window = Window.new()
	_merge_window.hide()
	_merge_window.title = "Merge Library Tags"
	_merge_window.size = Vector2i(520, 310)
	_merge_window.min_size = Vector2i(460, 280)
	_merge_window.exclusive = true
	_merge_window.transient = true
	_merge_window.close_requested.connect(_merge_window.hide)
	add_child(_merge_window)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_merge_window.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)
	var explanation := Label.new()
	explanation.text = "Replace a tag across project metadata and every character in the library. Matching is case-insensitive and duplicate target tags are collapsed."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(explanation)
	_merge_old_tag = LineEdit.new()
	_merge_old_tag.placeholder_text = "Existing tag"
	content.add_child(_merge_old_tag)
	_merge_new_tag = LineEdit.new()
	_merge_new_tag.placeholder_text = "Replacement tag"
	content.add_child(_merge_new_tag)
	_merge_status = Label.new()
	_merge_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_merge_status)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	var buttons := HBoxContainer.new()
	content.add_child(buttons)
	var merge_button := Button.new()
	merge_button.text = "Merge Tags"
	merge_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	merge_button.pressed.connect(_merge_tags)
	buttons.add_child(merge_button)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_merge_window.hide)
	buttons.add_child(close_button)


func _rebuild_facets() -> void:
	var facets := CCFLibraryService.facet_values(_projects)
	_populate_series_filter_list()
	_populate_facet_list(_folder_list, facets.get("folders", []), _active_folder)
	_populate_facet_list(_collection_list, facets.get("collections", []), _active_collection)
	_populate_facet_list(_tag_list, facets.get("tags", []), _active_tag)


func _populate_facet_list(list_node: ItemList, raw_values: Variant, active_value: String) -> void:
	list_node.clear()
	if not raw_values is Array:
		return
	var active_index := -1
	for raw_value in raw_values:
		var facet_text := str(raw_value)
		var item_index := list_node.item_count
		list_node.add_item(facet_text)
		list_node.set_item_metadata(item_index, facet_text)
		if facet_text.nocasecmp_to(active_value) == 0:
			active_index = item_index
	if active_index >= 0:
		list_node.select(active_index)


func _apply_filters() -> void:
	var needle := _search.text.strip_edges().to_lower() if _search != null else ""
	_filtered.clear()
	for row in _projects:
		if _favorites_only != null and _favorites_only.button_pressed:
			if not bool(row.get("favorite", false)) and int(row.get("favorite_character_count", 0)) <= 0:
				continue
		var row_series_id := str(row.get("series_id", ""))
		if _active_series_id == "__unassigned__":
			if not row_series_id.is_empty():
				continue
		elif not _active_series_id.is_empty() and row_series_id != _active_series_id:
			continue
		if _active_folder == "__unfiled__":
			if not str(row.get("folder", "")).strip_edges().is_empty():
				continue
		elif not _active_folder.is_empty() and str(row.get("folder", "")).nocasecmp_to(_active_folder) != 0:
			continue
		if not _active_collection.is_empty() and not _array_contains_case_insensitive(row.get("collections", []), _active_collection):
			continue
		if not _active_tag.is_empty() and not _array_contains_case_insensitive(row.get("all_tags", []), _active_tag):
			continue
		if not needle.is_empty() and not str(row.get("search_text", "")).contains(needle):
			continue
		_filtered.append(row)
	_sort_rows()
	_result_count.text = "%d of %d project%s" % [
		_filtered.size(),
		_projects.size(),
		"" if _projects.size() == 1 else "s"
	]
	_rebuild_content()
	_save_view_state()


func _sort_rows() -> void:
	var sort_mode := _selected_sort_mode()
	_filtered.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			match sort_mode:
				SORT_UPDATED_ASC:
					return str(first.get("updated_at", "")) < str(second.get("updated_at", ""))
				SORT_NAME_ASC:
					return str(first.get("name", "")).naturalnocasecmp_to(str(second.get("name", ""))) < 0
				SORT_NAME_DESC:
					return str(first.get("name", "")).naturalnocasecmp_to(str(second.get("name", ""))) > 0
				SORT_CREATED_DESC:
					return str(first.get("created_at", "")) > str(second.get("created_at", ""))
				SORT_CHARACTER_COUNT:
					var first_count := int(first.get("character_count", 0))
					var second_count := int(second.get("character_count", 0))
					if first_count == second_count:
						return str(first.get("name", "")).naturalnocasecmp_to(str(second.get("name", ""))) < 0
					return first_count > second_count
				SORT_FAVORITES:
					var first_favorite := bool(first.get("favorite", false))
					var second_favorite := bool(second.get("favorite", false))
					if first_favorite == second_favorite:
						return str(first.get("updated_at", "")) > str(second.get("updated_at", ""))
					return first_favorite and not second_favorite
				_:
					return str(first.get("updated_at", "")) > str(second.get("updated_at", ""))
	)


func _rebuild_content() -> void:
	_rebuild_list()
	_rebuild_grid()
	if not _primary_project_id.is_empty() and _row_by_id(_primary_project_id).is_empty():
		_primary_project_id = ""
	if _primary_project_id.is_empty() and not _filtered.is_empty():
		_primary_project_id = str(_filtered[0].get("project_id", ""))
	_update_detail(_row_by_id(_primary_project_id))
	_sync_selection_controls()


func _rebuild_list() -> void:
	_list_view.clear()
	for row in _filtered:
		var project_id := str(row.get("project_id", ""))
		var character_count := int(row.get("character_count", 0))
		var label := "%s%s   •   %d character%s" % [
			"★ " if bool(row.get("favorite", false)) else "",
			str(row.get("name", "Untitled Project")),
			character_count,
			"" if character_count == 1 else "s"
		]
		var series_name := str(row.get("series_name", "")).strip_edges()
		if not series_name.is_empty():
			label += "   •   Series: %s" % series_name
		var folder_text := str(row.get("folder", "")).strip_edges()
		if not folder_text.is_empty():
			label += "   •   %s" % folder_text
		var names: Array[String] = _string_array(row.get("character_names", []))
		if not names.is_empty():
			label += "   •   " + _join_values(names, ", ").left(80)
		var summary_text := str(row.get("summary", "")).strip_edges()
		if not summary_text.is_empty():
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
	for row in _filtered:
		var project_id := str(row.get("project_id", ""))
		var card := CCFLibraryProjectCard.new()
		card.configure(row, _selected_project_ids.has(project_id))
		card.primary_requested.connect(_on_card_primary_requested)
		card.selection_changed.connect(_on_card_selection_changed)
		card.open_requested.connect(_open_project_id)
		_grid.add_child(card)
		_card_nodes[project_id] = card
	call_deferred("_update_grid_columns")


func _update_grid_columns() -> void:
	if _grid == null or _grid_scroll == null:
		return
	var usable_width := maxf(230.0, _grid_scroll.size.x - 20.0)
	_grid.columns = maxi(1, int(floor(usable_width / 245.0)))


func _on_list_item_selected(index: int) -> void:
	if index < 0 or index >= _list_view.item_count:
		return
	_primary_project_id = str(_list_view.get_item_metadata(index))
	_update_detail(_row_by_id(_primary_project_id))


func _on_list_multi_selected(index: int, selected: bool) -> void:
	if index < 0 or index >= _list_view.item_count:
		return
	var project_id := str(_list_view.get_item_metadata(index))
	_set_selection(project_id, selected)
	if selected:
		_primary_project_id = project_id
		_update_detail(_row_by_id(project_id))


func _on_list_item_activated(index: int) -> void:
	if index < 0 or index >= _list_view.item_count:
		return
	_open_project_id(str(_list_view.get_item_metadata(index)))


func _on_card_primary_requested(project_id: String, additive: bool) -> void:
	_primary_project_id = project_id
	if additive:
		_set_selection(project_id, not _selected_project_ids.has(project_id))
	_update_detail(_row_by_id(project_id))


func _on_card_selection_changed(project_id: String, selected: bool) -> void:
	_set_selection(project_id, selected)
	if selected:
		_primary_project_id = project_id
		_update_detail(_row_by_id(project_id))


func _set_selection(project_id: String, selected: bool) -> void:
	if selected:
		_selected_project_ids[project_id] = true
	else:
		_selected_project_ids.erase(project_id)
	var card_value: Variant = _card_nodes.get(project_id, null)
	if card_value is CCFLibraryProjectCard:
		card_value.set_selected(selected)
	_sync_selection_controls()


func _sync_selection_controls() -> void:
	var selected_count := _selected_project_ids.size()
	if selected_count > 0:
		_selection_label.text = "%d project%s selected" % [
			selected_count, "" if selected_count == 1 else "s"
		]
	elif not _primary_project_id.is_empty():
		_selection_label.text = "No bulk selection • actions use active project"
	else:
		_selection_label.text = "No projects selected"
	_delete_button.disabled = selected_count == 0 and _primary_project_id.is_empty()


func _update_detail(row: Dictionary) -> void:
	var has_selection := not row.is_empty()
	_open_button.disabled = not has_selection
	_favorite_button.disabled = not has_selection
	_duplicate_button.disabled = not has_selection
	if not has_selection:
		_detail_portrait.texture = null
		_detail_fallback.visible = true
		_detail_name.text = "Select a project"
		_detail_summary.text = ""
		_detail_metadata.text = ""
		_detail_characters.text = ""
		_favorite_button.text = "Favourite"
		return
	_detail_name.text = str(row.get("name", "Untitled Project"))
	_detail_portrait.texture = _load_texture(str(row.get("thumbnail_path", "")))
	_detail_fallback.visible = _detail_portrait.texture == null
	var summary_text := str(row.get("summary", "")).strip_edges()
	_detail_summary.text = summary_text if not summary_text.is_empty() else "No project summary yet."
	var metadata_lines: Array[String] = []
	metadata_lines.append("%d character%s" % [
		int(row.get("character_count", 0)),
		"" if int(row.get("character_count", 0)) == 1 else "s"
	])
	var series_name := str(row.get("series_name", "")).strip_edges()
	var series_id := str(row.get("series_id", "")).strip_edges()
	if series_id.is_empty():
		metadata_lines.append("Series: Unassigned")
	elif bool(row.get("series_missing", false)):
		metadata_lines.append("Series: Missing reference (%s)" % series_id)
	else:
		metadata_lines.append("Series: %s" % series_name)
	var folder_text := str(row.get("folder", "")).strip_edges()
	metadata_lines.append("Folder: %s" % (folder_text if not folder_text.is_empty() else "Unfiled"))
	var collections: Array[String] = _string_array(row.get("collections", []))
	metadata_lines.append("Collections: %s" % (_join_values(collections, ", ") if not collections.is_empty() else "None"))
	var tags: Array[String] = _string_array(row.get("all_tags", []))
	metadata_lines.append("Tags: %s" % (_join_values(tags, ", ") if not tags.is_empty() else "None"))
	var formats: Array[String] = _string_array(row.get("interoperability_formats", []))
	metadata_lines.append("Imported formats: %s" % (_join_values(formats, ", ") if not formats.is_empty() else "Native CCF / none recorded"))
	metadata_lines.append("Updated: %s" % _friendly_date(str(row.get("updated_at", ""))))
	_detail_metadata.text = _join_values(metadata_lines, "\n")
	_detail_characters.text = _character_summary_text(row.get("characters", []))
	_favorite_button.text = "Remove Favourite" if bool(row.get("favorite", false)) else "Favourite"


func _character_summary_text(raw_characters: Variant) -> String:
	if not raw_characters is Array or raw_characters.is_empty():
		return "Characters\nNo characters recorded."
	var lines: Array[String] = ["Characters"]
	for raw_character in raw_characters:
		if not raw_character is Dictionary:
			continue
		var character: Dictionary = raw_character
		var heading := "• %s" % str(character.get("name", "Untitled Character"))
		var role_text := str(character.get("role", "")).strip_edges()
		if not role_text.is_empty():
			heading += " — %s" % role_text
		if bool(character.get("favorite", false)):
			heading += " ★"
		lines.append(heading)
		var summary_text := str(character.get("summary", "")).strip_edges()
		if not summary_text.is_empty():
			lines.append("  %s" % summary_text.left(220))
		var details: Array[String] = []
		var creator_text := str(character.get("creator", "")).strip_edges()
		if not creator_text.is_empty():
			details.append("Creator: %s" % creator_text)
		var version_text := str(character.get("character_version", "")).strip_edges()
		if not version_text.is_empty():
			details.append("Version: %s" % version_text)
		var source_format := str(character.get("source_format", "")).strip_edges()
		var source_spec := str(character.get("source_spec", "")).strip_edges()
		if not source_format.is_empty() or not source_spec.is_empty():
			details.append("Source: %s %s" % [source_format, source_spec])
		if not details.is_empty():
			lines.append("  %s" % _join_values(details, " • "))
	return _join_values(lines, "\n")


func _on_series_filter_selected(index: int) -> void:
	_active_series_id = str(_series_list.get_item_metadata(index))
	_active_folder = ""
	_active_collection = ""
	_active_tag = ""
	_folder_list.deselect_all()
	_collection_list.deselect_all()
	_tag_list.deselect_all()
	_apply_filters()


func _on_folder_selected(index: int) -> void:
	_active_folder = str(_folder_list.get_item_metadata(index))
	_active_collection = ""
	_active_tag = ""
	_active_series_id = ""
	_series_list.deselect_all()
	_collection_list.deselect_all()
	_tag_list.deselect_all()
	_apply_filters()


func _on_collection_selected(index: int) -> void:
	_active_collection = str(_collection_list.get_item_metadata(index))
	_active_folder = ""
	_active_tag = ""
	_active_series_id = ""
	_series_list.deselect_all()
	_folder_list.deselect_all()
	_tag_list.deselect_all()
	_apply_filters()


func _on_tag_selected(index: int) -> void:
	_active_tag = str(_tag_list.get_item_metadata(index))
	_active_folder = ""
	_active_collection = ""
	_active_series_id = ""
	_series_list.deselect_all()
	_folder_list.deselect_all()
	_collection_list.deselect_all()
	_apply_filters()


func _clear_organisation_filters() -> void:
	_active_folder = ""
	_active_collection = ""
	_active_tag = ""
	_active_series_id = ""
	_series_list.deselect_all()
	_folder_list.deselect_all()
	_collection_list.deselect_all()
	_tag_list.deselect_all()
	_apply_filters()


func _filter_unfiled() -> void:
	_active_folder = "__unfiled__"
	_active_collection = ""
	_active_tag = ""
	_active_series_id = ""
	_series_list.deselect_all()
	_folder_list.deselect_all()
	_collection_list.deselect_all()
	_tag_list.deselect_all()
	_apply_filters()


func _change_view_mode() -> void:
	_view_state["view_mode"] = VIEW_GRID if _view_option.selected == 0 else VIEW_LIST
	_apply_view_visibility()
	_save_view_state()


func _apply_view_visibility() -> void:
	var grid_mode := str(_view_state.get("view_mode", VIEW_GRID)) == VIEW_GRID
	if _grid_scroll != null:
		_grid_scroll.visible = grid_mode
	if _list_view != null:
		_list_view.visible = not grid_mode


func _change_sort_mode() -> void:
	_view_state["sort_mode"] = _selected_sort_mode()
	_apply_filters()


func _selected_sort_mode() -> String:
	match _sort_option.selected:
		1:
			return SORT_UPDATED_ASC
		2:
			return SORT_NAME_ASC
		3:
			return SORT_NAME_DESC
		4:
			return SORT_CREATED_DESC
		5:
			return SORT_CHARACTER_COUNT
		6:
			return SORT_FAVORITES
		_:
			return SORT_UPDATED_DESC


func _select_sort_option(sort_mode: String) -> void:
	var option_index := 0
	match sort_mode:
		SORT_UPDATED_ASC:
			option_index = 1
		SORT_NAME_ASC:
			option_index = 2
		SORT_NAME_DESC:
			option_index = 3
		SORT_CREATED_DESC:
			option_index = 4
		SORT_CHARACTER_COUNT:
			option_index = 5
		SORT_FAVORITES:
			option_index = 6
	_sort_option.select(option_index)


func _populate_series_filter_list() -> void:
	if _series_list == null:
		return
	_series_list.clear()
	var unassigned_index := _series_list.item_count
	_series_list.add_item("Unassigned")
	_series_list.set_item_metadata(unassigned_index, "__unassigned__")
	if _active_series_id == "__unassigned__":
		_series_list.select(unassigned_index)
	for series in CCFSeriesService.list_series():
		var series_id := str(series.get("series_id", ""))
		var item_index := _series_list.item_count
		_series_list.add_item(str(series.get("name", "Untitled Series")))
		_series_list.set_item_metadata(item_index, series_id)
		if series_id == _active_series_id:
			_series_list.select(item_index)


func _populate_bulk_series_option() -> void:
	if _bulk_series_option == null:
		return
	var previous_id := ""
	if _bulk_series_option.selected >= 0 and _bulk_series_option.selected < _bulk_series_option.item_count:
		previous_id = str(_bulk_series_option.get_item_metadata(_bulk_series_option.selected))
	_bulk_series_option.clear()
	_bulk_series_option.add_item("Choose series...")
	_bulk_series_option.set_item_metadata(0, "")
	var selected_index := 0
	for series in CCFSeriesService.list_series():
		var item_index := _bulk_series_option.item_count
		var series_id := str(series.get("series_id", ""))
		_bulk_series_option.add_item(str(series.get("name", "Untitled Series")))
		_bulk_series_option.set_item_metadata(item_index, series_id)
		if series_id == previous_id:
			selected_index = item_index
	_bulk_series_option.select(selected_index)


func _assign_bulk_series() -> void:
	if _bulk_series_option == null or _bulk_series_option.selected <= 0:
		_status.text = "Choose a series first."
		return
	var series_id := str(_bulk_series_option.get_item_metadata(_bulk_series_option.selected))
	var result := CCFLibraryService.set_project_series(_selected_ids_or_primary(), series_id)
	_handle_bulk_result(result, "%d project(s) assigned to the series." % int(result.get("updated", 0)))


func _clear_bulk_series() -> void:
	var result := CCFLibraryService.set_project_series(_selected_ids_or_primary(), "")
	_handle_bulk_result(result, "%d project(s) cleared from their series." % int(result.get("updated", 0)))


func _auto_match_selected_series() -> void:
	var project_ids := _selected_ids_or_primary()
	if project_ids.is_empty():
		_status.text = "Select at least one project."
		return
	var assigned := 0
	var ambiguous := 0
	var unmatched := 0
	for project_id in project_ids:
		var loaded := CCFStorageService.load_project(project_id)
		if not loaded.get("ok", false):
			continue
		var project: Dictionary = loaded.get("data", {})
		var match_result := CCFSeriesService.match_project(project)
		if not bool(match_result.get("confident", false)):
			if match_result.get("candidates", []).is_empty():
				unmatched += 1
			else:
				ambiguous += 1
			continue
		var best: Dictionary = match_result.get("best", {})
		CCFSeriesService.assign_project(project, str(best.get("series_id", "")))
		if CCFStorageService.save_project(project).get("ok", false):
			assigned += 1
	CCFLibraryService.invalidate_index()
	_status.text = "Auto Series: %d assigned • %d ambiguous • %d unmatched" % [assigned, ambiguous, unmatched]
	project_changed.emit()
	refresh_projects(false)


func _apply_selected_series_tags() -> void:
	var project_ids := _selected_ids_or_primary()
	if project_ids.is_empty():
		_status.text = "Select at least one project."
		return
	var updated := 0
	var added := 0
	for project_id in project_ids:
		var loaded := CCFStorageService.load_project(project_id)
		if not loaded.get("ok", false):
			continue
		var project: Dictionary = loaded.get("data", {})
		var tag_result := CCFSeriesService.apply_default_tags(project)
		if not tag_result.get("ok", false):
			continue
		if CCFStorageService.save_project(project).get("ok", false):
			updated += 1
			added += int(tag_result.get("added", 0))
	CCFLibraryService.invalidate_index()
	_status.text = "%d series tag%s added across %d project(s)." % [added, "" if added == 1 else "s", updated]
	project_changed.emit()
	refresh_projects(false)


func _set_selected_favorite(favorite: bool) -> void:
	var project_ids := _selected_ids_or_primary()
	var result := CCFLibraryService.set_project_favorite(project_ids, favorite)
	_handle_bulk_result(result, "%d project(s) updated." % int(result.get("updated", 0)))


func _add_bulk_tags() -> void:
	var tags := _split_tags(_bulk_tags.text)
	var result := CCFLibraryService.bulk_add_tags(
		_selected_ids_or_primary(), tags, _bulk_tags_characters.button_pressed
	)
	if result.get("ok", false):
		_bulk_tags.clear()
	_handle_bulk_result(result, "%d project(s) tagged." % int(result.get("updated", 0)))


func _set_bulk_folder() -> void:
	var result := CCFLibraryService.set_project_folder(_selected_ids_or_primary(), _folder_edit.text)
	_handle_bulk_result(result, "%d project(s) moved virtually." % int(result.get("updated", 0)))


func _clear_bulk_folder() -> void:
	var result := CCFLibraryService.set_project_folder(_selected_ids_or_primary(), "")
	_handle_bulk_result(result, "%d project(s) unfiled." % int(result.get("updated", 0)))


func _add_bulk_collection() -> void:
	var result := CCFLibraryService.add_project_collection(
		_selected_ids_or_primary(), _collection_edit.text
	)
	_handle_bulk_result(result, "%d project(s) added to the collection." % int(result.get("updated", 0)))


func _remove_bulk_collection() -> void:
	var result := CCFLibraryService.remove_project_collection(
		_selected_ids_or_primary(), _collection_edit.text
	)
	_handle_bulk_result(result, "%d project(s) removed from the collection." % int(result.get("updated", 0)))


func _handle_bulk_result(result: Dictionary, success_message: String) -> void:
	if result.get("ok", false):
		_status.text = success_message
		project_changed.emit()
		refresh_projects(false)
	else:
		_status.text = str(result.get("error", "The library update failed."))


func _clear_selection() -> void:
	_selected_project_ids.clear()
	_list_view.deselect_all()
	for card_value in _card_nodes.values():
		if card_value is CCFLibraryProjectCard:
			card_value.set_selected(false)
	_sync_selection_controls()


func _toggle_primary_favorite() -> void:
	var row := _row_by_id(_primary_project_id)
	if row.is_empty():
		return
	var project_ids: Array[String] = [_primary_project_id]
	var result := CCFLibraryService.set_project_favorite(project_ids, not bool(row.get("favorite", false)))
	_handle_bulk_result(result, "Favourite status updated.")


func _open_primary() -> void:
	_open_project_id(_primary_project_id)


func _open_project_id(project_id: String) -> void:
	if not project_id.is_empty():
		open_project_requested.emit(project_id)


func _duplicate_primary() -> void:
	if _primary_project_id.is_empty():
		return
	var result := CCFStorageService.duplicate_project(_primary_project_id)
	if result.get("ok", false):
		CCFLibraryService.invalidate_index()
		_status.text = "Project duplicated."
		project_changed.emit()
		refresh_projects(false)
	else:
		_status.text = str(result.get("error", "Could not duplicate the project."))


func _request_delete() -> void:
	var project_ids := _selected_ids_or_primary()
	if project_ids.is_empty():
		return
	_delete_confirm.dialog_text = "Delete %d project%s and all local assets? This cannot be undone." % [
		project_ids.size(), "" if project_ids.size() == 1 else "s"
	]
	_delete_confirm.popup_centered()


func _delete_selected() -> void:
	var result := CCFLibraryService.delete_projects(_selected_ids_or_primary())
	if result.get("ok", false):
		_selected_project_ids.clear()
		_primary_project_id = ""
		_status.text = "%d project(s) deleted." % int(result.get("deleted", 0))
		project_changed.emit()
		refresh_projects(false)
	else:
		_status.text = str(result.get("error", "Some projects could not be deleted."))


func _open_merge_window() -> void:
	_merge_status.text = ""
	_merge_window.popup_centered()


func _merge_tags() -> void:
	var result := CCFLibraryService.merge_tag(_merge_old_tag.text, _merge_new_tag.text)
	if result.get("ok", false):
		_merge_status.text = "Updated %d project(s) with %d replacement(s)." % [
			int(result.get("projects", 0)), int(result.get("replacements", 0))
		]
		_merge_old_tag.clear()
		_merge_new_tag.clear()
		project_changed.emit()
		refresh_projects(false)
	else:
		_merge_status.text = str(result.get("error", "The tag merge failed."))


func _selected_ids_or_primary() -> Array[String]:
	var result: Array[String] = []
	for raw_project_id in _selected_project_ids.keys():
		result.append(str(raw_project_id))
	if result.is_empty() and not _primary_project_id.is_empty():
		result.append(_primary_project_id)
	return result


func _row_by_id(project_id: String) -> Dictionary:
	if project_id.is_empty():
		return {}
	for row in _projects:
		if str(row.get("project_id", "")) == project_id:
			return row
	return {}


func _save_view_state() -> void:
	_view_state["view_mode"] = VIEW_GRID if _view_option.selected == 0 else VIEW_LIST
	_view_state["sort_mode"] = _selected_sort_mode()
	_view_state["favorites_only"] = _favorites_only.button_pressed
	_view_state["folder_filter"] = _active_folder
	_view_state["collection_filter"] = _active_collection
	_view_state["tag_filter"] = _active_tag
	_view_state["series_filter"] = _active_series_id
	CCFLibraryService.save_view_state(_view_state)


func _section_label(label_text: String) -> Label:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 16)
	return label


func _small_button(label_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label_text
	button.pressed.connect(callback)
	return button


func _split_tags(value: String) -> Array[String]:
	var result: Array[String] = []
	for raw_tag in value.replace(";", ",").split(",", false):
		var tag_text := str(raw_tag).strip_edges()
		if not tag_text.is_empty() and not _array_contains_case_insensitive(result, tag_text):
			result.append(tag_text)
	return result


func _string_array(raw_value: Variant) -> Array[String]:
	var result: Array[String] = []
	if raw_value is Array:
		for item in raw_value:
			var text := str(item).strip_edges()
			if not text.is_empty():
				result.append(text)
	return result


func _array_contains_case_insensitive(raw_values: Variant, candidate: String) -> bool:
	if not raw_values is Array:
		return false
	for raw_value in raw_values:
		if str(raw_value).nocasecmp_to(candidate) == 0:
			return true
	return false


func _join_values(raw_values: Variant, separator: String) -> String:
	var values := _string_array(raw_values)
	var output := ""
	for value_index in range(values.size()):
		if value_index > 0:
			output += separator
		output += values[value_index]
	return output


func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) != OK or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _friendly_date(value: String) -> String:
	if value.is_empty():
		return "Unknown"
	return value.replace("T", " ").trim_suffix("Z")
