extends SceneTree

var _finished := false


func _init() -> void:
	var watchdog := create_timer(10.0)
	watchdog.timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_tests")


func _run_tests() -> void:
	var concept := "Lila is a 23-year-old woman with G-cup breasts. She says `No shortcuts` when challenged."
	var plan := CCFConceptFidelityService.build_plan(concept, "Lila")
	var anchors_value: Variant = plan.get("anchors", [])
	if not anchors_value is Array or anchors_value.size() < 3:
		_fail("Concept fidelity plan did not capture the expected name/age/measurement anchors.")
		return

	var good_candidate := {
		"name": "Lila",
		"description": "Age: twenty-three years old\nAppearance: Curvy build with G-cup breasts.",
		"personality": "Mind: Confident and playful."
	}
	var good_report := CCFConceptFidelityService.validate_candidate(plan, good_candidate)
	if bool(good_report.get("clear_drift", true)):
		_fail("Equivalent age wording and G-cup formatting were incorrectly treated as clear drift.")
		return

	var drift_candidate := {
		"name": "Mia",
		"description": "Age: 27 years old\nAppearance: Curvy build.",
		"personality": "Mind: Confident and playful."
	}
	var drift_report := CCFConceptFidelityService.validate_candidate(plan, drift_candidate)
	if not bool(drift_report.get("clear_drift", false)):
		_fail("Clear name/age/measurement drift was not detected.")
		return
	if int(drift_report.get("critical_missing_count", 0)) < 3:
		_fail("Expected all three critical fidelity markers to be missing in the drift fixture.")
		return
	var retry_text := CCFConceptFidelityService.retry_instructions(drift_report)
	for expected in ["Lila", "23 years old", "G-cup"]:
		if not retry_text.contains(expected):
			_fail("Fidelity retry instructions are missing marker: %s" % expected)
			return

	# Quoted/backticked literals are diagnostics only. Missing one may be useful to show
	# later in Preview, but it must not trigger an automatic character rewrite by itself.
	var advisory_plan := CCFConceptFidelityService.build_plan("A character whose motto is `Stay curious`.")
	var advisory_report := CCFConceptFidelityService.validate_candidate(
		advisory_plan,
		{"name": "Rin", "description": "Age: 24", "personality": "Mind: Inquisitive."}
	)
	if bool(advisory_report.get("clear_drift", false)):
		_fail("Advisory quoted markers must not trigger automatic fidelity retry.")
		return
	if int(advisory_report.get("advisory_missing_count", 0)) < 1:
		_fail("Missing advisory literal was not recorded for diagnostics.")
		return

	# Verify the generation service stores the plan independently from the template
	# contract and Mode & Style metadata, avoiding another decorator-collision regression.
	var service := CCFConceptFidelityGenerationService.new()
	service._queue = [
		{
			"id": "fidelity-test",
			"payload": {
				"messages": [
					{"role": "system", "content": "test"},
					{"role": "user", "content": "base prompt"}
				]
			},
			"metadata": {}
		}
	]
	service._decorate_job_with_fidelity_plan("fidelity-test", plan)
	var decorated: Dictionary = service._queue[0]
	var stored_plan_value: Variant = decorated.get("concept_fidelity_plan", {})
	if not stored_plan_value is Dictionary or stored_plan_value.is_empty():
		_fail("Generation job did not retain its concept fidelity plan.")
		return
	var metadata_value: Variant = decorated.get("metadata", {})
	if not metadata_value is Dictionary:
		_fail("Generation job did not retain fidelity metadata.")
		return
	var metadata: Dictionary = metadata_value
	var plan_summary_value: Variant = metadata.get("concept_fidelity_plan", {})
	if not plan_summary_value is Dictionary or int(plan_summary_value.get("anchor_count", 0)) < 3:
		_fail("Concept fidelity plan summary was not stored in generation metadata.")
		return

	_finished = true
	print("Concept fidelity regression test passed.")
	quit(0)


func _on_watchdog_timeout() -> void:
	if _finished:
		return
	push_error("Concept fidelity regression test timed out before completion.")
	quit(1)


func _fail(message: String) -> void:
	_finished = true
	push_error(message)
	quit(1)
