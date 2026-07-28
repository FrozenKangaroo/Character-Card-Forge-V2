extends SceneTree


func _init() -> void:
	var template := CCFTemplateService.load_default_template()
	var contract := CCFGenerationContractService.contract_for_template(template)
	var field_rules_value: Variant = contract.get("field_rules", {})
	if not field_rules_value is Dictionary:
		_fail("Default generation contract has no field_rules dictionary.")
		return
	var field_rules: Dictionary = field_rules_value
	var description_value: Variant = field_rules.get("description", {})
	if not description_value is Dictionary:
		_fail("Default generation contract has no Description rule.")
		return
	var description_rule: Dictionary = description_value
	var description_labels_value: Variant = description_rule.get("required_labels", [])
	if not description_labels_value is Array:
		_fail("Default Description contract has no required_labels array.")
		return
	var description_labels: Array = description_labels_value
	for required_label in ["Age", "Appearance", "Outfit Style", "Distinguishing Features"]:
		if not description_labels.has(required_label):
			_fail("Default Description contract is missing required label: %s" % required_label)
			return

	var service := CCFTemplateContractGuardGenerationService.new()
	service._queue = [
		{
			"id": "dispatch-test",
			"payload": {
				"messages": [
					{"role": "system", "content": "test"},
					{"role": "user", "content": "base prompt"}
				]
			},
			"metadata": {}
		}
	]

	# This call mirrors the parity layer. v0.13.3 accidentally dispatched it to the
	# Mode & Style decorator because both helpers had the same method name.
	service._decorate_character_job("dispatch-test", contract)
	var contract_job: Dictionary = service._queue[0]
	var contract_metadata_value: Variant = contract_job.get("metadata", {})
	if not contract_metadata_value is Dictionary:
		_fail("Contract dispatch did not preserve job metadata.")
		return
	var contract_metadata: Dictionary = contract_metadata_value
	if not bool(contract_metadata.get("generation_contract_attached", false)):
		_fail("Template generation contract was not attached through the dispatch bridge.")
		return
	var stored_contract_value: Variant = contract_metadata.get("generation_contract", {})
	if not stored_contract_value is Dictionary or stored_contract_value.is_empty():
		_fail("Template generation contract metadata is empty after decoration.")
		return
	var prompt := _last_user_prompt(contract_job)
	if not prompt.contains("Generation completeness contract:") or not prompt.contains("Age"):
		_fail("Template contract text was not appended to the character-generation prompt.")
		return

	# This call mirrors the Mode & Style layer. It must add its own metadata without
	# replacing the already-attached generation contract.
	var mode_style := CCFModeStyleGenerationService.normalise_mode_style({})
	service._decorate_character_job("dispatch-test", mode_style)
	var styled_job: Dictionary = service._queue[0]
	var styled_metadata_value: Variant = styled_job.get("metadata", {})
	if not styled_metadata_value is Dictionary:
		_fail("Mode & Style dispatch did not preserve job metadata.")
		return
	var styled_metadata: Dictionary = styled_metadata_value
	if not styled_metadata.has("mode_style"):
		_fail("Mode & Style metadata was not attached through the dispatch bridge.")
		return
	var final_contract_value: Variant = styled_metadata.get("generation_contract", {})
	if not final_contract_value is Dictionary or final_contract_value.is_empty():
		_fail("Mode & Style decoration removed the template generation contract.")
		return

	print("Generation contract dispatch regression test passed.")
	quit(0)


func _last_user_prompt(job: Dictionary) -> String:
	var payload_value: Variant = job.get("payload", {})
	if not payload_value is Dictionary:
		return ""
	var messages_value: Variant = payload_value.get("messages", [])
	if not messages_value is Array or messages_value.is_empty():
		return ""
	var last_value: Variant = messages_value[messages_value.size() - 1]
	if not last_value is Dictionary:
		return ""
	return str(last_value.get("content", ""))


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
