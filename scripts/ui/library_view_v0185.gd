class_name CCFLibraryV0185View
extends "res://scripts/ui/library_view_v0184.gd"

const FRONT_PORCH_SYNC_SERVICE = preload(
	"res://scripts/services/front_porch_sync_service_v0185.gd"
)

var _v0185_ready := false
var _remote_sync_filter_v0185: OptionButton
var _deployment_filter_v0185: OptionButton


func _ready() -> void:
	super._ready()
	_build_front_porch_filters_v0185()
	_v0185_ready = true
	_restore_front_porch_filters_v0185()
	refresh_projects(false)


func refresh_projects(force_rebuild: bool = false) -> void:
	super.refresh_projects(force_rebuild)
	_projects = FRONT_PORCH_SYNC_SERVICE.enhance_library_rows(_projects)
	if _v0185_ready:
		_apply_filters()


func _build_front_porch_filters_v0185() -> void:
	if _workflow_filter == null or _workflow_filter.get_parent() == null:
		return
	var row := _workflow_filter.get_parent()
	_remote_sync_filter_v0185 = OptionButton.new()
	for option in [
		["All remote states", ""],
		["Not Installed", FRONT_PORCH_SYNC_SERVICE.STATE_NOT_INSTALLED],
		["Installed", FRONT_PORCH_SYNC_SERVICE.STATE_INSTALLED],
		["Modified Locally", FRONT_PORCH_SYNC_SERVICE.STATE_MODIFIED_LOCALLY],
		["Changed in Front Porch", FRONT_PORCH_SYNC_SERVICE.STATE_CHANGED_REMOTELY],
		["Diverged", FRONT_PORCH_SYNC_SERVICE.STATE_DIVERGED]
	]:
		_remote_sync_filter_v0185.add_item(str(option[0]))
		_remote_sync_filter_v0185.set_item_metadata(
			_remote_sync_filter_v0185.item_count - 1, str(option[1])
		)
	_remote_sync_filter_v0185.tooltip_text = "Private Front Porch identity and fingerprint state; no network request runs while browsing the Library."
	_remote_sync_filter_v0185.item_selected.connect(func(_index: int): _apply_filters())
	row.add_child(_remote_sync_filter_v0185)
	_deployment_filter_v0185 = OptionButton.new()
	_deployment_filter_v0185.add_item("All deployment states")
	_deployment_filter_v0185.set_item_metadata(0, "")
	_deployment_filter_v0185.add_item("Queued for deployment")
	_deployment_filter_v0185.set_item_metadata(1, "queued")
	_deployment_filter_v0185.add_item("Not queued")
	_deployment_filter_v0185.set_item_metadata(2, "not_queued")
	_deployment_filter_v0185.item_selected.connect(func(_index: int): _apply_filters())
	row.add_child(_deployment_filter_v0185)


func _apply_filters() -> void:
	if not _v0185_ready:
		super._apply_filters()
		return
	super._apply_filters()
	var remote_state := _selected_metadata_v0184(_remote_sync_filter_v0185)
	var deployment_state := _selected_metadata_v0184(_deployment_filter_v0185)
	if remote_state.is_empty() and deployment_state.is_empty():
		return
	var narrowed: Array[Dictionary] = []
	for row in _filtered:
		if not remote_state.is_empty():
			var states: Array = row.get("front_porch_sync_states_v0185", [])
			if not states.has(remote_state):
				continue
		var queued := bool(row.get("front_porch_deployment_queued_v0185", false))
		if deployment_state == "queued" and not queued:
			continue
		if deployment_state == "not_queued" and queued:
			continue
		narrowed.append(row)
	_filtered = narrowed
	_result_count.text = "%d of %d projects • remote/deployment policy applied" % [
		_filtered.size(), _projects.size()
	]
	_rebuild_content()
	_save_view_state()


func _save_view_state() -> void:
	super._save_view_state()
	if not _v0185_ready:
		return
	_view_state["remote_sync_filter_v0185"] = _selected_metadata_v0184(
		_remote_sync_filter_v0185
	)
	_view_state["deployment_filter_v0185"] = _selected_metadata_v0184(
		_deployment_filter_v0185
	)
	CCFLibraryService.save_view_state(_view_state)


func _restore_front_porch_filters_v0185() -> void:
	_select_metadata_v0184(
		_remote_sync_filter_v0185,
		str(_view_state.get("remote_sync_filter_v0185", ""))
	)
	_select_metadata_v0184(
		_deployment_filter_v0185,
		str(_view_state.get("deployment_filter_v0185", ""))
	)


func _update_detail(row: Dictionary) -> void:
	super._update_detail(row)
	if row.is_empty() or _detail_metadata == null:
		return
	var state_id := str(
		row.get("front_porch_sync_state_v0185", FRONT_PORCH_SYNC_SERVICE.STATE_NOT_INSTALLED)
	)
	_detail_metadata.text += "\nFront Porch: %s\nDeployment queue: %s" % [
		FRONT_PORCH_SYNC_SERVICE.sync_state_label(state_id),
		"Queued" if bool(row.get("front_porch_deployment_queued_v0185", false)) else "Not queued"
	]


func front_porch_library_capabilities_v0185() -> Dictionary:
	return {
		"remote_state_filter": _remote_sync_filter_v0185 != null,
		"deployment_queue_filter": _deployment_filter_v0185 != null,
		"library_browsing_network_requests": false
	}
