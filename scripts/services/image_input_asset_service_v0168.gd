class_name CCFImageInputAssetServiceV0168
extends RefCounted

const OP_TEXT_TO_IMAGE := "text_to_image"
const OP_IMAGE_TO_IMAGE := "image_to_image"
const OP_INPAINTING := "inpainting"
const OP_REFERENCE_IMAGES := "reference_images"

const TRANSPORT_KEY := "image_input_transport_v0168"
const SUPPORTED_EXTENSIONS := ["png", "jpg", "jpeg", "webp"]


static func normalise_operation(value: String) -> String:
	var clean := value.strip_edges().to_lower()
	if clean not in [OP_TEXT_TO_IMAGE, OP_IMAGE_TO_IMAGE, OP_INPAINTING, OP_REFERENCE_IMAGES]:
		return OP_TEXT_TO_IMAGE
	return clean


static func validate_bundle(operation: String, options: Dictionary) -> Dictionary:
	var clean_operation := normalise_operation(operation)
	var source_path := str(options.get("source_image_path", "")).strip_edges()
	var mask_path := str(options.get("mask_image_path", "")).strip_edges()
	var reference_paths := normalise_paths(options.get("reference_image_paths", []))
	if clean_operation in [OP_IMAGE_TO_IMAGE, OP_INPAINTING]:
		if source_path.is_empty():
			return {"ok": false, "error": "Choose a source image for %s." % operation_label(clean_operation)}
		var source_check := validate_image_path(source_path)
		if not bool(source_check.get("ok", false)):
			return source_check
	if clean_operation == OP_INPAINTING:
		if mask_path.is_empty():
			return {"ok": false, "error": "Choose a mask image before starting inpainting."}
		var mask_check := validate_image_path(mask_path)
		if not bool(mask_check.get("ok", false)):
			return mask_check
	if clean_operation == OP_REFERENCE_IMAGES:
		if reference_paths.is_empty():
			return {"ok": false, "error": "Choose at least one reference image before generating."}
		for path_text in reference_paths:
			var reference_check := validate_image_path(path_text)
			if not bool(reference_check.get("ok", false)):
				return reference_check
	return {"ok": true}


static func validate_image_path(path_text: String) -> Dictionary:
	var clean := path_text.strip_edges()
	if clean.is_empty():
		return {"ok": false, "error": "Image path is empty."}
	if not FileAccess.file_exists(clean):
		return {"ok": false, "error": "Image file does not exist: %s" % clean}
	var extension := clean.get_extension().to_lower()
	if extension not in SUPPORTED_EXTENSIONS:
		return {"ok": false, "error": "Unsupported image format '%s'. Use PNG, JPEG, or WebP." % extension}
	var bytes := FileAccess.get_file_as_bytes(clean)
	if bytes.is_empty():
		return {"ok": false, "error": "Image file is empty or could not be read: %s" % clean}
	return {"ok": true}


static func encoded_image(path_text: String) -> Dictionary:
	var validation := validate_image_path(path_text)
	if not bool(validation.get("ok", false)):
		return validation
	var bytes := FileAccess.get_file_as_bytes(path_text.strip_edges())
	return {
		"ok": true,
		"base64": Marshalls.raw_to_base64(bytes),
		"extension": path_text.get_extension().to_lower(),
		"path": path_text.strip_edges()
	}


static func normalise_paths(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if not value is Array:
		return result
	for raw_path in value:
		var clean := str(raw_path).strip_edges()
		if clean.is_empty() or clean in result:
			continue
		result.append(clean)
	return result


static func operation_transport(profile: Dictionary, operation: String) -> Dictionary:
	var transport_root: Variant = profile.get(TRANSPORT_KEY, {})
	if not transport_root is Dictionary:
		return {}
	var operations: Variant = transport_root.get("operations", {})
	if not operations is Dictionary:
		return {}
	var descriptor: Variant = operations.get(normalise_operation(operation), {})
	return descriptor.duplicate(true) if descriptor is Dictionary else {}


static func with_execution_readiness(capabilities: Dictionary, profile: Dictionary) -> Dictionary:
	var result := capabilities.duplicate(true)
	var operations: Dictionary = (
		result.get("operations", {}).duplicate(true)
		if result.get("operations", {}) is Dictionary
		else {}
	)
	var backend := CCFSettingsService.image_backend(profile)
	if backend == CCFSettingsService.IMAGE_BACKEND_AUTOMATIC1111:
		operations[OP_IMAGE_TO_IMAGE] = _operation_descriptor(
			CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED,
			true,
			CCFImageModelCapabilityServiceV0161.SOURCE_BACKEND,
			CCFImageModelCapabilityServiceV0161.CONFIDENCE_KNOWN
		)
		operations[OP_INPAINTING] = _operation_descriptor(
			CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED,
			true,
			CCFImageModelCapabilityServiceV0161.SOURCE_BACKEND,
			CCFImageModelCapabilityServiceV0161.CONFIDENCE_KNOWN
		)
	# Generic/provider-specific image-input transports remain data-driven. A
	# profile only becomes execution-ready when it explicitly maps the operation.
	for operation_name in [OP_IMAGE_TO_IMAGE, OP_INPAINTING, OP_REFERENCE_IMAGES]:
		var transport := operation_transport(profile, operation_name)
		if transport.is_empty():
			continue
		operations[operation_name] = _operation_descriptor(
			CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED,
			true,
			CCFImageModelCapabilityServiceV0161.SOURCE_USER_OVERRIDE,
			CCFImageModelCapabilityServiceV0161.CONFIDENCE_USER_DEFINED
		)
	result["operations"] = operations
	return result


static func operation_execution_ready(capabilities: Dictionary, operation: String) -> bool:
	var clean := normalise_operation(operation)
	if clean == OP_TEXT_TO_IMAGE:
		return true
	return (
		CCFImageModelCapabilityServiceV0161.operation_state(capabilities, clean)
		== CCFImageModelCapabilityServiceV0161.STATE_SUPPORTED
		and CCFImageModelCapabilityServiceV0161.execution_ready(capabilities, clean)
	)


static func operation_label(operation: String) -> String:
	match normalise_operation(operation):
		OP_IMAGE_TO_IMAGE:
			return "Image to Image"
		OP_INPAINTING:
			return "Inpainting"
		OP_REFERENCE_IMAGES:
			return "Reference Images"
		_:
			return "Text to Image"


static func _operation_descriptor(
	state: String,
	execution_ready: bool,
	source: String,
	confidence: String
) -> Dictionary:
	return {
		"state": state,
		"execution_ready": execution_ready,
		"source": source,
		"confidence": confidence
	}
