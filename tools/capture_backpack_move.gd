extends SceneTree

## OW1: the backpack's move verb and its quick-bar section, shot at the scale
## the game is actually read at.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/capture_backpack_move.gd
##
## Same harness as tools/capture_menu_panels.gd (see its header) with two
## differences that matter for this task.
##
## First, it drives the REAL input path rather than calling `_on_slot()`: a
## frame that proves a private method works proves nothing about whether the
## button reaches it, and "the button does not visibly reach it" is the whole
## of the owner's report.
##
## Second, every frame is written twice. The Ally is 1920x1080 across seven
## inches, so a legend that reads fine on a desktop monitor can be unreadable
## on the device -- bible §17, "do not judge only on desktop monitor". The
## `_handheld` copy is the same frame downscaled to 0.40, which is roughly the
## angular size a 7-inch panel at arm's length has against a 24-inch monitor at
## desk distance. It is a proxy, not a measurement, and it is the cheapest
## honest one available from a headless box.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 8

## 1920x1080 -> 768x432. See the header for where 0.40 comes from.
const HANDHELD_SCALE := 0.40


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return

	var world: Node = packed.instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var game := root.get_node_or_null(^"Game")
	if game == null:
		push_error("Game autoload not in the tree")
		quit(1)
		return
	var menu: Node = game.call("menu")
	if menu == null:
		push_error("autoload did not stand up the menu")
		quit(1)
		return

	# A stocked satchel and a party, so the panels are judged against real
	# contents rather than empty cells.
	var inventory: RefCounted = game.get("inventory")
	var party: RefCounted = game.get("party")
	if party != null and int(party.call("size")) == 0:
		var creature: RefCounted = game.call("make_creature", "terrapup")
		if creature != null:
			party.call("add", creature)
	if inventory != null:
		inventory.call("add", "orb_basic", 6)
		inventory.call("add", "potion_small", 3)
		inventory.call("add", "berries", 7)
		inventory.call("add", "wood", 24)
		inventory.call("add", "stone", 11)
		inventory.call("add", "fiber", 18)

	var written: Array[String] = []
	var failures: Array[String] = []

	menu.call("open", "backpack")
	for i in POSE_FRAMES:
		await process_frame
	var body: Node = menu.get("_bodies")[0]

	# 1. At rest: is there a quick bar, and does the verb legend name Move?
	var orbs: int = int(inventory.call("find_slot", "orb_basic"))
	if orbs >= 0:
		(body.get("_buttons")[orbs] as Button).grab_focus()
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("backpack_idle", written, failures)

	# 2. Mid-move: a stack in hand, which is the state a blind playtest entered
	#    by accident and could not read its way out of.
	await _press("ui_accept")
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("backpack_holding", written, failures)

	# 3. Cursor on the quick bar with a stack still in hand -- the frame that
	#    answers "I can't move anything into it".
	var bar: Array = body.get("_bar_buttons")
	if bar != null and bar.size() >= 3:
		(bar[2] as Button).grab_focus()
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("backpack_quickbar_target", written, failures)

	# 4. After the bind: the chip carries the item, the satchel still has it.
	await _press("ui_accept")
	for i in POSE_FRAMES * 2:
		await process_frame
	await _shoot("backpack_bound", written, failures)

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")

	if not failures.is_empty():
		print("")
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


## Both halves of a press, for the reason docs/AGENT_WORKFLOW.md records: focus
## navigation and Button.pressed need a real event, action state alone is not
## enough, and a capture driven only by `action_press` would photograph a
## screen nothing had happened on.
func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	Input.action_press(action)
	await process_frame
	await process_frame
	Input.action_release(action)
	event.pressed = false
	Input.parse_input_event(event)
	for i in 4:
		await process_frame


func _shoot(name: String, written: Array[String], failures: Array[String]) -> void:
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		failures.append("%s: viewport returned no image" % name)
		return

	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(path) != OK:
		failures.append("%s: save_png failed" % name)
		return
	written.append(path)
	print("  %-28s -> %s" % [name, path])

	var small := Image.new()
	small.copy_from(image)
	small.resize(
		int(image.get_width() * HANDHELD_SCALE),
		int(image.get_height() * HANDHELD_SCALE),
		Image.INTERPOLATE_LANCZOS
	)
	var small_path := "%s/%s_handheld.png" % [OUT_DIR, name]
	if small.save_png(small_path) != OK:
		failures.append("%s: handheld-proxy save_png failed" % name)
		return
	written.append(small_path)
	print("  %-28s -> %s" % ["%s (handheld proxy)" % name, small_path])
