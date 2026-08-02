extends SceneTree


func _init() -> void:
	var v01413_source := FileAccess.get_file_as_string("res://scripts/services/generation_service_v01413.gd")
	assert(
		v01413_source.contains('extends "res://scripts/services/generation_service_v0135.gd"'),
		"v0.14.13 must extend the v0.13.5 parity stack instead of the bare generation service."
	)

	var service := CCFGenerationServiceV01516.new()
	assert(service is CCFParityGenerationService, "The active v0.15.16 service must retain semantic completeness validation/repair.")
	assert(service is CCFInterviewGenerationService, "The active v0.15.16 service must retain Interview/Q&A generation.")
	assert(service is CCFBuilderPrecedenceGenerationService, "The active v0.15.16 service must retain Builder precedence.")
	assert(service is CCFModeStyleGenerationService, "The active v0.15.16 service must retain Mode & Style generation.")
	assert(service is CCFTemplateContractGuardGenerationService, "The active v0.15.16 service must retain fail-closed template-contract enforcement.")
	assert(service is CCFConceptFidelityGenerationService, "The active v0.15.16 service must retain concept-fidelity checks.")
	assert(service.has_method("queue_collaborator_reply"), "Restoring the parity stack must not remove Character Collaborator support.")
	assert(service.has_method("queue_collaborator_blueprint"), "Restoring the parity stack must not remove Blueprint handoff support.")

	var capabilities: Dictionary = service.generation_pipeline_capabilities_v01516()
	for key in [
		"template_contract",
		"semantic_repair",
		"interview",
		"builder_precedence",
		"mode_style",
		"concept_fidelity",
		"collaborator",
		"blueprint_handoff"
	]:
		assert(bool(capabilities.get(key, false)), "Restored generation capability is missing: %s" % key)

	# Exercise the actual inherited contract decorator through the v0.15.16 leaf.
	# This catches the kind of runtime-composition regression that the older unit
	# test missed by instantiating the contract guard directly.
	service._queue = [
		{
			"id": "v01516-contract-test",
			"payload": {
				"messages": [
					{"role": "system", "content": "test"},
					{"role": "user", "content": "base character prompt"}
				]
			},
			"metadata": {}
		}
	]
	var template := CCFTemplateService.load_default_template()
	var contract := CCFGenerationContractService.contract_for_template(template)
	service._decorate_character_job("v01516-contract-test", contract)
	var decorated_job: Dictionary = service._queue[0]
	var metadata_value: Variant = decorated_job.get("metadata", {})
	assert(metadata_value is Dictionary, "Restored contract decoration must preserve metadata.")
	var metadata: Dictionary = metadata_value
	assert(bool(metadata.get("generation_contract_attached", false)), "The real v0.15.16 service must attach the active template contract.")
	var prompt := _last_user_prompt(decorated_job)
	assert(prompt.contains("Generation completeness contract:"), "The active v0.15.16 prompt must include the semantic generation contract.")
	assert(prompt.contains("Age") and prompt.contains("Appearance"), "Default Description Generation Components must be present in the active contract prompt.")
	assert(prompt.contains("Mind") and prompt.contains("Relationship Behavior toward {{user}}"), "Default Personality Generation Components must be present in the active contract prompt.")

	# Prove the validator rejects structurally flattened output. The model is not
	# allowed to bypass configured components merely because its JSON is valid.
	var flattened := {
		"name": "Pipeline Test",
		"description": "A detailed but completely unlabelled physical description.",
		"personality": "A detailed but completely unlabelled personality profile.",
		"scenario": "A valid scenario with enough content to be meaningful.",
		"first_message": "A valid opening message with enough content to be meaningful."
	}
	var report := CCFGenerationContractService.validate_generated_data(flattened, contract)
	assert(not bool(report.get("ok", true)), "Flattened output must fail the restored active-template contract.")

	var workspace_source := FileAccess.get_file_as_string("res://scripts/ui/workspace_v01516.gd")
	assert(workspace_source.contains("queue_character_generation"), "Generate Character must route through the restored parity pipeline.")
	assert(not workspace_source.contains('call(\n\t\t"queue_full_character_synthesis"'), "Generate Character must not use the v0.15.12 unvalidated synthesis shortcut.")
	assert(workspace_source.contains("GENERATION_SERVICE_V01516"), "Workspace must install the v0.15.16 generation service.")

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01516.gd")
	assert(main_source.contains('BUILD_DISPLAY_VERSION_V01516 := "0.15.16"'), "The v0.15.16 shell must expose its build version.")
	assert(_active_shell_inherits_v01516(), "The active scene must use v0.15.16 or a later shell inheriting from it.")

	service.free()
	print("v0.15.16 generation pipeline restoration regression passed")
	quit(0)


func _last_user_prompt(job: Dictionary) -> String:
	var payload_value: Variant = job.get("payload", {})
	if not payload_value is Dictionary:
		return ""
	var messages_value: Variant = (payload_value as Dictionary).get("messages", [])
	if not messages_value is Array or messages_value.is_empty():
		return ""
	var message_value: Variant = messages_value[messages_value.size() - 1]
	if not message_value is Dictionary:
		return ""
	return str((message_value as Dictionary).get("content", ""))


func _active_shell_inherits_v01516() -> bool:
	var scene_source := FileAccess.get_file_as_string("res://scenes/main.tscn")
	var marker := "res://scripts/"
	var marker_at := scene_source.find(marker)
	if marker_at < 0:
		return false
	var end_at := scene_source.find("\"", marker_at)
	if end_at < 0:
		return false
	var path := scene_source.substr(marker_at, end_at - marker_at)
	for _depth in range(20):
		if path == "res://scripts/main_v01516.gd":
			return true
		if not FileAccess.file_exists(path):
			return false
		var source := FileAccess.get_file_as_string(path)
		var extends_marker := "extends \""
		var extends_at := source.find(extends_marker)
		if extends_at < 0:
			return false
		var start_at := extends_at + extends_marker.length()
		var next_end := source.find("\"", start_at)
		if next_end < 0:
			return false
		path = source.substr(start_at, next_end - start_at)
	return false
