extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message_text: String) -> void:
	push_error(message_text)
	print("V0204_LOREBOOK_NAMES_ERROR: %s" % message_text)
	quit(1)


func _require(condition: bool, message_text: String) -> bool:
	if condition:
		return true
	_fail(message_text)
	return false


func _fixture_book() -> Dictionary:
	return {
		"name": "Saionji Iori Lorebook",
		"entries": [
			{
				"name": "",
				"keys": ["Saionji Iori", "Iori", "Iorin"],
				"content": "Iori is an agejo fashion student.",
				"comment": ""
			},
			{
				"keys": ["Rouge L'Amour", "club", "Shinjuku"],
				"content": "Rouge L'Amour is Iori's workplace.",
				"comment": ""
			},
			{
				"keys": ["Aya", "friend"],
				"content": "Aya is Iori's high-school friend.",
				"comment": ""
			},
			{
				"keys": ["IORI", "brand"],
				"content": "Iori's fashion brand.",
				"comment": ""
			},
			{
				"keys": ["open day", "café"],
				"content": "The university café event.",
				"comment": ""
			},
			{
				"keys": ["makeover", "transformation"],
				"content": "The makeover process.",
				"comment": ""
			},
			{
				"keys": ["agejo", "gyaru"],
				"content": "Iori's fashion style.",
				"comment": ""
			},
			{
				"name": "Content warning: underage backstory",
				"keys": ["compensated dating", "backstory"],
				"content": "Off-screen historical context.",
				"comment": "Content warning: underage backstory"
			},
			{
				"keys": [],
				"content": "Iori's family background.",
				"comment": "Saionji Iori's Family"
			},
			{
				"name": "Karaoke Guy",
				"keys": ["karaoke"],
				"content": "A university acquaintance.",
				"comment": ""
			}
		]
	}


func _fixture_blueprint() -> String:
	return """CHARACTER IDENTITY
- Full name: Saionji Iori

## LOREBOOK
- The following lorebook entries are planned:
  1. Saionji Iori (keywords: Iori, Saionji Iori)
  2. Rouge L'Amour (keywords: Rouge L'Amour, club)
  3. Aya (keywords: Aya, friend)
  4. IORI / IORI MODE (keywords: IORI, brand)
  5. Open Day Café (keywords: open day, café)
  6. Makeover Process (keywords: makeover, transformation)
  7. Agejo Gyaru Style (keywords: agejo, gyaru)
  8. Compensated Dating Backstory (keywords: compensated dating, backstory) - includes content warning
  9. Saionji Iori's Family (keywords: family)
  10. Karaoke Guy (keywords: karaoke) - corrected from "Karaoke Classmate"

SYSTEM / BEHAVIOURAL RULES
- Preserve established facts.
"""


