class_name CCFImageProviderTransportServiceV0173Hotfix1
extends RefCounted

const TRANSPORT_OPENAI_IMAGES := "openai_images_generations"
const TRANSPORT_OPENROUTER_IMAGES := "openrouter_images"


static func transport_for_base_url(base_url: String) -> String:
	return (
		TRANSPORT_OPENROUTER_IMAGES
		if is_openrouter_base_url(base_url)
		else TRANSPORT_OPENAI_IMAGES
	)


static func is_openrouter_base_url(base_url: String) -> bool:
	var host := _url_host(base_url)
	return host == "openrouter.ai" or host.ends_with(".openrouter.ai")


static func openrouter_generation_url(base_url: String) -> String:
	var api_root := _openrouter_api_root(base_url)
	return api_root + "/images" if not api_root.is_empty() else ""


static func openrouter_models_url(base_url: String) -> String:
	var api_root := _openrouter_api_root(base_url)
	return api_root + "/images/models" if not api_root.is_empty() else ""


static func safe_request_url(request_url: String) -> String:
	var clean := request_url.strip_edges()
	var query_index := clean.find("?")
	if query_index >= 0:
		clean = clean.left(query_index)
	var fragment_index := clean.find("#")
	if fragment_index >= 0:
		clean = clean.left(fragment_index)
	var scheme_index := clean.find("://")
	if scheme_index < 0:
		return clean
	var authority_start := scheme_index + 3
	var path_index := clean.find("/", authority_start)
	var authority_end := path_index if path_index >= 0 else clean.length()
	var authority := clean.substr(authority_start, authority_end - authority_start)
	var at_index := authority.rfind("@")
	if at_index >= 0:
		clean = clean.left(authority_start) + authority.substr(at_index + 1) + clean.substr(authority_end)
	return clean


static func _openrouter_api_root(base_url: String) -> String:
	if not is_openrouter_base_url(base_url):
		return ""
	var clean := safe_request_url(base_url)
	while clean.ends_with("/"):
		clean = clean.left(clean.length() - 1)
	var api_index := clean.to_lower().find("/api/v1")
	if api_index >= 0:
		return clean.left(api_index) + "/api/v1"
	return clean + "/api/v1"


static func _url_host(base_url: String) -> String:
	var clean := base_url.strip_edges()
	var scheme_index := clean.find("://")
	if scheme_index < 0:
		return ""
	var authority_start := scheme_index + 3
	var path_index := clean.find("/", authority_start)
	var authority := (
		clean.substr(authority_start)
		if path_index < 0
		else clean.substr(authority_start, path_index - authority_start)
	)
	var at_index := authority.rfind("@")
	if at_index >= 0:
		authority = authority.substr(at_index + 1)
	if authority.begins_with("["):
		var bracket_index := authority.find("]")
		return authority.substr(1, bracket_index - 1).to_lower() if bracket_index > 0 else ""
	var colon_index := authority.find(":")
	if colon_index >= 0:
		authority = authority.left(colon_index)
	return authority.to_lower()
