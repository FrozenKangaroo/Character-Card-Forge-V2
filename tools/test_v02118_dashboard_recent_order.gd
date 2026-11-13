extends SceneTree

const TEST_USER_DATA_ISOLATION = preload("res://tools/test_user_data_isolation.gd")
var _test_user_data_isolation := TEST_USER_DATA_ISOLATION.activate(
	"v02118-dashboard-recent-order"
)


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("V02118_DASHBOARD_RECENT_ORDER_ERROR: %s" % message)
	quit(1)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _run() -> void:
	var rows: Array = [
		{"project_id": "a", "name": "Carla", "updated_at": "2026-08-05T10:02:06"},
		{"project_id": "b", "name": "Aya", "updated_at": "2026-07-31T08:57:27"},
		{"project_id": "c", "name": "Sakuraba", "updated_at": "2026-09-19T07:56:26"},
		{"project_id": "d", "name": "Untouched", "updated_at": ""},
		{"project_id": "e", "name": "Lillith", "updated_at": "2026-07-31T13:41:29"},
		{"project_id": "f", "name": "Thao", "updated_at": "2026-07-31T13:42:48"},
	]
	var ordered := CCFDashboardView.recent_rows(rows, 5)
	var names: Array[String] = []
	for row in ordered:
		names.append(str(row.get("name", "")))
	if not _require(
		names == ["Sakuraba", "Carla", "Thao", "Lillith", "Aya"],
		"Recent projects must be newest first and limited to five rows; got %s." % [names]
	):
		return
	if not _require(
		not names.has("Untouched"),
		"A project without a usable timestamp must sort after dated projects."
	):
		return
	var all_rows := CCFDashboardView.recent_rows(rows, 0)
	if not _require(
		all_rows.size() == rows.size()
		and str(all_rows[all_rows.size() - 1].get("name", "")) == "Untouched",
		"A zero limit must keep every row while still sorting missing timestamps last."
	):
		return
	# The input array must not be reordered in place; the library index is shared.
	if not _require(
		str(rows[0].get("name", "")) == "Carla",
		"Ordering the dashboard must not mutate the library index rows."
	):
		return

	var view := CCFDashboardView.new()
	if not _require(
		str(view.call("_friendly_date", "2026-09-19T07:56:26Z")) == "2026-09-19 07:56"
		and str(view.call("_friendly_date", "2026-09-19T07:56:26.123456")) == "2026-09-19 07:56"
		and str(view.call("_friendly_date", "  ")) == "Unknown date",
		"The dashboard must show a compact local timestamp rather than raw ISO text."
	):
		view.free()
		return
	view.free()
	print("V02118_DASHBOARD_RECENT_ORDER_OK")
	quit(0)
