class_name CCFToolWindowStateService
extends RefCounted

const STATE_FILE := CCFStorageService.SETTINGS_DIR + "/tool_windows.json"
const FORMAT_VERSION := 1

static func show_window(
    window: Window,
    window_id: String,
    default_size: Vector2i,
    reference_window: Window = null,
    constrain_to_reference_screen: bool = false
) -> void:
    if window == null:
        return
    if window.visible:
        window.grab_focus()
        return

    var required_screen := -1
    if constrain_to_reference_screen and reference_window != null:
        required_screen = _reference_screen(reference_window)
    if _restore_geometry(window, window_id, required_screen):
        window.show()
        window.grab_focus()
        return

    if reference_window != null and _show_on_reference_screen(
        window, default_size, reference_window
    ):
        return

    window.popup_centered_clamped(default_size, 0.90)

static func save_window(window: Window, window_id: String) -> void:
    if window == null or window_id.strip_edges().is_empty():
        return

    var state := _load_state()
    var windows: Dictionary = state.get("windows", {}).duplicate(true)
    windows[window_id] = {
        "position": [window.position.x, window.position.y],
        "size": [window.size.x, window.size.y]
    }
    state["windows"] = windows
    _save_state(state)

static func _restore_geometry(
    window: Window, window_id: String, required_screen: int = -1
) -> bool:
    var state := _load_state()
    var windows = state.get("windows", {})
    if not windows is Dictionary:
        return false
    var entry = windows.get(window_id, {})
    if not entry is Dictionary:
        return false

    var saved_size := _vector_from_array(entry.get("size", []), window.size)
    var saved_position := _vector_from_array(entry.get("position", []), window.position)
    var saved_rect := Rect2i(saved_position, saved_size)
    var usable_rects := _usable_screen_rects()
    var screen := screen_for_saved_geometry(saved_rect, usable_rects)
    if screen < 0:
        return false
    if required_screen >= 0 and screen != required_screen:
        return false
    var usable_rect: Rect2i = usable_rects[screen]
    if usable_rect.size.x <= 0 or usable_rect.size.y <= 0:
        return false
    var geometry := clamp_geometry_to_usable_rect(
        saved_position, saved_size, window.min_size, usable_rect
    )
    window.current_screen = screen
    window.size = geometry.get("size", saved_size)
    window.position = geometry.get("position", saved_position)
    return true

static func screen_for_saved_geometry(
    saved_rect: Rect2i,
    usable_rects: Array[Rect2i],
    minimum_visible_size: Vector2i = Vector2i(48, 48)
) -> int:
    var best_screen := -1
    var best_area := 0
    for screen_index in range(usable_rects.size()):
        var overlap := saved_rect.intersection(usable_rects[screen_index])
        if (
            overlap.size.x < minimum_visible_size.x
            or overlap.size.y < minimum_visible_size.y
        ):
            continue
        var area := overlap.size.x * overlap.size.y
        if area > best_area:
            best_area = area
            best_screen = screen_index
    return best_screen

static func contextual_geometry(
    default_size: Vector2i,
    minimum_size: Vector2i,
    reference_rect: Rect2i,
    usable_rect: Rect2i,
    margin: int = 24
) -> Dictionary:
    var reference_center := usable_rect.get_center()
    if reference_rect.intersects(usable_rect):
        reference_center = reference_rect.get_center()
    var desired_position := Vector2i(
        int(reference_center.x - default_size.x / 2.0),
        int(reference_center.y - default_size.y / 2.0)
    )
    return clamp_geometry_to_usable_rect(
        desired_position, default_size, minimum_size, usable_rect, margin
    )

static func clamp_geometry_to_usable_rect(
    desired_position: Vector2i,
    desired_size: Vector2i,
    minimum_size: Vector2i,
    usable_rect: Rect2i,
    margin: int = 24
) -> Dictionary:
    var safe_margin := maxi(0, margin)
    var available_size := Vector2i(
        maxi(1, usable_rect.size.x - safe_margin * 2),
        maxi(1, usable_rect.size.y - safe_margin * 2)
    )
    var effective_minimum := Vector2i(
        mini(maxi(1, minimum_size.x), available_size.x),
        mini(maxi(1, minimum_size.y), available_size.y)
    )
    var safe_size := Vector2i(
        clampi(desired_size.x, effective_minimum.x, available_size.x),
        clampi(desired_size.y, effective_minimum.y, available_size.y)
    )
    var minimum_position := usable_rect.position + Vector2i(safe_margin, safe_margin)
    var maximum_position := usable_rect.end - safe_size - Vector2i(
        safe_margin, safe_margin
    )
    var safe_position := Vector2i(
        clampi(desired_position.x, minimum_position.x, maximum_position.x),
        clampi(desired_position.y, minimum_position.y, maximum_position.y)
    )
    return {"position": safe_position, "size": safe_size}

static func _show_on_reference_screen(
    window: Window, default_size: Vector2i, reference_window: Window
) -> bool:
    var usable_rects := _usable_screen_rects()
    if usable_rects.is_empty():
        return false
    var reference_rect := Rect2i(reference_window.position, reference_window.size)
    var screen := _reference_screen(reference_window, usable_rects)
    if screen < 0:
        screen = 0
    var geometry := contextual_geometry(
        default_size,
        window.min_size,
        reference_rect,
        usable_rects[screen]
    )
    window.current_screen = screen
    window.size = geometry.get("size", default_size)
    window.position = geometry.get("position", usable_rects[screen].position)
    window.show()
    window.grab_focus()
    return true

static func _reference_screen(
    reference_window: Window, usable_rects: Array[Rect2i] = []
) -> int:
    var screen_rects := usable_rects
    if screen_rects.is_empty():
        screen_rects = _usable_screen_rects()
    var screen := reference_window.current_screen
    if screen >= 0 and screen < screen_rects.size():
        return screen
    return screen_for_saved_geometry(
        Rect2i(reference_window.position, reference_window.size),
        screen_rects,
        Vector2i(1, 1)
    )

static func _usable_screen_rects() -> Array[Rect2i]:
    var result: Array[Rect2i] = []
    for screen in range(DisplayServer.get_screen_count()):
        var usable_rect := DisplayServer.screen_get_usable_rect(screen)
        if usable_rect.size.x > 0 and usable_rect.size.y > 0:
            result.append(usable_rect)
    return result

static func _load_state() -> Dictionary:
    CCFStorageService.ensure_directories()
    if not FileAccess.file_exists(STATE_FILE):
        return _default_state()

    var file := FileAccess.open(STATE_FILE, FileAccess.READ)
    if file == null:
        return _default_state()
    var parsed = JSON.parse_string(file.get_as_text())
    file.close()
    if not parsed is Dictionary:
        return _default_state()

    var state := _default_state()
    var incoming_windows = parsed.get("windows", {})
    if incoming_windows is Dictionary:
        state["windows"] = incoming_windows.duplicate(true)
    return state

static func _save_state(state: Dictionary) -> void:
    CCFStorageService.ensure_directories()
    var file := FileAccess.open(STATE_FILE, FileAccess.WRITE)
    if file == null:
        return
    state["format_version"] = FORMAT_VERSION
    file.store_string(JSON.stringify(state, "  "))
    file.close()

static func _default_state() -> Dictionary:
    return {
        "format_version": FORMAT_VERSION,
        "windows": {}
    }

static func _vector_from_array(value: Variant, fallback: Vector2i) -> Vector2i:
    if not value is Array or value.size() < 2:
        return fallback
    return Vector2i(int(value[0]), int(value[1]))
