extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0185_FRONT_PORCH_RELIABILITY_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _make_project() -> Dictionary:
	var project := CCFStorageService.new_project()
	var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
	metadata["name"] = "Front Porch Reliability Fixture"
	project["metadata"] = metadata
	var character_id := CCFStorageService.active_character_id(project)
	var character := CCFStorageService.get_character(project, character_id)
	var authored: Dictionary = character.get("character", {}).duplicate(true)
	authored["name"] = "Mara Finch"
	authored["description"] = "A careful courier who maps every safe route twice."
	authored["personality"] = "Practical, warm, patient, and quietly stubborn."
	authored["scenario"] = "Mara meets {{user}} beside a storm-closed bridge."
	authored["first_message"] = "The bridge is gone, but I know another way."
	character["character"] = authored
	var character_metadata: Dictionary = character.get("metadata", {}).duplicate(true)
	character_metadata["name"] = "Mara Finch"
	character["metadata"] = character_metadata
	var characters: Array = project.get("characters", []).duplicate(true)
	characters[0] = character
	project["characters"] = characters
	return project


func _find_button(root: Node, button_text: String) -> Button:
	for node in root.find_children("*", "Button", true, false):
		if node is Button and node.text == button_text:
			return node
	return null


func _find_tab(root: Node, title_text: String) -> bool:
	for node in root.find_children("*", "TabContainer", true, false):
		if not node is TabContainer:
			continue
		for index in range((node as TabContainer).get_tab_count()):
			if (node as TabContainer).get_tab_title(index) == title_text:
				return true
	return false


