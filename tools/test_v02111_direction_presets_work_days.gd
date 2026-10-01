extends SceneTree

const SOURCE_SERVICE = preload(
	"res://scripts/services/idea_source_service_v0213.gd"
)
const WORK_DAYS = preload(
	"res://scripts/services/front_porch_work_days_v02111.gd"
)
const FRONT_PORCH_SERVICE = preload(
	"res://scripts/services/front_porch_extension_service_current.gd"
)
const GENERATION_SERVICE = preload(
	"res://scripts/services/generation_service_current.gd"
)

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_direction_preset_contract()
	_test_work_days_contract()
	if _failed:
		quit(1)
		return
	print("V02111_DIRECTION_PRESETS_WORK_DAYS_OK")
	quit(0)


func _test_direction_preset_contract() -> void:
	var service := SOURCE_SERVICE.new()
	var source := service.blank_source()
	source["id"] = "preset-test-source"
	source["core_premise"] = "A reusable relationship engine."
	source["direction_presets"] = [
		{
			"id": "workplace", "group": "Setting",
			"title": "Workplace", "direction": "Focus on workplace scenarios.",
			"future": {"preserved": true}
		},
		{
			"id": "quiet", "group": "Tone",
			"title": "Quiet", "direction": "Use a quiet, reflective tone."
		}
	]
	var parsed := service.parse_text(JSON.stringify(source))
	var normalised: Dictionary = parsed.get("source", {})
	var presets := service.direction_presets(normalised)
	var context := service.generation_context(normalised)
	var prepared := service.compose_generation_input(
		context, str(presets[0].get("direction", ""))
	)
	_require(
		bool(parsed.get("load_allowed", false))
		and presets.size() == 2
		and bool((presets[0].get("future", {}) as Dictionary).get("preserved", false))
		and not context.contains("Focus on workplace scenarios.")
		and prepared.count("Focus on workplace scenarios.") == 1,
		"Presets must preserve order/future fields and enter generation only through Additional Direction."
	)
	var duplicated := source.duplicate(true)
	(duplicated["direction_presets"] as Array)[1]["id"] = "workplace"
	var invalid := service.parse_text(JSON.stringify(duplicated))
	_require(
		not bool(invalid.get("ok", true)),
		"Duplicate preset IDs must be rejected safely."
	)


func _test_work_days_contract() -> void:
	var cases := [
		[[1, 2, 3, 4, 5], [1, 2, 3, 4, 5]],
		["1, 2, 3, 4, 5", [1, 2, 3, 4, 5]],
		[["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"], [1, 2, 3, 4, 5]],
		[["Mon", "Wed", "Fri"], [1, 3, 5]],
		["Monday-Friday", [1, 2, 3, 4, 5]],
		["Monday to Friday", [1, 2, 3, 4, 5]],
		["Mon-Fri", [1, 2, 3, 4, 5]],
		["weekdays", [1, 2, 3, 4, 5]],
		["Saturday-Sunday", [6, 7]],
		["weekends", [6, 7]]
	]
	for case_value in cases:
		var case: Array = case_value
		var parsed := WORK_DAYS.normalise(case[0])
		_require(
			bool(parsed.get("ok", false)) and parsed.get("value", []) == case[1],
			"Supported Work Days input failed: %s" % JSON.stringify(case[0])
		)
	var invalid := WORK_DAYS.normalise("I usually work weekdays except holidays")
	_require(not bool(invalid.get("ok", true)), "Ambiguous Work Days prose must be rejected.")

	var extension := FRONT_PORCH_SERVICE.new()
	var project := CCFStorageService.new_project()
	var character_id := str(project.get("characters", [])[0].get("character_id", ""))
	var document := CCFStorageService.character_workspace_document(project, character_id)
	var applied := extension.apply_control_values(
		document,
		{"fp_work_days": true},
		{"fp_work_days": ["Monday", "Wednesday", "Friday"]},
		false
	)
	_require(
		bool(applied.get("ok", false))
		and CCFStorageService.get_value_at_path(
			document,
			"character.card_extensions.front_porch.realism_engine.workDays",
			[]
		) == [1, 3, 5]
		and extension.is_included(document, extension.field_by_id("fp_work_days")),
		"Applying generated day names must enable Work Days and store canonical IDs."
	)

	CCFStorageService.set_value_at_path(document, "concept.prompt", "A weekday worker.")
	var generator := GENERATION_SERVICE.new()
	var queued := generator.queue_front_porch_fields_v0172(
		document,
		[extension.field_by_id("fp_work_days")],
		{
			"name": "Offline", "base_url": "http://127.0.0.1:1/v1",
			"model": "offline", "max_output_tokens": 256
		},
		0,
		"Work days"
	)
	var jobs: Array = generator.get("_queue")
	var prompt := JSON.stringify((jobs[0] as Dictionary).get("payload", {})) if not jobs.is_empty() else ""
	_require(
		bool(queued.get("ok", false))
		and prompt.contains("Monday=1")
		and prompt.contains("Sunday=7")
		and prompt.contains("[1,2,3,4,5]")
		and prompt.contains("Never return day-name prose"),
		"The provider prompt must give the full canonical Work Days mapping and example."
	)
	generator.free()


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)

