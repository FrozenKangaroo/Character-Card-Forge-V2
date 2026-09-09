class_name CCFUpdateServiceV0180Hotfix2
extends Node

signal check_started()
signal check_finished(result: Dictionary)

const UPDATE_SERVICE_VERSION_V0180_HOTFIX2 := 1
const CACHE_FORMAT_VERSION_V0180_HOTFIX2 := 1
const CHECK_INTERVAL_SECONDS_V0180_HOTFIX2 := 86400
const MAX_RELEASE_BODY_CHARS_V0180_HOTFIX2 := 16000
const REPOSITORY_V0180_HOTFIX2 := "FrozenKangaroo/Character-Card-Forge-V2"
const LATEST_RELEASE_API_V0180_HOTFIX2 := (
	"https://api.github.com/repos/%s/releases/latest"
	% REPOSITORY_V0180_HOTFIX2
)
const RELEASE_PAGE_PREFIX_V0180_HOTFIX2 := (
	"https://github.com/%s/releases/tag/" % REPOSITORY_V0180_HOTFIX2
)
const RELEASE_DOWNLOAD_PREFIX_V0180_HOTFIX2 := (
	"https://github.com/%s/releases/download/" % REPOSITORY_V0180_HOTFIX2
)
const RELEASES_PAGE_V0180_HOTFIX2 := (
	"https://github.com/%s/releases" % REPOSITORY_V0180_HOTFIX2
)
const CACHE_FILE_V0180_HOTFIX2 := (
	CCFStorageService.CACHE_DIR + "/github_update_check_v1.json"
)

var _request_v0180_hotfix2: HTTPRequest
var _busy_v0180_hotfix2 := false
var _requested_current_version_v0180_hotfix2 := ""
var _cache_v0180_hotfix2: Dictionary = {}


func _ready() -> void:
	_cache_v0180_hotfix2 = _load_cache_v0180_hotfix2()
	_request_v0180_hotfix2 = HTTPRequest.new()
	_request_v0180_hotfix2.timeout = 30.0
	_request_v0180_hotfix2.body_size_limit = 2 * 1024 * 1024
	add_child(_request_v0180_hotfix2)
	_request_v0180_hotfix2.request_completed.connect(
		_on_request_completed_v0180_hotfix2
	)


func update_capabilities_v0180_hotfix2() -> Dictionary:
	return {
		"version": "0.18.0-hotfix2",
		"service_version": UPDATE_SERVICE_VERSION_V0180_HOTFIX2,
		"github_public_release_api": true,
		"automatic_packaged_startup_check": true,
		"minimum_check_interval_hours": 24,
		"manual_check": true,
		"platform_asset_selection": true,
		"silent_install": false,
		"provider_credentials_used": false,
		"source_editor_auto_network": false
	}


func is_busy_v0180_hotfix2() -> bool:
	return _busy_v0180_hotfix2


func releases_page_v0180_hotfix2() -> String:
	return RELEASES_PAGE_V0180_HOTFIX2


func automatic_check_due_v0180_hotfix2(now_unix: int = -1) -> bool:
	var now := now_unix
	if now < 0:
		now = int(Time.get_unix_time_from_system())
	var last_checked := int(
		_cache_v0180_hotfix2.get("last_checked_unix", 0)
	)
	return (
		last_checked <= 0
		or now - last_checked >= CHECK_INTERVAL_SECONDS_V0180_HOTFIX2
	)


func cached_result_v0180_hotfix2(current_version: String) -> Dictionary:
	var release_value: Variant = _cache_v0180_hotfix2.get("release", {})
	if not release_value is Dictionary or release_value.is_empty():
		return {"ok": false, "error": "No cached GitHub release check is available."}
	return evaluate_release_v0180_hotfix2(
		current_version, release_value as Dictionary
	)


