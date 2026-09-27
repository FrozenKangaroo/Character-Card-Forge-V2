class_name CCFIdeaGeneratorWindowCurrent
extends "res://scripts/ui/idea_generator_window_v01533_hotfix1.gd"

signal active_idea_source_changed_v0213(source: Dictionary)
signal idea_source_title_requested_v0213(source: Dictionary, context: String)

const IDEA_PACK_SERVICE_V0210 = preload(
	"res://scripts/services/idea_pack_service_v0210.gd"
)
const IDEA_SOURCE_SERVICE_V0213 = preload(
	"res://scripts/services/idea_source_service_v0213.gd"
)
const IDEA_NOTEBOOK_TREE_V0215 = preload(
	"res://scripts/ui/idea_notebook_tree_v0215.gd"
)

var _idea_pack_service_v0210 := IDEA_PACK_SERVICE_V0210.new()
var _import_dialog_v0210: FileDialog
var _import_preview_v0210: Window
var _import_preview_data_v0210: Dictionary = {}
var _import_rows_v0210: Array[Dictionary] = []
var _import_detail_v0210: TextEdit
var _import_status_v0210: Label
var _import_confirm_v0210: Button
var _import_notebook_v0210: OptionButton

var _export_window_v0210: Window
var _export_dialog_v0210: FileDialog
var _export_scope_v0210: OptionButton
var _export_rows_v0210: Array[Dictionary] = []
var _export_title_v0210: LineEdit
var _export_id_v0210: LineEdit
var _export_description_v0210: TextEdit
var _export_version_v0210: LineEdit
var _export_status_v0210: Label
var _pending_export_ideas_v0210: Array[Dictionary] = []
var _structured_detail_v0210: TextEdit
var _export_selected_idea_ids_v0214: Array[String] = []
var _export_folder_notebook_ids_v0215: Dictionary = {}

var _notebook_search_v0211: LineEdit
var _notebook_sort_v0211: OptionButton
var _idea_sort_v0211: OptionButton
var _idea_result_summary_v0211: Label
var _save_new_notebook_dialog_v0211: ConfirmationDialog
var _save_new_notebook_name_v0211: LineEdit
var _save_new_notebook_folder_v0215: OptionButton

var _notebook_tree_v0215: Tree
var _notebook_tree_popup_v0215: PopupMenu
var _notebook_tree_selection_kind_v0215 := "special"
var _notebook_tree_selection_id_v0215 := "__all__"
var _notebook_tree_items_v0215: Dictionary = {}
var _notebook_tree_rebuilding_v0215 := false
var _notebook_tree_name_action_v0215 := ""
var _notebook_tree_pending_delete_kind_v0215 := ""
var _notebook_tree_context_metadata_v0215: Dictionary = {}
var _notebook_tree_root_v0215: TreeItem
var _notebook_tree_last_query_v0215 := ""
var _notebook_tree_expanded_before_search_v0215: Array[String] = []
var _hierarchy_snapshot_v0215: Dictionary = {}
var _focused_idea_load_count_v0215_hotfix := 0
var _notebook_tree_refresh_count_v0215_hotfix := 0

var _idea_source_service_v0213 := IDEA_SOURCE_SERVICE_V0213.new()
var _active_idea_source_v0213: Dictionary = {}
var _active_source_saved_v0213 := false
var _active_source_external_path_v0213 := ""
var _source_editor_base_v0213: Dictionary = {}
var _source_saved_v0213 := false
var _source_external_path_v0213 := ""
var _source_tab_v0213: VBoxContainer
var _source_list_v0213: ItemList
var _source_visible_ids_v0213: Array[String] = []
var _source_title_v0213: LineEdit
var _source_description_v0213: TextEdit
var _source_version_v0213: LineEdit
var _source_bible_v0213: TextEdit
var _source_summary_v0213: TextEdit
var _source_premise_v0213: TextEdit
var _source_setup_v0213: TextEdit
var _source_variables_v0213: TextEdit
var _source_rules_v0213: TextEdit
var _source_guardrails_v0213: TextEdit
var _source_diversity_v0213: TextEdit
var _source_links_v0213: TextEdit
var _source_tags_v0213: LineEdit
var _source_notes_v0213: TextEdit
var _source_sections_v0213: TextEdit
var _source_raw_prompt_v0213: TextEdit
var _source_status_v0213: Label
var _active_source_panel_v0213: PanelContainer
var _active_source_banner_v0213: Label
var _active_source_explanation_v0213: Label
var _active_source_actions_v0213: HFlowContainer
var _active_source_view_button_v0213: Button
var _source_load_dialog_v0213: FileDialog
var _source_export_dialog_v0213: FileDialog
var _source_pending_export_v0213: Dictionary = {}
var _source_delete_dialog_v0213: ConfirmationDialog


func _ready() -> void:
	super._ready()
	_build_idea_pack_dialogs_v0210()
	_build_save_new_notebook_dialog_v0211()
	_build_idea_source_tab_v0213()
	_build_idea_source_dialogs_v0213()
	_install_active_source_banner_v0213()
	_refresh_source_library_v0213()


func _build_notebook_tab_v01532() -> void:
	super._build_notebook_tab_v01532()
	if _notebook_tab_v01532 == null:
		return
	_idea_list_v01532.select_mode = ItemList.SELECT_MULTI
	var multi_select_callback := Callable(self, "_on_idea_multi_selected_v0214")
	if not _idea_list_v01532.multi_selected.is_connected(multi_select_callback):
		_idea_list_v01532.multi_selected.connect(multi_select_callback)
	_install_notebook_organization_v0211()
	_install_notebook_folder_tree_v0215()
	var toolbar := VBoxContainer.new()
	toolbar.name = "IdeaPackActionsV0210"
	toolbar.add_theme_constant_override("separation", 8)
	var action_row := HFlowContainer.new()
	action_row.name = "IdeaPackActionButtonsV0210"
	action_row.add_theme_constant_override("separation", 8)
	toolbar.add_child(action_row)
	var import_button := Button.new()
	import_button.name = "ImportIdeaPackV0210"
	import_button.text = "Import Idea Pack…"
	import_button.tooltip_text = "Validate and preview a .ccfideas.json file before adding selected entries to Idea Notebook."
	import_button.pressed.connect(_open_import_dialog_v0210)
	action_row.add_child(import_button)
	var export_button := Button.new()
	export_button.name = "ExportIdeaPackV0210"
	export_button.text = "Choose Ideas & Export…"
	export_button.tooltip_text = "Choose checked ideas from all saved ideas, the live multi-selection, one Notebook, one Bible or one semantic Series, then export a structured Idea Pack."
	export_button.pressed.connect(_open_export_window_v0210)
	action_row.add_child(export_button)
	var explanation := Label.new()
	explanation.name = "IdeaPackExplanationV0210"
	explanation.text = "Idea Packs preserve Series, Seeds, rules, guardrails, links and custom sections."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	explanation.modulate = Color(0.72, 0.76, 0.86)
	toolbar.add_child(explanation)
	_notebook_tab_v01532.add_child(toolbar)
	_notebook_tab_v01532.move_child(toolbar, 1)

	if _idea_notebook_v01532 == null or _idea_notebook_v01532.get_parent() == null:
		return
	var notebook_box := _idea_notebook_v01532.get_parent()
	var editor := notebook_box.get_parent()
	if not editor is VBoxContainer:
		return
	var structured_box := VBoxContainer.new()
	structured_box.name = "StructuredIdeaDetailsV0210"
	structured_box.add_theme_constant_override("separation", 3)
	var label := Label.new()
	label.text = "Structured Idea Pack details"
	structured_box.add_child(label)
	_structured_detail_v0210 = TextEdit.new()
	_structured_detail_v0210.custom_minimum_size.y = 180
	_structured_detail_v0210.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_structured_detail_v0210.editable = false
	_structured_detail_v0210.placeholder_text = "Ordinary saved ideas have no additional structured fields."
	structured_box.add_child(_structured_detail_v0210)
	(editor as VBoxContainer).add_child(structured_box)
	(editor as VBoxContainer).move_child(structured_box, notebook_box.get_index() + 1)


func _install_notebook_organization_v0211() -> void:
	if _notebook_filter_v01532 == null or _idea_list_v01532 == null:
		return
	var filters := _notebook_filter_v01532.get_parent() as HFlowContainer
	if filters == null:
		return
	_notebook_search_v0211 = LineEdit.new()
	_notebook_search_v0211.name = "NotebookSearchV0211"
	_notebook_search_v0211.placeholder_text = "Find notebook…"
	_notebook_search_v0211.custom_minimum_size.x = 170
	_notebook_search_v0211.tooltip_text = (
		"Filter the notebook picker by name. All Ideas, Unfiled and the currently selected notebook remain available."
	)
	_notebook_search_v0211.text_changed.connect(
		func(_text: String) -> void: _refresh_notebook_v01532()
	)

	_notebook_sort_v0211 = OptionButton.new()
	_notebook_sort_v0211.name = "NotebookSortV0211"
	_notebook_sort_v0211.tooltip_text = "Choose how named notebooks are ordered in the picker."
	_add_option_v01532(_notebook_sort_v0211, "Notebooks: A–Z", "name")
	_add_option_v01532(_notebook_sort_v0211, "Notebooks: Most Ideas", "count")
	_add_option_v01532(_notebook_sort_v0211, "Notebooks: Recent Activity", "recent")
	_notebook_sort_v0211.item_selected.connect(
		func(_index: int) -> void: _refresh_notebook_v01532()
	)

	_idea_sort_v0211 = OptionButton.new()
	_idea_sort_v0211.name = "IdeaSortV0211"
	_idea_sort_v0211.tooltip_text = "Choose how ideas matching the current filters are ordered."
	_add_option_v01532(_idea_sort_v0211, "Ideas: Updated Newest", "updated_newest")
	_add_option_v01532(_idea_sort_v0211, "Ideas: Updated Oldest", "updated_oldest")
	_add_option_v01532(_idea_sort_v0211, "Ideas: Created Newest", "created_newest")
	_add_option_v01532(_idea_sort_v0211, "Ideas: Title A–Z", "title_az")
	_add_option_v01532(_idea_sort_v0211, "Ideas: Title Z–A", "title_za")
	_add_option_v01532(_idea_sort_v0211, "Ideas: Notebook then Title", "notebook_title")
	_idea_sort_v0211.item_selected.connect(
		func(_index: int) -> void: _refresh_ideas_v01532()
	)

	var list_panel := _idea_list_v01532.get_parent() as VBoxContainer
	if list_panel != null:
		var organization := VBoxContainer.new()
		organization.name = "IdeaNotebookOrganizationV0211"
		organization.add_theme_constant_override("separation", 4)
		_notebook_search_v0211.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_notebook_sort_v0211.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_idea_sort_v0211.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		organization.add_child(_notebook_search_v0211)
		organization.add_child(_notebook_sort_v0211)
		organization.add_child(_idea_sort_v0211)
		list_panel.add_child(organization)
		list_panel.move_child(organization, _idea_list_v01532.get_index())
		_idea_result_summary_v0211 = Label.new()
		_idea_result_summary_v0211.name = "IdeaResultSummaryV0211"
		_idea_result_summary_v0211.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_idea_result_summary_v0211.modulate = Color(0.64, 0.68, 0.82)
		list_panel.add_child(_idea_result_summary_v0211)
		list_panel.move_child(
			_idea_result_summary_v0211, organization.get_index() + 1
		)


func _install_notebook_folder_tree_v0215() -> void:
	if _idea_list_v01532 == null or _notebook_filter_v01532 == null:
		return
	_notebook_filter_v01532.visible = false
	var legacy_filters := _notebook_filter_v01532.get_parent()
	if legacy_filters != null:
		for child in legacy_filters.get_children():
			if child is Button and (child as Button).text in [
				"New Notebook…", "Rename…", "Delete Notebook…"
			]:
				(child as Button).visible = false
	var ideas_panel := _idea_list_v01532.get_parent() as VBoxContainer
	if ideas_panel == null:
		return
	var outer_split := ideas_panel.get_parent() as HSplitContainer
	if outer_split == null or outer_split.get_child_count() < 2:
		return
	var editor_panel := outer_split.get_child(1) as Control
	if editor_panel == null:
		return
	outer_split.remove_child(ideas_panel)
	outer_split.remove_child(editor_panel)
	outer_split.split_offset = 280

	var tree_panel := VBoxContainer.new()
	tree_panel.name = "IdeaNotebookTreePanelV0215"
	tree_panel.custom_minimum_size.x = 220
	tree_panel.add_theme_constant_override("separation", 5)
	outer_split.add_child(tree_panel)
	var tree_heading := Label.new()
	tree_heading.text = "Folders & Notebooks"
	tree_heading.add_theme_font_size_override("font_size", 17)
	tree_panel.add_child(tree_heading)
	var toolbar := HFlowContainer.new()
	toolbar.name = "IdeaNotebookTreeToolbarV0215"
	toolbar.add_theme_constant_override("separation", 5)
	tree_panel.add_child(toolbar)
	_add_tree_toolbar_button_v0215(toolbar, "+ Folder", "Create a folder inside the selected folder.", "new_folder")
	_add_tree_toolbar_button_v0215(toolbar, "+ Notebook", "Create a notebook in the selected folder.", "new_notebook")
	_add_tree_toolbar_button_v0215(toolbar, "Rename", "Rename the selected folder or notebook.", "rename")
	_add_tree_toolbar_button_v0215(toolbar, "Delete", "Safely delete the selected folder or notebook.", "delete")

	var organization := ideas_panel.get_node_or_null("IdeaNotebookOrganizationV0211") as VBoxContainer
	if organization != null:
		if _notebook_search_v0211.get_parent() == organization:
			organization.remove_child(_notebook_search_v0211)
			tree_panel.add_child(_notebook_search_v0211)
		if _notebook_sort_v0211.get_parent() == organization:
			organization.remove_child(_notebook_sort_v0211)
			tree_panel.add_child(_notebook_sort_v0211)
	_notebook_search_v0211.placeholder_text = "Find folder or notebook…"
	_notebook_search_v0211.tooltip_text = "Search the hierarchy while retaining matching items and their ancestor path."
	_notebook_sort_v0211.tooltip_text = "Sort notebook siblings inside every folder. Folders remain grouped first."

	_notebook_tree_v0215 = IDEA_NOTEBOOK_TREE_V0215.new()
	_notebook_tree_v0215.name = "IdeaNotebookFolderTreeV0215"
	_notebook_tree_v0215.hide_root = true
	_notebook_tree_v0215.columns = 1
	_notebook_tree_v0215.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_notebook_tree_v0215.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_notebook_tree_v0215.allow_reselect = true
	_notebook_tree_v0215.set_column_expand(0, true)
	_notebook_tree_v0215.set_column_custom_minimum_width(0, 220)
	_notebook_tree_v0215.item_selected.connect(_on_notebook_tree_selected_v0215)
	_notebook_tree_v0215.item_collapsed.connect(_on_notebook_tree_collapsed_v0215)
	_notebook_tree_v0215.gui_input.connect(_on_notebook_tree_gui_input_v0215)
	(_notebook_tree_v0215 as CCFIdeaNotebookTreeV0215).hierarchy_drop.connect(
		_on_notebook_tree_drop_v0215
	)
	tree_panel.add_child(_notebook_tree_v0215)

	var inner_split := HSplitContainer.new()
	inner_split.name = "IdeaNotebookIdeasAndDetailsV0215"
	inner_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner_split.split_offset = 360
	outer_split.add_child(inner_split)
	inner_split.add_child(ideas_panel)
	inner_split.add_child(editor_panel)
	ideas_panel.custom_minimum_size.x = 280
	editor_panel.custom_minimum_size.x = 380

	_notebook_tree_popup_v0215 = PopupMenu.new()
	_notebook_tree_popup_v0215.name = "IdeaNotebookTreeContextV0215"
	_notebook_tree_popup_v0215.id_pressed.connect(_on_notebook_tree_context_action_v0215)
	add_child(_notebook_tree_popup_v0215)


