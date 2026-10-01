class_name CCFIdeaGeneratorWindowCurrent
extends "res://scripts/ui/idea_generator_window_v01533_hotfix1.gd"

signal active_idea_source_changed_v0213(source: Dictionary)
signal idea_source_title_requested_v0213(source: Dictionary, context: String)
signal direction_preset_selected_v02111(preset: Dictionary, source_id: String)

const IDEA_PACK_SERVICE_V0210 = preload(
	"res://scripts/services/idea_pack_service_v0210.gd"
)
const IDEA_SOURCE_SERVICE_V0213 = preload(
	"res://scripts/services/idea_source_service_v0213.gd"
)
const IDEA_NOTEBOOK_TREE_V0215 = preload(
	"res://scripts/ui/idea_notebook_tree_v0215.gd"
)
const IDEA_LIBRARY_LIST_V0217 = preload(
	"res://scripts/ui/idea_library_list_v0217.gd"
)
const IDEA_FOLDER_PICKER_V0217 = preload(
	"res://scripts/ui/idea_folder_picker_v0217.gd"
)
const IDEA_FOLDER_ICON_V0216 = preload(
	"res://assets/icons/idea_folder_v0216.svg"
)
const IDEA_SPECIAL_VIEW_ICON_V0216 = preload(
	"res://assets/icons/idea_special_view_v0216.svg"
)

const IDEA_GENERATOR_WINDOW_STATE_ID_V0217 := "unified_idea_generator_v0217"
const IDEA_GENERATOR_PREFERRED_SIZE_V0217 := Vector2i(1280, 900)
const IDEA_GENERATOR_MINIMUM_SIZE_V0217 := Vector2i(880, 680)

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
var _export_folder_ids_v0217: Dictionary = {}

var _notebook_search_v0211: LineEdit
var _notebook_sort_v0211: OptionButton
var _idea_sort_v0211: OptionButton
var _idea_result_summary_v0211: Label
var _save_new_notebook_dialog_v0211: ConfirmationDialog
var _save_new_notebook_name_v0211: LineEdit
var _save_new_notebook_folder_v0215: OptionButton
var _save_generated_folder_picker_v0217
var _save_new_folder_parent_picker_v0217

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
var _pending_delete_idea_ids_v0216: Array[String] = []
var _idea_delete_batch_refresh_count_v0216 := 0

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
var _source_direction_presets_v02111: Array[Dictionary] = []
var _source_preset_list_v02111: ItemList
var _source_preset_group_v02111: LineEdit
var _source_preset_title_v02111: LineEdit
var _source_preset_direction_v02111: TextEdit
var _source_preset_selected_v02111 := -1
var _source_preset_updating_v02111 := false
var _active_source_preset_controls_v02111: VBoxContainer
var _active_source_preset_group_v02111: OptionButton
var _active_source_preset_choice_v02111: OptionButton
var _active_source_preset_updating_v02111 := false
var _active_source_preset_id_v02111 := ""
var _source_load_dialog_v0213: FileDialog
var _source_export_dialog_v0213: FileDialog
var _source_pending_export_v0213: Dictionary = {}
var _source_delete_dialog_v0213: ConfirmationDialog
var _idea_generator_geometry_active_v0217 := false
var _provisional_ideas_panel_v02112: PanelContainer
var _provisional_ideas_scroll_v02112: ScrollContainer
var _provisional_ideas_list_v02112: VBoxContainer
var _provisional_ideas_status_v02112: Label
var _provisional_ideas_notice_v02112: Label
var _provisional_idea_job_v02112 := ""
var _provisional_idea_group_v02112 := ""
var _provisional_idea_count_v02112 := 0
var _provisional_batch_index_v02112 := 0
var _provisional_batch_count_v02112 := 1
var _provisional_batch_target_v02112 := 0
var _provisional_provider_label_v02112 := ""


func _ready() -> void:
	super._ready()
	min_size = IDEA_GENERATOR_MINIMUM_SIZE_V0217
	size = IDEA_GENERATOR_PREFERRED_SIZE_V0217
	if _ai_ideas_host != null:
		_ai_ideas_host.custom_minimum_size.y = 420
	var visibility_callback := Callable(
		self, "_on_idea_generator_visibility_changed_v0217"
	)
	if not visibility_changed.is_connected(visibility_callback):
		visibility_changed.connect(visibility_callback)
	var delete_key_callback := Callable(self, "_on_idea_list_gui_input_v0216")
	if (
		_idea_list_v01532 != null
		and not _idea_list_v01532.gui_input.is_connected(delete_key_callback)
	):
		_idea_list_v01532.gui_input.connect(delete_key_callback)
	if _delete_idea_dialog_v01532 != null:
		var cancel_callback := Callable(self, "_cancel_delete_ideas_v0216")
		if not _delete_idea_dialog_v01532.canceled.is_connected(cancel_callback):
			_delete_idea_dialog_v01532.canceled.connect(cancel_callback)
	_build_idea_pack_dialogs_v0210()
	_build_save_new_notebook_dialog_v0211()
	_build_idea_source_tab_v0213()
	_build_idea_source_dialogs_v0213()
	_install_active_source_banner_v0213()
	_refresh_source_library_v0213()
	_update_delete_idea_action_v0216()
	_install_provisional_ideas_v02112()


func _install_provisional_ideas_v02112() -> void:
	var ai_tab := _tabs.get_node_or_null("AI Ideas") as VBoxContainer
	if ai_tab == null or _ai_ideas_host == null:
		return
	_provisional_ideas_panel_v02112 = PanelContainer.new()
	_provisional_ideas_panel_v02112.name = "ProvisionalIdeasV02112"
	_provisional_ideas_panel_v02112.visible = false
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_provisional_ideas_panel_v02112.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 7)
	margin.add_child(root)
	_provisional_ideas_status_v02112 = Label.new()
	_provisional_ideas_status_v02112.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_provisional_ideas_status_v02112.modulate = Color(0.88, 0.72, 1.0)
	root.add_child(_provisional_ideas_status_v02112)
	_provisional_ideas_notice_v02112 = Label.new()
	_provisional_ideas_notice_v02112.name = "ProvisionalIdeasNoticeV02112"
	_provisional_ideas_notice_v02112.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_provisional_ideas_notice_v02112.modulate = Color(0.95, 0.72, 0.43)
	_provisional_ideas_notice_v02112.hide()
	root.add_child(_provisional_ideas_notice_v02112)
	_provisional_ideas_scroll_v02112 = ScrollContainer.new()
	_provisional_ideas_scroll_v02112.name = "ProvisionalIdeasScrollV02112"
	_provisional_ideas_scroll_v02112.custom_minimum_size = Vector2(0, 280)
	_provisional_ideas_scroll_v02112.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_provisional_ideas_scroll_v02112.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_provisional_ideas_scroll_v02112.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_provisional_ideas_scroll_v02112)
	_provisional_ideas_list_v02112 = VBoxContainer.new()
	_provisional_ideas_list_v02112.name = "ProvisionalIdeasListV02112"
	_provisional_ideas_list_v02112.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_provisional_ideas_list_v02112.add_theme_constant_override("separation", 7)
	_provisional_ideas_scroll_v02112.add_child(_provisional_ideas_list_v02112)
	ai_tab.add_child(_provisional_ideas_panel_v02112)
	ai_tab.move_child(
		_provisional_ideas_panel_v02112, _ai_ideas_host.get_index()
	)


func begin_provisional_ideas_v02112(job_id: String, metadata: Dictionary = {}) -> void:
	if _provisional_ideas_panel_v02112 == null:
		return
	var group_id := str(metadata.get("idea_batch_group_id", job_id))
	if group_id.is_empty():
		group_id = job_id
	if group_id != _provisional_idea_group_v02112:
		_clear_provisional_cards_v02112()
		_provisional_idea_group_v02112 = group_id
	_remove_provisional_job_cards_v02112(job_id)
	_provisional_idea_job_v02112 = job_id
	_provisional_idea_count_v02112 = 0
	_provisional_batch_index_v02112 = int(metadata.get("idea_batch_index", 0))
	_provisional_batch_count_v02112 = maxi(
		1, int(metadata.get("idea_batch_request_count", 1))
	)
	_provisional_batch_target_v02112 = maxi(
		0, int(metadata.get("idea_batch_request_size", 0))
	)
	var provider_parts: Array[String] = []
	for provider_value in [metadata.get("profile_name", ""), metadata.get("model", "")]:
		var provider_part := str(provider_value).strip_edges()
		if not provider_part.is_empty() and not provider_part in provider_parts:
			provider_parts.append(provider_part)
	_provisional_provider_label_v02112 = " • ".join(provider_parts)
	_provisional_ideas_panel_v02112.visible = true
	_set_provisional_status_v02112("● Connecting…")


