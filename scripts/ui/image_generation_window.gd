class_name CCFImageGenerationWindow
extends Window

signal project_changed(project: Dictionary)

const WINDOW_STATE_ID := "image_generation"

var _settings: Dictionary = {}
var _project: Dictionary = {}
var _active_character_id := ""
var _image_service: CCFImageGenerationService
var _project_selector: OptionButton
var _character_selector: OptionButton
var _profile_selector: OptionButton
var _model_edit: LineEdit
var _image_size_edit: LineEdit
var _prompt_style_selector: OptionButton
var _extra_direction_edit: TextEdit
var _prompt_edit: TextEdit
var _negative_prompt_edit: TextEdit
var _gallery: ItemList
var _preview: TextureRect
var _preview_info: Label
var _status: Label
var _generate_button: Button
var _cancel_button: Button
var _set_portrait_button: Button
var _remove_button: Button
var _selected_image_index := -1
var _loading_controls := false


func _ready() -> void:
	close_requested.connect(_close_window)
	_image_service = CCFImageGenerationService.new()
	add_child(_image_service)
	_image_service.generation_started.connect(_on_generation_started)
	_image_service.generation_completed.connect(_on_generation_completed)
	_image_service.generation_failed.connect(_on_generation_failed)
	_image_service.generation_cancelled.connect(_on_generation_cancelled)
	_build_ui()
	_reload_settings()
	_refresh_projects()


func open_studio() -> void:
	_reload_settings()
	_refresh_profiles()
	_refresh_projects()
	CCFToolWindowStateService.show_window(self, WINDOW_STATE_ID, Vector2i(1180, 820))