func _add_tree_toolbar_button_v0215(
	parent: Control, label: String, tooltip: String, action: String
) -> void:
	var button := Button.new()
	button.text = label
	button.tooltip_text = tooltip
	button.pressed.connect(_on_notebook_tree_toolbar_v0215.bind(action))
	parent.add_child(button)


func _on_notebook_tree_toolbar_v0215(action: String) -> void:
	match action:
		"new_folder": _open_tree_name_dialog_v0215("new_folder")
		"new_notebook": _open_tree_name_dialog_v0215("new_notebook")
		"rename": _open_tree_name_dialog_v0215("rename")
		"delete": _request_tree_delete_v0215()


func _open_tree_name_dialog_v0215(action: String) -> void:
	_notebook_tree_name_action_v0215 = action
	_name_action_v01532 = action
	var metadata := _selected_tree_metadata_v0215()
	var kind := str(metadata.get("kind", "special"))
	var target_parent := _tree_creation_parent_v0215()
	var target_path := NOTEBOOK_SERVICE.folder_path(target_parent)
	var location := "root" if target_path.is_empty() else "‘%s’" % target_path
	if action == "rename":
		if kind != "folder" and kind != "notebook":
			_status_v01532.text = "All Ideas and Unfiled are built-in views and cannot be renamed."
			return
		_name_input_v01532.text = str(metadata.get("name", ""))
		_name_dialog_v01532.dialog_text = "Rename the selected %s. Its stable ID and contents will not change." % kind
		_name_dialog_v01532.ok_button_text = "Rename"
	elif action == "new_folder":
		_name_input_v01532.text = ""
		_name_dialog_v01532.dialog_text = "Create a new folder inside %s." % location
		_name_dialog_v01532.ok_button_text = "Create Folder"
	else:
		_name_input_v01532.text = ""
		_name_dialog_v01532.dialog_text = "Create a new notebook inside %s." % location
		_name_dialog_v01532.ok_button_text = "Create Notebook"
	_name_dialog_v01532.popup_centered()
	_name_input_v01532.grab_focus()


func _open_name_dialog_v01532(action: String) -> void:
	_open_tree_name_dialog_v0215("rename" if action == "rename" else "new_notebook")


func _apply_name_dialog_v01532() -> void:
	var metadata := _selected_tree_metadata_v0215()
	var result: Dictionary
	match _notebook_tree_name_action_v0215:
		"new_folder":
			result = NOTEBOOK_SERVICE.create_folder(
				_name_input_v01532.text, _tree_creation_parent_v0215()
			)
			if bool(result.get("ok", false)):
				var folder: Dictionary = result.get("folder", {})
				_notebook_tree_selection_kind_v0215 = "folder"
				_notebook_tree_selection_id_v0215 = str(folder.get("id", ""))
		"new_notebook":
			result = NOTEBOOK_SERVICE.create_notebook(
				_name_input_v01532.text, _tree_creation_parent_v0215()
			)
			if bool(result.get("ok", false)):
				var notebook: Dictionary = result.get("notebook", {})
				_notebook_tree_selection_kind_v0215 = "notebook"
				_notebook_tree_selection_id_v0215 = str(notebook.get("id", ""))
		"rename":
			var kind := str(metadata.get("kind", ""))
			if kind == "folder":
				result = NOTEBOOK_SERVICE.rename_folder(
					str(metadata.get("id", "")), _name_input_v01532.text
				)
			elif kind == "notebook":
				result = NOTEBOOK_SERVICE.rename_notebook(
					str(metadata.get("id", "")), _name_input_v01532.text
				)
			else:
				result = {"ok": false, "error": "Select a folder or notebook to rename."}
		_:
			result = {"ok": false, "error": "Unknown notebook action."}
	if not bool(result.get("ok", false)):
		_status_v01532.text = str(result.get("error", "Could not update the notebook hierarchy."))
		return
	_refresh_notebook_v01532()
	_status_v01532.text = "Idea Notebook hierarchy updated."


func _request_tree_delete_v0215() -> void:
	var metadata := _selected_tree_metadata_v0215()
	var kind := str(metadata.get("kind", "special"))
	var item_name := str(metadata.get("name", ""))
	if kind == "folder":
		_notebook_tree_pending_delete_kind_v0215 = "folder"
		_delete_notebook_dialog_v01532.title = "Delete Idea Notebook Folder"
		_delete_notebook_dialog_v01532.ok_button_text = "Delete Folder"
		_delete_notebook_dialog_v01532.dialog_text = (
			"Delete folder ‘%s’? Its subfolders and notebooks will be kept and moved to the parent level. No ideas will be deleted."
			% item_name
		)
	elif kind == "notebook":
		_notebook_tree_pending_delete_kind_v0215 = "notebook"
		_delete_notebook_dialog_v01532.title = "Delete Idea Notebook"
		_delete_notebook_dialog_v01532.ok_button_text = "Delete Notebook"
		_delete_notebook_dialog_v01532.dialog_text = (
			"Delete notebook ‘%s’? Its saved ideas will be kept and moved to Unfiled."
			% item_name
		)
	else:
		_status_v01532.text = "All Ideas and Unfiled are built-in views and cannot be deleted."
		return
	_delete_notebook_dialog_v01532.popup_centered()


func _request_delete_notebook_v01532() -> void:
	_request_tree_delete_v0215()


func _delete_selected_notebook_v01532() -> void:
	var metadata := _selected_tree_metadata_v0215()
	var item_id := str(metadata.get("id", ""))
	var result: Dictionary
	if _notebook_tree_pending_delete_kind_v0215 == "folder":
		result = NOTEBOOK_SERVICE.delete_folder(item_id)
	else:
		result = NOTEBOOK_SERVICE.delete_notebook(item_id)
	if not bool(result.get("ok", false)):
		_status_v01532.text = str(result.get("error", "Could not delete the selected item."))
		return
	_notebook_tree_selection_kind_v0215 = "special"
	_notebook_tree_selection_id_v0215 = "__all__"
	_refresh_notebook_v01532()
	_status_v01532.text = (
		"Folder deleted; its contents were kept at the parent level."
		if _notebook_tree_pending_delete_kind_v0215 == "folder"
		else "Notebook deleted; its ideas are now Unfiled."
	)


func _tree_creation_parent_v0215() -> String:
	var metadata := _selected_tree_metadata_v0215()
	var kind := str(metadata.get("kind", "special"))
	if kind == "folder":
		return str(metadata.get("id", ""))
	if kind == "notebook":
		return str(metadata.get("parent_folder_id", ""))
	return ""


func _selected_tree_metadata_v0215() -> Dictionary:
	if _notebook_tree_v0215 != null:
		var item := _notebook_tree_v0215.get_selected()
		if item != null:
			var value: Variant = item.get_metadata(0)
			if value is Dictionary:
				return (value as Dictionary).duplicate(true)
	return {
		"kind": _notebook_tree_selection_kind_v0215,
		"id": _notebook_tree_selection_id_v0215,
		"name": ""
	}


func _open_save_generated_v01532() -> void:
	super._open_save_generated_v01532()
	if _save_generated_notebook_v01532 == null:
		return
	var target_row := _save_generated_notebook_v01532.get_parent() as HBoxContainer
	if target_row == null:
		return
	var create_button := Button.new()
	create_button.name = "NewNotebookWhileSavingV0211"
	create_button.text = "New Notebook…"
	create_button.tooltip_text = (
		"Create a notebook and select it as the destination without leaving this save window."
	)
	create_button.pressed.connect(_open_new_notebook_while_saving_v0211)
	target_row.add_child(create_button)
	target_row.move_child(
		create_button, _save_generated_notebook_v01532.get_index() + 1
	)


func _build_save_new_notebook_dialog_v0211() -> void:
	_save_new_notebook_dialog_v0211 = ConfirmationDialog.new()
	_save_new_notebook_dialog_v0211.name = "SaveNewNotebookDialogV0211"
	_save_new_notebook_dialog_v0211.visible = false
	_save_new_notebook_dialog_v0211.title = "Create Destination Notebook"
	_save_new_notebook_dialog_v0211.dialog_text = (
		"Name the notebook that should receive the selected generated ideas."
	)
	_save_new_notebook_dialog_v0211.ok_button_text = "Create and Select"
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	_save_new_notebook_dialog_v0211.add_child(content)
	_save_new_notebook_name_v0211 = LineEdit.new()
	_save_new_notebook_name_v0211.name = "SaveNewNotebookNameV0211"
	_save_new_notebook_name_v0211.placeholder_text = "Notebook name"
	_save_new_notebook_name_v0211.custom_minimum_size.x = 400
	content.add_child(_save_new_notebook_name_v0211)
	_save_new_notebook_folder_v0215 = OptionButton.new()
	_save_new_notebook_folder_v0215.name = "SaveNewNotebookFolderV0215"
	_save_new_notebook_folder_v0215.tooltip_text = "Choose the organisational folder for the new notebook."
	content.add_child(_save_new_notebook_folder_v0215)
	_save_new_notebook_dialog_v0211.confirmed.connect(
		_create_notebook_while_saving_v0211
	)
	add_child(_save_new_notebook_dialog_v0211)
	_save_new_notebook_dialog_v0211.hide()


func _open_new_notebook_while_saving_v0211() -> void:
	if _save_new_notebook_dialog_v0211 == null:
		return
	_save_new_notebook_name_v0211.text = ""
	_fill_folder_destinations_v0215(
		_save_new_notebook_folder_v0215, _tree_creation_parent_v0215()
	)
	_save_new_notebook_dialog_v0211.popup_centered()
	_save_new_notebook_name_v0211.grab_focus()


func _create_notebook_while_saving_v0211() -> void:
	var result := NOTEBOOK_SERVICE.create_notebook(
		_save_new_notebook_name_v0211.text,
		_selected_metadata_v01532(_save_new_notebook_folder_v0215, "")
	)
	if not bool(result.get("ok", false)):
		if _save_generated_status_v01532 != null:
			_save_generated_status_v01532.text = str(
				result.get("error", "Could not create the destination notebook.")
			)
		return
	var notebook_value: Variant = result.get("notebook", {})
	var notebook: Dictionary = (
		notebook_value if notebook_value is Dictionary else {}
	)
	var notebook_id := str(notebook.get("id", ""))
	_fill_destination_notebooks_v01532(
		_save_generated_notebook_v01532, notebook_id
	)
	_refresh_notebook_v01532()
	if _save_generated_status_v01532 != null:
		_save_generated_status_v01532.text = (
			"Created and selected notebook ‘%s’. Choose Save Selected when ready."
			% NOTEBOOK_SERVICE.notebook_path(notebook_id)
		)


func _fill_destination_notebooks_v01532(
	selector: OptionButton, selected_id: String
) -> void:
	if selector == null:
		return
	selector.clear()
	_add_option_v01532(selector, "Unfiled", "")
	var snapshot := NOTEBOOK_SERVICE.hierarchy_snapshot()
	var notebook_paths: Dictionary = snapshot.get("notebook_paths", {})
	var notebooks: Array = snapshot.get("notebooks", []).duplicate(true)
	notebooks.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		return str(notebook_paths.get(str(first.get("id", "")), "")).to_lower() < str(notebook_paths.get(str(second.get("id", "")), "")).to_lower()
	)
	for notebook in notebooks:
		var notebook_id := str(notebook.get("id", ""))
		_add_option_v01532(
			selector, str(notebook_paths.get(notebook_id, notebook.get("name", "Notebook"))), notebook_id
		)
	_select_metadata_v01532(selector, selected_id, "")


func _fill_folder_destinations_v0215(
	selector: OptionButton, selected_id: String
) -> void:
	if selector == null:
		return
	selector.clear()
	_add_option_v01532(selector, "Root level", "")
	var snapshot := NOTEBOOK_SERVICE.hierarchy_snapshot()
	var folder_paths: Dictionary = snapshot.get("folder_paths", {})
	var folders: Array = snapshot.get("folders", []).duplicate(true)
	folders.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		return str(folder_paths.get(str(first.get("id", "")), "")).to_lower() < str(folder_paths.get(str(second.get("id", "")), "")).to_lower()
	)
	for folder in folders:
		var folder_id := str(folder.get("id", ""))
		_add_option_v01532(
			selector, str(folder_paths.get(folder_id, folder.get("name", "Folder"))), folder_id
		)
	_select_metadata_v01532(selector, selected_id, "")


func _selected_named_notebook_v01532() -> String:
	return (
		_notebook_tree_selection_id_v0215
		if _notebook_tree_selection_kind_v0215 == "notebook"
		else ""
	)


func _selected_notebook_name_v01532() -> String:
	if _notebook_tree_selection_kind_v0215 != "notebook":
		return ""
	var snapshot := NOTEBOOK_SERVICE.hierarchy_snapshot()
	return NOTEBOOK_SERVICE.notebook_path_from_snapshot(
		_notebook_tree_selection_id_v0215, snapshot
	)


