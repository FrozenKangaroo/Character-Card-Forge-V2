extends SceneTree

const TEST_USER_DATA_ISOLATION = preload("res://tools/test_user_data_isolation.gd")
var _test_user_data_isolation := TEST_USER_DATA_ISOLATION.activate(
	"v02119-front-porch-trait-kit"
)

const SAMPLE_KIT := [
	{
		"kind": "boon",
		"text": "example novie boon",
		"tier": "emerging",
		"pinned": false
	},
	{
		"kind": "boon",
		"text": "example skilled boon",
		"tier": "developing",
		"pinned": false
	},
	{
		"kind": "bogey",
		"text": "example novice bogey",
		"tier": "emerging",
		"pinned": false
	},
	{
		"kind": "bogey",
		"text": "example skilled bogey",
		"tier": "developing",
		"pinned": true
	},
	{
		"kind": "bogey",
		"text": "example novice bogey that pushes against boon",
		"tier": "emerging",
		"pinned": false,
		"linkedTo": "example novie boon"
	},
]


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V02119_FRONT_PORCH_TRAIT_KIT_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var service := CCFFrontPorchExtensionServiceCurrent.new()
	if not _test_field_contract(service):
		return
	if not _test_card_round_trip(service):
		return
	if not _test_limits(service):
		return
	if not _test_links_and_unknown_keys(service):
		return
	if not await _test_ai_preview_apply(service):
		return
	if not _test_control_link_behaviour():
		return
	var capabilities := service.capabilities()
	if not _require(
		str(capabilities.get("trait_kit_field_id", "")) == "fp_trait_kit"
		and int(capabilities.get("trait_kit_max_entries", 0)) == 6
		and int(capabilities.get("trait_kit_max_bogeys", 0)) == 3
		and capabilities.get("trait_kit_tiers", [])
		== ["emerging", "developing", "established"],
		"Capabilities must describe the Front Porch Boons & Bogies contract."
	):
		return
	print("V02119_FRONT_PORCH_TRAIT_KIT_OK")
	quit(0)


func _test_field_contract(
	service: CCFFrontPorchExtensionServiceCurrent
) -> bool:
	var field := service.field_by_id("fp_trait_kit")
	if not _require(
		not field.is_empty() and str(field.get("type", "")) == "trait_kit",
		"The Front Porch catalog must expose the trait kit as its own field type."
	):
		return false
	if not _require(
		service.full_project_path(field)
		== "character.card_extensions.front_porch.realism_engine.traitKit",
		"The trait kit must map onto Rawhide's realism_engine.traitKit property."
	):
		return false
	var help := str(field.get("help_text", ""))
	return _require(
		help.contains("six") and help.contains("three bogies") and help.contains("0.60"),
		"The help text must state the six-entry and three-bogey caps and the seeding strengths."
	)


func _test_card_round_trip(
	service: CCFFrontPorchExtensionServiceCurrent
) -> bool:
	var card := _sample_card()
	var imported := CCFCardFormatService.import_card_to_project(card, "json")
	if not _require(bool(imported.get("ok", false)), "The sample card must import."):
		return false
	var project: Dictionary = imported.get("project", {})
	var character_id := CCFStorageService.active_character_id(project)
	var document := CCFStorageService.character_workspace_document(
		project, character_id
	)
	var field := service.field_by_id("fp_trait_kit")
	var value: Variant = service.value_for(document, field)
	if not _require(
		service.is_included(document, field)
		and value is Array
		and (value as Array).size() == SAMPLE_KIT.size(),
		"Import must keep every boon and bogey entry."
	):
		return false
	if not _require(
		str((value as Array)[4].get("linkedTo", "")) == "example novie boon",
		"Import must keep a bogey's linked boon."
	):
		return false

	var exported := CCFCardFormatService.export_character_v2(project, character_id)
	var realism: Dictionary = CCFStorageService.get_value_at_path(
		exported, "data.extensions.front_porch.realism_engine", {}
	)
	if not _require(
		realism.get("traitKit") == SAMPLE_KIT,
		"Export must reproduce the trait kit byte-for-byte."
	):
		return false

	var reimported := CCFCardFormatService.import_card_to_project(exported, "json")
	if not _require(
		bool(reimported.get("ok", false)),
		"The exported card must re-import."
	):
		return false
	var second_project: Dictionary = reimported.get("project", {})
	var second_id := CCFStorageService.active_character_id(second_project)
	var second_document := CCFStorageService.character_workspace_document(
		second_project, second_id
	)
	return _require(
		service.value_for(second_document, field) == SAMPLE_KIT,
		"A second round trip must not reorder, trim or reword the kit."
	)