func save_window_state() -> void:
	CCFToolWindowStateService.save_window(self, WINDOW_STATE_ID)


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var heading := Label.new()
	heading.text = "Image Generation Studio"
	heading.add_theme_font_size_override("font_size", 22)
	root.add_child(heading)

	var hint := Label.new()
	hint.text = "Generate character artwork through an OpenAI-compatible image endpoint. Generated files stay as ordinary per-character PNG assets and can be promoted to the character portrait."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(0.72, 0.75, 0.84)
	root.add_child(hint)

	var source_row := HFlowContainer.new()
	source_row.add_theme_constant_override("separation", 8)
	root.add_child(source_row)
	source_row.add_child(_label("Project"))
	_project_selector = OptionButton.new()
	_project_selector.custom_minimum_size.x = 300
	_project_selector.item_selected.connect(_on_project_selected)
	source_row.add_child(_project_selector)
	source_row.add_child(_label("Character"))
	_character_selector = OptionButton.new()
	_character_selector.custom_minimum_size.x = 280
	_character_selector.item_selected.connect(_on_character_selected)
	source_row.add_child(_character_selector)
	var reload_button := Button.new()
	reload_button.text = "Reload Projects"
	reload_button.pressed.connect(_refresh_projects)
	source_row.add_child(reload_button)

	var provider_row := HFlowContainer.new()
	provider_row.add_theme_constant_override("separation", 8)
	root.add_child(provider_row)
	provider_row.add_child(_label("Image provider"))
	_profile_selector = OptionButton.new()
	_profile_selector.custom_minimum_size.x = 240
	_profile_selector.item_selected.connect(_on_profile_selected)
	provider_row.add_child(_profile_selector)
	var default_provider_button := Button.new()
	default_provider_button.text = "Use as Image Default"
	default_provider_button.tooltip_text = "Assign this reusable API profile to the Image generation role."
	default_provider_button.pressed.connect(_save_default_image_profile)
	provider_row.add_child(default_provider_button)
	provider_row.add_child(_label("Model"))
	_model_edit = LineEdit.new()
	_model_edit.custom_minimum_size.x = 260
	_model_edit.placeholder_text = "Image model ID"
	provider_row.add_child(_model_edit)

	var option_row := HFlowContainer.new()
	option_row.add_theme_constant_override("separation", 8)
	root.add_child(option_row)
	option_row.add_child(_label("Size"))
	_image_size_edit = LineEdit.new()
	_image_size_edit.custom_minimum_size.x = 150
	_image_size_edit.placeholder_text = "1024x1024 or auto"
	option_row.add_child(_image_size_edit)
	option_row.add_child(_label("Prompt style"))
	_prompt_style_selector = OptionButton.new()
	for style_entry in [
		{"label": "Auto", "value": "auto"},
		{"label": "Natural language", "value": "natural"},
		{"label": "Stable Diffusion style", "value": "stable_diffusion"}
	]:
		_prompt_style_selector.add_item(str(style_entry["label"]))
		_prompt_style_selector.set_item_metadata(
			_prompt_style_selector.item_count - 1, str(style_entry["value"])
		)
	_prompt_style_selector.item_selected.connect(_on_prompt_style_selected)
	option_row.add_child(_prompt_style_selector)
	var build_prompt_button := Button.new()
	build_prompt_button.text = "Build Prompt from Character"
	build_prompt_button.pressed.connect(_build_prompt_from_character)
	option_row.add_child(build_prompt_button)

	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.split_offset = 620
	root.add_child(body)

	var prompt_side := VBoxContainer.new()
	prompt_side.custom_minimum_size.x = 520
	prompt_side.add_theme_constant_override("separation", 7)
	body.add_child(prompt_side)
	prompt_side.add_child(_label("Additional visual direction"))
	_extra_direction_edit = TextEdit.new()
	_extra_direction_edit.custom_minimum_size.y = 90
	_extra_direction_edit.placeholder_text = "Optional clothing, composition, lighting, background, art-direction, or pose notes."
	prompt_side.add_child(_extra_direction_edit)
	prompt_side.add_child(_label("Image prompt"))
	_prompt_edit = TextEdit.new()
	_prompt_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_prompt_edit.custom_minimum_size.y = 220
	_prompt_edit.placeholder_text = "Build a prompt from the selected character, then edit it freely."
	prompt_side.add_child(_prompt_edit)
	prompt_side.add_child(_label("Avoid / negative direction"))
	_negative_prompt_edit = TextEdit.new()
	_negative_prompt_edit.custom_minimum_size.y = 90
	_negative_prompt_edit.placeholder_text = "Optional. For OpenAI-compatible routes this is appended as provider-neutral exclusion guidance."
	prompt_side.add_child(_negative_prompt_edit)

	var generation_actions := HBoxContainer.new()
	generation_actions.add_theme_constant_override("separation", 8)
	prompt_side.add_child(generation_actions)
	_generate_button = Button.new()
	_generate_button.text = "Generate Image"
	_generate_button.pressed.connect(_generate_image)
	generation_actions.add_child(_generate_button)
	_cancel_button = Button.new()
	_cancel_button.text = "Cancel"
	_cancel_button.disabled = true
	_cancel_button.pressed.connect(_cancel_generation)
	generation_actions.add_child(_cancel_button)

	var gallery_side := VBoxContainer.new()
	gallery_side.custom_minimum_size.x = 420
	gallery_side.add_theme_constant_override("separation", 7)
	body.add_child(gallery_side)
	gallery_side.add_child(_label("Generated image gallery"))
	_gallery = ItemList.new()
	_gallery.custom_minimum_size.y = 150
	_gallery.select_mode = ItemList.SELECT_SINGLE
	_gallery.item_selected.connect(_on_gallery_selected)
	gallery_side.add_child(_gallery)
	_preview = TextureRect.new()
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.custom_minimum_size = Vector2(360, 300)
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gallery_side.add_child(_preview)
	_preview_info = Label.new()
	_preview_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_info.modulate = Color(0.72, 0.75, 0.84)
	gallery_side.add_child(_preview_info)

	var gallery_actions := HBoxContainer.new()
	gallery_actions.add_theme_constant_override("separation", 8)
	gallery_side.add_child(gallery_actions)
	_set_portrait_button = Button.new()
	_set_portrait_button.text = "Set as Portrait"
	_set_portrait_button.disabled = true
	_set_portrait_button.pressed.connect(_set_selected_as_portrait)
	gallery_actions.add_child(_set_portrait_button)
	var open_file_button := Button.new()
	open_file_button.text = "Open Image"
	open_file_button.pressed.connect(_open_selected_image)
	gallery_actions.add_child(open_file_button)
	_remove_button = Button.new()
	_remove_button.text = "Remove from Gallery"
	_remove_button.disabled = true
	_remove_button.tooltip_text = "Remove the gallery record but keep the PNG file as a recoverable asset."
	_remove_button.pressed.connect(_remove_selected_from_gallery)
	gallery_actions.add_child(_remove_button)

	_status = Label.new()
	_status.text = "Select a saved project and character."
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.7, 0.82, 0.72)
	root.add_child(_status)


