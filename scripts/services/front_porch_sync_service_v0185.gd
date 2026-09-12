class_name CCFFrontPorchSyncServiceV0185
extends CCFFrontPorchInstallServiceV0173

const STATE_FILE := CCFStorageService.SETTINGS_DIR + "/front_porch_sync_v0185.json"
const PORTRAIT_CACHE_DIR := CCFStorageService.CACHE_DIR + "/front_porch_portraits_v0185"
const BINDING_KEY := "front_porch_sync_v0185"
const MAX_REPORTS := 30
const MAX_PORTRAIT_FILES := 48
const MAX_PORTRAIT_BYTES := 32 * 1024 * 1024

const STATE_NOT_INSTALLED := "not_installed"
const STATE_INSTALLED := "installed"
const STATE_MODIFIED_LOCALLY := "modified_locally"
const STATE_CHANGED_REMOTELY := "changed_front_porch"
const STATE_DIVERGED := "diverged"

var _verified_capabilities: Dictionary = {}


static func capabilities_v0185() -> Dictionary:
	return {
		"credential_safe_diagnostics": true,
		"behavior_based_capabilities": true,
		"authenticated_character_listing": true,
		"authenticated_portrait_cache": true,
		"bounded_portrait_cache": true,
		"explicit_install_identity": true,
		"exchange_fingerprints": true,
		"compare_before_change": true,
		"sequential_deployment_queue": true,
		"persistent_deployment_report": true,
		"advisory_source_update_checks": true,
		"group_import_requires_verified_endpoint": true,
		"delete_requires_verified_endpoint": true,
		"automatic_overwrite": false,
		"raw_database_writes": false,
		"credentials_persisted": false
	}


static func default_local_state() -> Dictionary:
	return {
		"format_version": 1,
		"deployment_queue": [],
		"deployment_reports": [],
		"source_update_opt_in": {}
	}


static func load_local_state() -> Dictionary:
	CCFStorageService.ensure_directories()
	if not FileAccess.file_exists(STATE_FILE):
		return default_local_state()
	var file := FileAccess.open(STATE_FILE, FileAccess.READ)
	if file == null:
		return default_local_state()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	var state := default_local_state()
	if parsed is Dictionary:
		for key in state.keys():
			if (parsed as Dictionary).has(key):
				state[key] = (parsed as Dictionary).get(key)
	return state


