extends SceneTree

const TEST_USER_DATA_ISOLATION = preload("res://tools/test_user_data_isolation.gd")
var _test_user_data_isolation := TEST_USER_DATA_ISOLATION.activate(
	"v02115-collaborator-safe-handoff"
)

const SAFE_HANDOFF = preload(
	"res://scripts/services/collaborator_safe_handoff_service_v02115.gd"
)
const GENERATION_SERVICE = preload(
	"res://scripts/services/generation_service_current.gd"
)
const SETTINGS_VIEW = preload("res://scripts/ui/settings_view_current.gd")
const COLLABORATOR_WINDOW = preload(
	"res://scripts/ui/character_collaborator_window_current.gd"
)

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_strategy_is_independent()
	_test_complete_and_incomplete_blueprints()
	_test_hostile_partial_json_recovery()
	_test_service_jobs()
	_test_bounded_tail_repair_request()
	await _test_settings_surface_and_current_window()
	if _failed:
		quit(1)
		return
	print("V02115_COLLABORATOR_SAFE_HANDOFF_OK")
	quit(0)


func _test_strategy_is_independent() -> void:
	var settings := {
		"generation": {
			"generation_strategy": "fast_full",
			"collaborator_handoff_strategy": "safe_section",
		}
	}
	_require(
		SAFE_HANDOFF.strategy_from_settings(settings) == "safe_section",
		"Collaborator handoff strategy must not inherit the ordinary character-generation strategy."
	)
	settings["generation"]["collaborator_handoff_strategy"] = "single_response"
	_require(
		SAFE_HANDOFF.strategy_from_settings(settings) == "single_response"
		and str(settings["generation"]["generation_strategy"]) == "fast_full",
		"Changing Collaborator handoff strategy must leave ordinary generation strategy untouched."
	)


func _test_complete_and_incomplete_blueprints() -> void:
	var bodies: Array[String] = []
	for index in range(SAFE_HANDOFF.BLUEPRINT_SECTIONS.size()):
		bodies.append("Complete accepted detail for section %d." % (index + 1))
	var complete := SAFE_HANDOFF.assembled_blueprint(bodies)
	var complete_assessment := SAFE_HANDOFF.assess_blueprint(complete)
	_require(
		bool(complete_assessment.get("complete", false)),
		"An assembled Safe Section blueprint must satisfy the completeness contract."
	)
	var accepted_only := SAFE_HANDOFF.assembled_accepted_sections(
		bodies.slice(0, 2)
	)
	_require(
		accepted_only.contains("RELATIONSHIP TO {{user}}")
		and not accepted_only.contains("APPEARANCE")
		and not accepted_only.contains("None established."),
		"Later section requests must see only genuinely accepted earlier sections, never placeholder future sections."
	)

	var malformed_bodies := bodies.duplicate(true)
	malformed_bodies[5] = "The setting establishes:"
	var malformed := SAFE_HANDOFF.assembled_blueprint(malformed_bodies)
	var assessment := SAFE_HANDOFF.assess_blueprint(malformed)
	var prefix := SAFE_HANDOFF.accepted_prefix(malformed, assessment)
	_require(
		not bool(assessment.get("complete", true))
		and int(assessment.get("first_problem_index", -1)) == 5
		and str(assessment.get("first_problem_heading", "")) == "SETTING / WORLD FACTS",
		"Completeness checking must identify the first malformed section."
	)
	_require(
		prefix == malformed.substr(0, malformed.find("SETTING / WORLD FACTS")).rstrip(" \t\r\n")
		and prefix.contains("HISTORY"),
		"Tail recovery must preserve the exact complete prefix and discard the malformed section onward."
	)
	var safe_prefix_sections := SAFE_HANDOFF.accepted_sections_before_problem(
		malformed_bodies, assessment
	)
	_require(
		safe_prefix_sections.size() == 5
		and str(safe_prefix_sections[4]) == str(malformed_bodies[4])
		and not safe_prefix_sections.has(malformed_bodies[5]),
		"Safe Section recovery must retain only complete sections before the malformed boundary."
	)

	var replacement_values: Array[String] = []
	for index in range(5, SAFE_HANDOFF.BLUEPRINT_SECTIONS.size()):
		replacement_values.append("Replacement detail %d." % index)
	var replacement_blocks: Array[String] = []
	for local_index in range(replacement_values.size()):
		var heading_index := local_index + 5
		replacement_blocks.append(
			"%s\n%s" % [
				SAFE_HANDOFF.section_heading(heading_index),
				replacement_values[local_index],
			]
		)
	var stitched := SAFE_HANDOFF.stitch_replacement_tail(
		prefix, "\n\n".join(replacement_blocks)
	)
	_require(
		bool(SAFE_HANDOFF.assess_blueprint(stitched).get("complete", false))
		and stitched.begins_with(prefix),
		"A replacement tail must restore completeness without rewriting accepted earlier sections."
	)


