extends SceneTree

const MANUAL_GUIDED = preload("res://scripts/ui/manual_guided_window_v0144.gd")
const WORKSPACE = preload("res://scripts/ui/workspace_v0144.gd")
const MAIN = preload("res://scripts/main_v0144.gd")


func _init() -> void:
	var failures: Array[String] = []
	var window := MANUAL_GUIDED.new()
	root.add_child(window)
	var template := CCFTemplateService.load_default_template()
	var project := CCFStorageService.character_workspace_document(
		CCFStorageService.new_project(), ""
	)
	# character_workspace_document needs a real ID from the container.
	var container := CCFStorageService.new_project()
	var character_id := CCFStorageService.active_character_id(container)
	project = CCFStorageService.character_workspace_document(container, character_id)
	window.open_for_character(project, template, {})

	if window.PAGE_DEFINITIONS.size() != 7:
		failures.append("Manual Guided must retain the seven V1-inspired authoring pages.")
	if window._page_for_field({"id":"character"}, {"id":"personality","path":"character.personality"}) != "personality":
		failures.append("Personality field did not map to Personality page.")
	if window._page_for_field({"id":"character"}, {"id":"first_message","path":"character.first_message"}) != "first":
		failures.append("First Message field did not map to First Message(s) page.")
	if window._page_for_field({"id":"overview"}, {"id":"tags","path":"metadata.tags"}) != "tags_system":
		failures.append("Tags did not map to Tags and System Prompt page.")
	var tags = window._typed_value({"id":"tags","type":"tags","path":"metadata.tags"}, "gyaru, student\nromance")
	if not tags is Array or tags.size() != 3:
		failures.append("Manual Guided tags were not converted back to an array.")
	var greetings = window._typed_value({"id":"alternate_greetings","type":"multiline","path":"character.alternate_greetings"}, "Hello there.\n\nTwo months later...")
	if not greetings is Array or greetings.size() != 2:
		failures.append("Alternative greetings were not converted back to an array.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v0144.gd")
	if "Manual Guided" not in workspace_source or "does not call AI" not in workspace_source:
		failures.append("Workspace is missing the explicit no-AI Manual Guided entry point.")
	var main_source := FileAccess.get_file_as_string("res://scripts/main_v0144.gd")
	if "0.14.4" not in main_source:
		failures.append("v0.14.4 development label is missing.")

	window.queue_free()
	if failures.is_empty():
		print("v0.14.4 Manual Guided regression: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
