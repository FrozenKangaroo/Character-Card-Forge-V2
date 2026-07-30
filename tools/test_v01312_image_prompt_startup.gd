extends SceneTree

const CONTROLLER = preload("res://scripts/ui/image_generation_controller_v0133.gd")


func _init() -> void:
	var controller = CONTROLLER.new()
	controller._prompt_edit = TextEdit.new()
	controller._negative_prompt_edit = TextEdit.new()
	controller._extra_direction_edit = TextEdit.new()
	controller._status = Label.new()
	controller._project = {"project_id": "project_test"}
	controller._active_character_id = "character_test"

	# Passive project/character refreshes call this base hook. It must never
	# require the AI prompt service or queue a provider request.
	controller._build_prompt_from_character()
	_expect(controller._prompt_generation_service == null, "Passive prompt refresh must not initialise or call the AI prompt service.")

	var prompt_button := Button.new()
	prompt_button.text = "Build Prompt from Character"
	prompt_button.pressed.connect(controller._build_prompt_from_character)
	controller.add_child(prompt_button)
	controller._upgrade_prompt_actions()
	_expect(not prompt_button.pressed.is_connected(controller._build_prompt_from_character), "The legacy button callback must be detached from the passive refresh hook.")
	_expect(prompt_button.pressed.is_connected(controller._generate_prompt_from_character), "The prompt button must invoke the explicit AI-generation action.")
	_expect(prompt_button.text == "Generate Prompt from Character", "The upgraded button should clearly identify the AI action.")

	print("v0.13.12 Image Studio startup prompt regression passed.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
