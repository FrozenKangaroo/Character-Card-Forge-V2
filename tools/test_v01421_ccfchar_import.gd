extends SceneTree


func _init() -> void:
	var minimal := {
		"format": "character_card_forge_character_source",
		"format_version": 1,
		"concept": {"prompt": "A racer girl who drags {{user}} to the track after class."}
	}
	var parsed := CCFCharSourceServiceV01421.normalise_source(minimal)
	assert(parsed.get("ok", false), "Concept-only .ccfchar sources must be accepted.")
	var values: Dictionary = parsed.get("values", {})
	assert(values.size() == 1 and values.has("concept.prompt"), "Concept-only source must not invent missing fields.")

	var workspace := CCFStorageService.new_character_record("Existing")
	CCFStorageService.set_value_at_path(workspace, "character.description", "Keep this description")
	var applied := CCFCharSourceServiceV01421.apply_values(workspace, parsed, ["concept.prompt"])
	assert(applied.get("ok", false), "Concept-only source should apply.")
	assert(CCFStorageService.get_value_at_path(workspace, "character.description", "") == "Keep this description", "Omitted fields must remain untouched.")
	assert(CCFStorageService.get_value_at_path(workspace, "concept.prompt", "") == minimal.concept.prompt, "Concept must map into the workspace.")

	var complete := {
		"format": "character_card_forge_character_source",
		"format_version": 1,
		"metadata": {"summary": "", "tags": ["racing", "university"]},
		"character": {
			"name": "Mika",
			"personality": "Competitive and excitable.",
			"alternate_greetings": ["Hi {{user}}!", "Track day, {{user}}!"]
		},
		"generation": {"template_id": "default", "mode": "full", "style": "anime romantic comedy"},
		"lorebook": {"name": "Mika Lore", "entries": [{"keys": ["karting"], "content": "Mika raced karts."}]}
	}
	var complete_parsed := CCFCharSourceServiceV01421.normalise_source(complete)
	assert(complete_parsed.get("ok", false), "Full .ccfchar source should parse.")
	var complete_values: Dictionary = complete_parsed.get("values", {})
	assert(complete_values.has("character.alternate_greetings"), "Alternative greetings must be supported.")
	assert(complete_values.has("character.character_book"), "Lorebook must map to character.character_book.")
	assert(complete_values.get("generation.mode") == "full", "Generation mode must be importable.")
	assert(complete_values.get("generation.style") == "anime romantic comedy", "Generation style must be importable.")

	var all_paths: Array[String] = []
	for raw_path in complete_values.keys():
		all_paths.append(str(raw_path))
	CCFCharSourceServiceV01421.apply_values(workspace, complete_parsed, all_paths)
	assert(CCFStorageService.get_value_at_path(workspace, "metadata.summary", "not-empty") == "", "Explicit empty strings must be able to clear selected fields.")
	assert((CCFStorageService.get_value_at_path(workspace, "character.alternate_greetings", []) as Array).size() == 2, "Alternative greetings must round-trip into workspace data.")
	assert(CCFStorageService.get_value_at_path(workspace, "generation.mode", "") == "full", "Mode must be stored in generation authoring state.")
	assert((CCFStorageService.get_value_at_path(workspace, "character.character_book", {}) as Dictionary).get("name", "") == "Mika Lore", "Lorebook must be applied intact.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01421.gd")
	assert(workspace_source.contains("Import .ccfchar Source"), "Workspace must expose the .ccfchar importer.")
	assert(workspace_source.contains("Apply Selected"), "Importer must provide review/selective apply.")
	assert(workspace_source.contains("Import Another .ccfchar"), "Importer review must make repeat imports obvious.")
	assert(workspace_source.contains("_ccfchar_preview = Window.new()"), "Import preview must use a normal Window with an explicit action bar.")
	assert(workspace_source.contains("_ccfchar_preview.force_native = true"), "Importer review must be a native detachable window.")
	assert(workspace_source.contains("_ccfchar_preview.transient = false"), "Importer review must not be trapped inside the main window.")
	assert(workspace_source.contains("_ccfchar_dialog.force_native = true"), "CCFCHAR file picker must also be native.")
	assert(workspace_source.contains("_ccfchar_apply_button.pressed.connect(_apply_ccfchar_selected)"), "Visible Apply Selected button must invoke the importer directly.")
	assert(workspace_source.contains("cancel_button.pressed.connect(_close_ccfchar_preview)"), "Import preview must provide a visible Cancel action.")
	var docs := FileAccess.get_file_as_string("res://docs/ccfchar-format.md")
	assert(docs.contains("Missing property = do nothing"), "Format documentation must explain non-destructive partial imports.")
	assert(_active_shell_preserves("main_v01421.gd"), "The active main shell must preserve v0.14.21 through direct use or inheritance.")

	print("v0.14.21 CCFCHAR import regression passed")
	quit(0)


func _active_shell_preserves(target_script: String) -> bool:
	var scene := FileAccess.get_file_as_string("res://scenes/main.tscn")
	var marker := "res://scripts/"
	var start := scene.find(marker)
	if start < 0:
		return false
	start += marker.length()
	var finish := scene.find("\"", start)
	if finish < 0:
		return false
	return _script_inheritance_contains(scene.substr(start, finish - start), target_script, {})


func _script_inheritance_contains(script_name: String, target_script: String, visited: Dictionary) -> bool:
	if script_name == target_script:
		return true
	if visited.has(script_name):
		return false
	visited[script_name] = true
	var source := FileAccess.get_file_as_string("res://scripts/%s" % script_name)
	var marker := "extends \"res://scripts/"
	var start := source.find(marker)
	if start < 0:
		return false
	start += marker.length()
	var finish := source.find("\"", start)
	if finish < 0:
		return false
	return _script_inheritance_contains(source.substr(start, finish - start), target_script, visited)
