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
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert(scene_source.contains("main_v0156.gd"), "The active scene must use v0.15.6.")
	print("v0.15.6 Collaborator rich-text artifact regression passed")
	quit(0)