func check_for_updates_v0180_hotfix2(
	current_version: String
) -> Dictionary:
	if _busy_v0180_hotfix2:
		return {"ok": false, "error": "An update check is already running."}
	if not bool(parse_version_v0180_hotfix2(current_version).get("ok", false)):
		return {
			"ok": false,
			"error": "The installed application version is not comparable."
		}
	var headers := PackedStringArray([
		"Accept: application/vnd.github+json",
		"User-Agent: Character-Card-Forge-V2",
		"X-GitHub-Api-Version: 2022-11-28"
	])
	var etag := str(_cache_v0180_hotfix2.get("etag", "")).strip_edges()
	if not etag.is_empty():
		headers.append("If-None-Match: %s" % etag)
	_requested_current_version_v0180_hotfix2 = current_version.strip_edges()
	_busy_v0180_hotfix2 = true
	var request_error := _request_v0180_hotfix2.request(
		LATEST_RELEASE_API_V0180_HOTFIX2,
		headers,
		HTTPClient.METHOD_GET
	)
	if request_error != OK:
		_busy_v0180_hotfix2 = false
		_requested_current_version_v0180_hotfix2 = ""
		return {
			"ok": false,
			"error": "Could not start the GitHub update check (error %s)."
			% request_error
		}
	check_started.emit()
	return {"ok": true}


func process_release_response_v0180_hotfix2(
	current_version: String,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray,
	cached_release: Dictionary = {}
) -> Dictionary:
	if response_code == 304:
		if cached_release.is_empty():
			return {
				"ok": false,
				"error": "GitHub returned an unchanged response but no cached release exists."
			}
		return evaluate_release_v0180_hotfix2(
			current_version, cached_release
		)
	if response_code == 403 or response_code == 429:
		return {
			"ok": false,
			"error": "GitHub temporarily limited update checks. CCF will wait before checking automatically again."
		}
	if response_code == 404:
		return {
			"ok": false,
			"error": "GitHub does not currently report a published Character Card Forge release."
		}
	if response_code < 200 or response_code >= 300:
		return {
			"ok": false,
			"error": "GitHub update check returned HTTP %s." % response_code
		}
	var body_text := body.get_string_from_utf8()
	var parser := JSON.new()
	if parser.parse(body_text) != OK or not parser.data is Dictionary:
		return {
			"ok": false,
			"error": "GitHub returned an invalid release description."
		}
	var release := normalise_release_v0180_hotfix2(parser.data as Dictionary)
	if release.is_empty():
		return {
			"ok": false,
			"error": "GitHub's latest release did not contain a safe, comparable release record."
		}
	var result := evaluate_release_v0180_hotfix2(
		current_version, release
	)
	if bool(result.get("ok", false)):
		result["etag"] = _header_value_v0180_hotfix2(headers, "etag")
	return result


func evaluate_release_v0180_hotfix2(
	current_version: String, release: Dictionary
) -> Dictionary:
	var latest_version := str(release.get("version", "")).strip_edges()
	var comparison := compare_versions_v0180_hotfix2(
		latest_version, current_version
	)
	if comparison == -99:
		return {
			"ok": false,
			"error": "The GitHub release version could not be compared safely."
		}
	var platform_name := OS.get_name()
	var asset := select_platform_asset_v0180_hotfix2(
		release, platform_name
	)
	return {
		"ok": true,
		"current_version": current_version,
		"latest_version": latest_version,
		"comparison": comparison,
		"update_available": comparison > 0,
		"release": release.duplicate(true),
		"platform": platform_name,
		"asset": asset
	}


static func normalise_release_v0180_hotfix2(raw: Dictionary) -> Dictionary:
	if bool(raw.get("draft", false)) or bool(raw.get("prerelease", false)):
		return {}
	var tag := str(raw.get("tag_name", "")).strip_edges()
	var parsed_version := parse_version_v0180_hotfix2(tag)
	if not bool(parsed_version.get("ok", false)):
		return {}
	var release_url := str(raw.get("html_url", "")).strip_edges()
	if not release_url.begins_with(RELEASE_PAGE_PREFIX_V0180_HOTFIX2):
		return {}
	var assets: Array = []
	var raw_assets: Variant = raw.get("assets", [])
	if raw_assets is Array:
		for raw_asset in raw_assets:
			if not raw_asset is Dictionary:
				continue
			var asset_name := str(raw_asset.get("name", "")).strip_edges()
			var download_url := str(
				raw_asset.get("browser_download_url", "")
			).strip_edges()
			if (
				asset_name.is_empty()
				or asset_name.contains("/")
				or asset_name.contains("\\")
				or not download_url.begins_with(
					RELEASE_DOWNLOAD_PREFIX_V0180_HOTFIX2
				)
				or str(raw_asset.get("state", "uploaded")) != "uploaded"
			):
				continue
			assets.append({
				"name": asset_name,
				"download_url": download_url,
				"size": maxi(0, int(raw_asset.get("size", 0))),
				"digest": str(raw_asset.get("digest", "")).strip_edges()
			})
	var release_body := str(raw.get("body", "")).strip_edges()
	return {
		"tag": tag,
		"version": str(parsed_version.get("normalised", "")),
		"name": str(raw.get("name", tag)).strip_edges(),
		"body": release_body.left(MAX_RELEASE_BODY_CHARS_V0180_HOTFIX2),
		"published_at": str(raw.get("published_at", "")).strip_edges(),
		"release_url": release_url,
		"assets": assets
	}


