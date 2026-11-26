class_name CCFFrontPorchTraitKitControlV02119
extends VBoxContainer

# Editor for Front Porch's `realism_engine.traitKit` array (Boons & Bogies).
#
# Card shape, per Front Porch's design doc (docs/design/boons-and-bogies.md §4):
#   [{kind: "boon"|"bogey", text: String, tier: "emerging"|"developing"|"established",
#     pinned: bool, linkedTo?: String}]
#
# Limits enforced here and again in the service: at most 6 entries combined and at
# most 3 bogeys. `linkedTo` names a boon's exact text and only bogeys may carry it.
# Unknown keys on an entry are preserved so a future Front Porch field survives.

signal value_changed

const MAX_ENTRIES := 6
const MAX_BOGEYS := 3
const KINDS := ["boon", "bogey"]
const TIERS := ["emerging", "developing", "established"]
const TIER_LABELS := {
	"emerging": "Novice",
	"developing": "Skilled",
	"established": "Master",
}

var _rows_box := VBoxContainer.new()
var _add_boon_button := Button.new()
var _add_bogey_button := Button.new()
var _status := Label.new()
var _editable := true
var _loading := false


func _init() -> void:
	name = "FrontPorchTraitKitV02119"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)

	_rows_box.name = "TraitKitRowsV02119"
	_rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_box.add_theme_constant_override("separation", 8)
	add_child(_rows_box)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	add_child(actions)
	_add_boon_button.name = "AddBoonV02119"
	_add_boon_button.text = "+ Add boon"
	_add_boon_button.tooltip_text = (
		"Add an ability this character can grow into. Front Porch seeds it into "
		+ "new chats at the chosen tier."
	)
	_add_boon_button.pressed.connect(_add_entry.bind("boon"))
	actions.add_child(_add_boon_button)
	_add_bogey_button.name = "AddBogeyV02119"
	_add_bogey_button.text = "+ Add bogey"
	_add_bogey_button.tooltip_text = (
		"Add a recurring flaw that can fire during play. At most three bogies, "
		+ "shared with the card's other flaws."
	)
	_add_bogey_button.pressed.connect(_add_entry.bind("bogey"))
	actions.add_child(_add_bogey_button)

	_status.name = "TraitKitStatusV02119"
	_status.modulate = Color(0.68, 0.72, 0.82)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(_status)
	_refresh_status()


func set_items(value: Variant) -> void:
	_loading = true
	for child in _rows_box.get_children():
		_rows_box.remove_child(child)
		child.queue_free()
	if value is Array:
		for raw_entry in value as Array:
			if raw_entry is Dictionary:
				_add_entry_from_dictionary(raw_entry as Dictionary)
			elif raw_entry != null and not str(raw_entry).strip_edges().is_empty():
				# Malformed but non-empty data stays visible and editable instead
				# of being dropped on load.
				_add_entry_from_dictionary({"text": str(raw_entry)})
	_loading = false
	_refresh_all()


func items_value() -> Array:
	var result: Array = []
	for row_value in _rows_box.get_children():
		if not row_value is PanelContainer:
			continue
		var row := row_value as PanelContainer
		var text := _row_text(row).strip_edges()
		if text.is_empty():
			continue
		var entry := {
			"kind": _row_kind(row),
			"text": text,
			"tier": _row_tier(row),
			"pinned": _row_pinned(row),
		}
		var link := _row_link(row)
		if _row_kind(row) == "bogey" and not link.is_empty():
			entry["linkedTo"] = link
		var extras: Variant = row.get_meta("trait_kit_extras", {})
		if extras is Dictionary:
			for raw_key in (extras as Dictionary).keys():
				if not entry.has(raw_key):
					entry[raw_key] = (extras as Dictionary)[raw_key]
		result.append(entry)
	return result


func set_editable(enabled: bool) -> void:
	_editable = enabled
	_refresh_all()


func entry_count() -> int:
	return items_value().size()


func bogey_count() -> int:
	var count := 0
	for entry in items_value():
		if str(entry.get("kind", "")) == "bogey":
			count += 1
	return count


func row_count() -> int:
	return _rows_box.get_child_count()


func _add_entry(kind: String) -> void:
	if not _editable:
		return
	if entry_count() >= MAX_ENTRIES:
		return
	if kind == "bogey" and bogey_count() >= MAX_BOGEYS:
		return
	var tier := "emerging"
	_add_entry_from_dictionary({
		"kind": kind,
		"text": "",
		"tier": tier,
		# Front Porch pins card-seeded bogies by default so the author's core
		# flaw cannot fade out early; boons start unpinned.
		"pinned": kind == "bogey",
	})
	_refresh_all()
	if not _loading:
		value_changed.emit()


