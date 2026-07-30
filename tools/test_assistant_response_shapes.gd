extends SceneTree

const SERVICE = preload("res://scripts/services/generation_service_v01310_hotfix.gd")


func _init() -> void:
	var service = SERVICE.new()

	_expect_equal(
		service._extract_content({"choices": [{"message": {"content": "{\"name\":\"A\"}"}}]}),
		'{"name":"A"}',
		"standard chat-completions content"
	)
	_expect_equal(
		service._extract_content({"choices": [{"message": {"content": [{"type": "output_text", "text": "{\"name\":\"B\"}"}]}}]}),
		'{"name":"B"}',
		"output_text content part"
	)
	_expect_equal(
		service._extract_content({"choices": [{"message": {"content": [{"type": "text", "text": {"value": "{\"name\":\"C\"}"}}]}}]}),
		'{"name":"C"}',
		"nested text value content part"
	)
	_expect_equal(
		service._extract_content({"choices": [{"message": {"content": ""}}, {"message": {"content": "{\"name\":\"D\"}"}}]}),
		'{"name":"D"}',
		"later non-empty choice"
	)
	_expect_equal(
		service._extract_content({"output_text": "{\"name\":\"E\"}"}),
		'{"name":"E"}',
		"top-level output_text"
	)
	_expect_equal(
		service._extract_content({"output": [{"type": "message", "content": [{"type": "output_text", "text": "{\"name\":\"F\"}"}]}]}),
		'{"name":"F"}',
		"Responses-style output message"
	)
	_expect_equal(
		service._extract_direct_reasoning_json(
			{"choices": [{"message": {"content": "", "reasoning_content": "{\"name\":\"G\"}"}}]},
			"object"
		),
		'{"name":"G"}',
		"direct JSON reasoning fallback"
	)
	_expect_equal(
		service._extract_direct_reasoning_json(
			{"choices": [{"message": {"content": "", "reasoning_content": "Thinking first, then maybe JSON."}}]},
			"object"
		),
		"",
		"prose reasoning is not treated as final output"
	)

	var length_diagnostic: String = service._empty_assistant_text_message(
		{
			"choices": [
				{
					"finish_reason": "length",
					"message": {"content": "", "reasoning_content": "Still thinking..."}
				}
			]
		}
	)
	if not length_diagnostic.contains("finish_reason=length"):
		_fail("Length-limited blank output should explain finish_reason=length.")
		return
	if not length_diagnostic.to_lower().contains("reasoning"):
		_fail("Reasoning-only blank output should mention reasoning token use.")
		return

	print("Assistant response shape regression passed.")
	quit(0)


func _expect_equal(actual: String, expected: String, label: String) -> void:
	if actual != expected:
		_fail("%s failed. Expected %s, got %s" % [label, expected, actual])


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
