extends SceneTree

# Development-only UI capture harness.
#
# Loads the real main scene in-process, drives it through its own public and
# underscore entry points (no mouse events), and writes PNG screenshots. This
# exists because desktop automation can be unreliable on some sessions and
# because a deterministic scripted capture is reproducible in CI-less
# environments.
#
# Usage:
#   godot --accessibility disabled --path . --script res://tools/dev/capture_ui.gd -- <out_dir> [project_name]
#
# Screenshots are written as <out_dir>/NN_name.png.
#
# `--accessibility disabled` is not optional on this desktop: Godot 4.7.1's
# accesskit_unix driver can panic ("InterfaceNotFound") when a tab switch
# rebuilds the accessibility tree on Wayland, which kills the capture run
# mid-way. The crash is in the engine's accessibility bridge, not in CCF.

const OUT_FALLBACK := "user://ui_captures"

var _out_dir := OUT_FALLBACK
var _main: Node
var _shot_index := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out_dir = str(args[0])
	var project_name := "Aya"
	if args.size() > 1:
		project_name = str(args[1])
	DirAccess.make_dir_recursive_absolute(_out_dir)

	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		printerr("CAPTURE_FAILED: main scene did not load")
		quit(1)
		return
	_main = packed.instantiate()
	root.add_child(_main)
	await _settle(12)
	_main.call("_show_view", "home")
	await _settle(8)
	await _shot("home")

	_main.call("_show_view", "library")
	await _settle(10)
	await _shot("library")

	_main.call("_show_view", "workspace")
	await _settle(6)
	var project_id := _find_project_id(project_name)
	if project_id.is_empty():
		printerr("CAPTURE_WARNING: project %s not found" % project_name)
	else:
		_main.call("_open_project", project_id)
		await _settle(14)
		await _shot("workspace_character")
		await _capture_workspace_tabs()

	_main.call("_show_view", "settings")
	await _settle(10)
	await _shot("settings")

	_main.call("_open_help_center_v0203", "")
	await _settle(10)
	await _shot("help_center")

	print("CAPTURE_DONE: %d screenshots in %s" % [_shot_index, _out_dir])
	quit(0)


func _capture_workspace_tabs() -> void:
	var workspace: Node = _main.get("_workspace")
	if workspace == null:
		return
	var tabs: TabContainer = workspace.get("_tabs")
	if tabs == null:
		printerr("CAPTURE_WARNING: workspace tabs not found")
		return
	for index in range(tabs.get_tab_count()):
		var title := tabs.get_tab_title(index)
		if not title.to_lower().contains("front porch"):
			continue
		tabs.current_tab = index
		await _settle(10)
		await _shot("workspace_front_porch")
		var group_tabs: TabContainer = workspace.get("_front_porch_group_tabs_v0172")
		if group_tabs != null:
			for group_index in range(group_tabs.get_tab_count()):
				group_tabs.current_tab = group_index
				await _settle(6)
				var slug := _slug(group_tabs.get_tab_title(group_index))
				await _shot("front_porch_%s" % slug)
				if slug == "opening_state":
					await _capture_opening_state_tail(workspace, group_tabs)
		return


func _find_project_id(project_name: String) -> String:
	var index_result: Dictionary = CCFLibraryService.refresh_index(false)
	var rows: Array = index_result.get("rows", [])
	for row in rows:
		if str(row.get("name", "")).to_lower() == project_name.to_lower():
			return str(row.get("project_id", ""))
	return ""


func _slug(value: String) -> String:
	return value.to_lower().replace(" ", "_").replace("/", "_")


func _settle(frames: int) -> void:
	for _index in range(frames):
		await process_frame


func _shot(label: String) -> void:
	await process_frame
	# The viewport texture holds the last drawn frame; waiting for the draw
	# signal keeps a capture from lagging one navigation step behind.
	await RenderingServer.frame_post_draw
	await process_frame
	_shot_index += 1
	var path := "%s/%02d_%s.png" % [_out_dir, _shot_index, label]
	var image: Image = root.get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		printerr("CAPTURE_FAILED: could not write %s (%d)" % [path, error])
	else:
		print("CAPTURE: %s" % path)


# Scrolls the Opening State section to its newest rows so the capture proves
# the field exists in the built UI, not only in the service tests.
func _capture_opening_state_tail(workspace: Node, group_tabs: TabContainer) -> void:
	var page: Node = group_tabs.get_child(group_tabs.current_tab)
	var scroll := page as ScrollContainer
	if scroll == null:
		return
	var row := page.find_child("fp_afterglow_enabled_row_v0172", true, false) as Control
	if row == null:
		printerr("CAPTURE_WARNING: Afterglow row not found in the Opening State section")
		return
	scroll.ensure_control_visible(row)
	await _settle(8)
	await _shot("front_porch_afterglow_row")
