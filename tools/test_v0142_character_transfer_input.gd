extends SceneTree

var _cleanup_project_ids: Array[String] = []


func _init() -> void:
	_test_copy_between_existing_projects()
	_test_move_to_new_project()
	_test_shift_enter_newline()
	_cleanup()
	print("v0.14.2 character transfer and text-input regression passed")
	quit(0)


func _test_copy_between_existing_projects() -> void:
	var source := CCFStorageService.new_project()
	var source_id := str(source.get("project_id", ""))
	_cleanup_project_ids.append(source_id)
	var source_character_id := CCFStorageService.active_character_id(source)
	var source_character := CCFStorageService.get_character(source, source_character_id)
	CCFStorageService.set_value_at_path(source_character, "character.name", "Alice Example")
	CCFStorageService.set_value_at_path(source_character, "concept.prompt", "A detailed source concept.")
	CCFStorageService.set_value_at_path(source_character, "workspace.builder", {"foundation.genre": "Mystery"})
	var relative_image := "characters/%s/generated_images/transfer_test.png" % source_character_id
	CCFStorageService.set_value_at_path(source_character, "assets.portrait", relative_image)
	CCFStorageService.set_value_at_path(source_character, "assets.generated_images", [{"image_id": "img_test", "path": relative_image}])
	CCFStorageService.update_character(source, source_character)
	_assert_true(bool(CCFStorageService.save_project(source).get("ok", false)), "Source project should save before copy regression.")
	_write_fixture_file(source_id, relative_image, "copy-fixture")

	var target := CCFStorageService.new_project()
	var target_id := str(target.get("project_id", ""))
	_cleanup_project_ids.append(target_id)
	var target_character_id := CCFStorageService.active_character_id(target)
	var target_character := CCFStorageService.get_character(target, target_character_id)
	CCFStorageService.set_value_at_path(target_character, "character.name", "Existing Target")
	CCFStorageService.update_character(target, target_character)
	_assert_true(bool(CCFStorageService.save_project(target).get("ok", false)), "Target project should save before copy regression.")

	var result := CCFCharacterTransferService.transfer_character(
		source,
		source_character_id,
		target_id,
		CCFCharacterTransferService.OPERATION_COPY
	)
	_assert_true(bool(result.get("ok", false)), "Copy between existing projects should succeed.")
	var copied_id := str(result.get("target_character_id", ""))
	_assert_true(not copied_id.is_empty() and copied_id != source_character_id, "Copy must allocate an independent character ID.")
	var loaded_target := CCFStorageService.load_project(target_id)
	_assert_true(bool(loaded_target.get("ok", false)), "Copied destination should reload.")
	var copied_character := CCFStorageService.get_character(loaded_target.get("data", {}), copied_id)
	_assert_equal(CCFStorageService.character_display_name(copied_character), "Alice Example", "Copied character should preserve card identity.")
	_assert_equal(
		str(CCFStorageService.get_value_at_path(copied_character, "workspace.builder.foundation.genre", "")),
		"Mystery",
		"Copy should preserve Builder state."
	)
	var copied_portrait := str(CCFStorageService.get_value_at_path(copied_character, "assets.portrait", ""))
	_assert_true(copied_portrait.contains("characters/%s/" % copied_id), "Copied asset paths must be remapped to the copied character ID.")
	_assert_true(
		FileAccess.file_exists(ProjectSettings.globalize_path(CCFStorageService.project_folder(target_id).path_join(copied_portrait))),
		"Copied character-managed files should exist in the destination project."
	)
	_assert_true(
		CCFStorageService.character_index(source, source_character_id) >= 0,
		"Copy must leave the source character intact."
	)


