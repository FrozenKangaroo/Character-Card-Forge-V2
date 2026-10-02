class_name CCFPublicIdeaSourceBrowserV02113
extends Window

signal source_chosen(source: Dictionary, catalog_entry: Dictionary)

const CATALOG_V02113 = preload(
	"res://scripts/services/public_idea_source_catalog_v02113.gd"
)

var _catalog_service := CATALOG_V02113.new()
var _manifest_request: HTTPRequest
var _source_request: HTTPRequest
var _search: LineEdit
var _source_list: ItemList
var _title: Label
var _description: Label
var _metadata: Label
var _status: Label
var _use_button: Button
var _entries: Array[Dictionary] = []
var _visible_entries: Array[Dictionary] = []
var _selected_entry: Dictionary = {}
var _pending_source_entry: Dictionary = {}
var _manifest_busy := false
var _source_busy := false


func _ready() -> void:
	title = "Public Idea Sources"
	min_size = Vector2i(760, 560)
	size = Vector2i(1040, 720)
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	force_native = true
	transient = false
	exclusive = false
	unresizable = false
	close_requested.connect(_close_browser)
	_build_ui()
	_build_requests()


func open_browser() -> void:
	popup_centered_clamped(Vector2i(1040, 720), 0.92)
	if _entries.is_empty() and not _manifest_busy:
		_request_manifest()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 14)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	var heading := Label.new()
	heading.text = "Choose a Public Idea Source"
	heading.add_theme_font_size_override("font_size", 24)
	root.add_child(heading)
	var intro := Label.new()
	intro.text = "Browse the public Character Card Forge catalog. A chosen source is downloaded, verified and loaded temporarily; save it explicitly if you want it in your local library."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(intro)
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	root.add_child(toolbar)
	_search = LineEdit.new()
	_search.placeholder_text = "Search titles, descriptions and tags…"
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(_apply_filter)
	toolbar.add_child(_search)
	var refresh := Button.new()
	refresh.text = "Refresh"
	refresh.pressed.connect(_request_manifest)
	toolbar.add_child(refresh)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 370
	root.add_child(split)
	_source_list = ItemList.new()
	_source_list.custom_minimum_size.x = 300
	_source_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_source_list.item_selected.connect(_select_entry)
	split.add_child(_source_list)
	var detail_panel := PanelContainer.new()
	split.add_child(detail_panel)
	var detail_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		detail_margin.add_theme_constant_override(side, 14)
	detail_panel.add_child(detail_margin)
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 10)
	detail_margin.add_child(detail)
	_title = Label.new()
	_title.text = "Select a source"
	_title.add_theme_font_size_override("font_size", 21)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_title)
	_description = Label.new()
	_description.text = "Choose an entry on the left to see its details."
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(_description)
	_metadata = Label.new()
	_metadata.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_metadata.modulate = Color(0.70, 0.74, 0.86)
	detail.add_child(_metadata)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.78, 0.81, 0.91)
	root.add_child(_status)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_close_browser)
	actions.add_child(close_button)
	_use_button = Button.new()
	_use_button.text = "Use Selected Source"
	_use_button.disabled = true
	_use_button.pressed.connect(_request_selected_source)
	actions.add_child(_use_button)


func _build_requests() -> void:
	_manifest_request = HTTPRequest.new()
	_manifest_request.timeout = 30.0
	_manifest_request.body_size_limit = CATALOG_V02113.MAX_MANIFEST_BYTES
	_manifest_request.request_completed.connect(_manifest_completed)
	add_child(_manifest_request)
	_source_request = HTTPRequest.new()
	_source_request.timeout = 30.0
	_source_request.body_size_limit = CATALOG_V02113.MAX_SOURCE_BYTES
	_source_request.request_completed.connect(_source_completed)
	add_child(_source_request)


func _request_manifest() -> void:
	if _manifest_busy:
		return
	_manifest_busy = true
	_status.text = "Loading the public catalog…"
	_use_button.disabled = true
	var request_error := _manifest_request.request(
		CATALOG_V02113.DEFAULT_MANIFEST_URL,
		PackedStringArray(["Accept: application/json", "Cache-Control: no-cache"])
	)
	if request_error != OK:
		_manifest_busy = false
		_status.text = "Could not start the public catalog request (error %d)." % request_error


