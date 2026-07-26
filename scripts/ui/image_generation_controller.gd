class_name CCFImageGenerationController
extends CCFImageGenerationWindow


func _refresh_profiles() -> void:
	if _profile_selector == null:
		return
	_loading_controls = true
	_profile_selector.clear()
	var selected_profile_id := CCFSettingsService.role_profile_id(
		_settings, CCFSettingsService.ROLE_IMAGE
	)
	var selected_index := 0
	var row_index := 0
	for raw_profile in CCFSettingsService.image_profiles(_settings):
		if not raw_profile is Dictionary:
			continue
		var profile: Dictionary = raw_profile
		var profile_id := str(profile.get("id", "image_default"))
		_profile_selector.add_item(str(profile.get("name", "Image Provider")))
		_profile_selector.set_item_metadata(row_index, profile_id)
		if profile_id == selected_profile_id:
			selected_index = row_index
		row_index += 1
	if _profile_selector.item_count > 0:
		_profile_selector.select(selected_index)
	_loading_controls = false
	_load_selected_profile_settings()


func _selected_profile() -> Dictionary:
	if _profile_selector == null or _profile_selector.selected < 0:
		return CCFSettingsService.profile_for_role(_settings, CCFSettingsService.ROLE_IMAGE)
	return CCFSettingsService.image_profile_by_id(
		_settings, str(_profile_selector.get_selected_metadata())
	)


func _save_image_defaults() -> void:
	if _profile_selector.selected < 0:
		return
	var profile_id := str(_profile_selector.get_selected_metadata())
	var profile := CCFSettingsService.image_profile_by_id(_settings, profile_id).duplicate(true)
	profile["model"] = _model_edit.text.strip_edges()
	profile["image_settings"] = _current_generation_options("profile_default", "")
	CCFSettingsService.replace_image_profile_by_id(_settings, profile_id, profile)
	var save_result := CCFSettingsService.save_settings(_settings)
	if bool(save_result.get("ok", false)):
		_settings = CCFSettingsService.load_settings()
		_status.text = "Saved image-generation defaults to %s." % str(profile.get("name", "Image Provider"))
	else:
		_status.text = str(save_result.get("error", "Could not save image defaults."))


func _select_profile_by_id(profile_id: String) -> void:
	for item_index in range(_profile_selector.item_count):
		if str(_profile_selector.get_item_metadata(item_index)) == profile_id:
			_profile_selector.select(item_index)
			_load_selected_profile_settings()
			return