func _test_move_to_new_project() -> void:
	var source := CCFStorageService.new_project()
	var source_id := str(source.get("project_id", ""))
	_cleanup_project_ids.append(source_id)
	var source_character_id := CCFStorageService.active_character_id(source)
	var source_character := CCFStorageService.get_character(source, source_character_id)
	CCFStorageService.set_value_at_path(source_character, "character.name", "Mina Transfer")
	CCFStorageService.set_value_at_path(source_character, "generation.interview_review", {
		"format_version": 1,
		"entries": [{"id": "goal", "answer": "Protect her team", "source": "ai"}]
	})
	var relative_attachment := "characters/%s/attachments/note.txt" % source_character_id
	source_character["attachments"] = [{
		"attachment_id": "attachment_transfer_test",
		"display_name": "Transfer Note",
		"kind": "text",
		"relative_path": relative_attachment,
		"source_filename": "note.txt"
	}]
	CCFStorageService.update_character(source, source_character)
	_assert_true(bool(CCFStorageService.save_project(source).get("ok", false)), "Move source project should save.")
	_write_fixture_file(source_id, relative_attachment, "move-fixture")

	var result := CCFCharacterTransferService.transfer_character(
		source,
		source_character_id,
		"",
		CCFCharacterTransferService.OPERATION_MOVE,
		"Mina Project"
	)
	_assert_true(bool(result.get("ok", false)), "Move into a new project should succeed.")
	_assert_true(bool(result.get("created_project", false)), "Move should report that it created a destination project.")
	_assert_true(bool(result.get("source_replaced_with_empty_draft", false)), "Moving the sole source character should preserve the source project with an empty draft.")
	var target_id := str(result.get("target_project_id", ""))
	_cleanup_project_ids.append(target_id)
	var moved_id := str(result.get("target_character_id", ""))
	_assert_equal(moved_id, source_character_id, "Move should preserve character identity when there is no destination collision.")
	var target_project: Dictionary = result.get("target_project", {})
	var moved_character := CCFStorageService.get_character(target_project, moved_id)
	_assert_equal(CCFStorageService.character_display_name(moved_character), "Mina Transfer", "Moved character should preserve content.")
	_assert_equal(
		str(CCFStorageService.get_value_at_path(moved_character, "generation.interview_review.entries", [])[0].get("answer", "")),
		"Protect her team",
		"Move should preserve private Interview review state."
	)
	_assert_true(
		FileAccess.file_exists(ProjectSettings.globalize_path(CCFStorageService.project_folder(target_id).path_join(relative_attachment))),
		"Moved character attachment should exist in the new project."
	)
	_assert_true(
		not FileAccess.file_exists(ProjectSettings.globalize_path(CCFStorageService.project_folder(source_id).path_join(relative_attachment))),
		"Source character-managed files should be removed only after a successful move."
	)
	_assert_true(
		CCFStorageService.character_index(source, source_character_id) < 0,
		"Moved character should no longer exist in the source roster."
	)


func _test_shift_enter_newline() -> void:
	var service := CCFTextInputConventionService.new()
	var editor := TextEdit.new()
	editor.text = "first"
	editor.set_caret_line(0)
	editor.set_caret_column(editor.text.length())
	var shift_enter := InputEventKey.new()
	shift_enter.pressed = true
	shift_enter.shift_pressed = true
	shift_enter.keycode = KEY_ENTER
	service._on_text_edit_gui_input(shift_enter, editor)
	_assert_equal(editor.text, "first\n", "Shift+Enter should insert a newline in multiline editors.")
	var plain_enter := InputEventKey.new()
	plain_enter.pressed = true
	plain_enter.keycode = KEY_ENTER
	service._on_text_edit_gui_input(plain_enter, editor)
	_assert_equal(editor.text, "first\n", "Shared convention must leave plain Enter to each editor's existing behaviour.")
	editor.free()
	service.free()


func _write_fixture_file(project_id: String, relative_path: String, content: String) -> void:
	var absolute := ProjectSettings.globalize_path(
		CCFStorageService.project_folder(project_id).path_join(relative_path)
	)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(absolute, FileAccess.WRITE)
	_assert_true(file != null, "Regression fixture file should be writable.")
	file.store_string(content)
	file.close()


func _cleanup() -> void:
	for project_id in _cleanup_project_ids:
		var absolute := ProjectSettings.globalize_path(CCFStorageService.project_folder(project_id))
		if DirAccess.dir_exists_absolute(absolute):
			CCFStorageService.delete_project(project_id)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_fail("%s Expected %s, got %s." % [message, str(expected), str(actual)])


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_fail(message)


func _fail(message: String) -> void:
	_cleanup()
	push_error(message)
	quit(1)
