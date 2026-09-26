extends SceneTree

const READABILITY = preload(
	"res://scripts/services/personality_readability_service_v0212.gd"
)
const WORKSPACE_CURRENT = preload(
	"res://scripts/ui/workspace_current.gd"
)

const STRUCTURED_PERSONALITY := (
	"Personality structure:\n"
	+ "Mind: Loud, open, and shame-free by design. She explains: ordinary prose colons stay inline.\n"
	+ "Moral Alignment: Pragmatically fair with hard lines.\n"
	+ "Emotional Tendencies: Sunny, teasing, and unbothered by default."
)

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_visual_formatter()
	if not _failed:
		await _test_live_workspace()
	if _failed:
		quit(1)
		return
	print("V0212_PERSONALITY_READABILITY_OK")
	quit(0)


func _test_visual_formatter() -> void:
	var result := READABILITY.format_for_display(STRUCTURED_PERSONALITY)
	var display := str(result.get("display_text", ""))
	_require(
		display.contains("Personality structure:\n\nMind:")
		and display.contains("design. She explains: ordinary prose")
		and display.contains("lines.\n\nEmotional Tendencies:"),
		"Structured headings must receive visual spacing without splitting ordinary prose colons."
	)
	_require(
		str(result.get("stored_text", "")) == STRUCTURED_PERSONALITY
		and bool(result.get("stored_text_unchanged", false))
		and bool(result.get("visual_only", false)),
		"The formatter must return the exact source as its canonical stored text."
	)
	var inline := (
		"Mind: Decisive and bright. Moral Alignment: Kind but pragmatic. "
		+ "Speech Style: She says: exactly what she means."
	)
	var inline_display := str(
		READABILITY.format_for_display(inline).get("display_text", "")
	)
	_require(
		inline_display.contains("bright.\n\nMoral Alignment:")
		and inline_display.contains("pragmatic.\n\nSpeech Style:")
		and inline_display.contains("She says: exactly"),
		"Known headings may be separated when a model returns them inline, while sentence colons remain untouched."
	)
	var capabilities := READABILITY.capabilities()
	_require(
		bool(capabilities.get("exports_unchanged", false))
		and bool(capabilities.get("token_estimates_unchanged", false))
		and bool(capabilities.get("custom_template_headings_supported", false)),
		"The contract must explicitly remain presentation-only."
	)


func _test_live_workspace() -> void:
	var workspace := WORKSPACE_CURRENT.new()
	root.add_child(workspace)
	await process_frame
	await process_frame
	var project := CCFStorageService.new_project()
	var characters: Array = project.get("characters", []).duplicate(true)
	var record: Dictionary = (characters[0] as Dictionary).duplicate(true)
	var character: Dictionary = record.get("character", {}).duplicate(true)
	character["personality"] = STRUCTURED_PERSONALITY
	record["character"] = character
	characters[0] = record
	project["characters"] = characters
	workspace.load_project(
		project,
		CCFTemplateService.load_template("default"),
		CCFSettingsService.default_settings()
	)
	await process_frame
	await process_frame
	var preview := workspace.find_child(
		"PersonalityReadablePreviewV0212", true, false
	) as TextEdit
	var editor := workspace.find_child(
		"PersonalityReadablePreviewV0212RawEditor", true, false
	) as TextEdit
	var toggle := workspace.find_child(
		"PersonalityReadablePreviewV0212Toggle", true, false
	) as Button
	var hint := workspace.find_child(
		"PersonalityReadablePreviewV0212Hint", true, false
	) as Label
	if not _require(
		preview != null and editor != null and toggle != null and hint != null,
		"The live Personality field must provide readable and exact-text views."
	):
		return
	_require(
		preview.visible
		and not editor.visible
		and not preview.editable
		and preview.text.contains("Mind:")
		and preview.text.contains("\n\nMoral Alignment:")
		and toggle.text == "Edit text"
		and hint.visible,
		"Structured Personality text must open in a clearly labelled, read-only readable view."
	)
	workspace.call("_capture_all_fields")
	var captured: Dictionary = workspace.get("_project")
	_require(
		str(CCFStorageService.get_value_at_path(
			captured, "character.personality", ""
		)) == STRUCTURED_PERSONALITY,
		"Capturing the Workspace must never persist display-only blank lines."
	)
	var original_tokens := CCFCardInspectionServiceV0182.estimate_tokens(
		STRUCTURED_PERSONALITY
	)
	var captured_tokens := CCFCardInspectionServiceV0182.estimate_tokens(
		str(CCFStorageService.get_value_at_path(
			captured, "character.personality", ""
		))
	)
	_require(
		captured_tokens == original_tokens,
		"Readable view must not change the card's authored-token estimate."
	)
	var personality_field: Dictionary = {}
	for field_value in CCFTemplateService.generation_fields(
		CCFTemplateService.load_template("default")
	):
		if (
			field_value is Dictionary
			and str((field_value as Dictionary).get("path", ""))
			== "character.personality"
		):
			personality_field = (field_value as Dictionary).duplicate(true)
			break
	workspace.call(
		"_add_preview_row", personality_field, "", STRUCTURED_PERSONALITY
	)
	var generated_preview := workspace.find_child(
		"PersonalityGeneratedReadablePreviewV0212", true, false
	) as TextEdit
	var generated_editor := workspace.find_child(
		"PersonalityGeneratedReadablePreviewV0212RawEditor", true, false
	) as TextEdit
	_require(
		generated_preview != null
		and generated_editor != null
		and generated_preview.visible
		and not generated_editor.visible
		and generated_preview.text.contains("\n\nMoral Alignment:")
		and generated_editor.text == STRUCTURED_PERSONALITY,
		"The pre-apply generation review must use the same visual-only Personality view while retaining its editable proposal."
	)
	toggle.emit_signal("pressed")
	await process_frame
	_require(
		editor.visible and not preview.visible and toggle.text == "Readable view",
		"Edit text must reveal the exact canonical TextEdit without visual spacing."
	)
	var edited := STRUCTURED_PERSONALITY + "\nLoyalty: Earned slowly."
	editor.text = edited
	workspace.call("_capture_all_fields")
	captured = workspace.get("_project")
	_require(
		str(CCFStorageService.get_value_at_path(
			captured, "character.personality", ""
		)) == edited,
		"Edits must save exactly as authored rather than copying the formatted preview."
	)
	var capabilities := workspace.personality_readability_capabilities_v0212()
	_require(
		bool(capabilities.get("workspace_readable_view", false))
		and bool(capabilities.get("generation_preview_readable_view", false))
		and int(capabilities.get("template_heading_count", 0)) > 0,
		"The live Workspace must expose both readable Personality surfaces and template headings."
	)
	workspace.queue_free()
	await process_frame


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_failed = true
	push_error(message)
	return false
