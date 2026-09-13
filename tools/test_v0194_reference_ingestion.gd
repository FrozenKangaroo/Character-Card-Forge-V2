extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _fail(message_text: String) -> void:
	push_error(message_text)
	print("V0194_REFERENCE_INGESTION_ERROR: %s" % message_text)
	quit(1)


func _require(condition: bool, message_text: String) -> bool:
	if condition:
		return true
	_fail(message_text)
	return false


func _run() -> void:
	if not _test_url_boundaries():
		return
	if not _test_remote_inspection():
		return
	if not _test_pdf_extraction():
		return
	if not _test_managed_attachment_pipeline():
		return
	if not await _test_active_ui_wiring():
		return
	print("V0194_REFERENCE_INGESTION_OK")
	quit(0)


func _test_url_boundaries() -> bool:
	var valid := CCFReferenceIngestionServiceV0194.validate_https_url(
		"https://example.com/reference.pdf"
	)
	var relative := CCFReferenceIngestionServiceV0194.resolve_redirect_url(
		"https://example.com/docs/old.html", "new.html"
	)
	var root_relative := CCFReferenceIngestionServiceV0194.resolve_redirect_url(
		"https://example.com/docs/old.html", "/assets/new.pdf"
	)
	return (
		_require(bool(valid.get("ok", false)), "A normal HTTPS reference must validate.")
		and _require(
			not bool(CCFReferenceIngestionServiceV0194.validate_https_url(
				"http://example.com/reference.pdf"
			).get("ok", false)),
			"Plain HTTP references must be rejected."
		)
		and _require(
			not bool(CCFReferenceIngestionServiceV0194.validate_https_url(
				"https://name:secret@example.com/file"
			).get("ok", false)),
			"Embedded remote credentials must be rejected."
		)
		and _require(
			str(relative.get("url", "")) == "https://example.com/docs/new.html",
			"Relative redirects must stay on the current HTTPS directory."
		)
		and _require(
			str(root_relative.get("url", "")) == "https://example.com/assets/new.pdf",
			"Root-relative redirects must resolve against the HTTPS origin."
		)
		and _require(
			not bool(CCFReferenceIngestionServiceV0194.resolve_redirect_url(
				"https://example.com/file", "http://example.com/unsafe"
			).get("ok", false)),
			"Redirects must never downgrade from HTTPS to HTTP."
		)
		and _require(
			not bool(CCFReferenceIngestionServiceV0194.resolve_redirect_url(
				"https://example.com/file", ""
			).get("ok", false)),
			"A redirect without a Location destination must fail closed."
		)
	)


func _test_remote_inspection() -> bool:
	var html := (
		"<html><head><style>.hidden {display:none}</style><script>ignore_me()</script></head>"
		+ "<body><h1>Reference title</h1><p>Useful character evidence.</p></body></html>"
	).to_utf8_buffer()
	var inspected := CCFReferenceIngestionServiceV0194.inspect_download(
		html, "text/html; charset=utf-8", "reference.html"
	)
	var preprocess: Dictionary = inspected.get("preprocess", {})
	return (
		_require(bool(inspected.get("ok", false)), "Bounded HTTPS HTML must be inspectable.")
		and _require(
			str(preprocess.get("extracted_text", "")).contains("Reference title")
			and str(preprocess.get("extracted_text", "")).contains("Useful character evidence")
			and not str(preprocess.get("extracted_text", "")).contains("ignore_me"),
			"HTML preprocessing must extract readable text without active script/style content."
		)
		and _require(
			not bool(CCFReferenceIngestionServiceV0194.inspect_download(
				PackedByteArray([1, 2, 3]), "application/octet-stream", "program.bin"
			).get("ok", false)),
			"Unsupported remote binary content must be rejected before acceptance."
		)
	)


func _test_pdf_extraction() -> bool:
	var extracted := CCFReferenceIngestionServiceV0194.extract_pdf_bytes(
		_simple_pdf("Hello PDF world")
	)
	var compressed := CCFReferenceIngestionServiceV0194.extract_pdf_bytes(
		_compressed_pdf("Compressed PDF evidence")
	)
	var scanned := CCFReferenceIngestionServiceV0194.extract_pdf_bytes(
		_simple_pdf("")
	)
	return (
		_require(
			str(extracted.get("status", "")) == "ready"
			and int(extracted.get("page_count", 0)) == 1
			and str(extracted.get("extracted_text", "")).contains("Hello PDF world"),
			"A PDF text layer must be extracted locally with page metadata."
		)
		and _require(
			str(compressed.get("status", "")) == "ready"
			and str(compressed.get("extracted_text", "")).contains("Compressed PDF evidence"),
			"A standard Flate-compressed PDF text stream must be extracted locally."
		)
		and _require(
			str(scanned.get("status", "")) == "no_text_layer"
			and str(scanned.get("summary", "")).contains("OCR"),
			"Image-only PDFs must remain stored without silently invoking OCR."
		)
	)


