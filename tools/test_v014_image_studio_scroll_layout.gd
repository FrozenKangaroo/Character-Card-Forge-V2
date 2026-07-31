extends SceneTree


func _init() -> void:
	var page := CCFImageGenerationPage.new()
	page._ready()

	_assert_true(page._studio_scroll != null, "Embedded Image Studio must create a scroll container.")
	_assert_equal(
		page._studio_scroll.vertical_scroll_mode,
		ScrollContainer.SCROLL_MODE_AUTO,
		"Embedded Image Studio must allow vertical overflow to scroll."
	)
	_assert_equal(
		page._studio_scroll.horizontal_scroll_mode,
		ScrollContainer.SCROLL_MODE_DISABLED,
		"Embedded Image Studio should continue fitting the main workspace width rather than requiring horizontal scrolling."
	)
	_assert_true(
		bool(page._studio_scroll.size_flags_vertical & Control.SIZE_EXPAND),
		"Image Studio scroll viewport must consume available workspace height."
	)

	var controller := CCFImageGenerationWindow.new()
	var studio_root := MarginContainer.new()
	controller.add_child(studio_root)
	page.attach_controller(controller)

	_assert_true(
		studio_root.get_parent() == page._studio_scroll,
		"Mounted Image Studio UI must live inside the vertical scroll viewport."
	)
	_assert_true(page._mounted, "Image Studio page should report the controller UI as mounted.")

	controller.queue_free()
	page.queue_free()
	print("v0.14 Image Studio scroll-layout regression passed")
	quit(0)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_fail("%s Expected %s, got %s." % [message, str(expected), str(actual)])


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_fail(message)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
