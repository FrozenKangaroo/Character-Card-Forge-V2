extends SceneTree

const TEST_USER_DATA_ISOLATION = preload("res://tools/test_user_data_isolation.gd")
var _test_user_data_isolation := TEST_USER_DATA_ISOLATION.activate(
	"v02114-idea-prompt-provenance"
)

const PROVENANCE = preload(
	"res://scripts/services/idea_prompt_provenance_v02114.gd"
)
const DIVERSITY = preload(
	"res://scripts/services/idea_diversity_guardrails_v0214.gd"
)
const REVIEW = preload(
	"res://scripts/services/idea_final_review_service_v0218.gd"
)
const NOTEBOOK = preload(
	"res://scripts/services/idea_notebook_service_v01532.gd"
)
const IDEA_PACK = preload(
	"res://scripts/services/idea_pack_service_v0210.gd"
)
const IDEA_WINDOW = preload(
	"res://scripts/ui/idea_generator_window_current.gd"
)

var _failed := false
var _library_root := "user://v02114-prompt-library"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	NOTEBOOK.set_storage_root_for_testing(_library_root)
	var saved := _test_per_idea_prompt_and_library_save()
	_test_idea_pack_round_trip(saved)
	await _test_library_ui(saved)
	NOTEBOOK.reset_storage_root_after_testing()
	if _failed:
		quit(1)
		return
	print("V02114_IDEA_PROMPT_PROVENANCE_OK")
	quit(0)


func _test_per_idea_prompt_and_library_save() -> Array[Dictionary]:
	var prompt_a := "Generate reunions with an old friend in a seaside town."
	var context_a := {
		"prompt_mode": "primary_prompt",
		"seed_text": prompt_a,
		"series_context": "SERIES CONTEXT: Coastline stories"
	}
	var initial := DIVERSITY.create_session(1, 1, true, "off", false, context_a)
	initial["seed_snapshot"] = prompt_a
	DIVERSITY.record_batch(initial, [{
		"title": "Harbour Return",
		"concept": "An old friend returns while the harbour closes for a storm."
	}])
	var curation := REVIEW.create_curation_session(initial, {})
	var prompt_b := "Set the next idea at an Antarctic research station."
	var extension := REVIEW.create_extension_session(curation, 1, 1, prompt_b)
	DIVERSITY.record_batch(extension, [{
		"title": "Whiteout Reunion",
		"concept": "A former friend arrives during an Antarctic whiteout."
	}])
	var generated := DIVERSITY.accepted_ideas(extension)
	_require(generated.size() == 2, "The extension must retain the old Idea and append the new one.")
	_require(
		PROVENANCE.reusable_prompt(generated[0]) == prompt_a
		and PROVENANCE.reusable_prompt(generated[1]) == prompt_b,
		"Every Idea must retain the prompt from the request that actually generated it."
	)
	var saved: Array[Dictionary] = []
	for generated_idea in generated:
		var result := NOTEBOOK.save_generated_idea(generated_idea, "", {
			"type": "idea_generator",
			"seed_prompt": "Incorrect aggregate fallback"
		})
		_require(bool(result.get("ok", false)), "Generated Ideas must save to the Idea Library.")
		if bool(result.get("ok", false)):
			saved.append(result.get("idea", {}) as Dictionary)
	_require(
		saved.size() == 2
		and str((saved[0].get("source", {}) as Dictionary).get("generation_prompt", "")) == prompt_a
		and str((saved[1].get("source", {}) as Dictionary).get("generation_prompt", "")) == prompt_b,
		"Saving must prefer per-Idea provenance over stale batch-level prompt metadata."
	)
	for idea in saved:
		_require(
			not idea.has(PROVENANCE.INTERNAL_KEY)
			and str((idea.get("source", {}) as Dictionary).get("seed_prompt", ""))
			== PROVENANCE.reusable_prompt(idea),
			"Saved records must be portable and retain the legacy seed_prompt alias."
		)
	var legacy := {"source": {"seed_prompt": "Legacy prompt"}}
	_require(
		PROVENANCE.reusable_prompt(legacy) == "Legacy prompt"
		and PROVENANCE.reusable_prompt({}).is_empty(),
		"Legacy Ideas with seed_prompt and old Ideas without any prompt must both remain supported."
	)
	return saved


func _test_idea_pack_round_trip(saved: Array[Dictionary]) -> void:
	var exporter := IDEA_PACK.new(_library_root)
	var pack := exporter.build_export_pack(saved, {
		"id": "prompt-round-trip",
		"title": "Prompt round trip"
	})
	var entries: Array = pack.get("entries", [])
	_require(
		entries.size() == 2
		and not str((entries[0] as Dictionary).get("generation_prompt", "")).is_empty(),
		"Idea Pack entries must carry the optional original generation prompt."
	)
	var preview := exporter.parse_text(JSON.stringify(pack))
	_require(
		bool(preview.get("ok", false)) and bool(preview.get("import_allowed", false)),
		"An Idea Pack containing generation_prompt must remain valid and importable."
	)
	var rendered := exporter.render_entry_for_generation(entries[0] as Dictionary)
	_require(
		not rendered.contains(str((entries[0] as Dictionary).get("generation_prompt", ""))),
		"Prompt provenance must not be injected into an Idea's conceptual generation text."
	)
	var importer := IDEA_PACK.new("user://v02114-prompt-import")
	var imported_preview := importer.parse_text(JSON.stringify(pack))
	var imported := importer.import_preview(imported_preview, [
		{"index": 0, "selected": true, "action": "import"},
		{"index": 1, "selected": true, "action": "import"}
	])
	var imported_ideas := importer.list_local_ideas()
	_require(
		bool(imported.get("ok", false))
		and imported_ideas.size() == 2
		and not PROVENANCE.reusable_prompt(imported_ideas[0]).is_empty(),
		"Idea Pack import must restore reusable prompt provenance."
	)
	var old_pack := pack.duplicate(true)
	for entry_value in old_pack.get("entries", []):
		if entry_value is Dictionary:
			(entry_value as Dictionary).erase("generation_prompt")
	var old_preview := exporter.parse_text(JSON.stringify(old_pack))
	_require(
		bool(old_preview.get("ok", false)) and bool(old_preview.get("import_allowed", false)),
		"Older Idea Packs without generation_prompt must remain fully supported."
	)


func _test_library_ui(saved: Array[Dictionary]) -> void:
	var window := IDEA_WINDOW.new()
	root.add_child(window)
	await process_frame
	await process_frame
	window.call("_load_selected_idea_v01532", str(saved[0].get("id", "")))
	var prompt_text := window.find_child("OriginalIdeaPromptTextV02114", true, false) as TextEdit
	var reuse_button := window.find_child("ReuseOriginalPromptV02114", true, false) as Button
	var emitted := {"prompt": ""}
	window.original_prompt_requested_v02114.connect(func(prompt: String) -> void:
		emitted["prompt"] = prompt
	)
	if reuse_button != null:
		reuse_button.pressed.emit()
	_require(
		prompt_text != null
		and reuse_button != null
		and not reuse_button.disabled
		and prompt_text.text == PROVENANCE.reusable_prompt(saved[0])
		and str(emitted.get("prompt", "")) == prompt_text.text,
		"Idea Library must show the stored prompt and send it back through the generator action."
	)
	window.queue_free()
	await process_frame


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