func _reload_settings() -> void:
	_settings = CCFSettingsService.load_settings()
	if _profile_selector == null:
		return
	_refresh_profiles()
	var generation_settings: Dictionary = _settings.get("generation", {})
	_image_size_edit.text = str(generation_settings.get("default_image_size", "1024x1024"))
	_select_prompt_style(str(generation_settings.get("default_image_prompt_style", "auto")))


func _refresh_profiles() -> void:
	if _profile_selector == null:
		return
	_loading_controls = true
	_profile_selector.clear()
	var selected_profile_id := CCFSettingsService.role_profile_id(
		_settings, CCFSettingsService.ROLE_IMAGE
	)
	var selected_index := 0
	for raw_profile in _settings.get("api_profiles", []):
		if not raw_profile is Dictionary:
			continue
		var profile: Dictionary = raw_profile
		var profile_id := str(profile.get("id", "default"))
		_profile_selector.add_item(str(profile.get("name", "Profile")))
		var item_index := _profile_selector.item_count - 1
		_profile_selector.set_item_metadata(item_index, profile_id)
		if profile_id == selected_profile_id:
			selected_index = item_index
	if _profile_selector.item_count > 0:
		_profile_selector.select(selected_index)
	_loading_controls = false
	_load_selected_profile_model()


func _refresh_projects() -> void:
	if _project_selector == null:
		return
	var previous_project_id := str(_project.get("project_id", ""))
	_loading_controls = true
	_project_selector.clear()
	var rows := CCFStorageService.list_projects()
	var selected_index := -1
	for raw_row in rows:
		if not raw_row is Dictionary:
			continue
		var row: Dictionary = raw_row
		var project_id := str(row.get("project_id", ""))
		_project_selector.add_item(str(row.get("name", "Untitled Project")))
		var item_index := _project_selector.item_count - 1
		_project_selector.set_item_metadata(item_index, project_id)
		if project_id == previous_project_id:
			selected_index = item_index
	_loading_controls = false
	if _project_selector.item_count == 0:
		_project.clear()
		_active_character_id = ""
		_character_selector.clear()
		_refresh_gallery()
		_status.text = "No saved character projects are available yet."
		return
	if selected_index < 0:
		selected_index = 0
	_project_selector.select(selected_index)
	_load_project(str(_project_selector.get_item_metadata(selected_index)))


func _load_project(project_id: String) -> void:
	var loaded := CCFStorageService.load_project(project_id)
	if not bool(loaded.get("ok", false)):
		_status.text = str(loaded.get("error", "Could not load the selected project."))
		return
	_project = loaded.get("data", {}).duplicate(true)
	_active_character_id = CCFStorageService.active_character_id(_project)
	_refresh_characters()
	_build_prompt_from_character()
	_refresh_gallery()
	_status.text = "Image Studio loaded the saved project. Generated assets are saved immediately."


