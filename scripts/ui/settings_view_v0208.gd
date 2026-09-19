class_name CCFSettingsV0208View
extends "res://scripts/ui/settings_view_v0200.gd"

var _collaborator_reply_output_v0208: SpinBox
var _collaborator_input_allowance_v0208: Label


func _ready() -> void:
	super._ready()
	_install_collaborator_budget_v0208()
	_load_active_profile()


func _install_collaborator_budget_v0208() -> void:
	if _max_tokens == null or not _max_tokens.get_parent() is GridContainer:
		return
	var form := _max_tokens.get_parent() as GridContainer
	for child in form.get_children():
		if not child is Label:
			continue
		if child.text in ["Maximum output tokens", "Text maximum output tokens"]:
			child.text = "Text model maximum output tokens"
		elif child.text.begins_with("Context Window is the model's total request capacity"):
			child.text = (
				"Context Window is the total input + output capacity. Text model maximum output "
				+ "is the profile ceiling; Collaborator uses the separate reply request above "
				+ "when calculating input room. Set Context Window to 0 if unknown."
			)
		elif child.text.begins_with("Text and Vision models can have completely different token limits"):
			child.text = (
				"Vision limits are independent. Character Collaborator Text replies use "
				+ "the separate reply output request; Vision image analysis does not."
			)
	_max_tokens.tooltip_text = (
		"Model/profile output ceiling. Collaborator requests its separate reply amount below, "
		+ "never more than this ceiling. Other Text tasks retain their current limits."
	)

	var label := _label("Collaborator reply output request")
	label.tooltip_text = "Maximum output requested for one Character Collaborator Text reply, summary or Workspace handoff."
	form.add_child(label)
	_collaborator_reply_output_v0208 = SpinBox.new()
	_collaborator_reply_output_v0208.name = "CollaboratorReplyOutputV0208"
	_collaborator_reply_output_v0208.min_value = 128
	_collaborator_reply_output_v0208.max_value = 2147483647
	_collaborator_reply_output_v0208.step = 128
	_collaborator_reply_output_v0208.suffix = " tokens"
	_collaborator_reply_output_v0208.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_collaborator_reply_output_v0208.tooltip_text = (
		"Defaults to 16,384. The actual request is capped by Text model maximum output. "
		+ "A larger request leaves less room for the conversation and attachments."
	)
	form.add_child(_collaborator_reply_output_v0208)
	var allowance_title := _label("Collaborator input allowance")
	form.add_child(allowance_title)
	_collaborator_input_allowance_v0208 = Label.new()
	_collaborator_input_allowance_v0208.name = "CollaboratorInputAllowanceV0208"
	_collaborator_input_allowance_v0208.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	form.add_child(_collaborator_input_allowance_v0208)
	var insert_at := _max_tokens.get_index() + 1
	for control in [label, _collaborator_reply_output_v0208, allowance_title, _collaborator_input_allowance_v0208]:
		form.move_child(control, insert_at)
		insert_at += 1
	_collaborator_reply_output_v0208.value_changed.connect(_update_collaborator_allowance_v0208.unbind(1))
	_max_tokens.value_changed.connect(_update_collaborator_allowance_v0208.unbind(1))
	if _context_window_tokens_v0151 != null:
		_context_window_tokens_v0151.value_changed.connect(_update_collaborator_allowance_v0208.unbind(1))


func _load_active_profile() -> void:
	super._load_active_profile()
	if _collaborator_reply_output_v0208 == null:
		return
	var profile := CCFSettingsService.active_profile(_settings)
	_collaborator_reply_output_v0208.value = int(profile.get("collaborator_reply_output_tokens", 16384))
	_update_collaborator_allowance_v0208()


func _capture_loaded_profile() -> void:
	super._capture_loaded_profile()
	if _loaded_profile_id.is_empty() or _collaborator_reply_output_v0208 == null:
		return
	var profile := CCFSettingsService.profile_by_id(_settings, _loaded_profile_id).duplicate(true)
	profile["collaborator_reply_output_tokens"] = int(_collaborator_reply_output_v0208.value)
	CCFSettingsService.replace_profile_by_id(_settings, _loaded_profile_id, profile)


func _update_collaborator_allowance_v0208() -> void:
	if _collaborator_input_allowance_v0208 == null:
		return
	var profile := {
		"max_output_tokens": int(_max_tokens.value),
		"collaborator_reply_output_tokens": int(_collaborator_reply_output_v0208.value)
	}
	var effective := CCFCollaboratorTokenBudgetCurrent.requested_output_tokens(profile)
	var context_window := int(_context_window_tokens_v0151.value) if _context_window_tokens_v0151 != null else 0
	if context_window <= 0:
		_collaborator_input_allowance_v0208.text = (
			"Unknown context window. Effective reply request: %s tokens; input is not blocked locally."
			% _formatted_token_count_v0208(effective)
		)
		return
	var available := maxi(0, context_window - effective)
	_collaborator_input_allowance_v0208.text = (
		"%s tokens = %s total context − %s effective reply request."
		% [
			_formatted_token_count_v0208(available),
			_formatted_token_count_v0208(context_window),
			_formatted_token_count_v0208(effective)
		]
	)


func _formatted_token_count_v0208(value: int) -> String:
	var digits := str(maxi(0, value))
	var result := ""
	while digits.length() > 3:
		result = ",%s%s" % [digits.substr(digits.length() - 3), result]
		digits = digits.substr(0, digits.length() - 3)
	return digits + result