func _test_hostile_partial_json_recovery() -> void:
	var raw := (
		'{"suggested_name":"Rika","concept_prompt":"CHARACTER IDENTITY\\n'
		+ 'Rika says \\\"hello\\\" beside C:\\\\cards.\\n\\n'
		+ 'RELATIONSHIP TO {{user}}\\nTrusted friend.\\n\\n'
		+ 'APPEARANCE\\nHer unfinished coat has {'
	)
	var recovered := SAFE_HANDOFF.extract_partial_concept_from_json(raw)
	_require(
		recovered.contains('Rika says "hello" beside C:\\cards.')
		and recovered.contains("APPEARANCE\nHer unfinished coat has {"),
		"Partial JSON recovery must decode escaped quotes/backslashes and retain braces inside strings."
	)
	var assessment := SAFE_HANDOFF.assess_blueprint(recovered)
	_require(
		not bool(assessment.get("complete", true))
		and int(assessment.get("first_problem_index", -1)) == 2,
		"A truncated recovered concept must repair from its first incomplete section rather than replacing valid prior sections."
	)


func _test_service_jobs() -> void:
	var service := GENERATION_SERVICE.new()
	var profile := {
		"name": "Test",
		"base_url": "https://example.invalid/v1",
		"api_key": "test",
		"model": "test-model",
		"max_output_tokens": 4096,
		"context_window_tokens": 32000,
	}
	var messages := [
		{"role": "user", "content": "Create Rika as a long-established friend."}
	]
	var blueprint_result := service.queue_collaborator_blueprint(
		messages, [], "", profile, 0, "session-test"
	)
	_require(
		bool(blueprint_result.get("ok", false)),
		"The established single-response Collaborator blueprint path must remain available."
	)
	var queue_value: Variant = service.get("_queue")
	var queue: Array = queue_value if queue_value is Array else []
	var queued_blueprint: Dictionary = queue[0] if not queue.is_empty() else {}
	var blueprint_metadata: Dictionary = queued_blueprint.get("metadata", {})
	var payload: Dictionary = queued_blueprint.get("payload", {})
	var payload_text := JSON.stringify(payload.get("messages", []))
	_require(
		bool(blueprint_metadata.get("collaborator_blueprint_completeness_v02115", false))
		and payload_text.contains("COMPLETENESS CONTRACT")
		and payload_text.contains("None established."),
		"Single-response blueprints must carry the complete-heading contract needed for bounded tail repair."
	)

	var section_result := service.queue_collaborator_blueprint_section_v02115(
		messages, [], "", 0, "", profile, 0, "session-test", "blueprint"
	)
	_require(
		bool(section_result.get("ok", false)),
		"Safe Section mode must queue a provider-independent blueprint-section job."
	)
	queue_value = service.get("_queue")
	queue = queue_value if queue_value is Array else []
	var found_section := false
	for job_value in queue:
		if not job_value is Dictionary:
			continue
		var job: Dictionary = job_value
		if str(job.get("type", "")) != "collaborator_blueprint_section_v02115":
			continue
		var metadata: Dictionary = job.get("metadata", {})
		found_section = (
			int(metadata.get("collaborator_section_index_v02115", -1)) == 0
			and str(metadata.get("collaborator_section_heading_v02115", ""))
			== "CHARACTER IDENTITY"
		)
	_require(
		found_section,
		"Safe Section jobs must retain stable section identity and handoff metadata."
	)
	service.free()


