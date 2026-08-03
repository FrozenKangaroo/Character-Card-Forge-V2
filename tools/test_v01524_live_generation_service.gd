extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	assert(packed != null, "v0.15.24 must have a loadable main scene.")
	var app := packed.instantiate()
	assert(app != null, "v0.15.24 main scene must instantiate.")
	get_root().add_child(app)
	await process_frame

	var workspace := _find_workspace_v01524(app)
	assert(workspace != null, "The live app shell must install CCFWorkspaceV01524View.")
	assert(workspace.call("_ensure_strategy_generation_service_v01524"), "The live Workspace must be able to enforce the strategy-aware generation service.")

	var service_value: Variant = workspace.get("_generation_service")
	assert(service_value is Node, "The live Workspace must have a generation-service Node.")
	var service := service_value as Node
	assert(service is CCFGenerationServiceV01522, "The live Workspace must not retain the legacy v0.14.3 generation service.")
	assert(service.has_method("queue_character_generation_with_strategy"), "Generate Character requires the v0.15.22 strategy-aware queue method at runtime.")
	assert(service.has_signal("diagnostics_available"), "The installed strategy service must retain Generation Diagnostics.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01524.gd")
	assert(workspace_source.contains("_ensure_strategy_generation_service_v01524"), "v0.15.24 must guard the actual Generate Character path before calling the strategy method.")
	assert(workspace_source.contains("super._generate_character()"), "The runtime guard must preserve the v0.15.22 Safe/Fast generation implementation.")

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01524.gd")
	assert(main_source.contains('BUILD_DISPLAY_VERSION_V01524 := "0.15.24"'), "The v0.15.24 shell must expose its build version.")
	assert(_active_shell_inherits_from("res://scripts/main_v01524.gd"), "The active scene must use or inherit v0.15.24.")

	app.queue_free()
	await process_frame
	print("v0.15.24 live generation-service wiring regression passed")
	quit(0)


func _find_workspace_v01524(root: Node) -> CCFWorkspaceV01524View:
	if root is CCFWorkspaceV01524View:
		return root as CCFWorkspaceV01524View
	for child in root.get_children():
		if child is Node:
			var found := _find_workspace_v01524(child)
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