func append_provisional_idea_v02112(job_id: String, idea: Dictionary) -> void:
	if job_id != _provisional_idea_job_v02112 or _provisional_ideas_list_v02112 == null:
		return
	var follow_output := provisional_should_follow_v02112()
	_provisional_idea_count_v02112 += 1
	_provisional_ideas_list_v02112.add_child(
		_build_provisional_idea_card_v02112(
			idea,
			_provisional_idea_count_v02112,
			"Provisional — awaiting the complete response and validation",
			true,
			job_id
		)
	)
	_set_provisional_status_v02112("● Generating final response…")
	if follow_output:
		call_deferred("_scroll_provisional_to_bottom_v02112")


func set_provisional_ideas_checking_v02112(job_id: String) -> void:
	if job_id != _provisional_idea_job_v02112 or _provisional_ideas_status_v02112 == null:
		return
	_provisional_ideas_status_v02112.text = (
		"◌ Checking/parsing… The complete response is being validated."
	)


func set_provisional_phase_v02112(
	job_id: String, phase: String, metadata: Dictionary = {}
) -> void:
	if job_id != _provisional_idea_job_v02112:
		return
	match phase:
		"connecting":
			_set_provisional_status_v02112("● Connecting…")
		"thinking":
			_set_provisional_status_v02112("● Thinking…")
		"generating_final", "streaming":
			_set_provisional_status_v02112("● Generating final response…")
		"checking":
			set_provisional_ideas_checking_v02112(job_id)
		"retrying":
			discard_provisional_attempt_v02112(job_id, "retry", metadata)
		"json_repair":
			discard_provisional_attempt_v02112(job_id, "json_repair", metadata)
		"transport_fallback":
			discard_provisional_attempt_v02112(job_id, "provider_unsupported", metadata)


func discard_provisional_attempt_v02112(
	job_id: String, reason: String, _metadata: Dictionary = {}
) -> void:
	if job_id != _provisional_idea_job_v02112:
		return
	_remove_provisional_job_cards_v02112(job_id)
	_provisional_idea_count_v02112 = 0
	if _provisional_ideas_notice_v02112 != null:
		_provisional_ideas_notice_v02112.show()
		match reason:
			"retry", "malformed_stream":
				_provisional_ideas_notice_v02112.text = (
					"Stream interrupted — retrying. Provisional Ideas from the abandoned attempt were discarded."
				)
			"provider_unsupported", "transport_fallback":
				_provisional_ideas_notice_v02112.text = (
					"Streaming unavailable for this attempt — continuing normally. Final Ideas will appear when generation finishes."
				)
			"json_repair":
				_provisional_ideas_notice_v02112.text = (
					"Generated response needs JSON repair — requesting corrected output. Provisional Ideas from the malformed response were discarded."
				)
			_:
				_provisional_ideas_notice_v02112.text = (
					"The provisional attempt was discarded: %s." % reason.replace("_", " ")
				)
	_provisional_ideas_panel_v02112.show()


func retain_completed_provisional_batch_v02112(
	job_id: String, ideas: Array, metadata: Dictionary = {}
) -> void:
	if job_id != _provisional_idea_job_v02112:
		return
	_remove_provisional_job_cards_v02112(job_id)
	var batch_number := int(metadata.get("idea_batch_index", _provisional_batch_index_v02112)) + 1
	var follow_output := provisional_should_follow_v02112()
	for idea_value in ideas:
		if not idea_value is Dictionary:
			continue
		_provisional_ideas_list_v02112.add_child(
			_build_provisional_idea_card_v02112(
				idea_value,
				_provisional_ideas_list_v02112.get_child_count() + 1,
				"Batch %d received — retained while the generation session continues" % batch_number,
				false,
				job_id
			)
		)
	_provisional_idea_job_v02112 = ""
	_provisional_idea_count_v02112 = 0
	if follow_output:
		call_deferred("_scroll_provisional_to_bottom_v02112")


func provisional_should_follow_v02112() -> bool:
	if _provisional_ideas_scroll_v02112 == null:
		return true
	var bar := _provisional_ideas_scroll_v02112.get_v_scroll_bar()
	if bar == null or bar.max_value <= bar.page:
		return true
	return bar.value >= bar.max_value - bar.page - 24.0


func _set_provisional_status_v02112(state_text: String) -> void:
	if _provisional_ideas_status_v02112 == null:
		return
	var received_target := (
		str(_provisional_batch_target_v02112)
		if _provisional_batch_target_v02112 > 0
		else "?"
	)
	_provisional_ideas_status_v02112.text = (
		"%s%s\nBatch %d of %d • Ideas received: %d / %s"
		% [
			(
				_provisional_provider_label_v02112 + "\n"
				if not _provisional_provider_label_v02112.is_empty()
				else ""
			),
			state_text,
			_provisional_batch_index_v02112 + 1,
			_provisional_batch_count_v02112,
			_provisional_idea_count_v02112,
			received_target
		]
	)


func _build_provisional_idea_card_v02112(
	idea: Dictionary,
	display_index: int,
	state_text: String,
	provisional: bool,
	job_id: String
) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.set_meta("stream_job_id_v02112", job_id)
	card.set_meta("stream_provisional_v02112", provisional)
	card.add_theme_constant_override("separation", 3)
	var title_label := Label.new()
	title_label.text = "%d. %s" % [display_index, str(idea.get("title", "Untitled Idea"))]
	title_label.add_theme_font_size_override("font_size", 16)
	card.add_child(title_label)
	var concept := Label.new()
	concept.text = str(idea.get("concept", idea.get("description", "")))
	concept.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	concept.modulate = Color(0.75, 0.78, 0.87)
	card.add_child(concept)
	var state_label := Label.new()
	state_label.text = state_text
	state_label.modulate = (
		Color(0.88, 0.66, 0.42) if provisional else Color(0.55, 0.82, 0.64)
	)
	card.add_child(state_label)
	return card


func _remove_provisional_job_cards_v02112(job_id: String) -> void:
	if _provisional_ideas_list_v02112 == null:
		return
	for child in _provisional_ideas_list_v02112.get_children():
		if (
			bool(child.get_meta("stream_provisional_v02112", false))
			and str(child.get_meta("stream_job_id_v02112", "")) == job_id
		):
			child.queue_free()


func _scroll_provisional_to_bottom_v02112() -> void:
	if _provisional_ideas_scroll_v02112 == null:
		return
	var bar := _provisional_ideas_scroll_v02112.get_v_scroll_bar()
	if bar != null:
		_provisional_ideas_scroll_v02112.scroll_vertical = int(bar.max_value)


func _clear_provisional_cards_v02112() -> void:
	if _provisional_ideas_list_v02112 != null:
		for child in _provisional_ideas_list_v02112.get_children():
			child.queue_free()


func clear_provisional_ideas_v02112(job_id: String = "") -> void:
	if (
		not job_id.is_empty()
		and not _provisional_idea_job_v02112.is_empty()
		and job_id != _provisional_idea_job_v02112
	):
		return
	_clear_provisional_cards_v02112()
	if _provisional_ideas_panel_v02112 != null:
		_provisional_ideas_panel_v02112.visible = false
	if _provisional_ideas_notice_v02112 != null:
		_provisional_ideas_notice_v02112.hide()
		_provisional_ideas_notice_v02112.text = ""
	_provisional_idea_job_v02112 = ""
	_provisional_idea_group_v02112 = ""
	_provisional_idea_count_v02112 = 0
	_provisional_provider_label_v02112 = ""


func open_studio() -> void:
	_open_studio_request_count_v0215_hotfix += 1
	_options = OPTION_SERVICE.load_options()
	_rebuild_structured_fields()
	_idea_generator_geometry_active_v0217 = true
	CCFToolWindowStateService.show_window(
		self,
		IDEA_GENERATOR_WINDOW_STATE_ID_V0217,
		IDEA_GENERATOR_PREFERRED_SIZE_V0217
	)
	grab_focus()


func _on_idea_generator_visibility_changed_v0217() -> void:
	if _idea_generator_geometry_active_v0217 and not visible:
		CCFToolWindowStateService.save_window(
			self, IDEA_GENERATOR_WINDOW_STATE_ID_V0217
		)


