extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_prepare_settings_v01529()
	var project := _create_saved_project_v01529()
	await _test_real_app_v01529(project)
	print("v0.15.29 embedded Image Studio and AI prompt regression passed")
	quit(0)


func _prepare_settings_v01529() -> void:
	var settings := CCFSettingsService.default_settings()
	var text_profile: Dictionary = settings.get("api_profiles", [])[0].duplicate(true)
	text_profile["id"] = "image_prompt_text_profile"
	text_profile["name"] = "Image Prompt Text Model"
	text_profile["base_url"] = "http://127.0.0.1:9/v1"
	text_profile["model"] = "test-text-model"
	settings["api_profiles"] = [text_profile]
	settings["active_api_profile_id"] = "image_prompt_text_profile"
	CCFSettingsService.set_role_profile(
		settings, CCFSettingsService.ROLE_TEXT, "image_prompt_text_profile"
	)

	var image_profile: Dictionary = CCFSettingsService.image_profiles(settings)[0].duplicate(true)
	image_profile["id"] = "image_prompt_sd_profile"
	image_profile["name"] = "Local SD"
	image_profile["model"] = "portrait.safetensors"
	settings["image_profiles"] = [image_profile]
	CCFSettingsService.set_role_profile(
		settings, CCFSettingsService.ROLE_IMAGE, "image_prompt_sd_profile"
	)
	var save_result := CCFSettingsService.save_settings(settings)
	assert(bool(save_result.get("ok", false)), "v0.15.29 fixture settings must save.")


func _create_saved_project_v01529() -> Dictionary:
	var project := CCFStorageService.new_project()
	var metadata: Dictionary = project.get("metadata", {}).duplicate(true)
	metadata["name"] = "Prompt Regression Project"
	project["metadata"] = metadata
	var characters: Array = project.get("characters", []).duplicate(true)
	var character: Dictionary = characters[0].duplicate(true)
	var character_metadata: Dictionary = character.get("metadata", {}).duplicate(true)
	character_metadata["name"] = "Ava"
	character["metadata"] = character_metadata
	var card: Dictionary = character.get("character", {}).duplicate(true)
	card["name"] = "Ava"
	card["description"] = "A 24-year-old woman with long silver hair, blue eyes, and a fitted black jacket."
	card["personality"] = "Calm, observant, quietly confident, with a dry sense of humour."
	card["scenario"] = "Standing beneath neon city lights after rain."
	card["first_mes"] = "Ava glances over her shoulder as reflected neon ripples across the wet street."
	character["character"] = card
	characters[0] = character
	project["characters"] = characters
	var save_result := CCFStorageService.save_project(project)
	assert(bool(save_result.get("ok", false)), "v0.15.29 fixture project must save.")
	return project


