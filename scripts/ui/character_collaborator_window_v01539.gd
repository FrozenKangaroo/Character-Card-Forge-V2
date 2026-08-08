class_name CCFCharacterCollaboratorWindowV01539
extends "res://scripts/ui/character_collaborator_window_v01537_sources.gd"

const CARD_VISION_SERVICE_V01539 = preload(
	"res://scripts/services/collaborator_card_vision_service_v01539.gd"
)

var _card_ingestion_dialog_v01539: ConfirmationDialog
var _card_ingestion_mode_v01539: OptionButton
var _card_ingestion_hint_v01539: Label
var _pending_card_ingestions_v01539: Array[Dictionary] = []
var _pending_vision_source_ids_v01539: Dictionary = {}


func _ready() -> void:
	super._ready()
	_build_card_ingestion_dialog_v01539()
	_enable_apng_attachment_filter_v01539()


func collaborator_source_capabilities_v01533() -> Dictionary:
	var result := super.collaborator_source_capabilities_v01533()
	result.merge(CARD_VISION_SERVICE_V01539.capabilities(), true)
	return result


func card_png_dual_ingestion_capabilities_v01539() -> Dictionary:
	return CARD_VISION_SERVICE_V01539.capabilities()


func _build_card_ingestion_dialog_v01539() -> void:
	_card_ingestion_dialog_v01539 = ConfirmationDialog.new()
	_card_ingestion_dialog_v01539.visible = false
	_card_ingestion_dialog_v01539.title = "Character Card PNG Detected"
	_card_ingestion_dialog_v01539.min_size = Vector2i(720, 330)
	_card_ingestion_dialog_v01539.ok_button_text = "Add"
	_card_ingestion_dialog_v01539.confirmed.connect(_confirm_card_ingestion_v01539)
	_card_ingestion_dialog_v01539.canceled.connect(_cancel_card_ingestion_v01539)
	add_child(_card_ingestion_dialog_v01539)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	_card_ingestion_dialog_v01539.add_child(root)

	_card_ingestion_hint_v01539 = Label.new()
	_card_ingestion_hint_v01539.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_card_ingestion_hint_v01539)

	_card_ingestion_mode_v01539 = OptionButton.new()
	_card_ingestion_mode_v01539.add_item("Card data + Vision (recommended)")
	_card_ingestion_mode_v01539.set_item_metadata(0, CARD_VISION_SERVICE_V01539.MODE_CARD_AND_VISION)
	_card_ingestion_mode_v01539.add_item("Card data only")
	_card_ingestion_mode_v01539.set_item_metadata(1, CARD_VISION_SERVICE_V01539.MODE_CARD_ONLY)
	_card_ingestion_mode_v01539.add_item("Vision only")
	_card_ingestion_mode_v01539.set_item_metadata(2, CARD_VISION_SERVICE_V01539.MODE_VISION_ONLY)
	_card_ingestion_mode_v01539.select(0)
	root.add_child(_card_ingestion_mode_v01539)

	var note := Label.new()
	note.text = "Card data and Vision remain separate evidence. Vision analysis never overwrites embedded Character Card metadata. Separate UserPersona/user-profile residue is still excluded from the AI-facing card source."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(note)
	_card_ingestion_dialog_v01539.hide()


func _enable_apng_attachment_filter_v01539() -> void:
	if _attachment_dialog_v01521 == null:
		return
	_attachment_dialog_v01521.filters = PackedStringArray([
		"*.txt, *.md, *.markdown, *.srt, *.ass, *.ssa, *.json ; Text, Markdown, subtitle and JSON references",
		"*.png, *.apng, *.jpg, *.jpeg, *.webp ; Reference images and Character Card images",
		"*.txt, *.md, *.markdown, *.srt, *.ass, *.ssa, *.json, *.png, *.apng, *.jpg, *.jpeg, *.webp ; All supported Collaborator attachments"
	])