func _run() -> void:
	var capabilities := CCFFrontPorchSyncServiceV0185.capabilities_v0185()
	if not _require(
		bool(capabilities.get("credential_safe_diagnostics", false))
		and bool(capabilities.get("behavior_based_capabilities", false))
		and bool(capabilities.get("sequential_deployment_queue", false))
		and bool(capabilities.get("compare_before_change", false))
		and not bool(capabilities.get("automatic_overwrite", true))
		and not bool(capabilities.get("raw_database_writes", true))
		and not bool(capabilities.get("credentials_persisted", true)),
		"v0.18.5 must expose its diagnostics, sync and queue safety boundaries."
	):
		return

	var project := _make_project()
	var character_id := CCFStorageService.active_character_id(project)
	var fingerprint := CCFFrontPorchSyncServiceV0185.character_fingerprint(project, character_id)
	var same_fingerprint := CCFFrontPorchSyncServiceV0185.character_fingerprint(project.duplicate(true), character_id)
	if not _require(
		not fingerprint.is_empty() and fingerprint == same_fingerprint,
		"Card fingerprints must be deterministic."
	):
		return
	var recorded := CCFFrontPorchSyncServiceV0185.record_exchange(
		project, character_id, "front-porch-mara", fingerprint
	)
	var linked_project: Dictionary = recorded.get("project", {})
	var binding := CCFFrontPorchSyncServiceV0185.binding_for_character(
		linked_project, character_id
	)
	var exported := CCFCardFormatService.export_character_v2(linked_project, character_id)
	if not _require(
		bool(recorded.get("ok", false))
		and str(binding.get("remote_id", "")) == "front-porch-mara"
		and str(binding.get("last_exchanged_fingerprint", "")) == fingerprint
		and not JSON.stringify(exported).contains(CCFFrontPorchSyncServiceV0185.BINDING_KEY),
		"Install identity and fingerprints must persist privately outside portable card exports."
	):
		return

	if not _require(
		CCFFrontPorchSyncServiceV0185.sync_state(fingerprint, fingerprint, fingerprint) == CCFFrontPorchSyncServiceV0185.STATE_INSTALLED
		and CCFFrontPorchSyncServiceV0185.sync_state("local-new", fingerprint, fingerprint) == CCFFrontPorchSyncServiceV0185.STATE_MODIFIED_LOCALLY
		and CCFFrontPorchSyncServiceV0185.sync_state(fingerprint, fingerprint, "remote-new") == CCFFrontPorchSyncServiceV0185.STATE_CHANGED_REMOTELY
		and CCFFrontPorchSyncServiceV0185.sync_state("local-new", fingerprint, "remote-new") == CCFFrontPorchSyncServiceV0185.STATE_DIVERGED
		and CCFFrontPorchSyncServiceV0185.sync_state(fingerprint, "", "") == CCFFrontPorchSyncServiceV0185.STATE_NOT_INSTALLED,
		"The five promised Front Porch sync states must classify independently."
	):
		return

	var remote_card := exported.duplicate(true)
	var remote_data: Dictionary = remote_card.get("data", {}).duplicate(true)
	remote_data["scenario"] = "Front Porch changed this scenario."
	remote_card["data"] = remote_data
	var differences := CCFFrontPorchSyncServiceV0185.field_differences(
		exported, remote_card
	)
	if not _require(
		differences.size() == 1
		and str(differences[0].get("field", "")) == "scenario"
		and CCFFrontPorchSyncServiceV0185.differences_text(differences).contains("Front Porch changed"),
		"Compare must expose complete authored field differences before either direction is applied."
	):
		return

	var saved := CCFStorageService.save_project(linked_project)
	if not _require(bool(saved.get("ok", false)), "The linked fixture project must save."):
		return
	CCFFrontPorchSyncServiceV0185.replace_deployment_queue([])
	var queued := CCFFrontPorchSyncServiceV0185.enqueue_deployment({
		"project_id": str(linked_project.get("project_id", "")),
		"character_id": character_id,
		"action": "update",
		"remote_id": "front-porch-mara"
	})
	CCFFrontPorchSyncServiceV0185.append_deployment_report({
		"summary": "Focused regression",
		"outcomes": [{"status": "skipped", "name": "Mara Finch", "message": "Explicit review required."}]
	})
	if not _require(
		bool(queued.get("ok", false))
		and CCFFrontPorchSyncServiceV0185.deployment_queue().size() == 1
		and CCFFrontPorchSyncServiceV0185.deployment_report_text().contains("SKIPPED")
		and CCFFrontPorchSyncServiceV0185.deployment_report_text().contains("Explicit review required"),
		"Deployment queue and per-item outcome history must persist."
	):
		return

	var eligible_character := CCFStorageService.get_character(linked_project, character_id)
	var ineligible := CCFFrontPorchSyncServiceV0185.source_update_eligibility(eligible_character)
	eligible_character["interoperability"] = {"source_url": "https://example.test/public-card.json"}
	var eligible := CCFFrontPorchSyncServiceV0185.source_update_eligibility(eligible_character)
	if not _require(
		not bool(ineligible.get("eligible", true))
		and bool(eligible.get("eligible", false)),
		"Advisory update checks must require a stable public source ID or URL."
	):
		return

	var window := CCFImportExportWindowV0185.new()
	window.visible = false
	get_root().add_child(window)
	await process_frame
	await process_frame
	window.open_for_project(linked_project, CCFSettingsService.default_settings(), character_id)
	await process_frame
	var window_caps := window.front_porch_sync_capabilities_v0185()
	if not _require(
		_find_tab(window, "Front Porch Sync")
		and _find_button(window, "Run Connection Diagnostics") != null
		and _find_button(window, "Compare Selected") != null
		and _find_button(window, "Run Queue Sequentially") != null
		and bool(window_caps.get("compare_required_for_update", false)),
		"Front Porch Sync must provide diagnostics, previewed compare and an explicit sequential queue UI."
	):
		return
	window.queue_free()
	await process_frame

	var library := CCFLibraryV0185View.new()
	library.size = Vector2(1600, 900)
	get_root().add_child(library)
	await process_frame
	await process_frame
	var library_caps := library.front_porch_library_capabilities_v0185()
	if not _require(
		bool(library_caps.get("remote_state_filter", false))
		and bool(library_caps.get("deployment_queue_filter", false))
		and not bool(library_caps.get("library_browsing_network_requests", true)),
		"Library filters must expose private remote and deployment states without background network access."
	):
		return
	library.queue_free()
	CCFFrontPorchSyncServiceV0185.replace_deployment_queue([])
	await process_frame
	print("V0185_FRONT_PORCH_RELIABILITY_OK")
	quit(0)
