extends SceneTree

func _init() -> void:
	var project := CCFStorageService.new_project()
	var characters: Array = project.get("characters", [])
	if characters.is_empty():
		_fail("new project did not contain a character")
		return
	var character: Dictionary = characters[0]
	var card: Dictionary = character.get("character", {}).duplicate(true)
	card["name"] = "Eleanor"
	card["description"] = "Age: 22\nAppearance: Tall with brown hair."
	card["personality"] = "Mind: Thoughtful"
	card["scenario"] = "A university library."
	card["first_message"] = "The main opening."
	card["example_dialogue"] = "<START>\n{{char}}: Hello."
	card["alternate_greetings"] = ["Alternate opening one.", "Alternate opening two."]
	character["character"] = card
	characters[0] = character
	project["characters"] = characters
	var character_id := str(character.get("character_id", ""))
	var exported := CCFCardFormatService.export_character_v2(project, character_id)
	var data: Dictionary = exported.get("data", {})
	var alternatives: Array = data.get("alternate_greetings", [])
	if alternatives.size() != 2:
		_fail("alternate greeting count was not preserved")
		return
	if str(alternatives[0]) != "Alternate opening one." or str(alternatives[1]) != "Alternate opening two.":
		_fail("alternate greeting text was not preserved")
		return
	print("Alternative greetings export regression passed.")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
