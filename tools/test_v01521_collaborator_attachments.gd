extends SceneTree

const TEST_DIR := "user://v01521_attachment_regression"


func _init() -> void:
	_prepare_fixture_files()

	var text_result := CCFCollaboratorAttachmentServiceV01521.load_file_attachment(TEST_DIR + "/notes.txt")
	assert(bool(text_result.get("ok", false)), "TXT attachments must load successfully.")
	var text_attachment: Dictionary = text_result.get("attachment", {})
	assert(str(text_attachment.get("kind", "")) == "text", "TXT attachments must be stored as text context.")
	assert(str(text_attachment.get("text", "")).contains("never forget the blue umbrella"), "Text attachment contents must be embedded verbatim.")
	assert(int(text_attachment.get("estimated_tokens", 0)) > 0, "Text attachments must report an estimated context cost.")

	var srt_result := CCFCollaboratorAttachmentServiceV01521.load_file_attachment(TEST_DIR + "/dialogue.srt")
	assert(bool(srt_result.get("ok", false)), "SRT attachments must load successfully.")
	assert(str(srt_result.get("attachment", {}).get("text", "")).contains("00:00:01,000 --> 00:00:03,000"), "Subtitle timing must be preserved verbatim.")

	var ass_result := CCFCollaboratorAttachmentServiceV01521.load_file_attachment(TEST_DIR + "/dialogue.ass")
	assert(bool(ass_result.get("ok", false)), "ASS attachments must load successfully.")
	assert(str(ass_result.get("attachment", {}).get("text", "")).contains("Dialogue: 0,0:00:01.00"), "ASS event/style fields must be preserved verbatim.")

	var json_result := CCFCollaboratorAttachmentServiceV01521.load_file_attachment(TEST_DIR + "/notes.json")
	assert(bool(json_result.get("ok", false)), "Raw JSON attachments must load as reference context.")
	assert(str(json_result.get("attachment", {}).get("format", "")) == "json", "Raw JSON attachments must remain distinguishable from the dedicated Character Card import workflow.")

	var image_classification := CCFCollaboratorAttachmentServiceV01521.classify_path("reference.PNG")
	assert(bool(image_classification.get("supported", false)), "PNG must remain a supported Collaborator attachment.")
	assert(str(image_classification.get("kind", "")) == "image", "Image attachments must remain routed through the existing Vision path.")

	var unsupported := CCFCollaboratorAttachmentServiceV01521.classify_path("archive.zip")
	assert(not bool(unsupported.get("supported", false)), "Unsupported file types must be rejected before they enter Collaborator context.")

	var too_large_result := CCFCollaboratorAttachmentServiceV01521.load_file_attachment(TEST_DIR + "/too_large.txt")
	assert(not bool(too_large_result.get("ok", true)), "Oversized text references must fail closed.")
	assert(str(too_large_result.get("error", "")).contains("4 MiB"), "Oversized attachment failures must explain the safety limit.")

	var summary := CCFCollaboratorAttachmentServiceV01521.summarise_context(
		[text_attachment, srt_result.get("attachment", {}), ass_result.get("attachment", {}), json_result.get("attachment", {})]
	)
	assert(int(summary.get("count", 0)) == 4, "Attachment summary must report the active reference count.")
	assert(int(summary.get("estimated_tokens", 0)) >= int(text_attachment.get("estimated_tokens", 0)), "Attachment summary must expose aggregate context cost.")

	var window_source := FileAccess.get_file_as_string("res://scripts/ui/character_collaborator_window_v01521.gd")
	for marker in [
		"Attach…",
		"Attach Files…",
		"Reference Context",
		"_attach_reference_files_v01521",
		"_remove_attachment_v01521",
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
	assert(runner_source.contains("DEFAULT_MANIFEST") and runner_source.contains("regression_suites_v015"), "Broad regression runs must continue to use a versioned registry after v0.15.21 so attachment coverage can remain in release gating through manifest inheritance.")
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
		'{"purpose":"reference only","facts":["blue umbrella","station platform"]}\n'
	)
	_write_fixture(
		TEST_DIR + "/notes.txt",
		"Character continuity note: never forget the blue umbrella.\nSecond line stays intact.\n"
	)
	var large_file := FileAccess.open(TEST_DIR + "/too_large.txt", FileAccess.WRITE)
	assert(large_file != null, "Could not create oversized attachment fixture.")
	large_file.resize(CCFCollaboratorAttachmentServiceV01521.MAX_TEXT_BYTES + 1)
	large_file.close()


func _write_fixture(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null, "Could not create attachment regression fixture: %s" % path)
	file.store_string(content)
	file.close()


func _cleanup_fixture_files() -> void:
	var directory := DirAccess.open(TEST_DIR)
	if directory != null:
		for file_name in directory.get_files():
			directory.remove(file_name)
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