func _add_entry_from_dictionary(raw_entry: Dictionary) -> void:
	var kind := str(raw_entry.get("kind", "boon")).to_lower()
	if kind not in KINDS:
		kind = "boon"
	var tier := str(raw_entry.get("tier", "emerging")).to_lower()
	if tier not in TIERS:
		tier = "emerging"

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_box.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	content.add_child(top)

	var kind_select := OptionButton.new()
	kind_select.name = "KindV02119"
	for kind_option in KINDS:
		var index := kind_select.item_count
		kind_select.add_item("Boon" if kind_option == "boon" else "Bogey")
		kind_select.set_item_metadata(index, kind_option)
	kind_select.select(0 if kind == "boon" else 1)
	kind_select.item_selected.connect(_on_kind_selected.bind(panel))
	top.add_child(kind_select)

	var tier_select := OptionButton.new()
	tier_select.name = "TierV02119"
	for tier_option in TIERS:
		var index := tier_select.item_count
		tier_select.add_item(str(TIER_LABELS.get(tier_option, tier_option)))
		tier_select.set_item_metadata(index, tier_option)
	tier_select.select(TIERS.find(tier))
	tier_select.tooltip_text = (
		"Novice starts at 0.30 strength, Skilled at 0.60, Master at 0.80 when "
		+ "Front Porch seeds the kit into a new chat."
	)
	tier_select.item_selected.connect(_on_row_changed)
	top.add_child(tier_select)

	var pinned := CheckBox.new()
	pinned.name = "PinnedV02119"
	pinned.text = "Pinned"
	pinned.button_pressed = bool(raw_entry.get("pinned", false))
	pinned.tooltip_text = (
		"A pinned trait is never silently retired by the growth system. Front "
		+ "Porch pins card-seeded bogies by default."
	)
	pinned.toggled.connect(_on_row_changed)
	top.add_child(pinned)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)

	var remove_button := Button.new()
	remove_button.name = "RemoveV02119"
	remove_button.text = "Remove"
	remove_button.pressed.connect(_remove_row.bind(panel))
	top.add_child(remove_button)

	var editor := TextEdit.new()
	editor.name = "TextV02119"
	editor.text = str(raw_entry.get("text", ""))
	editor.placeholder_text = (
		"One ability (boon) or one recurring flaw (bogey), written as a short sentence"
	)
	editor.custom_minimum_size.y = 56
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.text_changed.connect(_on_text_changed.bind(panel))
	content.add_child(editor)

	var link_row := HBoxContainer.new()
	link_row.name = "LinkRowV02119"
	link_row.add_theme_constant_override("separation", 8)
	content.add_child(link_row)
	var link_label := Label.new()
	link_label.text = "Pushes against boon"
	link_row.add_child(link_label)
	var link_select := OptionButton.new()
	link_select.name = "LinkV02119"
	link_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	link_select.tooltip_text = (
		"Optional: name the boon this flaw works against. Front Porch grows the "
		+ "boon toward overcoming the bogey."
	)
	link_select.item_selected.connect(_on_link_selected.bind(panel))
	link_row.add_child(link_select)

	var extras := raw_entry.duplicate(true)
	for known in ["kind", "text", "tier", "pinned", "linkedTo"]:
		extras.erase(known)
	panel.set_meta("trait_kit_extras", extras)
	panel.set_meta("trait_kit_previous_text", str(raw_entry.get("text", "")))
	panel.set_meta("trait_kit_link", str(raw_entry.get("linkedTo", "")))
	_refresh_row(panel)


func _remove_row(row: PanelContainer) -> void:
	if not _editable:
		return
	_rows_box.remove_child(row)
	row.queue_free()
	_refresh_all()
	if not _loading:
		value_changed.emit()


func _on_kind_selected(_index: int, row: PanelContainer) -> void:
	if _row_kind(row) != "bogey":
		row.set_meta("trait_kit_link", "")
	_refresh_row(row)
	_refresh_status()
	if not _loading:
		value_changed.emit()


func _on_link_selected(_index: int, row: PanelContainer) -> void:
	# Store the chosen target before any later rebuild reconstructs the list,
	# otherwise the imported link (or a cleared one) silently comes back.
	row.set_meta("trait_kit_link", _row_link(row))
	_refresh_status()
	if not _loading:
		value_changed.emit()


func _on_row_changed(_value: Variant = null) -> void:
	_refresh_status()
	if not _loading:
		value_changed.emit()


func _on_text_changed(row: PanelContainer) -> void:
	# Keep links attached when a boon is renamed: Front Porch matches `linkedTo`
	# by exact text, so a stale string would silently unlink the bogey.
	var previous := str(row.get_meta("trait_kit_previous_text", ""))
	var current := _row_text(row).strip_edges()
	if not previous.is_empty() and previous != current and _row_kind(row) == "boon":
		for other_value in _rows_box.get_children():
			if not other_value is PanelContainer:
				continue
			var other := other_value as PanelContainer
			if other == row or _row_kind(other) != "bogey":
				continue
			if str(other.get_meta("trait_kit_link", "")) == previous:
				other.set_meta("trait_kit_link", current)
	row.set_meta("trait_kit_previous_text", current)
	# Rebuild every link selector: a renamed boon must appear under its new
	# text, and links that followed the rename must show the new target.
	_refresh_all()
	if not _loading:
		value_changed.emit()