func _refresh_notebook_v01532() -> void:
	if _notebook_filter_v01532 == null:
		return
	var selected_tag := _selected_metadata_v01532(_tag_filter_v01532, "")
	var include_archived := _show_archived_v01532 != null and _show_archived_v01532.button_pressed
	_hierarchy_snapshot_v0215 = NOTEBOOK_SERVICE.hierarchy_snapshot()
	var all_ideas := NOTEBOOK_SERVICE.list_ideas({"include_archived": true})
	_refresh_notebook_tree_v0215(
		include_archived, _hierarchy_snapshot_v0215, all_ideas
	)
	_tag_filter_v01532.clear()
	_add_option_v01532(_tag_filter_v01532, "All Tags", "")
	for tag in _all_tags_from_ideas_v0215(all_ideas, include_archived):
		_add_option_v01532(_tag_filter_v01532, tag, tag)
	_select_metadata_v01532(_tag_filter_v01532, selected_tag, "")
	_refresh_ideas_v01532(_hierarchy_snapshot_v0215)


func _all_tags_from_ideas_v0215(
	ideas: Array, include_archived: bool
) -> Array[String]:
	var seen := {}
	var result: Array[String] = []
	for idea_value in ideas:
		if not idea_value is Dictionary:
			continue
		var idea: Dictionary = idea_value
		if not include_archived and bool(idea.get("archived", false)):
			continue
		for raw_tag in idea.get("tags", []):
			var tag := str(raw_tag).strip_edges()
			var key := tag.to_lower()
			if tag.is_empty() or seen.has(key):
				continue
			seen[key] = true
			result.append(tag)
	result.sort_custom(func(first: String, second: String) -> bool:
		return first.to_lower() < second.to_lower()
	)
	return result


func _refresh_notebook_tree_v0215(
	include_archived: bool,
	snapshot: Dictionary = {},
	all_ideas: Array = []
) -> void:
	if _notebook_tree_v0215 == null:
		return
	_notebook_tree_refresh_count_v0215_hotfix += 1
	var snapshot_supplied := not snapshot.is_empty()
	if not snapshot_supplied:
		snapshot = NOTEBOOK_SERVICE.hierarchy_snapshot()
	if all_ideas.is_empty() and not snapshot_supplied:
		all_ideas = NOTEBOOK_SERVICE.list_ideas({"include_archived": true})
	_hierarchy_snapshot_v0215 = snapshot
	var query := _notebook_search_v0211.text.strip_edges().to_lower() if _notebook_search_v0211 != null else ""
	var live_expanded := _live_expanded_folder_ids_v0215()
	if _notebook_tree_last_query_v0215.is_empty() and _notebook_tree_v0215.get_root() != null:
		NOTEBOOK_SERVICE.save_expanded_folder_ids(live_expanded)
		if not query.is_empty():
			_notebook_tree_expanded_before_search_v0215 = live_expanded.duplicate()
	elif not _notebook_tree_last_query_v0215.is_empty() and query.is_empty():
		NOTEBOOK_SERVICE.save_expanded_folder_ids(
			_notebook_tree_expanded_before_search_v0215
		)
	var expanded := NOTEBOOK_SERVICE.expanded_folder_ids()
	if (
		not query.is_empty()
		and _notebook_tree_last_query_v0215.is_empty()
		and _notebook_tree_v0215.get_root() == null
	):
		_notebook_tree_expanded_before_search_v0215 = expanded.duplicate()
	_notebook_tree_last_query_v0215 = query
	var folders: Array = snapshot.get("folders", [])
	var notebooks: Array = snapshot.get("notebooks", [])
	var count_snapshot := NOTEBOOK_SERVICE.hierarchy_counts_from_snapshot(
		snapshot, all_ideas, include_archived
	)
	var counts: Dictionary = count_snapshot.get("notebook_counts", {})
	var folder_counts: Dictionary = count_snapshot.get("folder_counts", {})
	var activity := {}
	for notebook in notebooks:
		activity[str(notebook.get("id", ""))] = str(notebook.get("updated_at", ""))
	for idea in all_ideas:
		var notebook_id := str(idea.get("notebook_id", ""))
		var updated := str(idea.get("updated_at", ""))
		if not notebook_id.is_empty() and updated > str(activity.get(notebook_id, "")):
			activity[notebook_id] = updated
	var folder_by_id := {}
	var folder_children := {}
	var notebooks_by_parent := {}
	for folder in folders:
		var folder_id := str(folder.get("id", ""))
		var parent_id := str(folder.get("parent_folder_id", ""))
		folder_by_id[folder_id] = folder
		if not folder_children.has(parent_id):
			folder_children[parent_id] = []
		(folder_children[parent_id] as Array).append(folder)
	for notebook in notebooks:
		var parent_id := str(notebook.get("parent_folder_id", ""))
		if not notebooks_by_parent.has(parent_id):
			notebooks_by_parent[parent_id] = []
		(notebooks_by_parent[parent_id] as Array).append(notebook)
	for values in folder_children.values():
		(values as Array).sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
			return str(first.get("name", "")).to_lower() < str(second.get("name", "")).to_lower()
		)
	var notebook_sort := _selected_metadata_v01532(_notebook_sort_v0211, "name")
	for values in notebooks_by_parent.values():
		(values as Array).sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
			return _notebook_tree_sort_less_v0215(first, second, notebook_sort, counts, activity)
		)
	var visible_folders := {}
	var visible_notebooks := {}
	if query.is_empty():
		for folder in folders:
			visible_folders[str(folder.get("id", ""))] = true
		for notebook in notebooks:
			visible_notebooks[str(notebook.get("id", ""))] = true
	else:
		for folder in folders:
			if str(folder.get("name", "")).to_lower().contains(query):
				_mark_folder_subtree_visible_v0215(
					str(folder.get("id", "")), folder_by_id, folder_children,
					notebooks_by_parent, visible_folders, visible_notebooks
				)
		for notebook in notebooks:
			if str(notebook.get("name", "")).to_lower().contains(query):
				visible_notebooks[str(notebook.get("id", ""))] = true
				_mark_folder_ancestors_visible_v0215(
					str(notebook.get("parent_folder_id", "")), folder_by_id, visible_folders
				)
	_mark_selected_tree_path_visible_v0215(
		folder_by_id, notebooks, visible_folders, visible_notebooks
	)
	var selected_parent := ""
	if _notebook_tree_selection_kind_v0215 == "folder" and folder_by_id.has(_notebook_tree_selection_id_v0215):
		selected_parent = str((folder_by_id[_notebook_tree_selection_id_v0215] as Dictionary).get("parent_folder_id", ""))
	elif _notebook_tree_selection_kind_v0215 == "notebook":
		for notebook in notebooks:
			if str(notebook.get("id", "")) == _notebook_tree_selection_id_v0215:
				selected_parent = str(notebook.get("parent_folder_id", ""))
				break
	var expand_cursor := selected_parent
	var expand_visited := {}
	while not expand_cursor.is_empty() and folder_by_id.has(expand_cursor) and not expand_visited.has(expand_cursor):
		expand_visited[expand_cursor] = true
		if not expand_cursor in expanded:
			expanded.append(expand_cursor)
		expand_cursor = str((folder_by_id[expand_cursor] as Dictionary).get("parent_folder_id", ""))

	_notebook_tree_rebuilding_v0215 = true
	_notebook_tree_v0215.clear()
	_notebook_tree_items_v0215.clear()
	_notebook_tree_root_v0215 = _notebook_tree_v0215.create_item()
	_add_tree_item_v0215(
		_notebook_tree_root_v0215, "All Ideas (%d)" % int(counts.get("__all__", 0)),
		{"kind": "special", "id": "__all__", "name": "All Ideas"}, "All saved ideas"
	)
	_add_tree_item_v0215(
		_notebook_tree_root_v0215, "Unfiled (%d)" % int(counts.get("__unfiled__", 0)),
		{"kind": "special", "id": "__unfiled__", "name": "Unfiled"}, "Ideas not assigned to a notebook"
	)
	_add_tree_children_v0215(
		_notebook_tree_root_v0215, "", folder_children, notebooks_by_parent,
		visible_folders, visible_notebooks, counts, folder_counts, expanded, not query.is_empty()
	)
	var selected_key := "%s:%s" % [
		_notebook_tree_selection_kind_v0215,
		_notebook_tree_selection_id_v0215
	]
	var selected_item: TreeItem = _notebook_tree_items_v0215.get(selected_key)
	if selected_item == null:
		selected_item = _notebook_tree_items_v0215.get("special:__all__")
		_notebook_tree_selection_kind_v0215 = "special"
		_notebook_tree_selection_id_v0215 = "__all__"
	if selected_item != null:
		selected_item.select(0)
	_notebook_tree_rebuilding_v0215 = false
	_refresh_legacy_notebook_filter_v0215(notebooks, counts, query)


func _add_tree_children_v0215(
	parent: TreeItem,
	parent_id: String,
	folder_children: Dictionary,
	notebooks_by_parent: Dictionary,
	visible_folders: Dictionary,
	visible_notebooks: Dictionary,
	counts: Dictionary,
	folder_counts: Dictionary,
	expanded: Array[String],
	force_expand: bool
) -> void:
	for folder_value in folder_children.get(parent_id, []):
		var folder: Dictionary = folder_value
		var folder_id := str(folder.get("id", ""))
		if not visible_folders.has(folder_id):
			continue
		var path := NOTEBOOK_SERVICE.folder_path_from_snapshot(
			folder_id, _hierarchy_snapshot_v0215
		)
		var item := _add_tree_item_v0215(
			parent,
			"%s (%d)" % [str(folder.get("name", "Folder")), int(folder_counts.get(folder_id, 0))],
			{
				"kind": "folder", "id": folder_id,
				"name": str(folder.get("name", "Folder")),
				"parent_folder_id": str(folder.get("parent_folder_id", ""))
			},
			path
		)
		item.collapsed = not force_expand and not folder_id in expanded
		_add_tree_children_v0215(
			item, folder_id, folder_children, notebooks_by_parent,
			visible_folders, visible_notebooks, counts, folder_counts, expanded, force_expand
		)
	for notebook_value in notebooks_by_parent.get(parent_id, []):
		var notebook: Dictionary = notebook_value
		var notebook_id := str(notebook.get("id", ""))
		if not visible_notebooks.has(notebook_id):
			continue
		_add_tree_item_v0215(
			parent,
			"%s (%d)" % [str(notebook.get("name", "Notebook")), int(counts.get(notebook_id, 0))],
			{
				"kind": "notebook", "id": notebook_id,
				"name": str(notebook.get("name", "Notebook")),
				"parent_folder_id": str(notebook.get("parent_folder_id", ""))
			},
			NOTEBOOK_SERVICE.notebook_path_from_snapshot(
				notebook_id, _hierarchy_snapshot_v0215
			)
		)


func _add_tree_item_v0215(
	parent: TreeItem, label: String, metadata: Dictionary, tooltip: String
) -> TreeItem:
	var item := _notebook_tree_v0215.create_item(parent)
	item.set_text(0, label)
	item.set_metadata(0, metadata)
	item.set_tooltip_text(0, tooltip)
	_notebook_tree_items_v0215["%s:%s" % [metadata.get("kind", ""), metadata.get("id", "")]] = item
	return item


func _notebook_tree_sort_less_v0215(
	first: Dictionary, second: Dictionary, mode: String,
	counts: Dictionary, activity: Dictionary
) -> bool:
	if mode == "count":
		var first_count := int(counts.get(str(first.get("id", "")), 0))
		var second_count := int(counts.get(str(second.get("id", "")), 0))
		if first_count != second_count:
			return first_count > second_count
	elif mode == "recent":
		var first_updated := str(activity.get(str(first.get("id", "")), first.get("updated_at", "")))
		var second_updated := str(activity.get(str(second.get("id", "")), second.get("updated_at", "")))
		if first_updated != second_updated:
			return first_updated > second_updated
	return str(first.get("name", "")).to_lower() < str(second.get("name", "")).to_lower()


func _mark_folder_ancestors_visible_v0215(
	folder_id: String, folder_by_id: Dictionary, visible_folders: Dictionary
) -> void:
	var cursor := folder_id
	var visited := {}
	while not cursor.is_empty() and folder_by_id.has(cursor) and not visited.has(cursor):
		visited[cursor] = true
		visible_folders[cursor] = true
		cursor = str((folder_by_id[cursor] as Dictionary).get("parent_folder_id", ""))


func _mark_folder_subtree_visible_v0215(
	folder_id: String, folder_by_id: Dictionary, folder_children: Dictionary,
	notebooks_by_parent: Dictionary, visible_folders: Dictionary,
	visible_notebooks: Dictionary
) -> void:
	_mark_folder_ancestors_visible_v0215(folder_id, folder_by_id, visible_folders)
	var pending: Array[String] = [folder_id]
	var visited := {}
	while not pending.is_empty():
		var current: String = pending.pop_back()
		if visited.has(current):
			continue
		visited[current] = true
		visible_folders[current] = true
		for notebook_value in notebooks_by_parent.get(current, []):
			visible_notebooks[str((notebook_value as Dictionary).get("id", ""))] = true
		for child_value in folder_children.get(current, []):
			pending.append(str((child_value as Dictionary).get("id", "")))


func _mark_selected_tree_path_visible_v0215(
	folder_by_id: Dictionary, notebooks: Array,
	visible_folders: Dictionary, visible_notebooks: Dictionary
) -> void:
	if _notebook_tree_selection_kind_v0215 == "folder":
		_mark_folder_ancestors_visible_v0215(
			_notebook_tree_selection_id_v0215, folder_by_id, visible_folders
		)
	elif _notebook_tree_selection_kind_v0215 == "notebook":
		visible_notebooks[_notebook_tree_selection_id_v0215] = true
		for notebook in notebooks:
			if str(notebook.get("id", "")) == _notebook_tree_selection_id_v0215:
				_mark_folder_ancestors_visible_v0215(
					str(notebook.get("parent_folder_id", "")), folder_by_id, visible_folders
				)
				break


