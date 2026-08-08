extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V01540_AI_ACTIVITY_REGRESSION_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _record(
	job_id: String,
	label: String,
	status: String,
	job_type: String = "idea_generation",
	parent_id: String = ""
) -> Dictionary:
	return {
		"job_id": job_id,
		"label": label,
		"worker_label": "Idea Generator",
		"status": status,
		"job_type": job_type,
		"parent_id": parent_id
	}


func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	if not _require(scene != null, "The real v0.15.40 main scene must load."):
		return
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame

	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		workspace_value is CCFWorkspaceV01540View,
		"The live app must install the v0.15.40 Workspace."
	):
		return
	var workspace := workspace_value as CCFWorkspaceV01540View
	var status_value: Variant = workspace.get("_status")
	if not _require(status_value is Label, "Workspace must expose its normal status label."):
		return
	var status_label := status_value as Label

	var caps := workspace.workspace_ai_activity_capabilities_v01540()
	if not _require(bool(caps.get("authoritative_ai_jobs_state", false)), "AI Jobs state must be authoritative for Workspace AI activity."):
		return
	if not _require(bool(caps.get("clears_stale_activity_when_idle", false)), "v0.15.40 must advertise stale activity cleanup."):
		return

	# Reproduce the reported bug: the queue is empty but the old activity text remains.
	status_label.text = "Generating ideas…"
	workspace.set("_ai_activity_status_owned_v01540", true)
	workspace.set("_ai_activity_last_rendered_v01540", "Generating ideas…")
	workspace.set("_ai_activity_last_job_id_v01540", "ideas-1")
	workspace.call("_reconcile_workspace_ai_activity_from_records_v01540", [])
	if not _require(status_label.text == "Ready.", "Idle AI Jobs state must clear stale 'Generating ideas…' text."):
		return
	if not _require(not bool(workspace.get("_ai_activity_status_owned_v01540")), "Idle cleanup must release AI ownership of the Workspace status."):
		return

	# Running work should become the visible activity.
	workspace.call(
		"_reconcile_workspace_ai_activity_from_records_v01540",
		[
			_record("ideas-2", "Generating ideas", "running"),
			_record("character-1", "Generating character", "queued", "character_generation")
		]
	)
	if not _require(status_label.text == "Generating ideas…", "Running work must take priority over queued work."):
		return

	# Finishing one job while another remains must switch to the remaining live job.
	workspace.call(
		"_reconcile_workspace_ai_activity_from_records_v01540",
		[_record("character-1", "Generating character", "running", "character_generation")]
	)
	if not _require(status_label.text == "Generating character…", "Finishing one job must switch the status to another live job."):
		return
	if not _require(str(workspace.get("_ai_activity_last_job_id_v01540")) == "character-1", "The remaining live job must become the tracked activity owner."):
		return

	# Queued/capacity/dependency states are still legitimate live activity.
	workspace.call(
		"_reconcile_workspace_ai_activity_from_records_v01540",
		[_record("ideas-3", "Generating ideas", "waiting_capacity")]
	)
	if not _require(status_label.text.contains("waiting for AI capacity"), "Capacity waiting must remain visible as live AI activity."):
		return
	workspace.call(
		"_reconcile_workspace_ai_activity_from_records_v01540",
		[_record("ideas-4", "Generating ideas", "queued")]
	)
	if not _require(status_label.text.contains("queued"), "Queued work must remain visible as live AI activity."):
		return

	# A later non-AI status message must never be erased merely because the queue goes idle.
	workspace.set("_ai_activity_status_owned_v01540", true)
	workspace.set("_ai_activity_last_rendered_v01540", "Generating ideas…")
	workspace.set("_ai_activity_last_job_id_v01540", "ideas-5")
	status_label.text = "Saved at 12:34:56"
	workspace.call("_reconcile_workspace_ai_activity_from_records_v01540", [])
	if not _require(status_label.text == "Saved at 12:34:56", "Idle cleanup must preserve a newer non-AI Workspace status message."):
		return

	# Lifecycle state is primary: a genuinely running child outranks a parent that
	# is only coordinating the build.
	workspace.call(
		"_reconcile_workspace_ai_activity_from_records_v01540",
		[
			_record("character-2", "Generating character", "coordinating", "character_generation"),
			_record("character-2::scenario", "Scenario", "running", "safe_section", "character-2")
		]
	)
	if not _require(status_label.text.begins_with("Scenario"), "A genuinely running child must outrank a coordinating parent while work is active."):
		return

	# At equal lifecycle state, prefer the top-level job so the general Workspace
	# status does not flicker through internal section labels.
	workspace.call(
		"_reconcile_workspace_ai_activity_from_records_v01540",
		[
			_record("character-3", "Generating character", "running", "character_generation"),
			_record("character-3::scenario", "Scenario", "running", "safe_section", "character-3")
		]
	)
	if not _require(status_label.text == "Generating character…", "A running parent must win the tie against its running Safe Section child."):
		return

	workspace.call("_reconcile_workspace_ai_activity_from_records_v01540", [])
	if not _require(status_label.text == "Ready.", "Final idle transition must clear the last owned AI activity message."):
		return

	app.queue_free()
	await process_frame
	print("v0.15.40 Workspace AI activity lifecycle regression passed")
	quit(0)
