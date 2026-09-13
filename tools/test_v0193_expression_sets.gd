extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message_text: String) -> void:
	push_error(message_text)
	print("V0193_EXPRESSION_SET_ERROR: %s" % message_text)
	quit(1)


func _require(condition: bool, message_text: String) -> bool:
	if condition:
		return true
	_fail(message_text)
	return false


func _run() -> void:
	var capabilities := CCFExpressionSetServiceV0193.capabilities()
	var labels: Array = capabilities.get("supported_labels", [])
	if not _require(
		labels.size() == 30
		and labels.has("neutral")
		and CCFExpressionSetServiceV0193.directions().size() == 30
		and not bool(capabilities.get("parallel_image_store", true)),
		"Expression sets must use all exact Front Porch labels without creating another image store."
	):
		return

	var project := CCFStorageService.new_project()
	var character: Dictionary = project.get("characters", [])[0]
	var character_id := str(character.get("character_id", ""))
	character["metadata"]["name"] = "Expression Test"
	character["character"]["name"] = "Expression Test"
	project["characters"][0] = character
	var relative_path := "characters/%s/generated_images/expression-result.png" % character_id
	var image_path := CCFStorageService.project_folder(str(project.get("project_id", ""))).path_join(relative_path)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(image_path.get_base_dir()))
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.32, 0.44, 0.78, 1.0))
	if not _require(image.save_png(ProjectSettings.globalize_path(image_path)) == OK, "The generated-image fixture must save."):
		return
	var snapshot := CCFImageResultWorkflowServiceV01610.execution_snapshot(
		{"id": "image-profile", "name": "Regression Image", "image_backend": "openai"},
		"example/image-model", "1024x1024", "natural", "A consistent portrait", "",
		{"sampler": "Euler a", "steps": 28, "cfg_scale": 7.0, "seed": 42, "batch_size": 1, "image_operation": "text_to_image"}
	)
	var created := CCFExpressionSetServiceV0193.create_batch(
		project, character_id, ["joy", "sadness", "joy", "unsupported"],
		{"mode": "prompt"}, snapshot
	)
	if not _require(bool(created.get("ok", false)), "A valid selected expression batch must be created."):
		return
	project = created.get("project", {})
	var batch: Dictionary = created.get("batch", {})
	var batch_id := str(batch.get("batch_id", ""))
	if not _require(
		(batch.get("items", []) as Array).size() == 2
		and str((batch.get("items", []) as Array)[0].get("label", "")) == "joy"
		and str((batch.get("items", []) as Array)[0].get("prompt", "")).contains("same character identity"),
		"Selected labels must be de-duplicated, validated and receive visible identity-preserving prompts."
	):
		return

	var generating := CCFExpressionSetServiceV0193.mark_generating(project, character_id, batch_id, "joy")
	project = generating.get("project", {})
	var record := {
		"format_version": 2,
		"image_id": "expression-result-1",
		"path": relative_path,
		"model": "example/image-model",
		"prompt": CCFExpressionSetServiceV0193.compose_prompt("A consistent portrait", "joy"),
		"seed": 42,
		"execution_snapshot_v01610": snapshot.duplicate(true)
	}
	var attached := CCFExpressionSetServiceV0193.attach_result(project, character_id, batch_id, "joy", record)
	project = attached.get("project", {})
	var failed := CCFExpressionSetServiceV0193.mark_failed(project, character_id, batch_id, "sadness", "Provider unavailable")
	project = failed.get("project", {})
	var retried := CCFExpressionSetServiceV0193.retry_item(project, character_id, batch_id, "sadness")
	project = retried.get("project", {})
	batch = CCFExpressionSetServiceV0193.batch_by_id(project, character_id, batch_id)
	var item_states: Dictionary = {}
	for raw_item in batch.get("items", []):
		item_states[str(raw_item.get("label", ""))] = str(raw_item.get("state", ""))
	if not _require(
		item_states.get("joy") == CCFExpressionSetServiceV0193.STATE_REVIEW
		and item_states.get("sadness") == CCFExpressionSetServiceV0193.STATE_QUEUED,
		"Retrying one failed expression must preserve successful sibling results."
	):
		return

	var accepted := CCFExpressionSetServiceV0193.accept_item(project, character_id, batch_id, "joy")
	if not _require(bool(accepted.get("ok", false)), "A reviewed result must be accepted into Avatar Gallery."):
		return
	project = accepted.get("project", {})
	var gallery_entries := CCFFrontPorchAvatarGalleryServiceV0175.entries_for_character(CCFStorageService.get_character(project, character_id))
	var accepted_provenance: Dictionary = gallery_entries[0].get("provenance", {}).get("image_studio", {})
	if not _require(
		gallery_entries.size() == 1
		and str(gallery_entries[0].get("label", "")) == "joy"
		and accepted_provenance.get("execution_snapshot_v01610", {}) is Dictionary
		and str(accepted_provenance.get("execution_snapshot_v01610", {}).get("model", "")) == "example/image-model",
		"Acceptance must use the canonical Avatar Gallery and preserve the exact Image Studio execution snapshot."
	):
		return

	var second := CCFExpressionSetServiceV0193.create_batch(project, character_id, ["joy"], {"mode": "prompt"}, snapshot)
	project = second.get("project", {})
	var second_batch: Dictionary = second.get("batch", {})
	var second_id := str(second_batch.get("batch_id", ""))
	project = CCFExpressionSetServiceV0193.attach_result(project, character_id, second_id, "joy", record).get("project", {})
	var collision := CCFExpressionSetServiceV0193.accept_item(project, character_id, second_id, "joy")
	if not _require(not bool(collision.get("ok", false)) and bool(collision.get("needs_replace", false)), "An existing exact label must require an explicit replacement choice."):
		return
	var replaced := CCFExpressionSetServiceV0193.accept_item(project, character_id, second_id, "joy", true)
	project = replaced.get("project", {})
	gallery_entries = CCFFrontPorchAvatarGalleryServiceV0175.entries_for_character(CCFStorageService.get_character(project, character_id))
	if not _require(
		bool(replaced.get("ok", false))
		and gallery_entries.size() == 1
		and FileAccess.file_exists(ProjectSettings.globalize_path(image_path)),
		"Replacing a label must remove only the old gallery role and leave the generated PNG recoverable."
	):
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	var app := packed.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var image_window_value: Variant = app.get("_image_generation_window")
	var expression_window_value: Variant = image_window_value.get("_expression_window_v0193") if image_window_value is CCFImageGenerationWindowV0193 else null
	var open_button_value: Variant = image_window_value.get("_expression_set_button_v0193") if image_window_value is CCFImageGenerationWindowV0193 else null
	var version_found := false
	for node in app.find_children("*", "Label", true, false):
		if node is Label and node.text == "Godot rewrite • v0.19.3":
			version_found = true
			break
	if not _require(
		image_window_value is CCFImageGenerationWindowV0193
		and expression_window_value is CCFExpressionSetWindowV0193
		and not (expression_window_value as Window).visible
		and (expression_window_value as Window).force_native
		and (image_window_value as CCFImageGenerationWindowV0193).expression_set_surface_ready_v0193()
		and open_button_value is Button
		and (open_button_value as Button).text == "Generate Expression Set…"
		and (open_button_value as Button).is_inside_tree()
		and _find_button(expression_window_value, "Accept into Avatar Gallery") != null
		and _find_button(expression_window_value, "Replace Existing Label…") != null
		and version_found,
		"The live v0.19.3 shell must mount a hidden detachable, review-first Expression Set workflow."
	):
		return
	app.queue_free()
	await process_frame
	print("V0193_EXPRESSION_SET_OK")
	quit(0)


func _find_button(root_node: Node, label_text: String) -> Button:
	for node in root_node.find_children("*", "Button", true, false):
		if node is Button and node.text == label_text:
			return node
	return null