func _build_notebook_tab_v01532() -> void:
	super._build_notebook_tab_v01532()
	if _notebook_tab_v01532 == null:
		return
	_notebook_tab_v01532.name = "Idea Library"
	_idea_list_v01532.set_script(IDEA_LIBRARY_LIST_V0217)
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
	import_button.tooltip_text = "Validate and preview a .ccfideas.json file before adding selected entries to the Idea Library."
	import_button.pressed.connect(_open_import_dialog_v0210)
	action_row.add_child(import_button)
	var export_button := Button.new()
	export_button.name = "ExportIdeaPackV0210"
	export_button.text = "Choose Ideas & Export…"
	export_button.tooltip_text = "Choose checked ideas from all saved ideas, one recursive Folder, the live multi-selection, one Bible or one semantic Series, then export a structured Idea Pack."
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
	for child in notebook_box.get_children():
		if child is Label:
			(child as Label).text = "Folder"
			break
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
	_notebook_search_v0211.placeholder_text = "Find folder…"
	_notebook_search_v0211.custom_minimum_size.x = 170
	_notebook_search_v0211.tooltip_text = (
		"Filter the Folder tree by name while retaining each matching Folder's ancestor path."
	)
	_notebook_search_v0211.text_changed.connect(
		func(_text: String) -> void: _refresh_notebook_v01532()
	)

	_notebook_sort_v0211 = OptionButton.new()
	_notebook_sort_v0211.name = "NotebookSortV0211"
	_notebook_sort_v0211.tooltip_text = "Choose how sibling Folders are ordered."
	_add_option_v01532(_notebook_sort_v0211, "Folders: A–Z", "name")
	_add_option_v01532(_notebook_sort_v0211, "Folders: Most Ideas", "count")
	_add_option_v01532(_notebook_sort_v0211, "Folders: Recent Activity", "recent")
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
	_add_option_v01532(_idea_sort_v0211, "Ideas: Folder then Title", "folder_title")
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
				"New Notebook…", "New Folder…", "Rename…",
				"Delete Notebook…", "Delete Folder…"
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
	tree_heading.text = "Folders"
	tree_heading.add_theme_font_size_override("font_size", 17)
	tree_panel.add_child(tree_heading)
	var toolbar := HFlowContainer.new()
	toolbar.name = "IdeaNotebookTreeToolbarV0215"
	toolbar.add_theme_constant_override("separation", 5)
	tree_panel.add_child(toolbar)
	_add_tree_toolbar_button_v0215(toolbar, "+ Folder", "Create a folder inside the selected folder.", "new_folder")
	_add_tree_toolbar_button_v0215(toolbar, "Rename", "Rename the selected folder.", "rename")
	_add_tree_toolbar_button_v0215(toolbar, "Delete", "Safely delete the selected folder without deleting Ideas.", "delete")

	var organization := ideas_panel.get_node_or_null("IdeaNotebookOrganizationV0211") as VBoxContainer
	if organization != null:
		if _notebook_search_v0211.get_parent() == organization:
			organization.remove_child(_notebook_search_v0211)
			tree_panel.add_child(_notebook_search_v0211)
		if _notebook_sort_v0211.get_parent() == organization:
			organization.remove_child(_notebook_sort_v0211)
			tree_panel.add_child(_notebook_sort_v0211)
	_notebook_search_v0211.placeholder_text = "Find folder…"
	_notebook_search_v0211.tooltip_text = "Search the hierarchy while retaining matching items and their ancestor path."
	_notebook_sort_v0211.tooltip_text = "Sort sibling Folders inside every parent Folder."

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
	(_notebook_tree_v0215 as CCFIdeaNotebookTreeV0215).idea_drop.connect(
		_on_idea_tree_drop_v0217
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
		"rename": _open_tree_name_dialog_v0215("rename")
		"delete": _request_tree_delete_v0215()


func _open_tree_name_dialog_v0215(action: String) -> void:
	_notebook_tree_name_action_v0215 = action
	_name_action_v01532 = action
	var metadata := _selected_tree_metadata_v0215()
	var kind := str(metadata.get("kind", "special"))
	if action == "rename":
		if kind != "folder":
			_status_v01532.text = "All Ideas and Unfiled are built-in views and cannot be renamed."
			return
	var dialog_state := _tree_name_dialog_state_v0216(
		action, metadata, _tree_creation_parent_v0215()
	)
	_name_dialog_v01532.title = str(dialog_state.get("title", "Idea Library"))
	_name_dialog_v01532.dialog_text = str(dialog_state.get("description", ""))
	_name_dialog_v01532.ok_button_text = str(dialog_state.get("confirm", "Continue"))
	_name_input_v01532.placeholder_text = str(dialog_state.get("placeholder", "Name"))
	_name_input_v01532.text = str(dialog_state.get("value", ""))
	_name_dialog_v01532.popup_centered()
	_name_input_v01532.grab_focus()


func _tree_name_dialog_state_v0216(
	action: String, metadata: Dictionary, target_parent_id: String
) -> Dictionary:
	var kind := str(metadata.get("kind", ""))
	if action == "rename" and kind == "folder":
		return {
			"title": "Rename Folder",
			"description": "Rename this folder. Its stable ID and contents will not change.",
			"placeholder": "Folder name",
			"confirm": "Rename Folder",
			"value": str(metadata.get("name", ""))
		}
	var target_path := NOTEBOOK_SERVICE.folder_path_from_snapshot(
		target_parent_id, _current_hierarchy_snapshot_v0216()
	)
	var location := "Root" if target_path.is_empty() else target_path
	if action == "new_folder":
		return {
			"title": "Create Folder",
			"description": "Create a new folder inside:\n%s" % location,
			"placeholder": "Folder name",
			"confirm": "Create Folder",
			"value": ""
		}
	return {
		"title": "Create Folder",
		"description": "Create a new folder inside:\n%s" % location,
		"placeholder": "Folder name",
		"confirm": "Create Folder",
		"value": ""
	}


func _current_hierarchy_snapshot_v0216() -> Dictionary:
	if _hierarchy_snapshot_v0215.is_empty():
		_hierarchy_snapshot_v0215 = NOTEBOOK_SERVICE.hierarchy_snapshot()
	return _hierarchy_snapshot_v0215


func _open_name_dialog_v01532(action: String) -> void:
	_open_tree_name_dialog_v0215("rename" if action == "rename" else "new_folder")


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
		"rename":
			var kind := str(metadata.get("kind", ""))
			if kind == "folder":
				result = NOTEBOOK_SERVICE.rename_folder(
					str(metadata.get("id", "")), _name_input_v01532.text
				)
			else:
				result = {"ok": false, "error": "Select a folder to rename."}
		_:
			result = {"ok": false, "error": "Unknown Folder action."}
	if not bool(result.get("ok", false)):
		_status_v01532.text = str(result.get("error", "Could not update the Folder hierarchy."))
		return
	_refresh_notebook_v01532()
	_status_v01532.text = "Idea Library hierarchy updated."


func _request_tree_delete_v0215() -> void:
	var metadata := _selected_tree_metadata_v0215()
	var kind := str(metadata.get("kind", "special"))
	var item_name := str(metadata.get("name", ""))
	if kind == "folder":
		_notebook_tree_pending_delete_kind_v0215 = "folder"
		_delete_notebook_dialog_v01532.title = "Delete Idea Library Folder"
		_delete_notebook_dialog_v01532.ok_button_text = "Delete Folder"
		_delete_notebook_dialog_v01532.dialog_text = (
			"Delete folder ‘%s’? Its direct Ideas and child Folders will move to the parent Folder. Root-level direct Ideas become Unfiled. No Ideas will be deleted."
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
	result = NOTEBOOK_SERVICE.delete_folder(item_id)
	if not bool(result.get("ok", false)):
		_status_v01532.text = str(result.get("error", "Could not delete the selected item."))
		return
	_notebook_tree_selection_kind_v0215 = "special"
	_notebook_tree_selection_id_v0215 = "__all__"
	_refresh_notebook_v01532()
	_status_v01532.text = "Folder deleted; its Ideas and child Folders were kept at the parent level."


func _tree_creation_parent_v0215() -> String:
	var metadata := _selected_tree_metadata_v0215()
	var kind := str(metadata.get("kind", "special"))
	if kind == "folder":
		return str(metadata.get("id", ""))
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
	if _notebook_tree_selection_kind_v0215 == "folder":
		_fill_destination_notebooks_v01532(
			_save_generated_notebook_v01532,
			_notebook_tree_selection_id_v0215
		)
	var target_row := _save_generated_notebook_v01532.get_parent() as HBoxContainer
	if target_row == null:
		return
	var preferred_folder_id := _selected_metadata_v01532(
		_save_generated_notebook_v01532, ""
	)
	_save_generated_notebook_v01532.hide()
	var target_label := target_row.get_child(0) as Label
	if target_label != null:
		target_label.text = "Destination Folder"
	var create_button := Button.new()
	create_button.name = "NewFolderWhileSavingV0217"
	create_button.text = "New Folder…"
	create_button.tooltip_text = (
		"Create a Folder and select it as the destination without leaving this save window."
	)
	create_button.pressed.connect(_open_new_notebook_while_saving_v0211)
	target_row.add_child(create_button)
	target_row.move_child(
		create_button, _save_generated_notebook_v01532.get_index() + 1
	)
	var content := target_row.get_parent() as VBoxContainer
	if content == null:
		return
	_save_generated_folder_picker_v0217 = IDEA_FOLDER_PICKER_V0217.new()
	_save_generated_folder_picker_v0217.name = "SaveGeneratedFolderPickerV0217"
	content.add_child(_save_generated_folder_picker_v0217)
	content.move_child(
		_save_generated_folder_picker_v0217, target_row.get_index() + 1
	)
	_save_generated_folder_picker_v0217.configure_v0217(true, false, true)
	_save_generated_folder_picker_v0217.refresh_v0217(
		preferred_folder_id,
		"folder" if not preferred_folder_id.is_empty() else "unfiled"
	)
	_save_generated_folder_picker_v0217.folder_selected.connect(
		_on_save_generated_folder_selected_v0217
	)


func _build_save_new_notebook_dialog_v0211() -> void:
	_save_new_notebook_dialog_v0211 = ConfirmationDialog.new()
	_save_new_notebook_dialog_v0211.name = "SaveNewNotebookDialogV0211"
	_save_new_notebook_dialog_v0211.visible = false
	_save_new_notebook_dialog_v0211.title = "Create Destination Folder"
	_save_new_notebook_dialog_v0211.dialog_text = (
		"Create a Folder under Root or another Folder, then select it as the destination."
	)
	_save_new_notebook_dialog_v0211.ok_button_text = "Create and Select"
	_save_new_notebook_dialog_v0211.force_native = true
	_save_new_notebook_dialog_v0211.transient = true
	_save_new_notebook_dialog_v0211.exclusive = true
	_save_new_notebook_dialog_v0211.size = Vector2i(660, 560)
	_save_new_notebook_dialog_v0211.min_size = Vector2i(600, 500)
	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	_save_new_notebook_dialog_v0211.add_child(content)
	_save_new_notebook_name_v0211 = LineEdit.new()
	_save_new_notebook_name_v0211.name = "SaveNewNotebookNameV0211"
	_save_new_notebook_name_v0211.placeholder_text = "Folder name"
	_save_new_notebook_name_v0211.custom_minimum_size.x = 400
	content.add_child(_save_new_notebook_name_v0211)
	var parent_label := Label.new()
	parent_label.text = "Create under:"
	content.add_child(parent_label)
	_save_new_notebook_folder_v0215 = OptionButton.new()
	_save_new_notebook_folder_v0215.name = "SaveNewNotebookFolderV0215"
	_save_new_notebook_folder_v0215.tooltip_text = "Choose the parent Folder for the new Folder."
	_save_new_notebook_folder_v0215.hide()
	content.add_child(_save_new_notebook_folder_v0215)
	_save_new_folder_parent_picker_v0217 = IDEA_FOLDER_PICKER_V0217.new()
	_save_new_folder_parent_picker_v0217.name = "SaveNewFolderParentPickerV0217"
	_save_new_folder_parent_picker_v0217.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_save_new_folder_parent_picker_v0217)
	_save_new_folder_parent_picker_v0217.configure_v0217(false, true, true)
	_save_new_folder_parent_picker_v0217.folder_selected.connect(
		_on_save_new_folder_parent_selected_v0217
	)
	_save_new_notebook_dialog_v0211.confirmed.connect(
		_create_notebook_while_saving_v0211
	)
	_save_generated_window_v01532.add_child(_save_new_notebook_dialog_v0211)
	_save_new_notebook_dialog_v0211.hide()


func _open_new_notebook_while_saving_v0211() -> void:
	if _save_new_notebook_dialog_v0211 == null:
		return
	_save_new_notebook_name_v0211.text = ""
	_fill_folder_destinations_v0215(
		_save_new_notebook_folder_v0215, _tree_creation_parent_v0215()
	)
	var preferred_parent_id := _selected_metadata_v01532(
		_save_new_notebook_folder_v0215, ""
	)
	_save_new_folder_parent_picker_v0217.refresh_v0217(
		preferred_parent_id,
		"folder" if not preferred_parent_id.is_empty() else "root"
	)
	_save_new_notebook_dialog_v0211.popup_centered_clamped(
		Vector2i(660, 560), 0.92
	)
	_save_new_notebook_name_v0211.grab_focus()


func _create_notebook_while_saving_v0211() -> void:
	var parent_folder_id: String = str(
		_save_new_folder_parent_picker_v0217.selected_folder_id_v0217()
		if _save_new_folder_parent_picker_v0217 != null
		else _selected_metadata_v01532(_save_new_notebook_folder_v0215, "")
	)
	var result := NOTEBOOK_SERVICE.create_folder(
		_save_new_notebook_name_v0211.text,
		parent_folder_id
	)
	if not bool(result.get("ok", false)):
		if _save_generated_status_v01532 != null:
			_save_generated_status_v01532.text = str(
				result.get("error", "Could not create the destination Folder.")
			)
		return
	var folder_value: Variant = result.get("folder", {})
	var folder: Dictionary = (
		folder_value if folder_value is Dictionary else {}
	)
	var folder_id := str(folder.get("id", ""))
	_fill_destination_notebooks_v01532(
		_save_generated_notebook_v01532, folder_id
	)
	if _save_generated_folder_picker_v0217 != null:
		_save_generated_folder_picker_v0217.refresh_v0217(folder_id, "folder")
	_refresh_notebook_v01532()
	if _save_generated_status_v01532 != null:
		_save_generated_status_v01532.text = (
			"Created and selected Folder ‘%s’. Choose Save Selected when ready."
			% NOTEBOOK_SERVICE.folder_path(folder_id)
		)


func _on_save_generated_folder_selected_v0217(
	folder_id: String, selection_kind: String
) -> void:
	if _save_generated_notebook_v01532 == null:
		return
	_select_metadata_v01532(
		_save_generated_notebook_v01532,
		folder_id if selection_kind == "folder" else "",
		""
	)


func _on_save_new_folder_parent_selected_v0217(
	folder_id: String, selection_kind: String
) -> void:
	if _save_new_notebook_folder_v0215 == null:
		return
	_select_metadata_v01532(
		_save_new_notebook_folder_v0215,
		folder_id if selection_kind == "folder" else "",
		""
	)


func _fill_destination_notebooks_v01532(
	selector: OptionButton, selected_id: String
) -> void:
	if selector == null:
		return
	selector.clear()
	_add_option_v01532(selector, "Unfiled", "")
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
		if _notebook_tree_selection_kind_v0215 == "folder"
		else ""
	)


