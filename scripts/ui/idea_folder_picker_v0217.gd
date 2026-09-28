class_name CCFIdeaFolderPickerV0217
extends VBoxContainer

signal folder_selected(folder_id: String, selection_kind: String)

const IDEA_LIBRARY_SERVICE = preload(
	"res://scripts/services/idea_notebook_service_v01532.gd"
)

var _allow_unfiled := false
var _allow_root := false
var _search_enabled := true
var _search: LineEdit
var _tree: Tree
var _selected_path: Label
var _selected_folder_id := ""
var _selected_kind := ""
var _query := ""
var _expanded_before_search: Array[String] = []
var _items_by_folder_id: Dictionary = {}


func configure_v0217(
	allow_unfiled: bool,
	allow_root: bool,
	search_enabled: bool = true
) -> void:
	_allow_unfiled = allow_unfiled
	_allow_root = allow_root
	_search_enabled = search_enabled
	_ensure_controls_v0217()
	_search.visible = _search_enabled
	refresh_v0217("", "root" if _allow_root else "unfiled")


func refresh_v0217(
	selected_folder_id: String = "", selected_kind: String = ""
) -> void:
	_ensure_controls_v0217()
	var previous_expanded := _expanded_folder_ids_v0217()
	if not previous_expanded.is_empty() and _query.is_empty():
		_expanded_before_search = previous_expanded
	_selected_folder_id = selected_folder_id.strip_edges()
	_selected_kind = selected_kind.strip_edges()
	if _selected_kind.is_empty():
		_selected_kind = (
			"folder" if not _selected_folder_id.is_empty()
			else ("root" if _allow_root else "unfiled")
		)
	_tree.clear()
	_items_by_folder_id.clear()
	var root_item := _tree.create_item()
	if _allow_root:
		var root_choice := _tree.create_item(root_item)
		root_choice.set_text(0, "Root level")
		root_choice.set_metadata(0, {
			"kind": "root", "id": "", "path": "Root level"
		})
	if _allow_unfiled:
		var unfiled_choice := _tree.create_item(root_item)
		unfiled_choice.set_text(0, "Unfiled")
		unfiled_choice.set_metadata(0, {
			"kind": "unfiled", "id": "", "path": "Unfiled"
		})
	var snapshot := IDEA_LIBRARY_SERVICE.hierarchy_snapshot()
	var folders_value: Variant = snapshot.get("folders", [])
	var folders: Array = folders_value if folders_value is Array else []
	var folder_paths: Dictionary = snapshot.get("folder_paths", {})
	var folder_by_id: Dictionary = {}
	var children_by_parent: Dictionary = {}
	for value in folders:
		if not value is Dictionary:
			continue
		var folder: Dictionary = value
		var folder_id := str(folder.get("id", ""))
		if folder_id.is_empty():
			continue
		folder_by_id[folder_id] = folder
		var parent_id := str(folder.get("parent_folder_id", ""))
		if not children_by_parent.has(parent_id):
			children_by_parent[parent_id] = []
		(children_by_parent[parent_id] as Array).append(folder)
	var visible_ids := _visible_folder_ids_v0217(folder_by_id, folder_paths)
	_append_folder_children_v0217(
		root_item, "", children_by_parent, folder_paths, visible_ids
	)
	_restore_expansion_v0217()
	_select_current_v0217()


func selected_folder_id_v0217() -> String:
	return _selected_folder_id if _selected_kind == "folder" else ""


func selected_kind_v0217() -> String:
	return _selected_kind


func select_folder_id_v0217(
	folder_id: String, selection_kind: String = ""
) -> void:
	_selected_folder_id = folder_id.strip_edges()
	_selected_kind = selection_kind.strip_edges()
	if _selected_kind.is_empty():
		_selected_kind = (
			"folder" if not _selected_folder_id.is_empty()
			else ("root" if _allow_root else "unfiled")
		)
	_select_current_v0217()


func tree_control_v0217() -> Tree:
	_ensure_controls_v0217()
	return _tree


func search_control_v0217() -> LineEdit:
	_ensure_controls_v0217()
	return _search


func item_for_folder_id_v0217(folder_id: String) -> TreeItem:
	return _items_by_folder_id.get(folder_id) as TreeItem


func item_for_kind_v0217(kind: String) -> TreeItem:
	return _find_special_item_v0217(kind)


func _ensure_controls_v0217() -> void:
	if _tree != null:
		return
	add_theme_constant_override("separation", 6)
	_search = LineEdit.new()
	_search.name = "FolderPickerSearchV0217"
	_search.placeholder_text = "Search Folders…"
	_search.clear_button_enabled = true
	_search.text_changed.connect(_on_search_changed_v0217)
	add_child(_search)
	_tree = Tree.new()
	_tree.name = "FolderPickerTreeV0217"
	_tree.hide_root = true
	_tree.columns = 1
	_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.custom_minimum_size = Vector2(420, 220)
	_tree.set_column_expand(0, true)
	_tree.item_selected.connect(_on_tree_item_selected_v0217)
	add_child(_tree)
	_selected_path = Label.new()
	_selected_path.name = "FolderPickerSelectedPathV0217"
	_selected_path.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_selected_path.modulate = Color(0.72, 0.76, 0.86)
	add_child(_selected_path)


