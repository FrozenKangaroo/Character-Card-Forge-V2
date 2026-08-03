extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_warning_cleanup_sources()
	await _test_live_startup_and_detached_collaborator_scroll()
	print("v0.15.27 runtime warning and Collaborator lifecycle regression passed")
	quit(0)


func _test_warning_cleanup_sources() -> void:
	var diagnostics_source := FileAccess.get_file_as_string(
		"res://scripts/services/generation_service_v01522.gd"
	)
	assert(
		diagnostics_source.contains("var header_name :="),
		"Diagnostics redaction must use a non-shadowing header_name local."
	)
	assert(
		not diagnostics_source.contains("var name := header_text.substr"),
		"The Node.name-shadowing Diagnostics local must not return."
	)

	var scheduler_source := FileAccess.get_file_as_string(
		"res://scripts/services/generation_service_v01526.gd"
	)
	assert(
		scheduler_source.contains("var dependencies_satisfied := true"),
		"Dependency-wave readiness must use a non-shadowing local."
	)
	assert(
		not scheduler_source.contains("var ready := true"),
		"The Node.ready-shadowing scheduler local must not return."
	)

	var collaborator_source := FileAccess.get_file_as_string(
		"res://scripts/ui/character_collaborator_window_v0153.gd"
	)
	assert(
		collaborator_source.contains("not is_inside_tree()"),
		"Collaborator scrolling must guard detached windows before awaiting frames."
	)
	assert(
		collaborator_source.contains("var scene_tree := get_tree()"),
		"Collaborator scrolling must retain and validate one SceneTree reference."
	)
	assert(
		collaborator_source.contains("get_tree() != scene_tree"),
		"Collaborator scrolling must stop when its tree changes during an await."
	)


func _test_live_startup_and_detached_collaborator_scroll() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	assert(packed != null, "v0.15.27 must keep the main scene loadable.")
	var app := packed.instantiate()
	assert(app != null, "v0.15.27 main scene must instantiate.")
	get_root().add_child(app)
	for _frame in range(5):
		await process_frame
	assert(
		_active_shell_inherits_from("res://scripts/main_v01527.gd"),
		"The active scene must use or inherit the v0.15.27 shell."
	)

	var transient_window := CCFCharacterCollaboratorWindowV01521.new()
	get_root().add_child(transient_window)
	await process_frame
	await process_frame
	assert(
		transient_window.is_inside_tree(),
		"The Collaborator lifecycle fixture must enter the SceneTree before testing detachment."
	)

	# Start the asynchronous two-frame scroll and detach the window while it is
	# suspended at its first process-frame await. This reproduces the runtime path
	# that previously called get_tree() on a queued-for-deletion Collaborator.
	transient_window.call("_scroll_chat_to_bottom")
	get_root().remove_child(transient_window)
	transient_window.queue_free()
	for _frame in range(4):
		await process_frame

	app.queue_free()
	await process_frame


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