static func select_platform_asset_v0180_hotfix2(
	release: Dictionary, platform_name: String
) -> Dictionary:
	var suffix := ""
	match platform_name:
		"Windows":
			suffix = "-windows-x86_64.zip"
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			suffix = "-linux-x86_64.tar.gz"
		"macOS":
			suffix = "-macos-universal-unsigned.zip"
		_:
			return {}
	var release_version := str(release.get("version", "")).strip_edges()
	if release_version.is_empty():
		return {}
	var expected_name := "CharacterCardForge-v%s%s" % [
		release_version, suffix
	]
	var assets_value: Variant = release.get("assets", [])
	if not assets_value is Array:
		return {}
	for raw_asset in assets_value:
		if (
			raw_asset is Dictionary
			and str(raw_asset.get("name", "")) == expected_name
		):
			return raw_asset.duplicate(true)
	return {}


static func compare_versions_v0180_hotfix2(
	left_version: String, right_version: String
) -> int:
	var left := parse_version_v0180_hotfix2(left_version)
	var right := parse_version_v0180_hotfix2(right_version)
	if not bool(left.get("ok", false)) or not bool(right.get("ok", false)):
		return -99
	var left_core: Array = left.get("core", [])
	var right_core: Array = right.get("core", [])
	for index in range(3):
		var left_number := int(left_core[index])
		var right_number := int(right_core[index])
		if left_number != right_number:
			return 1 if left_number > right_number else -1
	var left_rank := int(left.get("suffix_rank", 0))
	var right_rank := int(right.get("suffix_rank", 0))
	if left_rank != right_rank:
		return 1 if left_rank > right_rank else -1
	var left_suffix: Array = left.get("suffix", [])
	var right_suffix: Array = right.get("suffix", [])
	var longest := maxi(left_suffix.size(), right_suffix.size())
	for index in range(longest):
		if index >= left_suffix.size():
			return -1
		if index >= right_suffix.size():
			return 1
		var token_compare := _compare_version_token_v0180_hotfix2(
			str(left_suffix[index]), str(right_suffix[index])
		)
		if token_compare != 0:
			return token_compare
	return 0


static func parse_version_v0180_hotfix2(raw_version: String) -> Dictionary:
	var clean := raw_version.strip_edges()
	if clean.begins_with("v") or clean.begins_with("V"):
		clean = clean.substr(1)
	if clean.is_empty():
		return {"ok": false}
	clean = clean.split("+", true, 1)[0]
	var version_parts := clean.split("-", true, 1)
	var core_text := str(version_parts[0])
	var raw_core := core_text.split(".", false)
	if raw_core.is_empty() or raw_core.size() > 3:
		return {"ok": false}
	var core: Array[int] = []
	for raw_number in raw_core:
		var number_text := str(raw_number)
		if not number_text.is_valid_int() or int(number_text) < 0:
			return {"ok": false}
		core.append(int(number_text))
	while core.size() < 3:
		core.append(0)
	var suffix: Array[String] = []
	var suffix_rank := 0
	if version_parts.size() > 1:
		var suffix_text := str(version_parts[1]).strip_edges().to_lower()
		if suffix_text.is_empty():
			return {"ok": false}
		suffix_rank = 1 if suffix_text.begins_with("hotfix") else -1
		for token in suffix_text.replace("-", ".").split(".", false):
			suffix.append(str(token))
	var normalised := "%d.%d.%d" % [core[0], core[1], core[2]]
	if not suffix.is_empty():
		normalised += "-" + ".".join(suffix)
	return {
		"ok": true,
		"normalised": normalised,
		"core": core,
		"suffix": suffix,
		"suffix_rank": suffix_rank
	}