func _entry_names(book: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for raw_entry in book.get("entries", []):
		if raw_entry is Dictionary:
			result.append(str((raw_entry as Dictionary).get("name", "")))
	return result


func _shuffled_fixture_book() -> Dictionary:
	var fixture := _fixture_book()
	var source: Array = fixture.get("entries", [])
	var shuffled: Array = []
	for source_index in [7, 1, 9, 4, 0, 8, 3, 6, 2, 5]:
		shuffled.append((source[source_index] as Dictionary).duplicate(true))
	fixture["entries"] = shuffled
	return fixture


func _run() -> void:
	var fixture := _fixture_book()
	var planned_entries := CCFLorebookEntryNamingServiceV0204.planned_entries_from_blueprint(
		_fixture_blueprint()
	)
	var named := CCFLorebookEntryNamingServiceV0204.normalise_book_names(
		fixture, planned_entries, true
	)
	var expected: Array[String] = [
		"Saionji Iori",
		"Rouge L'Amour",
		"Aya",
		"IORI / IORI MODE",
		"Open Day Café",
		"Makeover Process",
		"Agejo Gyaru Style",
		"Compensated Dating Backstory",
		"Saionji Iori's Family",
		"Karaoke Guy"
	]
	if not _require(
		_entry_names(named) == expected
		and str((named.get("entries", []) as Array)[7].get("comment", ""))
		== "Content warning: underage backstory",
		"Missing names must use title-like comments or primary keys while warnings remain separate."
	):
		return

	var shuffled_named := CCFLorebookEntryNamingServiceV0204.normalise_book_names(
		_shuffled_fixture_book(), planned_entries, true
	)
	var shuffled_expected: Array[String] = [
		"Compensated Dating Backstory",
		"Rouge L'Amour",
		"Karaoke Guy",
		"Open Day Café",
		"Saionji Iori",
		"Saionji Iori's Family",
		"IORI / IORI MODE",
		"Agejo Gyaru Style",
		"Aya",
		"Makeover Process"
	]
	if not _require(
		_entry_names(shuffled_named) == shuffled_expected,
		"Planned names must follow entry identity when generated entries are reordered."
	):
		return

	var manually_named := _fixture_book()
	var manual_entries: Array = manually_named.get("entries", [])
	(manual_entries[0] as Dictionary)["name"] = "Custom Iori Notes"
	var reopened := CCFLorebookEntryNamingServiceV0204.normalise_book_names(
		manually_named, planned_entries
	)
	if not _require(
		_entry_names(reopened)[0] == "Custom Iori Notes",
		"Opening an existing Lorebook must preserve manually edited entry names."
	):
		return

	var workspace := CCFWorkspaceV01517View.new()
	var workspace_named := workspace._normalise_lorebook_v01517(
		fixture, _fixture_blueprint()
	)
	if not _require(
		_entry_names(workspace_named) == expected,
		"Blueprint supplementary material must receive names before entering character data."
	):
		workspace.free()
		return
	workspace.free()

	var materialised := CCFCollaboratorCompletionServiceV01535.materialise_character(
		{
			"handoff_mode": "detailed_workspace_draft",
			"suggested_name": "Saionji Iori",
			"fields": {},
			"concept_prompt": _fixture_blueprint(),
			"lorebook": fixture
		},
		"Saionji Iori",
		{},
		CCFCollaboratorCompletionServiceV01535.DEST_SAME_PROJECT_NEW
	)
	var materialised_character: Dictionary = materialised.get("character", {})
	var materialised_book: Variant = CCFStorageService.get_value_at_path(
		materialised_character, "character.character_book", {}
	)
	if not _require(
		bool(materialised.get("ok", false))
		and materialised_book is Dictionary
		and _entry_names(materialised_book as Dictionary) == expected,
		"Detailed Collaborator handoff must normalise Lorebook names too."
	):
		return

	var active_character := CCFStorageService.new_character_record("Saionji Iori")
	CCFStorageService.set_value_at_path(
		active_character, "concept.prompt", _fixture_blueprint()
	)
	CCFStorageService.set_value_at_path(
		active_character, "character.character_book", fixture
	)
	var lorebook_window := CCFLorebookWindowV01415.new()
	root.add_child(lorebook_window)
	await process_frame
	lorebook_window.open_for_project({}, active_character)
	await process_frame
	var live_book_value: Variant = lorebook_window.get("_character_book")
	if not _require(
		live_book_value is Dictionary
		and _entry_names(live_book_value as Dictionary) == expected,
		"Opening Lorebook Manager must repair unnamed entries without using warnings as titles."
	):
		return
	lorebook_window.queue_free()
	await process_frame

	var generation_source := FileAccess.get_file_as_string(
		"res://scripts/services/generation_service_v01517.gd"
	)
	if not _require(
		generation_source.contains("Every useful entry must contain a concise, distinct, human-readable `name`")
		and generation_source.contains("never in name"),
		"Both Collaborator Lorebook generation paths must require distinct names and separate warnings."
	):
		return

	print("V0204_LOREBOOK_NAMES_OK")
	quit(0)
