extends SceneTree

const TEST_DIR := "user://v01521_attachment_regression"


func _init() -> void:
	_prepare_fixture_files()

	var service := CCFCollaboratorAttachmentServiceV01521
	for extension in ["txt", "md", "markdown", "srt", "ass", "ssa", "json"]:
		var classified := service.classify_path("/tmp/reference.%s" % extension)
		assert(bool(classified.get("ok", false)), "v0.15.21 must accept .%s text attachments." % extension)
		assert(str(classified.get("kind", "")) == "text", ".%s must route through the text attachment path." % extension)
	for extension in ["png", "jpg", "jpeg", "webp"]:
		var classified_image := service.classify_path("/tmp/reference.%s" % extension)
		assert(bool(classified_image.get("ok", false)), "Existing .%s image attachment support must remain available." % extension)
		assert(str(classified_image.get("kind", "")) == "image", "Images must continue through the Vision attachment path.")
	assert(not bool(service.classify_path("/tmp/reference.exe").get("ok", true)), "Unsupported binary file types must not be silently treated as text.")

	var srt_result := service.load_text_attachment(TEST_DIR + "/dialogue.srt")
	assert(bool(srt_result.get("ok", false)), "SRT attachment fixture must load.")
	var srt_attachment: Dictionary = srt_result.get("attachment", {})
	assert(str(srt_attachment.get("raw_text", "")).contains("00:00:01,000 --> 00:00:03,000"), "SRT timestamps must be preserved verbatim.")
	assert(str(srt_attachment.get("raw_text", "")).contains("You always say that."), "SRT dialogue must be preserved verbatim.")
	assert(bool(srt_attachment.get("embedded_text_copy", false)), "Text attachments must persist an embedded text copy instead of depending on the source path.")
	assert(str(srt_attachment.get("context_provenance", "")) == "user_attached_text_file", "Text attachment provenance must be explicit.")

	var ass_result := service.load_text_attachment(TEST_DIR + "/dialogue.ass")
	assert(bool(ass_result.get("ok", false)), "ASS attachment fixture must load.")
	var ass_text := str((ass_result.get("attachment", {}) as Dictionary).get("raw_text", ""))
	assert(ass_text.contains("Dialogue: 0,0:00:01.00,0:00:03.00,Default,Akari"), "ASS dialogue/style/speaker metadata must remain intact.")

	var json_result := service.load_text_attachment(TEST_DIR + "/notes.json")
	assert(bool(json_result.get("ok", false)), "JSON attachment fixture must load as reference text.")
	var json_attachment: Dictionary = json_result.get("attachment", {})
	assert(bool(json_attachment.get("json_valid", false)), "Valid JSON attachments should be identified without rewriting their source text.")
	assert(str(json_attachment.get("raw_text", "")).contains('"relationship": "childhood friend"'), "JSON source structure must be retained.")

	var collaborator := CCFCharacterCollaboratorWindowV01521.new()
	assert(collaborator is CCFCharacterCollaboratorWindowV01515, "Unified attachments must extend the established Blueprint-first Collaborator rather than replace it.")
	assert(collaborator.has_method("_on_image_selected"), "Existing image attachment/Vision entry point must remain inherited.")
	assert(collaborator.has_method("_apply_vision_summary_v01511"), "Persistent Vision Analysis behavior must remain available.")
	collaborator.free()

	var window_source := FileAccess.get_file_as_string("res://scripts/ui/character_collaborator_window_v01521.gd")
	for marker in [
		"FILE_MODE_OPEN_FILES",
		"*.srt",
		"*.ass",
		"*.ssa",
		"*.json",
		"Attach Files…",
		"Remove Attachment",
		"_remove_context_item(index)",
		"_attachment_context_tokens_v01521",
		"super._apply_vision_summary_v01511"
	]:
		assert(window_source.contains(marker), "v0.15.21 Collaborator attachment UI is missing %s." % marker)

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01521.gd")
	assert(workspace_source.contains("CHARACTER_COLLABORATOR_WINDOW_V01521"), "The live Workspace must instantiate the unified-attachment Collaborator.")
	assert(workspace_source.contains('extends "res://scripts/ui/workspace_v01517.gd"'), "v0.15.21 Workspace must retain Blueprint materialisation/template continuity through inheritance.")

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01521.gd")
	assert(main_source.contains('extends "res://scripts/main_v01520.gd"'), "v0.15.21 must retain the broad regression-safety shell.")
	assert(main_source.contains('BUILD_DISPLAY_VERSION_V01521 := "0.15.21"'), "The v0.15.21 shell must expose its build version.")
	assert(_active_shell_inherits_from("res://scripts/main_v01521.gd"), "The active scene must use or inherit v0.15.21.")

	var runner_source := FileAccess.get_file_as_string("res://tools/run_regression_suite.py")
	assert(
		runner_source.contains("DEFAULT_MANIFEST") and runner_source.contains("regression_suites_v"),
		"Broad regression runs must continue to use a versioned registry after v0.15.21 so attachment coverage can remain in release gating through manifest inheritance."
	)
	var manifest_source := FileAccess.get_file_as_string("res://tools/regression_suites_v01521.json")
	assert(manifest_source.contains("v01521_collaborator_attachments"), "The v0.15.21 regression registry must include the unified attachment regression for later manifests to inherit.")

	_cleanup_fixture_files()
	print("v0.15.21 unified Character Collaborator attachments regression passed")
	quit(0)


func _prepare_fixture_files() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_DIR))
	_write_fixture(
		TEST_DIR + "/dialogue.srt",
		"1\n00:00:01,000 --> 00:00:03,000\nAkari: You always say that.\n\n2\n00:00:04,000 --> 00:00:06,000\nMaybe I like hearing you say it.\n"
	)
	_write_fixture(
		TEST_DIR + "/dialogue.ass",
		"[Script Info]\nTitle: Attachment Regression\n\n[Events]\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\nDialogue: 0,0:00:01.00,0:00:03.00,Default,Akari,0,0,0,,You always say that.\n"
	)
	_write_fixture(
		TEST_DIR + "/notes.json",
		"{\n  \"name\": \"Akari\",\n  \"relationship\": \"childhood friend\",\n  \"notes\": [\"teasing\", \"protective\"]\n}\n"
	)


func _write_fixture(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null, "Could not create attachment regression fixture %s." % path)
	file.store_string(text)
	file.close()


func _cleanup_fixture_files() -> void:
	var directory := DirAccess.open(TEST_DIR)
	if directory == null:
		return
	for filename in directory.get_files():
		directory.remove(filename)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIR))


func _active_shell_inherits_from(target_path: String) -> bool:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		return false
	var root := packed.instantiate()
	if root == null:
		return false
	var current := root.get_script() as Script
	while current != null:
		if current.resource_path == target_path:
			root.free()
			return true
		current = current.get_base_script()
	root.free()
	return false
