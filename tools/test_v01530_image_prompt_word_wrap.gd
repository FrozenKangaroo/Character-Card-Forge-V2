extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	assert(packed != null, "v0.15.30 main scene must load.")
	var app := packed.instantiate()
	assert(app != null, "v0.15.30 main scene must instantiate.")
	get_root().add_child(app)
	for _frame in range(6):
		await process_frame

	var image_window := _find_image_window_v01530(app)
	assert(
		image_window != null,
		"The live app must install CCFImageGenerationWindowV01530."
	)
	app.call("_open_image_studio")
	for _frame in range(3):
		await process_frame

	var prompt_edit := image_window.get("_prompt_edit") as TextEdit
	var negative_prompt_edit := image_window.get("_negative_prompt_edit") as TextEdit
	assert(prompt_edit != null, "Image Studio must expose the Image Prompt TextEdit.")
	assert(
		negative_prompt_edit != null,
		"Image Studio must expose the Negative Prompt TextEdit."
	)
	_assert_wrapping_v01530(prompt_edit, "Image Prompt")
	_assert_wrapping_v01530(negative_prompt_edit, "Negative Prompt")

	var long_paragraph := (
		"portrait photography detailed lighting character expression clothing environment composition "
		+ "cinematic background depth of field reflections atmosphere texture colour balance pose camera angle "
	).repeat(12)
	prompt_edit.text = long_paragraph
	negative_prompt_edit.text = long_paragraph
	for _frame in range(3):
		await process_frame
	assert(
		prompt_edit.get_line_wrap_count(0) > 0,
		"Image Prompt must visually wrap a long single paragraph instead of becoming one horizontal line."
	)
	assert(
		negative_prompt_edit.get_line_wrap_count(0) > 0,
		"Negative Prompt must visually wrap a long single paragraph instead of becoming one horizontal line."
	)

	var source := FileAccess.get_file_as_string(
		"res://scripts/ui/image_generation_window_v01530.gd"
	)
	assert(
		source.count("TextEdit.LINE_WRAPPING_BOUNDARY") >= 1,
		"v0.15.30 must explicitly retain boundary word wrapping for prompt editors."
	)
	assert(
		_active_shell_inherits_from("res://scripts/main_v01530.gd"),
		"The active scene must use or inherit the v0.15.30 shell."
	)

	app.queue_free()
	await process_frame
	print("v0.15.30 Image Prompt and Negative Prompt word-wrap regression passed")
	quit(0)


func _assert_wrapping_v01530(editor: TextEdit, label_text: String) -> void:
	assert(
		editor.wrap_mode == TextEdit.LINE_WRAPPING_BOUNDARY,
		"%s must use boundary word wrapping." % label_text
	)
	assert(
		editor.scroll_horizontal == 0,
		"%s must not retain a horizontal scroll offset after wrap configuration." % label_text
	)


func _find_image_window_v01530(root: Node) -> CCFImageGenerationWindowV01530:
	if root is CCFImageGenerationWindowV01530:
		return root as CCFImageGenerationWindowV01530
	for child in root.get_children():
		if child is Node:
			var found := _find_image_window_v01530(child)
			if found != null:
				return found
	return null


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
