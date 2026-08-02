class_name CCFCharacterCollaboratorWindowV0156
extends "res://scripts/ui/character_collaborator_window_v0155.gd"


func _render_heading_v0154(body: RichTextLabel, text: String, level: int) -> void:
	# Avoid RichTextLabel's synthetic bold path here. On some Linux/font stacks
	# push_bold() can produce dark vertical glyph artifacts when combined with
	# coloured text. Size + colour still provide a strong visual hierarchy.
	var size_value := 24 - ((level - 1) * 2)
	var heading_color := Color(0.90, 0.69, 1.0) if level >= 3 else Color(0.69, 0.80, 1.0)
	body.push_font_size(size_value)
	body.push_color(heading_color)
	_render_inline_v0156(body, text.strip_edges())
	body.pop()
	body.pop()


func _render_semantic_bullet_v0154(body: RichTextLabel, line: String) -> bool:
	var payload := line.substr(2)
	if not payload.begins_with("**"):
		return false
	var close_index := payload.find("**", 2)
	if close_index <= 2:
		return false
	var label_text := payload.substr(2, close_index - 2).strip_edges()
	var rest := payload.substr(close_index + 2).strip_edges()
	var semantic_key := label_text.trim_suffix(":").to_lower()
	body.push_color(_semantic_color_v0154(semantic_key))
	body.add_text("• %s" % label_text)
	body.pop()
	if not rest.is_empty():
		body.add_text(" ")
		_render_inline_v0156(body, rest)
	return true


func _render_inline_v0154(body: RichTextLabel, text: String) -> void:
	_render_inline_v0156(body, text)


func _render_inline_v0156(body: RichTextLabel, text: String) -> void:
	# Preserve Markdown-style emphasis without invoking synthetic bold. Bold spans
	# use a brighter theme-safe tint while italics continue using native italics.
	var cursor := 0
	while cursor < text.length():
		if text.substr(cursor, 2) == "**":
			var bold_end := text.find("**", cursor + 2)
			if bold_end >= 0:
				body.push_color(Color(0.93, 0.88, 1.0))
				body.add_text(text.substr(cursor + 2, bold_end - cursor - 2))
				body.pop()
				cursor = bold_end + 2
				continue
		if text.substr(cursor, 1) == "*":
			var italic_end := text.find("*", cursor + 1)
			if italic_end >= 0:
				body.push_italics()
				body.add_text(text.substr(cursor + 1, italic_end - cursor - 1))
				body.pop()
				cursor = italic_end + 1
				continue
		var next_marker := text.find("*", cursor)
		if next_marker < 0:
			body.add_text(text.substr(cursor))
			break
		if next_marker > cursor:
			body.add_text(text.substr(cursor, next_marker - cursor))
			cursor = next_marker
		else:
			body.add_text("*")
			cursor += 1