func _refresh_legacy_notebook_filter_v0215(
	notebooks: Array[Dictionary], counts: Dictionary, query: String
) -> void:
	_notebook_filter_v01532.clear()
	_add_option_v01532(_notebook_filter_v01532, "All Ideas (%d)" % int(counts.get("__all__", 0)), "__all__")
	_add_option_v01532(_notebook_filter_v01532, "Unfiled (%d)" % int(counts.get("__unfiled__", 0)), "__unfiled__")
	for notebook in notebooks:
		var notebook_id := str(notebook.get("id", ""))
		var path := NOTEBOOK_SERVICE.notebook_path_from_snapshot(
			notebook_id, _hierarchy_snapshot_v0215
		)
		if not query.is_empty() and not path.to_lower().contains(query):
			continue
		_add_option_v01532(
			_notebook_filter_v01532,
			"%s (%d)" % [path, int(counts.get(notebook_id, 0))], notebook_id
		)
	var legacy_value := _notebook_tree_selection_id_v0215
	if _notebook_tree_selection_kind_v0215 == "folder":
		legacy_value = "__all__"
	_select_metadata_v01532(_notebook_filter_v01532, legacy_value, "__all__")


func _on_notebook_tree_selected_v0215() -> void:
	if _notebook_tree_rebuilding_v0215:
		return
	var metadata := _selected_tree_metadata_v0215()
	_notebook_tree_selection_kind_v0215 = str(metadata.get("kind", "special"))
	_notebook_tree_selection_id_v0215 = str(metadata.get("id", "__all__"))
	var legacy_value := _notebook_tree_selection_id_v0215
	if _notebook_tree_selection_kind_v0215 == "folder":
		legacy_value = "__all__"
	_select_metadata_v01532(_notebook_filter_v01532, legacy_value, "__all__")
	_refresh_ideas_v01532()


func _on_notebook_tree_collapsed_v0215(_item: TreeItem) -> void:
	if _notebook_tree_rebuilding_v0215:
		return
	NOTEBOOK_SERVICE.save_expanded_folder_ids(_live_expanded_folder_ids_v0215())


func _live_expanded_folder_ids_v0215() -> Array[String]:
	var result: Array[String] = []
	if _notebook_tree_v0215 == null:
		return result
	var root_item := _notebook_tree_v0215.get_root()
	if root_item == null:
		return result
	var pending: Array[TreeItem] = []
	var child: TreeItem = root_item.get_first_child()
	while child != null:
		pending.append(child)
		child = child.get_next()
	while not pending.is_empty():
		var item: TreeItem = pending.pop_back()
		var metadata_value: Variant = item.get_metadata(0)
		if metadata_value is Dictionary:
			var metadata: Dictionary = metadata_value
			if str(metadata.get("kind", "")) == "folder" and not item.collapsed:
				result.append(str(metadata.get("id", "")))
		var nested: TreeItem = item.get_first_child()
		while nested != null:
			pending.append(nested)
			nested = nested.get_next()
	return result


func _on_notebook_tree_gui_input_v0215(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_RIGHT:
		return
	var item := _notebook_tree_v0215.get_item_at_position(mouse_event.position)
	if item != null:
		item.select(0)
		_on_notebook_tree_selected_v0215()
		var metadata_value: Variant = item.get_metadata(0)
		_notebook_tree_context_metadata_v0215 = (
			(metadata_value as Dictionary).duplicate(true)
			if metadata_value is Dictionary else {}
		)
	else:
		_notebook_tree_context_metadata_v0215 = {
			"kind": "special", "id": "__all__", "name": "All Ideas"
		}
		_notebook_tree_selection_kind_v0215 = "special"
		_notebook_tree_selection_id_v0215 = "__all__"
		var all_item: TreeItem = _notebook_tree_items_v0215.get("special:__all__")
		if all_item != null:
			all_item.select(0)
	_notebook_tree_popup_v0215.clear()
	_notebook_tree_popup_v0215.add_item("New Folder…", 1)
	_notebook_tree_popup_v0215.add_item("New Notebook…", 2)
	var kind := str(_notebook_tree_context_metadata_v0215.get("kind", "special"))
	if kind == "folder" or kind == "notebook":
		_notebook_tree_popup_v0215.add_separator()
		_notebook_tree_popup_v0215.add_item("Rename…", 3)
		_notebook_tree_popup_v0215.add_item(
			"Delete Folder…" if kind == "folder" else "Delete Notebook…", 4
		)
	_notebook_tree_popup_v0215.position = Vector2i(
		_notebook_tree_v0215.get_screen_position() + mouse_event.position
	)
	_notebook_tree_popup_v0215.popup()


func _on_notebook_tree_context_action_v0215(action_id: int) -> void:
	match action_id:
		1: _open_tree_name_dialog_v0215("new_folder")
		2: _open_tree_name_dialog_v0215("new_notebook")
		3: _open_tree_name_dialog_v0215("rename")
		4: _request_tree_delete_v0215()


func _on_notebook_tree_drop_v0215(
	kind: String, item_id: String, destination_folder_id: String
) -> void:
	var result := (
		NOTEBOOK_SERVICE.move_folder(item_id, destination_folder_id)
		if kind == "folder"
		else NOTEBOOK_SERVICE.move_notebook(item_id, destination_folder_id)
	)
	if not bool(result.get("ok", false)):
		_status_v01532.text = str(result.get("error", "Could not move the selected item."))
		return
	_notebook_tree_selection_kind_v0215 = kind
	_notebook_tree_selection_id_v0215 = item_id
	_refresh_notebook_v01532()
	var destination_path := NOTEBOOK_SERVICE.folder_path(destination_folder_id)
	_status_v01532.text = "Moved to %s." % (
		"the root level" if destination_path.is_empty() else destination_path
	)


func _refresh_ideas_v01532(snapshot: Dictionary = {}) -> void:
	if _idea_list_v01532 == null:
		return
	if snapshot.is_empty():
		snapshot = NOTEBOOK_SERVICE.hierarchy_snapshot()
	_hierarchy_snapshot_v0215 = snapshot
	var selected_ids_before := _live_notebook_selected_ids_v0214()
	var selected_notebook := _notebook_tree_selection_id_v0215
	var selected_kind := _notebook_tree_selection_kind_v0215
	var filters := {
		"notebook_id": (
			selected_notebook if selected_kind != "folder" else "__all__"
		),
		"tag": _selected_metadata_v01532(_tag_filter_v01532, ""),
		"search": _search_v01532.text if _search_v01532 != null else "",
		"include_archived": (
			_show_archived_v01532 != null
			and _show_archived_v01532.button_pressed
		)
	}
	if selected_kind == "folder":
		filters["notebook_ids"] = NOTEBOOK_SERVICE.notebook_ids_in_folder_from_snapshot(
			selected_notebook, snapshot, true
		)
	var rows := NOTEBOOK_SERVICE.list_ideas(filters)
	var notebook_names := {"": "Unfiled"}
	var notebook_paths: Dictionary = snapshot.get("notebook_paths", {})
	for notebook in snapshot.get("notebooks", []):
		var notebook_id := str(notebook.get("id", ""))
		notebook_names[str(notebook.get("id", ""))] = str(
			notebook_paths.get(notebook_id, notebook.get("name", "Notebook"))
		)
	var sort_mode := _selected_metadata_v01532(
		_idea_sort_v0211, "updated_newest"
	)
	rows.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		var first_title := str(first.get("title", "")).to_lower()
		var second_title := str(second.get("title", "")).to_lower()
		if sort_mode == "updated_oldest":
			return str(first.get("updated_at", "")) < str(second.get("updated_at", ""))
		if sort_mode == "created_newest":
			return str(first.get("created_at", "")) > str(second.get("created_at", ""))
		if sort_mode == "title_az":
			return first_title < second_title
		if sort_mode == "title_za":
			return first_title > second_title
		if sort_mode == "notebook_title":
			var first_notebook := str(notebook_names.get(
				str(first.get("notebook_id", "")), "Unfiled"
			)).to_lower()
			var second_notebook := str(notebook_names.get(
				str(second.get("notebook_id", "")), "Unfiled"
			)).to_lower()
			if first_notebook != second_notebook:
				return first_notebook < second_notebook
			return first_title < second_title
		return str(first.get("updated_at", "")) > str(second.get("updated_at", ""))
	)
	_idea_list_v01532.clear()
	_visible_idea_ids_v01532.clear()
	var reselect_index := -1
	for idea in rows:
		var idea_title := str(idea.get("title", "Untitled idea"))
		if bool(idea.get("archived", false)):
			idea_title += "  [Archived]"
		var subtitle_parts: Array[String] = []
		if selected_kind == "special" and selected_notebook == "__all__":
			subtitle_parts.append(str(notebook_names.get(
				str(idea.get("notebook_id", "")), "Unfiled"
			)))
		var role := str(idea.get("character_role", "")).strip_edges()
		if not role.is_empty():
			subtitle_parts.append(role)
		elif not (idea.get("tags", []) as Array).is_empty():
			subtitle_parts.append(", ".join(idea.get("tags", [])))
		var display := idea_title
		if not subtitle_parts.is_empty():
			display += "\n" + " • ".join(subtitle_parts)
		_idea_list_v01532.add_item(display)
		var idea_id := str(idea.get("id", ""))
		_visible_idea_ids_v01532.append(idea_id)
		if idea_id == _selected_idea_id_v01532:
			reselect_index = _visible_idea_ids_v01532.size() - 1
	if _idea_result_summary_v0211 != null:
		var view_label := _selected_tree_scope_name_v0215(notebook_names)
		_idea_result_summary_v0211.text = (
			"Showing %d idea%s in %s"
			% [rows.size(), "" if rows.size() == 1 else "s", view_label]
		)
	var restored_selection := false
	for index in range(_visible_idea_ids_v01532.size()):
		if _visible_idea_ids_v01532[index] in selected_ids_before:
			_idea_list_v01532.select(index, false)
			restored_selection = true
	if reselect_index >= 0:
		_load_selected_idea_v01532(_selected_idea_id_v01532)
	elif not rows.is_empty():
		var next_active_index := 0
		if restored_selection:
			var selected_indices := _idea_list_v01532.get_selected_items()
			if not selected_indices.is_empty():
				next_active_index = int(selected_indices[-1])
		else:
			_idea_list_v01532.select(0, false)
		_selected_idea_id_v01532 = _visible_idea_ids_v01532[next_active_index]
		_load_selected_idea_v01532(_selected_idea_id_v01532)
	else:
		_selected_idea_id_v01532 = ""
		_clear_editor_v01532()
		_set_editor_enabled_v01532(false)
		_status_v01532.text = (
			"No saved ideas match the current notebook, tag and search filters."
		)


func _on_idea_multi_selected_v0214(index: int, selected: bool) -> void:
	# Multi-selection is the batch/export set, not the Idea Details focus. Godot
	# emits this once per changed row during Shift selection, so loading here made
	# a range selection perform N disk reads and N full editor rebuilds. Keep the
	# lightweight focus identity in step with the last selected row for existing
	# keyboard/export semantics; item_selected owns the one actual details load.
	if index < 0 or index >= _visible_idea_ids_v01532.size():
		return
	if selected:
		_selected_idea_id_v01532 = _visible_idea_ids_v01532[index]


func _live_notebook_selected_ids_v0214() -> Array[String]:
	var result: Array[String] = []
	if _idea_list_v01532 == null:
		return result
	for index_value in _idea_list_v01532.get_selected_items():
		var index := int(index_value)
		if index < 0 or index >= _visible_idea_ids_v01532.size():
			continue
		var idea_id := _visible_idea_ids_v01532[index]
		if not idea_id.is_empty() and not idea_id in result:
			result.append(idea_id)
	return result


func _selected_notebook_name_for_summary_v0211(
	notebook_id: String, notebook_names: Dictionary
) -> String:
	if notebook_id == "__all__":
		return "All Ideas"
	if notebook_id == "__unfiled__":
		return "Unfiled"
	return str(notebook_names.get(notebook_id, "the selected notebook"))


func _selected_tree_scope_name_v0215(notebook_names: Dictionary) -> String:
	if _notebook_tree_selection_kind_v0215 == "folder":
		var snapshot := (
			_hierarchy_snapshot_v0215
			if not _hierarchy_snapshot_v0215.is_empty()
			else NOTEBOOK_SERVICE.hierarchy_snapshot()
		)
		var path := NOTEBOOK_SERVICE.folder_path_from_snapshot(
			_notebook_tree_selection_id_v0215, snapshot
		)
		return "Folder: %s" % (path if not path.is_empty() else "root")
	return _selected_notebook_name_for_summary_v0211(
		_notebook_tree_selection_id_v0215, notebook_names
	)


func _load_selected_idea_v01532(idea_id: String) -> void:
	_focused_idea_load_count_v0215_hotfix += 1
	super._load_selected_idea_v01532(idea_id)
	if _structured_detail_v0210 == null:
		return
	if _loaded_idea_v01532.is_empty() or str(_loaded_idea_v01532.get("id", "")) != idea_id:
		_structured_detail_v0210.text = ""
		return
	var idea := _loaded_idea_v01532
	var structured_value: Variant = idea.get("structured_idea", {})
	if not structured_value is Dictionary or (structured_value as Dictionary).is_empty():
		_structured_detail_v0210.text = ""
		return
	_structured_detail_v0210.text = _idea_pack_service_v0210.generation_context_for_idea(idea)


func _clear_editor_v01532() -> void:
	super._clear_editor_v01532()
	if _structured_detail_v0210 != null:
		_structured_detail_v0210.text = ""


func _use_selected_idea_v01532() -> void:
	if _selected_idea_id_v01532.is_empty():
		return
	var loaded := _idea_pack_service_v0210.load_local_idea(_selected_idea_id_v01532)
	if not bool(loaded.get("ok", false)):
		_status_v01532.text = str(loaded.get("error", "Could not load idea."))
		return
	var idea_value: Variant = loaded.get("data", {})
	if not idea_value is Dictionary:
		_status_v01532.text = "The selected idea is not a valid Idea Notebook record."
		return
	var idea: Dictionary = idea_value
	var concept := str(idea.get("concept", "")).strip_edges()
	var structured_value: Variant = idea.get("structured_idea", {})
	if structured_value is Dictionary and not (structured_value as Dictionary).is_empty():
		concept = _idea_pack_service_v0210.generation_context_for_idea(idea)
	if concept.is_empty():
		_status_v01532.text = "This saved idea has no concept text."
		return
	concept_selected.emit(concept)
	hide()