static func save_local_state(state: Dictionary) -> Dictionary:
	CCFStorageService.ensure_directories()
	var file := FileAccess.open(STATE_FILE, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not save Front Porch sync state."}
	file.store_string(JSON.stringify(state, "  "))
	file.close()
	return {"ok": true}


static func character_fingerprint(project: Dictionary, character_id: String) -> String:
	var card := CCFCardFormatService.export_character_v2(project, character_id)
	if card.is_empty():
		return ""
	return JSON.stringify(_canonical_value(card)).sha256_text()


static func card_fingerprint(card_value: Variant) -> String:
	if not card_value is Dictionary or (card_value as Dictionary).is_empty():
		return ""
	return JSON.stringify(_canonical_value(card_value)).sha256_text()


static func binding_for_character(project: Dictionary, character_id: String) -> Dictionary:
	var character := CCFStorageService.get_character(project, character_id)
	var workspace_value: Variant = character.get("workspace", {})
	if not workspace_value is Dictionary:
		return {}
	var binding_value: Variant = (workspace_value as Dictionary).get(BINDING_KEY, {})
	return (binding_value as Dictionary).duplicate(true) if binding_value is Dictionary else {}


static func record_exchange(
	project: Dictionary,
	character_id: String,
	remote_id: String,
	remote_fingerprint := ""
) -> Dictionary:
	var clean_remote_id := remote_id.strip_edges()
	var index := CCFStorageService.character_index(project, character_id)
	if index < 0 or clean_remote_id.is_empty():
		return {"ok": false, "error": "A local character and Front Porch character ID are required."}
	var updated := project.duplicate(true)
	var characters: Array = updated.get("characters", []).duplicate(true)
	var character: Dictionary = (characters[index] as Dictionary).duplicate(true)
	var workspace: Dictionary = character.get("workspace", {}).duplicate(true)
	var local_fingerprint := character_fingerprint(updated, character_id)
	workspace[BINDING_KEY] = {
		"remote_id": clean_remote_id,
		"last_exchanged_fingerprint": local_fingerprint,
		"last_remote_fingerprint": (
			remote_fingerprint if not remote_fingerprint.is_empty() else local_fingerprint
		),
		"last_exchanged_at": Time.get_datetime_string_from_system(true)
	}
	character["workspace"] = workspace
	characters[index] = character
	updated["characters"] = characters
	return {"ok": true, "project": updated, "binding": workspace[BINDING_KEY]}


static func record_remote_observation(
	project: Dictionary, character_id: String, remote_fingerprint: String
) -> Dictionary:
	var binding := binding_for_character(project, character_id)
	if binding.is_empty():
		return {"ok": false, "error": "This character is not linked to Front Porch."}
	var index := CCFStorageService.character_index(project, character_id)
	var updated := project.duplicate(true)
	var characters: Array = updated.get("characters", []).duplicate(true)
	var character: Dictionary = (characters[index] as Dictionary).duplicate(true)
	var workspace: Dictionary = character.get("workspace", {}).duplicate(true)
	binding["last_remote_fingerprint"] = remote_fingerprint
	binding["last_checked_at"] = Time.get_datetime_string_from_system(true)
	workspace[BINDING_KEY] = binding
	character["workspace"] = workspace
	characters[index] = character
	updated["characters"] = characters
	return {"ok": true, "project": updated, "binding": binding}


static func clear_binding(project: Dictionary, character_id: String) -> Dictionary:
	var index := CCFStorageService.character_index(project, character_id)
	if index < 0:
		return {"ok": false, "error": "The local character could not be found."}
	var updated := project.duplicate(true)
	var characters: Array = updated.get("characters", []).duplicate(true)
	var character: Dictionary = (characters[index] as Dictionary).duplicate(true)
	var workspace: Dictionary = character.get("workspace", {}).duplicate(true)
	workspace.erase(BINDING_KEY)
	character["workspace"] = workspace
	characters[index] = character
	updated["characters"] = characters
	return {"ok": true, "project": updated}


static func sync_state(
	local_fingerprint: String, last_exchanged: String, remote_fingerprint: String
) -> String:
	if last_exchanged.is_empty():
		return STATE_NOT_INSTALLED
	var local_changed := not local_fingerprint.is_empty() and local_fingerprint != last_exchanged
	var remote_changed := not remote_fingerprint.is_empty() and remote_fingerprint != last_exchanged
	if local_changed and remote_changed:
		return STATE_DIVERGED
	if local_changed:
		return STATE_MODIFIED_LOCALLY
	if remote_changed:
		return STATE_CHANGED_REMOTELY
	return STATE_INSTALLED


static func sync_state_label(state_id: String) -> String:
	match state_id:
		STATE_INSTALLED: return "Installed"
		STATE_MODIFIED_LOCALLY: return "Modified Locally"
		STATE_CHANGED_REMOTELY: return "Changed in Front Porch"
		STATE_DIVERGED: return "Diverged"
		_: return "Not Installed"


static func project_sync_summary(project: Dictionary) -> Dictionary:
	var states: Array[String] = []
	var remote_ids: Array[String] = []
	for character_value in project.get("characters", []):
		if not character_value is Dictionary:
			continue
		var character := character_value as Dictionary
		var character_id := str(character.get("character_id", ""))
		var binding := binding_for_character(project, character_id)
		var state_id := sync_state(
			character_fingerprint(project, character_id),
			str(binding.get("last_exchanged_fingerprint", "")),
			str(binding.get("last_remote_fingerprint", ""))
		)
		if not states.has(state_id):
			states.append(state_id)
		var remote_id := str(binding.get("remote_id", ""))
		if not remote_id.is_empty():
			remote_ids.append(remote_id)
	var aggregate := STATE_NOT_INSTALLED
	for priority_state in [STATE_DIVERGED, STATE_CHANGED_REMOTELY, STATE_MODIFIED_LOCALLY, STATE_INSTALLED]:
		if states.has(priority_state):
			aggregate = priority_state
			break
	return {"state": aggregate, "states": states, "remote_ids": remote_ids}


static func enhance_library_rows(rows: Array[Dictionary]) -> Array[Dictionary]:
	var queued_projects: Dictionary = {}
	for item_value in load_local_state().get("deployment_queue", []):
		if item_value is Dictionary:
			queued_projects[str((item_value as Dictionary).get("project_id", ""))] = true
	var result: Array[Dictionary] = []
	for source_row in rows:
		var row := source_row.duplicate(true)
		var project_id := str(row.get("project_id", ""))
		var loaded := CCFStorageService.load_project(project_id)
		var summary := {"state": STATE_NOT_INSTALLED, "states": [STATE_NOT_INSTALLED]}
		if bool(loaded.get("ok", false)):
			summary = project_sync_summary(loaded.get("data", {}))
		row["front_porch_sync_state_v0185"] = summary.get("state", STATE_NOT_INSTALLED)
		row["front_porch_sync_states_v0185"] = summary.get("states", [])
		row["front_porch_deployment_queued_v0185"] = queued_projects.has(project_id)
		result.append(row)
	return result


static func field_differences(local_card: Dictionary, remote_card: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var local_data: Dictionary = local_card.get("data", {}) if local_card.get("data", {}) is Dictionary else {}
	var remote_data: Dictionary = remote_card.get("data", {}) if remote_card.get("data", {}) is Dictionary else {}
	var keys: Array = local_data.keys()
	for key in remote_data.keys():
		if not keys.has(key):
			keys.append(key)
	keys.sort()
	for key_value in keys:
		var key := str(key_value)
		if _canonical_value(local_data.get(key)) == _canonical_value(remote_data.get(key)):
			continue
		rows.append({
			"field": key,
			"local": _display_value(local_data.get(key)),
			"front_porch": _display_value(remote_data.get(key))
		})
	return rows


static func differences_text(rows: Array[Dictionary]) -> String:
	if rows.is_empty():
		return "No authored Character Card differences found."
	var lines := PackedStringArray(["Authored fields that differ (%d)" % rows.size(), ""])
	for row in rows:
		lines.append("%s" % str(row.get("field", "field")).capitalize())
		lines.append("  CCF: %s" % str(row.get("local", "")))
		lines.append("  Front Porch: %s" % str(row.get("front_porch", "")))
		lines.append("")
	return "\n".join(lines)


static func enqueue_deployment(item: Dictionary) -> Dictionary:
	var clean := {
		"queue_id": str(item.get("queue_id", "")).strip_edges(),
		"project_id": str(item.get("project_id", "")).strip_edges(),
		"character_id": str(item.get("character_id", "")).strip_edges(),
		"action": str(item.get("action", "install")),
		"remote_id": str(item.get("remote_id", "")).strip_edges(),
		"queued_at": Time.get_datetime_string_from_system(true)
	}
	if str(clean.get("queue_id", "")).is_empty():
		clean["queue_id"] = "%s-%d" % [str(clean.get("character_id", "")), Time.get_ticks_msec()]
	if str(clean.get("project_id", "")).is_empty() or str(clean.get("character_id", "")).is_empty():
		return {"ok": false, "error": "A project and character are required."}
	if not str(clean.get("action", "")) in ["install", "update"]:
		return {"ok": false, "error": "Deployment action must be install or update."}
	if clean.get("action") == "update" and str(clean.get("remote_id", "")).is_empty():
		return {"ok": false, "error": "Update requires the linked Front Porch character ID."}
	var state := load_local_state()
	var queue: Array = state.get("deployment_queue", []).duplicate(true)
	queue.append(clean)
	state["deployment_queue"] = queue
	var saved := save_local_state(state)
	return {"ok": bool(saved.get("ok", false)), "item": clean, "queue": queue, "error": saved.get("error", "")}


static func deployment_queue() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in load_local_state().get("deployment_queue", []):
		if value is Dictionary:
			result.append((value as Dictionary).duplicate(true))
	return result


static func replace_deployment_queue(queue: Array) -> Dictionary:
	var state := load_local_state()
	state["deployment_queue"] = queue.duplicate(true)
	return save_local_state(state)


static func append_deployment_report(report: Dictionary) -> Dictionary:
	var state := load_local_state()
	var reports: Array = state.get("deployment_reports", []).duplicate(true)
	var clean := report.duplicate(true)
	clean["recorded_at"] = Time.get_datetime_string_from_system(true)
	reports.push_front(clean)
	if reports.size() > MAX_REPORTS:
		reports.resize(MAX_REPORTS)
	state["deployment_reports"] = reports
	return save_local_state(state)


static func deployment_report_text() -> String:
	var reports: Array = load_local_state().get("deployment_reports", [])
	if reports.is_empty():
		return "No deployments have been run."
	var lines := PackedStringArray(["Front Porch Deployment History", ""])
	for value in reports:
		if not value is Dictionary:
			continue
		var report := value as Dictionary
		lines.append("%s — %s" % [str(report.get("recorded_at", "")), str(report.get("summary", "Deployment"))])
		for outcome_value in report.get("outcomes", []):
			if outcome_value is Dictionary:
				var outcome := outcome_value as Dictionary
				lines.append("  [%s] %s — %s" % [str(outcome.get("status", "unknown")).to_upper(), str(outcome.get("name", "Character")), str(outcome.get("message", ""))])
		lines.append("")
	return "\n".join(lines)


static func source_update_eligibility(character: Dictionary) -> Dictionary:
	var interoperability: Dictionary = character.get("interoperability", {}) if character.get("interoperability", {}) is Dictionary else {}
	var source_url := str(interoperability.get("source_url", interoperability.get("source_uri", ""))).strip_edges()
	var source_id := str(interoperability.get("source_id", interoperability.get("public_id", ""))).strip_edges()
	var public_url := source_url.begins_with("https://") or source_url.begins_with("http://")
	return {
		"eligible": public_url or not source_id.is_empty(),
		"source_url": source_url,
		"source_id": source_id,
		"reason": "Stable public source found." if public_url or not source_id.is_empty() else "No stable public source ID or URL is recorded."
	}


func verified_capabilities() -> Dictionary:
	return _verified_capabilities.duplicate(true)


func list_remote_characters() -> Dictionary:
	if not is_authenticated():
		return {"ok": false, "auth_required": true, "error": "Connect to Front Porch first."}
	var raw := await _perform_request(HTTPClient.METHOD_GET, "/api/characters?scope=allCharacters&sort=name", "", _session_headers())
	var response := _classify_json_response(raw, "Could not load the Front Porch character library.")
	if not bool(response.get("ok", false)):
		return response
	var payload: Variant = response.get("payload", {})
	var characters: Array = []
	if payload is Array:
		characters = (payload as Array).duplicate(true)
	elif payload is Dictionary:
		for key in ["characters", "items", "results"]:
			if (payload as Dictionary).get(key, null) is Array:
				characters = ((payload as Dictionary).get(key) as Array).duplicate(true)
				break
	_verified_capabilities["character_list"] = true
	_absorb_explicit_capabilities(payload)
	return {"ok": true, "characters": characters, "payload": payload}


func fetch_remote_detail(remote_id: String) -> Dictionary:
	return await _fetch_remote_json("/api/characters/%s/detail" % remote_id.uri_encode(), "character_detail")


func fetch_remote_card(remote_id: String) -> Dictionary:
	var result := await _fetch_remote_json("/api/characters/%s/export.json" % remote_id.uri_encode(), "character_export_json")
	if bool(result.get("ok", false)):
		result["card"] = result.get("payload", {})
	return result


func fetch_portrait(remote_id: String, width := 320) -> Dictionary:
	if not is_authenticated():
		return {"ok": false, "auth_required": true, "error": "Connect to Front Porch first."}
	var safe_width := clampi(width, 64, 1024)
	var raw := await _perform_binary_request(HTTPClient.METHOD_GET, "/api/characters/%s/avatar?w=%d" % [remote_id.uri_encode(), safe_width], _session_headers())
	var failure := _binary_failure(raw, "Could not fetch the Front Porch portrait.")
	if not failure.is_empty():
		return failure
	var bytes: PackedByteArray = raw.get("bytes", PackedByteArray())
	if bytes.is_empty():
		return {"ok": false, "error": "Front Porch returned an empty portrait."}
	CCFStorageService.ensure_directories()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PORTRAIT_CACHE_DIR))
	var cache_path := PORTRAIT_CACHE_DIR.path_join("%s-%d.img" % [_safe_filename(remote_id), safe_width])
	var file := FileAccess.open(cache_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not cache the Front Porch portrait."}
	file.store_buffer(bytes)
	file.close()
	_trim_portrait_cache()
	_verified_capabilities["authenticated_portrait"] = true
	return {"ok": true, "path": cache_path, "bytes": bytes, "response_code": 200}


func run_diagnostics(sample_remote_id := "") -> Dictionary:
	var lines := PackedStringArray(["Character Card Forge v0.18.5 — Front Porch Connection Report", "Address: %s" % base_url(), "Credentials and session cookies: omitted", ""])
	var health := await detect()
	if not bool(health.get("ok", false)):
		lines.append("Reachability: Failed — %s" % str(health.get("error", "Front Porch unavailable.")))
		return {"ok": false, "report": "\n".join(lines), "health": health, "capabilities": verified_capabilities()}
	lines.append("Reachability: Passed")
	lines.append("Front Porch version: %s" % str(health.get("version", "unknown")))
	_absorb_explicit_capabilities(health.get("payload", {}))
	var auth := await auth_state()
	lines.append("Login session: %s" % ("Authenticated" if bool(auth.get("authenticated", false)) else "Not authenticated"))
	if not bool(auth.get("authenticated", false)):
		return {"ok": true, "report": "\n".join(lines), "health": health, "auth": auth, "capabilities": verified_capabilities()}
	var listed := await list_remote_characters()
	lines.append("Character library endpoint: %s" % ("Passed" if bool(listed.get("ok", false)) else "Failed — %s" % str(listed.get("error", "Unavailable"))))
	var remote_id := sample_remote_id.strip_edges()
	if remote_id.is_empty() and bool(listed.get("ok", false)):
		var characters: Array = listed.get("characters", [])
		if not characters.is_empty() and characters[0] is Dictionary:
			remote_id = str((characters[0] as Dictionary).get("id", ""))
	if not remote_id.is_empty():
		var detail := await fetch_remote_detail(remote_id)
		lines.append("Character detail endpoint: %s" % ("Passed" if bool(detail.get("ok", false)) else "Unavailable"))
		var exported := await fetch_remote_card(remote_id)
		lines.append("Character export endpoint: %s" % ("Passed" if bool(exported.get("ok", false)) else "Unavailable"))
		var portrait := await fetch_portrait(remote_id, 96)
		lines.append("Authenticated portrait endpoint: %s" % ("Passed" if bool(portrait.get("ok", false)) else "Unavailable"))
	lines.append("")
	lines.append("Verified capabilities: %s" % _capability_labels())
	lines.append("Character deletion: %s" % ("Verified" if bool(_verified_capabilities.get("character_delete", false)) else "Not verified; disabled in CCF"))
	lines.append("Group-card import: %s" % ("Verified" if bool(_verified_capabilities.get("group_card_import", false)) else "Not verified; CCF will not send group packages to character import"))
	lines.append("Direct database access: Never used")
	return {"ok": bool(listed.get("ok", false)), "report": "\n".join(lines), "health": health, "auth": auth, "characters": listed.get("characters", []), "capabilities": verified_capabilities()}


func delete_remote_character(remote_id: String) -> Dictionary:
	if not bool(_verified_capabilities.get("character_delete", false)):
		return {"ok": false, "unsupported": true, "error": "Front Porch deletion was not safely verified, so Remove is disabled."}
	var raw := await _perform_request(HTTPClient.METHOD_POST, "/api/characters/%s/delete" % remote_id.uri_encode(), "", _session_headers())
	return _classify_json_response(raw, "Front Porch did not remove the character.")


func check_public_source_update(
	source_url: String, current_fingerprint: String
) -> Dictionary:
	var clean_url := source_url.strip_edges()
	if not clean_url.begins_with("https://") and not clean_url.begins_with("http://"):
		return {"ok": false, "error": "The imported source does not provide a public HTTP(S) URL."}
	if not is_inside_tree():
		return {"ok": false, "error": "The update checker is not attached to the running app."}
	var request := HTTPRequest.new()
	request.timeout = REQUEST_TIMEOUT_SECONDS
	request.use_threads = true
	request.body_size_limit = 4 * 1024 * 1024
	request.max_redirects = 3
	add_child(request)
	var start_error := request.request(
		clean_url,
		PackedStringArray(["Accept: application/json"]),
		HTTPClient.METHOD_GET
	)
	if start_error != OK:
		request.queue_free()
		return {"ok": false, "error": "Could not start the public source check (%s)." % error_string(start_error)}
	var completed: Array = await request.request_completed
	request.queue_free()
	if int(completed[0]) != HTTP_REQUEST_SUCCESS:
		return {"ok": false, "error": "The public source could not be reached."}
	var response_code := int(completed[1])
	if response_code < 200 or response_code >= 300:
		return {"ok": false, "error": "The public source returned HTTP %d." % response_code}
	var parsed: Variant = JSON.parse_string((completed[3] as PackedByteArray).get_string_from_utf8())
	if not parsed is Dictionary:
		return {"ok": false, "error": "The public source did not return a Character Card JSON object."}
	var source_fingerprint := card_fingerprint(parsed)
	if source_fingerprint.is_empty():
		return {"ok": false, "error": "The public source card could not be fingerprinted."}
	return {
		"ok": true,
		"update_available": source_fingerprint != current_fingerprint,
		"source_fingerprint": source_fingerprint,
		"card": (parsed as Dictionary).duplicate(true)
	}


func _fetch_remote_json(path: String, capability_key: String) -> Dictionary:
	if not is_authenticated():
		return {"ok": false, "auth_required": true, "error": "Connect to Front Porch first."}
	var raw := await _perform_request(HTTPClient.METHOD_GET, path, "", _session_headers())
	var result := _classify_json_response(raw, "Front Porch endpoint is unavailable.")
	if bool(result.get("ok", false)):
		_verified_capabilities[capability_key] = true
		_absorb_explicit_capabilities(result.get("payload", {}))
	return result


func _classify_json_response(raw: Dictionary, fallback: String) -> Dictionary:
	if int(raw.get("network_result", -1)) != HTTP_REQUEST_SUCCESS:
		return {"ok": false, "network_error": true, "error": str(raw.get("error", fallback))}
	var code := int(raw.get("response_code", 0))
	if code == 401:
		clear_session()
		return {"ok": false, "auth_required": true, "response_code": code, "error": "Front Porch login expired."}
	var payload: Variant = JSON.parse_string(str(raw.get("body", "")))
	if code < 200 or code >= 300:
		var message := fallback
		if payload is Dictionary and not str((payload as Dictionary).get("error", "")).is_empty():
			message = str((payload as Dictionary).get("error", ""))
		return {"ok": false, "response_code": code, "error": "%s (HTTP %d)" % [message, code], "payload": payload}
	if payload == null:
		return {"ok": false, "response_code": code, "error": "Front Porch returned unreadable JSON."}
	return {"ok": true, "response_code": code, "payload": payload}


func _perform_binary_request(method: HTTPClient.Method, path: String, headers: PackedStringArray) -> Dictionary:
	if not is_inside_tree():
		return {"network_result": -1, "response_code": 0, "bytes": PackedByteArray(), "error": "Front Porch client is not attached to the running app."}
	var request := HTTPRequest.new()
	request.timeout = REQUEST_TIMEOUT_SECONDS
	request.use_threads = true
	add_child(request)
	var start_error := request.request(_base_url + path, headers, method)
	if start_error != OK:
		request.queue_free()
		return {"network_result": -1, "response_code": 0, "bytes": PackedByteArray(), "error": "Could not start the Front Porch request (%s)." % error_string(start_error)}
	var completed: Array = await request.request_completed
	request.queue_free()
	return {"network_result": int(completed[0]), "response_code": int(completed[1]), "headers": completed[2], "bytes": completed[3]}


func _binary_failure(raw: Dictionary, fallback: String) -> Dictionary:
	if int(raw.get("network_result", -1)) != HTTP_REQUEST_SUCCESS:
		return {"ok": false, "network_error": true, "error": str(raw.get("error", fallback))}
	var code := int(raw.get("response_code", 0))
	if code == 401:
		clear_session()
		return {"ok": false, "auth_required": true, "error": "Front Porch login expired."}
	if code < 200 or code >= 300:
		return {"ok": false, "response_code": code, "error": "%s (HTTP %d)" % [fallback, code]}
	return {}


func _absorb_explicit_capabilities(payload: Variant) -> void:
	if not payload is Dictionary:
		return
	var candidates: Array[Dictionary] = []
	for key in ["capabilities", "features", "apiCapabilities"]:
		var value: Variant = (payload as Dictionary).get(key, {})
		if value is Dictionary:
			candidates.append(value)
	for candidate in candidates:
		for source_key in ["characterDelete", "character_delete", "deleteCharacter"]:
			if candidate.get(source_key, false) == true:
				_verified_capabilities["character_delete"] = true
		for source_key in ["groupCardImport", "group_card_import", "groupImport"]:
			if candidate.get(source_key, false) == true:
				_verified_capabilities["group_card_import"] = true


func _capability_labels() -> String:
	var labels := PackedStringArray()
	for key in _verified_capabilities.keys():
		if bool(_verified_capabilities.get(key, false)):
			labels.append(str(key).replace("_", " "))
	labels.sort()
	return ", ".join(labels) if not labels.is_empty() else "none beyond reachability"


static func _trim_portrait_cache() -> void:
	var absolute := ProjectSettings.globalize_path(PORTRAIT_CACHE_DIR)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	var rows: Array[Dictionary] = []
	var total_bytes := 0
	for filename in DirAccess.get_files_at(PORTRAIT_CACHE_DIR):
		var path := PORTRAIT_CACHE_DIR.path_join(filename)
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var size := file.get_length()
		var modified := FileAccess.get_modified_time(path)
		file.close()
		total_bytes += size
		rows.append({"path": path, "size": size, "modified": modified})
	rows.sort_custom(func(first: Dictionary, second: Dictionary) -> bool: return int(first.get("modified", 0)) < int(second.get("modified", 0)))
	while rows.size() > MAX_PORTRAIT_FILES or total_bytes > MAX_PORTRAIT_BYTES:
		var oldest: Dictionary = rows.pop_front()
		total_bytes -= int(oldest.get("size", 0))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(str(oldest.get("path", ""))))


static func _canonical_value(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		var keys: Array = (value as Dictionary).keys()
		keys.sort_custom(func(first: Variant, second: Variant) -> bool: return str(first) < str(second))
		for key in keys:
			result[str(key)] = _canonical_value((value as Dictionary).get(key))
		return result
	if value is Array:
		var result: Array = []
		for item in value as Array:
			result.append(_canonical_value(item))
		return result
	return value


static func _display_value(value: Variant) -> String:
	var text := str(value) if not value is Array and not value is Dictionary else JSON.stringify(value)
	text = text.replace("\n", " ").strip_edges()
	return text.left(240) + ("…" if text.length() > 240 else "")


static func _safe_filename(value: String) -> String:
	var result := ""
	for index in range(value.length()):
		var character := value.substr(index, 1)
		if "abcdefghijklmnopqrstuvwxyz0123456789-_".contains(character.to_lower()):
			result += character.to_lower()
	return result if not result.is_empty() else "portrait"