func _manifest_completed(
	result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	_manifest_busy = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_status.text = "Could not load the public catalog (network result %d, HTTP %d)." % [result, response_code]
		return
	var parsed := _catalog_service.parse_manifest_text(body.get_string_from_utf8())
	if not bool(parsed.get("ok", false)):
		_status.text = str(parsed.get("error", "The public catalog could not be read."))
		return
	var catalog: Dictionary = parsed.get("catalog", {})
	_entries.clear()
	for value in catalog.get("sources", []):
		if value is Dictionary:
			_entries.append((value as Dictionary).duplicate(true))
	_status.text = "Loaded %d public Idea Sources. Internet access is used only while browsing or choosing a public source." % _entries.size()
	_apply_filter(_search.text)


func _apply_filter(query: String) -> void:
	_visible_entries = _catalog_service.filter_entries(_entries, query)
	_source_list.clear()
	_selected_entry.clear()
	_use_button.disabled = true
	for entry in _visible_entries:
		var label := str(entry.get("title", "Untitled Idea Source"))
		var version := str(entry.get("source_version", ""))
		if not version.is_empty():
			label += "  ·  v%s" % version
		_source_list.add_item(label)
	_title.text = "Select a source"
	_description.text = "Choose an entry on the left to see its details."
	_metadata.text = ""
	if _visible_entries.size() == 1:
		_source_list.select(0)
		_select_entry(0)


func _select_entry(index: int) -> void:
	if index < 0 or index >= _visible_entries.size():
		return
	_selected_entry = _visible_entries[index].duplicate(true)
	_title.text = str(_selected_entry.get("title", "Untitled Idea Source"))
	_description.text = str(_selected_entry.get("description", "No description provided."))
	var details: Array[String] = []
	var source_version := str(_selected_entry.get("source_version", ""))
	if not source_version.is_empty():
		details.append("Source version: %s" % source_version)
	var content_rating := str(_selected_entry.get("content_rating", ""))
	if not content_rating.is_empty():
		details.append("Content: %s" % content_rating.capitalize())
	var tags: Array = _selected_entry.get("tags", [])
	if not tags.is_empty():
		details.append("Tags: %s" % ", ".join(tags))
	_metadata.text = "\n".join(details)
	_use_button.disabled = false


func _request_selected_source() -> void:
	if _selected_entry.is_empty() or _source_busy:
		return
	var url := _catalog_service.source_url(_selected_entry)
	if url.is_empty():
		_status.text = "The selected catalog entry has an unsafe source path."
		return
	_status.text = "Downloading and verifying %s…" % str(_selected_entry.get("title", "the selected source"))
	_use_button.disabled = true
	_pending_source_entry = _selected_entry.duplicate(true)
	_source_busy = true
	var request_error := _source_request.request(
		url, PackedStringArray(["Accept: application/json"])
	)
	if request_error != OK:
		_source_busy = false
		_pending_source_entry.clear()
		_status.text = "Could not start the Idea Source download (error %d)." % request_error
		_use_button.disabled = false


func _source_completed(
	result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	_source_busy = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_status.text = "Could not download the selected source (network result %d, HTTP %d)." % [result, response_code]
		_pending_source_entry.clear()
		_use_button.disabled = false
		return
	var validated := _catalog_service.validate_source_body(_pending_source_entry, body)
	if not bool(validated.get("ok", false)):
		_status.text = str(validated.get("error", "The public Idea Source could not be verified."))
		_pending_source_entry.clear()
		_use_button.disabled = false
		return
	var chosen_entry := _pending_source_entry.duplicate(true)
	_pending_source_entry.clear()
	source_chosen.emit(
		(validated.get("source", {}) as Dictionary).duplicate(true), chosen_entry
	)
	hide()


func _close_browser() -> void:
	if _manifest_request != null and _manifest_busy:
		_manifest_request.cancel_request()
	if _source_request != null and _source_busy:
		_source_request.cancel_request()
	_manifest_busy = false
	_source_busy = false
	_pending_source_entry.clear()
	hide()