func _append_folder_children_v0217(
	parent_item: TreeItem,
	parent_id: String,
	children_by_parent: Dictionary,
	folder_paths: Dictionary,
	visible_ids: Dictionary
) -> void:
	var rows_value: Variant = children_by_parent.get(parent_id, [])
	var rows: Array = rows_value.duplicate(true) if rows_value is Array else []
	rows.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		return str(first.get("name", "")).naturalnocasecmp_to(
			str(second.get("name", ""))
		) < 0
	)
	for value in rows:
		if not value is Dictionary:
			continue
		var folder: Dictionary = value
		var folder_id := str(folder.get("id", ""))
		if not visible_ids.has(folder_id):
			continue
		var path := str(folder_paths.get(folder_id, folder.get("name", "Folder")))
		var item := _tree.create_item(parent_item)
		item.set_text(0, str(folder.get("name", "Folder")))
		item.set_tooltip_text(0, path)
		item.set_metadata(0, {
			"kind": "folder", "id": folder_id, "path": path
		})
		_items_by_folder_id[folder_id] = item
		_append_folder_children_v0217(
			item, folder_id, children_by_parent, folder_paths, visible_ids
		)


func _visible_folder_ids_v0217(
	folder_by_id: Dictionary, folder_paths: Dictionary
) -> Dictionary:
	var visible: Dictionary = {}
	if _query.is_empty():
		for folder_id in folder_by_id.keys():
			visible[str(folder_id)] = true
		return visible
	for folder_id_value in folder_by_id.keys():
		var folder_id := str(folder_id_value)
		var folder: Dictionary = folder_by_id.get(folder_id, {})
		var searchable := "%s %s" % [
			str(folder.get("name", "")), str(folder_paths.get(folder_id, ""))
		]
		if not searchable.to_lower().contains(_query):
			continue
		var current_id := folder_id
		while not current_id.is_empty() and folder_by_id.has(current_id):
			visible[current_id] = true
			current_id = str(
				(folder_by_id.get(current_id, {}) as Dictionary).get(
					"parent_folder_id", ""
				)
			)
	return visible


func _restore_expansion_v0217() -> void:
	var expanded_ids := _expanded_before_search
	if not _query.is_empty():
		expanded_ids = []
		for folder_id in _items_by_folder_id.keys():
			expanded_ids.append(str(folder_id))
	for folder_id_value in _items_by_folder_id.keys():
		var folder_id := str(folder_id_value)
		var item := _items_by_folder_id.get(folder_id) as TreeItem
		if item != null:
			item.collapsed = not folder_id in expanded_ids
	var selected_item := _items_by_folder_id.get(_selected_folder_id) as TreeItem
	while selected_item != null:
		selected_item.collapsed = false
		selected_item = selected_item.get_parent()


func _select_current_v0217() -> void:
	var item: TreeItem
	if _selected_kind == "folder":
		item = _items_by_folder_id.get(_selected_folder_id) as TreeItem
	else:
		item = _find_special_item_v0217(_selected_kind)
	if item == null:
		_selected_folder_id = ""
		_selected_kind = "root" if _allow_root else "unfiled"
		item = _find_special_item_v0217(_selected_kind)
	if item != null:
		item.select(0)
		_tree.scroll_to_item(item, true)
		var metadata_value: Variant = item.get_metadata(0)
		if metadata_value is Dictionary:
			_selected_path.text = "Selected: %s" % str(
				(metadata_value as Dictionary).get("path", item.get_text(0))
			)


func _find_special_item_v0217(kind: String) -> TreeItem:
	if _tree == null or _tree.get_root() == null:
		return null
	var item := _tree.get_root().get_first_child()
	while item != null:
		var metadata_value: Variant = item.get_metadata(0)
		if (
			metadata_value is Dictionary
			and str((metadata_value as Dictionary).get("kind", "")) == kind
		):
			return item
		item = item.get_next()
	return null


func _expanded_folder_ids_v0217() -> Array[String]:
	var result: Array[String] = []
	for folder_id_value in _items_by_folder_id.keys():
		var folder_id := str(folder_id_value)
		var item := _items_by_folder_id.get(folder_id) as TreeItem
		if item != null and not item.collapsed:
			result.append(folder_id)
	return result


func _on_tree_item_selected_v0217() -> void:
	var item := _tree.get_selected()
	if item == null:
		return
	var metadata_value: Variant = item.get_metadata(0)
	if not metadata_value is Dictionary:
		return
	var metadata: Dictionary = metadata_value
	_selected_kind = str(metadata.get("kind", ""))
	_selected_folder_id = str(metadata.get("id", ""))
	_selected_path.text = "Selected: %s" % str(
		metadata.get("path", item.get_text(0))
	)
	folder_selected.emit(_selected_folder_id, _selected_kind)


func _on_search_changed_v0217(value: String) -> void:
	var next_query := value.strip_edges().to_lower()
	if _query.is_empty() and not next_query.is_empty():
		_expanded_before_search = _expanded_folder_ids_v0217()
	_query = next_query
	refresh_v0217(_selected_folder_id, _selected_kind)
