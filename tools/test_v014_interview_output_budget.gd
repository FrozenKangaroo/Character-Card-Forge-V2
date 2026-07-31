extends SceneTree


func _init() -> void:
	var service := CCFGenerationServiceV014Hotfix1.new()

	var questions: Array = []
	for index in range(24):
		questions.append({
			"id": "question_%02d" % index,
			"label": "Question %02d" % index,
			"question": "Develop a useful planning answer for interview question %02d." % index,
			"required": true
		})

	var large_budget_payload := {
		"temperature": 0.8,
		"max_tokens": 384000,
		"messages": [
			{"role": "system", "content": "Original system prompt"},
			{"role": "user", "content": "Original character generation prompt"}
		]
	}
	var large_interview := service._build_interview_payload(
		large_budget_payload,
		"A deliberately detailed concept used to exercise the private interview stage.",
		questions,
		{},
		false
	)
	_assert_equal(
		int(large_interview.get("max_tokens", 0)),
		384000,
		"Private interview must preserve a large resolved Text-role output budget."
	)
	_assert_true(
		int(large_interview.get("max_tokens", 0)) > 2600,
		"Private interview must not reintroduce the legacy 2,600-token ceiling."
	)
	_assert_true(
		float(large_interview.get("temperature", 1.0)) <= 0.65,
		"Interview-specific temperature control should remain intact."
	)

	var modest_budget_payload := large_budget_payload.duplicate(true)
	modest_budget_payload["max_tokens"] = 1800
	var modest_interview := service._build_interview_payload(
		modest_budget_payload,
		"Short concept.",
		questions.slice(0, 3),
		{},
		false
	)
	_assert_equal(
		int(modest_interview.get("max_tokens", 0)),
		1800,
		"The hotfix must respect a deliberately smaller resolved profile budget rather than raising it."
	)

	var retry_interview := service._build_interview_payload(
		large_budget_payload,
		"A detailed concept.",
		questions.slice(0, 5),
		{"question_00": "Known answer"},
		true
	)
	_assert_equal(
		int(retry_interview.get("max_tokens", 0)),
		384000,
		"Missing-answer interview retries must preserve the same resolved output budget."
	)

	print("v0.14 interview output budget regression passed")
	quit(0)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_fail("%s Expected %s, got %s." % [message, str(expected), str(actual)])


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_fail(message)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
