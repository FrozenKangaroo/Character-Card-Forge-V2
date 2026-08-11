extends SceneTree


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/character_collaborator_window_v0156.gd")
	assert(source.contains("_render_heading_v0154"), "v0.15.6 must override heading rendering.")
	assert(source.contains("_render_semantic_bullet_v0154"), "v0.15.6 must override semantic-label rendering.")
	assert(source.contains("_render_inline_v0156"), "v0.15.6 must provide artifact-safe inline emphasis.")
	assert(not source.contains("body.push_bold()"), "v0.15.6 Collaborator renderer must not invoke synthetic bold glyph rendering.")
	assert(source.contains("push_color"), "v0.15.6 must preserve semantic colour styling.")
	assert(source.contains("push_font_size"), "v0.15.6 headings must preserve size hierarchy.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v0156.gd")
	assert(workspace_source.contains("CHARACTER_COLLABORATOR_WINDOW_V0156"), "v0.15.6 Workspace must install the fixed Collaborator window.")
	if not _active_main_shell_inherits("res://scripts/main_v0156.gd"):
		push_error("The active main-shell inheritance chain no longer retains the v0.15.6 Collaborator rich-text layer.")
		quit(1)
		return
	print("v0.15.6 Collaborator rich-text artifact regression passed")
	quit(0)


func _active_main_shell_inherits(target_script: String) -> bool:
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	var scene_regex := RegEx.new()
	if scene_regex.compile('\\[ext_resource path="(res://scripts/main[^\"]*\\.gd)" type="Script" id="1_main"\\]') != OK:
		return false
	var scene_match := scene_regex.search(scene_source)
	if scene_match == null:
		return false
	var extends_regex := RegEx.new()
	if extends_regex.compile('(?m)^extends\\s+"(res://[^\"]+\\.gd)"\\s*$') != OK:
		return false
	var current := scene_match.get_string(1)
	var visited: Dictionary = {}
	for _index in range(64):
		if current == target_script:
			return true
		if visited.has(current) or not FileAccess.file_exists(current):
			return false
		visited[current] = true
		var source_text := FileAccess.get_file_as_string(current)
		var extends_match := extends_regex.search(source_text)
		if extends_match == null:
			return false
		current = extends_match.get_string(1)
	return false
