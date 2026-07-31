class_name CCFWorkspaceV01410View
extends "res://scripts/ui/workspace_v0148.gd"

const DERIVATION_WINDOW_V01410 = preload("res://scripts/ui/character_derivation_window_v01410.gd")
const DERIVATION_MENU_ID := 1410

var _derivation_window: CCFCharacterDerivationWindowV01410


func _ready() -> void:
	super._ready()
	_build_derivation_window()
	_add_derivation_character_menu_action()


func _build_derivation_window() -> void:
	_derivation_window = DERIVATION_WINDOW_V01410.new()
	_derivation_window.visible = false
	_derivation_window.create_requested.connect(_on_derivation_create_requested)
	add_child(_derivation_window)
	_derivation_window.hide()


func _add_derivation_character_menu_action() -> void:
	for node in find_children("*", "MenuButton", true, false):
		if not node is MenuButton:
			continue
		var menu := node as MenuButton
		if menu.text != "Character":
			continue
		var popup := menu.get_popup()
		popup.add_separator()
		popup.add_item("Create Related Character / AI Variation…", DERIVATION_MENU_ID)
		popup.id_pressed.connect(_on_derivation_menu_pressed)
		return


func _on_derivation_menu_pressed(id: int) -> void:
	if id != DERIVATION_MENU_ID:
		return
	_open_derivation_window()


func _open_derivation_window() -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		_status.text = "Open a character before creating a related character or variation."
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	var source := CCFStorageService.get_character(_project_container, _active_character_id)
	_derivation_window.open_for_character(CCFStorageService.character_display_name(source))
	_status.text = "Describe the related character or variation to create from the active character."


func _on_derivation_create_requested(options: Dictionary) -> void:
	if _project_container.is_empty() or _active_character_id.is_empty():
		return
	_capture_all_fields()
	_commit_active_character_to_container()
	_capture_project_name()

	var source_id := _active_character_id
	var source := CCFStorageService.get_character(_project_container, source_id)
	if source.is_empty():
		_status.text = "The source character could not be found."
		return
	var source_name := CCFStorageService.character_display_name(source)
	var mode := str(options.get("mode", "related"))
	var requested_name := str(options.get("name", "")).strip_edges()
	if requested_name.is_empty() and mode == "variation":
		requested_name = source_name
	var new_character := CCFStorageService.new_character_record(requested_name)
	var new_id := str(new_character.get("character_id", ""))

	var concept_text := _build_derivation_concept(source, options)
	var concept: Dictionary = new_character.get("concept", {}).duplicate(true)
	concept["prompt"] = concept_text
	concept["notes"] = "Created from %s using Character Card Forge related-character/variation workflow." % source_name
	new_character["concept"] = concept

	var source_generation: Dictionary = source.get("generation", {})
	var generation: Dictionary = new_character.get("generation", {}).duplicate(true)
	generation["template_id"] = str(source_generation.get("template_id", "default"))
	new_character["generation"] = generation

	var workspace: Dictionary = new_character.get("workspace", {}).duplicate(true)
	workspace["derivation"] = {
		"source_project_id": str(_project_container.get("project_id", "")),
		"source_character_id": source_id,
		"source_character_name": source_name,
		"derivation_type": mode,
		"derivation_prompt": str(options.get("instruction", "")),
		"created_at": Time.get_datetime_string_from_system(true)
	}
	new_character["workspace"] = workspace

	var characters: Array = []
	var raw_characters: Variant = _project_container.get("characters", [])
	if raw_characters is Array:
		characters = raw_characters.duplicate(true)
	characters.append(new_character)
	_project_container["characters"] = characters
	var project_workspace: Dictionary = _project_container.get("workspace", {}).duplicate(true)
	project_workspace["active_character_id"] = new_id
	_project_container["workspace"] = project_workspace

	var template_id := str(generation.get("template_id", "default"))
	load_project(_project_container, CCFTemplateService.load_template(template_id), _settings)
	_dirty = true
	_status.text = "%s created from %s. Review the seeded Generation Concept before saving." % [
		"AI variation" if mode == "variation" else "Related character",
		source_name
	]
	if bool(options.get("auto_generate", true)):
		call_deferred("_launch_derivation_generation")


