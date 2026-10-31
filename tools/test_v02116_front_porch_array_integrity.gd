extends SceneTree

const LIST_CONTROL = preload(
	"res://scripts/ui/front_porch_string_list_control_v02116.gd"
)
const FRONT_PORCH_SERVICE = preload(
	"res://scripts/services/front_porch_extension_service_current.gd"
)
const STORAGE = preload("res://scripts/services/storage_service.gd")
const CARD_FORMAT = preload("res://scripts/services/card_format_service.gd")
const WORKSPACE = preload("res://scripts/ui/workspace_current.gd")


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V02116_FRONT_PORCH_ARRAY_INTEGRITY_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var service = FRONT_PORCH_SERVICE.new()
	if not _test_strict_generation_validation(service):
		return
	if not _test_atomic_list_control():
		return
	if not _test_round_trip(service):
		return
	if not _test_live_preview_preserves_existing(service):
		return
	print("V02116_FRONT_PORCH_ARRAY_INTEGRITY_OK")
	quit(0)


func _test_strict_generation_validation(
	service
) -> bool:
	var ambitions: Dictionary = service.field_by_id("fp_ambitions")
	var valid: Dictionary = service.normalise_generated_preview_value_v02116(
		ambitions,
		[
			"Keep a comfortable, honest, no-strings arrangement alive",
			"Graduate without romantic drama"
		]
	)
	if not _require(
		bool(valid.get("ok", false))
		and valid.get("value", []).size() == 2
		and valid.get("value", [])[0] == (
			"Keep a comfortable, honest, no-strings arrangement alive"
		),
		"A valid generated array must preserve comma-bearing elements atomically."
	):
		return false
	var repeated: Dictionary = service.normalise_generated_preview_value_v02116(
		ambitions, ["Deliberate repeated beat", "Deliberate repeated beat"]
	)
	if not _require(
		repeated.get("value", []).size() == 2,
		"Structured array members must retain order and must not be silently deduplicated."
	):
		return false
	var hostile: Dictionary = service.normalise_generated_preview_value_v02116(
		service.field_by_id("fp_inventory_carrying"),
		[
			"Silver smartphone (two weeks of chats, kept private)",
			"\"秘密\", 鍵 and a folded note\nkept in the inner pocket"
		]
	)
	if not _require(
		bool(hostile.get("ok", false))
		and hostile.get("value", []).size() == 2
		and str(hostile.get("value", [])[0]).contains("chats, kept private")
		and str(hostile.get("value", [])[1]).contains("\n"),
		"Unicode, quotes, parentheses, commas and line breaks must remain inside their source item."
	):
		return false
	var empty: Dictionary = service.normalise_generated_preview_value_v02116(
		ambitions, ["", "   "]
	)
	var malformed: Dictionary = service.normalise_generated_preview_value_v02116(
		ambitions,
		"Keep a comfortable, honest, no-strings arrangement alive"
	)
	var wrong_member: Dictionary = service.normalise_generated_preview_value_v02116(
		ambitions, ["Valid", 7]
	)
	return _require(
		bool(empty.get("ok", false))
		and empty.get("value", []) == []
		and not bool(malformed.get("ok", true))
		and str(malformed.get("error", "")).contains("JSON array of strings")
		and not bool(wrong_member.get("ok", true)),
		"Generated list validation must allow empty arrays but reject strings and non-string members."
	)


func _test_atomic_list_control() -> bool:
	var control = LIST_CONTROL.new()
	root.add_child(control)
	var values := [
		"Confident, assertive partners",
		"Sundress (rain-soaked, hem torn)",
		"A two-line qualification\nthat remains one item"
	]
	control.set_items(values)
	if not _require(
		control.item_count() == 3 and control.items_value() == values,
		"The manual list editor must use one explicit editor per item and preserve punctuation/newlines."
	):
		return false
	control.set_items("Legacy, ambiguous manual text")
	var legacy_value := control.items_value()
	control.queue_free()
	return _require(
		legacy_value == ["Legacy, ambiguous manual text"],
		"A string shown for explicit correction must remain one item instead of being comma-split."
	)