func _test_managed_attachment_pipeline() -> bool:
	var project_id := "v0194-reference-test"
	var local_pdf_path := "user://v0194-reference-fixture.pdf"
	var file := FileAccess.open(local_pdf_path, FileAccess.WRITE)
	if not _require(file != null, "The focused test must be able to create its local PDF fixture."):
		return false
	file.store_buffer(_simple_pdf("Managed PDF evidence"))
	file.close()
	var imported_pdf := CCFAttachmentService.import_file(
		project_id, "character-1", "project", local_pdf_path
	)
	if not _require(bool(imported_pdf.get("ok", false)), "Local PDFs must import into managed storage."):
		return false
	var pdf_attachment: Dictionary = imported_pdf.get("attachment", {})
	if not _require(
		not bool(pdf_attachment.get("include_in_context", true))
		and str(pdf_attachment.get("preprocess", {}).get("status", "")) == "ready",
		"Imported PDFs must be extracted but remain out of generation context until explicitly enabled."
	):
		return false

	var inspected := CCFReferenceIngestionServiceV0194.inspect_download(
		"Remote character evidence".to_utf8_buffer(),
		"text/plain",
		"evidence.txt"
	)
	var source := {
		"kind": "remote_https",
		"source_url": "https://example.com/evidence.txt",
		"final_url": "https://example.com/evidence.txt",
		"fetched_at": "2026-09-13T00:00:00Z",
		"content_type": "text/plain",
		"sha256": "fixture"
	}
	var imported_remote := CCFAttachmentService.import_bytes(
		project_id,
		"character-1",
		"project",
		"Remote character evidence".to_utf8_buffer(),
		"evidence.txt",
		source,
		true,
		inspected.get("preprocess", {})
	)
	if not _require(bool(imported_remote.get("ok", false)), "Reviewed remote bytes must copy into managed storage."):
		return false
	var remote_attachment: Dictionary = imported_remote.get("attachment", {})
	var managed_path := CCFAttachmentService.resolve_absolute_path(
		project_id, remote_attachment
	)
	var project := {
		"project_id": project_id,
		"attachments": [remote_attachment],
		"characters": []
	}
	var context := CCFAttachmentService.context_report(project, "", 12000)
	return (
		_require(FileAccess.file_exists(managed_path), "Accepted remote content must have a managed project copy.")
		and _require(
			str(remote_attachment.get("source", {}).get("source_url", ""))
			== "https://example.com/evidence.txt",
			"Remote source provenance must survive attachment normalization."
		)
		and _require(
			str(context.get("text", "")).contains("Untrusted remote reference")
			and str(context.get("text", "")).contains("Remote character evidence"),
			"Enabled remote text must reuse the bounded attachment context pipeline and carry an untrusted-data boundary."
		)
	)


func _test_active_ui_wiring() -> bool:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var app := packed.instantiate()
	get_root().add_child(app)
	await process_frame
	await process_frame
	var workspace_value: Variant = app.get("_workspace")
	if not _require(
		workspace_value is CCFWorkspaceV0194View,
		"The active scene must install the v0.19.4 workspace."
	):
		return false
	var workspace := workspace_value as CCFWorkspaceV0194View
	var capabilities := workspace.reference_ingestion_capabilities_v0194()
	if not _require(
		bool(capabilities.get("local_pdf_text_layer", false))
		and bool(capabilities.get("https_preview_before_accept", false))
		and not bool(capabilities.get("background_remote_refresh", true)),
		"The active attachment surface must expose the review-first v0.19.4 contract."
	):
		return false
	var add_url_found := false
	var refresh_found := false
	var version_found := false
	for node in app.find_children("*", "Button", true, false):
		if node is Button and node.text == "Add from URL…":
			add_url_found = true
		if node is Button and node.text == "Refresh Remote…":
			refresh_found = true
	for node in app.find_children("*", "Label", true, false):
		if node is Label and node.text in [
			"Godot rewrite • v0.19.4", "Godot rewrite • v0.19.5"
		]:
			version_found = true
	if not _require(
		add_url_found and refresh_found and version_found,
		"The current build must visibly expose URL ingestion, explicit refresh and its v0.19.4 identity."
	):
		return false
	app.queue_free()
	await process_frame
	return true


func _simple_pdf(text: String) -> PackedByteArray:
	var stream := "BT /F1 12 Tf 72 720 Td"
	if not text.is_empty():
		stream += " (%s) Tj" % text
	stream += " ET"
	return (
		"%PDF-1.4\n"
		+ "1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n"
		+ "2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n"
		+ "3 0 obj << /Type /Page /Parent 2 0 R /Contents 4 0 R >> endobj\n"
		+ "4 0 obj << /Length %d >> stream\n%s\nendstream endobj\n" % [stream.length(), stream]
		+ "%%EOF\n"
	).to_ascii_buffer()


func _compressed_pdf(text: String) -> PackedByteArray:
	var stream := "BT /F1 12 Tf 72 720 Td (%s) Tj ET" % text
	var compressed := stream.to_ascii_buffer().compress(FileAccess.COMPRESSION_DEFLATE)
	var result := (
		"%PDF-1.4\n"
		+ "1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n"
		+ "2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n"
		+ "3 0 obj << /Type /Page /Parent 2 0 R /Contents 4 0 R >> endobj\n"
		+ "4 0 obj << /Length %d /Filter /FlateDecode >> stream\n" % compressed.size()
	).to_ascii_buffer()
	result.append_array(compressed)
	result.append_array("\nendstream endobj\n%%EOF\n".to_ascii_buffer())
	return result
