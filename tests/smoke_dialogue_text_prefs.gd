extends SceneTree

## UX §8: the player's dialogue text size and background opacity reach a real
## conversation, and the largest size still fits its box on screen.
##
##   godot --headless --path . --script tests/smoke_dialogue_text_prefs.gd

const DIALOGUE_SCENE := "res://scenes/ui/dialogue_panel.tscn"
const TEXT := preload("res://scripts/ui/text_prefs.gd")
const CONVERSATION := "grandpa_house"
const SETTLE := 6

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var world := Node.new()
	world.name = "StageWorld"
	root.add_child(world)
	current_scene = world
	var panel: Node = (load(DIALOGUE_SCENE) as PackedScene).instantiate()
	world.add_child(panel)
	for i in SETTLE:
		await process_frame

	var body: Label = panel.get_node("Root/Box/Margin/Row/Text/Body")
	var box: PanelContainer = panel.get_node("Root/Box")
	var base_size := body.get_theme_font_size("font_size")

	TEXT.set_text_percent(150)
	TEXT.set_background_percent(60)
	if not bool(panel.call("start", CONVERSATION)):
		_fail("the %s conversation did not start" % CONVERSATION)
	for i in SETTLE:
		await process_frame
	if body.get_theme_font_size("font_size") != roundi(base_size * 1.5):
		_fail("body text is %d at 150%%, expected %d" % [body.get_theme_font_size("font_size"), roundi(base_size * 1.5)])
	var plate := box.get_theme_stylebox("panel") as StyleBoxFlat
	if plate == null or absf(plate.bg_color.a - 0.6) > 0.001:
		_fail("the panel plate did not take the 60% background")
	var box_rect := box.get_global_rect()
	if box_rect.position.y < 0.0:
		_fail("the grown box leaves the top of the screen (%s)" % box_rect)
	# Every line of the conversation at the largest size must fit the box.
	var lines := 0
	while bool(panel.call("is_open")) and lines < 40:
		var body_rect := body.get_global_rect()
		if body_rect.end.y > box_rect.end.y + 0.5 or body.get_line_count() > body.get_visible_line_count():
			_fail("line %d overflows the box at 150%%: '%s'" % [lines, body.text.left(60)])
			break
		panel.call("advance")
		lines += 1
		for i in SETTLE:
			await process_frame
	print("checked %d lines of '%s' at 150%% text on a 60%% plate" % [lines, CONVERSATION])

	TEXT.reset()
	panel.call("apply_text_prefs")
	if body.get_theme_font_size("font_size") != base_size:
		_fail("resetting did not return the body to its authored size")

	panel.queue_free()
	await process_frame
	if _failures.is_empty():
		print("dialogue text prefs smoke passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


func _fail(message: String) -> void:
	_failures.append(message)
