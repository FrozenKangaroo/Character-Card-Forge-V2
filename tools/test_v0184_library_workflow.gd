extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V0184_LIBRARY_WORKFLOW_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _make_project(project_name: String, character_name: String) -> Dictionary:
	var project := CCFStorageService.new_project()
	var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
	metadata["name"] = project_name
	project["metadata"] = metadata
	var character_id := CCFStorageService.active_character_id(project)
	var record := CCFStorageService.get_character(project, character_id)
	var card: Dictionary = record.get("character", {}).duplicate(true)
	card["name"] = character_name
	card["description"] = "A careful archivist with a copper compass and a precise memory."
	card["personality"] = "Patient, observant, dryly funny, and protective of fragile histories."
	card["scenario"] = "%s meets {{user}} in a storm-damaged archive." % character_name
	card["first_message"] = "Hold the lantern steady; this page is older than either of us."
	record["character"] = card
	var character_metadata: Dictionary = record.get("metadata", {}).duplicate(true)
	character_metadata["name"] = character_name
	record["metadata"] = character_metadata
	var characters: Array = project.get("characters", []).duplicate(true)
	characters[0] = record
	project["characters"] = characters
	return project


func _find_button(root: Node, label_text: String) -> Button:
	for node in root.find_children("*", "Button", true, false):
		if node is Button and node.text == label_text:
			return node
	return null


func _find_menu(root: Node, label_text: String) -> MenuButton:
	for node in root.find_children("*", "MenuButton", true, false):
		if node is MenuButton and node.text == label_text:
			return node
	return null


