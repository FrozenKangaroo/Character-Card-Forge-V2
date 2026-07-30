class_name CCFAttachmentManagerV01311Window
extends CCFAttachmentManagerWindow


func _build_ui() -> void:
	super._build_ui()
	if _analysis_mode == null:
		return
	_analysis_mode.clear()
	_analysis_mode.add_item("Visual Analysis")
	_analysis_mode.set_item_metadata(0, "concept")
	_analysis_mode.add_item("Creative Concept")
	_analysis_mode.set_item_metadata(1, "creative_concept")
	_analysis_mode.select(0)
	_analysis_mode.tooltip_text = (
		"Visual Analysis proposes observable appearance information conservatively. "
		+ "Creative Concept first extracts visual anchors with the Vision role, then uses the Text role to invent a generation-ready character premise."
	)


func _analyse_selected() -> void:
	var attachment := _selected_attachment()
	if attachment.is_empty():
		return
	if _generation_service == null:
		_status.text = "Vision generation service is unavailable."
		return
	_apply_metadata()
	attachment = _selected_attachment()
	var workspace_document := CCFStorageService.character_workspace_document(
		_project, _active_character_id
	)
	workspace_document["attachment_context_character_limit"] = _context_limit()
	var selected_analysis_mode := (
		str(_analysis_mode.get_selected_metadata())
		if _analysis_mode.selected >= 0
		else "concept"
	)
	var profile := CCFSettingsService.profile_for_role(
		_settings, CCFSettingsService.ROLE_VISION
	).duplicate(true)
	if selected_analysis_mode == "creative_concept":
		profile["_creative_text_profile"] = CCFSettingsService.profile_for_role(
			_settings, CCFSettingsService.ROLE_TEXT
		).duplicate(true)
	var generation_settings = _settings.get("generation", {})
	var retries := (
		int(generation_settings.get("retry_count", 1))
		if generation_settings is Dictionary
		else 1
	)
	var result := _generation_service.queue_vision_analysis(
		workspace_document,
		_template,
		attachment,
		profile,
		selected_analysis_mode,
		retries
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not queue vision analysis."))
		return
	_job_id = str(result.get("job_id", ""))
	_analyse_button.disabled = true
	var queued_ahead := int(result.get("queued_ahead", 0))
	var action_name := (
		"Creative Concept"
		if selected_analysis_mode == "creative_concept"
		else "Visual Analysis"
	)
	_status.text = "%s queued%s." % [
		action_name,
		" behind %d job(s)" % queued_ahead if queued_ahead > 0 else ""
	]