func _on_attachment_files_selected_v01521(paths: PackedStringArray) -> void:
	var remaining := PackedStringArray()
	var structured_json_added := 0
	var detected_card_images := 0
	for path in paths:
		var extension := path.get_extension().to_lower()
		if extension == "json":
			var loaded_json := SOURCE_SERVICE_V01537.from_card_file(path)
			if bool(loaded_json.get("ok", false)):
				var source_value: Variant = loaded_json.get("source", {})
				if source_value is Dictionary:
					var added_json := add_source_v01537(source_value as Dictionary, false)
					if bool(added_json.get("ok", false)):
						structured_json_added += 1
						continue
		elif extension in ["png", "apng"]:
			var loaded_card := SOURCE_SERVICE_V01537.from_card_file(path)
			if bool(loaded_card.get("ok", false)):
				var card_source_value: Variant = loaded_card.get("source", {})
				if card_source_value is Dictionary:
					_pending_card_ingestions_v01539.append({
						"path": path,
						"source": (card_source_value as Dictionary).duplicate(true)
					})
					detected_card_images += 1
					continue
		remaining.append(path)

	if not remaining.is_empty():
		super._on_attachment_files_selected_v01521(remaining)
	if detected_card_images > 0:
		_show_next_card_ingestion_v01539()
	elif structured_json_added > 0:
		_status.text = "%d Character Card JSON source%s added. Embedded UserPersona residue remains excluded from AI context." % [
			structured_json_added,
			"" if structured_json_added == 1 else "s"
		]


func _show_next_card_ingestion_v01539() -> void:
	if _pending_card_ingestions_v01539.is_empty():
		return
	var candidate: Dictionary = _pending_card_ingestions_v01539[0]
	var source_value: Variant = candidate.get("source", {})
	var source: Dictionary = source_value if source_value is Dictionary else {}
	var label := str(source.get("label", str(candidate.get("path", "")).get_file()))
	_card_ingestion_hint_v01539.text = (
		"%s contains embedded Character Card metadata and a visible image. Choose how Character Collaborator should use this file."
		% label
	)
	_card_ingestion_mode_v01539.select(0)
	_card_ingestion_dialog_v01539.popup_centered(Vector2i(740, 350))


func _confirm_card_ingestion_v01539() -> void:
	if _pending_card_ingestions_v01539.is_empty():
		return
	var candidate: Dictionary = _pending_card_ingestions_v01539.pop_front()
	var selected_index := _card_ingestion_mode_v01539.selected
	var ingestion_mode := str(_card_ingestion_mode_v01539.get_item_metadata(selected_index))
	_apply_card_ingestion_v01539(candidate, ingestion_mode)
	call_deferred("_show_next_card_ingestion_v01539")


func _cancel_card_ingestion_v01539() -> void:
	if not _pending_card_ingestions_v01539.is_empty():
		_pending_card_ingestions_v01539.pop_front()
	_status.text = "Character Card image skipped."
	call_deferred("_show_next_card_ingestion_v01539")


func _apply_card_ingestion_v01539(candidate: Dictionary, ingestion_mode: String) -> Dictionary:
	var plan := CARD_VISION_SERVICE_V01539.ingestion_plan(ingestion_mode)
	var path := str(candidate.get("path", ""))
	var source_value: Variant = candidate.get("source", {})
	var source: Dictionary = source_value if source_value is Dictionary else {}
	var source_id := ""
	var metadata_added := false
	var vision_queued := false

	if bool(plan.get("use_card_metadata", false)):
		var added := add_source_v01537(source, false)
		if not bool(added.get("ok", false)):
			_status.text = str(added.get("error", "Could not add Character Card metadata."))
			return {"ok": false, "error": _status.text}
		source_id = str(source.get("source_context_id", ""))
		metadata_added = true

	if bool(plan.get("use_vision", false)):
		var vision_result := _queue_card_image_vision_v01539(path, source_id)
		if not bool(vision_result.get("ok", false)):
			if metadata_added:
				_status.text = "Character Card metadata was added, but Vision could not be queued: %s" % str(vision_result.get("error", "Vision unavailable."))
				return {"ok": true, "metadata_added": true, "vision_queued": false}
			_status.text = str(vision_result.get("error", "Vision could not be queued."))
			return vision_result
		vision_queued = true

	if metadata_added and vision_queued:
		_status.text = "Character Card metadata added and visible PNG queued for Vision. The two remain separate linked evidence."
	elif metadata_added:
		_status.text = "Character Card metadata added without Vision analysis."
	elif vision_queued:
		_status.text = "Character Card PNG queued for Vision only; embedded metadata was not added to Collaborator sources."
	_refresh_all()
	return {
		"ok": true,
		"metadata_added": metadata_added,
		"vision_queued": vision_queued,
		"source_context_id": source_id,
		"mode": str(plan.get("mode", ingestion_mode))
	}


