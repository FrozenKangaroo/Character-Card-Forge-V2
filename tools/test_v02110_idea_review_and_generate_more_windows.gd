extends SceneTree

const REVIEW = preload("res://scripts/services/idea_final_review_service_v0218.gd")
const DIVERSITY = preload("res://scripts/services/idea_diversity_guardrails_v0214.gd")
const PRESENTATION = preload(
	"res://scripts/services/idea_review_presentation_service_v02110.gd"
)
const WINDOW_STATE = preload("res://scripts/services/tool_window_state_service.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_presentation_and_contextual_geometry()
	await _test_live_review_and_generate_more_windows()
	if _failed:
		quit(1)
		return
	print("V02110_IDEA_REVIEW_AND_GENERATE_MORE_WINDOWS_OK")
	quit(0)


func _test_presentation_and_contextual_geometry() -> void:
	var idea := _idea("Inspectable Idea", "A complete generated concept for review.")
	idea["opening_beat"] = "An extra meaningful schema field."
	var sections := PRESENTATION.detail_sections({"idea": idea})
	var labels: Array[String] = []
	for section_value in sections:
		labels.append(str((section_value as Dictionary).get("label", "")))
	_require(
		labels.slice(0, 6) == [
			"Concept", "Character Name", "Character Role", "Source Anchor",
			"Roleplay Hook", "Tags"
		]
		and "Opening Beat" in labels
		and str(sections[0].get("text", "")) == "A complete generated concept for review.",
		"Review presentation must expose the real record idea with Concept first and preserve other meaningful generated fields."
	)

	var screens: Array[Rect2i] = [
		Rect2i(0, 0, 1920, 1040),
		Rect2i(1920, 0, 2560, 1400)
	]
	var valid_saved := Rect2i(2100, 100, 900, 700)
	var offscreen_saved := Rect2i(-5000, -5000, 900, 700)
	_require(
		WINDOW_STATE.screen_for_saved_geometry(valid_saved, screens) == 1
		and WINDOW_STATE.screen_for_saved_geometry(offscreen_saved, screens) == -1,
		"Valid saved geometry must keep its display while completely off-screen geometry must be rejected."
	)
	var reference := Rect2i(2200, 120, 1100, 820)
	var contextual := WINDOW_STATE.contextual_geometry(
		Vector2i(980, 760), Vector2i(720, 520), reference, screens[1]
	)
	var contextual_rect := Rect2i(
		contextual.get("position", Vector2i.ZERO),
		contextual.get("size", Vector2i.ZERO)
	)
	_require(
		screens[1].encloses(contextual_rect),
		"Unsaved contextual tools must be centred and clamped on the reference window's display."
	)
	var short_screen := Rect2i(0, 0, 900, 360)
	var short_geometry := WINDOW_STATE.contextual_geometry(
		Vector2i(720, 520), Vector2i(480, 320), Rect2i(100, 30, 650, 280), short_screen
	)
	var short_rect := Rect2i(
		short_geometry.get("position", Vector2i.ZERO),
		short_geometry.get("size", Vector2i.ZERO)
	)
	_require(
		short_screen.encloses(short_rect) and short_rect.size.y <= 312,
		"Contextual geometry must shrink safely when the usable display height is smaller than the preferred dialog."
	)


func _test_live_review_and_generate_more_windows() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _require(packed != null, "The current application scene must load."):
		return
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	await process_frame
	var workspace: CCFWorkspaceCurrent = app.get("_workspace")
	var generator: CCFIdeaGeneratorWindowCurrent = workspace.get(
		"_idea_generator_v01532"
	)
	var project: Dictionary = (workspace.get("_project") as Dictionary).duplicate(true)
	project["project_id"] = "v02110-live"
	workspace.set("_project", project)

	var session := DIVERSITY.create_session(1, 1, true, "off", true, {
		"prompt_mode": "primary_prompt",
		"seed_text": "Inspect this complete Idea."
	})
	session["project_id_snapshot"] = "v02110-live"
	session["seed_snapshot"] = "Inspect this complete Idea."
	DIVERSITY.record_batch(session, [
		_idea("Inspectable Idea", "A complete generated concept for review.")
	])
	workspace.set("_idea_diversity_session_v0214", session)
	var clusters: Array[Dictionary] = []
	workspace.call("_show_idea_similarity_review_v0214", clusters)
	await process_frame
	var keep := workspace.find_child("KeepFinalIdeaV0218_idea-001", true, false) as CheckBox
	var toggle := workspace.find_child(
		"ToggleFinalIdeaDetailsV02110_idea-001", true, false
	) as Button
	var details := workspace.find_child(
		"FinalIdeaDetailsV02110_idea-001", true, false
	) as Control
	var expand_all := workspace.find_child(
		"ExpandAllFinalIdeasV02110", true, false
	) as Button
	var collapse_all := workspace.find_child(
		"CollapseAllFinalIdeasV02110", true, false
	) as Button
	_require(
		keep != null and keep.button_pressed
		and toggle != null and toggle.text == "Show Idea"
		and details != null and not details.visible
		and expand_all != null and collapse_all != null,
		"Every review candidate must start checked with its complete Idea collapsed and global expansion controls available."
	)
	if toggle != null:
		toggle.button_pressed = true
	await process_frame
	_require(
		details != null and details.visible and toggle.text == "Hide Idea"
		and keep != null and keep.button_pressed,
		"Showing an Idea must reveal its read-only details without changing retention selection."
	)
	workspace.call("_set_final_review_details_expanded_v02110", false)
	_require(
		details != null and not details.visible
		and toggle != null and toggle.text == "Show Idea"
		and keep != null and keep.button_pressed,
		"Collapse All must affect presentation only, never the keep checkbox."
	)

	var curation := REVIEW.create_curation_session(session, {})
	workspace.set("_idea_curation_session_v0218", curation)
	workspace.call("_open_generate_more_dialog_v0218")
	await process_frame
	var dialog := workspace.get("_idea_generate_more_dialog_v0218") as Window
	var body_scroll := generator.find_child(
		"GenerateMoreBodyScrollV02110", true, false
	) as ScrollContainer
	var footer := generator.find_child(
		"GenerateMoreActionFooterV02110", true, false
	) as Control
	var cancel := generator.find_child("CancelGenerateMoreV02110", true, false) as Button
	var confirm := generator.find_child("ConfirmGenerateMoreV02110", true, false) as Button
	var instruction := workspace.get("_idea_generate_more_instruction_v0219") as TextEdit
	_require(
		dialog != null and dialog.get_parent() == generator
		and dialog.transient and dialog.force_native
		and body_scroll != null and footer != null
		and cancel != null and confirm != null
		and instruction != null and instruction.text == "Inspect this complete Idea.",
		"Generate More must be owned by the Idea Generator and retain the v0.21.9 editable instruction inside a scrollable body with explicit actions."
	)
	if dialog != null:
		dialog.size = Vector2i(520, 340)
	await process_frame
	_require(
		footer != null and footer.visible
		and cancel != null and cancel.visible
		and confirm != null and confirm.visible
		and footer.position.y + footer.size.y <= dialog.size.y,
		"Generate More actions must remain visible and reachable at a small usable window height."
	)
	workspace.call("_cancel_generate_more_dialog_v0219")
	dialog.hide()
	app.queue_free()
	await process_frame


func _idea(title: String, concept: String) -> Dictionary:
	return {
		"title": title,
		"character_name": "Mika",
		"character_role": "{{user}}'s returning former colleague",
		"source_anchor": "former colleague",
		"roleplay_hook": "Mika arrives with a choice only {{user}} can make.",
		"concept": concept,
		"tags": ["reunion", "choice"]
	}


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_failed = true
	push_error(message)
	return false