func _test_bounded_tail_repair_request() -> void:
	var service := GENERATION_SERVICE.new()
	var section_values: Array[String] = [
		"Rika is the settled character.",
		"She is {{user}}'s trusted friend.",
		"She has dark hair and a red coat.",
		"She is energetic and",
	]
	var partial_blocks: Array[String] = []
	for index in range(section_values.size()):
		partial_blocks.append("%s\n%s" % [
			SAFE_HANDOFF.section_heading(index), section_values[index]
		])
	var partial := "\n\n".join(partial_blocks)
	service.set("_active_job", {
		"id": "repair-test",
		"type": "collaborator_blueprint",
		"label": "Blueprint",
		"payload": {"messages": []},
		"metadata": {
			"collaborator_blueprint_completeness_v02115": true,
			"collaborator_source_context_v02115": "ORIGINAL SOURCE FACT AFTER TRUNCATION",
		},
		"attempt": 1,
		"repair_attempts": 0,
		"max_retries": 0,
		"parse_mode": "object",
		"model": "test",
		"profile_name": "test",
	})
	service.call("_process_completed_content", JSON.stringify({
		"suggested_name": "Rika",
		"concept_prompt": partial,
		"alternate_greetings": [],
		"lorebook": {"name": "", "entries": []},
	}))
	var active_value: Variant = service.get("_active_job")
	var active: Dictionary = active_value if active_value is Dictionary else {}
	var metadata: Dictionary = active.get("metadata", {})
	var payload: Dictionary = active.get("payload", {})
	var request_text := JSON.stringify(payload.get("messages", []))
	var expected_boundary := partial.find("PERSONALITY & BEHAVIOUR")
	_require(
		bool(metadata.get("collaborator_tail_repair_active_v02115", false))
		and str(metadata.get("collaborator_tail_repair_prefix_v02115", ""))
		== partial.substr(0, expected_boundary).rstrip(" \t\r\n")
		and request_text.contains("PERSONALITY & BEHAVIOUR")
		and request_text.contains("ORIGINAL SOURCE FACT AFTER TRUNCATION"),
		"Single-response repair must request only the malformed section onward while retaining the original source and exact accepted prefix."
	)
	service.free()


func _test_settings_surface_and_current_window() -> void:
	var settings := CCFSettingsService.default_settings()
	settings["generation"]["generation_strategy"] = "fast_full"
	settings["generation"]["collaborator_handoff_strategy"] = "single_response"
	var view := SETTINGS_VIEW.new()
	root.add_child(view)
	await process_frame
	view.load_settings(settings)
	await process_frame
	var selector := view.find_child(
		"CollaboratorHandoffStrategyV02115", true, false
	) as OptionButton
	_require(
		selector != null
		and str(selector.get_selected_metadata()) == "single_response",
		"Settings must expose and load the independent Collaborator handoff strategy."
	)
	view.queue_free()

	var window := COLLABORATOR_WINDOW.new()
	root.add_child(window)
	await process_frame
	_require(
		window.has_method("_queue_safe_blueprint_section_v02115")
		and window.has_method("_discard_safe_handoff_for_project_change_v02115")
		and window.has_method("source_precedence_capabilities_v0171"),
		"The live Collaborator window must add project-scoped Safe Section handoff without losing current source-precedence behavior."
	)
	window.set("_safe_handoff_v02115", {
		"active": true,
		"project_id": "project-a",
	})
	window.update_project_context(
		{"project_id": "project-a"}, settings, "", {}
	)
	_require(
		not (window.get("_safe_handoff_v02115") as Dictionary).is_empty(),
		"Refreshing the same project must preserve its in-progress Safe Section handoff."
	)
	window.update_project_context(
		{"project_id": "project-b"}, settings, "", {}
	)
	_require(
		(window.get("_safe_handoff_v02115") as Dictionary).is_empty(),
		"Switching projects must discard the old project's in-progress Safe Section handoff."
	)
	window.queue_free()
	await process_frame


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