func _queue_card_image_vision_v01539(path: String, source_context_id: String = "") -> Dictionary:
	if path.strip_edges().is_empty():
		return {"ok": false, "error": "The Character Card image path is unavailable."}
	if _generation_service == null or not _generation_service.has_method("queue_collaborator_vision_summary"):
		return {"ok": false, "error": "The active generation service has no Vision attachment pipeline."}
	var clean_source_id := source_context_id.strip_edges()
	if not clean_source_id.is_empty():
		_pending_vision_source_ids_v01539[path] = clean_source_id
	_on_image_selected(path)
	return {"ok": true}


func _refresh_multi_source_list_v01537() -> void:
	super._refresh_multi_source_list_v01537()
	if _multi_source_list_v01537 == null:
		return
	var sources := active_source_contexts_v01537()
	var session := _active_session()
	var context_items: Variant = session.get("context_items", [])
	var live_rows: Array[HBoxContainer] = []
	for child in _multi_source_list_v01537.get_children():
		if child is HBoxContainer and not child.is_queued_for_deletion():
			live_rows.append(child as HBoxContainer)
	for index in range(mini(sources.size(), live_rows.size())):
		var source: Dictionary = sources[index]
		if not CARD_VISION_SERVICE_V01539.is_visual_card_source(source):
			continue
		var row := live_rows[index]
		var linked := CARD_VISION_SERVICE_V01539.source_has_linked_vision(source, context_items)
		for child in row.get_children():
			if child is Label:
				if linked and not (child as Label).text.contains("Vision linked"):
					(child as Label).text += " • Vision linked"
				break
		var analyse := Button.new()
		analyse.text = "Re-analyse Image" if linked else "Analyse Image"
		analyse.tooltip_text = "Analyse the visible Character Card image with the configured Vision model. The result stays separate from embedded card metadata."
		analyse.pressed.connect(
			_on_analyse_card_source_v01539.bind(
				str(source.get("source_context_id", "")),
				CARD_VISION_SERVICE_V01539.source_image_path(source)
			)
		)
		row.add_child(analyse)
		if row.get_child_count() >= 2:
			row.move_child(analyse, row.get_child_count() - 2)


func _on_analyse_card_source_v01539(source_context_id: String, path: String) -> void:
	var result := _queue_card_image_vision_v01539(path, source_context_id)
	if bool(result.get("ok", false)):
		_status.text = "Character Card image queued for Vision analysis. Existing structured metadata remains unchanged."
	else:
		_status.text = str(result.get("error", "Could not queue Character Card Vision analysis."))


func _apply_vision_summary_v01511(summary: String, metadata: Dictionary) -> void:
	var image_path := str(metadata.get("image_path", ""))
	var linked_source_id := str(_pending_vision_source_ids_v01539.get(image_path, ""))
	var before_ids := _context_ids_v01521()
	super._apply_vision_summary_v01511(summary, metadata)
	if linked_source_id.is_empty():
		return
	_pending_vision_source_ids_v01539.erase(image_path)

	var session := _active_session().duplicate(true)
	var items_value: Variant = session.get("context_items", [])
	var items: Array = items_value.duplicate(true) if items_value is Array else []
	var linked_context: Dictionary = {}
	for index in range(items.size()):
		if not items[index] is Dictionary:
			continue
		var item: Dictionary = (items[index] as Dictionary).duplicate(true)
		var context_id := str(item.get("context_id", ""))
		if before_ids.has(context_id):
			continue
		if str(item.get("type", "")) != "vision_reference":
			continue
		if str(item.get("source_path", "")) != image_path:
			continue
		item = CARD_VISION_SERVICE_V01539.annotate_vision_context(item, linked_source_id)
		items[index] = item
		linked_context = item
		break
	if linked_context.is_empty():
		return

	var sources := active_source_contexts_v01537()
	for index in range(sources.size()):
		if str(sources[index].get("source_context_id", "")) != linked_source_id:
			continue
		var marked := CARD_VISION_SERVICE_V01539.mark_source_vision_analysis(
			sources[index], linked_context, metadata
		)
		if not marked.is_empty():
			sources[index] = marked
		break
	session["context_items"] = items
	_store_sources_in_session_v01537(session, sources)
	_store_active_session(session)
	_refresh_all()
	_status.text = "Vision analysis linked to the Character Card source as separate visual evidence. Embedded metadata was not overwritten."
