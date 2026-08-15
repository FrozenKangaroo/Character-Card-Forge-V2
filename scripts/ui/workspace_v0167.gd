class_name CCFWorkspaceV0167View
extends "res://scripts/ui/workspace_v0160.gd"

const GENERATION_SERVICE_V0167 = preload(
	"res://scripts/services/generation_service_v0167.gd"
)
const DETAIL_LEVEL_SERVICE_V0167 = preload(
	"res://scripts/services/idea_generator_detail_level_service_v0167.gd"
)

var _idea_detail_service_v0167 := DETAIL_LEVEL_SERVICE_V0167.new()
var _idea_detail_selector_v0167: OptionButton
var _idea_detail_hint_v0167: Label
var _selected_idea_detail_level_v0167 := "standard"


func _build_idea_window() -> void:
	super._build_idea_window()
	_install_idea_detail_selector_v0167()


func _create_worker_service_v01526(
	worker_id: String, worker_label: String, job_number_base: int
) -> CCFGenerationServiceV01526:
	var service := GENERATION_SERVICE_V0167.new() as CCFGenerationServiceV01526
	add_child(service)
	service.configure_scheduler_v01526(
		_ai_scheduler_v01526, worker_id, worker_label, job_number_base
	)
	service.job_started.connect(_on_job_started)
	service.job_completed.connect(_on_job_completed)
	service.job_failed.connect(_on_job_failed)
	service.job_cancelled.connect(_on_job_cancelled)
	service.queue_changed.connect(_on_worker_queue_changed_v01526)
	service.diagnostics_available.connect(_on_generation_diagnostics_available_v01522)
	return service


func _generate_ideas() -> void:
	var profile := CCFSettingsService.profile_for_role(
		_settings, CCFSettingsService.ROLE_TEXT
	)
	var clean_level := _idea_detail_service_v0167.normalise_level_id(
		_selected_idea_detail_level_v0167
	)
	var result: Dictionary
	if (
		_generation_service != null
		and _generation_service.has_method("queue_idea_generation_with_detail_v0167")
	):
		result = _generation_service.call(
			"queue_idea_generation_with_detail_v0167",
			_idea_seed.text,
			profile,
			int(_idea_count.value),
			int(_generation_settings().get("retry_count", 1)),
			str(_project.get("project_id", "")),
			CCFSeriesService.generation_context_for_project(_project),
			clean_level
		) as Dictionary
	else:
		result = _generation_service.queue_idea_generation(
			_idea_seed.text,
			profile,
			int(_idea_count.value),
			int(_generation_settings().get("retry_count", 1)),
			str(_project.get("project_id", "")),
			CCFSeriesService.generation_context_for_project(_project)
		)
	if not bool(result.get("ok", false)):
		_idea_status.text = str(
			result.get("error", "Could not queue idea generation.")
		)
		return
	_idea_job_id = str(result.get("job_id", ""))
	_idea_generate_button.disabled = true
	var queued_ahead := int(result.get("queued_ahead", 0))
	_idea_status.text = (
		"Queued • %s detail%s"
		% [
			_idea_detail_service_v0167.label_for(clean_level),
			(" behind %d job(s)" % queued_ahead if queued_ahead > 0 else "")
		]
	)


func idea_detail_level_capabilities_v0167() -> Dictionary:
	return {
		"format_version": 1,
		"selector": true,
		"default_level": _idea_detail_service_v0167.default_level_id(),
		"selected_level": _selected_idea_detail_level_v0167,
		"levels": _idea_detail_service_v0167.ordered_levels(),
		"session_persistence": true,
		"provider_budget_forwarding": true
	}


func _install_idea_detail_selector_v0167() -> void:
	if _idea_window == null or _idea_count == null:
		return
	var controls := _idea_count.get_parent() as HBoxContainer
	if controls == null:
		return

	var label := Label.new()
	label.name = "IdeaDetailLevelLabelV0167"
	label.text = "Detail"
	controls.add_child(label)
	controls.move_child(label, _idea_count.get_index() + 1)

	_idea_detail_selector_v0167 = OptionButton.new()
	_idea_detail_selector_v0167.name = "IdeaDetailLevelSelectorV0167"
	_idea_detail_selector_v0167.custom_minimum_size.x = 145
	controls.add_child(_idea_detail_selector_v0167)
	controls.move_child(
		_idea_detail_selector_v0167, label.get_index() + 1
	)

	var default_level := _idea_detail_service_v0167.default_level_id()
	_selected_idea_detail_level_v0167 = default_level
	var selected_index := 0
	var levels := _idea_detail_service_v0167.ordered_levels()
	for index in range(levels.size()):
		var level: Dictionary = levels[index]
		var level_id := str(level.get("id", ""))
		_idea_detail_selector_v0167.add_item(
			str(level.get("label", level_id.capitalize()))
		)
		_idea_detail_selector_v0167.set_item_metadata(index, level_id)
		if level_id == default_level:
			selected_index = index
	if _idea_detail_selector_v0167.item_count > 0:
		_idea_detail_selector_v0167.select(selected_index)
	_idea_detail_selector_v0167.item_selected.connect(
		_on_idea_detail_selected_v0167
	)
	_idea_detail_selector_v0167.tooltip_text = (
		"Controls how deeply each generated concept is developed. "
		+ "It changes the prompt contract and output budget, not the number of ideas."
	)

	_idea_detail_hint_v0167 = Label.new()
	_idea_detail_hint_v0167.name = "IdeaDetailLevelHintV0167"
	_idea_detail_hint_v0167.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_idea_detail_hint_v0167.modulate = Color(0.64, 0.68, 0.82)
	var root := controls.get_parent() as VBoxContainer
	if root != null:
		root.add_child(_idea_detail_hint_v0167)
		root.move_child(_idea_detail_hint_v0167, controls.get_index() + 1)
	_refresh_idea_detail_hint_v0167()


func _on_idea_detail_selected_v0167(index: int) -> void:
	if (
		_idea_detail_selector_v0167 == null
		or index < 0
		or index >= _idea_detail_selector_v0167.item_count
	):
		_selected_idea_detail_level_v0167 = (
			_idea_detail_service_v0167.default_level_id()
		)
	else:
		_selected_idea_detail_level_v0167 = (
			_idea_detail_service_v0167.normalise_level_id(
				str(_idea_detail_selector_v0167.get_item_metadata(index))
			)
		)
	_refresh_idea_detail_hint_v0167()


func _refresh_idea_detail_hint_v0167() -> void:
	if _idea_detail_hint_v0167 == null:
		return
	var level := _idea_detail_service_v0167.level_by_id(
		_selected_idea_detail_level_v0167
	)
	_idea_detail_hint_v0167.text = "%s — %s" % [
		str(level.get("label", "Standard")),
		str(level.get("description", "Balanced detail for normal character ideation."))
	]
