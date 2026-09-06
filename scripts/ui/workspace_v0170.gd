class_name CCFWorkspaceV0170View
extends "res://scripts/ui/workspace_v0167.gd"

const IMAGE_SOURCE_SERVICE_V0170 = preload(
	"res://scripts/services/collaborator_source_context_service_v01537.gd"
)
const HANDOFF_SERVICE_V0170 = preload(
	"res://scripts/services/image_collaborator_handoff_service_v0170.gd"
)
const CHARACTER_COLLABORATOR_WINDOW_V0170 = preload(
	"res://scripts/ui/character_collaborator_window_v0170.gd"
)


func _build_character_collaborator_window_v015() -> void:
	_character_collaborator_window = CHARACTER_COLLABORATOR_WINDOW_V0170.new()
	_character_collaborator_window.visible = false
	_character_collaborator_window.force_native = true
	_character_collaborator_window.transient = false
	_character_collaborator_window.exclusive = false
	_character_collaborator_window.set_generation_service(_generation_service)
	_character_collaborator_window.sessions_changed.connect(
		_on_collaborator_sessions_changed_v015
	)
	_character_collaborator_window.character_draft_ready.connect(
		_on_collaborator_character_draft_ready_v015
	)
	add_child(_character_collaborator_window)
	_character_collaborator_window.hide()


func open_collaborator_with_image_result_v0170(
	source: Dictionary,
	options: Dictionary = {}
) -> Dictionary:
	var clean := IMAGE_SOURCE_SERVICE_V0170.upgrade_source(source)
	if (
		clean.is_empty()
		or str(clean.get("source_type", ""))
		!= IMAGE_SOURCE_SERVICE_V0170.TYPE_IMAGE_STUDIO_RESULT
	):
		return {"ok": false, "error": "The Image Studio source is invalid."}
	if _project_container.is_empty():
		return {"ok": false, "error": "Open the image's Character Project in Workspace first."}

	var provenance_value: Variant = clean.get("provenance", {})
	var provenance: Dictionary = (
		provenance_value as Dictionary if provenance_value is Dictionary else {}
	)
	var source_project_id := str(provenance.get("project_id", "")).strip_edges()
	var workspace_project_id := str(
		_project_container.get("project_id", "")
	).strip_edges()
	if source_project_id.is_empty() or source_project_id != workspace_project_id:
		return {
			"ok": false,
			"error": "Open the same Character Project in Workspace before sending this image to Collaborator."
		}
	_commit_active_character_to_container()
	_capture_project_name()

	var handoff_mode := str(options.get(
		"mode", HANDOFF_SERVICE_V0170.MODE_EXISTING_TARGET
	))
	var opened: Dictionary = {}
	if handoff_mode == HANDOFF_SERVICE_V0170.MODE_EXISTING_TARGET:
		var source_character_id := str(
			provenance.get("character_id", "")
		).strip_edges()
		if source_character_id != _active_character_id:
			return {
				"ok": false,
				"error": "Select the image's character in Workspace before using it as the Collaborator target."
			}
		var character := CCFStorageService.get_character(
			_project_container, _active_character_id
		)
		if character.is_empty():
			return {"ok": false, "error": "The current Workspace character could not be loaded."}
		var target := IMAGE_SOURCE_SERVICE_V0170.from_character(
			character,
			workspace_project_id,
			str(provenance.get("project_name", "Untitled Project")),
			IMAGE_SOURCE_SERVICE_V0170.ROLE_TARGET
		)
		opened = open_collaborator_with_source_v01533(target)
		if not bool(opened.get("ok", false)):
			return opened
		var added_value: Variant = _character_collaborator_window.call(
			"add_source_v01537", clean, false
		)
		var added: Dictionary = (
			added_value as Dictionary if added_value is Dictionary else {}
		)
		if not bool(added.get("ok", false)):
			return {
				"ok": false,
				"error": str(added.get(
					"error", "The image source could not be added to Collaborator."
				))
			}
	else:
		opened = open_collaborator_with_source_v01533(clean)
		if not bool(opened.get("ok", false)):
			return opened

	var vision_requested := bool(options.get("analyse_with_vision", false))
	var vision_queued := false
	var vision_warning := ""
	if vision_requested:
		if _character_collaborator_window.has_method(
			"_queue_card_image_vision_v01539"
		):
			var vision_value: Variant = _character_collaborator_window.call(
				"_queue_card_image_vision_v01539",
				str(provenance.get("source_path", "")),
				str(clean.get("source_context_id", ""))
			)
			var vision_result: Dictionary = (
				vision_value as Dictionary if vision_value is Dictionary else {}
			)
			vision_queued = bool(vision_result.get("ok", false))
			if not vision_queued:
				vision_warning = str(vision_result.get(
					"error", "Vision analysis could not be queued."
				))
		else:
			vision_warning = "The active Collaborator does not support linked Vision analysis."

	var mode_message := (
		"with the current character as the explicit target"
		if handoff_mode == HANDOFF_SERVICE_V0170.MODE_EXISTING_TARGET
		else "as a new image-led conversation without an existing character target"
	)
	var message := (
		"Character Collaborator opened %s. The image and its generation record are read-only Reference Context."
		% mode_message
	)
	if vision_queued:
		message += " Separate Vision analysis was queued as supplementary evidence."
	elif not vision_warning.is_empty():
		message += " The structured handoff succeeded, but %s" % vision_warning
	_status.text = message
	return {
		"ok": true,
		"message": message,
		"vision_requested": vision_requested,
		"vision_queued": vision_queued,
		"vision_warning": vision_warning,
		"source_context_id": str(clean.get("source_context_id", "")),
		"mode": handoff_mode,
		"canonical_character_changed": false
	}


func image_collaborator_handoff_capabilities_v0170() -> Dictionary:
	return HANDOFF_SERVICE_V0170.capabilities()