func _refresh_characters() -> void:
	_loading_controls = true
	_character_selector.clear()
	var selected_index := 0
	var row_index := 0
	for summary in CCFStorageService.project_character_summaries(_project):
		var character_id := str(summary.get("character_id", ""))
		_character_selector.add_item(str(summary.get("name", "Untitled Character")))
		_character_selector.set_item_metadata(row_index, character_id)
		if character_id == _active_character_id:
			selected_index = row_index
		row_index += 1
	if _character_selector.item_count > 0:
		_character_selector.select(selected_index)
	_loading_controls = false


func _on_project_selected(index: int) -> void:
	if _loading_controls or index < 0:
		return
	_load_project(str(_project_selector.get_item_metadata(index)))


func _on_character_selected(index: int) -> void:
	if _loading_controls or index < 0:
		return
	_active_character_id = str(_character_selector.get_item_metadata(index))
	_build_prompt_from_character()
	_refresh_gallery()


func _on_profile_selected(_index: int) -> void:
	if _loading_controls:
		return
	_load_selected_profile_model()


func _load_selected_profile_model() -> void:
	var profile := _selected_profile()
	_model_edit.text = str(profile.get("model", ""))


func _save_default_image_profile() -> void:
	if _profile_selector.selected < 0:
		return
	var profile_id := str(_profile_selector.get_selected_metadata())
	CCFSettingsService.set_role_profile(_settings, CCFSettingsService.ROLE_IMAGE, profile_id)
	var save_result := CCFSettingsService.save_settings(_settings)
	if bool(save_result.get("ok", false)):
		_status.text = "%s is now the default Image generation profile." % _profile_selector.get_item_text(_profile_selector.selected)
	else:
		_status.text = str(save_result.get("error", "Could not save the Image provider role."))


func _on_prompt_style_selected(_index: int) -> void:
	if _loading_controls:
		return
	_build_prompt_from_character()


func _build_prompt_from_character() -> void:
	if _project.is_empty() or _active_character_id.is_empty() or _prompt_edit == null:
		return
	_prompt_edit.text = CCFImageGenerationService.build_prompt(
		_project,
		_active_character_id,
		_selected_prompt_style(),
		_extra_direction_edit.text
	)


func _generate_image() -> void:
	if _project.is_empty() or _active_character_id.is_empty():
		_status.text = "Select a saved project and character first."
		return
	var result := _image_service.generate(
		str(_project.get("project_id", "")),
		_active_character_id,
		_selected_profile(),
		_prompt_edit.text,
		_negative_prompt_edit.text,
		_image_size_edit.text,
		_selected_prompt_style(),
		_model_edit.text
	)
	if not bool(result.get("ok", false)):
		_status.text = str(result.get("error", "Could not start image generation."))


func _cancel_generation() -> void:
	_image_service.cancel()


func _on_generation_started() -> void:
	_generate_button.disabled = true
	_cancel_button.disabled = false
	_status.text = "Generating image…"


func _on_generation_completed(record: Dictionary) -> void:
	_generate_button.disabled = false
	_cancel_button.disabled = true
	var character_index := CCFStorageService.character_index(_project, _active_character_id)
	if character_index < 0:
		_status.text = "Image was saved, but the originating character is no longer in this project."
		return
	var characters: Array = _project.get("characters", []).duplicate(true)
	var character: Dictionary = characters[character_index].duplicate(true)
	var assets: Dictionary = character.get("assets", {}).duplicate(true)
	var generated_images: Array = assets.get("generated_images", []).duplicate(true)
	generated_images.push_front(record.duplicate(true))
	assets["generated_images"] = generated_images
	character["assets"] = assets
	characters[character_index] = character
	_project["characters"] = characters
	var save_result := CCFStorageService.save_project(_project)
	if not bool(save_result.get("ok", false)):
		_status.text = "Image file was saved, but its gallery record could not be saved: %s" % str(save_result.get("error", "Unknown error"))
		return
	_refresh_gallery()
	if _gallery.item_count > 0:
		_gallery.select(0)
		_on_gallery_selected(0)
	project_changed.emit(_project.duplicate(true))
	_status.text = "Image generated and added to the character gallery."


func _on_generation_failed(message: String) -> void:
	_generate_button.disabled = false
	_cancel_button.disabled = true
	_status.text = message