func _test_real_app_v01529(project: Dictionary) -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	assert(packed != null, "v0.15.29 main scene must load.")
	var app := packed.instantiate()
	assert(app != null, "v0.15.29 main scene must instantiate.")
	get_root().add_child(app)
	for _frame in range(6):
		await process_frame

	var image_window := _find_image_window_v01529(app)
	assert(image_window != null, "The live app must install CCFImageGenerationWindowV01529.")
	assert(not image_window.visible, "The Image Studio controller window must remain hidden when embedded.")

	image_window.sync_saved_project_v01528(
		project, CCFStorageService.active_character_id(project)
	)
	await process_frame
	var prompt_edit := image_window.get("_prompt_edit") as TextEdit
	assert(prompt_edit != null, "Image Studio must expose its prompt editor.")
	assert(
		prompt_edit.text.strip_edges().is_empty(),
		"Loading or switching a character must be passive and must not silently build a local prompt."
	)
	var prompt_service := image_window.get("_prompt_generation_service_v01529") as CCFImagePromptGenerationServiceV01529
	assert(prompt_service != null, "The current Image Studio must install the v0.15.29 AI prompt service.")
	assert(
		prompt_service.concurrent_capabilities_v01526().get("scheduler_gated_requests", false),
		"AI image-prompt generation must retain the current scheduler-aware generation stack."
	)
	assert(
		prompt_service.pending_count() == 0 and not prompt_service.has_active_job(),
		"Passive project/character refresh must not queue a Text-provider request."
	)

	app.call("_open_image_studio")
	await process_frame
	assert(not image_window.visible, "Opening Image Studio from navigation must not show a native popup Window.")
	assert(str(app.get("_current_view")) == "image", "Image Studio must be a selected main navigation view.")
	var image_page := _visible_image_page_v01529(app)
	assert(image_page != null, "Opening Image Studio must reveal the embedded main-workspace page.")
	var studio_scroll := image_page.get("_studio_scroll") as ScrollContainer
	assert(studio_scroll != null, "The embedded Image Studio must retain its scrolling viewport.")
	assert(
		_find_margin_container_v01529(studio_scroll) != null,
		"The current Image Studio controls must be mounted inside the embedded scroll viewport."
	)

	var ai_button := _find_button_v01529(image_page, "Generate Prompt from Character")
	var local_button := _find_button_v01529(image_page, "Build Local Fallback")
	assert(ai_button != null, "The normal prompt action must be Generate Prompt from Character.")
	assert(local_button != null, "The deterministic prompt builder must remain an explicit Local Fallback action.")

	image_window.call("_build_local_prompt_from_character_v01529")
	assert(
		not prompt_edit.text.strip_edges().is_empty(),
		"Build Local Fallback must still create a deterministic prompt without AI."
	)
	assert(
		prompt_service.pending_count() == 0 and not prompt_service.has_active_job(),
		"Build Local Fallback must not queue a Text-provider request."
	)

	prompt_edit.text = ""
	image_window.call("_generate_prompt_from_character_v01529")
	assert(
		not str(image_window.get("_prompt_generation_job_id_v01529")).is_empty(),
		"Generate Prompt from Character must queue a real AI image-prompt job."
	)
	assert(
		prompt_service.pending_count() > 0 or prompt_service.has_active_job(),
		"The explicit prompt action must enter the Text generation queue rather than locally extracting card fields."
	)
	var active_or_queued: Variant = prompt_service.get("_queue")
	if active_or_queued is Array:
		(active_or_queued as Array).clear()
	image_window.set("_prompt_generation_job_id_v01529", "")

	var character := CCFStorageService.get_character(
		project, CCFStorageService.active_character_id(project)
	)
	var messages := prompt_service.build_image_prompt_messages(
		project, character, "stable_diffusion", "waist-up portrait"
	)
	assert(not messages.is_empty(), "The AI prompt service must build Text-role request messages from the selected character.")
	var rendered := JSON.stringify(messages)
	assert(rendered.contains("PURPOSE-BUILT image-generation prompt"), "The AI request must ask the model to author a purpose-built image prompt.")
	assert(rendered.contains("Ava"), "The AI request must include the selected character source material.")
	assert(rendered.contains("waist-up portrait"), "Additional visual direction must remain authoritative input to the AI prompt writer.")

	app.queue_free()
	await process_frame


func _visible_image_page_v01529(root: Node) -> CCFImageGenerationPage:
	if root is CCFImageGenerationPage and (root as CCFImageGenerationPage).visible:
		return root as CCFImageGenerationPage
	for child in root.get_children():
		if child is Node:
			var found := _visible_image_page_v01529(child)
			if found != null:
				return found
	return null


func _find_image_window_v01529(root: Node) -> CCFImageGenerationWindowV01529:
	if root is CCFImageGenerationWindowV01529:
		return root as CCFImageGenerationWindowV01529
	for child in root.get_children():
		if child is Node:
			var found := _find_image_window_v01529(child)
			if found != null:
				return found
	return null


func _find_button_v01529(root: Node, button_text: String) -> Button:
	if root is Button and (root as Button).text == button_text:
		return root as Button
	for child in root.get_children():
		if child is Node:
			var found := _find_button_v01529(child, button_text)
			if found != null:
				return found
	return null


func _find_margin_container_v01529(root: Node) -> MarginContainer:
	if root is MarginContainer:
		return root as MarginContainer
	for child in root.get_children():
		if child is Node:
			var found := _find_margin_container_v01529(child)
			if found != null:
				return found
	return null