func _test_limits(
	service: CCFFrontPorchExtensionServiceCurrent
) -> bool:
	var too_many: Array = []
	for index in range(7):
		too_many.append({
			"kind": "boon", "text": "boon %d" % index,
			"tier": "emerging", "pinned": false
		})
	if not _require(
		not bool(service.normalise_trait_kit_v02119(too_many).get("ok", true)),
		"Seven entries must be rejected: the card cap is six combined."
	):
		return false

	var too_many_bogeys: Array = []
	for index in range(4):
		too_many_bogeys.append({
			"kind": "bogey", "text": "bogey %d" % index,
			"tier": "emerging", "pinned": false
		})
	if not _require(
		not bool(
			service.normalise_trait_kit_v02119(too_many_bogeys).get("ok", true)
		),
		"Four bogeys must be rejected: card bogies share the three-flaw budget."
	):
		return false

	var duplicate: Array = [
		{"kind": "boon", "text": "Same", "tier": "emerging", "pinned": false},
		{"kind": "bogey", "text": "same", "tier": "emerging", "pinned": false},
	]
	if not _require(
		not bool(service.normalise_trait_kit_v02119(duplicate).get("ok", true)),
		"Duplicate text must be rejected regardless of kind or case."
	):
		return false

	var bad_tier: Array = [
		{"kind": "boon", "text": "x", "tier": "legendary", "pinned": false}
	]
	if not _require(
		not bool(service.normalise_trait_kit_v02119(bad_tier).get("ok", true)),
		"An unknown tier must be rejected rather than silently downgraded."
	):
		return false
	return _require(
		not bool(service.normalise_trait_kit_v02119("not an array").get("ok", true)),
		"A non-array trait kit must be rejected."
	)


func _test_links_and_unknown_keys(
	service: CCFFrontPorchExtensionServiceCurrent
) -> bool:
	var link_to_missing: Array = [
		{"kind": "boon", "text": "steady hands", "tier": "emerging", "pinned": false},
		{
			"kind": "bogey", "text": "clumsy", "tier": "emerging",
			"pinned": true, "linkedTo": "steady hands (typo)"
		},
	]
	if not _require(
		not bool(
			service.normalise_trait_kit_v02119(link_to_missing).get("ok", true)
		),
		"A link that names no boon in the kit must be rejected."
	):
		return false

	var boon_with_link: Array = [
		{
			"kind": "boon", "text": "steady hands", "tier": "emerging",
			"pinned": false, "linkedTo": "steady hands"
		}
	]
	if not _require(
		not bool(
			service.normalise_trait_kit_v02119(boon_with_link).get("ok", true)
		),
		"Only a bogey may carry linkedTo."
	):
		return false

	var with_future_key: Array = [
		{
			"kind": "boon", "text": "steady hands", "tier": "developing",
			"pinned": false, "futureFrontPorchFlag": true
		},
		{
			"kind": "bogey", "text": "clumsy", "tier": "emerging",
			"pinned": true, "linkedTo": "steady hands"
		},
	]
	var normalised := service.normalise_trait_kit_v02119(with_future_key)
	if not _require(
		bool(normalised.get("ok", false)),
		"A valid kit with a future per-entry key must normalise."
	):
		return false
	var entries: Array = normalised.get("value", [])
	return _require(
		entries[0].get("futureFrontPorchFlag") == true
		and entries[1].get("linkedTo") == "steady hands",
		"Unknown per-entry keys must survive normalisation."
	)


func _sample_card() -> Dictionary:
	return {
		"spec": "chara_card_v2",
		"spec_version": "2.0",
		"data": {
			"name": "Trait Kit Sample",
			"description": "A card that carries a Boons & Bogies kit.",
			"personality": "Careful.",
			"scenario": "A workshop.",
			"first_mes": "Hello.",
			"mes_example": "",
			"system_prompt": "",
			"post_history_instructions": "",
			"alternate_greetings": [],
			"tags": [],
			"creator": "",
			"character_version": "",
			"extensions": {
				"front_porch": {
					"version": "2.5",
					"realism_engine": {
						"enabled": false,
						"traitKit": SAMPLE_KIT.duplicate(true),
					},
				},
			},
		},
	}