func _test_round_trip(service) -> bool:
	var project := STORAGE.new_project()
	var character_id := STORAGE.active_character_id(project)
	var document := STORAGE.character_workspace_document(project, character_id)
	STORAGE.set_value_at_path(
		document,
		"character.card_extensions.front_porch.realism_engine.future_array_rule",
		{"preserve": ["yes, exactly"]}
	)
	var enabled: Dictionary = {}
	var values: Dictionary = {}
	for field in service.all_fields():
		var field_id := str(field.get("id", ""))
		enabled[field_id] = service.is_included(document, field)
		values[field_id] = service.value_for(document, field)
	var expected := {
		"fp_ambitions": [
			"Keep a comfortable, honest, no-strings arrangement alive",
			"Graduate without romantic drama"
		],
		"fp_plan_lines": ["Call Aya, confirm the plan, and leave before midnight"],
		"fp_likes": ["Confident, assertive partners", "静かな夜, 温かいお茶"],
		"fp_dislikes": ["Promises that sound kind, but hide an obligation"],
		"fp_intimate_into": ["Confident, attentive partners"],
		"fp_intimate_not_into": ["Pressure, humiliation, or ignored boundaries"],
		"fp_inventory_worn": ["Sundress (rain-soaked, hem torn)"],
		"fp_inventory_carrying": [
			"Silver smartphone (two weeks of chats, kept private)", "Wallet"
		]
	}
	for field_id in expected:
		enabled[field_id] = true
		values[field_id] = expected[field_id]
	var applied: Dictionary = service.apply_control_values(document, enabled, values, true)
	if not _require(bool(applied.get("ok", false)), "Valid structured list fields must apply."):
		return false
	var repeated_apply: Dictionary = service.apply_control_values(
		document, enabled, values, true
	)
	if not _require(
		bool(repeated_apply.get("ok", false)),
		"Repeated generated-list apply operations must remain stable."
	):
		return false
	STORAGE.update_character(project, document)
	var card := CARD_FORMAT.export_character_v2(project, character_id)
	var imported := CARD_FORMAT.import_card_to_project(card, "json")
	if not _require(bool(imported.get("ok", false)), "The generated card must import again."):
		return false
	var imported_project: Dictionary = imported.get("project", {})
	var imported_id := STORAGE.active_character_id(imported_project)
	var exported := CARD_FORMAT.export_character_v2(imported_project, imported_id)
	var realism: Dictionary = STORAGE.get_value_at_path(
		exported, "data.extensions.front_porch.realism_engine", {}
	)
	for field_id in expected:
		var field: Dictionary = service.field_by_id(field_id)
		if not _require(
			STORAGE.get_value_at_path(
				realism, str(field.get("key_path", "")), []
			) == expected[field_id],
			"%s must survive apply/export/import without comma splitting." % field_id
		):
			return false
	return _require(
		realism.get("future_array_rule", {}).get("preserve", []) == ["yes, exactly"],
		"Unrelated and unknown Front Porch data must remain unchanged."
	)


func _test_live_preview_preserves_existing(
	service
) -> bool:
	# Build a minimal document explicitly so this UI-focused test does not need to
	# start the complete application shell or make any provider request.
	var document: Dictionary = {
		"character_id": "array-integrity-character",
		"character": {"card_extensions": {}},
		"concept": {"prompt": "Test character"}
	}
	var enabled: Dictionary = {}
	var values: Dictionary = {}
	for field in service.all_fields():
		var field_id := str(field.get("id", ""))
		enabled[field_id] = service.is_included(document, field)
		values[field_id] = service.value_for(document, field)
	enabled["fp_ambitions"] = true
	values["fp_ambitions"] = ["Existing, correct ambition"]
	service.apply_control_values(document, enabled, values, false)
	var workspace = WORKSPACE.new()
	workspace.set("_front_porch_service_v0172", service)
	var invalid_preview_box := VBoxContainer.new()
	workspace.add_child(invalid_preview_box)
	workspace.set("_preview_result_box", invalid_preview_box)
	workspace.set("_preview_metadata", {"front_porch_generation_contract": 1})
	var field: Dictionary = service.field_by_id("fp_ambitions")
	workspace.call(
		"_add_preview_row",
		field,
		["Existing, correct ambition"],
		"Keep a comfortable, honest, no-strings arrangement alive"
	)
	var preview_rows: Array = workspace.get("_preview_rows")
	if not _require(preview_rows.size() == 1, "Malformed output must remain visible for review."):
		return false
	var invalid_row: Dictionary = preview_rows[0]
	var invalid_checkbox: CheckBox = invalid_row.get("checkbox")
	if not _require(
		not invalid_checkbox.button_pressed
		and not bool(invalid_row.get("front_porch_generated_shape_valid_v02116", true)),
		"Malformed list output must be clearly invalid and unchecked by default."
	):
		return false
	if not _require(
		STORAGE.get_value_at_path(
			document,
			"character.card_extensions.front_porch.realism_engine.ambitions",
			[]
		) == ["Existing, correct ambition"],
		"Rejecting malformed output must preserve the existing correct value."
	):
		return false

	var valid_items := [
		"Keep a comfortable, honest, no-strings arrangement alive",
		"Graduate without romantic drama"
	]
	workspace.set("_preview_rows", [])
	var valid_preview_box := VBoxContainer.new()
	workspace.add_child(valid_preview_box)
	workspace.set("_preview_result_box", valid_preview_box)
	workspace.call(
		"_add_preview_row", field, ["Existing, correct ambition"], valid_items
	)
	preview_rows = workspace.get("_preview_rows")
	var valid_row: Dictionary = preview_rows[-1]
	var valid_editor: Variant = valid_row.get("editor")
	if not _require(
		valid_editor is Control
		and valid_editor.has_method("items_value")
		and valid_editor.call("items_value") == valid_items,
		"Valid model arrays must reach the review as atomic list items."
	):
		return false
	values["fp_ambitions"] = valid_editor.call("items_value")
	var applied: Dictionary = service.apply_control_values(
		document, enabled, values, false
	)
	var applied_items: Variant = STORAGE.get_value_at_path(
		document,
		"character.card_extensions.front_porch.realism_engine.ambitions",
		[]
	)
	workspace.free()
	return _require(
		bool(applied.get("ok", false)) and applied_items == valid_items,
		"Repeated preview/apply must preserve valid comma-bearing array elements exactly."
	)
