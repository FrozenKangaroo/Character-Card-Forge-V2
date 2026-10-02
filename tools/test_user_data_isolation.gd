class_name CCFTestUserDataIsolation
extends RefCounted

# The Python runner already supplies process-level HOME/XDG/AppData isolation.
# Direct Godot test execution does not, so persistence tests opt in here before
# their first service call. This keeps user:// writes away from the real CCF
# application directory while preserving normal direct-test behaviour.


static func activate(test_id: String) -> Dictionary:
	var before := ProjectSettings.globalize_path("user://")
	# Do not trust the flag alone: a developer can inherit or set it while still
	# using the real application data directory. The official runner's user://
	# always lives below its ccf-regression-* temporary root.
	var runner_path_isolated := (
		OS.has_environment("CCF_REGRESSION_RUN")
		and before.contains("ccf-regression-")
	)
	if runner_path_isolated:
		return {
			"ok": true,
			"runner_isolated": true,
			"direct_isolated": false,
			"path": before
		}
	var safe_id := _safe_test_id(test_id)
	var custom_name := "ccf-regression-direct/%s-%d-%d" % [
		safe_id, OS.get_process_id(), Time.get_ticks_usec()
	]
	ProjectSettings.set_setting("application/config/use_custom_user_dir", true)
	ProjectSettings.set_setting("application/config/custom_user_dir_name", custom_name)
	var after := ProjectSettings.globalize_path("user://")
	var isolated := after != before and after.contains("ccf-regression-direct")
	if not isolated:
		push_error(
			"Regression user-data isolation could not be established; persistence tests must stop before writing."
		)
	assert(
		isolated,
		"Persistence regression refused to run without isolated user data."
	)
	if isolated:
		# Preserve the same non-interactive application behavior as the official
		# runner, but only after user:// has been successfully relocated.
		OS.set_environment("CCF_REGRESSION_RUN", "1")
	return {
		"ok": isolated,
		"runner_isolated": false,
		"direct_isolated": isolated,
		"path": after,
		"original_path": before
	}


static func require_active(state: Dictionary) -> void:
	assert(
		bool(state.get("ok", false)),
		"Persistence regression refused to run without isolated user data."
	)


static func _safe_test_id(test_id: String) -> String:
	var clean := test_id.strip_edges().to_lower()
	var expression := RegEx.new()
	expression.compile("[^a-z0-9_-]+")
	clean = expression.sub(clean, "-", true).strip_edges()
	return clean if not clean.is_empty() else "unnamed-test"