# The AI proposal path is separate from the form: the review window builds its
# own editor per field, and only then applies the value. A valid kit proposal
# must survive that pipeline, not just the main form.
func _test_ai_preview_apply(
	service: CCFFrontPorchExtensionServiceCurrent
) -> bool:
	var workspace := CCFWorkspaceCurrent.new()
	root.add_child(workspace)
	await process_frame
	await process_frame
	await process_frame

	var project := CCFStorageService.new_project()
	workspace.load_project(
		project,
		CCFTemplateService.load_default_template(),
		CCFSettingsService.load_settings()
	)
	await process_frame
	await process_frame

	var field := service.field_by_id("fp_trait_kit")
	workspace.set("_preview_metadata", {"front_porch_generation_contract": 1})
	var loaded_document: Dictionary = workspace.get("_project")
	workspace.set(
		"_preview_project_id", str(loaded_document.get("project_id", ""))
	)
	workspace.set("_preview_rows", [])
	workspace.call(
		"_add_front_porch_trait_kit_preview_row_v02119", field, [], SAMPLE_KIT
	)
	if not _require(
		(workspace.get("_preview_rows") as Array).size() == 1,
		"The review window must build one trait-kit row for an AI proposal."
	):
		workspace.queue_free()
		return false
	var row: Dictionary = (workspace.get("_preview_rows") as Array)[0]
	var editor: Variant = row.get("editor")
	if not _require(
		editor is CCFFrontPorchTraitKitControlV02119,
		"The trait-kit review row must use the structured editor, not a text box."
	):
		workspace.queue_free()
		return false
	(editor as CCFFrontPorchTraitKitControlV02119).set_editable(true)
	workspace.call("_apply_preview")
	await process_frame

	var document: Dictionary = workspace.get("_project")
	var applied: Variant = CCFStorageService.get_value_at_path(
		document,
		"character.card_extensions.front_porch.realism_engine.traitKit",
		null
	)
	var ok: bool = applied == SAMPLE_KIT
	if not ok:
		_fail(
			"Applying a valid AI trait-kit proposal must store the array, got %s."
			% str(applied)
		)
	workspace.queue_free()
	return ok


# Findings 2 and 3 from the PR review: renaming a boon must move the links, and
# a link the author clears must stay cleared across later rebuilds.
func _test_control_link_behaviour() -> bool:
	var boon_text := "reads a room fast"
	var control := CCFFrontPorchTraitKitControlV02119.new()
	control.set_items([
		{"kind": "boon", "text": boon_text, "tier": "emerging", "pinned": false},
		{
			"kind": "bogey", "text": "talks over people", "tier": "emerging",
			"pinned": true, "linkedTo": boon_text
		},
	])
	control.set_editable(true)

	var editors := control.find_children("TextV02119", "TextEdit", true, false)
	if not _require(
		editors.size() == 2,
		"The control must build one text editor per entry."
	):
		control.free()
		return false
	var boon_editor := editors[0] as TextEdit
	var bogey_panel := _row_panel_for(boon_editor)
	boon_editor.text = "reads a room instantly"
	control.call("_on_text_changed", bogey_panel)
	var entries: Array = control.items_value()
	if not _require(
		str(entries[1].get("linkedTo", "")) == "reads a room instantly",
		"Renaming a boon must move every link that pointed at its old text."
	):
		control.free()
		return false

	var link_selects := control.find_children("LinkV02119", "OptionButton", true, false)
	if not _require(
		link_selects.size() == 2,
		"Every entry must carry a link selector, hidden for boons."
	):
		control.free()
		return false
	# Row order matches the kit, so the bogey's selector is the second one.
	var bogey_link := link_selects[1] as OptionButton
	var bogey_panel_for_link := _row_panel_for(bogey_link)
	bogey_link.select(0)
	control.call("_on_link_selected", 0, bogey_panel_for_link)
	control.call("_refresh_all")
	entries = control.items_value()
	if not _require(
		not entries[1].has("linkedTo"),
		"Clearing a link must survive the next rebuild of the link selectors."
	):
		control.free()
		return false
	control.free()
	return true


func _row_panel_for(control: Control) -> PanelContainer:
	var node: Node = control
	while node != null and not node is PanelContainer:
		node = node.get_parent()
	return node as PanelContainer