func _on_generation_cancelled() -> void:
	_generate_button.disabled = false
	_cancel_button.disabled = true
	_status.text = "Image generation cancelled."


func _refresh_gallery() -> void:
	_selected_image_index = -1
	_gallery.clear()
	_preview.texture = null
	_preview_info.text = ""
	_set_portrait_button.disabled = true
	_remove_button.disabled = true
	var character := CCFStorageService.get_character(_project, _active_character_id)
	if character.is_empty():
		return
	var assets: Dictionary = character.get("assets", {})
	var generated_images = assets.get("generated_images", [])
	if not generated_images is Array:
		return
	for raw_entry in generated_images:
		var entry := _normalise_gallery_entry(raw_entry)
		if entry.is_empty():
			continue
		var created_at := str(entry.get("created_at", "")).replace("T", " ")
		var model_id := str(entry.get("model", "")).strip_edges()
		var gallery_label := created_at if not created_at.is_empty() else str(entry.get("path", "Generated image"))
		if not model_id.is_empty():
			gallery_label += " — %s" % model_id
		_gallery.add_item(gallery_label)
		_gallery.set_item_metadata(_gallery.item_count - 1, entry)
	if _gallery.item_count > 0:
		_gallery.select(0)
		_on_gallery_selected(0)


func _on_gallery_selected(index: int) -> void:
	if index < 0 or index >= _gallery.item_count:
		return
	_selected_image_index = index
	var entry = _gallery.get_item_metadata(index)
	if not entry is Dictionary:
		return
	var image_entry: Dictionary = entry
	var project_id := str(_project.get("project_id", ""))
	var user_path := CCFImageGenerationService.resolve_generated_image_path(
		project_id, str(image_entry.get("path", ""))
	)
	_preview.texture = _texture_from_user_path(user_path)
	_preview_info.text = _gallery_entry_summary(image_entry)
	_set_portrait_button.disabled = user_path.is_empty() or _preview.texture == null
	_remove_button.disabled = false


func _set_selected_as_portrait() -> void:
	var entry := _selected_gallery_entry()
	if entry.is_empty():
		return
	var character_index := CCFStorageService.character_index(_project, _active_character_id)
	if character_index < 0:
		return
	var characters: Array = _project.get("characters", []).duplicate(true)
	var character: Dictionary = characters[character_index].duplicate(true)
	var assets: Dictionary = character.get("assets", {}).duplicate(true)
	assets["portrait"] = str(entry.get("path", ""))
	character["assets"] = assets
	characters[character_index] = character
	_project["characters"] = characters
	var save_result := CCFStorageService.save_project(_project)
	if not bool(save_result.get("ok", false)):
		_status.text = str(save_result.get("error", "Could not save the portrait assignment."))
		return
	project_changed.emit(_project.duplicate(true))
	_status.text = "Selected generated image is now the character portrait."


func _remove_selected_from_gallery() -> void:
	var entry := _selected_gallery_entry()
	if entry.is_empty():
		return
	var character_index := CCFStorageService.character_index(_project, _active_character_id)
	if character_index < 0:
		return
	var characters: Array = _project.get("characters", []).duplicate(true)
	var character: Dictionary = characters[character_index].duplicate(true)
	var assets: Dictionary = character.get("assets", {}).duplicate(true)
	var old_images = assets.get("generated_images", [])
	var remaining: Array = []
	var target_id := str(entry.get("image_id", ""))
	var target_path := str(entry.get("path", ""))
	if old_images is Array:
		for raw_entry in old_images:
			var candidate := _normalise_gallery_entry(raw_entry)
			if candidate.is_empty():
				continue
			var same_id := not target_id.is_empty() and str(candidate.get("image_id", "")) == target_id
			var same_path := str(candidate.get("path", "")) == target_path
			if same_id or same_path:
				continue
			remaining.append(raw_entry)
	assets["generated_images"] = remaining
	character["assets"] = assets
	characters[character_index] = character
	_project["characters"] = characters
	var save_result := CCFStorageService.save_project(_project)
	if not bool(save_result.get("ok", false)):
		_status.text = str(save_result.get("error", "Could not update the generated image gallery."))
		return
	_refresh_gallery()
	project_changed.emit(_project.duplicate(true))
	_status.text = "Gallery record removed. The PNG remains in the project asset folder for recovery."