func _selected_notebook_name_v01532() -> String:
	if _notebook_tree_selection_kind_v0215 != "folder":
		return ""
	var snapshot := NOTEBOOK_SERVICE.hierarchy_snapshot()
	return NOTEBOOK_SERVICE.folder_path_from_snapshot(
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
	var count_snapshot := NOTEBOOK_SERVICE.hierarchy_counts_from_snapshot(
		snapshot, all_ideas, include_archived
	)
	var counts: Dictionary = count_snapshot.get("direct_folder_counts", {})
	var folder_counts: Dictionary = count_snapshot.get("folder_counts", {})
	var activity := {}
	for folder in folders:
		activity[str(folder.get("id", ""))] = str(folder.get("updated_at", ""))
	for idea in all_ideas:
		var folder_id := str(idea.get("folder_id", ""))
		var updated := str(idea.get("updated_at", ""))
		if not folder_id.is_empty() and updated > str(activity.get(folder_id, "")):
			activity[folder_id] = updated
	var folder_by_id := {}
	var folder_children := {}
	for folder in folders:
		var folder_id := str(folder.get("id", ""))
		var parent_id := str(folder.get("parent_folder_id", ""))
		folder_by_id[folder_id] = folder
		if not folder_children.has(parent_id):
			folder_children[parent_id] = []
		(folder_children[parent_id] as Array).append(folder)
	var folder_sort := _selected_metadata_v01532(_notebook_sort_v0211, "name")
	for values in folder_children.values():
		(values as Array).sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
			return _notebook_tree_sort_less_v0215(first, second, folder_sort, folder_counts, activity)
		)
	var visible_folders := {}
	if query.is_empty():
		for folder in folders:
			visible_folders[str(folder.get("id", ""))] = true
	else:
		for folder in folders:
			if str(folder.get("name", "")).to_lower().contains(query):
				_mark_folder_subtree_visible_v0215(
					str(folder.get("id", "")), folder_by_id, folder_children,
					{}, visible_folders, {}
				)
	_mark_selected_tree_path_visible_v0215(
		folder_by_id, [], visible_folders, {}
	)
	var selected_parent := ""
	if _notebook_tree_selection_kind_v0215 == "folder" and folder_by_id.has(_notebook_tree_selection_id_v0215):
		selected_parent = str((folder_by_id[_notebook_tree_selection_id_v0215] as Dictionary).get("parent_folder_id", ""))
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
		{"kind": "special", "id": "__unfiled__", "name": "Unfiled"}, "Ideas not assigned to a Folder"
	)
	_add_tree_children_v0215(
		_notebook_tree_root_v0215, "", folder_children, {},
		visible_folders, {}, counts, folder_counts, expanded, not query.is_empty()
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
	_refresh_legacy_notebook_filter_v0215(folders, counts, query)


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


func _add_tree_item_v0215(
	parent: TreeItem, label: String, metadata: Dictionary, tooltip: String
) -> TreeItem:
	var item := _notebook_tree_v0215.create_item(parent)
	var presentation := _tree_presentation_descriptor_v0216(
		str(metadata.get("kind", "special")), str(metadata.get("id", ""))
	)
	var item_metadata := metadata.duplicate(true)
	item_metadata["presentation_kind"] = str(presentation.get("kind", "special"))
	item_metadata["presentation_label"] = str(
		presentation.get("label", "Built-in view")
	)
	item.set_text(0, label)
	item.set_metadata(0, item_metadata)
	var icon_value: Variant = presentation.get("icon")
	if icon_value is Texture2D:
		item.set_icon(0, icon_value as Texture2D)
		item.set_icon_max_width(0, 18)
	var semantic_tooltip := str(presentation.get("tooltip", ""))
	item.set_tooltip_text(
		0,
		semantic_tooltip if tooltip.is_empty()
		else "%s\n%s" % [semantic_tooltip, tooltip]
	)
	_notebook_tree_items_v0215["%s:%s" % [metadata.get("kind", ""), metadata.get("id", "")]] = item
	return item


func _tree_presentation_descriptor_v0216(kind: String, item_id: String = "") -> Dictionary:
	match kind:
		"folder":
			return {
				"kind": "folder",
				"label": "Folder",
				"icon": IDEA_FOLDER_ICON_V0216,
				"tooltip": "Folder — contains Ideas and child Folders. Selecting it shows direct and descendant Ideas."
			}
		_:
			return {
				"kind": "special",
				"label": "Built-in view",
				"icon": IDEA_SPECIAL_VIEW_ICON_V0216,
				"tooltip": (
					"Built-in view — Ideas not assigned to a Folder."
					if item_id == "__unfiled__"
					else "Built-in view — all saved ideas."
				)
			}


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
	_notebooks_by_parent: Dictionary, visible_folders: Dictionary,
	_visible_notebooks: Dictionary
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
		for child_value in folder_children.get(current, []):
			pending.append(str((child_value as Dictionary).get("id", "")))


func _mark_selected_tree_path_visible_v0215(
	folder_by_id: Dictionary, _notebooks: Array,
	visible_folders: Dictionary, _visible_notebooks: Dictionary
) -> void:
	if _notebook_tree_selection_kind_v0215 == "folder":
		_mark_folder_ancestors_visible_v0215(
			_notebook_tree_selection_id_v0215, folder_by_id, visible_folders
		)


func _refresh_legacy_notebook_filter_v0215(
	folders: Array[Dictionary], counts: Dictionary, query: String
) -> void:
	_notebook_filter_v01532.clear()
	_add_option_v01532(_notebook_filter_v01532, "All Ideas (%d)" % int(counts.get("__all__", 0)), "__all__")
	_add_option_v01532(_notebook_filter_v01532, "Unfiled (%d)" % int(counts.get("__unfiled__", 0)), "__unfiled__")
	for folder in folders:
		var folder_id := str(folder.get("id", ""))
		var path := NOTEBOOK_SERVICE.folder_path_from_snapshot(
			folder_id, _hierarchy_snapshot_v0215
		)
		if not query.is_empty() and not path.to_lower().contains(query):
			continue
		_add_option_v01532(
			_notebook_filter_v01532,
			"%s (%d)" % [path, int(counts.get(folder_id, 0))], folder_id
		)
	var legacy_value := _notebook_tree_selection_id_v0215
	_select_metadata_v01532(_notebook_filter_v01532, legacy_value, "__all__")


func _on_notebook_tree_selected_v0215() -> void:
	if _notebook_tree_rebuilding_v0215:
		return
	var metadata := _selected_tree_metadata_v0215()
	_notebook_tree_selection_kind_v0215 = str(metadata.get("kind", "special"))
	_notebook_tree_selection_id_v0215 = str(metadata.get("id", "__all__"))
	var legacy_value := _notebook_tree_selection_id_v0215
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
	var kind := str(_notebook_tree_context_metadata_v0215.get("kind", "special"))
	if kind == "folder":
		_notebook_tree_popup_v0215.add_separator()
		_notebook_tree_popup_v0215.add_item("Rename…", 3)
		_notebook_tree_popup_v0215.add_item("Delete Folder…", 4)
	_notebook_tree_popup_v0215.position = Vector2i(
		_notebook_tree_v0215.get_screen_position() + mouse_event.position
	)
	_notebook_tree_popup_v0215.popup()


func _on_notebook_tree_context_action_v0215(action_id: int) -> void:
	match action_id:
		1: _open_tree_name_dialog_v0215("new_folder")
		3: _open_tree_name_dialog_v0215("rename")
		4: _request_tree_delete_v0215()


func _on_notebook_tree_drop_v0215(
	kind: String, item_id: String, destination_folder_id: String
) -> void:
	if kind != "folder":
		return
	var result := NOTEBOOK_SERVICE.move_folder(item_id, destination_folder_id)
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


func _on_idea_tree_drop_v0217(
	idea_ids: Array[String], destination_folder_id: String
) -> void:
	if idea_ids.is_empty():
		return
	var result := NOTEBOOK_SERVICE.move_ideas_to_folder(
		idea_ids, destination_folder_id
	)
	var failed := int(result.get("failed", 0))
	var moved := int(result.get("moved", 0))
	# The service updates the batch first; rebuild counts/list/tree exactly once.
	_refresh_notebook_v01532()
	if failed > 0:
		_status_v01532.text = "Moved %d Idea%s. %d could not be moved. %s" % [
			moved, "" if moved == 1 else "s", failed,
			str(result.get("error", ""))
		]
		return
	var destination_path := NOTEBOOK_SERVICE.folder_path(destination_folder_id)
	_status_v01532.text = "Moved %d Idea%s to %s." % [
		moved,
		"" if moved == 1 else "s",
		"Unfiled" if destination_folder_id.is_empty() else destination_path
	]


func _refresh_ideas_v01532(snapshot: Dictionary = {}) -> void:
	if _idea_list_v01532 == null:
		return
	if snapshot.is_empty():
		snapshot = NOTEBOOK_SERVICE.hierarchy_snapshot()
	_hierarchy_snapshot_v0215 = snapshot
	var selected_ids_before := _live_notebook_selected_ids_v0214()
	var selected_folder := _notebook_tree_selection_id_v0215
	var selected_kind := _notebook_tree_selection_kind_v0215
	var filters := {
		"folder_id": selected_folder,
		"tag": _selected_metadata_v01532(_tag_filter_v01532, ""),
		"search": _search_v01532.text if _search_v01532 != null else "",
		"include_archived": (
			_show_archived_v01532 != null
			and _show_archived_v01532.button_pressed
		)
	}
	if selected_kind == "folder":
		filters["folder_id"] = "__all__"
		filters["folder_ids"] = NOTEBOOK_SERVICE.folder_ids_in_folder_from_snapshot(
			selected_folder, snapshot, true
		)
	var rows := NOTEBOOK_SERVICE.list_ideas(filters)
	var folder_names := {"": "Unfiled"}
	var folder_paths: Dictionary = snapshot.get("folder_paths", {})
	for folder in snapshot.get("folders", []):
		var folder_id := str(folder.get("id", ""))
		folder_names[folder_id] = str(
			folder_paths.get(folder_id, folder.get("name", "Folder"))
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
		if sort_mode == "folder_title":
			var first_folder := str(folder_names.get(
				str(first.get("folder_id", "")), "Unfiled"
			)).to_lower()
			var second_folder := str(folder_names.get(
				str(second.get("folder_id", "")), "Unfiled"
			)).to_lower()
			if first_folder != second_folder:
				return first_folder < second_folder
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
		if selected_kind == "special" and selected_folder == "__all__":
			subtitle_parts.append(str(folder_names.get(
				str(idea.get("folder_id", "")), "Unfiled"
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
		_idea_list_v01532.set_item_metadata(
			_idea_list_v01532.item_count - 1, idea_id
		)
		_visible_idea_ids_v01532.append(idea_id)
		if idea_id == _selected_idea_id_v01532:
			reselect_index = _visible_idea_ids_v01532.size() - 1
	if _idea_result_summary_v0211 != null:
		_idea_result_summary_v0211.text = _scope_summary_v0216(
			rows.size(), folder_names
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
			"No saved Ideas match the current Folder, tag and search filters."
		)
	_update_delete_idea_action_v0216()


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
	_update_delete_idea_action_v0216()


func _on_idea_selected_v01532(index: int) -> void:
	super._on_idea_selected_v01532(index)
	_update_delete_idea_action_v0216()


func _set_editor_enabled_v01532(enabled: bool) -> void:
	super._set_editor_enabled_v01532(enabled)
	_update_delete_idea_action_v0216()


func _update_delete_idea_action_v0216() -> void:
	if _delete_idea_button_v01532 == null:
		return
	var selected_count := _live_notebook_selected_ids_v0214().size()
	_delete_idea_button_v01532.disabled = selected_count == 0
	if selected_count == 0:
		_delete_idea_button_v01532.text = "Delete Selected…"
	elif selected_count == 1:
		_delete_idea_button_v01532.text = "Delete Idea…"
	else:
		_delete_idea_button_v01532.text = "Delete %d Ideas…" % selected_count


func _request_delete_idea_v01532() -> void:
	var selected_ids := _live_notebook_selected_ids_v0214()
	if selected_ids.is_empty():
		_status_v01532.text = "Select one or more saved ideas to delete."
		_update_delete_idea_action_v0216()
		return
	_pending_delete_idea_ids_v0216 = selected_ids.duplicate()
	var count := _pending_delete_idea_ids_v0216.size()
	_delete_idea_dialog_v01532.title = (
		"Delete Saved Idea" if count == 1 else "Delete Saved Ideas"
	)
	_delete_idea_dialog_v01532.ok_button_text = (
		"Delete Idea" if count == 1 else "Delete %d Ideas" % count
	)
	var preview := _selected_idea_delete_preview_v0216(
		_pending_delete_idea_ids_v0216
	)
	_delete_idea_dialog_v01532.dialog_text = (
		"You are about to permanently delete %d saved idea%s.\n\n"
		+ "This does not affect Character Projects or characters already created from %s.%s"
	) % [
		count,
		"" if count == 1 else "s",
		"this idea" if count == 1 else "these ideas",
		preview
	]
	_delete_idea_dialog_v01532.popup_centered()


func _selected_idea_delete_preview_v0216(idea_ids: Array[String]) -> String:
	if _idea_list_v01532 == null or idea_ids.size() > 20:
		return ""
	var lines: Array[String] = []
	var preview_limit := mini(5, idea_ids.size())
	for index_value in _idea_list_v01532.get_selected_items():
		var index := int(index_value)
		if index < 0 or index >= _visible_idea_ids_v01532.size():
			continue
		if not _visible_idea_ids_v01532[index] in idea_ids:
			continue
		var item_text := _idea_list_v01532.get_item_text(index)
		lines.append("• %s" % item_text.get_slice("\n", 0))
		if lines.size() >= preview_limit:
			break
	if lines.is_empty():
		return ""
	if idea_ids.size() > lines.size():
		lines.append("• …")
	return "\n\nSelected:\n%s" % "\n".join(lines)


func _cancel_delete_ideas_v0216() -> void:
	_pending_delete_idea_ids_v0216.clear()


func _delete_selected_idea_v01532() -> void:
	if _pending_delete_idea_ids_v0216.is_empty():
		return
	var selected_ids := _pending_delete_idea_ids_v0216.duplicate()
	_pending_delete_idea_ids_v0216.clear()
	var first_selected_index := _visible_idea_ids_v01532.size()
	for idea_id in selected_ids:
		var visible_index := _visible_idea_ids_v01532.find(idea_id)
		if visible_index >= 0:
			first_selected_index = mini(first_selected_index, visible_index)
	var deleted_ids := {}
	var failures: Array[String] = []
	for idea_id in selected_ids:
		var result := NOTEBOOK_SERVICE.delete_idea(idea_id)
		if bool(result.get("ok", false)):
			deleted_ids[idea_id] = true
		else:
			failures.append("%s: %s" % [
				idea_id, str(result.get("error", "Could not delete saved idea."))
			])
	var next_focus := _selected_idea_id_v01532
	if deleted_ids.has(next_focus):
		next_focus = _surviving_idea_near_v0216(first_selected_index, deleted_ids)
	_selected_idea_id_v01532 = next_focus
	_idea_delete_batch_refresh_count_v0216 += 1
	_refresh_notebook_v01532()
	if not next_focus.is_empty():
		var next_index := _visible_idea_ids_v01532.find(next_focus)
		if next_index >= 0:
			_idea_list_v01532.select(next_index, false)
	_update_delete_idea_action_v0216()
	var deleted_count := deleted_ids.size()
	if failures.is_empty():
		_status_v01532.text = "Deleted %d saved idea%s." % [
			deleted_count, "" if deleted_count == 1 else "s"
		]
	else:
		var failure_summary := "; ".join(failures.slice(0, 3))
		_status_v01532.text = (
			"Deleted %d saved idea%s. %d could not be deleted. %s"
			% [
				deleted_count,
				"" if deleted_count == 1 else "s",
				failures.size(),
				failure_summary
			]
		)


func _surviving_idea_near_v0216(start_index: int, deleted_ids: Dictionary) -> String:
	if _visible_idea_ids_v01532.is_empty():
		return ""
	var safe_start := clampi(start_index, 0, _visible_idea_ids_v01532.size() - 1)
	for index in range(safe_start, _visible_idea_ids_v01532.size()):
		var idea_id := _visible_idea_ids_v01532[index]
		if not deleted_ids.has(idea_id):
			return idea_id
	for index in range(safe_start - 1, -1, -1):
		var idea_id := _visible_idea_ids_v01532[index]
		if not deleted_ids.has(idea_id):
			return idea_id
	return ""


func _on_idea_list_gui_input_v0216(event: InputEvent) -> void:
	if not event is InputEventKey or _idea_list_v01532 == null:
		return
	var key_event := event as InputEventKey
	if (
		not key_event.pressed
		or key_event.echo
		or key_event.keycode != KEY_DELETE
		or not _idea_list_v01532.has_focus()
	):
		return
	if _live_notebook_selected_ids_v0214().is_empty():
		return
	_request_delete_idea_v01532()
	_idea_list_v01532.accept_event()


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
	folder_id: String, folder_names: Dictionary
) -> String:
	if folder_id == "__all__":
		return "All Ideas"
	if folder_id == "__unfiled__":
		return "Unfiled"
	return str(folder_names.get(folder_id, "the selected Folder"))


func _selected_tree_scope_name_v0215(folder_names: Dictionary) -> String:
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
		_notebook_tree_selection_id_v0215, folder_names
	)


func _scope_summary_v0216(idea_count: int, _folder_names: Dictionary) -> String:
	var idea_text := "%d idea%s" % [idea_count, "" if idea_count == 1 else "s"]
	if _notebook_tree_selection_kind_v0215 == "folder":
		var snapshot := _current_hierarchy_snapshot_v0216()
		var folder_path := NOTEBOOK_SERVICE.folder_path_from_snapshot(
			_notebook_tree_selection_id_v0215, snapshot
		)
		var folder_count := NOTEBOOK_SERVICE.folder_ids_in_folder_from_snapshot(
			_notebook_tree_selection_id_v0215, snapshot, true
		).size() - 1
		return "Folder: %s\n%s across this Folder and %d subfolder%s" % [
			folder_path if not folder_path.is_empty() else "Root",
			idea_text,
			folder_count,
			"" if folder_count == 1 else "s"
		]
	if _notebook_tree_selection_id_v0215 == "__unfiled__":
		return "Unfiled\n%s" % idea_text
	return "All Ideas\n%s" % idea_text


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
		_status_v01532.text = "The selected Idea is not a valid Idea Library record."
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
	target_label.text = "Import into Folder:"
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
	var folder_id := _selected_metadata_v01532(_import_notebook_v0210, "")
	_import_confirm_v0210.disabled = true
	var result := _idea_pack_service_v0210.import_preview(
		_import_preview_data_v0210, selections, folder_id
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


func _idea_pack_hierarchy_snapshot_v0217() -> Dictionary:
	# Export may use an injected storage root in tests or future portable-library
	# views, so derive the hierarchy from the same Idea Pack service as its Ideas.
	var folders := _idea_pack_service_v0210.list_local_folders()
	var folder_by_id := {}
	for folder in folders:
		folder_by_id[str(folder.get("id", ""))] = folder
	var folder_paths := {}
	for folder in folders:
		var folder_id := str(folder.get("id", ""))
		var names: Array[String] = []
		var cursor := folder_id
		var visited := {}
		while not cursor.is_empty() and folder_by_id.has(cursor) and not visited.has(cursor):
			visited[cursor] = true
			var row: Dictionary = folder_by_id[cursor]
			names.push_front(str(row.get("name", "Folder")))
			cursor = str(row.get("parent_folder_id", ""))
		folder_paths[folder_id] = " / ".join(names)
	return {
		"ok": true,
		"folders": folders,
		"folder_by_id": folder_by_id,
		"folder_paths": folder_paths
	}


func _build_export_window_v0210() -> void:
	for child in _export_window_v0210.get_children():
		_export_window_v0210.remove_child(child)
		child.queue_free()
	_export_rows_v0210.clear()
	_export_folder_ids_v0217.clear()
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
	heading.text = "Export semantic Idea Library material"
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
	var hierarchy := _idea_pack_hierarchy_snapshot_v0217()
	var folder_paths: Dictionary = hierarchy.get("folder_paths", {})
	for folder in hierarchy.get("folders", []):
		var folder_id := str(folder.get("id", ""))
		_export_folder_ids_v0217[folder_id] = NOTEBOOK_SERVICE.folder_ids_in_folder_from_snapshot(
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
		var folder_ids_value: Variant = _export_folder_ids_v0217.get(value, [])
		var folder_ids: Array = folder_ids_value if folder_ids_value is Array else []
		return str(idea.get("folder_id", "")) in folder_ids
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
		"source": "Character Card Forge v0.21.7"
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
			"Idea Sources are reusable inputs that create many Ideas. They are separate from generated Ideas in the Idea Library and from Workspace Generation Concepts."
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
	use_button.tooltip_text = "Activate this reusable source without creating an Idea Library entry."

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
	_build_direction_preset_editor_v02111(editor)
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
	_build_active_source_preset_controls_v02111(content)
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
	_source_status_v0213.text = "Loaded external source temporarily from %s. It has not been saved to the Idea Source Library or Idea Library." % path


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
	_source_status_v0213.text = "Saved to the Idea Source Library. No saved Idea entry was created."


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
	_active_source_preset_id_v02111 = ""
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
	_active_source_preset_id_v02111 = ""
	_refresh_active_source_banner_v0213()
	active_idea_source_changed_v0213.emit({})


func active_idea_source_v0213() -> Dictionary:
	return _active_idea_source_v0213.duplicate(true)


func active_idea_source_context_v0213() -> String:
	if _active_idea_source_v0213.is_empty():
		return ""
	return _idea_source_service_v0213.generation_context(_active_idea_source_v0213)


func prepared_generation_input_v0213(additional_direction: String) -> String:
	return IDEA_SOURCE_SERVICE_V0213.compose_generation_input(
		active_idea_source_context_v0213(), additional_direction
	)


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
	_source_direction_presets_v02111 = _idea_source_service_v0213.direction_presets(source)
	_rebuild_source_preset_list_v02111(0 if not _source_direction_presets_v02111.is_empty() else -1)
	var sections_value: Variant = source.get("sections", [])
	_source_sections_v0213.text = JSON.stringify(sections_value, "  ") if sections_value is Array and not (sections_value as Array).is_empty() else ""
	_source_raw_prompt_v0213.text = str(source.get("raw_prompt", ""))


func _capture_source_editor_v0213() -> Dictionary:
	_commit_source_preset_fields_v02111()
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
	source["direction_presets"] = _source_direction_presets_v02111.duplicate(true)
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
		_refresh_active_source_preset_controls_v02111()
		return
	var source_title := str(_active_idea_source_v0213.get("title", "")).strip_edges()
	if source_title.is_empty():
		source_title = "Untitled reusable source"
	_active_source_banner_v0213.text = "Active Idea Source: %s" % source_title
	_active_source_explanation_v0213.text = "This structured source will be included in every Idea generation request until cleared or replaced. The prompt below is optional Additional Direction for this batch."
	_active_source_actions_v0213.show()
	_refresh_active_source_preset_controls_v02111()


func idea_source_capabilities_v0213() -> Dictionary:
	var capabilities := _idea_source_service_v0213.capabilities()
	capabilities["source_library_ui"] = _source_tab_v0213 != null
	capabilities["idea_pack_actions_preserved"] = (
		_import_dialog_v0210 != null and _export_dialog_v0210 != null
	)
	capabilities["active_source_id"] = str(_active_idea_source_v0213.get("id", ""))
	capabilities["active_source_context"] = active_idea_source_context_v0213()
	capabilities["direction_preset_editor"] = _source_preset_list_v02111 != null
	capabilities["direction_preset_selector"] = _active_source_preset_choice_v02111 != null
	return capabilities


func _build_direction_preset_editor_v02111(parent: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "Reusable Additional Direction Presets"
	heading.add_theme_font_size_override("font_size", 17)
	parent.add_child(heading)
	var hint := Label.new()
	hint.text = "Optional grouped shortcuts. Selecting one later copies its exact text into Additional Direction; it is never injected into every generation."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.68, 0.72, 0.84)
	parent.add_child(hint)
	var split := HSplitContainer.new()
	split.custom_minimum_size.y = 310
	split.split_offset = 310
	parent.add_child(split)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 260
	split.add_child(left)
	_source_preset_list_v02111 = ItemList.new()
	_source_preset_list_v02111.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_source_preset_list_v02111.allow_reselect = true
	_source_preset_list_v02111.item_selected.connect(_select_source_preset_v02111)
	left.add_child(_source_preset_list_v02111)
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("separation", 6)
	left.add_child(actions)
	_add_source_button_v0213(actions, "Add", _add_source_preset_v02111)
	_add_source_button_v0213(actions, "Duplicate", _duplicate_source_preset_v02111)
	_add_source_button_v0213(actions, "Delete", _delete_source_preset_v02111)
	_add_source_button_v0213(actions, "Move Up", _move_source_preset_v02111.bind(-1))
	_add_source_button_v0213(actions, "Move Down", _move_source_preset_v02111.bind(1))
	var fields := VBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(fields)
	_source_preset_group_v02111 = LineEdit.new()
	_source_preset_group_v02111.placeholder_text = "Optional category, for example Setting"
	_source_preset_group_v02111.text_changed.connect(_source_preset_field_changed_v02111)
	fields.add_child(_labelled_control_v01532("Group", _source_preset_group_v02111))
	_source_preset_title_v02111 = LineEdit.new()
	_source_preset_title_v02111.placeholder_text = "Required selector title"
	_source_preset_title_v02111.text_changed.connect(_source_preset_field_changed_v02111)
	fields.add_child(_labelled_control_v01532("Title", _source_preset_title_v02111))
	_source_preset_direction_v02111 = _source_text_edit_v0213(155)
	_source_preset_direction_v02111.placeholder_text = "Required reusable Additional Direction text"
	_source_preset_direction_v02111.text_changed.connect(_source_preset_field_changed_v02111)
	fields.add_child(_labelled_control_v01532("Direction", _source_preset_direction_v02111))
	_set_source_preset_fields_enabled_v02111(false)


func _preset_list_label_v02111(preset: Dictionary) -> String:
	var title := str(preset.get("title", "")).strip_edges()
	if title.is_empty():
		title = "Untitled direction"
	var group := str(preset.get("group", "")).strip_edges()
	return "%s  ·  %s" % [group, title] if not group.is_empty() else title


func _rebuild_source_preset_list_v02111(selected_index: int = -1) -> void:
	if _source_preset_list_v02111 == null:
		return
	_source_preset_updating_v02111 = true
	# The array may already have been deleted, moved or replaced. Invalidate the
	# previous row before selecting from the new layout so _select_source_preset
	# cannot commit stale editor fields into whichever preset inherited its index.
	_source_preset_selected_v02111 = -1
	_source_preset_list_v02111.clear()
	for preset in _source_direction_presets_v02111:
		_source_preset_list_v02111.add_item(_preset_list_label_v02111(preset))
	_source_preset_updating_v02111 = false
	if selected_index >= 0 and selected_index < _source_direction_presets_v02111.size():
		_source_preset_list_v02111.select(selected_index)
		_select_source_preset_v02111(selected_index)
	else:
		_source_preset_selected_v02111 = -1
		_set_source_preset_fields_enabled_v02111(false)


func _select_source_preset_v02111(index: int) -> void:
	if index < 0 or index >= _source_direction_presets_v02111.size():
		return
	_commit_source_preset_fields_v02111()
	_source_preset_selected_v02111 = index
	var preset := _source_direction_presets_v02111[index]
	_source_preset_updating_v02111 = true
	_source_preset_group_v02111.text = str(preset.get("group", ""))
	_source_preset_title_v02111.text = str(preset.get("title", ""))
	_source_preset_direction_v02111.text = str(preset.get("direction", ""))
	_source_preset_updating_v02111 = false
	_set_source_preset_fields_enabled_v02111(true)


func _set_source_preset_fields_enabled_v02111(enabled: bool) -> void:
	if _source_preset_group_v02111 != null:
		_source_preset_group_v02111.editable = enabled
		_source_preset_title_v02111.editable = enabled
		_source_preset_direction_v02111.editable = enabled


func _commit_source_preset_fields_v02111() -> void:
	var index := _source_preset_selected_v02111
	if _source_preset_updating_v02111 or index < 0 or index >= _source_direction_presets_v02111.size():
		return
	var preset := _source_direction_presets_v02111[index].duplicate(true)
	preset["group"] = _source_preset_group_v02111.text.strip_edges()
	preset["title"] = _source_preset_title_v02111.text.strip_edges()
	preset["direction"] = _source_preset_direction_v02111.text.strip_edges()
	_source_direction_presets_v02111[index] = preset
	if _source_preset_list_v02111 != null and index < _source_preset_list_v02111.item_count:
		_source_preset_list_v02111.set_item_text(index, _preset_list_label_v02111(preset))


func _source_preset_field_changed_v02111(_value: String = "") -> void:
	_commit_source_preset_fields_v02111()


func _add_source_preset_v02111() -> void:
	_commit_source_preset_fields_v02111()
	var source := _source_editor_base_v0213.duplicate(true)
	source["direction_presets"] = _source_direction_presets_v02111
	_source_direction_presets_v02111.append({
		"id": _idea_source_service_v0213.unique_direction_preset_id(source),
		"group": "", "title": "New Direction", "direction": ""
	})
	_rebuild_source_preset_list_v02111(_source_direction_presets_v02111.size() - 1)
	_source_preset_title_v02111.grab_focus()
	_source_preset_title_v02111.select_all()


func _duplicate_source_preset_v02111() -> void:
	_commit_source_preset_fields_v02111()
	var index := _source_preset_selected_v02111
	if index < 0 or index >= _source_direction_presets_v02111.size():
		return
	var source := _source_editor_base_v0213.duplicate(true)
	source["direction_presets"] = _source_direction_presets_v02111
	var preset := _source_direction_presets_v02111[index].duplicate(true)
	preset["id"] = _idea_source_service_v0213.unique_direction_preset_id(
		source, str(preset.get("id", "direction"))
	)
	preset["title"] = "%s Copy" % str(preset.get("title", "Direction"))
	_source_direction_presets_v02111.insert(index + 1, preset)
	_rebuild_source_preset_list_v02111(index + 1)


func _delete_source_preset_v02111() -> void:
	var index := _source_preset_selected_v02111
	if index < 0 or index >= _source_direction_presets_v02111.size():
		return
	_source_direction_presets_v02111.remove_at(index)
	_rebuild_source_preset_list_v02111(mini(index, _source_direction_presets_v02111.size() - 1))


func _move_source_preset_v02111(offset: int) -> void:
	_commit_source_preset_fields_v02111()
	var index := _source_preset_selected_v02111
	var target := index + offset
	if index < 0 or target < 0 or target >= _source_direction_presets_v02111.size():
		return
	var preset := _source_direction_presets_v02111[index]
	_source_direction_presets_v02111.remove_at(index)
	_source_direction_presets_v02111.insert(target, preset)
	_rebuild_source_preset_list_v02111(target)


func _build_active_source_preset_controls_v02111(parent: VBoxContainer) -> void:
	_active_source_preset_controls_v02111 = VBoxContainer.new()
	_active_source_preset_controls_v02111.name = "DirectionPresetControlsV02111"
	var row := HFlowContainer.new()
	row.add_theme_constant_override("separation", 8)
	_active_source_preset_controls_v02111.add_child(row)
	var group_label := Label.new()
	group_label.text = "Preset group"
	row.add_child(group_label)
	_active_source_preset_group_v02111 = OptionButton.new()
	_active_source_preset_group_v02111.custom_minimum_size.x = 190
	_active_source_preset_group_v02111.item_selected.connect(_active_preset_group_selected_v02111)
	row.add_child(_active_source_preset_group_v02111)
	var preset_label := Label.new()
	preset_label.text = "Direction"
	row.add_child(preset_label)
	_active_source_preset_choice_v02111 = OptionButton.new()
	_active_source_preset_choice_v02111.custom_minimum_size.x = 260
	_active_source_preset_choice_v02111.item_selected.connect(_active_preset_selected_v02111)
	row.add_child(_active_source_preset_choice_v02111)
	var hint := Label.new()
	hint.text = "Choosing a preset copies its text into Additional Direction. Edit the copied text freely; the saved preset is unchanged."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.68, 0.72, 0.84)
	_active_source_preset_controls_v02111.add_child(hint)
	parent.add_child(_active_source_preset_controls_v02111)
	_active_source_preset_controls_v02111.hide()


func _refresh_active_source_preset_controls_v02111() -> void:
	if _active_source_preset_controls_v02111 == null:
		return
	var presets := _idea_source_service_v0213.direction_presets(_active_idea_source_v0213)
	if _active_idea_source_v0213.is_empty() or presets.is_empty():
		_active_source_preset_controls_v02111.hide()
		return
	_active_source_preset_controls_v02111.show()
	_active_source_preset_updating_v02111 = true
	_active_source_preset_group_v02111.clear()
	_active_source_preset_group_v02111.add_item("All groups")
	_active_source_preset_group_v02111.set_item_metadata(0, "__all__")
	var groups: Array[String] = []
	var has_ungrouped := false
	for preset in presets:
		var group := str(preset.get("group", "")).strip_edges()
		if group.is_empty():
			has_ungrouped = true
		elif group not in groups:
			groups.append(group)
	if has_ungrouped:
		_active_source_preset_group_v02111.add_item("Ungrouped / General")
		_active_source_preset_group_v02111.set_item_metadata(
			_active_source_preset_group_v02111.item_count - 1, ""
		)
	for group in groups:
		_active_source_preset_group_v02111.add_item(group)
		_active_source_preset_group_v02111.set_item_metadata(
			_active_source_preset_group_v02111.item_count - 1, group
		)
	_active_source_preset_group_v02111.select(0)
	_rebuild_active_preset_choices_v02111("__all__")
	_active_source_preset_updating_v02111 = false


func _rebuild_active_preset_choices_v02111(group: String) -> void:
	_active_source_preset_choice_v02111.clear()
	_active_source_preset_choice_v02111.add_item("None / Custom")
	_active_source_preset_choice_v02111.set_item_metadata(0, "")
	for preset in _idea_source_service_v0213.direction_presets(_active_idea_source_v0213):
		if group != "__all__" and str(preset.get("group", "")).strip_edges() != group:
			continue
		_active_source_preset_choice_v02111.add_item(str(preset.get("title", "Untitled")))
		_active_source_preset_choice_v02111.set_item_metadata(
			_active_source_preset_choice_v02111.item_count - 1,
			str(preset.get("id", ""))
		)
	_active_source_preset_choice_v02111.select(0)


func _active_preset_group_selected_v02111(index: int) -> void:
	if _active_source_preset_updating_v02111:
		return
	var group := str(_active_source_preset_group_v02111.get_item_metadata(index))
	_active_source_preset_updating_v02111 = true
	_rebuild_active_preset_choices_v02111(group)
	_active_source_preset_updating_v02111 = false
	_active_source_preset_id_v02111 = ""


func _active_preset_selected_v02111(index: int) -> void:
	if _active_source_preset_updating_v02111:
		return
	var preset_id := str(_active_source_preset_choice_v02111.get_item_metadata(index))
	_active_source_preset_id_v02111 = preset_id
	if preset_id.is_empty():
		direction_preset_selected_v02111.emit(
			{}, str(_active_idea_source_v0213.get("id", ""))
		)
		return
	for preset in _idea_source_service_v0213.direction_presets(_active_idea_source_v0213):
		if str(preset.get("id", "")) == preset_id:
			direction_preset_selected_v02111.emit(
				preset.duplicate(true), str(_active_idea_source_v0213.get("id", ""))
			)
			return


func mark_direction_preset_custom_v02111() -> void:
	_active_source_preset_id_v02111 = ""
	if _active_source_preset_choice_v02111 == null:
		return
	_active_source_preset_updating_v02111 = true
	_active_source_preset_choice_v02111.select(0)
	_active_source_preset_updating_v02111 = false
