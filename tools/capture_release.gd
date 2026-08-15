extends SceneTree

## Capture the release ceremony (R4.10) for the blind-judge pass.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script tools/capture_release.gd
##
## Four frames, one per thing the ceremony has to sell:
##   release_choose   - the six-up choice beat, focus on the newcomer
##   release_inspect  - the same beat mid-comparison, focus on a bonded veteran
##   release_confirm  - the farewell question for a belt member
##   release_done     - the goodbye beat, released creature in the viewport
##
## The belt is staged as a believable mid-game party — five species, spread
## levels, real bond and damage — because a critic shown five identical Lv 1
## rows cannot judge whether the comparison a real decision needs is on
## screen.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"
const PROGRESSION := preload("res://scripts/creatures/progression.gd")

const SETTLE_FRAMES := 240
const POSE_FRAMES := 10


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var world: Node = (load(SCENE) as PackedScene).instantiate()
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
	var party: RefCounted = game.get("party")
	if menu == null or party == null:
		push_error("no menu or party to stage the ceremony on")
		quit(1)
		return

	var cfg: Dictionary = PROGRESSION.config()
	var belt := [
		["terrapup", "Biscuit", 12, 74, 1.0],
		["ripplet", "", 8, 31, 0.85],
		["galewisp", "Kite", 10, 48, 1.0],
		["mudsnout", "", 7, 22, 0.45],
		["bramblebun", "", 5, 9, 0.9],
	]
	for entry in belt:
		var creature: RefCounted = game.call("make_creature", str(entry[0]), str(entry[1]))
		if creature == null:
			push_error("species %s did not build" % str(entry[0]))
			quit(1)
			return
		creature.call("set_level", int(entry[2]), cfg)
		creature.set("bond", int(entry[3]))
		var hp := float(creature.get("max_hp")) * float(entry[4])
		creature.set("hp", hp)
		party.call("add", creature)

	# The squeeze: a fresh catch, species name only, the way a real one
	# arrives.
	var newcomer: RefCounted = game.call("make_creature", "meadowhart")
	newcomer.call("set_level", 9, cfg)
	game.set("pending_catch", newcomer)

	# `Game._watch_pending_catch` opens the ceremony on its own.
	for i in 90:
		await process_frame
		if bool(menu.call("is_open")):
			break
	var tab: Node = null
	var tabs: Array = menu.get("_tabs")
	for i in tabs.size():
		if str((tabs[i] as Dictionary).get("id", "")) == "creatures":
			tab = (menu.get("_bodies") as Array)[i]
			break
	if tab == null or str(tab.get("_release_stage")) != "choose":
		push_error("the ceremony did not reach its choose beat")
		quit(1)
		return

	var written: Array[String] = []
	var failures: Array[String] = []

	for i in POSE_FRAMES:
		await process_frame
	await _shoot("release_choose", written, failures)

	# Mid-comparison: the veteran with the deepest bond, the row the decision
	# actually hurts on.
	(tab.get("_rows")[0] as Button).grab_focus()
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("release_inspect", written, failures)

	# The farewell question for the least-bonded belt member.
	(tab.get("_rows")[4] as Button).grab_focus()
	await process_frame
	await _press("ui_accept")
	if str(tab.get("_release_stage")) != "confirm":
		failures.append("could not reach the confirm beat")
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("release_confirm", written, failures)

	# Let them go: down to the release button, confirm, goodbye beat.
	await _press("ui_down")
	await _press("ui_accept")
	if str(tab.get("_release_stage")) != "done":
		failures.append("could not reach the done beat")
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("release_done", written, failures)

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")
	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	Input.action_press(action)
	await process_frame
	await process_frame
	Input.action_release(action)
	event = InputEventAction.new()
	event.action = action
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
	var error := image.save_png(path)
	if error != OK:
		failures.append("%s: save_png failed (%d)" % [name, error])
		return
	written.append(path)
	print("  %-16s -> %s" % [name, path])