func _build_idea_pack_dialogs_v0210() -> void:
	_import_dialog_v0210 = FileDialog.new()
	_import_dialog_v0210.visible = false
	_import_dialog_v0210.title = "Import Character Card Forge Idea Pack"
	_configure_independent_file_dialog_v0213(_import_dialog_v0210)
	_import_dialog_v0210.access = FileDialog.ACCESS_FILESYSTEM
	_import_dialog_v0210.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_import_dialog_v0210.filters = PackedStringArray([
		"*.ccfideas.json ; Character Card Forge Idea Pack",
		"*.json ; JSON files"
	])
	_import_dialog_v0210.file_selected.connect(_preview_idea_pack_file_v0210)
	add_child(_import_dialog_v0210)
	_import_dialog_v0210.hide()

	_import_preview_v0210 = Window.new()
	_import_preview_v0210.visible = false
	_import_preview_v0210.title = "Review Idea Pack Import"
	_import_preview_v0210.size = Vector2i(1180, 760)
	_import_preview_v0210.min_size = Vector2i(900, 600)
	_import_preview_v0210.force_native = true
	_import_preview_v0210.transient = false
	_import_preview_v0210.exclusive = false
	_import_preview_v0210.close_requested.connect(_import_preview_v0210.hide)
	add_child(_import_preview_v0210)
	_import_preview_v0210.hide()

	_export_window_v0210 = Window.new()
	_export_window_v0210.visible = false
	_export_window_v0210.title = "Export Character Card Forge Idea Pack"
	_export_window_v0210.size = Vector2i(980, 720)
	_export_window_v0210.min_size = Vector2i(760, 560)
	_export_window_v0210.force_native = true
	_export_window_v0210.transient = false
	_export_window_v0210.exclusive = false
	_export_window_v0210.close_requested.connect(_export_window_v0210.hide)
	add_child(_export_window_v0210)
	_export_window_v0210.hide()

	_export_dialog_v0210 = FileDialog.new()
	_export_dialog_v0210.visible = false
	_export_dialog_v0210.title = "Save Idea Pack"
	_configure_independent_file_dialog_v0213(_export_dialog_v0210)
	_export_dialog_v0210.access = FileDialog.ACCESS_FILESYSTEM
	_export_dialog_v0210.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_export_dialog_v0210.filters = PackedStringArray([
		"*.ccfideas.json ; Character Card Forge Idea Pack"
	])
	_export_dialog_v0210.file_selected.connect(_write_export_v0210)
	add_child(_export_dialog_v0210)
	_export_dialog_v0210.hide()


func _open_import_dialog_v0210() -> void:
	_import_dialog_v0210.popup_centered_ratio(0.8)


func _preview_idea_pack_file_v0210(path: String) -> void:
	_import_preview_data_v0210 = _idea_pack_service_v0210.parse_file(path)
	_build_import_preview_v0210()
	_import_preview_v0210.popup_centered()


func _build_import_preview_v0210() -> void:
	for child in _import_preview_v0210.get_children():
		child.queue_free()
	_import_rows_v0210.clear()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_import_preview_v0210.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	var pack: Dictionary = _import_preview_data_v0210.get("pack", {})
	var heading := Label.new()
	heading.text = str(pack.get("title", "Untitled Idea Pack"))
	heading.add_theme_font_size_override("font_size", 21)
	root.add_child(heading)
	var summary: Dictionary = _import_preview_data_v0210.get("summary", {})
	var conflict_summary: Dictionary = _import_preview_data_v0210.get("conflict_summary", {})
	var summary_label := Label.new()
	summary_label.text = (
		"Schema %d • %d Series • %d Seeds • %d other • %d new • %d existing-ID conflicts • %d likely title duplicate%s"
		% [
			int(_import_preview_data_v0210.get("schema_version", 0)),
			int(summary.get("series", 0)),
			int(summary.get("seeds", 0)),
			int(summary.get("other", 0)),
			int(conflict_summary.get("new", 0)),
			int(conflict_summary.get("conflicts", 0)),
			int(conflict_summary.get("title_warnings", 0)),
			"" if int(conflict_summary.get("title_warnings", 0)) == 1 else "s"
		]
	)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(summary_label)
	var issue_text := _format_issues_v0210(
		_import_preview_data_v0210.get("errors", []),
		_import_preview_data_v0210.get("warnings", [])
	)
	if not issue_text.is_empty():
		var issues := TextEdit.new()
		issues.custom_minimum_size.y = 110
		issues.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		issues.editable = false
		issues.text = issue_text
		root.add_child(issues)
	var controls := HFlowContainer.new()
	controls.add_theme_constant_override("separation", 8)
	root.add_child(controls)
	var target_label := Label.new()
	target_label.text = "Import into:"
	controls.add_child(target_label)
	_import_notebook_v0210 = OptionButton.new()
	_import_notebook_v0210.custom_minimum_size.x = 220
	_fill_destination_notebooks_v01532(_import_notebook_v0210, "")
	controls.add_child(_import_notebook_v0210)
	var select_all := Button.new()
	select_all.text = "Select All"
	select_all.pressed.connect(_set_import_selection_v0210.bind(true))
	controls.add_child(select_all)
	var select_none := Button.new()
	select_none.text = "Select None"
	select_none.pressed.connect(_set_import_selection_v0210.bind(false))
	controls.add_child(select_none)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 680
	root.add_child(split)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	split.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)
	var analysed_value: Variant = _import_preview_data_v0210.get("analysed_entries", [])
	if analysed_value is Array:
		for row_value in analysed_value:
			if row_value is Dictionary:
				_add_import_row_v0210(list, row_value as Dictionary)
	_import_detail_v0210 = TextEdit.new()
	_import_detail_v0210.custom_minimum_size.x = 360
	_import_detail_v0210.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_import_detail_v0210.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_import_detail_v0210.editable = false
	split.add_child(_import_detail_v0210)
	if not _import_rows_v0210.is_empty():
		_show_import_detail_v0210(int(_import_rows_v0210[0].get("index", 0)))
	_import_status_v0210 = Label.new()
	_import_status_v0210.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_import_status_v0210)
	var actions := HBoxContainer.new()
	root.add_child(actions)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(_import_preview_v0210.hide)
	actions.add_child(cancel)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	_import_confirm_v0210 = Button.new()
	_import_confirm_v0210.text = "Import Selected"
	_import_confirm_v0210.disabled = not bool(_import_preview_data_v0210.get("import_allowed", false))
	_import_confirm_v0210.tooltip_text = (
		"Nothing is written until this button is pressed. The selected batch is committed atomically."
	)
	_import_confirm_v0210.pressed.connect(_import_selected_v0210)
	actions.add_child(_import_confirm_v0210)


func _add_import_row_v0210(parent: VBoxContainer, row: Dictionary) -> void:
	var entry: Dictionary = row.get("entry", {})
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	parent.add_child(container)
	var check := CheckBox.new()
	check.button_pressed = bool(row.get("selected", true))
	check.set_meta("entry_index_v0210", int(row.get("index", -1)))
	container.add_child(check)
	var inspect := Button.new()
	inspect.text = "%s  [%s]" % [str(entry.get("title", "Untitled")), str(entry.get("kind", "unknown"))]
	inspect.alignment = HORIZONTAL_ALIGNMENT_LEFT
	inspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspect.tooltip_text = "Inspect this entry's complete structured generator context."
	inspect.pressed.connect(_show_import_detail_v0210.bind(int(row.get("index", -1))))
	container.add_child(inspect)
	var conflict := str(row.get("conflict", "new"))
	var conflict_label := Label.new()
	match conflict:
		"existing_id": conflict_label.text = "Existing ID"
		"duplicate_pack_id": conflict_label.text = "Duplicate in pack"
		"likely_title_duplicate": conflict_label.text = "Similar title"
		_: conflict_label.text = "New"
	conflict_label.custom_minimum_size.x = 115
	container.add_child(conflict_label)
	var action := OptionButton.new()
	action.custom_minimum_size.x = 185
	if conflict == "existing_id":
		_add_action_v0210(action, "Skip existing", "skip")
		_add_action_v0210(action, "Replace/update existing", "replace")
		_add_action_v0210(action, "Keep both as copy", "keep_both")
	elif conflict == "duplicate_pack_id":
		_add_action_v0210(action, "Skip duplicate", "skip")
		_add_action_v0210(action, "Keep both as copy", "keep_both")
	else:
		_add_action_v0210(action, "Import as new", "import")
	container.add_child(action)
	_import_rows_v0210.append({
		"index": int(row.get("index", -1)),
		"check": check,
		"action": action
	})


func _add_action_v0210(selector: OptionButton, label: String, value: String) -> void:
	selector.add_item(label)
	selector.set_item_metadata(selector.item_count - 1, value)


func _show_import_detail_v0210(entry_index: int) -> void:
	if _import_detail_v0210 == null:
		return
	var entries_value: Variant = _import_preview_data_v0210.get("entries", [])
	if not entries_value is Array or entry_index < 0 or entry_index >= (entries_value as Array).size():
		_import_detail_v0210.text = ""
		return
	var entry_value: Variant = (entries_value as Array)[entry_index]
	if not entry_value is Dictionary:
		_import_detail_v0210.text = ""
		return
	_import_detail_v0210.text = _idea_pack_service_v0210.render_entry_for_generation(entry_value as Dictionary)


func _set_import_selection_v0210(selected: bool) -> void:
	for row in _import_rows_v0210:
		var check_value: Variant = row.get("check")
		if check_value is CheckBox:
			(check_value as CheckBox).button_pressed = selected


func _import_selected_v0210() -> void:
	var selections: Array = []
	for row in _import_rows_v0210:
		var check_value: Variant = row.get("check")
		var action_value: Variant = row.get("action")
		if not check_value is CheckBox or not action_value is OptionButton:
			continue
		var action_selector := action_value as OptionButton
		var action := "skip"
		if action_selector.selected >= 0:
			action = str(action_selector.get_item_metadata(action_selector.selected))
		selections.append({
			"index": int(row.get("index", -1)),
			"selected": (check_value as CheckBox).button_pressed,
			"action": action
		})
	var notebook_id := _selected_metadata_v01532(_import_notebook_v0210, "")
	_import_confirm_v0210.disabled = true
	var result := _idea_pack_service_v0210.import_preview(
		_import_preview_data_v0210, selections, notebook_id
	)
	if not bool(result.get("ok", false)):
		_import_status_v0210.text = str(result.get("error", "Idea Pack import failed. No ideas were changed."))
		_import_confirm_v0210.disabled = not bool(_import_preview_data_v0210.get("import_allowed", false))
		return
	_import_preview_v0210.hide()
	_refresh_notebook_v01532()
	_status_v01532.text = (
		"Idea Pack import complete: %d new, %d updated, %d kept as copies, %d skipped."
		% [
			int(result.get("imported", 0)),
			int(result.get("replaced", 0)),
			int(result.get("copies", 0)),
			int(result.get("skipped", 0))
		]
	)


func _format_issues_v0210(errors_value: Variant, warnings_value: Variant) -> String:
	var lines: Array[String] = []
	if errors_value is Array:
		for issue_value in errors_value:
			if issue_value is Dictionary:
				lines.append("ERROR: %s" % str((issue_value as Dictionary).get("message", "Validation error")))
	if warnings_value is Array:
		for issue_value in warnings_value:
			if issue_value is Dictionary:
				lines.append("WARNING: %s" % str((issue_value as Dictionary).get("message", "Validation warning")))
	return "\n".join(lines)


func _open_export_window_v0210() -> void:
	_sync_notebook_selection_for_export_v0210()
	_build_export_window_v0210()
	_export_window_v0210.popup_centered()


func _build_export_window_v0210() -> void:
	for child in _export_window_v0210.get_children():
		_export_window_v0210.remove_child(child)
		child.queue_free()
	_export_rows_v0210.clear()
	_export_folder_notebook_ids_v0215.clear()
	var ideas := _idea_pack_service_v0210.list_local_ideas(true)
	var preferred_scope := _preferred_export_scope_v0210(ideas)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_export_window_v0210.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	var heading := Label.new()
	heading.text = "Export semantic Idea Notebook material"
	heading.add_theme_font_size_override("font_size", 20)
	root.add_child(heading)
	var metadata_grid := GridContainer.new()
	metadata_grid.columns = 2
	root.add_child(metadata_grid)
	metadata_grid.add_child(_simple_label_v0210("Pack title"))
	_export_title_v0210 = LineEdit.new()
	_export_title_v0210.text = "Character Card Forge Idea Pack"
	_export_title_v0210.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metadata_grid.add_child(_export_title_v0210)
	metadata_grid.add_child(_simple_label_v0210("Pack ID"))
	_export_id_v0210 = LineEdit.new()
	_export_id_v0210.placeholder_text = "Generated automatically when left empty"
	metadata_grid.add_child(_export_id_v0210)
	metadata_grid.add_child(_simple_label_v0210("Source version"))
	_export_version_v0210 = LineEdit.new()
	metadata_grid.add_child(_export_version_v0210)
	metadata_grid.add_child(_simple_label_v0210("Description"))
	_export_description_v0210 = TextEdit.new()
	_export_description_v0210.custom_minimum_size.y = 70
	_export_description_v0210.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	metadata_grid.add_child(_export_description_v0210)
	var controls := HFlowContainer.new()
	controls.add_theme_constant_override("separation", 8)
	root.add_child(controls)
	controls.add_child(_simple_label_v0210("Selection scope"))
	_export_scope_v0210 = OptionButton.new()
	_export_scope_v0210.custom_minimum_size.x = 260
	_add_export_scope_with_count_v0214(
		"All Ideas", {"kind": "all", "value": ""}, ideas
	)
	_add_export_scope_with_count_v0214(
		"Selected Ideas",
		{
			"kind": "selected",
			"value": (
				_export_selected_idea_ids_v0214[0]
				if not _export_selected_idea_ids_v0214.is_empty()
				else ""
			),
			"values": _export_selected_idea_ids_v0214.duplicate()
		},
		ideas
	)
	var hierarchy := NOTEBOOK_SERVICE.hierarchy_snapshot()
	var notebook_paths: Dictionary = hierarchy.get("notebook_paths", {})
	var folder_paths: Dictionary = hierarchy.get("folder_paths", {})
	for notebook in _idea_pack_service_v0210.list_local_notebooks():
		var notebook_id := str(notebook.get("id", ""))
		var notebook_name := str(notebook_paths.get(notebook_id, ""))
		if notebook_name.is_empty():
			notebook_name = str(notebook.get("name", "Notebook"))
		_add_export_scope_with_count_v0214(
			"Notebook: %s" % notebook_name,
			{"kind": "notebook", "value": notebook_id},
			ideas
		)
	for folder in hierarchy.get("folders", []):
		var folder_id := str(folder.get("id", ""))
		_export_folder_notebook_ids_v0215[folder_id] = NOTEBOOK_SERVICE.notebook_ids_in_folder_from_snapshot(
			folder_id, hierarchy, true
		)
		_add_export_scope_with_count_v0214(
			"Folder: %s" % str(folder_paths.get(folder_id, folder.get("name", "Folder"))),
			{"kind": "folder", "value": folder_id},
			ideas
		)
	var filter_values := _idea_pack_service_v0210.export_filter_values(ideas)
	for bible in filter_values.get("bibles", []):
		_add_export_scope_with_count_v0214(
			"Bible: %s" % str(bible),
			{"kind": "bible", "value": str(bible)},
			ideas
		)
	for series_name in filter_values.get("series", []):
		_add_export_scope_with_count_v0214(
			"Series: %s" % str(series_name),
			{"kind": "series", "value": str(series_name)},
			ideas
		)
	_export_scope_v0210.item_selected.connect(_apply_export_scope_v0210)
	controls.add_child(_export_scope_v0210)
	var select_all := Button.new()
	select_all.text = "Select All"
	select_all.pressed.connect(_set_export_selection_v0210.bind(true))
	controls.add_child(select_all)
	var select_none := Button.new()
	select_none.text = "Select None"
	select_none.pressed.connect(_set_export_selection_v0210.bind(false))
	controls.add_child(select_none)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for idea in ideas:
		var check := CheckBox.new()
		var entry := _idea_pack_service_v0210.idea_to_entry(idea)
		check.text = "%s  [%s • %s]" % [str(entry.get("title", "Untitled")), str(entry.get("kind", "seed")), str(entry.get("id", ""))]
		check.button_pressed = true
		list.add_child(check)
		_export_rows_v0210.append({"check": check, "idea": idea})
	_select_export_scope_v0210(preferred_scope)
	_apply_export_scope_v0210(_export_scope_v0210.selected)
	_export_status_v0210 = Label.new()
	_export_status_v0210.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_export_status_v0210)
	var actions := HBoxContainer.new()
	root.add_child(actions)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(_export_window_v0210.hide)
	actions.add_child(cancel)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	var save := Button.new()
	save.text = "Export Checked Ideas…"
	save.pressed.connect(_choose_export_path_v0210)
	actions.add_child(save)


