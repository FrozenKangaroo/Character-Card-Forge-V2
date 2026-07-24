class_name CCFToolWindowStateService
extends RefCounted

const STATE_FILE := CCFStorageService.SETTINGS_DIR + "/tool_windows.json"
const FORMAT_VERSION := 1

static func show_window(window: Window, window_id: String, default_size: Vector2i) -> void:
    if window == null:
        return
    if window.visible:
        window.grab_focus()
        return

    if _restore_geometry(window, window_id):
        window.show()
        window.grab_focus()
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

static func _restore_geometry(window: Window, window_id: String) -> bool:
    var state := _load_state()
    var windows = state.get("windows", {})
    if not windows is Dictionary:
        return false
    var entry = windows.get(window_id, {})
    if not entry is Dictionary:
        return false

    var saved_size := _vector_from_array(entry.get("size", []), window.size)
    saved_size.x = maxi(saved_size.x, window.min_size.x)
    saved_size.y = maxi(saved_size.y, window.min_size.y)
    window.size = saved_size

    var saved_position := _vector_from_array(entry.get("position", []), window.position)
    var saved_rect := Rect2(saved_position, saved_size)
    if DisplayServer.get_screen_from_rect(saved_rect) < 0:
        return false

    window.position = saved_position
    return true

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