func _open_selected_image() -> void:
	var entry := _selected_gallery_entry()
	if entry.is_empty():
		return
	var user_path := CCFImageGenerationService.resolve_generated_image_path(
		str(_project.get("project_id", "")), str(entry.get("path", ""))
	)
	if user_path.is_empty():
		_status.text = "The selected image path is invalid."
		return
	var absolute_path := ProjectSettings.globalize_path(user_path)
	if not FileAccess.file_exists(user_path) and not FileAccess.file_exists(absolute_path):
		_status.text = "The selected image file no longer exists."
		return
	OS.shell_open(absolute_path)


func _selected_gallery_entry() -> Dictionary:
	if _selected_image_index < 0 or _selected_image_index >= _gallery.item_count:
		return {}
	var entry = _gallery.get_item_metadata(_selected_image_index)
	return entry.duplicate(true) if entry is Dictionary else {}


func _selected_profile() -> Dictionary:
	if _profile_selector.selected < 0:
		return CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_IMAGE)
	return CCFSettingsService.profile_by_id(
		_settings, str(_profile_selector.get_selected_metadata())
	)


func _selected_prompt_style() -> String:
	if _prompt_style_selector.selected < 0:
		return "auto"
	return str(_prompt_style_selector.get_selected_metadata())


func _select_prompt_style(prompt_style: String) -> void:
	for item_index in range(_prompt_style_selector.item_count):
		if str(_prompt_style_selector.get_item_metadata(item_index)) == prompt_style:
			_prompt_style_selector.select(item_index)
			return
	if _prompt_style_selector.item_count > 0:
		_prompt_style_selector.select(0)


func _normalise_gallery_entry(raw_entry: Variant) -> Dictionary:
	if raw_entry is Dictionary:
		var record: Dictionary = raw_entry.duplicate(true)
		if str(record.get("path", "")).strip_edges().is_empty():
			return {}
		return record
	var legacy_path := str(raw_entry).strip_edges()
	if legacy_path.is_empty():
		return {}
	return {"format_version": 0, "image_id": "", "path": legacy_path}


func _texture_from_user_path(user_path: String) -> Texture2D:
	if user_path.is_empty():
		return null
	var decoded_image := Image.new()
	var load_error := decoded_image.load(ProjectSettings.globalize_path(user_path))
	if load_error != OK:
		return null
	return ImageTexture.create_from_image(decoded_image)


func _gallery_entry_summary(entry: Dictionary) -> String:
	var lines: Array[String] = []
	var dimensions := ""
	if int(entry.get("width", 0)) > 0 and int(entry.get("height", 0)) > 0:
		dimensions = "%d×%d" % [int(entry.get("width", 0)), int(entry.get("height", 0))]
	if not dimensions.is_empty():
		lines.append(dimensions)
	var profile_label := str(entry.get("profile_name", "")).strip_edges()
	var model_id := str(entry.get("model", "")).strip_edges()
	if not profile_label.is_empty() or not model_id.is_empty():
		lines.append("Provider: %s%s" % [profile_label, " • %s" % model_id if not model_id.is_empty() else ""])
	var prompt_text := str(entry.get("prompt", "")).strip_edges()
	if not prompt_text.is_empty():
		lines.append("Prompt: %s" % prompt_text.left(500))
	var relative_path := str(entry.get("path", "")).strip_edges()
	if not relative_path.is_empty():
		lines.append("File: %s" % relative_path)
	return "\n".join(lines)


func _close_window() -> void:
	save_window_state()
	hide()


func _label(label_text: String) -> Label:
	var label := Label.new()
	label.text = label_text
	return label