func _run() -> void:
	var capabilities := CCFLibraryWorkflowServiceV0184.capabilities()
	if not _require(
		bool(capabilities.get("private_notes", false))
		and bool(capabilities.get("smart_collections", false))
		and bool(capabilities.get("exact_duplicate_evidence", false))
		and bool(capabilities.get("batch_export", false))
		and not bool(capabilities.get("automatic_merge_or_delete", true))
		and not bool(capabilities.get("direct_database_writes", true)),
		"v0.18.4 must advertise the complete private Library workflow without automatic destructive actions."
	):
		return

	var first_project := _make_project("Archive North", "Mira Vale")
	var second_project := _make_project("Archive South", "Mira Vale")
	var first_saved := CCFStorageService.save_project(first_project)
	var second_saved := CCFStorageService.save_project(second_project)
	var first_id := str(first_saved.get("project_id", ""))
	var second_id := str(second_saved.get("project_id", ""))
	if not _require(
		bool(first_saved.get("ok", false)) and bool(second_saved.get("ok", false)),
		"Fixture projects must save."
	):
		return

	var workflow_saved := CCFLibraryWorkflowServiceV0184.set_workflow_metadata(
		[first_id],
		{
			"workflow_state": "needs_review",
			"notes": "Private continuity note that must not enter a Character Card export.",
			"privacy_markers": ["adult", "private"]
		}
	)
	var first_loaded := CCFStorageService.load_project(first_id)
	var first_data: Dictionary = first_loaded.get("data", {})
	var workflow := CCFLibraryWorkflowServiceV0184.workflow_metadata(first_data)
	var first_character_id := CCFStorageService.active_character_id(first_data)
	var exported_card := CCFCardFormatService.export_character_v2(first_data, first_character_id)
	if not _require(
		bool(workflow_saved.get("ok", false))
		and str(workflow.get("workflow_state", "")) == "needs_review"
		and str(workflow.get("notes", "")).contains("Private continuity")
		and workflow.get("privacy_markers", []).size() == 2
		and not JSON.stringify(exported_card).contains("Private continuity note"),
		"Workflow state, notes and privacy markers must persist privately without entering Character Card export."
	):
		return

	CCFLibraryWorkflowServiceV0184.record_activity(first_id, "open", "Focused regression")
	CCFLibraryWorkflowServiceV0184.record_activity(first_id, "export", "Focused regression")
	var recent_ids := CCFLibraryWorkflowServiceV0184.recent_project_ids()
	var saved_view := CCFLibraryWorkflowServiceV0184.save_view(
		"Needs Review — Private",
		{"workflow_state": "needs_review", "query": "mira", "recent_only": true},
		true
	)
	if not _require(
		recent_ids.size() > 0 and recent_ids[0] == first_id
		and bool(saved_view.get("ok", false))
		and str(saved_view.get("view", {}).get("kind", "")) == "smart_collection",
		"Recent activity and rule-backed Smart Collections must be saved in local Library state."
	):
		return

	var index_result := CCFLibraryService.refresh_index(true)
	var indexed_rows: Array[Dictionary] = []
	for row_value in index_result.get("rows", []):
		if row_value is Dictionary:
			indexed_rows.append(row_value)
	var enhanced := CCFLibraryWorkflowServiceV0184.enhance_rows(indexed_rows)
	var first_row: Dictionary = {}
	for row in enhanced:
		if str(row.get("project_id", "")) == first_id:
			first_row = row
			break
	if not _require(
		not first_row.is_empty()
		and bool(first_row.get("sensitive", false))
		and str(first_row.get("workflow_state", "")) == "needs_review"
		and int(first_row.get("token_total", 0)) > 0
		and CCFLibraryWorkflowServiceV0184.row_matches_rules(
			first_row,
			{"workflow_state": "needs_review", "query": "private continuity", "recent_only": true}
		),
		"Enhanced rows must expose workflow, privacy, token, recent-use and searchable private-note evidence."
	):
		return

	var validation := CCFLibraryWorkflowServiceV0184.batch_validate([first_id, second_id])
	if not _require(
		bool(validation.get("ok", false))
		and int(validation.get("project_count", 0)) == 2
		and int(validation.get("character_count", 0)) == 2
		and str(CCFLibraryWorkflowServiceV0184.batch_report_text(validation, "Test Report")).contains("Mira Vale"),
		"Batch validation must return a complete per-project/per-character report."
	):
		return

	var export_directory := "/tmp/ccf_v0184_batch_exports"
	var batch_export := CCFLibraryWorkflowServiceV0184.export_project_packages(
		[first_id, second_id], export_directory
	)
	if not _require(
		bool(batch_export.get("ok", false))
		and int(batch_export.get("succeeded", 0)) == 2
		and batch_export.get("outcomes", []).size() == 2
		and FileAccess.file_exists(str(batch_export.get("outcomes", [])[0].get("path", ""))),
		"Export Selected must reuse project packages and report each outcome."
	):
		return
	var card_export := CCFLibraryWorkflowServiceV0184.export_character_cards(
		[first_id, second_id], "/tmp/ccf_v0184_card_exports"
	)
	if not _require(
		bool(card_export.get("ok", false))
		and int(card_export.get("succeeded", 0)) == 2
		and card_export.get("outcomes", []).size() == 2,
		"Safe format conversion must reuse Character Card V2 export checks and report each character outcome."
	):
		return

	var group_result := CCFLibraryWorkflowServiceV0184.create_group_project(
		[first_id, second_id], "Mira Archive Ensemble"
	)
	var group_loaded := CCFStorageService.load_project(str(group_result.get("project_id", "")))
	var group_project: Dictionary = group_loaded.get("data", {})
	var workflows: Array = group_project.get("card_workflows", [])
	if not _require(
		bool(group_result.get("ok", false))
		and bool(group_loaded.get("ok", false))
		and group_project.get("characters", []).size() == 2
		and workflows.size() == 1
		and workflows[0].get("selected_character_ids", []).size() == 2
		and workflows[0].get("front_porch_group", null) is Dictionary,
		"Group creation must reuse the normal multi-character project and Front Porch group-workflow models."
	):
		return

	var duplicate_scan := CCFLibraryWorkflowServiceV0184.scan_duplicates([first_id, second_id])
	var matches: Array = duplicate_scan.get("matches", [])
	if not _require(
		bool(duplicate_scan.get("ok", false))
		and not matches.is_empty()
		and str(matches[0].get("type", "")) == "exact"
		and matches[0].get("evidence", []).size() > 0
		and not bool(matches[0].get("automatic_action", true)),
		"Duplicate review must show exact hash evidence and never take an automatic action."
	):
		return
	var duplicate_resolution := CCFLibraryWorkflowServiceV0184.resolve_duplicate(
		matches[0], "merge", "first"
	)
	var other_project_id := str(duplicate_resolution.get("archived_project_id", ""))
	var archived_loaded := CCFStorageService.load_project(other_project_id)
	if not _require(
		bool(duplicate_resolution.get("ok", false))
		and bool(duplicate_resolution.get("recoverable", false))
		and bool(
			CCFLibraryWorkflowServiceV0184.workflow_metadata(
				archived_loaded.get("data", {})
			).get("archived", false)
		),
		"Explicit Merge/Replace duplicate resolution must archive the non-preferred project for recovery."
	):
		return

	var library_view := CCFLibraryV0184View.new()
	get_root().add_child(library_view)
	await process_frame
	await process_frame
	var batch_menu := _find_menu(library_view, "Selected Project Actions")
	var quick_menu := _find_menu(library_view, "Quick Actions…")
	var report_window_value: Variant = library_view.get("_report_window")
	var duplicate_window_value: Variant = library_view.get("_duplicate_window")
	if not _require(
		library_view is CCFLibraryV0184View
		and batch_menu != null
		and batch_menu.get_popup().item_count >= 10
		and quick_menu != null
		and quick_menu.get_popup().item_count >= 11
		and _find_button(library_view, "Save Private Workflow") != null
		and _find_button(library_view, "Save Smart Collection…") != null,
		"The live Library must expose workflow editing, saved views, batch actions and quick actions."
	):
		return
	if not _require(
		report_window_value is Window
		and duplicate_window_value is Window
		and not (report_window_value as Window).visible
		and not (duplicate_window_value as Window).visible
		and (report_window_value as Window).force_native
		and (duplicate_window_value as Window).force_native,
		"Library report and duplicate-review windows must start closed and remain freely movable native windows."
	):
		return
	library_view.queue_free()
	await process_frame
	print("V0184_LIBRARY_WORKFLOW_OK")
	quit(0)