func _simple_label_v0210(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


func _add_export_scope_v0210(label: String, metadata: Dictionary) -> void:
	_export_scope_v0210.add_item(label)
	_export_scope_v0210.set_item_metadata(_export_scope_v0210.item_count - 1, metadata)


func _add_export_scope_with_count_v0214(
	label: String, metadata: Dictionary, ideas: Array
) -> void:
	var count := 0
	for idea_value in ideas:
		if (
			idea_value is Dictionary
			and _idea_matches_export_scope_metadata_v0214(
				idea_value as Dictionary, metadata
			)
		):
			count += 1
	_add_export_scope_v0210("%s (%d)" % [label, count], metadata)


func _sync_notebook_selection_for_export_v0210() -> void:
	_export_selected_idea_ids_v0214 = _live_notebook_selected_ids_v0214()


func _preferred_export_scope_v0210(ideas: Array) -> Dictionary:
	if _export_selected_idea_ids_v0214.is_empty():
		if _notebook_tree_selection_kind_v0215 == "folder":
			return {
				"kind": "folder",
				"value": _notebook_tree_selection_id_v0215
			}
		if _notebook_tree_selection_kind_v0215 == "notebook":
			return {
				"kind": "notebook",
				"value": _notebook_tree_selection_id_v0215
			}
		return {"kind": "all", "value": ""}
	if _export_selected_idea_ids_v0214.size() > 1:
		return {
			"kind": "selected",
			"value": _export_selected_idea_ids_v0214[0],
			"values": _export_selected_idea_ids_v0214.duplicate()
		}
	var selected_id := _export_selected_idea_ids_v0214[0]
	var selected_idea: Dictionary = {}
	for idea_value in ideas:
		if (
			idea_value is Dictionary
			and str((idea_value as Dictionary).get("id", ""))
			== selected_id
		):
			selected_idea = idea_value as Dictionary
			break
	if selected_idea.is_empty():
		return {"kind": "all", "value": ""}
	var entry := _idea_pack_service_v0210.idea_to_entry(selected_idea)
	if str(entry.get("kind", "")).strip_edges().to_lower() == "series":
		var classification_value: Variant = entry.get("classification", {})
		var classification: Dictionary = (
			classification_value if classification_value is Dictionary else {}
		)
		var series_candidates: Array[String] = []
		for field_id in ["primary_series", "secondary_series"]:
			var values: Variant = classification.get(field_id, [])
			if values is Array:
				for value in values as Array:
					var clean := str(value).strip_edges()
					if not clean.is_empty() and not clean in series_candidates:
						series_candidates.append(clean)
		var entry_title := str(entry.get("title", "")).strip_edges()
		if not entry_title.is_empty() and not entry_title in series_candidates:
			series_candidates.append(entry_title)
		for series_name in series_candidates:
			for idea_value in ideas:
				if (
					idea_value is Dictionary
					and _idea_pack_service_v0210.idea_matches_export_scope(
						idea_value as Dictionary, "series", series_name
					)
				):
					return {"kind": "series", "value": series_name}
		var bible := str(classification.get("bible", "")).strip_edges()
		if not bible.is_empty():
			return {"kind": "bible", "value": bible}
	return {
		"kind": "selected",
		"value": selected_id,
		"values": _export_selected_idea_ids_v0214.duplicate()
	}


func _select_export_scope_v0210(preferred_scope: Dictionary) -> void:
	if _export_scope_v0210 == null:
		return
	var preferred_kind := str(preferred_scope.get("kind", "all"))
	var preferred_value := str(preferred_scope.get("value", ""))
	var all_index := 0
	for index in range(_export_scope_v0210.item_count):
		var metadata_value: Variant = _export_scope_v0210.get_item_metadata(index)
		if not metadata_value is Dictionary:
			continue
		var metadata: Dictionary = metadata_value
		if str(metadata.get("kind", "")) == "all":
			all_index = index
		if (
			str(metadata.get("kind", "")) == preferred_kind
			and str(metadata.get("value", "")) == preferred_value
		):
			_export_scope_v0210.select(index)
			return
	_export_scope_v0210.select(all_index)


func _apply_export_scope_v0210(_selected_index: int) -> void:
	for row in _export_rows_v0210:
		var check_value: Variant = row.get("check")
		var idea_value: Variant = row.get("idea")
		if not check_value is CheckBox or not idea_value is Dictionary:
			continue
		var matches_scope := _idea_matches_current_export_scope_v0210(
			idea_value as Dictionary
		)
		(check_value as CheckBox).button_pressed = matches_scope
		(check_value as CheckBox).visible = matches_scope


func _set_export_selection_v0210(selected: bool) -> void:
	for row in _export_rows_v0210:
		var check_value: Variant = row.get("check")
		var idea_value: Variant = row.get("idea")
		if (
			check_value is CheckBox
			and idea_value is Dictionary
			and _idea_matches_current_export_scope_v0210(
				idea_value as Dictionary
			)
		):
			(check_value as CheckBox).button_pressed = selected


func _idea_matches_current_export_scope_v0210(idea: Dictionary) -> bool:
	if _export_scope_v0210 == null or _export_scope_v0210.selected < 0:
		return false
	var metadata_value: Variant = _export_scope_v0210.get_item_metadata(
		_export_scope_v0210.selected
	)
	if not metadata_value is Dictionary:
		return false
	return _idea_matches_export_scope_metadata_v0214(
		idea, metadata_value as Dictionary
	)


func _idea_matches_export_scope_metadata_v0214(
	idea: Dictionary, metadata: Dictionary
) -> bool:
	var kind := str(metadata.get("kind", "all"))
	var value := str(metadata.get("value", ""))
	if kind == "selected":
		var values_value: Variant = metadata.get("values", [])
		if values_value is Array and not (values_value as Array).is_empty():
			return str(idea.get("id", "")) in (values_value as Array)
		return not value.is_empty() and str(idea.get("id", "")) == value
	if kind == "folder":
		var notebook_ids_value: Variant = _export_folder_notebook_ids_v0215.get(value, [])
		var notebook_ids: Array = notebook_ids_value if notebook_ids_value is Array else []
		return str(idea.get("notebook_id", "")) in notebook_ids
	return _idea_pack_service_v0210.idea_matches_export_scope(
		idea, kind, value
	)


func _choose_export_path_v0210() -> void:
	_pending_export_ideas_v0210.clear()
	for row in _export_rows_v0210:
		var check_value: Variant = row.get("check")
		var idea_value: Variant = row.get("idea")
		if (
			check_value is CheckBox
			and (check_value as CheckBox).button_pressed
			and idea_value is Dictionary
			and _idea_matches_current_export_scope_v0210(
				idea_value as Dictionary
			)
		):
			_pending_export_ideas_v0210.append((idea_value as Dictionary).duplicate(true))
	if _pending_export_ideas_v0210.is_empty():
		_export_status_v0210.text = "Select at least one idea to export."
		return
	_export_dialog_v0210.current_file = "character-card-forge-ideas.ccfideas.json"
	_export_dialog_v0210.popup_centered_ratio(0.8)


func _write_export_v0210(path: String) -> void:
	var metadata := {
		"id": _export_id_v0210.text,
		"title": _export_title_v0210.text,
		"description": _export_description_v0210.text,
		"source_version": _export_version_v0210.text,
		"created_at": Time.get_datetime_string_from_system(true),
		"source": "Character Card Forge v0.21.1"
	}
	var result := _idea_pack_service_v0210.export_to_file(path, _pending_export_ideas_v0210, metadata)
	if not bool(result.get("ok", false)):
		_export_status_v0210.text = str(result.get("error", "Could not export Idea Pack."))
		return
	_export_window_v0210.hide()
	_status_v01532.text = "Exported %d Idea Pack entr%s to %s" % [
		int(result.get("entry_count", 0)),
		"y" if int(result.get("entry_count", 0)) == 1 else "ies",
		str(result.get("path", path))
	]


func _build_idea_source_tab_v0213() -> void:
	_source_tab_v0213 = VBoxContainer.new()
	_source_tab_v0213.name = "Idea Sources"
	_source_tab_v0213.add_theme_constant_override("separation", 8)
	_tabs.add_child(_source_tab_v0213)
	var intro := Label.new()
	intro.text = (
		"Idea Sources are reusable inputs that create many Ideas. They are separate from generated Ideas in Idea Notebook and from Workspace Generation Concepts."
	)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_source_tab_v0213.add_child(intro)
	var toolbar := HFlowContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	_source_tab_v0213.add_child(toolbar)
	_add_source_button_v0213(toolbar, "New Source", _new_source_v0213)
	_add_source_button_v0213(toolbar, "Load Idea Source…", _open_source_file_v0213)
	_add_source_button_v0213(toolbar, "Save Current Source", _save_current_source_v0213)
	_add_source_button_v0213(toolbar, "Export Idea Source…", _choose_source_export_v0213)
	_add_source_button_v0213(toolbar, "Duplicate", _duplicate_source_v0213)
	_add_source_button_v0213(toolbar, "Rename", _focus_source_title_v0213)
	_add_source_button_v0213(toolbar, "Delete…", _request_delete_source_v0213)
	var use_button := _add_source_button_v0213(toolbar, "Use in Idea Generator", _use_source_v0213)
	use_button.tooltip_text = "Activate this reusable source without creating an Idea Notebook entry."

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 300
	_source_tab_v0213.add_child(split)
	var library_panel := VBoxContainer.new()
	library_panel.custom_minimum_size.x = 260
	library_panel.add_theme_constant_override("separation", 6)
	split.add_child(library_panel)
	var library_heading := Label.new()
	library_heading.text = "Saved Idea Source Library"
	library_heading.add_theme_font_size_override("font_size", 17)
	library_panel.add_child(library_heading)
	var library_hint := Label.new()
	library_hint.text = "Only sources you explicitly save appear here. Loading an external file remains temporary."
	library_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	library_hint.modulate = Color(0.66, 0.70, 0.82)
	library_panel.add_child(library_hint)
	_source_list_v0213 = ItemList.new()
	_source_list_v0213.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_source_list_v0213.allow_reselect = true
	_source_list_v0213.item_selected.connect(_load_selected_source_v0213)
	library_panel.add_child(_source_list_v0213)

	var editor_scroll := ScrollContainer.new()
	editor_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	split.add_child(editor_scroll)
	var editor := VBoxContainer.new()
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.add_theme_constant_override("separation", 7)
	editor_scroll.add_child(editor)
	var editor_heading := Label.new()
	editor_heading.text = "Reusable Generator Source"
	editor_heading.add_theme_font_size_override("font_size", 17)
	editor.add_child(editor_heading)
	_source_title_v0213 = LineEdit.new()
	_source_title_v0213.placeholder_text = "Optional — for example, She Got Pregnant"
	editor.add_child(_labelled_control_v01532("Title (optional)", _source_title_v0213))
	var title_actions := HFlowContainer.new()
	title_actions.add_theme_constant_override("separation", 8)
	editor.add_child(title_actions)
	var suggest := _add_source_button_v0213(title_actions, "Suggest Name", _suggest_source_title_v0213)
	suggest.tooltip_text = "Provides a local fallback suggestion. A blank title also asks the generation model to infer a concise reusable name without blocking generation."
	_source_description_v0213 = _source_text_edit_v0213(75)
	editor.add_child(_labelled_control_v01532("Description", _source_description_v0213))
	_source_version_v0213 = LineEdit.new()
	_source_version_v0213.placeholder_text = "Optional source/Bible version"
	editor.add_child(_labelled_control_v01532("Source version", _source_version_v0213))
	_source_bible_v0213 = _source_text_edit_v0213(90)
	_source_bible_v0213.placeholder_text = "Optional JSON object with Series/Bible metadata"
	editor.add_child(_labelled_control_v01532("Source Bible / Series (JSON)", _source_bible_v0213))
	_source_summary_v0213 = _source_text_edit_v0213(100)
	editor.add_child(_labelled_control_v01532("Summary", _source_summary_v0213))
	_source_premise_v0213 = _source_text_edit_v0213(150)
	editor.add_child(_labelled_control_v01532("Core premise / reusable engine", _source_premise_v0213))
	_source_setup_v0213 = _source_text_edit_v0213(110)
	editor.add_child(_labelled_control_v01532("Setup / framing", _source_setup_v0213))
	_source_variables_v0213 = _source_text_edit_v0213(110)
	editor.add_child(_labelled_control_v01532("Core variables (one per line)", _source_variables_v0213))
	_source_rules_v0213 = _source_text_edit_v0213(110)
	editor.add_child(_labelled_control_v01532("Generation rules (one per line)", _source_rules_v0213))
	_source_guardrails_v0213 = _source_text_edit_v0213(110)
	editor.add_child(_labelled_control_v01532("Guardrails (one per line)", _source_guardrails_v0213))
	_source_diversity_v0213 = _source_text_edit_v0213(100)
	editor.add_child(_labelled_control_v01532("Suggested diversity axes (one per line)", _source_diversity_v0213))
	_source_links_v0213 = _source_text_edit_v0213(90)
	editor.add_child(_labelled_control_v01532("Cross-links / related Series (one per line)", _source_links_v0213))
	_source_tags_v0213 = LineEdit.new()
	_source_tags_v0213.placeholder_text = "romance, drama, university"
	editor.add_child(_labelled_control_v01532("Tags (comma separated)", _source_tags_v0213))
	_source_notes_v0213 = _source_text_edit_v0213(90)
	editor.add_child(_labelled_control_v01532("Notes", _source_notes_v0213))
	_source_sections_v0213 = _source_text_edit_v0213(130)
	_source_sections_v0213.placeholder_text = '[{"label":"Relationship engine","content":"..."}]'
	editor.add_child(_labelled_control_v01532("Arbitrary labelled sections (JSON array)", _source_sections_v0213))
	_source_raw_prompt_v0213 = _source_text_edit_v0213(130)
	editor.add_child(_labelled_control_v01532("Raw / custom prompt", _source_raw_prompt_v0213))
	_source_status_v0213 = Label.new()
	_source_status_v0213.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_source_status_v0213.modulate = Color(0.72, 0.76, 0.86)
	_source_tab_v0213.add_child(_source_status_v0213)
	_new_source_v0213()


func _build_idea_source_dialogs_v0213() -> void:
	_source_load_dialog_v0213 = FileDialog.new()
	_source_load_dialog_v0213.visible = false
	_source_load_dialog_v0213.title = "Load Character Card Forge Idea Source"
	_configure_independent_file_dialog_v0213(_source_load_dialog_v0213)
	_source_load_dialog_v0213.access = FileDialog.ACCESS_FILESYSTEM
	_source_load_dialog_v0213.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_source_load_dialog_v0213.filters = PackedStringArray([
		"*.ccfideasource.json ; Character Card Forge Idea Source",
		"*.json ; JSON files"
	])
	_source_load_dialog_v0213.file_selected.connect(_load_source_file_v0213)
	add_child(_source_load_dialog_v0213)
	_source_load_dialog_v0213.hide()
	_source_export_dialog_v0213 = FileDialog.new()
	_source_export_dialog_v0213.visible = false
	_source_export_dialog_v0213.title = "Export Character Card Forge Idea Source"
	_configure_independent_file_dialog_v0213(_source_export_dialog_v0213)
	_source_export_dialog_v0213.access = FileDialog.ACCESS_FILESYSTEM
	_source_export_dialog_v0213.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_source_export_dialog_v0213.filters = PackedStringArray([
		"*.ccfideasource.json ; Character Card Forge Idea Source"
	])
	_source_export_dialog_v0213.file_selected.connect(_export_source_file_v0213)
	add_child(_source_export_dialog_v0213)
	_source_export_dialog_v0213.hide()
	_source_delete_dialog_v0213 = ConfirmationDialog.new()
	_source_delete_dialog_v0213.visible = false
	_source_delete_dialog_v0213.title = "Delete Saved Idea Source"
	_source_delete_dialog_v0213.dialog_text = "Delete this source from the internal Idea Source Library? Portable files and generated Ideas are unaffected."
	_source_delete_dialog_v0213.ok_button_text = "Delete Source"
	_source_delete_dialog_v0213.confirmed.connect(_delete_source_v0213)
	add_child(_source_delete_dialog_v0213)
	_source_delete_dialog_v0213.hide()


func _configure_independent_file_dialog_v0213(dialog: FileDialog) -> void:
	if dialog == null:
		return
	dialog.use_native_dialog = true
	dialog.force_native = true
	dialog.exclusive = false
	dialog.always_on_top = false
	dialog.unresizable = false


func _install_active_source_banner_v0213() -> void:
	var ai_tab := _tabs.get_node_or_null("AI Ideas") as VBoxContainer
	if ai_tab == null:
		return
	_active_source_panel_v0213 = PanelContainer.new()
	_active_source_panel_v0213.name = "ActiveIdeaSourcePanelV0213"
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.12, 0.20, 0.96)
	panel_style.border_color = Color(0.38, 0.43, 0.68, 0.95)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(7)
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	_active_source_panel_v0213.add_theme_stylebox_override("panel", panel_style)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	_active_source_panel_v0213.add_child(content)
	_active_source_banner_v0213 = Label.new()
	_active_source_banner_v0213.name = "ActiveIdeaSourceBannerV0213"
	_active_source_banner_v0213.add_theme_font_size_override("font_size", 17)
	_active_source_banner_v0213.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_active_source_banner_v0213)
	_active_source_explanation_v0213 = Label.new()
	_active_source_explanation_v0213.name = "ActiveIdeaSourceExplanationV0213"
	_active_source_explanation_v0213.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_active_source_explanation_v0213.modulate = Color(0.76, 0.79, 0.90)
	content.add_child(_active_source_explanation_v0213)
	_active_source_actions_v0213 = HFlowContainer.new()
	_active_source_actions_v0213.name = "ActiveIdeaSourceActionsV0213"
	_active_source_actions_v0213.add_theme_constant_override("separation", 8)
	content.add_child(_active_source_actions_v0213)
	_active_source_view_button_v0213 = _add_source_button_v0213(
		_active_source_actions_v0213, "View/Edit Source", _view_active_source_v0213
	)
	_add_source_button_v0213(
		_active_source_actions_v0213, "Change Source", _change_active_source_v0213
	)
	var clear_button := _add_source_button_v0213(
		_active_source_actions_v0213, "Clear Source", _clear_active_source_from_panel_v0213
	)
	clear_button.tooltip_text = "Stop using this source for generation. The saved or external source is not deleted."
	ai_tab.add_child(_active_source_panel_v0213)
	if _ai_ideas_host != null:
		ai_tab.move_child(_active_source_panel_v0213, _ai_ideas_host.get_index())
	_refresh_active_source_banner_v0213()


