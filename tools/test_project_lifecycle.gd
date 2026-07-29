extends SceneTree


func _init() -> void:
	var failures: Array[String] = []

	var empty_project := CCFStorageService.new_project()
	_blank_first_character(empty_project)
	if CCFProjectLifecycleService.project_has_real_character(empty_project):
		failures.append("A blank new project was treated as having a real character.")
	var empty_prepare := CCFProjectLifecycleService.prepare_for_save(
		empty_project, CCFStorageService.active_character_id(empty_project)
	)
	if bool(empty_prepare.get("ok", false)) or not bool(empty_prepare.get("empty", false)):
		failures.append("A blank new project was allowed through the save lifecycle.")

	var named_project := CCFStorageService.new_project()
	_set_first_character_name(named_project, "Eleanor Smith")
	var named_metadata: Dictionary = named_project.get("metadata", {}).duplicate(true)
	named_metadata["name"] = ""
	named_metadata["name_is_manual"] = false
	named_project["metadata"] = named_metadata
	CCFProjectLifecycleService.sync_project_name(named_project)
	if str(named_project.get("metadata", {}).get("name", "")) != "Eleanor":
		failures.append("Automatic project naming did not use the first character's first name.")

	var manual_metadata: Dictionary = named_project.get("metadata", {}).duplicate(true)
	manual_metadata["name"] = "University Friends"
	manual_metadata["name_is_manual"] = true
	named_project["metadata"] = manual_metadata
	_set_first_character_name(named_project, "Ellie Smith")
	CCFProjectLifecycleService.sync_project_name(named_project)
	if str(named_project.get("metadata", {}).get("name", "")) != "University Friends":
		failures.append("A manually named project was overwritten by automatic naming.")

	var extra_id := CCFStorageService.add_character(named_project, "Untitled Character")
	_blank_character(named_project, extra_id)
	var prepared := CCFProjectLifecycleService.prepare_for_save(
		named_project, extra_id
	)
	if not bool(prepared.get("ok", false)):
		failures.append("A valid named character project failed save preparation.")
	elif int(prepared.get("removed_count", 0)) != 1:
		failures.append("An empty added-character draft was not pruned before save.")

	var unnamed_with_content := CCFStorageService.new_project()
	_blank_first_character(unnamed_with_content)
	var first_id := CCFStorageService.active_character_id(unnamed_with_content)
	var first := CCFStorageService.get_character(unnamed_with_content, first_id)
	var concept: Dictionary = first.get("concept", {}).duplicate(true)
	concept["prompt"] = "A real character concept without a final name yet."
	first["concept"] = concept
	CCFStorageService.update_character(unnamed_with_content, first)
	var unnamed_prepare := CCFProjectLifecycleService.prepare_for_save(
		unnamed_with_content, first_id
	)
	if bool(unnamed_prepare.get("ok", false)) or bool(unnamed_prepare.get("empty", true)):
		failures.append("Meaningful unnamed character content was not blocked from placeholder-name save.")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Project lifecycle regression passed.")
	quit(0)


func _blank_first_character(project: Dictionary) -> void:
	var character_id := CCFStorageService.active_character_id(project)
	_blank_character(project, character_id)


func _set_first_character_name(project: Dictionary, character_name: String) -> void:
	var character_id := CCFStorageService.active_character_id(project)
	var character := CCFStorageService.get_character(project, character_id)
	var metadata: Dictionary = character.get("metadata", {}).duplicate(true)
	var card: Dictionary = character.get("character", {}).duplicate(true)
	metadata["name"] = character_name
	card["name"] = character_name
	character["metadata"] = metadata
	character["character"] = card
	CCFStorageService.update_character(project, character)


func _blank_character(project: Dictionary, character_id: String) -> void:
	var index := CCFStorageService.character_index(project, character_id)
	if index < 0:
		return
	var characters: Array = project.get("characters", []).duplicate(true)
	var character: Dictionary = characters[index].duplicate(true)
	var metadata: Dictionary = character.get("metadata", {}).duplicate(true)
	var card: Dictionary = character.get("character", {}).duplicate(true)
	metadata["name"] = ""
	card["name"] = ""
	character["metadata"] = metadata
	character["character"] = card
	characters[index] = character
	project["characters"] = characters
