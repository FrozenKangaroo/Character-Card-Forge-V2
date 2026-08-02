extends SceneTree

const MANIFEST_PATH := "res://tools/regression_suites_v01520.json"
const REQUIRED_SUITES := [
	"current_wiring",
	"core",
	"generation",
	"authoring",
	"content",
	"collaborator",
	"image_and_vision",
	"workflow"
]
const REQUIRED_TEST_IDS := [
	"project_lifecycle",
	"default_template_selection",
	"generation_contract_dispatch",
	"v0146_preview_selection_safety",
	"v0147_manual_guided_components",
	"v0148_manual_guided_alternative_greetings",
	"v0149_library_ux",
	"v01415_lorebook_support",
	"v01420_relationship_variants",
	"v01421_ccfchar_import",
	"v01422_graph_canvas",
	"v015_character_collaborator",
	"v0155_independent_sessions",
	"v0157_collaborator_vision",
	"v01515_blueprint_handoff",
	"v01516_generation_pipeline_restoration",
	"v01517_blueprint_materialisation",
	"v01518_checkout_hygiene",
	"v01519_release_selection_shell"
]


func _init() -> void:
	var manifest_text := FileAccess.get_file_as_string(MANIFEST_PATH)
	assert(not manifest_text.is_empty(), "v0.15.20 regression manifest must exist.")
	var parsed: Variant = JSON.parse_string(manifest_text)
	assert(parsed is Dictionary, "v0.15.20 regression manifest must parse as a JSON object.")
	var manifest: Dictionary = parsed
	assert(int(manifest.get("format_version", 0)) == 1, "Regression manifest format must be versioned.")

	var suites_value: Variant = manifest.get("suites", {})
	assert(suites_value is Dictionary, "Regression manifest must contain suites.")
	var suites: Dictionary = suites_value
	for suite_name in REQUIRED_SUITES:
		assert(suites.has(suite_name), "Broad regression manifest is missing suite %s." % suite_name)

	var profiles_value: Variant = manifest.get("profiles", {})
	assert(profiles_value is Dictionary, "Regression manifest must contain profiles.")
	var profiles: Dictionary = profiles_value
	var release_profile_value: Variant = profiles.get("release", [])
	assert(release_profile_value is Array, "Release regression profile must be an array.")
	var release_profile: Array = release_profile_value
	for suite_name in REQUIRED_SUITES:
		assert(release_profile.has(suite_name), "Release profile must include %s regression coverage." % suite_name)

	var discovered_ids := {}
	var test_count := 0
	for suite_name in suites:
		var suite_value: Variant = suites[suite_name]
		assert(suite_value is Dictionary, "Regression suite %s must be an object." % suite_name)
		var suite: Dictionary = suite_value
		var tests_value: Variant = suite.get("tests", [])
		assert(tests_value is Array, "Regression suite %s must contain a tests array." % suite_name)
		for test_value in tests_value:
			assert(test_value is Dictionary, "Regression test entries must be objects.")
			var test: Dictionary = test_value
			var test_id := str(test.get("id", "")).strip_edges()
			var path := str(test.get("path", "")).strip_edges()
			assert(not test_id.is_empty(), "Every regression test must have a stable id.")
			assert(not discovered_ids.has(test_id), "Regression test ids must be unique: %s" % test_id)
			assert(not path.is_empty(), "Regression test %s must declare a path." % test_id)
			assert(FileAccess.file_exists("res://%s" % path), "Regression test path must exist: %s" % path)
			discovered_ids[test_id] = true
			test_count += 1
	assert(test_count >= 30, "The release regression profile should cover a broad representative surface, not only the newest feature.")
	for test_id in REQUIRED_TEST_IDS:
		assert(discovered_ids.has(test_id), "Broad regression coverage is missing critical feature test %s." % test_id)

	var runner_source := FileAccess.get_file_as_string("res://tools/run_regression_suite.py")
	assert(runner_source.contains("TemporaryDirectory"), "Local regression runs must isolate persistent app data.")
	assert(runner_source.contains('"CCF_REGRESSION_RUN": "1"'), "Regression subprocesses should be explicitly marked as test runs.")
	assert(runner_source.contains("failures.append"), "Broad runner must continue collecting failures instead of hiding later regressions behind the first failure.")

	var release_source := FileAccess.get_file_as_string("res://release.sh")
	assert(release_source.contains("run_regression_suite.py"), "release.sh must automatically run the broad regression gate when Godot is available.")
	assert(release_source.contains("--profile release"), "release.sh must use the full release regression profile.")

	var generation_service := CCFGenerationServiceV01517.new()
	assert(generation_service is CCFParityGenerationService, "Current generation must retain parity generation.")
	assert(generation_service is CCFInterviewGenerationService, "Current generation must retain Interview/Q&A.")
	assert(generation_service is CCFTemplateContractGuardGenerationService, "Current generation must retain template contract enforcement.")
	assert(generation_service is CCFConceptFidelityGenerationService, "Current generation must retain concept fidelity validation.")
	assert(generation_service.has_method("queue_collaborator_blueprint"), "Current generation must retain Blueprint-first Collaborator handoff.")
	generation_service.free()

	var main_source := FileAccess.get_file_as_string("res://scripts/main_v01520.gd")
	assert(main_source.contains('extends "res://scripts/main_v01519.gd"'), "v0.15.20 must preserve v0.15.19 through inheritance.")
	assert(main_source.contains('BUILD_DISPLAY_VERSION_V01520 := "0.15.20"'), "The v0.15.20 shell must expose its build version.")
	assert(_active_shell_inherits_from("res://scripts/main_v01520.gd"), "The active scene must use or inherit v0.15.20.")

	print("v0.15.20 broad regression safety regression passed")
	quit(0)


func _active_shell_inherits_from(target_path: String) -> bool:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		return false
	var root := packed.instantiate()
	if root == null:
		return false
	var current := root.get_script() as Script
	while current != null:
		if current.resource_path == target_path:
			root.free()
			return true
		current = current.get_base_script()
	root.free()
	return false