func _add_source_button_v0213(parent: Control, text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _source_text_edit_v0213(minimum_height: int) -> TextEdit:
	var editor := TextEdit.new()
	editor.custom_minimum_size.y = minimum_height
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return editor


func _new_source_v0213() -> void:
	_source_editor_base_v0213 = _idea_source_service_v0213.blank_source()
	_source_saved_v0213 = false
	_source_external_path_v0213 = ""
	_populate_source_editor_v0213(_source_editor_base_v0213)
	if _source_status_v0213 != null:
		_source_status_v0213.text = "New temporary source. It will not enter the library until Save Current Source is pressed."


func _open_source_file_v0213() -> void:
	_source_load_dialog_v0213.popup_centered_ratio(0.8)


func _load_source_file_v0213(path: String) -> void:
	var result := _idea_source_service_v0213.parse_file(path)
	if not bool(result.get("load_allowed", false)):
		_source_status_v0213.text = _source_result_message_v0213(result)
		return
	_source_editor_base_v0213 = (result.get("source", {}) as Dictionary).duplicate(true)
	_source_saved_v0213 = false
	_source_external_path_v0213 = path
	_populate_source_editor_v0213(_source_editor_base_v0213)
	_source_status_v0213.text = "Loaded external source temporarily from %s. It has not been saved to the Idea Source Library or Idea Notebook." % path


func _load_selected_source_v0213(index: int) -> void:
	if index < 0 or index >= _source_visible_ids_v0213.size():
		return
	var result := _idea_source_service_v0213.load_source(_source_visible_ids_v0213[index])
	if not bool(result.get("ok", false)):
		_source_status_v0213.text = str(result.get("error", "Could not load Idea Source."))
		return
	_source_editor_base_v0213 = (result.get("source", {}) as Dictionary).duplicate(true)
	_source_saved_v0213 = true
	_source_external_path_v0213 = ""
	_populate_source_editor_v0213(_source_editor_base_v0213)
	_source_status_v0213.text = "Loaded saved Idea Source. Edit and save explicitly when ready."


func load_temporary_source_v0213(source: Dictionary, open_editor: bool = true, activate: bool = false) -> void:
	_source_editor_base_v0213 = source.duplicate(true)
	if str(_source_editor_base_v0213.get("id", "")).is_empty():
		_source_editor_base_v0213["id"] = str(_idea_source_service_v0213.blank_source().get("id", ""))
	_source_editor_base_v0213["format"] = IDEA_SOURCE_SERVICE_V0213.FORMAT_ID
	_source_editor_base_v0213["schema_version"] = IDEA_SOURCE_SERVICE_V0213.SCHEMA_VERSION
	_source_saved_v0213 = false
	_source_external_path_v0213 = ""
	_populate_source_editor_v0213(_source_editor_base_v0213)
	if activate:
		_use_source_v0213(false)
	if open_editor:
		_show_source_tab_v0213()
		open_studio()
	_source_status_v0213.text = "Extracted source is temporary and editable. Generate, save or export it when ready."


func _save_current_source_v0213() -> void:
	var captured := _capture_source_editor_v0213()
	if not bool(captured.get("ok", false)):
		_source_status_v0213.text = str(captured.get("error", "Could not read source fields."))
		return
	var result := _idea_source_service_v0213.save_source(captured.get("source", {}))
	if not bool(result.get("ok", false)):
		_source_status_v0213.text = str(result.get("error", "Could not save Idea Source."))
		return
	_source_editor_base_v0213 = (result.get("source", {}) as Dictionary).duplicate(true)
	_source_saved_v0213 = true
	_source_external_path_v0213 = ""
	if str(_active_idea_source_v0213.get("id", "")) == str(_source_editor_base_v0213.get("id", "")):
		_active_source_saved_v0213 = true
		_active_source_external_path_v0213 = ""
	_populate_source_editor_v0213(_source_editor_base_v0213)
	_refresh_source_library_v0213(str(_source_editor_base_v0213.get("id", "")))
	_source_status_v0213.text = "Saved to the Idea Source Library. No Idea Notebook entry was created."


func _choose_source_export_v0213() -> void:
	var captured := _capture_source_editor_v0213()
	if not bool(captured.get("ok", false)):
		_source_status_v0213.text = str(captured.get("error", "Could not read source fields."))
		return
	_source_pending_export_v0213 = (captured.get("source", {}) as Dictionary).duplicate(true)
	var file_stem := str(_source_pending_export_v0213.get("title", "idea-source")).strip_edges()
	if file_stem.is_empty():
		file_stem = "idea-source"
	_source_export_dialog_v0213.current_file = "%s.ccfideasource.json" % file_stem.validate_filename()
	_source_export_dialog_v0213.popup_centered_ratio(0.8)


func _export_source_file_v0213(path: String) -> void:
	var result := _idea_source_service_v0213.export_to_file(path, _source_pending_export_v0213)
	if not bool(result.get("ok", false)):
		_source_status_v0213.text = str(result.get("error", "Could not export Idea Source."))
		return
	_source_status_v0213.text = "Exported Idea Source to %s" % str(result.get("path", path))


func _duplicate_source_v0213() -> void:
	if not _source_saved_v0213:
		_source_status_v0213.text = "Save this temporary source before duplicating it in the library."
		return
	var result := _idea_source_service_v0213.duplicate_source(str(_source_editor_base_v0213.get("id", "")))
	if not bool(result.get("ok", false)):
		_source_status_v0213.text = str(result.get("error", "Could not duplicate Idea Source."))
		return
	_source_editor_base_v0213 = (result.get("source", {}) as Dictionary).duplicate(true)
	_source_saved_v0213 = true
	_populate_source_editor_v0213(_source_editor_base_v0213)
	_refresh_source_library_v0213(str(_source_editor_base_v0213.get("id", "")))
	_source_status_v0213.text = "Duplicated as a separate saved Idea Source."


func _focus_source_title_v0213() -> void:
	_source_title_v0213.grab_focus()
	_source_title_v0213.select_all()
	_source_status_v0213.text = "Edit the title, then choose Save Current Source. The stable source ID is unchanged."


func _request_delete_source_v0213() -> void:
	if not _source_saved_v0213:
		_source_status_v0213.text = "This source is temporary and has no library copy to delete."
		return
	_source_delete_dialog_v0213.popup_centered()


func _delete_source_v0213() -> void:
	var source_id := str(_source_editor_base_v0213.get("id", ""))
	var result := _idea_source_service_v0213.delete_source(source_id)
	if not bool(result.get("ok", false)):
		_source_status_v0213.text = str(result.get("error", "Could not delete Idea Source."))
		return
	if str(_active_idea_source_v0213.get("id", "")) == source_id:
		clear_active_idea_source_v0213()
	_new_source_v0213()
	_refresh_source_library_v0213()
	_source_status_v0213.text = "Deleted the saved Idea Source. Generated Ideas and portable files were not changed."


func _use_source_v0213(switch_to_generator: bool = true) -> void:
	var captured := _capture_source_editor_v0213()
	if not bool(captured.get("ok", false)):
		_source_status_v0213.text = str(captured.get("error", "Could not activate Idea Source."))
		return
	_active_idea_source_v0213 = (captured.get("source", {}) as Dictionary).duplicate(true)
	_active_source_saved_v0213 = _source_saved_v0213
	_active_source_external_path_v0213 = _source_external_path_v0213
	_refresh_active_source_banner_v0213()
	active_idea_source_changed_v0213.emit(_active_idea_source_v0213.duplicate(true))
	_source_status_v0213.text = "Idea Source activated. It will remain identical across every request in an Idea Generator batch."
	if str(_active_idea_source_v0213.get("title", "")).strip_edges().is_empty():
		_request_ai_source_title_v0213()
	if switch_to_generator:
		for index in range(_tabs.get_tab_count()):
			if _tabs.get_tab_title(index) == "AI Ideas":
				_tabs.current_tab = index
				call_deferred("_focus_active_source_panel_v0213")
				break


func clear_active_idea_source_v0213() -> void:
	_active_idea_source_v0213.clear()
	_active_source_saved_v0213 = false
	_active_source_external_path_v0213 = ""
	_refresh_active_source_banner_v0213()
	active_idea_source_changed_v0213.emit({})


func active_idea_source_v0213() -> Dictionary:
	return _active_idea_source_v0213.duplicate(true)


func active_idea_source_context_v0213() -> String:
	if _active_idea_source_v0213.is_empty():
		return ""
	return _idea_source_service_v0213.generation_context(_active_idea_source_v0213)


func prepared_generation_input_v0213(additional_direction: String) -> String:
	var ordinary_prompt := additional_direction.strip_edges()
	var source_context := active_idea_source_context_v0213().strip_edges()
	if source_context.is_empty():
		return ordinary_prompt
	var blocks: Array[String] = [source_context]
	if not ordinary_prompt.is_empty():
		blocks.append(
			"CURRENT IDEA-GENERATOR PROMPT / ADDITIONAL DIRECTION:\n%s"
			% ordinary_prompt
		)
	return "\n\n".join(blocks)


func prompt_presentation_v0213() -> Dictionary:
	if _active_idea_source_v0213.is_empty():
		return {
			"label": "Give the AI a theme, fragments, constraints, or leave it blank for varied character concepts.",
			"placeholder": "Example: cyberpunk Australia, reluctant healer, enemies-to-allies dynamic…",
			"mode": "primary_prompt"
		}
	return {
		"label": "Additional Direction (optional)\nLeave blank to generate directly from the active Idea Source, or add instructions to narrow this batch.",
		"placeholder": "For example: Focus on scenarios where paternity is already known.",
		"mode": "additional_direction"
	}


func _view_active_source_v0213() -> void:
	if _active_idea_source_v0213.is_empty():
		return
	_source_editor_base_v0213 = _active_idea_source_v0213.duplicate(true)
	_source_saved_v0213 = _active_source_saved_v0213
	_source_external_path_v0213 = _active_source_external_path_v0213
	_populate_source_editor_v0213(_source_editor_base_v0213)
	_refresh_source_library_v0213(
		str(_source_editor_base_v0213.get("id", "")) if _source_saved_v0213 else ""
	)
	_source_status_v0213.text = (
		"Editing the active saved source. Changes are not saved automatically; press Use in Idea Generator to apply edits to generation."
		if _source_saved_v0213 else
		"Editing the active temporary source. It has not been added to the library; press Use in Idea Generator to apply edits."
	)
	_show_source_tab_v0213()


func _change_active_source_v0213() -> void:
	_show_source_tab_v0213()
	if _source_status_v0213 != null:
		_source_status_v0213.text = "Choose, load or create a source, then press Use in Idea Generator to replace the active source."


func _clear_active_source_from_panel_v0213() -> void:
	clear_active_idea_source_v0213()


func _focus_active_source_panel_v0213() -> void:
	if _active_source_view_button_v0213 != null and not _active_idea_source_v0213.is_empty():
		_active_source_view_button_v0213.grab_focus()


func open_source_library_v0213() -> void:
	_show_source_tab_v0213()
	open_studio()


func load_saved_source_v0213(source_id: String, open_library: bool = true) -> bool:
	var result := _idea_source_service_v0213.load_source(source_id)
	if not bool(result.get("ok", false)):
		if _source_status_v0213 != null:
			_source_status_v0213.text = str(result.get("error", "Could not load saved Idea Source."))
		return false
	_source_editor_base_v0213 = (result.get("source", {}) as Dictionary).duplicate(true)
	_source_saved_v0213 = true
	_source_external_path_v0213 = ""
	_populate_source_editor_v0213(_source_editor_base_v0213)
	_refresh_source_library_v0213(source_id)
	if open_library:
		open_source_library_v0213()
	_source_status_v0213.text = "Loaded the saved Idea Source."
	return true


func _show_source_tab_v0213() -> void:
	_refresh_source_library_v0213(
		str(_source_editor_base_v0213.get("id", "")) if _source_saved_v0213 else ""
	)
	for index in range(_tabs.get_tab_count()):
		if _tabs.get_tab_title(index) == "Idea Sources":
			_tabs.current_tab = index
			return


func _suggest_source_title_v0213() -> void:
	var captured := _capture_source_editor_v0213()
	if not bool(captured.get("ok", false)):
		_source_status_v0213.text = str(captured.get("error", "Could not read source fields."))
		return
	var source: Dictionary = captured.get("source", {})
	if not _source_title_v0213.text.strip_edges().is_empty():
		_source_status_v0213.text = "The existing user-supplied title was preserved."
		return
	_request_ai_source_title_v0213(source)


func _request_ai_source_title_v0213(source_override: Dictionary = {}) -> void:
	var source := source_override.duplicate(true)
	if source.is_empty():
		var captured := _capture_source_editor_v0213()
		if not bool(captured.get("ok", false)):
			_source_status_v0213.text = str(captured.get("error", "Could not read source fields."))
			return
		source = (captured.get("source", {}) as Dictionary).duplicate(true)
	if not str(source.get("title", "")).strip_edges().is_empty():
		_source_status_v0213.text = "The existing user-supplied title was preserved."
		return
	if get_signal_connection_list("idea_source_title_requested_v0213").is_empty():
		apply_idea_source_title_fallback_v0213()
		return
	_source_status_v0213.text = "Asking the configured Text model for an editable source name; generation does not wait for it."
	idea_source_title_requested_v0213.emit(
		source,
		_idea_source_service_v0213.generation_context(source)
	)


func apply_idea_source_title_suggestion_v0213(
	title_suggestion: String, source_id: String = ""
) -> void:
	var clean_title := title_suggestion.strip_edges()
	if clean_title.is_empty():
		apply_idea_source_title_fallback_v0213(source_id)
		return
	if not source_id.is_empty() and str(_source_editor_base_v0213.get("id", "")) != source_id:
		return
	if not _source_title_v0213.text.strip_edges().is_empty():
		return
	_source_title_v0213.text = clean_title
	_source_editor_base_v0213["title"] = clean_title
	if str(_active_idea_source_v0213.get("id", "")) == str(_source_editor_base_v0213.get("id", "")):
		_active_idea_source_v0213["title"] = clean_title
		_refresh_active_source_banner_v0213()
	_source_status_v0213.text = "The Text model suggested an editable source name. Save explicitly if you want to keep it."


func apply_idea_source_title_fallback_v0213(source_id: String = "") -> void:
	if not source_id.is_empty() and str(_source_editor_base_v0213.get("id", "")) != source_id:
		return
	if not _source_title_v0213.text.strip_edges().is_empty():
		return
	var captured := _capture_source_editor_v0213()
	var source: Dictionary = (
		captured.get("source", {}) if bool(captured.get("ok", false)) else _source_editor_base_v0213
	)
	var fallback := _idea_source_service_v0213.suggested_title_fallback(source)
	_source_title_v0213.text = fallback
	_source_editor_base_v0213["title"] = fallback
	if str(_active_idea_source_v0213.get("id", "")) == str(_source_editor_base_v0213.get("id", "")):
		_active_idea_source_v0213["title"] = fallback
		_refresh_active_source_banner_v0213()
	_source_status_v0213.text = "AI naming was unavailable, so CCF supplied an editable local fallback. Idea generation was not blocked."


func _refresh_source_library_v0213(selected_id: String = "") -> void:
	if _source_list_v0213 == null:
		return
	_source_list_v0213.clear()
	_source_visible_ids_v0213.clear()
	var select_index := -1
	for source in _idea_source_service_v0213.list_sources():
		var title_text := str(source.get("title", "")).strip_edges()
		if title_text.is_empty():
			title_text = "Untitled Idea Source"
		var subtitle := str(source.get("description", "")).strip_edges().replace("\n", " ")
		if subtitle.length() > 90:
			subtitle = subtitle.left(89) + "…"
		_source_list_v0213.add_item(title_text + ("\n" + subtitle if not subtitle.is_empty() else ""))
		var source_id := str(source.get("id", ""))
		_source_visible_ids_v0213.append(source_id)
		if source_id == selected_id:
			select_index = _source_visible_ids_v0213.size() - 1
	if select_index >= 0:
		_source_list_v0213.select(select_index)


func _populate_source_editor_v0213(source: Dictionary) -> void:
	if _source_title_v0213 == null:
		return
	_source_title_v0213.text = str(source.get("title", ""))
	_source_description_v0213.text = str(source.get("description", ""))
	_source_version_v0213.text = str(source.get("source_version", ""))
	var bible_value: Variant = source.get("bible", {})
	_source_bible_v0213.text = JSON.stringify(bible_value, "  ") if bible_value is Dictionary and not (bible_value as Dictionary).is_empty() else ""
	_source_summary_v0213.text = str(source.get("summary", ""))
	_source_premise_v0213.text = str(source.get("core_premise", ""))
	_source_setup_v0213.text = str(source.get("setup", ""))
	_source_variables_v0213.text = _source_list_text_v0213(source.get("core_variables", []))
	_source_rules_v0213.text = _source_list_text_v0213(source.get("generation_rules", []))
	_source_guardrails_v0213.text = _source_list_text_v0213(source.get("guardrails", []))
	_source_diversity_v0213.text = _source_list_text_v0213(source.get("diversity_axes", []))
	_source_links_v0213.text = _source_list_text_v0213(source.get("cross_links", []))
	_source_tags_v0213.text = ", ".join(source.get("tags", []))
	_source_notes_v0213.text = str(source.get("notes", ""))
	var sections_value: Variant = source.get("sections", [])
	_source_sections_v0213.text = JSON.stringify(sections_value, "  ") if sections_value is Array and not (sections_value as Array).is_empty() else ""
	_source_raw_prompt_v0213.text = str(source.get("raw_prompt", ""))


func _capture_source_editor_v0213() -> Dictionary:
	var source := _source_editor_base_v0213.duplicate(true)
	if str(source.get("id", "")).is_empty():
		source["id"] = str(_idea_source_service_v0213.blank_source().get("id", ""))
	source["format"] = IDEA_SOURCE_SERVICE_V0213.FORMAT_ID
	source["schema_version"] = IDEA_SOURCE_SERVICE_V0213.SCHEMA_VERSION
	source["title"] = _source_title_v0213.text.strip_edges()
	source["description"] = _source_description_v0213.text.strip_edges()
	source["source_version"] = _source_version_v0213.text.strip_edges()
	source["summary"] = _source_summary_v0213.text.strip_edges()
	source["core_premise"] = _source_premise_v0213.text.strip_edges()
	source["setup"] = _source_setup_v0213.text.strip_edges()
	source["core_variables"] = _source_lines_v0213(_source_variables_v0213.text)
	source["generation_rules"] = _source_lines_v0213(_source_rules_v0213.text)
	source["guardrails"] = _source_lines_v0213(_source_guardrails_v0213.text)
	source["diversity_axes"] = _source_lines_v0213(_source_diversity_v0213.text)
	source["cross_links"] = _source_lines_v0213(_source_links_v0213.text)
	source["tags"] = _source_tags_v0213.text.split(",", false)
	source["notes"] = _source_notes_v0213.text.strip_edges()
	source["raw_prompt"] = _source_raw_prompt_v0213.text.strip_edges()
	var bible_text := _source_bible_v0213.text.strip_edges()
	if bible_text.is_empty():
		source["bible"] = {}
	else:
		var bible_json := JSON.new()
		if bible_json.parse(bible_text) != OK or not bible_json.data is Dictionary:
			return {"ok": false, "error": "Source Bible / Series must be a valid JSON object."}
		source["bible"] = (bible_json.data as Dictionary).duplicate(true)
	var sections_text := _source_sections_v0213.text.strip_edges()
	if sections_text.is_empty():
		source["sections"] = []
	else:
		var sections_json := JSON.new()
		if sections_json.parse(sections_text) != OK or not sections_json.data is Array:
			return {"ok": false, "error": "Arbitrary labelled sections must be a valid JSON array."}
		source["sections"] = (sections_json.data as Array).duplicate(true)
	var validation := _idea_source_service_v0213.parse_text(JSON.stringify(source))
	if not bool(validation.get("load_allowed", false)):
		return {"ok": false, "error": _source_result_message_v0213(validation)}
	return {"ok": true, "source": (validation.get("source", {}) as Dictionary).duplicate(true)}


func _source_lines_v0213(text_value: String) -> Array[String]:
	var result: Array[String] = []
	for line in text_value.split("\n", false):
		var clean := str(line).strip_edges().trim_prefix("- ").strip_edges()
		if not clean.is_empty():
			result.append(clean)
	return result


func _source_list_text_v0213(value: Variant) -> String:
	if not value is Array:
		return ""
	var result: Array[String] = []
	for item in value as Array:
		var clean := str(item).strip_edges()
		if not clean.is_empty():
			result.append(clean)
	return "\n".join(result)


func _source_result_message_v0213(result: Dictionary) -> String:
	var messages: Array[String] = []
	for key in ["errors", "warnings"]:
		var values: Variant = result.get(key, [])
		if not values is Array:
			continue
		for issue_value in values as Array:
			if issue_value is Dictionary:
				messages.append(str((issue_value as Dictionary).get("message", "Invalid Idea Source.")))
	return " ".join(messages) if not messages.is_empty() else "The Idea Source could not be loaded."


func _refresh_active_source_banner_v0213() -> void:
	if (
		_active_source_banner_v0213 == null
		or _active_source_explanation_v0213 == null
		or _active_source_actions_v0213 == null
	):
		return
	if _active_idea_source_v0213.is_empty():
		_active_source_banner_v0213.text = "Idea Source: None"
		_active_source_explanation_v0213.text = "The normal prompt is the primary generator input. Choose a reusable source from the Idea Sources tab when needed."
		_active_source_actions_v0213.hide()
		return
	var source_title := str(_active_idea_source_v0213.get("title", "")).strip_edges()
	if source_title.is_empty():
		source_title = "Untitled reusable source"
	_active_source_banner_v0213.text = "Active Idea Source: %s" % source_title
	_active_source_explanation_v0213.text = "This structured source will be included in every Idea generation request until cleared or replaced. The prompt below is optional Additional Direction for this batch."
	_active_source_actions_v0213.show()


func idea_source_capabilities_v0213() -> Dictionary:
	var capabilities := _idea_source_service_v0213.capabilities()
	capabilities["source_library_ui"] = _source_tab_v0213 != null
	capabilities["idea_pack_actions_preserved"] = (
		_import_dialog_v0210 != null and _export_dialog_v0210 != null
	)
	capabilities["active_source_id"] = str(_active_idea_source_v0213.get("id", ""))
	capabilities["active_source_context"] = active_idea_source_context_v0213()
	return capabilities
