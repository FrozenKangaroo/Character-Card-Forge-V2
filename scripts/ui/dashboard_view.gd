class_name CCFDashboardView
extends VBoxContainer

signal new_character_requested()
signal library_requested()
signal settings_requested()
signal open_project_requested(project_id: String)

var _stats_label: Label
var _recent_box: VBoxContainer

func _ready() -> void:
    add_theme_constant_override("separation", 18)

    var title := Label.new()
    title.text = "Welcome to Character Card Forge"
    title.add_theme_font_size_override("font_size", 28)
    add_child(title)

    var subtitle := Label.new()
    subtitle.text = "A clean Godot-native rewrite. Create, generate, edit, save, and browse character projects without a monolithic database."
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    subtitle.modulate = Color(0.78, 0.79, 0.86)
    add_child(subtitle)

    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation", 10)
    add_child(actions)
    actions.add_child(_button("New Project", func(): new_character_requested.emit(), true))
    actions.add_child(_button("Open Library", func(): library_requested.emit()))
    actions.add_child(_button("API Settings", func(): settings_requested.emit()))

    var stats_panel := PanelContainer.new()
    stats_panel.custom_minimum_size.y = 80
    add_child(stats_panel)
    var stats_margin := MarginContainer.new()
    stats_margin.add_theme_constant_override("margin_left", 18)
    stats_margin.add_theme_constant_override("margin_right", 18)
    stats_margin.add_theme_constant_override("margin_top", 14)
    stats_margin.add_theme_constant_override("margin_bottom", 14)
    stats_panel.add_child(stats_margin)
    _stats_label = Label.new()
    _stats_label.add_theme_font_size_override("font_size", 20)
    stats_margin.add_child(_stats_label)

    var recent_title := Label.new()
    recent_title.text = "Recent projects"
    recent_title.add_theme_font_size_override("font_size", 20)
    add_child(recent_title)

    _recent_box = VBoxContainer.new()
    _recent_box.add_theme_constant_override("separation", 8)
    add_child(_recent_box)
    refresh()

func refresh() -> void:
    if _stats_label == null:
        return
    var index_result := CCFLibraryService.refresh_index(false)
    var projects: Array = []
    var raw_projects: Variant = index_result.get("rows", [])
    if index_result.get("ok", false) and raw_projects is Array:
        projects = raw_projects
    var total_characters := 0
    for project in projects:
        total_characters += int(project.get("character_count", 1))
    var series_count := CCFSeriesService.list_series().size()
    _stats_label.text = "%d project%s • %d character%s • %d series" % [
        projects.size(),
        "" if projects.size() == 1 else "s",
        total_characters,
        "" if total_characters == 1 else "s",
        series_count
    ]
    for child in _recent_box.get_children():
        child.queue_free()
    if projects.is_empty():
        var empty := Label.new()
        empty.text = "No projects yet. Create the first one and give this forge something to work with."
        empty.modulate = Color(0.7, 0.71, 0.78)
        _recent_box.add_child(empty)
        return
    for row in recent_rows(projects, 5):
        var button := Button.new()
        button.text = "%s   •   %d character%s   •   %s" % [
            str(row.get("name", "Untitled Project")),
            int(row.get("character_count", 1)),
            "" if int(row.get("character_count", 1)) == 1 else "s",
            _friendly_date(str(row.get("updated_at", "")))
        ]
        var series_name := str(row.get("series_name", "")).strip_edges()
        if not series_name.is_empty():
            button.text += "   •   %s" % series_name
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.custom_minimum_size.y = 46
        button.pressed.connect(_emit_open_project.bind(str(row.get("project_id", ""))))
        _recent_box.add_child(button)


## Newest-first slice of the library index.
##
## The index is written in directory order, so the dashboard must order the
## rows itself: "Recent projects" was previously showing whichever projects
## happened to be listed first. Rows without a usable timestamp sort last.
static func recent_rows(rows: Array, limit: int = 5) -> Array[Dictionary]:
    var sorted_rows: Array[Dictionary] = []
    for raw_row in rows:
        if raw_row is Dictionary:
            sorted_rows.append((raw_row as Dictionary).duplicate(true))
    sorted_rows.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
        var first_time := _sort_time(first)
        var second_time := _sort_time(second)
        if first_time != second_time:
            return first_time > second_time
        return str(first.get("name", "")).naturalnocasecmp_to(
            str(second.get("name", ""))
        ) < 0
    )
    if limit > 0 and sorted_rows.size() > limit:
        sorted_rows.resize(limit)
    return sorted_rows


static func _sort_time(row: Dictionary) -> float:
    var raw := str(row.get("updated_at", "")).strip_edges()
    if raw.is_empty():
        raw = str(row.get("created_at", "")).strip_edges()
    if raw.is_empty():
        return 0.0
    return Time.get_unix_time_from_datetime_string(raw)

func _button(text: String, callback: Callable, accent := false) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(150, 44)
    if accent:
        button.add_theme_color_override("font_color", Color(0.97, 0.94, 1.0))
    button.pressed.connect(callback)
    return button

func _friendly_date(value: String) -> String:
    var text := value.strip_edges()
    if text.is_empty():
        return "Unknown date"
    text = text.replace("T", " ").trim_suffix("Z")
    var fractional := text.find(".")
    if fractional > 0:
        text = text.substr(0, fractional)
    if text.length() > 16:
        text = text.substr(0, 16)
    return text

func _emit_open_project(project_id: String) -> void:
    open_project_requested.emit(project_id)