func _build_derivation_concept(source: Dictionary, options: Dictionary) -> String:
	var source_name := CCFStorageService.character_display_name(source)
	var mode := str(options.get("mode", "related"))
	var instruction := str(options.get("instruction", "")).strip_edges()
	var lines: Array[String] = []
	lines.append("DERIVATION TASK: %s" % ("AI VARIATION" if mode == "variation" else "RELATED CHARACTER"))
	lines.append("User request: %s" % instruction)
	lines.append("")
	if mode == "variation":
		lines.append("Create a new standalone version of %s. Preserve established identity anchors unless the user explicitly asks to transform them. Apply the requested age/time/AU/personality/life-path changes consistently. Do not overwrite or describe the source character as the output." % source_name)
	else:
		lines.append("Create a distinct standalone character related to %s. Treat established facts about the requested person as authoritative, infer only missing details, and do not accidentally clone %s's identity or personality." % [source_name, source_name])

	if bool(options.get("include_source_card", true)):
		var card_value: Variant = source.get("character", {})
		var card: Dictionary = card_value if card_value is Dictionary else {}
		lines.append("")
		lines.append("SOURCE CHARACTER — %s" % source_name)
		for field_name in ["description", "personality", "scenario", "first_message", "example_dialogue", "creator_notes", "system_prompt"]:
			var value := str(card.get(field_name, "")).strip_edges()
			if not value.is_empty():
				lines.append("%s:\n%s" % [field_name.capitalize(), value])
		var source_concept_value: Variant = source.get("concept", {})
		if source_concept_value is Dictionary:
			var source_concept := str(source_concept_value.get("prompt", "")).strip_edges()
			if not source_concept.is_empty():
				lines.append("Original Generation Concept:\n%s" % source_concept)

	if bool(options.get("include_shared_context", true)):
		var shared_value: Variant = _project_container.get("shared_context", {})
		if shared_value is Dictionary and not shared_value.is_empty():
			lines.append("")
			lines.append("SHARED PROJECT CONTEXT:")
			for field_name in ["title", "premise", "setting", "situation", "shared_rules", "notes"]:
				var shared_text := str(shared_value.get(field_name, "")).strip_edges()
				if not shared_text.is_empty():
					lines.append("%s: %s" % [field_name.capitalize(), shared_text])

	if bool(options.get("include_relationships", true)):
		var relationship_lines: Array[String] = []
		var relationships_value: Variant = _project_container.get("relationships", [])
		if relationships_value is Array:
			for raw_relationship in relationships_value:
				if not raw_relationship is Dictionary:
					continue
				var relationship: Dictionary = raw_relationship
				if str(relationship.get("character_a_id", "")) == _active_character_id or str(relationship.get("character_b_id", "")) == _active_character_id:
					relationship_lines.append(JSON.stringify(relationship))
		if not relationship_lines.is_empty():
			lines.append("")
			lines.append("ESTABLISHED SOURCE RELATIONSHIPS:")
			lines.append_array(relationship_lines)

	lines.append("")
	lines.append("Return a complete Character Card candidate using the active template. The requested derivation is authoritative; preserve source facts only where compatible with that request.")
	return "\n".join(lines)


func _launch_derivation_generation() -> void:
	var generate_button := _find_workspace_button("Generate Character")
	if generate_button == null:
		_status.text = "Related character created. Use Generate Character to generate it."
		return
	generate_button.pressed.emit()


func _close_tool_windows_for_project_change() -> void:
	if _derivation_window != null and _derivation_window.visible:
		_derivation_window.hide()
	super._close_tool_windows_for_project_change()
