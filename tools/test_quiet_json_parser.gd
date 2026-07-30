extends SceneTree


func _init() -> void:
	var service := CCFGenerationServiceV0135.new()
	var valid := service._parse_job_output_with_diagnostics('{"name":"Eleanor"}', "object")
	if not bool(valid.get("ok", false)):
		_fail("Valid JSON should parse successfully.")
		return
	var valid_data: Variant = valid.get("data", {})
	if not valid_data is Dictionary or str(valid_data.get("name", "")) != "Eleanor":
		_fail("Valid JSON returned the wrong data.")
		return

	# Reproduces the provider failure shape reported at runtime: a quoted value ends
	# before the model closes the JSON string/object. This must become an ordinary
	# parse result so the existing JSON-repair request can run, not an engine error.
	var malformed := service._parse_job_output_with_diagnostics('{"answers":{"identity":"A young woman\nwith an unfinished response}', "object")
	if bool(malformed.get("ok", false)):
		_fail("Unterminated JSON should not be accepted as valid output.")
		return
	var diagnostic := str(malformed.get("diagnostic", ""))
	if diagnostic.is_empty():
		_fail("Malformed JSON should return a diagnostic for the repair pipeline.")
		return

	print("Quiet JSON parser regression passed.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
