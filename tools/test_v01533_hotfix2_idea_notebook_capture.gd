extends SceneTree

const NOTEBOOK_SERVICE = preload(
	"res://scripts/services/idea_notebook_service_v01532.gd"
)
const GENERATION_SERVICE = preload(
	"res://scripts/services/generation_service_v01533.gd"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	assert(packed != null, "The real main scene must load for hotfix2 coverage.")
	var app := packed.instantiate()
	root.add_child(app)
	for _frame in range(6):
		await process_frame

	var workspace_value: Variant = app.get("_workspace")
	assert(
		workspace_value is CCFWorkspaceV01533Hotfix2View,
		"The live app must install the v0.15.33-hotfix2 Workspace."
	)
	var workspace := workspace_value as CCFWorkspaceV01533Hotfix2View
	var capabilities := workspace.idea_notebook_capture_capabilities_v01533_hotfix2()
	assert(str(capabilities.get("current_job_type", "")) == "ideas")
	assert(bool(capabilities.get("all_live_generation_services", false)))
	assert(not bool(capabilities.get("auto_save", true)))

	var generator_value: Variant = workspace.get("_idea_generator_v01532")
	assert(
		generator_value is CCFIdeaGeneratorWindowV01533Hotfix1,
		"The hotfix2 Workspace must preserve the v0.15.33-hotfix1 Idea Generator."
	)
	var generator := generator_value as CCFIdeaGeneratorWindowV01533Hotfix1
	generator.set_last_generated_ideas_v01532([], {})
	var save_button := generator.get("_save_generated_button_v01532") as Button
	var develop_button := generator.get("_develop_generated_button_v01533") as Button
	var batch_label := generator.get("_last_batch_label_v01532") as Label
	assert(save_button != null and save_button.disabled)
	assert(develop_button != null and develop_button.disabled)

	# Model the architectural failure from the runtime screenshot: the embedded
	# legacy AI Ideas controller can own a compatible live generation service
	# different from Workspace's dedicated _idea_service_v01526 reference. The
	# visible idea cards can therefore complete while a single-worker Notebook
	# listener hears nothing.
	workspace.call("_finish_opening_unified_idea_generator")
	await process_frame
	var legacy_value: Variant = workspace.call("_find_legacy_ai_idea_window")
	var capture_host: Node = workspace
	if legacy_value is Window:
		capture_host = legacy_value as Window
	var alternate_service := GENERATION_SERVICE.new() as CCFGenerationService
	capture_host.add_child(alternate_service)
	await process_frame
	workspace.call("_connect_idea_capture_v01532")

	var before_count := NOTEBOOK_SERVICE.list_ideas({"include_archived": true}).size()
	var source_idea := {
		"title": "Runtime Capture Regression",
		"character_name": "Mira",
		"character_role": "{{user}}'s new stepsister",
		"source_anchor": "new stepsister",
		"roleplay_hook": "Mira and {{user}} must learn how to live under the same roof.",
		"concept": "Mira is {{user}}'s new stepsister after their parents remarry, and the sudden household change gives them an immediate relationship to negotiate.",
		"tags": ["family", "stepsister", "slow-burn"]
	}
	alternate_service.job_completed.emit(
		"regression-visible-ideas",
		"ideas",
		[source_idea.duplicate(true)],
		{
			"seed": "{{user}} suddenly got a new stepsister after their parents remarried",
			"idea_contract_version": "user_centric_roleplay_v3"
		}
	)
	await process_frame

	var captured: Array = generator.get("_last_generated_ideas_v01532")
	assert(
		captured.size() == 1,
		"An Idea completion from another live generation service must reach Idea Notebook."
	)
	assert(not save_button.disabled, "Captured AI Ideas must enable Save Generated Ideas.")
	assert(
		not develop_button.disabled,
		"Captured AI Ideas must enable Develop Generated Idea."
	)
	assert(
		batch_label != null and batch_label.text.contains("1 unsaved generated idea"),
		"The latest-batch status must report the captured result instead of saying no batch was captured."
	)
	assert(
		NOTEBOOK_SERVICE.list_ideas({"include_archived": true}).size() == before_count,
		"Capturing a completed batch must never auto-save it to Idea Notebook."
	)

	# The normal dedicated worker path must remain connected too.
	generator.set_last_generated_ideas_v01532([], {})
	var dedicated_value: Variant = workspace.get("_idea_service_v01526")
	assert(dedicated_value is CCFGenerationService)
	var dedicated := dedicated_value as CCFGenerationService
	dedicated.job_completed.emit(
		"regression-dedicated-ideas",
		"ideas",
		[source_idea.duplicate(true)],
		{"seed": "dedicated worker regression"}
	)
	await process_frame
	captured = generator.get("_last_generated_ideas_v01532")
	assert(captured.size() == 1, "The dedicated Idea worker must retain Notebook capture.")

	app.queue_free()
	await process_frame
	print("v0.15.33-hotfix2 AI Ideas Notebook capture regression passed")
	quit(0)