func _refresh_all() -> void:
	for row_value in _rows_box.get_children():
		if row_value is PanelContainer:
			_refresh_row(row_value as PanelContainer)
	_refresh_status()


func _refresh_row(row: PanelContainer) -> void:
	var kind := _row_kind(row)
	var link_row := row.find_child("LinkRowV02119", true, false) as Control
	if link_row != null:
		link_row.visible = kind == "bogey"
	_refresh_link_options(row)
	var kind_select := row.find_child("KindV02119", true, false) as OptionButton
	if kind_select != null:
		kind_select.disabled = not _editable
	var tier_select := row.find_child("TierV02119", true, false) as OptionButton
	if tier_select != null:
		tier_select.disabled = not _editable
	var pinned := row.find_child("PinnedV02119", true, false) as CheckBox
	if pinned != null:
		pinned.disabled = not _editable
	var editor := row.find_child("TextV02119", true, false) as TextEdit
	if editor != null:
		editor.editable = _editable
	var link_select := row.find_child("LinkV02119", true, false) as OptionButton
	if link_select != null:
		link_select.disabled = not _editable
	var remove_button := row.find_child("RemoveV02119", true, false) as Button
	if remove_button != null:
		remove_button.disabled = not _editable


func _refresh_link_options(row: PanelContainer) -> void:
	var link_select := row.find_child("LinkV02119", true, false) as OptionButton
	if link_select == null:
		return
	var wanted := str(row.get_meta("trait_kit_link", ""))
	link_select.clear()
	link_select.add_item("(no link)")
	link_select.set_item_metadata(0, "")
	var selected_index := 0
	var found := wanted.is_empty()
	for other_value in _rows_box.get_children():
		if not other_value is PanelContainer:
			continue
		var other := other_value as PanelContainer
		if other == row or _row_kind(other) != "boon":
			continue
		var boon_text := _row_text(other).strip_edges()
		if boon_text.is_empty():
			continue
		var index := link_select.item_count
		link_select.add_item(_shorten(boon_text))
		link_select.set_item_metadata(index, boon_text)
		link_select.set_item_tooltip(index, boon_text)
		if boon_text == wanted:
			selected_index = index
			found = true
	if not found and not wanted.is_empty():
		# A link whose boon was removed stays visible instead of silently
		# pointing at nothing; validation reports it on save.
		var index := link_select.item_count
		link_select.add_item("%s • missing boon" % _shorten(wanted))
		link_select.set_item_metadata(index, wanted)
		selected_index = index
	link_select.select(selected_index)


func _refresh_status() -> void:
	var entries := entry_count()
	var bogeys := bogey_count()
	var boons := entries - bogeys
	_status.text = "%d of %d entries • %d boons • %d of %d bogies" % [
		entries, MAX_ENTRIES, boons, bogeys, MAX_BOGEYS
	]
	_status.modulate = (
		Color(0.72, 0.78, 0.9)
		if entries <= MAX_ENTRIES and bogeys <= MAX_BOGEYS
		else Color(0.95, 0.62, 0.55)
	)
	_add_boon_button.disabled = not _editable or entries >= MAX_ENTRIES
	_add_bogey_button.disabled = (
		not _editable or entries >= MAX_ENTRIES or bogeys >= MAX_BOGEYS
	)


func _row_kind(row: PanelContainer) -> String:
	var select := row.find_child("KindV02119", true, false) as OptionButton
	if select == null or select.selected < 0:
		return "boon"
	return str(select.get_item_metadata(select.selected))


func _row_tier(row: PanelContainer) -> String:
	var select := row.find_child("TierV02119", true, false) as OptionButton
	if select == null or select.selected < 0:
		return "emerging"
	return str(select.get_item_metadata(select.selected))


func _row_pinned(row: PanelContainer) -> bool:
	var pinned := row.find_child("PinnedV02119", true, false) as CheckBox
	return pinned != null and pinned.button_pressed


func _row_text(row: PanelContainer) -> String:
	var editor := row.find_child("TextV02119", true, false) as TextEdit
	return editor.text if editor != null else ""


func _row_link(row: PanelContainer) -> String:
	var select := row.find_child("LinkV02119", true, false) as OptionButton
	if select == null or select.selected < 0:
		return ""
	return str(select.get_item_metadata(select.selected))


func _shorten(text: String) -> String:
	var flat := text.replace("\n", " ").strip_edges()
	if flat.length() <= 42:
		return flat
	return flat.substr(0, 39) + "…"