static func _compare_version_token_v0180_hotfix2(
	left: String, right: String
) -> int:
	if left == right:
		return 0
	if left.is_valid_int() and right.is_valid_int():
		return 1 if int(left) > int(right) else -1
	if left.is_valid_int() != right.is_valid_int():
		return -1 if left.is_valid_int() else 1
	return 1 if left > right else -1


func _on_request_completed_v0180_hotfix2(
	network_result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	_busy_v0180_hotfix2 = false
	var current_version := _requested_current_version_v0180_hotfix2
	_requested_current_version_v0180_hotfix2 = ""
	_cache_v0180_hotfix2["last_checked_unix"] = int(
		Time.get_unix_time_from_system()
	)
	if network_result != HTTPRequest.RESULT_SUCCESS:
		_save_cache_v0180_hotfix2()
		check_finished.emit({
			"ok": false,
			"error": "Could not reach GitHub for an update check (network result %s)."
			% network_result
		})
		return
	var cached_release_value: Variant = _cache_v0180_hotfix2.get(
		"release", {}
	)
	var cached_release: Dictionary = (
		cached_release_value.duplicate(true)
		if cached_release_value is Dictionary
		else {}
	)
	var result := process_release_response_v0180_hotfix2(
		current_version,
		response_code,
		headers,
		body,
		cached_release
	)
	if bool(result.get("ok", false)):
		var release_value: Variant = result.get("release", {})
		if release_value is Dictionary:
			_cache_v0180_hotfix2["release"] = release_value.duplicate(true)
		var etag := str(result.get("etag", "")).strip_edges()
		if not etag.is_empty():
			_cache_v0180_hotfix2["etag"] = etag
	_save_cache_v0180_hotfix2()
	check_finished.emit(result)


func _load_cache_v0180_hotfix2() -> Dictionary:
	if not FileAccess.file_exists(CACHE_FILE_V0180_HOTFIX2):
		return {
			"format_version": CACHE_FORMAT_VERSION_V0180_HOTFIX2,
			"last_checked_unix": 0,
			"etag": "",
			"release": {}
		}
	var file := FileAccess.open(CACHE_FILE_V0180_HOTFIX2, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not parser.data is Dictionary:
		return {}
	var parsed: Dictionary = parser.data
	return {
		"format_version": CACHE_FORMAT_VERSION_V0180_HOTFIX2,
		"last_checked_unix": maxi(0, int(parsed.get("last_checked_unix", 0))),
		"etag": str(parsed.get("etag", "")).strip_edges(),
		"release": (
			parsed.get("release", {}).duplicate(true)
			if parsed.get("release", {}) is Dictionary
			else {}
		)
	}


func _save_cache_v0180_hotfix2() -> void:
	CCFStorageService.ensure_directories()
	var file := FileAccess.open(CACHE_FILE_V0180_HOTFIX2, FileAccess.WRITE)
	if file == null:
		return
	var safe_cache := {
		"format_version": CACHE_FORMAT_VERSION_V0180_HOTFIX2,
		"last_checked_unix": maxi(
			0, int(_cache_v0180_hotfix2.get("last_checked_unix", 0))
		),
		"etag": str(_cache_v0180_hotfix2.get("etag", "")).strip_edges(),
		"release": _cache_v0180_hotfix2.get("release", {})
	}
	file.store_string(JSON.stringify(safe_cache, "  "))
	file.close()


static func _header_value_v0180_hotfix2(
	headers: PackedStringArray, requested_name: String
) -> String:
	var prefix := requested_name.to_lower() + ":"
	for raw_header in headers:
		var header := str(raw_header)
		if header.to_lower().begins_with(prefix):
			return header.substr(prefix.length()).strip_edges()
	return ""
